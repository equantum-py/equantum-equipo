# Bitácora técnica — Codex / EQ 2026

Entradas cronológicas. Registrar hechos, no secretos ni datos personales. No
borrar historia; agregar una entrada correctiva si un hecho cambia.

## 2026-10-09 UTC — Protocolo Maestro 2.0 preparado localmente

- Checkout: /workspace/scratch/b96fa0074e66/equantum-relaunch.
- Rama: codex/p1-hardening-20261009. Commits de trabajo local; no push/merge.
- Se creó la normativa 2.0, el plan P1–P7 según prioridades expresas, estado
  ejecutivo y esta bitácora. No se desarrollaron módulos ni se cambiaron datos,
  permisos, producción o Supabase remoto.
- El único AGENTS.md localizado fue el del checkout, que ya era provisional.
  No apareció una copia independiente en los adjuntos de esta sesión. Se
  enriqueció esa guía; Daniel/Derlis deben revisar el protocolo preparado.
- Documentos fuente inspeccionados: RELEASE_CLOSURE_PLAN E0–E8 y matriz de
  cobertura 00–19. P1–P7 aquí organizan prioridad, no alteran DOC00–19. P3
  DOTS queda limitado por DOC14–18; P4–P6 dependen de fuentes y gates del plan.
- Node operations, TypeScript y build con valores públicos ficticios constaban
  aprobados en esta sesión; no se repitieron por cambio documental. No equivalen
  a aceptación de módulo. SQL y 59 escenarios P1 siguen NO EJECUTADOS en este
  entorno.
- Automatizaciones comprobadas en checkout: scripts de pruebas locales y
  workflow de backup existente, no ejecutado. No hay CI de pruebas ni mecanismo
  de continuidad automática comprobado. Staging/base y branch rules requieren
  configuración externa. No se afirmará instalación por estar documentada.
- Decisiones: Daniel conserva autoridad empresarial; Derlis, la técnica crítica;
  ambos autorizan producción e irreversibles, conforme al encargo.
- Próximo gate: revisión de Daniel y Derlis. Después, validar P1 con baseline
  autorizado antes de iniciar P2.

## 2026-10-09 UTC — revisión de coherencia DOC08/DOC12 y DOTS/BI

- Fuentes comprobadas: DOC08 §§46–50; DOC12 §0/§3, Tabla 11 (ACC-FIN-001–008),
  Tabla 14 (ACC-DOTS) y Tabla 16 (ACC-BI); DOC13 §§0/3/5/16/27–35/43–47;
  DOC07 §§8/43/46/48/50/52; plan de cierre E0–E8 y registro oficial CSV.
- DOC08 figura correctamente en P2 como dueño del ciclo Clientes/Ventas y en
  P5 como fuente de los hechos económicos comerciales; DOC08 §50 dice que
  Ventas aporta hechos y Finanzas Gerencial consolida el impacto. DOC19 posee
  la consolidación financiera. DOC12 prueba los contratos —no crea reglas— y
  Tabla 11 contiene ACC-FIN-001–008; no es dueño del módulo financiero.
- La matriz oficial confirma localizadores ACC-FIN-001–008 en DOC12 Tabla 11.
  También conserva DOC12 Tabla 14 ACC-DOTS y Tabla 16 ACC-BI; no se alteraron
  IDs ni estados de aceptación.
- Dependencia DOTS corregida conceptualmente: DOC13 experiencia/contratos y
  pruebas con sintéticos pueden avanzar antes de P4. E1/DOC02/DOC11 es gate
  para contexto real; E4/P4 para métricas oficiales e integración BI; E5/DOC14–18
  y E1/E2 son gates de activación de acciones autónomas integradas (plan E6).
  DOTS no duplica NBA, Radar, Triage ni BI; ACC-DOTS-002/003/005 y ACC-BI-003
  respaldan estos límites.
- Archivos corregidos: docs/PROTOCOLO_MAESTRO.md, docs/PLAN_MAESTRO.md y
  docs/ESTADO_DEL_PROYECTO.md; esta entrada registra la revisión.
- Solo revisión documental: no se desarrolló código ni se ejecutaron tests.
  Pendiente: revisión/aprobación de Daniel y Derlis; P1 permanece PARTIAL.

