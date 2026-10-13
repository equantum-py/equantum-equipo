# Bitácora técnica — Codex / EQ 2026

Entradas cronológicas. Registrar hechos, no secretos ni datos personales. No
borrar historia; agregar una entrada correctiva si un hecho cambia.

## 2026-10-13 UTC — verificación de PR #8 y cierre del candidato de Prospectos

- Checkout `/workspace/scratch/b96fa0074e66/equantum-crm-review`, rama
  `codex/crm-prospects-menu-20261013`, HEAD local `03eabb9`. Los commits locales
  `5acec3f` y `195adea` siguen en la cadena, junto con `54e1dce` (candidato
  funcional DOC08) y `03eabb9` (manifiesto de la fuente). Árbol limpio al
  iniciar este registro. En este checkout no hay stash; no se borró ni alteró
  ningún stash del otro entorno.
- GitHub PR #8 está abierta en borrador, no integrada, mergeable en la última
  lectura: head `5cb579ad72164aeb47bb88785e109e6d3cc4e56e`, base
  `relanzamiento-2026` (`d7e6c1cdd8366333380a459fb069a3c91ab73c56`). Conserva
  la entrega acumulada y el DOCX oficial DOC08 v1.1 queda preservado por SHA-256
  en el commit local; el PR contiene el manifiesto, no el archivo binario.
- GitHub Actions, workflow run `38455348855`, job `115496530588`, terminó
  `success`. Pasaron instalación de dependencias y el script
  `validate:p1:app-local`, que ejecuta pruebas Node, TypeScript y build Next.js
  con valores Supabase no enrutables. Esto resuelve la verificación de build en
  CI; no demuestra integración con Supabase ni aceptación funcional DOC08.
- El check de Vercel del SHA de PR #8 pasó a `success`. No se pudo obtener el
  hostname de Preview: la consulta de deployments devolvió 403 `forbidden`.
  No se abrió el navegador contra la Preview ni se hizo E2E visual; no se
  inventa una URL ni se afirma que la Preview se verificó.
- No se aplicó la migración
  `20261013180000_commercial_prospect_workflow_v1.sql`. Sigue requiriendo
  revisión independiente de permisos/RLS; no se conectó a Supabase, no se
  usaron usuarios administrativos como actores y no se modificó producción.
  Los SQL/Auth E2E continúan sin ejecutar.
- Integridad: DOC08 conserva su versión 1.1 y hash verificado; el CSV P1
  conserva los 59 IDs y bytes originales. El índice conjunto mantiene 401 IDs
  formales + 59 P1 + 42 DOC08 (502 filas únicas). Ningún resultado formal se
  cambió a PASS por la compilación CI.
- Estado de aceptación: 401/401 formales, 59/59 P1 y 42/42 DOC08 aún no tienen
  PASS funcional registrado en esta ejecución. La implementación del primer
  flujo Prospecto→Radar→Oportunidad está codificada, pero no demostrada con
  sesión Auth real ni base de laboratorio.
- Estimación para cerrar este primer flujo, no para todo DOC08: 3–7
  persona-días después de revisión autorizada, condicionados a que el contrato
  de autorización pase revisión y el hostname protegido de Preview sea
  accesible. Incluye revisión/fixes de SQL, ejecución de negativos y positivos
  Auth/RLS, E2E del flujo y evidencia por escenario. No se convierte a fechas:
  no hay capacidad semanal confirmada en los documentos.

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
## 2026-10-13 UTC — menú y lectura de Prospectos

- Rama local aislada: `codex/crm-prospects-menu-20261013`, basada en HEAD
  `27a3d86` (`codex/p1-maestro-activation-20261009`). El checkout original y
  sus cambios sin commit permanecen intactos.
- Se agregó la sección “Ventas”, con Prospectos y Clientes debajo. El acceso del menú
  se consulta con `is_internal_user()`; RLS sigue siendo la autoridad real.
  La pantalla es de consulta y muestra errores de acceso explícitamente, sin
  presentar un rechazo como lista vacía. Alta, edición, calificación y
  conversión quedan señalizadas como no disponibles.
- `clients` y `prospects` reciben solamente `GRANT SELECT` para
  `authenticated` en una migración nueva, que exige RLS y las políticas de
  lectura interna ya existentes. No concede escritura ni acceso financiero.
  La pantalla Clientes oculta las acciones de edición/alta a perfiles que no
  sean admin/Master y distingue error de lista vacía; RLS sigue controlando
  las operaciones de base.
