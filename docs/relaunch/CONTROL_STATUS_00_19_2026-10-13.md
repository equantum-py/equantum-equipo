# eQuantum — resumen único de control DOC00–19 / P1–P7 / E0–E8

## Actualización de ejecución — 2026-10-13 UTC

- La rama revisable del candidato Prospectos está publicada como PR #8,
  borrador y sin merge (`5cb579ad72164aeb47bb88785e109e6d3cc4e56e` contra
  `d7e6c1cdd8366333380a459fb069a3c91ab73c56`). Los commits locales
  `5acec3f` y `195adea` se conservaron en la cadena de trabajo; no se reescribió
  ni se forzó ninguna referencia.
- Actions run `38455348855`, job `115496530588`: `success`, incluidos
  dependencias, `validate:p1:app-local`, TypeScript y build. El status de
  Vercel también está `success`; la API de Vercel devuelve 403 al listar esta
  Preview. No se pudo comprobar hostname ni ejecutar navegador E2E.
- DOC08 v1.1 y el CSV P1 (59 casos, contenido original) permanecen íntegros;
  el índice conserva 401+59+42 = 502 IDs. Estos son IDs inventariados, no 502
  resultados PASS. Los 401 formales, los 59 P1 y los 42 DOC08 siguen sin PASS
  funcional registrado para esta ejecución.
- La implementación del primer flujo comercial (Prospecto, asignación
  opcional, identidad canónica, historial, Radar y conversión confirmada e
  idempotente) está en el PR, sin prueba contra Auth/DB. La migración de
  autorización no se aplicó: falta revisión independiente. Tampoco se tocó
  producción.
- Estimación comprobable para cerrar solo este primer flujo después del gate
  de seguridad: 3–7 persona-días. La capacidad semanal no está registrada, por
  lo que no se presenta fecha de entrega. El rango total anterior de cierre
  00–19 sigue siendo provisional y no se reduce por un build CI.

El resto de este documento registra el corte de control previo y se conserva
como historial; los hechos de esta actualización prevalecen en los puntos
anteriores.

**Corte:** 2026-10-13 UTC
**Checkout observado:** `codex/crm-prospects-menu-20261013`
**HEAD de control:** `195adea` (`docs: consolidate eQuantum closure control status`);
el candidato funcional DOC08 está en el árbol de trabajo local, todavía sin
commit/publicación en esta instantánea.
**Ámbito:** consolidación de evidencia disponible; no constituye aceptación funcional, autorización de despliegue ni cambio de alcance.

## Resumen ejecutivo

- La matriz rectora conserva **401 IDs formales**: 361 ACC, 24 IT y 16 INT. En el registro, **401/401 figuran NO EJECUTADO**. La clasificación de auditoría es 44 IMPLEMENTADO SIN VERIFICACIÓN, 49 BLOQUEADO por validación administrada y 308 FALTANTE. Presencia de código o test no cambia ese estado. El CSV original P1 fue recuperado con integridad verificada: **59/59 NO EJECUTADOS**.
- Los **42 escenarios DOC08 §80** conservan IDs y texto. El estado de trazabilidad del candidato local es 4 IMPLEMENTADOS SIN PROBAR, 33 PARCIALES y 5 NO IMPLEMENTADOS; **0/42 pruebas funcionales ejecutadas**. No equivale a aceptación.
- Existen resultados técnicos acotados reutilizables: prueba local de Tareas/Triage/Radar 4/4 PASS; regresión SQL temporal de Tasks/Radar con 17 comprobaciones PASS y ROLLBACK, registrada en la conversación previa pero no vinculada a IDs formales; controles de lectura Clientes/Prospectos comprobados mediante metadatos en el proyecto de pruebas. Ninguno completa un criterio formal por sí mismo.
- Producción (`oujrahzvljdhzqsdyujh`) no fue modificada en este corte. La migración de lectura de Clientes/Prospectos registrada en el laboratorio es `20261013155753`, destino `rqisyolaffwktxhjwpqq`; requiere prueba con sesiones reales antes de aceptar aislamiento end-to-end.
- El checkout actual contiene una rama local de trabajo, no una rama publicada verificada. No se consultó el estado vivo de PRs ni se desplegó. La referencia `origin/relanzamiento-2026` observada en este repo está en `bc15f2c`; el candidato local está 12 commits por delante de esa referencia. No integrar automáticamente.

