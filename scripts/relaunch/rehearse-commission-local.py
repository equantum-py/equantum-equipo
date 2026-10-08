from pathlib import Path
import subprocess
import sys

repo = Path(sys.argv[1]).resolve()
expected = sys.argv[2]
home = Path.home()
container = 'equantum-staging'
db = 'equantum_commission_rehearsal'
log = home / 'equantum-commission-rehearsal.txt'
migration = 'supabase/migrations/20261008021415_commission_policies_v3.sql'
log.write_text('ENSAYO DESDE RESTORE NUEVO; SIN PRODUCCION\n')


def execute(command, source=None):
    result = subprocess.run(command, cwd=repo, input=source, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(result.stdout, flush=True)
    with log.open('a') as output:
        output.write(result.stdout)
    if result.returncode:
        raise RuntimeError(f'Ensayo detenido: código {result.returncode}. Evidencia: {log}')
    return result.stdout.strip()


for name in [migration, 'scripts/relaunch/migrate-v2-order.sh'] + [
    str(path.relative_to(repo)) for path in sorted((repo / 'supabase/tests').glob('*.sql'))
]:
    content = subprocess.check_output(['git','--no-pager','show',expected + ':' + name],cwd=repo)
    if (repo / name).read_bytes() != content:
        raise RuntimeError('El archivo local difiere del candidato: ' + name)

psql = ['docker','exec','-i',container,'psql','-U','postgres','-X',
        '-v','ON_ERROR_STOP=1','-At','-P','pager=off']
if execute(psql + ['-d','postgres'],
           "SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname='equantum_commission_rehearsal');") != 'f':
    raise RuntimeError('La base de ensayo ya existe. No se borró ni sobrescribió.')

dump = home / 'staging-baseline.dump'
restore_list = home / 'staging-baseline.restore-filtered.txt'
if not dump.is_file() or not restore_list.is_file():
    raise RuntimeError('Falta el dump o la lista filtrada del restore validado.')
active = [line for line in restore_list.read_text().splitlines()
          if line.strip() and not line.lstrip().startswith(';')]
if any('vault' in line.lower() for line in active):
    raise RuntimeError('La lista contiene Vault; no se inició el restore.')

execute(['docker','cp',str(dump),container + ':/tmp/commission-baseline.dump'])
execute(['docker','cp',str(restore_list),container + ':/tmp/commission-restore-list.txt'])
execute(['docker','exec',container,'createdb','-U','postgres',db])
execute(['docker','exec',container,'pg_restore','-U','postgres','-d',db,
         '--no-owner','--no-privileges','--single-transaction','--exit-on-error',
         '--use-list=/tmp/commission-restore-list.txt','/tmp/commission-baseline.dump'])

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
if counters != {'ATTEMPTED':'20','PASS':'20','FAIL':'0','TOTAL':'20'}:
    raise RuntimeError('Runner incompleto; se esperaban 20/20 migraciones.')

files = sorted((repo / 'supabase/tests').glob('*.sql'))
if len(files) != 25:
    raise RuntimeError('Inventario SQL inesperado; se esperaban 25 tests.')
for file in files:
    print('=== ' + file.name + ' ===',flush=True)
    execute(psql + ['-d',db],file.read_text())
    print('PASS | ' + file.name,flush=True)
with log.open('a') as output:
    output.write('\nMIGRATIONS=20/20 SQL_QA=25/25\n')
print('MIGRATIONS=20/20 SQL_QA=25/25')
print('ENSAYO_COMISION_DESDE_RESTORE_APROBADO; sin commit/push/merge/despliegue.')
print('Base de ensayo conservada:',db)
print('Evidencia:',log)