## 2026-10-09 UTC — activación operativa supervisada sobre P1

- Checkout: `/workspace/scratch/b96fa0074e66/equantum-relaunch`.
- Rama inicial: `codex/protocolo-maestro-2-0`, HEAD `dd40cff`; árbol limpio.
  Sincronización de publicación: no ejecutada.
- GitHub PR #2 se consultó en modo lectura: abierta, Draft, mergeable, cinco
  documentos; head remoto `24316a6fe43d73e170aa18fa6741a360a12b78c8`, base
  `02eabdc195e60f8c2c6133af942d193c9c1cbb19`. El commit local `dd40cff` de la
  rama con el mismo nombre no coincide con el head remoto; no se publicó ni
  integró. No hubo ejecuciones de Actions asociadas al head consultado.
- GitHub muestra la rama `codex/p1-hardening-20261009`; comparación remota con
  `relanzamiento-2026` (`bc15f2c`) = 3 commits adelante, 0 atrás, con cambios
  P1 de app, migraciones y pruebas. `git fetch` falló con
  `Failed to connect to browser-proxy port 8889`; no se pudo confirmar el SHA
  exacto ni que el árbol P1 local completo coincida con esa rama remota.
- La guía raíz `AGENTS.md` instruye leer `docs/PROTOCOLO_MAESTRO.md` y
  `docs/PLAN_MAESTRO.md`. Fue revisada manualmente en esta tarea. No se pudo
  demostrar carga automática: la tarea comenzó en el directorio padre, fuera
  de la raíz del checkout; además la PR sigue sin integrar. Para una tarea
  futura, iniciar el contexto de trabajo en la raíz del repositorio o leer la
  guía explícitamente.
- Abrí rama local, sin efectos remotos:
  `codex/p1-maestro-activation-20261009`, basada en
  `codex/p1-hardening-20261009` (`ecdf0a3f0a49d5addbcb6e1a2f0c1073f389ed1c`).
  No modifiqué las ramas originales.
- Se añadió `scripts/relaunch/validate-p1-app-local.sh` y el comando
  `npm run validate:p1:app-local`. En esta ejecución: Node operacional 4/4,
  Node financiero 1/1, TypeScript PASS y build Next.js PASS (11/11 páginas).
  Build con `https://example.invalid` y clave placeholder; no hizo llamadas a
  Supabase. Ningún defecto reproducible apareció en estas pruebas; no se
  alteraron reglas funcionales P1.
- `bash -n scripts/relaunch/validate-p1-app-local.sh` y `git diff --check`:
  PASS antes de las actualizaciones finales de documentación.
- Se preparó `.github/workflows/p1-app-checks.yml` con `workflow_dispatch`
  solamente, permisos `contents: read`, sin secretos de Supabase, sin SQL,
  sin deploy y con guardia contra `main`. **No publicada ni ejecutada.** No
  existe evidencia de cupo Actions disponible; el historial indica que hubo
  un bloqueo por facturación. Para activarla falta confirmar ese cupo y
  publicar la rama en el flujo autorizado. No se instalaron dependencias en
  esta ejecución.
- SQL: **BLOQUEADO**. `docker`, `podman`, `psql`, `pg_restore` y Supabase CLI no
  están disponibles; el baseline aprobado tampoco está en este checkout.
  No se buscó ni accedió al Cloud Shell. No se aplicaron migraciones ni se
  tocó Supabase remoto. Las 30 pruebas SQL del checkout no se ejecutaron.
- La matriz formal registra 24 casos IT bajo P01, todos sin ejecución previa
  válida en esta sesión. El conjunto llamado “59 escenarios P1” no tiene en el
  checkout un manifiesto independiente ejecutable que permita reportar 59
  resultados individuales. Se conserva NO EJECUTADO; no se inventaron casos ni
  PASS. P1/M03–M05 sigue PARTIAL; P2–P7 no se iniciaron.
- Estado final antes del commit local: pendiente revisión final del diff. Sin
  push, merge, deploy, cambios a `main`, Vercel o Supabase.

### Cierre de registro — mismo ciclo

- La revisión final se completó: exactamente cinco archivos preparados,
  `git diff --cached --check` PASS y escaneo de patrones de secretos sin
  coincidencias. Se creó un commit local para este paquete; no se publicó.