- Se añadió `supabase/tests/clients_prospects_read_contract_v1.sql` para
  comprobar RLS, políticas internas y lectura, y que Prospectos no reciba
  privilegios de escritura. **El test SQL no se ejecutó** porque no se conectó
  una base en esta sesión.
- Verificación ejecutada: `npm run test:operations` PASS (4 tests operativos
  y 1 financiero); `npm run build` PASS con URL/clave pública ficticias de
  build; `git diff --check` PASS. No se usó la clave real ni se conectó a
  Supabase.
- No se aplicó la migración, no se tocó producción o test remoto, no hubo
  push, PR, deploy ni merge. Oportunidades/Ventas financieras no se exponen en
  este primer tramo; sus políticas existentes no se modificaron.

## 2026-10-13 UTC — corrección DOC08 y seguridad Clientes/Prospectos

- Repo `/workspace/scratch/b96fa0074e66/equantum-crm-review`, rama
  `codex/crm-prospects-menu-20261013`; HEAD antes de este cambio `4dadd1d`.
  Los stash del otro checkout no se consultaron ni modificaron.
- Fuente funcional revisada directamente: DOC08 v1.1, §§4, 6–18, 22, 58,
  60–66 y 80. No se cambió nomenclatura P1–P7.
- Verificación en Supabase de pruebas `rqisyolaffwktxhjwpqq`: la migración
  `clients_prospects_read_grants_v1`, registrada como versión `20261013155753`,
  concede solo SELECT a authenticated en `clients` y `prospects`. Metadatos
  actuales: RLS activa; SELECT de anon denegado; INSERT/UPDATE de authenticated
  denegados en esas tablas y `commercial_entities`. `commercial_entities` ya
  conserva su policy de lectura interna. No se hizo escritura adicional.
- Policies confirmadas: Prospects SELECT interno; Commercial Entities SELECT
  interno; Clients SELECT interno y lectura Portal limitada a
  `id = portal_client_id()`, además de la policy admin-write existente. Las
  policies no sustituyen los GRANT; ambos controles están activos. El rol
  Portal y anon no se probaron mediante sesiones reales en esta sesión.
- Cambios locales: Prospectos etiqueta 42501/consulta/error técnico y permite
  reintentar; Clientes deja de permitir alta/edición de la tabla heredada,
  indica que la activación depende de venta más condición económica/documental,
  y distingue datos legados de identidad canónica pendiente. El indicador
  general “Sistema operativo” se reemplazó por “Vista privada”.
- Se generó `docs/relaunch/acceptance/DOC08_SCENARIOS_42_TRACEABILITY.csv` a
  partir de los 42 casos originales de §80. La revisión fue estática; ningún
  caso se marca probado con base en tablas o funciones solamente.
- Limitación vigente: el laboratorio carece de INSERT/UPDATE para el flujo de
  Prospects. Crear ese flujo de forma atómica y con deduplicación requiere
  revisión independiente de funciones/policies/grants y prueba con actores
  Auth reales. No se añadieron privilegios ni se alteró RLS en esta sesión.
- Pruebas locales: `node scripts/relaunch/task-triage-radar.test.cjs` PASS
  (4/4); `git diff --check` PASS. La prueba `finance-summary.test.cjs` no pudo
  iniciar (`Cannot find module 'typescript'`). `npm install --no-package-lock`
  quedó esperando en la red restringida y se canceló; no se generó lockfile ni
  se añadieron dependencias. Build NO EJECUTADO.
- No se usó Preview, push, PR, merge, deploy o Producción. DOC08 permanece
  PARCIAL; la matriz registra 42 casos de §80: 2 BLOQUEADOS por el contrato de
  escritura pendiente de revisión, 32 PARCIALES y 8 NO IMPLEMENTADOS. Ninguno
  de los 42 se marcó como prueba funcional ejecutada.
## 2026-10-13 UTC — consolidación de control DOC00–19

- Checkout `/workspace/scratch/b96fa0074e66/equantum-crm-review`, rama
  `codex/crm-prospects-menu-20261013`, HEAD `5acec3f`. Estado limpio antes de
  editar el resumen; no se hicieron cambios remotos, despliegues ni acciones
  sobre Producción. La consulta de refs PR #3/#5/#6/#7 mediante `git ls-remote`
  fue bloqueada porque el proxy de red del entorno no estaba disponible; por
  eso no se afirma su estado actual.
