from pathlib import Path
import json
import os
import shutil
import subprocess

repo = Path(__file__).resolve().parents[2]
home = Path.home()
log = home / 'equantum-commission-validacion.txt'
manifest = home / 'equantum-commission-migration.json'
template = repo / 'scripts/relaunch/sql/commission_policies_v3.sql'
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


log.write_text('VALIDACION LOCAL DE COMISION; SIN PRODUCCION\n')
psql = ['docker', 'exec', '-i', container, 'psql', '-U', 'postgres',
        '-d', database, '-X', '-v', 'ON_ERROR_STOP=1', '-At', '-P', 'pager=off']
if execute(psql, 'SELECT current_database();') != database:
    raise RuntimeError('Base inesperada.')

existing = list((repo / 'supabase/migrations').glob('*_commission_policies_v3.sql'))
if len(existing) > 1:
    raise RuntimeError('Hay más de una migración de comisiones.')
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
    execute([cli, 'migration', 'new', 'commission_policies_v3'])
    generated = list((repo / 'supabase/migrations').glob('*_commission_policies_v3.sql'))
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
    anchor = '  "20261008013538_release_guards_v3.sql"'
    if text.count(anchor) != 1:
        raise RuntimeError('Runner inesperado; no se modificó.')
    runner.write_text(text.replace(anchor, anchor + '\n' + entry, 1))

manifest.write_text(json.dumps({'migration':str(migration.relative_to(repo)),
                               'candidate':'commission-policies-v3'}, indent=2) + '\n')
print('MIGRACION_GENERADA=' + migration.name, flush=True)
installed = execute(psql, "SELECT to_regclass('public.commission_policy_versions') IS NOT NULL;")
if installed == 'f':
    execute(psql, migration.read_text())
elif installed != 't':
    raise RuntimeError('No se pudo comprobar el estado de instalación.')
else:
    if execute(psql, "SELECT to_regprocedure('public.snapshot_sale_commission_v3()') IS NOT NULL;") != 't':
        raise RuntimeError('Existe una tabla incompatible; no se modificó a ciegas.')
    print('Esquema de comisión ya presente; se valida sin reaplicarlo.', flush=True)

execute(psql, (repo / 'supabase/tests/commission_policy_snapshot_v3.sql').read_text())
execute(['bash', '-n', str(runner)])
execute(['bash', 'scripts/relaunch/qa-sql.sh', database])
execute(['git', '--no-pager', 'diff', '--check'])
execute(['git', '--no-pager', 'status', '--short'])
print('MIGRACION_GENERADA=' + migration.name)
print('VALIDACION_COMISION_LOCAL_APROBADA; sin commit/push/merge/despliegue.')
print('Evidencia:', log)