## Estado por módulo (nomenclatura original 00–19)

Los estados reproducen `MODULE_COVERAGE_00_19_2026-10-08.md`; el inventario estático no sustituye la verificación de cada criterio.

| DOC | Módulo | Estado registrado | Evidencia aprovechable / brecha principal |
|---|---|---|---|
| 00 | Visión y principios | PARCIAL (transversal) | Documentos de alcance y planes conservados; la visión depende de módulos y aceptación pendientes. |
| 01 | Arquitectura y seguridad | PARCIAL | Revisión M01, políticas y controles existentes; MFA, sesiones, auditoría central, revocación y validación formal siguen abiertos. |
| 02 | Usuarios y permisos | PARCIAL | Perfiles, permisos, RLS y pruebas SQL existentes; ciclo completo, onboarding y aceptación por rol pendientes. |
| 03 | Tareas | PARCIAL | Migraciones/UI y regresión aprovechable; 59 escenarios P1 no están trazados a resultado formal en este checkout; E2E e historial visible pendientes. |
| 04 | Triage | PARCIAL | Motor y pruebas locales existentes; señales multiobjeto, doble conteo y override auditado pendientes. |
| 05 | Radar y seguimiento | PARCIAL | Motor y continuidad desde Task; notificaciones, eventos Ticket, escalamiento y E2E pendientes. |
| 06 | eQ asistente de decisión | PARCIAL | Asistente legado y frontera financiera; no demuestra capacidades de decisión DOC06 de punta a punta. |
| 07 | Business Intelligence | FALTANTE | Contadores de dashboard no equivalen al catálogo KPI, calidad/frescura, drill-down, reportes y proyecciones DOC07. |
| 08 | Clientes y ventas | PARCIAL | Candidato local para alta/edición de Prospectos, necesidades, historial, asignación y Radar; migración de autorización pendiente de revisión independiente y aplicación solo al laboratorio. Oportunidades→Ventas→Clientes y activación económica/documental siguen pendientes. |
| 09 | Tickets | PARCIAL | Migraciones y pruebas existentes; Portal real, notas internas y Storage administrado requieren E2E. |
| 10 | Chat interno | FALTANTE | Chat V2 y sus recorridos no implementados. |
| 11 | Modelo de datos | PARCIAL | Fuentes/migraciones del núcleo; contratos transversales necesitan verificación por módulo. |
| 12 | Criterios de aceptación | PARCIAL | Registro 401 IDs disponible; todos siguen NO EJECUTADO y no hay runner que asocie resultados formales por ID. |
| 13 | DOTS desarrollo | FALTANTE | No hay agente/ciclo DOTS completo; sugerencias existentes no lo sustituyen. |
| 14 | Orquestación de IA | FALTANTE | Orquestador, herramientas, colas y reintentos gobernados no encontrados. |
| 15 | Memoria y conocimiento | FALTANTE | Captura, permisos, retención, búsqueda y borrado gobernados no encontrados. |
| 16 | Gobernanza de IA | FALTANTE | Políticas/registro de herramientas/aprobaciones y controles de IA no encontrados. |
| 17 | Evaluación y mejora continua IA | FALTANTE | Datasets, evaluadores, replay y métricas formales no encontrados. |
| 18 | Observabilidad de IA | FALTANTE | Trazas, costo, SLO, alertas y kill switch no encontrados. |
| 19 | Centro Ejecutivo / Finanzas Gerencial | PARCIAL | Finanzas/comercial base reutilizable; Centro Ejecutivo/ULi completo, ledger/cash y reporting no aceptados. |

## Control de paquetes P1–P7 y cierres E0–E8

