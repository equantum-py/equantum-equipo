#!/usr/bin/env node

/**
 * Creates/verifies/removes six synthetic Auth identities in the P1 test project.
 * Uses Supabase Auth Admin API and PostgREST only; it never inserts auth.users.
 * The service key and generated test passwords are never printed or committed.
 */
import { createClient } from '@supabase/supabase-js';
import { randomBytes, randomUUID } from 'node:crypto';
import { chmod, mkdir, readFile, rename, stat, unlink, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const PROJECT_REF = 'rqisyolaffwktxhjwpqq';
const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const DEFAULT_STATE_FILE = path.join(homedir(), '.cache', 'equantum-p1', `${PROJECT_REF}-auth-fixtures.json`);
const ACTORS = [
  { key: 'internal_owner', fullName: 'P1 synthetic internal owner' },
  { key: 'internal_peer', fullName: 'P1 synthetic internal peer' },
  { key: 'internal_viewer', fullName: 'P1 synthetic read-only viewer' },
  { key: 'internal_inactive', fullName: 'P1 synthetic inactive user' },
  { key: 'portal_a', fullName: 'P1 synthetic Portal A' },
  { key: 'portal_b', fullName: 'P1 synthetic Portal B' },
];

function fail(message) {
  throw new Error(message);
}

function config() {
  const ref = process.env.P1_TEST_PROJECT_REF;
  const url = process.env.P1_TEST_SUPABASE_URL;
  const key = process.env.P1_TEST_SERVICE_ROLE_KEY;
  if (ref !== PROJECT_REF) fail(`BLOCKED: P1_TEST_PROJECT_REF must be ${PROJECT_REF}.`);
  if (!url || !key) fail('BLOCKED: set P1_TEST_SUPABASE_URL and P1_TEST_SERVICE_ROLE_KEY in a protected local environment.');
  let parsed;
  try { parsed = new URL(url); } catch { fail('BLOCKED: P1_TEST_SUPABASE_URL is not a valid URL.'); }
  if (parsed.protocol !== 'https:' || parsed.hostname !== `${PROJECT_REF}.supabase.co`) {
    fail('BLOCKED: URL does not exactly identify the authorized test project; no request was sent.');
  }
  const stateFile = path.resolve(process.env.P1_FIXTURE_STATE_FILE || DEFAULT_STATE_FILE);
  const relative = path.relative(REPO_ROOT, stateFile);
  if (!relative.startsWith('..') && !path.isAbsolute(relative)) {
    fail('BLOCKED: fixture state must be stored outside the repository.');
  }
  return { url, key, stateFile };
}

function client(url, key) {
  return createClient(url, key, {
    auth: { autoRefreshToken: false, persistSession: false, detectSessionInUrl: false },
  });
}

async function writeState(file, state) {
  const dir = path.dirname(file);
  await mkdir(dir, { recursive: true, mode: 0o700 });
  await chmod(dir, 0o700);
  const temporary = `${file}.${process.pid}.tmp`;
  await writeFile(temporary, `${JSON.stringify(state, null, 2)}\n`, { mode: 0o600, flag: 'wx' });
  await rename(temporary, file);
  await chmod(file, 0o600);
}

async function readState(file) {
  const fileStat = await stat(file).catch(() => null);
  if (!fileStat) fail('BLOCKED: no fixture state file exists; run create first.');
  if ((fileStat.mode & 0o077) !== 0) fail('BLOCKED: fixture state file permissions are broader than 0600.');
  const state = JSON.parse(await readFile(file, 'utf8'));
  if (state.project_ref !== PROJECT_REF || !Array.isArray(state.users) || !Array.isArray(state.clients)) {
    fail('BLOCKED: fixture state does not match the authorized test project.');
  }
  return state;
}

async function readOne(clientRef, table, columns, id) {
  const { data, error } = await clientRef.from(table).select(columns).eq('id', id).maybeSingle();
  if (error) fail(`BLOCKED: could not verify synthetic ${table} fixture (database policy/ACL may be incomplete).`);
  return data;
}

async function verifyUser(admin, db, user, runId, password) {
  const { data: authData, error: authError } = await admin.auth.admin.getUserById(user.id);
  if (authError || !authData?.user || authData.user.email !== user.email
      || authData.user.user_metadata?.p1_fixture_run_id !== runId) {
    fail(`BLOCKED: Auth fixture identity check failed for ${user.actor}.`);
  }
  const profile = await readOne(db, 'profiles', 'id,full_name,role,active', user.id);
  const { data: permission, error: permissionError } = await db.from('user_permissions')
    .select('user_id,view_all_tasks,view_own_tasks,reassign_tasks')
    .eq('user_id', user.id).maybeSingle();
  if (!profile || permissionError || !permission) {
    fail(`FAIL: Auth did not create both profile and permissions rows for ${user.actor}.`);
  }
  const expectedActive = user.actor !== 'internal_inactive';
  const expectedViewAll = user.actor === 'internal_viewer';
  if (profile.full_name !== user.full_name || profile.role !== 'collaborator'
      || profile.active !== expectedActive
      || permission.view_all_tasks !== expectedViewAll
      || permission.reassign_tasks !== false) {
    fail(`FAIL: unexpected default profile values for synthetic ${user.actor}.`);
  }
  if (user.actor.startsWith('portal_')) {
    const { data: mapping, error: mappingError } = await db.from('client_portal_users')
      .select('user_id,client_id,active').eq('user_id', user.id).maybeSingle();
    if (mappingError || !mapping?.active || !stateClientExists(user, mapping.client_id)) {
      fail(`FAIL: synthetic ${user.actor} is missing its isolated Portal client mapping.`);
    }
  }
  const { data: sessionData, error: signInError } = await client(
    process.env.P1_TEST_SUPABASE_URL, process.env.P1_TEST_SERVICE_ROLE_KEY,
  ).auth.signInWithPassword({ email: user.email, password });
  if (signInError || !sessionData?.session?.access_token) {
    fail(`FAIL: synthetic Auth login failed for ${user.actor}.`);
  }
  return { actor: user.actor, user_id: user.id, role: profile.role, active: profile.active,
    view_all_tasks: permission.view_all_tasks, reassign_tasks: permission.reassign_tasks };
}

function stateClientExists(user, clientId) {
  const state = globalThis.__p1FixtureState;
  return state?.clients?.some((item) => item.actor === user.actor && item.id === clientId) === true;
}

async function create() {
  const { url, key, stateFile } = config();
  const existing = await stat(stateFile).catch(() => null);
  if (existing) fail('BLOCKED: a fixture state file already exists; verify or clean it before creating another run.');
  const admin = client(url, key);
  const db = client(url, key);
  const state = { version: 1, project_ref: PROJECT_REF, run_id: randomUUID(), users: [], clients: [] };
  globalThis.__p1FixtureState = state;
  await writeState(stateFile, state);
  try {
    for (const actor of ACTORS) {
      const email = `p1-${state.run_id}-${actor.key}@example.invalid`;
      const password = `${randomBytes(32).toString('base64url')}aA9!`;
      const { data, error } = await admin.auth.admin.createUser({
        email, password, email_confirm: true,
        user_metadata: {
          full_name: actor.fullName,
          p1_fixture_run_id: state.run_id,
          p1_fixture_actor: actor.key,
        },
      });
      if (error || !data?.user?.id) fail(`FAIL: Supabase Auth could not create synthetic ${actor.key}.`);
      const user = { actor: actor.key, id: data.user.id, email, full_name: actor.fullName, password };
      state.users.push(user);
      await writeState(stateFile, state);
      const profile = await readOne(db, 'profiles', 'id,full_name,role,active', user.id);
      const { data: permission, error: permissionError } = await db.from('user_permissions')
        .select('user_id').eq('user_id', user.id).maybeSingle();
      if (!profile || profile.full_name !== user.full_name || permissionError || !permission) {
        fail(`FAIL: Auth trigger did not create profile and permission rows for ${actor.key}.`);
      }
      process.stdout.write(`PASS Auth/profile trigger: ${actor.key} ${user.id}\n`);
    }
    const viewer = state.users.find((user) => user.actor === 'internal_viewer');
    const { error: viewerError } = await db.from('user_permissions')
      .update({ view_all_tasks: true, view_own_tasks: false }).eq('user_id', viewer.id);
    if (viewerError) fail('FAIL: could not configure the synthetic read-only viewer permission.');
    const inactive = state.users.find((user) => user.actor === 'internal_inactive');
    const { error: inactiveError } = await db.from('profiles').update({ active: false }).eq('id', inactive.id);
    if (inactiveError) fail('FAIL: could not configure the synthetic inactive profile.');

    for (const actor of ['portal_a', 'portal_b']) {
      const user = state.users.find((item) => item.actor === actor);
      const { data: clientData, error: clientError } = await db.from('clients')
        .insert({ name: `P1 synthetic ${actor} ${state.run_id}`, status: 'active' })
        .select('id').single();
      if (clientError || !clientData?.id) fail(`FAIL: could not create the synthetic client for ${actor}.`);
      const fixtureClient = { actor, id: clientData.id };
      state.clients.push(fixtureClient);
      await writeState(stateFile, state);
      const { error: mappingError } = await db.from('client_portal_users').insert({
        user_id: user.id, client_id: clientData.id, full_name: user.full_name, active: true,
      });
      if (mappingError) fail(`FAIL: could not create the synthetic Portal mapping for ${actor}.`);
      await writeState(stateFile, state);
    }
    globalThis.__p1FixtureState = state;
    const finalResults = [];
    for (const user of state.users) finalResults.push(await verifyUser(admin, db, user, state.run_id, user.password));
    process.stdout.write('PASS: Auth API created six synthetic users; trigger produced profile/permission rows and role fixtures were scoped.\n');
    process.stdout.write(`Fixture state (private file): ${stateFile}\n`);
  } catch (error) {
    process.stderr.write(`${error.message || 'Fixture creation failed.'}\n`);
    process.stderr.write('Partial state was retained securely. Run cleanup after checking the listed synthetic IDs.\n');
    process.exitCode = 1;
  }
}

async function verify() {
  const { url, key, stateFile } = config();
  const state = await readState(stateFile);
  globalThis.__p1FixtureState = state;
  if (state.users.length !== ACTORS.length) fail('BLOCKED: fixture set is incomplete; no scenario run should start.');
  const admin = client(url, key);
  const db = client(url, key);
  const results = [];
  for (const user of state.users) {
    const result = await verifyUser(admin, db, user, state.run_id, user.password);
    results.push(result);
  }
  process.stdout.write(`PASS: verified ${results.length} Auth sessions and profile/permission trigger rows in ${PROJECT_REF}.\n`);
  for (const result of results) process.stdout.write(`${result.actor} ${result.user_id} role=${result.role} active=${result.active}\n`);
}

async function cleanup() {
  const { url, key, stateFile } = config();
  const state = await readState(stateFile);
  globalThis.__p1FixtureState = state;
  const admin = client(url, key);
  const db = client(url, key);
  // This script never creates tasks. SQL scenario fixtures must run inside a
  // transaction and ROLLBACK before Auth cleanup; committed concurrency
  // fixtures require their own explicit teardown before this command.
  for (const user of state.users) {
    const { data, error } = await admin.auth.admin.getUserById(user.id);
    if (error || !data?.user) continue;
    if (data.user.email !== user.email || data.user.user_metadata?.p1_fixture_run_id !== state.run_id) {
      fail(`BLOCKED: refusing to delete an Auth identity that no longer matches this fixture (${user.actor}).`);
    }
  }
  for (const user of state.users) {
    const { data, error } = await admin.auth.admin.getUserById(user.id);
    if (error || !data?.user) continue;
    const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
    if (deleteError) fail(`BLOCKED: Auth did not delete synthetic ${user.actor}; state retained.`);
    const profile = await readOne(db, 'profiles', 'id', user.id);
    const { data: permission, error: permissionError } = await db.from('user_permissions')
      .select('user_id').eq('user_id', user.id).maybeSingle();
    if (permissionError || profile || permission) {
      fail(`FAIL: residual profile/permission row after deleting synthetic ${user.actor}; state retained.`);
    }
  }
  if (state.clients.length) {
    const { error } = await db.from('clients').delete().in('id', state.clients.map((item) => item.id));
    if (error) fail('BLOCKED: could not remove synthetic clients; fixture state retained.');
    const { data: remaining, error: verifyError } = await db.from('clients').select('id')
      .in('id', state.clients.map((item) => item.id));
    if (verifyError || remaining?.length) fail('FAIL: synthetic client residue remains; state retained.');
  }
  await unlink(stateFile);
  process.stdout.write(`PASS: deleted ${state.users.length} Auth fixtures; profiles/permissions cascaded and verified absent.\n`);
}

const command = process.argv[2];
try {
  if (command === 'create') await create();
  else if (command === 'verify') await verify();
  else if (command === 'cleanup') await cleanup();
  else fail('Usage: node scripts/relaunch/p1-auth-fixtures.mjs <create|verify|cleanup>');
} catch (error) {
  process.stderr.write(`${error.message || 'Fixture operation failed.'}\n`);
  process.exitCode = 1;
}
