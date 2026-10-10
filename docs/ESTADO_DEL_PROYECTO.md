# Estado del proyecto — EQ Relanzamiento 2026

Actualizado: 2026-10-10 UTC. Resumen de trabajo local; no representa producción.

## Resumen

P1/M03–M05 tiene implementación candidata de Tareas, Triage y Radar, pero sigue
PARTIAL. El esquema de prueba se reconstruyó en `eQuantum P1 Pruebas`; el trigger
Auth fue corregido y comprobado estructuralmente en ese proyecto. Se verificó
una denegación SQL para anon. El bucket privado de Storage todavía falta y no se
crearon usuarios Auth sintéticos: de los 59 casos, 1 tiene PASS acotado, 57 están
BLOQUEADOS por fixtures Auth/datos y 1 limpieza final NO EJECUTADA. Nada de esto
es aceptación formal ni valida producción.
## Ejecución P1 en Supabase de pruebas — 2026-10-10

- Destino confirmado antes de escribir: `equantum-p1-pruebas`, ref
  `rqisyolaffwktxhjwpqq`, PostgreSQL 17.11, estado `ACTIVE_HEALTHY`. No se
  escribió en `eQuantum Equipo` (`oujrahzvljdhzqsdyujh`).
- Se reconstruyó solo el esquema inicial autorizado desde metadatos de
  estructura; no se copiaron registros, identificadores, credenciales ni
  secretos. Se aplicaron las 24 migraciones en el orden de
  `scripts/relaunch/migrate-v2-order.sh`, más el baseline estructural de prueba.
- La inspección estructural anterior encontró PostgreSQL 17.11, 34 tablas
  públicas, 71 políticas públicas, RLS en las 34 tablas, Auth y Storage
  administrados presentes, y cero filas de aplicación/usuarios Auth. Esa
  evidencia estructural no verificaba el trigger de Auth ni la configuración
  del bucket. El smoke check se reforzó para exigirlos; al ejecutarlo contra el
  estado actual debe bloquear hasta completar esos prerrequisitos.
- La comparación de ACL de metadatos encontró una diferencia real: producción
  concede CRUD a `anon`, `authenticated` y `service_role` sobre las 13 tablas
  del esquema base; el proyecto de pruebas conserva permisos más limitados
  (por ejemplo, `authenticated` no tiene acceso directo a Tickets, Followups o
  Radar). No se amplió ningún permiso. Hasta que las pruebas usen privilegios
  temporales, específicos y revertidos por transacción, los resultados de
  solicitudes directas pueden diferir antes de llegar a RLS.
- Se verificó directamente el catálogo de `auth.users`: el proyecto de pruebas
  no tiene el trigger `on_auth_user_created`, aunque sí tiene
  `public.handle_new_user()`. La producción tiene el trigger habilitado y
  conectado a esa función. El hash de `pg_get_functiondef()` coincide entre
  ambos proyectos (`d4064af0ab44adb36eb3f46a4151d5fe`). La causa demostrable es
  que el baseline reconstruye la función pero no el trigger; ninguna de las 24
  migraciones del repositorio crea ese trigger. Corrección segura propuesta:
  una migración idempotente y revisable que cree el trigger solo si falta,
  rechace un trigger preexistente con destino distinto y fije
  `search_path = ''` en la función cualificada. No se aplicó DDL nuevo en esta
  sesión.
- Las políticas RLS instaladas fueron consultadas con definición efectiva. En
  `tasks`, la lectura limita al asignado o a scopes explícitos; las
  transiciones pasan por `transition_task_operational_status`, que exige actor
  activo, scope de escritura y estado esperado. Historial limita la lectura al
  alcance de la tarea. En Tickets, mensajes, clientes y mapeo Portal existen
  políticas internas y de cliente por `portal_client_id()`, con mensajes
  Portal limitados a tickets propios y `is_internal = false`. Estas expresiones
  son evidencia estructural, no prueba de resultado por actor.
- Hay una brecha efectiva de privilegios en el laboratorio: `authenticated`
  tiene SELECT/INSERT/UPDATE de `tasks` y SELECT de `task_status_history`, pero
  no tiene SELECT/INSERT/UPDATE/DELETE directos sobre `tickets`,
  `ticket_messages`, `clients`, `client_portal_users`, `followups` o
  `radar_items`. Las policies de esas tablas existen, pero el API no puede
  llegar a evaluarlas hasta preparar privilegios mínimos de prueba. No se dio
  `GRANT ALL` ni se ampliaron permisos.