- `git status --short` quedó limpio en
  `codex/p1-maestro-activation-20261009`. No hubo push, merge, despliegue ni
  cambios externos.

## 2026-10-09 UTC — corrección del disparador de P1 app checks

- Revisión encontró que el workflow manual filtraba `github.ref` como una
  rama normal. En eventos `pull_request`, GitHub usa una referencia
  `refs/pull/<n>/merge`; por eso ese filtro podía omitir el job.
- Se cambió a `pull_request` con destino exclusivo `relanzamiento-2026` y
  eventos `opened`, `synchronize` y `reopened`. Se limita además a ramas del
  mismo repositorio; no se usa `pull_request_target` ni se ejecuta código de
  forks. El permiso del token sigue siendo `contents: read`.
- Se conserva Node 24 y el script `npm run validate:p1:app-local`. El script
  ejecuta pruebas Node, TypeScript y build con URL/clave Supabase ficticias;
  no usa secretos ni se conecta con Supabase. SQL queda fuera.
- La sintaxis y la lógica de filtro se validaron localmente sin iniciar Actions.
  El workflow sigue sin publicar/ejecutar. GitHub informa que este repositorio
  es público y registra una ejecución previa de Actions el 2026-10-06. Sus
  runners estándar `ubuntu-latest` son gratuitos para repositorios públicos;
  esta conexión no permite consultar la política actual de habilitación.
- `package-lock.json` no existe; el job instala desde `package.json` sin
  generar lockfile. Es viable, aunque la resolución de versiones puede variar
  entre ejecuciones.
- Para usarlo falta autorizar publicar esta rama y abrir una PR hacia
  `relanzamiento-2026`; eso iniciará el check automáticamente. No se hizo
  ninguna acción externa.

## 2026-10-10 UTC — P1: verificación de pruebas y baseline administrado

- Checkout actual: `/workspace/scratch/b96fa0074e66/equantum-relaunch`;
  rama `codex/p1-maestro-activation-20261009`, HEAD `27a3d86`.
- Supabase de pruebas verificado por el conector: proyecto
  `rqisyolaffwktxhjwpqq`, `equantum-p1-pruebas`, `ACTIVE_HEALTHY`, PostgreSQL
  17.11. Confirmación de solo lectura: esquema `public` sin tablas de
  aplicación, políticas o funciones, y sin migraciones registradas. No se
  aplicaron cambios en esta sesión.
- Supabase de producción se consultó únicamente en metadatos autorizados. Su
  esquema de aplicación previo contiene 13 tablas, 4 enums, 8 funciones
  propias, 39 políticas, 3 triggers propios, 21 índices y 53 constraints.
  No se consultaron filas de negocio ni se copiaron datos.
- El repositorio disponible contiene las migraciones incrementales, pero no
  las migraciones originales que crean ese baseline. Por eso las migraciones
  versionadas solas no pueden crear el esquema inicial.
- Se detectó una diferencia relevante de ACL predeterminados: las tablas
  nuevas creadas como `postgres` reciben privilegios CRUD para roles API en
  producción, pero no en el proyecto de pruebas. Un intento anterior de
  preparar la réplica con `GRANT ALL PRIVILEGES ON ALL TABLES` fue bloqueado
  por revisión automática por ser demasiado amplio. No se intentó eludir el
  bloqueo ni se escribió al proyecto de pruebas.
- Validación local en este checkout: `npm run validate:p1:app-local` PASS,
  Node 5/5, TypeScript PASS, build Next.js PASS (11/11 páginas), usando URL y
  clave Supabase ficticias no enrutables. Esto no ejecuta SQL ni prueba
  conectividad/Auth/Storage.
- SQL P1: BLOQUEADO; no hay baseline en el proyecto de pruebas. Los 59
  escenarios: NO EJECUTADOS; no hay un manifiesto de 59 casos en el checkout
  disponible para asignar resultados individuales.
- Próximo paso requiere resolver la diferencia ACL en el baseline de prueba
  con privilegios mínimos, revisados por objeto y rol, o provisionar un
  baseline local autorizado. No copiar ACL amplios por defecto ni alterar
  producción. P1 y M03–M05 permanecen PARTIAL.

