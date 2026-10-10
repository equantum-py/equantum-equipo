# Inventario inicial de cobertura por módulo — eQuantum 2026

**Fecha:** 2026-10-08  
**Rama revisada:** `relanzamiento-2026`  
**HEAD revisado:** `2c0f3cd64e3b61b96a5e934c105d670474c90b7c`  
**`main` observado:** `c2b41570a5600a585c76ac77d798927e07549832`  
**Fuente funcional:** ZIP adjunto con los documentos rectores 00–19.  
**Fuente de implementación:** `docs/relaunch/IMPLEMENTATION_STATUS_2026-10-07.md`, árbol remoto del repositorio y registro versionado de aceptación.

## Cómo leer esta matriz

Es un inventario inicial para priorizar auditorías módulo por módulo, no una aprobación formal. Se basa en los estados y pruebas que el propio repositorio ya registra, más la inspección del árbol actual. Los módulos se auditan contra su documento rector cuando llegue su checkpoint. `PARCIAL` no equivale a PASS; `FALTANTE` recoge estados PENDING explícitos; las validaciones que requieren servicios reales permanecen pendientes/bloqueadas por ambiente. Los criterios ACC e IT/INT no se marcan ejecutados por aparecer relacionados con un test.

| # | Documento / módulo | Cobertura inicial | Evidencia existente en el repositorio | Brecha principal registrada |
|---:|---|---|---|---|
| 00 | Visión y principios | **PARCIAL (transversal)**; documento rector definitivo | Este checkpoint; los módulos propietarios existentes y el Documento 12 | La visión completa depende de módulos aún pendientes y de aceptación formal; M00 no es una función aislada |
| 01 | Arquitectura y seguridad | **PARCIAL** | `docs/relaunch/M01_ARCHITECTURE_SECURITY_REVIEW_2026-10-08.md`; Auth/RLS/MFA Master y restore PostgreSQL local registrados | Doble control Master, expiración por inactividad, MFA para permisos sensibles, audit log central, revocación remota de sesiones, salud/alertas y validación formal/externa siguen abiertos |
| 02 | Usuarios y permisos | **PARCIAL** | `app/admin/page.tsx`, políticas y pruebas SQL de permisos/RLS; estado de implementación | Ciclos de usuario, onboarding, alcance y administración sensible no están aceptados formalmente |
| 03 | Tareas | **PARCIAL** | Migraciones existentes más `20261008120000_tasks_radar_workflow_v3.sql`, UI de estados/contexto y test SQL versionado | Nueva migración/regresión no ejecutada en PostgreSQL en esta sesión; cierre de Proyecto, dependencias, historial visible y E2E siguen pendientes |
| 04 | Triage | **PARCIAL** | `20261007_triage_engine_v2.sql`, tests Golden existentes; dashboard ahora muestra razones/categorías humanas | Fórmula V2 sigue limitada a señales de Task; situaciones multiobjeto, doble conteo y override auditado pendientes |
| 05 | Radar y seguimiento | **PARCIAL** | Motor/vista existentes; nuevo enlace transaccional desde Task esperando y estados de salud en interfaz | SQL nuevo no ejecutado; notificaciones/background, eventos de Ticket, reconocimiento separado de cierre, escalamiento/capacidad y E2E pendientes |
| 06 | eQ asistente de decisión | **PARCIAL** | `app/api/ai/assistant/route.ts`, `lib/ai/assistant-handler.ts`, frontera financiera y pruebas locales | El estado oficial mantiene eQ completo como PENDING; falta comprobar capacidades de decisión autorizada de punta a punta |
| 07 | Business Intelligence | **FALTANTE** | El estado oficial lista BI V2 como PENDING; existen componentes/datos financieros que no equivalen a BI completo | Definiciones/KPI, reportes, hallazgos y aceptación de BI según Documento 07 |
| 08 | Clientes y ventas | **PARCIAL** | Migraciones comerciales, `CommercialWorkflow.tsx`, Golden comercial y flujo financiero/comercial | Quedan criterios de borde e integración del ciclo comercial por ejecutar; la cobertura de pruebas no sustituye ACC formal |
| 09 | Tickets | **PARCIAL** | Rutas Portal, migraciones de Tickets, test multi-Task y seguridad/RLS local | Sesiones reales Portal, notas internas y Storage administrado requieren E2E en staging |
| 10 | Chat interno | **FALTANTE** | Se preserva `chat_messages` legado; el estado oficial marca Chat V2 PENDING | Conversaciones, membresías, hilos y recorridos de chat del Documento 10 |
| 11 | Modelo de datos | **PARCIAL** | Migraciones V2/V3, reconciliación y tests; tablas/relaciones del núcleo existentes | Los contratos y extensiones transversales previstos deben auditarse contra el esquema real por módulo; no recrear ni duplicar fuentes |
| 12 | Criterios de aceptación | **PARCIAL** | Registros fuente, clasificación 361 ACC + 40 IT/INT y archivos de pruebas | El registro formal mantiene ejecuciones NO EJECUTADO; falta ejecutar, evidenciar y aprobar criterio por criterio |
| 13 | DOTS desarrollo | **FALTANTE** | El estado oficial lista DOTS PENDING | Copiloto de desarrollo, privacidad, onboarding/progreso y flujos conforme al Documento 13 |
| 14 | Orquestación de IA | **FALTANTE** | El estado oficial lista orquestación PENDING | Arquitectura/ejecución gobernada de flujos de IA conforme al Documento 14 |
| 15 | Memoria y conocimiento | **FALTANTE** | El estado oficial lista memoria/conocimiento PENDING | Fuentes, ciclo de memoria, permisos y recuperación conforme al Documento 15 |
| 16 | Gobernanza de IA | **FALTANTE** | El estado oficial lista gobernanza PENDING | Políticas, aprobaciones y controles de IA del Documento 16 |
| 17 | Evaluación y mejora continua de IA | **FALTANTE** | El estado oficial lista evaluación PENDING | Dataset, evaluación, métricas y ciclo de mejora del Documento 17 |
| 18 | Observabilidad de IA | **FALTANTE** | El estado oficial lista observabilidad PENDING | Telemetría, trazas, alertas y análisis de fallas del Documento 18 |
| 19 | Centro de Dirección Ejecutiva / Finanzas Gerencial | **PARCIAL** | `FinanceView.tsx`, `lib/finance/summary.ts`, contratos/SQL financieros y tests Node/SQL registrados | El estado oficial mantiene Centro Ejecutivo, ULi e indicadores financieros reales como PENDING; la base de Finanzas no equivale a ULi completo |