- Se agregó `docs/relaunch/CONTROL_STATUS_00_19_2026-10-13.md` como resumen
  único de módulos, P1–P7, E0–E8, evidencias, riesgos, ownership de contratos,
  candidato de piloto y estimación restante. `ESTADO_DEL_PROYECTO.md` apunta al
  resumen; matrices y auditorías originales se conservan como registros fuente.
- Conteo reproducido desde `REQUIREMENTS_TRACEABILITY_00_19_2026-10-08.csv`:
  401 IDs (361 ACC, 24 IT, 16 INT), formalmente NO EJECUTADOS; clasificación
  de auditoría: 44 implementados sin verificar, 49 bloqueados por staging,
  308 faltantes. Conteo de DOC08 §80: 42, clasificados 2 bloqueados,
  32 parciales y 8 no implementados; evidencia estática, cero pruebas
  funcionales registradas.
- Evidencia técnica local disponible: operaciones 4/4 PASS; la conversación
  previa registra 17 comprobaciones SQL Tasks/Radar PASS con ROLLBACK, pero no
  por ID formal. El test SQL de contrato Clientes/Prospectos sigue sin
  ejecución; falta prueba real Auth por rol/Preview posterior a la migración.
- Se identificaron reutilizables de P1, CRM, Finanzas e IA/DOTS. No se
  modificaron permisos ni reglas de negocio. `P1_SCENARIOS_59.csv` y el DOCX
  fuente DOC08 no están en este checkout. No se descarta esa evidencia; el CSV
  debe recuperarse de fuente versionada antes de mapearlo.
- Ownership propuesto: Seguridad/QA mantiene Auth/RLS y ledger DOC12; Operación
  mantiene dominios Task/Ticket/CRM y continuidad; Finanzas posee ledger,
  moneda/fiscalidad/comisión; BI posee semántica KPI/reportes; IA posee policy,
  runtime, memoria y observabilidad. Identidad canónica y contratos de eventos
  requieren owner nominal de datos/arquitectura. No hay asignaciones nominales
  ni dedicación real documentadas.
- Nueva estimación provisional: 61–109 persona-semanas restantes por F0–F7,
  basada en los gates abiertos y artefactos ya presentes. No es fecha ni
  compromiso: el repo carece de disponibilidad/velocidad real y estimaciones
  por escenario. El rango debe reestimarse después de F0 y 1–2 slices medidos.
- Validación de edición: conteos CSV con Python; `git diff --check` PASS. No se
  integró ninguna PR ni se cambió Producción.
# 2026-10-13 UTC — Prospectos DOC08 v1.1, candidato funcional

- Preservación local comprobada antes de editar: `195adea` desciende de
  `5acec3f`; no se borraron ni aplicaron stashes en este checkout. PR #3/#5/#6/#7
  se revisaron mediante GitHub; las cuatro siguen abiertas como borradores y
  ninguna fue integrada. La PR #7 es la base del menú/lectura.
- Recuperadas y verificadas la fuente oficial
  `docs/rectores/08_CLIENTES_Y_VENTAS_FINAL_v1.1_2026-10-06.docx` (SHA-256
  `7960c41c232179c9fcd065874783063fa743f6dd63fbb5f61b2bf57248db2450`) y la
  matriz P1 de 59 escenarios desde PR #5 (SHA-256
  `02f2cbf9cc399ef826cd170009104a685361affa638bc48cb09b11898aff5441`). Los
  IDs y estados originales de esos 59 casos no se modificaron.
- Se reemplazó la vista de solo lectura de Prospectos por un candidato de alta,
  edición, persona/empresa, origen, responsable opcional, necesidades múltiples,
  hechos separados de percepción, pausa/reativación, historial y próximo paso
  en Radar. La escritura usa una función transaccional en migración candidata;
  no se ejecutó en Supabase.
- La conversión a Oportunidad requiere estado `qualifying`, necesidad, próximo
  paso y confirmación humana; usa la función existente idempotente, conserva la
  identidad canónica y transfiere/actualiza Radar. Se revoca la llamada directa
  a la función antigua para que no se eluda la confirmación. No se cargan monto
  ni moneda financiera desde este MVP.
- RLS/grants propuestos son mínimos y Portal/anon quedan excluidos. La migración
  `20261013180000_commercial_prospect_workflow_v1.sql` permanece como candidata
  de revisión independiente; no se aplicó al laboratorio ni a Producción. Hace
  falta aprobación técnica de seguridad y Auth/RLS real antes de ejecutarla.