## 2026-10-10 UTC — P1: reconstrucción de esquema autorizada y avance SQL

- Corrección cronológica de la entrada anterior: después de esa anotación sí se
  escribió exclusivamente en el proyecto de pruebas `rqisyolaffwktxhjwpqq`.
  El proyecto se reconfirmó como `equantum-p1-pruebas`, PostgreSQL 17.11,
  `ACTIVE_HEALTHY`; nunca se escribió en `eQuantum Equipo`.
- Se leyó solo metadata de catálogos del proyecto original, sin consultar filas
  de negocio. El baseline reconstruido contiene 13 tablas, 4 enums, 8
  funciones, 39 policies, 2 triggers, 21 índices no respaldados por
  constraints y 53 constraints. Todas sus tablas tienen RLS habilitado.
- El archivo `scripts/relaunch/p1-test-only-baseline.sql` conserva únicamente
  la estructura; no contiene filas, UUIDs de usuarios, secretos ni objetos de
  Storage. No usa `GRANT ALL`, no deshabilita RLS ni muta los esquemas Auth o
  Storage administrados. Concede solo `EXECUTE` a `authenticated` para los
  cuatro helpers requeridos por las policies.
- La primera aplicación del baseline falló por crear una FK antes de la PK de
  `profiles`; la migración transaccional revirtió todo y se verificó cero
  objetos/migration records residuales. Se corrigió el orden de constraints y
  el baseline se aplicó correctamente con `p1_authorized_public_baseline_20261010`.
- Luego se aplicaron, en orden, 12 migraciones versionadas del runner:
  `20261006_model_data_v2_expand`, `20261006_identity_commercial_v2_data`,
  `20261006_catalog_pipeline_v2`, `20261006_proposals_sales_v2`,
  `20261006_active_services_projects_tasks_v2`,
  `20261006_security_permissions_v2`, `20261007_security_internal_boundary_v31`,
  `20261007_security_functions_v32`, `20261007_commercial_operations_v2`,
  `20261007_financial_core_v2`, `20261007_financial_operations_v2` y
  `20261007_sensitive_financial_permission_v2`.
- La siguiente migración, `20261007_radar_engine_v2.sql`, no pudo aplicarse:
  `supabase_apply_migration` devolvió tres veces
  `McpServerError: Invalid or expired requestState`. El historial y el catálogo
  confirman que no quedó aplicada parcialmente: no existen sus funciones ni
  trigger, y no se registró esa migración. No se usó SQL crudo como atajo para
  eludir el mecanismo DDL. Las 11 migraciones posteriores, incluidas las dos
  P1, quedan detenidas por orden hasta resolver este error del conector.
- Estado comprobado del proyecto de pruebas después de las 12 migraciones:
  30 tablas públicas, 43 policies, RLS habilitado en las 30, ninguna tabla
  pública sin RLS; el inventario de tablas informa cero filas en las 30 tablas
  públicas y `auth.users` también contiene cero usuarios. No se crearon
  usuarios ni fixtures persistentes.
- Permisos: no se agregaron permisos amplios. La equivalencia final de ACL de
  aplicación todavía no está comprobada porque la cadena no llegó a las
  migraciones de Radar/Tareas. Esa diferencia se mantiene como limitación; no
  equivale a una validación de permisos P1.
- Los archivos P1 de migración, tests y runner se compararon byte a byte con el
  HEAD `43714c65204eaf796adab3094e44e6ccf234603c` de la PR #3; coinciden. Se
  comprobó además que `tasks_permissions_v2.sql` y
  `tasks_granted_permissions_v2.sql` dependen de IDs preexistentes, por lo que
  no se ejecutaron en un proyecto vacío ni se copiaron identidades reales.
- No se encontró en el checkout ni en búsquedas del repositorio GitHub el
  inventario original de 59 escenarios. Los 59 quedan NO EJECUTADOS, sin
  fabricar casos o IDs.
- Preparación local: se agregó `scripts/relaunch/p1-test-target-preflight.sh`,
  verificador de solo lectura que rechaza una referencia distinta, un host
  distinto o una conexión que no sea PostgreSQL 17 con Auth/Storage presentes.
  `bash -n` y los casos de rechazo por referencia/URL ausente pasaron; no se
  probó una conexión `psql` porque esta sesión no recibió URL de base.
