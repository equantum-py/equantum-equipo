# Estado del proyecto — EQ Relanzamiento 2026

## Corrección de estado — 2026-10-13 UTC

La entrega de Prospectos está en la PR #8, abierta en borrador y sin integrar
(head `5cb579ad72164aeb47bb88785e109e6d3cc4e56e`). GitHub Actions completó con
éxito instalación, pruebas de aplicación, TypeScript y build Next.js. El check
de Vercel también figura `success`, pero no se recuperó el hostname de Preview
(API respondió 403) y no se ejecutó prueba desde navegador. Por tanto, esto
confirma CI, no un flujo operativo contra Supabase.

La migración de permisos de Prospectos no fue aplicada. La revisión de
seguridad independiente, la ejecución Auth/RLS real y el E2E
Prospecto→Asignación→Radar→Oportunidad siguen pendientes. El inventario
conjunto conserva 401 IDs DOC00–19, 59 IDs P1 y 42 IDs DOC08; no se marcó
ninguno como PASS a partir del build. Producción no se modificó.

Esfuerzo estimado del primer flujo verificable: 3–7 persona-días tras la
revisión del contrato de autorización, con incertidumbre en el extremo alto si
aparecen defectos. No hay capacidad semanal confirmada para traducir el
esfuerzo a calendario. La bitácora conserva la evidencia y los límites.

## Actualización — 2026-10-13 UTC

El corte detallado está en `docs/relaunch/CONTROL_STATUS_00_19_2026-10-13.md`;
la bitácora del nuevo candidato está en `docs/codex/WORKLOG.md`. Se recuperó
DOC08 v1.1 y el CSV original P1 de 59 casos con hashes verificados, y se
generó un índice conjunto que conserva los 401 IDs formales, los 59 P1 y los
42 escenarios DOC08 (502 filas). No se modificó ningún estado formal de prueba.

Está en desarrollo revisable un candidato de Prospectos con alta/edición,
identidad comercial canónica, necesidades múltiples, historial, asignación,
continuidad Radar y conversión humana e idempotente a Oportunidad. Su migración
de autorización/RLS aún no pasó revisión independiente ni se aplicó al
laboratorio. Clientes conserva la contención segura; el alta heredada no se
considera cumplimiento y la activación por condición económica/documental
sigue pendiente.

Verificación de esta ejecución: operaciones locales PASS al reutilizar
dependencias ya disponibles; sintaxis TypeScript TSX PASS; índice 502/502 y
`git diff --check` PASS. Next compiló, pero el worker de validación de tipos
terminó con código 1 por el entorno incompleto; el build completo no está
aprobado. SQL/Auth real y Preview NO EJECUTADOS; aceptación DOC08/P1 sigue sin
resultados. Producción no fue modificada. La entrega permanece local hasta
publicar una PR borrador revisable.

## 2026-10-13 — índice de control consolidado vigente

El resumen único de DOC00–19, P1–P7 y E0–E8 está en
`docs/relaunch/CONTROL_STATUS_00_19_2026-10-13.md`. Usar ese corte para el
estado integrado; las matrices CSV, la auditoría del 8-Oct y entradas
anteriores de este archivo siguen siendo registros fuente/históricos y no se
deben reinterpretar como aceptación nueva. La matriz formal conserva 401 IDs,
401 NO EJECUTADO; los 42 casos DOC08 §80 están inventariados, sin resultados
funcionales ejecutados. La estimación restante es provisional en esfuerzo; no
hay disponibilidad real del equipo para prometer calendario.

Actualizado: 2026-10-13 UTC. Resumen de trabajo local; no representa producción.

Nota: el resumen heredado de abajo conserva datos del corte del 9-Oct. Para
decisiones del corte actual, usar el índice de control del 13-Oct enlazado
arriba; no se eliminó la historia previa.

## Resumen

P1/M03–M05 tiene implementación candidata de Tareas, Triage y Radar, pero sigue
PARTIAL. Node operations, TypeScript y build pasaron en esta sesión; SQL y los
59 escenarios P1 no se ejecutaron aquí. Pruebas locales no acreditan aceptación
formal ni comportamiento de Supabase administrado.

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

## 2026-10-13 — corrección correctiva DOC08 en curso

- Documento rector revisado: `08_CLIENTES_Y_VENTAS_FINAL`, versión 1.1,
  2026-10-06. Se conserva el alcance y la numeración 00–19/P1–P7.
- En el laboratorio `rqisyolaffwktxhjwpqq` consta la migración
  `clients_prospects_read_grants_v1` (versión registrada
  `20261013155753`). Otorga solo `SELECT` a `authenticated` sobre `clients` y
  `prospects`; la consulta de metadatos confirma RLS activa, acceso anónimo
  denegado y ninguna escritura para `authenticated`. Las políticas SELECT
  internas existentes siguen requiriendo `is_internal_user()`; Clientes
  conserva además su política de portal para el cliente propio. No se probó en
  esta sesión una sesión real Auth de portal/interno/anon ni la pantalla
  protegida de Preview.
- Cambio local pendiente de revisión: Prospectos muestra errores de permisos,
  consulta y carga por separado, con reintento. Clientes queda en consulta:
  se quitó el alta/edición heredada que escribía solo en `clients`, sin crear o
  vincular la identidad canónica ni comprobar la condición de activación. La
  ficha identifica si `commercial_entity_id` está asociado y trata el estado
  como legado; no inventa historial.
- Se creó `docs/relaunch/acceptance/DOC08_SCENARIOS_42_TRACEABILITY.csv` con
  los 42 escenarios originales de DOC08 §80. Es una matriz de inventario
  estático; no declara escenarios funcionales como probados.
- Estado DOC08 continúa **PARCIAL**. Prospectos sigue sin alta/edición,
  asignación, necesidades múltiples ni seguimiento Radar funcional. No existe
  todavía una migración de escritura revisada y probada. La pantalla Preview no
  se verificó desde un navegador en esta sesión.
- Rama local `codex/crm-prospects-menu-20261013`, base anterior `4dadd1d`;
  cambios aún no committeados ni publicados. Producción sin cambios.
- Verificación local de este ajuste: prueba de Tareas/Triage/Radar 4/4 PASS y
  `git diff --check` PASS. La prueba financiera no pudo iniciar porque faltan
  dependencias (`typescript`); `npm install` quedó detenido por la red
  restringida. Build NO EJECUTADO. No se consultó la Preview desde navegador.
## 2026-10-13 — preparación revisable de Prospectos

- Se preparó en la rama local `codex/crm-prospects-menu-20261013` un primer
  ajuste de menú y lectura para Clientes/Prospectos, basado en el contrato RLS
  interno existente. La lista de Prospectos es solo de consulta; alta,
  calificación y conversión continúan sin UI en este cambio.
- Se preparó una migración con `SELECT` únicamente y una prueba SQL de contrato.
  No se ejecutaron contra Supabase. No hubo cambios en el proyecto de pruebas
  ni en Producción, despliegues o integración.
- Pruebas locales: `npm run test:operations` PASS; `npm run build` PASS con
  variables públicas ficticias; validación SQL NO EJECUTADA.
- Este cambio no altera la nomenclatura ni el alcance aprobado P1–P7 y no
  cambia el estado formal de aceptación de ningún criterio.
