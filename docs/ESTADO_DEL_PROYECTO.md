# Estado del proyecto — EQ Relanzamiento 2026

Actualizado: 2026-10-10 UTC. Resumen de trabajo local; no representa producción.

## Resumen

P1/M03–M05 tiene implementación candidata de Tareas, Triage y Radar, pero sigue
PARTIAL. El esquema de prueba fue reconstruido y las 24 migraciones del runner
están aplicadas en `eQuantum P1 Pruebas` (25 registros de historial: 1 baseline
estructural y 24 migraciones versionadas). La verificación actual encontró que
el trigger de Auth y el bucket/las políticas de escritura de Storage no están
reproducidos en ese proyecto. El archivo de 59 escenarios recuperado contiene
59 IDs únicos, todos `PREPARADO — NO EJECUTADO`; no representa aceptación formal.
Esto no valida producción.

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