- `git diff --check` PASS. No se hizo commit, push, merge, ni operación sobre
  producción. P1 y M03–M05 siguen PARTIAL.
- Bloqueo activo: el conector debe permitir aplicar
  `20261007_radar_engine_v2` al proyecto de pruebas con su estado de solicitud
  válido. Después se puede continuar la cadena, preparar identidades y datos
  sintéticos transaccionales, ejecutar regresiones y recuperar el manifiesto
  auténtico de los 59 escenarios.

## 2026-10-10 UTC — P1: continuación tras recuperar el conector

- Se reconfirmó el proyecto destino antes de continuar: `equantum-p1-pruebas`,
  ref `rqisyolaffwktxhjwpqq`, PostgreSQL 17.11. No se modificó el proyecto de
  producción.
- El conector volvió a aceptar la migración `20261007_radar_engine_v2.sql`.
  Después se aplicaron en orden las 11 migraciones restantes, incluida
  `20261008120000_tasks_radar_workflow_v3.sql` y
  `20261008143000_p1_task_write_scope_archive_radar_v1.sql`. El historial del
  proyecto registra baseline + 24/24 migraciones versionadas.
- Se añadió y ejecutó `scripts/relaunch/test-project-schema-smoke.sql`:
  PASS en PostgreSQL 17.11; Auth y Storage administrados presentes; 34 tablas
  públicas; 71 políticas; 0 tablas públicas sin RLS. `supabase_list_tables`
  reportó cero filas en todas las tablas públicas y cero `auth.users`.
- Se comprobó la presencia/signatura de `transition_task_operational_status`,
  `archive_task`, `sync_followup_to_radar` y `upsert_radar_item`. Es una
  comprobación estructural, no ejecución de transiciones ni prueba RLS por
  actor.
- La regresión funcional P1 sigue BLOQUEADA: las pruebas necesitan identidades
  Auth sintéticas enlazadas a perfiles y registros base. La sesión no ofrece
  Auth Admin para crearlas y eliminarlas por la vía soportada; no se escribió
  directamente en `auth.users` ni se persistieron fixtures.
- Se volvió a buscar el inventario auténtico de 59 escenarios en el checkout y
  en GitHub sin encontrarlo. Resultado: 59/59 NO EJECUTADOS; se requiere el
  artefacto original para conservar IDs y trazabilidad.
- Security Advisors del proyecto de pruebas reportó una tabla sin policy
  (`public.client_legacy_services`), dos funciones con `search_path` mutable y
  13 funciones `SECURITY DEFINER` ejecutables por `authenticated`. No se
  modificaron: requieren revisión contra los contratos y no justifican cambios
  rutinarios dentro de este checkpoint.
- La comparación de `information_schema.role_table_grants` fue solo lectura y
  confirmó una diferencia ACL: producción concede privilegios CRUD amplios a
  `anon`, `authenticated` y `service_role` en las 13 tablas base. En el
  proyecto de prueba `authenticated` tiene un subconjunto explícito y `anon`
  no puede leer las tablas P1. No se copió el patrón amplio ni se usó `GRANT
  ALL`. Esa diferencia debe compensarse únicamente con privilegios puntuales
  dentro de la transacción de cada prueba que necesite llegar hasta la policy;
  los tests funcionales aún no se ejecutaron.
- El smoke check se amplió para comprobar presencia de las funciones P1
  `transition_task_operational_status`, `archive_task` y `upsert_radar_item`,
  del guard de mutaciones de tareas y del índice único de Radar activo. Se
  ejecutó otra vez: PASS. La prueba solo confirma estructura y prerequisitos.
- Se añadió `scripts/relaunch/test-project-schema-smoke.sql` para reutilizar
  el preflight estructural en paquetes siguientes. `p1-test-target-preflight.sh`
  sigue siendo la guardia de solo lectura del host/ref para conexiones directas.
- `git diff --check` y `bash -n` del preflight pasaron. Cambios locales sin
  commit ni publicación; P1 y M03–M05 continúan PARTIAL.

## 2026-10-10 UTC — P1: Auth, Storage, RLS efectivo y escenarios recuperados

