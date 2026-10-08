from pathlib import Path
import json
import os
import shutil
import subprocess

repo = Path(__file__).resolve().parents[2]
home = Path.home()
log = home / 'equantum-commission-assignment-validacion.txt'
manifest = home / 'equantum-commission-assignment-migration.json'
template = repo / 'scripts/relaunch/sql/commission_assignment_v3.sql'
container = 'equantum-staging'
database = 'equantum_restore_clean'


def execute(command, source=None):
    result = subprocess.run(command, cwd=repo, input=source, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(result.stdout, flush=True)
    with log.open('a') as output:
        output.write(result.stdout)
    if result.returncode:
        raise RuntimeError(f'Validación detenida: código {result.returncode}. Evidencia: {log}')
    return result.stdout.strip()


log.write_text('VALIDACION LOCAL DE COMMISSION_ASSIGNMENT; SIN PRODUCCION\n')
psql = ['docker', 'exec', '-i', container, 'psql', '-U', 'postgres',
        '-d', database, '-X', '-v', 'ON_ERROR_STOP=1', '-At', '-P', 'pager=off']
if execute(psql, 'SELECT current_database();') != database:
    raise RuntimeError('Base inesperada.')

existing = list((repo / 'supabase/migrations').glob('*_commission_assignment_v3.sql'))
if len(existing) > 1:
    raise RuntimeError('Hay más de una migración de asignacion de comision.')
if existing:
    migration = existing[0]
    if migration.read_text() != template.read_text():
        raise RuntimeError('La migración existente no coincide con el candidato.')
else:
    cli = shutil.which('supabase')
    if not cli:
        for folder, dirs, files in os.walk(home):
            dirs[:] = [d for d in dirs if d not in
                       {'node_modules', '.cache', 'equantum-cli-cache', '.git',
                        'equantum-staging-pg17'}]
            if len(Path(folder).relative_to(home).parts) > 5:
                dirs[:] = []
                continue
            candidate = Path(folder) / 'supabase'
            if 'supabase' in files and os.access(candidate, os.X_OK):
                cli = str(candidate)
                break
    if not cli:
        raise RuntimeError('No se encontró el CLI instalado; no se descargó ni instaló otro.')
    execute([cli, 'migration', 'new', '--help'])
    execute([cli, 'migration', 'new', 'commission_assignment_v3'])
    generated = list((repo / 'supabase/migrations').glob('*_commission_assignment_v3.sql'))
    if len(generated) != 1:
        raise RuntimeError('CLI generó un resultado inesperado.')
    migration = generated[0]
    if migration.read_text().strip():
        raise RuntimeError('La migración generada no está vacía; no se sobrescribió.')
    migration.write_text(template.read_text())

runner = repo / 'scripts/relaunch/migrate-v2-order.sh'
text = runner.read_text()
entry = '  "' + migration.name + '"'
if entry not in text:
    anchor = '  "20261008024203_fiscal_policy_governance_v3.sql"'
    if text.count(anchor) != 1:
        raise RuntimeError('Runner inesperado; no se modificó.')
    runner.write_text(text.replace(anchor, anchor + '\n' + entry, 1))

manifest.write_text(json.dumps({'migration':str(migration.relative_to(repo)),
                               'candidate':'commission-assignment-v3'}, indent=2) + '\n')
print('MIGRACION_GENERADA=' + migration.name, flush=True)

# Ensayo desde baseline nuevo antes de actualizar la base local habitual.
db = 'equantum_assignment_rehearsal'
psql = ['docker','exec','-i',container,'psql','-U','postgres','-X','-v','ON_ERROR_STOP=1','-At','-P','pager=off']
if execute(psql + ['-d','postgres'],
           "SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname='equantum_assignment_rehearsal');") != 'f':
    raise RuntimeError('La base de ensayo ya existe. No se borró ni sobrescribió.')

dump = home / 'staging-baseline.dump'
restore_list = home / 'staging-baseline.restore-filtered.txt'
if not dump.is_file() or not restore_list.is_file():
    raise RuntimeError('Falta el dump o la lista filtrada del restore validado.')
active = [line for line in restore_list.read_text().splitlines()
          if line.strip() and not line.lstrip().startswith(';')]
if any('vault' in line.lower() for line in active):
    raise RuntimeError('La lista contiene Vault; no se inició el restore.')

execute(['docker','cp',str(dump),container + ':/tmp/assignment-baseline.dump'])
execute(['docker','cp',str(restore_list),container + ':/tmp/assignment-restore-list.txt'])
execute(['docker','exec',container,'createdb','-U','postgres',db])
execute(['docker','exec',container,'pg_restore','-U','postgres','-d',db,
         '--no-owner','--no-privileges','--single-transaction','--exit-on-error',
         '--use-list=/tmp/assignment-restore-list.txt','/tmp/assignment-baseline.dump'])

baseline = execute(psql + ['-d',db], """
SELECT name, actual, wanted FROM (VALUES
('clients',(SELECT count(*) FROM public.clients),3),
('projects',(SELECT count(*) FROM public.projects),0),
('tasks',(SELECT count(*) FROM public.tasks),3),
('followups',(SELECT count(*) FROM public.followups),0),
('tickets',(SELECT count(*) FROM public.tickets),2),
('ticket_messages',(SELECT count(*) FROM public.ticket_messages),3),
('ticket_events',(SELECT count(*) FROM public.ticket_events),10),
('profiles',(SELECT count(*) FROM public.profiles),3),
('user_permissions',(SELECT count(*) FROM public.user_permissions),3),
('chat_messages',(SELECT count(*) FROM public.chat_messages),2),
('client_portal_users',(SELECT count(*) FROM public.client_portal_users),1)
) AS counts(name,actual,wanted);
""")
rows = baseline.splitlines()
if len(rows) != 11 or any(row.split('|')[1] != row.split('|')[2] for row in rows):
    raise RuntimeError('Baseline no reconciliado; migraciones no ejecutadas.')

output = execute(['bash','scripts/relaunch/migrate-v2-order.sh',db,container])
counters = dict(line.split('=',1) for line in output.splitlines()
                if '=' in line and line.split('=',1)[0] in {'ATTEMPTED','PASS','FAIL','TOTAL'})
if counters != {'ATTEMPTED':'22','PASS':'22','FAIL':'0','TOTAL':'22'}:
    raise RuntimeError('Runner incompleto; se esperaban 22/22 migraciones.')

files = sorted((repo / 'supabase/tests').glob('*.sql'))
if len(files) != 27:
    raise RuntimeError('Inventario SQL inesperado; se esperaban 27 tests.')
for file in files:
    print('=== ' + file.name + ' ===',flush=True)
    execute(psql + ['-d',db],file.read_text())
    print('PASS | ' + file.name,flush=True)

# El restore nuevo aprobó el runner completo y toda la regresión.
# Mantener equantum_restore_clean actualizado para el QA oficial posterior.
current_psql = psql + ['-d', database]
installed = execute(current_psql, "SELECT to_regprocedure('public.assign_proposal_commission_v3(uuid,uuid)') IS NOT NULL;")
if installed == 'f':
    execute(current_psql, migration.read_text())
elif installed != 't':
    raise RuntimeError('Estado comision local inesperado.')
else:
    if execute(current_psql, "SELECT to_regprocedure('public.guard_proposal_commission_assignment_v3()') IS NOT NULL;") != 't':
        raise RuntimeError('Existe esquema comision incompatible; no se sobrescribió.')
execute(current_psql, (repo / 'supabase/tests/commission_assignment_v3.sql').read_text())
execute(['bash', '-n', str(runner)])
execute(['git', '--no-pager', 'diff', '--check'])
execute(['git', '--no-pager', 'status', '--short'])
execute(['node','--test','scripts/relaunch/finance-summary.test.cjs'])
execute(['npx','--no-install','tsc','--noEmit'])
execute(['npm','run','build'])
print('MIGRACION_GENERADA=' + migration.name)
with log.open('a') as output:
    output.write('\nMIGRATIONS=22/22 SQL_QA=27/27\n')
print('MIGRATIONS=22/22 SQL_QA=27/27')
print('VALIDACION_COMMISSION_ASSIGNMENT_GOBERNADA_APROBADA; sin commit/push/merge/despliegue.')
print('Evidencia:', log)