- La tabla `public.client_legacy_services` tiene RLS sin políticas: es cerrada
  para SELECT/INSERT/UPDATE/DELETE de `anon` y `authenticated`, por lo que el
  aviso del Advisor no señala una lectura pública. Sin embargo, ambos roles
  aún tienen TRUNCATE efectivo, que RLS no protege. Esto requiere una revocación
  versionada y acotada antes de considerar mínimo privilegio cerrado.
- Security Advisors de seguridad reportó además dos funciones invoker con
  `search_path` mutable (`calculate_task_triage`, `apply_task_triage_v2`) y 13
  funciones `SECURITY DEFINER` ejecutables por `authenticated`. Las dos
  primeras no son SECURITY DEFINER y `anon`/`authenticated` no pueden crear en
  `public`; riesgo inmediato bajo, con corrección simple recomendada mediante
  `SET search_path = ''`. Las funciones elevadas incluyen helpers necesarios
  para policies/RPC, con checks de actor/scope en las funciones revisadas;
  revocar EXECUTE en bloque rompería esas rutas. Se conserva pendiente la
  revisión individual, especialmente el cambio de permiso financiero Master
  frente al gate M01 de doble control. No se aplicaron cambios a funciones o
  grants.
- Storage: en la prueba hay RLS y una policy SELECT
  `ticket attachments read authorized` (propietario por carpeta UID o interno),
  pero no existe el bucket `ticket-attachments` ni policies INSERT/DELETE. La
  metadata leída de producción confirma un bucket-policy contract distinto:
  policy SELECT anterior de bucket, INSERT y DELETE propios. La migración V3
  reemplaza SELECT, pero presupone las dos policies de escritura. El aislamiento
  de lectura es estructuralmente correcto; lectura A/B y escrituras no fueron
  ejecutadas y el laboratorio no reproduce todavía el bucket ni el contrato
  completo. No se tocó producción.
- Se recuperó del artefacto previo
  `FASE1_P1_casos_prueba.csv`: 59 filas, 59 IDs auxiliares únicos, todos
  `PREPARADO — NO EJECUTADO`. La copia exacta queda en
  `docs/relaunch/acceptance/P1_SCENARIOS_59.csv`. No son los 401 IDs oficiales
  ACC/IT/INT y no cambian su aceptación. No se inventó estado PASS.
- No se ejecutó una regresión funcional. Esta sesión no dispone de Auth Admin
  ni de Storage API para crear/borrar identidades sintéticas por la vía
  soportada; tampoco se preparó un fixture administrativo persistente. Las
  pruebas de RLS por actor siguen bloqueadas hasta corregir el esquema de Auth,
  habilitar las políticas de acceso mínimas en el test harness y obtener un
  ciclo seguro de creación/limpieza de identidades. No se insertaron filas en
  `auth.users`.
- Preparación local pendiente de revisión: baseline solo de estructura,
  guardia de destino para P1–P7, smoke check ampliado y manifiesto auxiliar de
  los 59 escenarios.
- P1/M03–M05 permanece PARTIAL. No hubo merge, push ni despliegue.

## Activación supervisada — ejecución actual 2026-10-09

- Revisé `AGENTS.md`: está en la raíz y apunta expresamente a
  `docs/PROTOCOLO_MAESTRO.md` y `docs/PLAN_MAESTRO.md`. En esta sesión el
  checkout no era la raíz inicial del trabajo; leí esas instrucciones de forma
  explícita. La carga automática de AGENTS por la plataforma no quedó
  demostrada y la PR #2 del protocolo continúa abierta en borrador.
- Estado remoto consultado de la PR #2: abierta, Draft, mergeable, cinco
  archivos; head remoto `24316a6fe43d73e170aa18fa6741a360a12b78c8`, base
  `02eabdc195e60f8c2c6133af942d193c9c1cbb19`. El checkout local de la rama del
  protocolo termina en `dd40cff` y no coincide con ese head; no se publicó ni
  integró.
- GitHub también muestra la rama `codex/p1-hardening-20261009`; su comparación
  remota con `relanzamiento-2026` (`bc15f2c`) indica 3 commits adelante, 0 atrás
  y cambios P1 en aplicación, migraciones y pruebas. El fetch por Git falló por
  el proxy de este entorno; no se confirmó SHA remoto exacto ni identidad del
  árbol local completo contra ese head.