- Rama/HEAD de esta sesión: `codex/p1-maestro-activation-20261009`,
  `27a3d86de56ea68e91c565d2ac6830b3b16fb6bf`. Se preservaron los tres cambios
  locales existentes (estado, worklog y scripts); sin commit/push durante la
  inspección.
- Destino de pruebas confirmado por conector: `rqisyolaffwktxhjwpqq`. La tabla
  `supabase_migrations.schema_migrations` registra 25 entradas: baseline de
  estructura más las 24 migraciones versionadas de la rama candidata.
- Trigger de Auth: `auth.users` en pruebas tiene cero triggers de usuario. Sí
  existe `public.handle_new_user()`. En producción, consultada solo en
  metadatos, existe el trigger habilitado `on_auth_user_created AFTER INSERT`
  que llama a esa función. El hash de la definición de la función coincide en
  ambos entornos: `d4064af0ab44adb36eb3f46a4151d5fe`. `rg` sobre migrations y
  scripts confirma que las 24 migraciones versionadas no crean ese trigger;
  el baseline de prueba crea la función, pero no el trigger. Causa: el objeto
  operacional de Auth quedó fuera del baseline/migrations, no un fallo parcial
  demostrado del runner. Corrección propuesta: migration idempotente que
  instala el trigger solo si falta, falla seguro ante un trigger homónimo que
  llame a otra función y fija `search_path = ''` manteniendo todas las
  referencias de la función cualificadas. No se cambió esquema en esta sesión.
- RLS efectiva inspeccionada en `pg_policies`, estado RLS, grants y funciones.
  Las políticas instaladas de tareas limitan lectura por asignación/scope,
  escritura por asignación o permiso explícito de reasignación, y bloquean
  transición directa por triggers/RPC. Historial aplica el alcance actual de
  la tarea. Portal usa `portal_client_id()` para acotar tickets, mensajes,
  cliente y mapping; mensajes Portal requieren `is_internal = false`. Son
  expresiones verificadas, todavía sin ejecución por dos JWT/actores ficticios.
- Limitación del test target: `authenticated` solo tiene privilegios de tabla
  para `tasks` (SELECT/INSERT/UPDATE) y `task_status_history` (SELECT), entre las
  tablas revisadas; no tiene CRUD directo en Tickets, mensajes, clientes,
  followups o Radar. Las policies existen pero no son alcanzables por el API
  sin privilegios de tabla. No se ampliaron. Para las pruebas usar grants
  específicos dentro de la transacción y verificar rollback, o una lista
  mínima versionada y aprobada para test; nunca `GRANT ALL`.
- Storage en el target: RLS está activo y existe la policy SELECT
  `ticket attachments read authorized`, condicionada al folder UID o usuario
  interno. No existe bucket `ticket-attachments` y no hay policies INSERT ni
  DELETE en `storage.objects`. La metadata de producción, leída sin registros,
  muestra políticas de INSERT y DELETE propios y una policy SELECT anterior de
  bucket completo; la migración V3 sustituye SELECT pero presupone INSERT/DELETE
  previas. No se modificó Storage en ninguno de los dos proyectos. A/B,
  enumeración, subida y eliminación siguen sin ejecutarse.
- Security Advisors de seguridad: (a) `client_legacy_services` con RLS y sin
  policies: el API role no tiene SELECT/INSERT/UPDATE/DELETE efectivos, así que
  no es un leak; ambos roles sí tienen TRUNCATE efectivo, privilegio que RLS no
  cubre y que debe revocarse mediante corrección versionada; (b) dos funciones
  invoker con `search_path` mutable, bajo riesgo inmediato porque los roles
  API no pueden crear objetos en `public`, corrección recomendada `SET
  search_path = ''`; (c) 13 funciones SECURITY DEFINER ejecutables por
  authenticated. Los RPC hacen checks de actor/scope y los helpers son
  requeridos por policies; revocación global rompería el contrato. Se mantiene
  revisión individual, con atención a `set_financial_info_permission` frente
  al gate M01. No se deshabilitó RLS ni se alteraron grants.
- Security Advisor no se trata como PASS global. Advisors de rendimiento
  recibieron una lectura también: las recomendaciones de índices no usados no
  son accionables en un proyecto sin carga; los avisos de FK sin índice y
  policies permissive son seguimiento de rendimiento/revisión, no se cambiaron
  dentro de P1.
