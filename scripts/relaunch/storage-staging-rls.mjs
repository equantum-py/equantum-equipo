import { randomUUID } from "node:crypto";
import { createClient } from "@supabase/supabase-js";

const required = [
  "SUPABASE_URL",
  "SUPABASE_ANON_KEY",
  "STORAGE_PORTAL_A_EMAIL",
  "STORAGE_PORTAL_A_PASSWORD",
  "STORAGE_PORTAL_B_EMAIL",
  "STORAGE_PORTAL_B_PASSWORD",
  "STORAGE_INTERNAL_EMAIL",
  "STORAGE_INTERNAL_PASSWORD",
];

const missing = required.filter((name) => !process.env[name]);
if (missing.length) {
  console.error(
    `BLOCKED: faltan variables de entorno: ${missing.join(", ")}`,
  );
  process.exitCode = 2;
} else {
  await run();
}

function clientFor(email, password) {
  const client = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
        detectSessionInUrl: false,
      },
    },
  );
  return { client, email, password };
}

async function signIn(actor) {
  const { data, error } = await actor.client.auth.signInWithPassword({
    email: actor.email,
    password: actor.password,
  });
  if (error || !data.user) {
    throw new Error("No se pudo autenticar una cuenta de prueba.");
  }
  actor.userId = data.user.id;
}

function assertAllowed(result, label) {
  if (result.error || !result.data) {
    throw new Error(`FAIL: ${label}`);
  }
  console.log(`PASS: ${label}`);
}

function assertDenied(result, label) {
  if (!result.error && result.data) {
    throw new Error(`FAIL: ${label}`);
  }
  console.log(`PASS: ${label}`);
}

async function download(actor, path) {
  return actor.client.storage.from("ticket-attachments").download(path);
}

async function signedUrl(actor, path) {
  return actor.client.storage.from("ticket-attachments").createSignedUrl(path, 60);
}

async function run() {
  const url = process.env.SUPABASE_URL.replace(/\/$/, "");
  const portalA = clientFor(
    process.env.STORAGE_PORTAL_A_EMAIL,
    process.env.STORAGE_PORTAL_A_PASSWORD,
  );
  const portalB = clientFor(
    process.env.STORAGE_PORTAL_B_EMAIL,
    process.env.STORAGE_PORTAL_B_PASSWORD,
  );
  const internal = clientFor(
    process.env.STORAGE_INTERNAL_EMAIL,
    process.env.STORAGE_INTERNAL_PASSWORD,
  );
  const anon = createClient(
    url,
    process.env.SUPABASE_ANON_KEY,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
        detectSessionInUrl: false,
      },
    },
  );

  const objectId = randomUUID();
  let pathA;
  let pathB;
  let uploadedA = false;
  let uploadedB = false;
  let failed = false;

  try {
    await Promise.all([signIn(portalA), signIn(portalB), signIn(internal)]);
    if (
      portalA.userId === portalB.userId ||
      portalA.userId === internal.userId ||
      portalB.userId === internal.userId
    ) {
      throw new Error("Las cuentas de prueba deben ser distintas.");
    }

    pathA = `${portalA.userId}/qa-storage-${objectId}-a.txt`;
    pathB = `${portalB.userId}/qa-storage-${objectId}-b.txt`;

    const uploadA = await portalA.client.storage
      .from("ticket-attachments")
      .upload(pathA, "storage isolation QA A", {
        contentType: "text/plain",
        upsert: false,
      });
    if (uploadA.error) throw new Error("Falló la carga de prueba del Portal A.");
    uploadedA = true;
    console.log("PASS: Portal A carga un objeto privado propio");

    const ownA = await download(portalA, pathA);
    assertAllowed(ownA, "Portal A descarga su propio objeto");

    const crossAB = await download(portalB, pathA);
    assertDenied(crossAB, "Portal B no descarga el objeto de A");

    const crossSignedAB = await signedUrl(portalB, pathA);
    assertDenied(crossSignedAB, "Portal B no genera URL firmada para A");

    const uploadB = await portalB.client.storage
      .from("ticket-attachments")
      .upload(pathB, "storage isolation QA B", {
        contentType: "text/plain",
        upsert: false,
      });
    if (uploadB.error) throw new Error("Falló la carga de prueba del Portal B.");
    uploadedB = true;
    console.log("PASS: Portal B carga un objeto privado propio");

    const ownB = await download(portalB, pathB);
    assertAllowed(ownB, "Portal B descarga su propio objeto");

    const crossBA = await download(portalA, pathB);
    assertDenied(crossBA, "Portal A no descarga el objeto de B");

    const crossSignedBA = await signedUrl(portalA, pathB);
    assertDenied(crossSignedBA, "Portal A no genera URL firmada para B");

    const anonA = await download(anon, pathA);
    assertDenied(anonA, "anon no descarga el objeto de A");

    const anonB = await download(anon, pathB);
    assertDenied(anonB, "anon no descarga el objeto de B");

    const publicPath = (path) =>
      path.split("/").map(encodeURIComponent).join("/");
    let publicResponse;
    try {
      publicResponse = await fetch(
        `${url}/storage/v1/object/public/ticket-attachments/${publicPath(pathA)}`,
        { headers: { apikey: process.env.SUPABASE_ANON_KEY } },
      );
    } catch {
      throw new Error("No se pudo comprobar la ruta pública del bucket.");
    }
    if (publicResponse.ok) {
      throw new Error("FAIL: el bucket permite lectura pública.");
    }
    console.log("PASS: la ruta pública no expone el objeto");

    const internalSigned = await signedUrl(internal, pathA);
    if (internalSigned.error || !internalSigned.data?.signedUrl) {
      throw new Error(
        "FAIL: la cuenta interna autorizada no genera acceso temporal.",
      );
    }
    const internalResponse = await fetch(internalSigned.data.signedUrl)
      .catch(() => null);
    if (!internalResponse?.ok) {
      throw new Error("FAIL: la URL temporal interna no permite leer el objeto.");
    }
    console.log("PASS: usuario interno autorizado obtiene acceso temporal");
  } catch (error) {
    failed = true;
    console.error(error instanceof Error ? error.message : "Falló la prueba.");
  } finally {
    const cleanup = [];
    if (uploadedA) {
      const result = await portalA.client.storage
        .from("ticket-attachments")
        .remove([pathA]);
      if (result.error) cleanup.push("Portal A");
    }
    if (uploadedB) {
      const result = await portalB.client.storage
        .from("ticket-attachments")
        .remove([pathB]);
      if (result.error) cleanup.push("Portal B");
    }

    if (cleanup.length) {
      failed = true;
      console.error(
        `FAIL: no se pudo limpiar el objeto QA de ${cleanup.join(" y ")}.`,
      );
    } else if (uploadedA || uploadedB) {
      console.log("PASS: objetos QA eliminados");
    }

    await Promise.all([
      portalA.client.auth.signOut(),
      portalB.client.auth.signOut(),
      internal.client.auth.signOut(),
    ]);
  }

  if (failed) process.exitCode = 1;
  else console.log("STORAGE_STAGING_RLS_PASS");
}