- En rama local `codex/p1-maestro-activation-20261009`, basada en el candidato
  P1 `ecdf0a3`, ejecuté `npm run validate:p1:app-local`: PASS. Incluye Node
  operacional 4/4, Node financiero 1/1, TypeScript PASS y build Next.js PASS
  con 11/11 páginas. La compilación usó URL y clave pública ficticias bajo
  `example.invalid`; no prueba Supabase, Auth ni conectividad.
- La suite SQL no se ejecutó. En este entorno no están disponibles Docker,
  Podman, `psql`, `pg_restore`, Supabase CLI ni el baseline de pruebas. Hay 30
  archivos SQL versionados en esta rama; la matriz de aceptación disponible
  enumera 24 IT bajo P01 y no encontré un artefacto independiente que enumere
  los 59 escenarios citados para reportarlos individualmente. No se inventaron
  resultados ni se aplicaron migraciones.
- Se agregó un runner de aplicación local repetible y un workflow GitHub
  `pull_request` limitado a `relanzamiento-2026`, sin secretos, SQL,
  despliegue ni conexión a Supabase. El workflow no se publicó ni ejecutó.
  El repositorio es público y usa `ubuntu-latest`; GitHub documenta esos
  runners estándar como gratuitos en repositorios públicos. El historial
  muestra una ejecución previa de Actions (06-10), pero esta conexión no pudo
  leer la política actual de habilitación del repositorio.
  No hay continuidad automática persistente activa.
- P1/M03–M05 sigue **PARTIAL**. Ningún criterio formal se cambió a PASS. P2–P7
  no se iniciaron.

## Paquetes

- P1 DOC03–05: PARTIAL. Falta validación SQL sobre baseline autorizado y la
  ejecución/evidencia individual de 59 escenarios; E2E administrado según alcance.
- P2 DOC08–09: código y evidencia local parcial; aceptación integrada por
  criterio pendiente.
- P3 DOC13 DOTS: FALTANTE según la matriz vigente. Se puede avanzar con
  capacidades aisladas y sintéticas antes de P4; contexto real necesita E1 y
  las métricas oficiales esperan BI/E4. Acciones integradas siguen gated por
  E1, E2, E4, E5 y los permisos del módulo propietario.
- P4 DOC07 BI: FALTANTE según la matriz vigente.
- P5 Finanzas Gerencial: DOC19 es el espacio de consolidación (especialmente
  fase 1). DOC08 §§46–50 aporta los hechos comerciales fuente y la regla de que
  Finanzas consolida su impacto; DOC12 §0/§3 y Tabla 11 (ACC-FIN-001–008) son
  criterios de prueba, no una segunda especificación funcional. Hay componentes
  y pruebas, pero no aceptación global.
- P6 DOC19 Centro Ejecutivo/ULi: PARTIAL/PENDING por fases y dependencias; no
  equivale a la vista financiera existente.
- P7: requisitos y módulos restantes DOC00–19, rastreados antes de ejecución;
  aceptación DOC12 incompleta.
- Transversal DOC01/02/11/12: seguridad, permisos, ownership y aceptación
  gobiernan todos los paquetes.

Fuentes: docs/relaunch/MODULE_COVERAGE_00_19_2026-10-08.md,
docs/relaunch/RELEASE_CLOSURE_PLAN_00_19_2026-10-08.md y el registro oficial
acceptance/REQUIREMENTS_TRACEABILITY_00_19_2026-10-08.csv. No cambia estados
formales de criterios.

## Entorno y automatización

- Node/npm y dependencias existentes. Node operations tests, TypeScript y build
  pasaron con variables públicas ficticias para el build; eso no valida
  conectividad, Auth, RLS ni E2E.
- El checkout contiene 30 pruebas SQL versionadas; SQL NO EJECUTADO en este
  entorno, sin PostgreSQL/psql/Docker/Supabase CLI/baseline disponible.
- Hay workflow de backup en .github/workflows/phase0-supabase-backup.yml; no se
  ejecutó y no es CI de pruebas. No se verificó facturación de Actions.
- Se preparó localmente `.github/workflows/p1-app-checks.yml`, disparo manual
  únicamente, sin secretos ni acceso remoto. No se publicó ni ejecutó. No se
  observó CI de tests activos ni se verificaron reglas de protección de ramas;
  no se modificaron ajustes externos. El cupo de Actions sigue sin verificar.
- No hay lockfile versionado. No se instaló o actualizó dependencia por esta
  preparación.
- Staging Supabase separado, baseline autorizado y E2E Auth/Storage/MFA/sesiones
  siguen pendientes de confirmación/ejecución.

## Git y publicación