- Se recuperó el CSV previo `FASE1_P1_casos_prueba.csv` fuera del checkout. La
  copia íntegra se guarda como
  `docs/relaunch/acceptance/P1_SCENARIOS_59.csv`, SHA-256
  `02f2cbf9cc399ef826cd170009104a685361affa638bc48cb09b11898aff5441`;
  validación local: 59 filas, 59 IDs únicos, todas
  `PREPARADO — NO EJECUTADO`. IDs auxiliares, no reemplazan ACC/IT/INT.
- Se reforzó `scripts/relaunch/test-project-schema-smoke.sql` para bloquear si
  falta el trigger Auth correcto, el bucket privado o una de las tres policies
  SELECT/INSERT/DELETE esperadas. El estado actual del laboratorio no cumple
  esos checks. El smoke anterior no verificaba estos objetos y por ello no
  certificaba ese aspecto.
- No se pudo crear un Auth user disposable y borrarlo mediante Auth Admin ni
  hubo conector Storage para provisionar el bucket. No se insertaron usuarios
  en `auth.users`, no se crearon objetos en Storage y no se ejecutaron tests
  por actor. La propuesta de migration de trigger/hardening y la configuración
  Storage permanecen para PR revisable; no fueron aplicadas.
- Plan P1–P7 revisado en `docs/PLAN_MAESTRO.md`: conserva DOC03–05, DOC08–09,
  DOC13, DOC07, finanzas DOC19, Dirección/ULi DOC19 y requisitos restantes con
  cierre DOC12. No se renombró, fusionó ni eliminó alcance; E0–E8 y sus gates
  permanecen iguales. M03–M05 continúan PARTIAL.
- Próximo gate: revisar en PR el baseline/preflight/smoke y CSV; luego habilitar
  el trigger de Auth y bucket/policies en el proyecto de pruebas mediante
  migración/procedimiento soportado, añadir el juego mínimo de grants
  transaccionales, y obtener una vía aprobada de crear/limpiar actores Auth
  ficticios. Entonces ejecutar tests SQL y clasificar los 59 escenarios uno
  por uno. PR #3 sigue draft y no se integró.

## 2026-10-10 UTC — P1: resguardo de laboratorio en PR #5

- Se verificaron los seis paths del paquete: `docs/ESTADO_DEL_PROYECTO.md`,
  este worklog, `docs/relaunch/acceptance/P1_SCENARIOS_59.csv`,
  `scripts/relaunch/p1-test-only-baseline.sql`,
  `scripts/relaunch/p1-test-target-preflight.sh` y
  `scripts/relaunch/test-project-schema-smoke.sql`.
- Validación local actual: `git diff --check` PASS; `bash -n
  scripts/relaunch/p1-test-target-preflight.sh` PASS; CSV 59/59 IDs únicos,
  todos `PREPARADO — NO EJECUTADO`, hash
  `02f2cbf9cc399ef826cd170009104a685361affa638bc48cb09b11898aff5441`.
  La búsqueda local de patrones comunes de secretos no encontró coincidencias
  en los seis archivos.
- El smoke test exacto se ejecutó contra el ref de pruebas
  `rqisyolaffwktxhjwpqq` y devolvió BLOQUEADO por ausencia del trigger
  habilitado `on_auth_user_created` hacia `public.handle_new_user()`. No se
  ejecutaron DDL, Auth Admin, Storage API ni fixtures.
- Se creó la rama `codex/p1-test-lab-review-20261010` desde el HEAD remoto de la
  candidata P1 `43714c65204eaf796adab3094e44e6ccf234603c`; se abrió Draft PR #5
  hacia esa candidata. La comparación remota informa exactamente seis archivos
  nuevos y seis commits; HEAD remoto
  `32b24aa6cb28ef96b21d4a7937f30221ad70f2f7`. No hubo merge y PR #3 permanece
  separada. Los cambios locales de esta sesión siguen sin commit en el
  checkout; el resguardo remoto se hizo por GitHub.
- `docs/PLAN_MAESTRO.md` se contrastó: se mantienen los nombres, orden y
  alcance P1–P7 y los gates E0–E8; no se cambió ni recortó la nomenclatura.
