from pathlib import Path
import json
import re
import subprocess

repo = Path(__file__).resolve().parents[2]
home = Path.home()
container = 'equantum-staging'
database = 'equantum_flow_rehearsal'
log = home / 'equantum-commercial-flow-validacion.txt'
manifest = json.loads((home / 'equantum-commercial-flow-migration.json').read_text())
migration = repo / manifest['migration']
template = repo / 'scripts/relaunch/sql/commercial_flow_v3.sql'
if not migration.is_file() or migration.read_text() != template.read_text():
    raise RuntimeError('Migracion local distinta del candidato; no se modifico la base.')
previous = log.read_text()
if 'ATTEMPTED=22\nPASS=22\nFAIL=0\nTOTAL=22' not in previous:
    raise RuntimeError('Falta evidencia previa del runner 22/22; restore no repetido.')
with log.open('a') as output:
    output.write('\n=== REANUDACION: MISMO RESTORE; CORRECCION SOLO DEL TEST ===\n')


def execute(command, source=None):
    result = subprocess.run(command, cwd=repo, input=source, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(result.stdout, flush=True)
    with log.open('a') as output:
        output.write(result.stdout)
    if result.returncode:
        raise RuntimeError(f'Validacion detenida; evidencia: {log}')
    return result.stdout.strip()


psql = ['docker', 'exec', '-i', container, 'psql', '-U', 'postgres',
        '-X', '-v', 'ON_ERROR_STOP=1', '-At', '-P', 'pager=off']
if execute(psql + ['-d', database], 'SELECT current_database();') != database:
    raise RuntimeError('Base de ensayo inesperada.')
# Comprobar que las cinco funciones instaladas conservan exactamente el cuerpo
# de la migracion ya ensayada. La correccion no cambia funciones ni permisos.
functions = re.findall(r'CREATE FUNCTION public\.(\w+)\(.*?AS \$\$(.*?)\$\$;',
                       template.read_text(), re.S)
if len(functions) != 5:
    raise RuntimeError('Inventario de funciones inesperado.')
for name, body in functions:
    literal = "'" + body.replace("'", "''") + "'"
    query = ("SELECT count(*)=1 AND bool_and(prosrc=" + literal + ") "
             "FROM pg_proc WHERE pronamespace='public'::regnamespace AND proname='" + name + "';")
    if execute(psql + ['-d', database], query) != 't':
        raise RuntimeError('Funcion instalada incompatible: ' + name)
files = sorted((repo / 'supabase/tests').glob('*.sql'))
if len(files) != 28:
    raise RuntimeError('Se esperaban 28 pruebas SQL.')
for file in files:
    print('=== ' + file.name + ' ===', flush=True)
    execute(psql + ['-d', database], file.read_text())
    with log.open('a') as output:
        output.write('PASS | ' + file.name + '\n')
    print('PASS | ' + file.name, flush=True)

for command in [
    ['git', '--no-pager', 'diff', '--check'],
    ['bash', '-n', 'scripts/relaunch/migrate-v2-order.sh'],
    ['node', '--test', 'scripts/relaunch/finance-summary.test.cjs'],
    ['npx', '--no-install', 'tsc', '--noEmit'],
    ['npm', 'run', 'build'],
]:
    print('=== ' + ' '.join(command) + ' ===', flush=True)
    execute(command)

# Actualizar la base habitual solo despues de pasar SQL y compilacion.
usual = psql + ['-d', 'equantum_restore_clean']
exists = execute(usual, "SELECT to_regprocedure('public.create_proposal_workflow_v3(uuid,uuid,text,text,jsonb,uuid,uuid,text,text)') IS NOT NULL;")
if exists == 'f':
    execute(usual, migration.read_text())
elif exists != 't':
    raise RuntimeError('Estado de la base habitual inesperado.')
for file in ['commercial_financial_flow_v3.sql', 'commission_assignment_v3.sql',
             'commission_policy_snapshot_v3.sql']:
    execute(usual, (repo / 'supabase/tests' / file).read_text())
with log.open('a') as output:
    output.write('\nMIGRATIONS=22/22 (ensayo previo conservado); SQL_QA=28/28; BUILD=PASS\n')
print('MIGRACION_GENERADA=' + migration.name)
print('VALIDACION_CIRCUITO_LOCAL_APROBADA; sin commit/push/merge/despliegue.')
print('Evidencia:', log)