Checkout de esta sesión: /workspace/scratch/b96fa0074e66/equantum-relaunch.
Rama actual: codex/p1-maestro-activation-20261009, derivada localmente de
codex/p1-hardening-20261009. Cambios de esta activación aún sin publicar; no
hubo push, merge ni deploy. La PR #2 del protocolo está abierta en borrador,
pero su head remoto difiere del commit local de protocolo. No se tocó main,
Vercel ni Supabase remoto.

## Siguiente paso

Daniel y Derlis revisan y aprueban/corrigen el protocolo y el orden de paquetes.
Luego continuar P1 con baseline local autorizado y evidencia por escenario. No
iniciar P2 automáticamente.

## Resguardo de herramientas de laboratorio — 2026-10-10

Después de la anotación histórica anterior, los seis archivos actuales de
preparación se publicaron como commits de revisión en la rama
`codex/p1-test-lab-review-20261010`, basada en la candidata P1 remota
`codex/p1-maestro-activation-20261009` (`43714c65204eaf796adab3094e44e6ccf234603c`).
PR #5 está abierta como Draft hacia esa candidata. Incluye únicamente este estado,
`WORKLOG.md`, el baseline de estructura, el preflight, el smoke test y el CSV
original de 59 casos. No se integró la PR #3 ni se hizo merge.

Verificaciones de esta ejecución: `git diff --check` PASS; `bash -n` del
preflight PASS; el CSV conserva 59 IDs auxiliares únicos y 59 estados
`PREPARADO — NO EJECUTADO` (SHA-256
`02f2cbf9cc399ef826cd170009104a685361affa638bc48cb09b11898aff5441`). Se
ejecutó el smoke test actualizado contra `rqisyolaffwktxhjwpqq`: BLOQUEADO,
como corresponde, porque falta el trigger Auth
`on_auth_user_created → public.handle_new_user()`. Las pruebas de actor siguen
NO EJECUTADAS. El checkout local conserva sus cambios sin commit; la rama de
revisión fue creada separadamente mediante GitHub.

## P1 — trigger Auth, ACL de laboratorio y primera ejecución de escenarios — 2026-10-10 UTC