| Orden | Estado comprobado | Qué falta para cerrar sin recortar alcance |
|---|---|---|
| P1 — DOC03/04/05 | PARCIAL | El inventario original de 59 casos ya está recuperado e íntegro; faltan precondiciones sintéticas, ejecución por actor/ID, escenarios administrados y aceptación. |
| P2 — DOC08/09 | PARCIAL | Candidato Prospecto→Oportunidad pendiente de revisión/ejecución. Completar Oportunidad→Venta→Cliente, activación económica/documental, Clientes Legacy, Tickets/Portal/Storage y ejecutar los 42 casos DOC08 §80 más DOC09. |
| P3 — DOC13 | FALTANTE | Se pueden preparar contratos/UX sintéticos; ejecución DOTS real espera identidad, gobierno y módulos propietarios. |
| P4 — DOC07 | FALTANTE | Definir owner/fórmula/fuente/corte para cada KPI y construir BI sin recalcular hechos de Finanzas u otros módulos. |
| P5 — Finanzas DOC19 fase 1 | PARCIAL | Ledger/subledger, cuentas, conciliación e idempotencia trazables, fórmulas aprobadas y pruebas formales; no usar banco real. |
| P6 — DOC19/ULi | PARCIAL/PENDIENTE | Seguir fases de DOC19; ULi ejecutivo depende de BI y gobierno IA. `FinanceView` no representa el módulo completo. |
| P7 — resto DOC00–19 + DOC12 | PENDIENTE | Descomponer restante sin desplazar IDs, cerrar todas las pruebas, UAT, rollback/restore y aceptación formal. |
| E0 | PARCIAL | El inventario de 401 criterios y la cobertura por documento existen; falta cerrar ownership/decisiones de contratos y mapear cada prueba/log a IDs. |
| E1 | PARCIAL | Laboratorio aislado y pruebas de metadatos; faltan Auth real multirol, MFA, sesión, revocación y revisión/aceptación de seguridad. |
| E2 | PARCIAL | Código de Tareas/CRM/Tickets reutilizable; recorridos completos por actor, Portal/Chat y E2E administrado pendientes. |
| E3 | PARCIAL | Hechos comerciales/financieros y snapshots reutilizables; conversión íntegra, ledger y aceptación con golden aprobado pendientes. |
| E4 | FALTANTE | Catálogo BI, permisos, calidad/frescura, análisis, informes y fuentes gobernadas. |
| E5 | FALTANTE | Orquestación, política, memoria, evaluación, telemetría, costo y kill switch. |
| E6 | FALTANTE/PENDIENTE | DOTS/eQ operativo y automatización gated por E1/E2/E4/E5. |
| E7 | PARCIAL/PENDIENTE | DOC19 según fases y fuentes E3/E4/E5/E6. |
| E8 | PENDIENTE | 401 IDs con resultado/log, regresión, staging, backup/restore/rollback, UAT y aprobación de release. |

## Código y pruebas a conservar