## Resultado de conteo

- **PARCIAL:** 12 módulos (00–06, 08–09, 11–12, 19).
- **FALTANTE:** 8 módulos (07, 10, 13–18).
- **IMPLEMENTADO integralmente:** 0 en esta matriz inicial. Esto no niega funciones ya aprobadas; indica que no se auditó aquí un módulo completo contra todos sus requisitos y aceptaciones.
- **BLOQUEADO por ambiente:** aplica a verificaciones externas concretas —por ejemplo Supabase Auth/Storage real y E2E—; se detalla por criterio, no reemplaza el estado de implementación del módulo.

## Checkpoint 00 — conclusión

El Documento 00 está consolidado y su función es gobernar decisiones en los demás módulos. No corresponde agregarle una implementación duplicada. La conformidad del producto queda PARCIAL mientras existan módulos pendientes y criterios formales sin ejecución. El módulo 00 queda auditado documentalmente en esta pasada; la validación de su cumplimiento es transversal y debe apoyarse en los checkpoints propietarios, sin repetir regresiones ya registradas.

**Siguiente acción:** esperar la indicación del usuario sobre cuál módulo auditar después. Este inventario no autoriza avanzar automáticamente.


## Checkpoint M01 — Arquitectura y seguridad — 2026-10-08

**HEAD de entrada:** `deac6bb0149bb008a523e085ae36505b20379849`; **main observado:** `c2b41570a5600a585c76ac77d798927e07549832`, sin cambios.  
**Estado:** M01 **PARCIAL**. M00 permanece **PARCIAL**.

Auditoría detallada: `docs/relaunch/M01_ARCHITECTURE_SECURITY_REVIEW_2026-10-08.md`.
Los criterios DOC12 relacionados continúan `NO EJECUTADO`; no se cambió su
clasificación ni se inventaron IDs. Este checkpoint fue documental: sin
checkout local ni PostgreSQL/Docker en la sesión, no se ejecutaron nueva
regresión ni build. No hubo cambios de código, esquema, permisos o datos.

## Actualización de trazabilidad y plan — 2026-10-08

La auditoría funcional de esta fecha amplía este inventario, sin reescribir
la evidencia histórica. Ver:

- `FUNCTIONAL_AUDIT_00_19_2026-10-08.md` — alcance, evidencia y brechas
  por DOC00–19, con foco en BI, DOTS/automatización y Centro Ejecutivo/ULi.
- `RELEASE_CLOSURE_PLAN_00_19_2026-10-08.md` — dependencias, camino
  crítico, trabajo paralelo, entregas, aceptación, cronograma y recursos.
- `acceptance/REQUIREMENTS_TRACEABILITY_00_19_2026-10-08.csv` — 401 filas
  exactas de ACC/IT/INT, sin aprobar por similitud ni marcar aceptación.
- `acceptance/SOURCE_SECTION_COVERAGE_00_19_2026-10-08.csv` — índice de
  los 20 DOCX y sus hashes/secciones principales.

La clasificación de módulos de este inventario describe cobertura funcional,
no aceptación formal. La matriz fuente de criterios mantiene `NO EJECUTADO`.

### Revalidación de Fase 1 — 2026-10-08

Se repitieron en el checkout local de `relanzamiento-2026`:

- `npm run test:operations`: PASS, 4/4 reglas operativas y 1/1 suite
  financiera.
- `npx --no-install tsc --noEmit`: PASS.
- Build Next.js con valores públicos ficticios y efímeros: PASS, 11/11
  páginas generadas; no es una prueba de conexión a Supabase.
- PostgreSQL 17.11 responde localmente, pero no hay dump baseline accesible
  y no existe `equantum_restore_clean`; por tanto la migración y los tests
  SQL de Fase 1 no se ejecutaron. Los 28/28 anteriores son evidencia
  histórica, no resultado de esta ejecución.

M03–M05 permanecen **PARCIALES**. El checkout conserva la migración y prueba
`tasks_radar_workflow_v3`; no se publican como validadas hasta ejecutar ambos
sobre un restore real del baseline del proyecto. Siguen abiertos los
requisitos indicados en las brechas de módulos 03–05 arriba.

#### P1 aprobado D1/D2/D4/D6 — ejecución actual 2026-10-08

El RPC y la interfaz implementan verificación de salida de ESPERANDO,
reapertura diferenciada, autorización explícita en base de datos e idempotencia
por estado esperado. Prueba Node 4/4, TypeScript PASS y build PASS con variables
públicas ficticias (11/11 páginas; sin conexión a Supabase). Los 59 casos
SQL siguen NO EJECUTADOS: esta sesión no dispone de PostgreSQL activo ni del
baseline autorizado. No se marca aceptación formal; M03–M05 siguen PARCIALES.