- `commercial_entity_contacts` cubre el modelo N:N, pero la UI de contactos y
  la activación de Cliente bajo condición económica/documental siguen
  pendientes. No se reinterpretó quitar el alta heredada como cumplimiento.
- Se agregó `supabase/tests/commercial_prospect_workflow_v1.sql`, con ROLLBACK,
  identidades sintéticas existentes y prueba de autorización, denegación,
  aislamiento Portal/anon, conversión idempotente, historial e integración de
  Radar. El script simula claims PostgreSQL; NO reemplaza tokens Auth reales y
  NO fue ejecutado.
- Matriz DOC08 conserva los 42 escenarios y actualiza solo los afectados por
  este candidato; los resultados formales de esta ejecución siguen
  `NO EJECUTADO`. Se generó el índice conjunto: 401 IDs DOC00–19 + 59 P1 + 42
  DOC08 = 502 filas, sin promover comprobaciones internas a aceptación.
- Pruebas ejecutadas aquí: `node scripts/relaunch/task-triage-radar.test.cjs`
  PASS 4/4; `python3 scripts/relaunch/build-acceptance-index.py` PASS con 502
  IDs; `git diff --check` PASS. TypeScript transpile syntax-only PASS con
  TypeScript 5.9.3 disponible en otro checkout. `tsc --noEmit`, Next build,
  SQL, Auth/browser y Preview E2E NO EJECUTADOS; dependencias/red/entorno de
  Supabase no están disponibles en este checkout.
- La estimación global 61–109 persona-semanas del corte anterior no se cambia
  por porcentajes subjetivos: no hay capacidad semanal ni velocidad medida. La
  parte que falta para aceptar este primer recorrido es comprobable pero está
  condicionada a revisión de seguridad, corrida de DB, CI/build y sesión de
  Preview con usuarios sintéticos.

## 2026-10-13 UTC — verificación correctiva del candidato DOC08

- Se preservaron sin reescritura los commits locales `5acec3f` y `195adea`;
  `195adea` desciende de `5acec3f`. No hay stash en este checkout. Las ramas
  remotas PR #3, #5, #6 y #7 se consultaron en GitHub y siguen abiertas en
  borrador. La rama de trabajo sigue aislada; no hubo merge, push ni cambio
  remoto en esta verificación.
- Inventario y fuentes: DOC08 v1.1 recuperado (SHA-256 verificado en
  `docs/rectores/SOURCE_MANIFEST.md`); CSV P1 conserva 59 IDs únicos y el hash
  original; el índice de aceptación se genera con 401 IDs DOC00–19 + 59 P1 +
  42 DOC08 = 502 IDs únicos. Los resultados de ejecución continúan
  `NO EJECUTADO`.
- Se añadió un candidato para alta/edición de Prospectos, identidad canónica,
  necesidades múltiples, responsable opcional, hechos y percepción separados,
  continuidad Radar, historial y conversión confirmada a Oportunidad. El
  formulario de Cliente Legacy permanece retirado como contención; la activación
  Cliente económica/documental y el recorrido completo de Clientes siguen
  pendientes conforme a DOC08. No se rebajó el alcance.
- La migración propuesta usa RPC acotadas y revoca escrituras directas de
  `authenticated` en Prospects/Commercial Entities. Por afectar privilegios,
  RLS y acceso a una función de conversión existente, permanece **solo para
  revisión**: no fue aplicada en Supabase ni probada con JWT reales. El SQL
  preparado simula claims bajo `SET ROLE`; esa prueba aún no se ejecutó y no
  equivale a E2E Auth.
- Verificación local: `npm run test:operations` pasó al usar las dependencias
  ya instaladas en el checkout vecino (tests operativos y prueba financiera).
  El índice pasó con 502 IDs y `git diff --check` pasó. Next.js compiló el
  código, pero el worker de validación de tipos terminó con código 1; el
  checkout no tiene sus dependencias instaladas ni lockfile y la ruta de
  módulos del checkout vecino no es compatible con el typecheck. Por tanto,
  el build completo se considera **bloqueado**, no PASS. No hubo validación SQL,
  Auth real, Preview ni deploy.
- Bloqueos actuales para aceptar este tramo: revisión independiente de la
  migración; typecheck/build reproducible en CI o checkout con dependencias
  propias; aplicación solo al laboratorio después de esa revisión; prueba
  funcional con token real de usuario autorizado, usuario interno no
  autorizado, Portal y anon; verificación de Preview. Sin evidencia de esos
  pasos, DOC08 y los 42 escenarios permanecen parciales/no probados.