- **P1:** `lib/operations/task-triage-radar.ts`, migraciones `20261008120000_tasks_radar_workflow_v3.sql` y `20261008143000_p1_task_write_scope_archive_radar_v1.sql`; pruebas `tasks_radar_workflow_v3.sql`, `tasks_read_scope_write_denial_v3.sql`, `tasks_permissions_v2.sql`, `tasks_granted_permissions_v2.sql`, `tasks_triage_integration_v2.sql`. Mantener SQL/Auth/Storage como capas distintas de evidencia.
- **CRM/DOC08:** `components/commercial/ProspectsView.tsx`, `CommercialWorkflow.tsx`, migraciones comerciales y de identidad, `clients_prospects_read_contract_v1.sql`, `20261013110000_clients_prospects_read_grants_v1.sql`, `DOC08_SCENARIOS_42_TRACEABILITY.csv`. El commit `5acec3f` protege el manejo de errores y evita alta/edición heredada insegura; no entrega el CRM funcional.
- **Finanzas/DOC19:** `components/finance/{FinanceView,CommercialWorkflow,FinancialPolicies}.tsx`, `lib/finance/summary.ts`, migraciones fiscales/financieras y pruebas golden, RLS, idempotencia y conciliación. `finance-summary.test.cjs` no pudo ejecutarse en el último registro por dependencia `typescript` ausente.
- **IA/DOTS:** `app/api/ai/assistant/route.ts`, `lib/ai/assistant-handler.ts`, `lib/security/financial-ai.ts`, `financial_ai_boundary_v2.sql`. Es asistente acotado, no DOTS, memoria, orquestación ni observabilidad completos. Se observó estáticamente que algunos errores de lectura se convierten en listas vacías; queda como defecto de manejo de error por corregir bajo dueño de operaciones/IA según el dato consultado.
- `scripts/relaunch/qa-sql.sh` y pruebas SQL son base para el runner; hoy el runner está acoplado a una rama, contenedor y base, y no crea resultado por ID formal.
- Los commits/ramas locales contienen material aprovechable: `codex/p1-hardening-20261009`, `codex/p1-maestro-activation-20261009`, `codex/p1-validation-review-20261008`, `codex/protocolo-maestro-2-0`, `codex/crm-prospects-menu-20261013`. No se verificó el estado vivo de PRs #3/#5/#6/#7; la ausencia de refs remotas impide afirmar qué se publicó o integró. No borrar stash/ramas ni integrar sin revisión.

## Resultados desde la última entrega y bloqueos reales

**Delta ejecutado en esta sesión:** se recuperaron DOC08 v1.1 (SHA-256 verificado) y P1 CSV de 59 IDs (blob/SHA verificados); se generó índice conjunto de 502 IDs sin cambiar resultados. `npm run test:operations` pasó usando las dependencias ya disponibles en un checkout vecino; TSX transpile sintáctico pasó y el generador/`git diff --check` pasaron. Next compiló el código, pero el worker de validación de tipos terminó con código 1 por la instalación incompleta/incompatible del checkout: el build completo no es PASS. Se preparó candidato UI/SQL de Prospectos y prueba transaccional de laboratorio. SQL/Auth real y Preview no se ejecutaron; el SQL candidato simula claims y requiere E2E separado con tokens reales. Ninguno de estos resultados mueve IDs formales a PASS.

**Bloqueos:** (1) revisión de seguridad independiente del contrato de escritura/RLS antes de aplicar la migración exclusivamente al laboratorio; (2) no se ejecutó la regresión SQL ni pruebas Auth con usuarios/token real, Portal y anónimo; (3) no se ejecutó TypeScript completo, build ni Preview E2E por falta de dependencias/red en este entorno; (4) contactos en UI, activación Cliente según condición DOC08 y Oportunidad→Venta siguen pendientes; (5) faltan owners/decisiones para contratos KPI, fórmulas financieras, severidad IT/INT y contratos de identidad; (6) no hay capacidad semanal real ni velocidad histórica para un calendario responsable. DOC08 y P1 ya están recuperados con integridad, por lo que se cierra el antiguo bloqueo de procedencia.

**Riesgos de seguridad:** la migración candidata introduce `manage_prospects`, grants puntuales, policies, funciones `SECURITY DEFINER`, deduplicación y revocación del endpoint de conversión heredado. Requiere revisión independiente completa; no ejecutar todavía. No interpretar `RLS enabled` como prueba suficiente; evaluar todas las policies permisivas, grants, Auth real y Preview. `service_role` nunca debe simular un usuario. Mantener producción cerrada y no mezclar Portal con información interna.

## Frentes de entrega y propiedad exclusiva de contratos compartidos