- Confirmé antes de escribir el ref de destino `rqisyolaffwktxhjwpqq` (`equantum-p1-pruebas`, PostgreSQL 17.11). No se ejecutó ninguna escritura en `eQuantum Equipo` (`oujrahzvljdhzqsdyujh`).
- Causa confirmada del trigger ausente: la función `public.handle_new_user()` estaba presente, pero no existía un trigger homónimo en `auth.users`; el baseline de estructura no reconstruyó el trigger.
- Se aplicó en el test target la migración idempotente `p1_auth_user_profile_trigger_v1` (historial `20261010182514`). No reemplaza un trigger con otro destino ni habilita silenciosamente uno desactivado. Después se verificó que `on_auth_user_created` está habilitado y llama exactamente a `public.handle_new_user()`.
- Se ejecutó `supabase/tests/p1_auth_user_profile_trigger_v1.sql` contra el test target: PASS estructural. La llamada real del trigger durante creación Auth permanece NO EJECUTADA hasta crear cuentas ficticias mediante Auth Admin API; no se insertó en `auth.users`.
- `supabase/tests/security_rls_v3.sql` también pasó contra el target luego de retirar solo la directiva de cliente `psql` no aceptada por MCP; comprobó la policy Storage, las 12 tablas V2 con RLS y sus policies. `supabase/tests/p1_anon_role_access_v1.sql` pasó con el rol `anon` y ROLLBACK.
- En `client_legacy_services`, RLS estaba activo/sin políticas pero `anon` y `authenticated` tenían `TRUNCATE` efectivo. RLS no protege TRUNCATE. Se aplicó en el test target la revocación mínima `p1_revoke_legacy_service_truncate` (`20261010182831`). Verificación posterior: anon=false, authenticated=false; service_role conserva el valor preexistente. Producción no se inspeccionó ni modificó en esta acción; no se extrapola el ACL del laboratorio a producción.
- Se prepararon en el test target únicamente privilegios bajo policies existentes: `authenticated` obtiene SELECT/INSERT/UPDATE en Followups y Radar, SELECT/INSERT en task_events; no recibe DELETE ni UPDATE de task_events y anon no recibe acceso. Para el script de fixtures, service_role obtiene SELECT de profiles/user_permissions y clients/client_portal_users, INSERT/DELETE solo en clients/client_portal_users y UPDATE de columnas concretas `profiles.active`, `user_permissions.view_all_tasks/view_own_tasks`. No hay GRANT ALL ni se desactivó RLS. La repetición verificable está en `scripts/relaunch/p1-test-lab-actor-acl.sql`.
- Historial de cambios test-only vía MCP: `20261010183105 p1_minimum_actor_acl`, `20261010183426 p1_fixture_profile_verify_read`, `20261010183555 p1_auth_fixture_scoped_acl`. Son ACL de laboratorio, no migraciones de producto; el helper SQL versionado conserva sus comandos acotados. Mantener el target de pruebas aislado.
- `P1-ANON-ROLE-AUTH`: PASS acotado en `supabase/tests/p1_anon_role_access_v1.sql`. Bajo `SET LOCAL ROLE anon`, el RPC de transición y SELECT de tasks fueron rechazados por `insufficient_privilege`; terminó con ROLLBACK. Es prueba de autorización PostgreSQL, no E2E de JWT/HTTP.
- El preflight de fixtures mostró solo conteos en el test target: `auth.users=0`, profiles/clients/tasks/tickets/followups/radar_items=0. No se crearon residuos.
- `test-project-schema-smoke.sql` fue re-ejecutado: BLOQUEADO correctamente porque falta el bucket privado `ticket-attachments`. El CSV de 59 casos no contiene casos de Storage; Storage sigue siendo una dependencia separada del conjunto.
- Resultado del CSV actualizado por ID: 1 PASS acotado (`P1-ANON-ROLE-AUTH`), 57 BLOQUEADOS por faltar usuarios Auth sintéticos y fixtures, 1 NO EJECUTADO (`P1-POSTROLLBACK-CLEAN`, que corresponde al teardown después del lote). Los otros 57 escenarios requieren actor Auth y datos de aplicación aislados; `P1-AUTH-PORTAL` requiere además mapping Portal. No hay un escenario Storage entre los 59.
- `scripts/relaunch/p1-auth-fixtures.mjs` prepara seis identidades ficticias por Auth Admin API: responsable interno, par interno no autorizado, lector con view_all_tasks, interno inactivo, Portal A y Portal B. Verifica el perfil/permisos creados por trigger, asigna flags de prueba estrechos, crea dos clientes sintéticos y mappings Portal; limpieza borra usuarios mediante Admin API (nunca DML en auth.users) y clientes sintéticos, con state file fuera del repo, modo 0600. El script está preparado pero no ejecutado porque esta sesión no tiene la clave service_role del test project; no solicitarla por chat.
- Regresión local `npm run test:operations`: PASS (4/4 casos Tareas/Triage/Radar y 1/1 caso financiero). `node --check` de fixture Auth y `bash -n` del preflight/runner: PASS. No se repitió build porque no hubo cambios de app.
- La configuración privada también restringe TRUNCATE en el test target. El bucket privado y sus policies INSERT/DELETE siguen ausentes; ningún archivo fue subido.
- Suite SQL completa y 59 escenarios funcionales: NO EJECUTADOS/BLOQUEADOS mientras no haya Auth fixtures. P1/M03–M05 sigue PARTIAL. PR #3 permanece sin integrar y PR #5 permanece abierta como revisión; no se hizo merge ni despliegue.

## Resguardo de herramientas de laboratorio — 2026-10-10

Después de la anotación histórica anterior, los seis archivos actuales de
preparación se publicaron como commits de revisión en la rama
`codex/p1-test-lab-review-20261010`, basada en la candidata P1 remota
`codex/p1-maestro-activation-20261009` (`43714c65204eaf796adab3094e44e6ccf234603c`).
PR #5 está abierta como Draft hacia esa candidata. Incluye únicamente este estado,
`WORKLOG.md`, el baseline de estructura, el preflight, el smoke test y el CSV
original de 59 casos. No se integró la PR #3 ni se hizo merge.

Verificaciones de esta ejecución: `git diff --check` PASS; `bash -n` del
preflight PASS; el CSV conserva 59 IDs auxiliares únicos y 59 estados
`PREPARADO — NO EJECUTADO` (SHA-256
`02f2cbf9cc399ef826cd170009104a685361affa638bc48cb09b11898aff5441`). Se
ejecutó el smoke test actualizado contra `rqisyolaffwktxhjwpqq`: BLOQUEADO,
como corresponde, porque falta el trigger Auth
`on_auth_user_created → public.handle_new_user()`. Las pruebas de actor siguen
NO EJECUTADAS. El checkout local conserva sus cambios sin commit; la rama de
revisión fue creada separadamente mediante GitHub.