| Frente | Propietario único propuesto del contrato | Alcance de ese frente | Interfaces que debe consumir, no redefinir |
|---|---|---|---|
| Seguridad / QA | Owner de plataforma/seguridad: DOC01/02, RLS/Auth, identidad/ownership con arquitectura DOC11; QA administra el ledger de resultados DOC12 | Auth, permisos, políticas efectivas, fixtures, runner, evidencias y negativos | No define reglas comerciales, estados de dominio ni fórmulas. Cada módulo entrega casos al ledger DOC12. |
| Operación / CRM | Owner de operaciones/comercial: contratos de Tareas/Tickets, Prospectos/Oportunidades/Ventas/Clientes, Radar y eventos de continuidad; identidad canónica `commercial_entities` se decide con el owner de datos DOC11 | DOC03–05 y DOC08–11, procesos completos por actor | Consume ACL/RLS de seguridad; los hechos financieros pasan al owner de Finanzas; BI consume eventos/hechos publicados. |
| BI / Finanzas | Owner financiero único para ledger, monetización, fiscalidad, comisión y reconciliación; owner BI único para semántica/KPI/reportes, con aprobación del data owner de cada fuente | DOC07, DOC19; ACC-FIN-001..008 de DOC12 como suite de aceptación financiera | BI no recalcula hechos financieros; DOC19/ULi consume métricas BI versionadas; comercial entrega hechos canónicos. |
| IA / DOTS | Owner IA único para políticas, runtime, memoria, evaluación y observabilidad DOC14–18; DOTS/eQ consume contratos de módulos propietarios | DOC06, DOC13–18 y superficies IA de DOC19 | No elude Auth/RLS ni escribe tablas de dominio directamente; no recalcula KPI, no realiza acciones sensibles sin aprobación humana requerida. |

Cada contrato compartido debe tener un responsable nominal, revisión y versión antes de que dos frentes lo cambien. No hay nombres/capacidad asignada en el repositorio: la separación es de ownership técnico, no asignación confirmada a personas.

## Candidato de piloto interno (separado del cierre integral)

El piloto puede considerarse como candidato aparte, no como “P1 terminado”: Preview protegida, proyecto Supabase de pruebas `rqisyolaffwktxhjwpqq`, una cuenta sintética interna, lecturas internas de Clientes/Prospectos y funciones que se hayan probado desde la Preview. Antes de invitar usuarios, cerrar build y browser E2E del commit exacto; verificar Auth real, dashboard, Tareas/estado/historial, Triage/Radar, aislamiento Portal/anon y errores visibles. Deshabilitar explícitamente operaciones comerciales/financieras/Portal no probadas. La Preview/commit actual y los despliegues no se confirmaron en este corte. No usar producción ni datos reales.

## Estimación restante y capacidad

El cierre existente del 8-Oct estima 65–113 persona-semanas y 8–13 meses bajo 1.5–2 FTE netos de desarrollo, QA 0.5–1 FTE, PO 0.25–0.5 FTE y disponibilidad de owners de Finanzas/Seguridad. El repositorio **no** contiene disponibilidad real, velocidad histórica, nombres asignados ni capacidad actual; por tanto esa duración no es compromiso ni puede convertirse honestamente en fecha actual.

Reestimación provisional de esfuerzo restante, conservando el desglose F0–F7 y descontando solo el trabajo de base ya materializado (registro/índice de requisitos, laboratorio de pruebas y scaffolding/tests existentes). No se descuenta aceptación formal: los 401 IDs siguen NO EJECUTADO. Los valores de origen son los rangos del plan de cierre del 8-Oct. Se acredita un máximo de una persona-semana en cada una de F0–F3 por los entregables encontrados; F4–F7 quedan sin reducción porque su capacidad principal está faltante o no aceptada. Es una estimación gruesa de esfuerzo por fases, no un porcentaje de requisitos completados ni velocidad medida:

| Fase | Estimación 8-Oct | Restante provisional | Base del rango / trabajo aún observable |
|---|---:|---:|---|
| F0 | 3–5 | 2–4 | Registro de 401 y cobertura de 20 fuentes existen; faltan ownership/decisiones, conciliación por evidencia y contratos compartidos. |
| F1 | 6–10 | 5–9 | Hay proyecto de pruebas y metadatos/grants; faltan Auth real por rol, MFA/sesión/revocación, negativos y revisión formal. |
| F2 | 8–14 | 7–13 | Hay código y pruebas parciales de operación/CRM; faltan 59 casos P1 trazados, DOC09 Portal/Chat/Storage y E2E integrado. |
| F3 | 9–15 | 8–14 | Hay modelos/tests comerciales y financieros; falta terminar el ciclo fuente, ledger/reconciliación y golden aprobado/ejecutado. |
| F4 | 9–15 | 9–15 | DOC07 está clasificado FALTANTE; catálogo KPI, seguridad/frescura, análisis, reportes y exportación pendientes. |
| F5 | 10–18 | 10–18 | DOC14–18 faltantes como capacidades completas; runtime/políticas/memoria/evaluación/observabilidad pendientes. |
| F6 | 12–22 | 12–22 | DOTS/eQ integrado y DOC19 fases ejecutivas/gestión; depende E1/E2/E4/E5 y contratos de operación. |
| F7 | 8–14 | 8–14 | 401/401 formalmente sin ejecutar; smoke/E2E, staging, restore/rollback, UAT y decisión de release pendientes. |
| **Total aritmético** | **65–113** | **61–109** | Descuento explícito de 4 persona-semanas por scaffolding existente en F0–F3; reestimar después de F0 y medir una iteración real. |

Esta cifra es una reestimación **de esfuerzo**, no de calendario, con incertidumbre alta porque aún no hay estimaciones por requisito ni velocidad medida. No se suma DOC19 fases en paralelo dos veces: F3/F4/F6 conservan los límites del plan original. Para estimar calendario hacen falta capacidad neta semanal por frente, porcentaje de disponibilidad de PO/QA/owners y restricciones de staging/aprobación; convertirlo a meses sin esos datos sería una promesa inventada.

## Próximas entregas verificables

1. Recuperar el CSV P1 original de 59 casos desde una fuente versionada verificable; mantener IDs intactos.
2. Ejecutar un slice P1 por proceso (permisos → transición → historial → Radar) con fixtures repetibles y evidencias que mapeen a IDs; parametrizar runner, no alterar assertions.
3. DOC08: revisar de forma independiente el contrato de escritura Prospectos, convertir un prospecto sintético y probar alta/seguimiento/Radar/RLS; incluir clientes legacy y activación sin inventar historia.
4. Completar primer pase de E0: asignar un owner nominal a cada contrato de identidad, hechos comerciales/financieros, catálogo KPI, eventos y políticas IA; registrar decisiones pendientes sin renumerar IDs.
5. Ejecutar una Preview protegida de un commit congelado con autenticación interna y negativos Portal/anon antes del piloto.
6. Medir esfuerzo real de los primeros 1–2 slices y actualizar rangos/capacidad a partir de datos, no de porcentajes.

### Fuentes rectoras y evidencia

- `docs/PLAN_MAESTRO.md` — orden P1–P7 y dependencias.
- `docs/relaunch/RELEASE_CLOSURE_PLAN_00_19_2026-10-08.md` — E0–E8, ownership y baseline de estimación.
- `docs/relaunch/FUNCTIONAL_AUDIT_00_19_2026-10-08.md` y `docs/relaunch/MODULE_COVERAGE_00_19_2026-10-08.md` — inventario DOC00–19.
- `docs/relaunch/acceptance/REQUIREMENTS_TRACEABILITY_00_19_2026-10-08.csv` — IDs formales y estado de ejecución.
- `docs/relaunch/acceptance/SOURCE_SECTION_COVERAGE_00_19_2026-10-08.csv` — versiones, hashes y secciones fuente; no es aceptación.
- `docs/relaunch/acceptance/DOC08_SCENARIOS_42_TRACEABILITY.csv` — casos DOC08 §80; verificación funcional pendiente.
- `docs/ESTADO_DEL_PROYECTO.md` y `docs/codex/WORKLOG.md` — historial; este documento es el resumen de control vigente para este corte.
