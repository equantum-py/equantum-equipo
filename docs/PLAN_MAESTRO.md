# Plan Maestro de paquetes — Relanzamiento EQ 2026

Este plan organiza el trabajo; no agrega ni elimina requisitos. La secuencia
P1–P7 sigue la prioridad indicada por el responsable. Los documentos rectores y
el plan de cierre E0–E8 continúan siendo las fuentes detalladas.

| Paquete | Módulos/prioridad | Entrega y dependencias verificadas | Estado |
|---|---|---|---|
| P1 | Prioridad inmediata: DOC03 Tareas, DOC04 Triage, DOC05 Radar | Completar y validar comportamiento integrado. Requiere baseline PostgreSQL autorizado para SQL y staging Supabase para los recorridos administrados que correspondan. | Candidata de revisión; SQL y 59 escenarios NO EJECUTADOS; M03–05 PARTIAL. |
| P2 | Siguiente: DOC08 Comercial/Clientes y DOC09 Tickets | Recorridos conforme a cada documento, con identidad/ownership DOC11 y permisos DOC02. Auth/Portal/Storage requieren staging separado cuando aplique. DOC08 es propietario de los hechos comerciales de su ciclo; el uso posterior de esos hechos por Finanzas no duplica el módulo comercial. | Hay código y evidencia local parcial; aceptación integral pendiente. |
| P3 | Siguiente: DOC13 DOTS | Desarrollar experiencia, contratos y capacidades no sensibles con fixtures sintéticos. No crear verdad operativa paralela; consultas y cambios pasan por el módulo propietario. Las métricas oficiales consumen BI gobernado; DOTS puede desarrollarse antes de P4, pero no activar esa integración antes de sus gates. | DOC13 aparece FALTANTE en la matriz vigente. Desarrollo acotado puede empezar; integración real y acciones autónomas quedan gated. |
| P4 | Posterior: DOC07 BI | KPI, fuentes, calidad, frescura, permisos y reportes según DOC07. Depende de contratos, owners de métricas y fuentes de P1/P2/finanzas. | DOC07 aparece FALTANTE. |
| P5 | Posterior: Finanzas Gerencial, principalmente DOC19 fase 1 | Ledger, operaciones y reconciliación conforme a DOC19 y contratos aprobados. DOC08 §§46–50 aporta hechos fuente (venta/factura/cobro, tratamiento determinístico y base/comisión); DOC12 §0/§3 y Tabla 11, ACC-FIN-001–008, define cómo probarlos, no una especificación financiera distinta. Fixtures sintéticos; no conectar bancos reales. | Implementación parcial; aceptación total no acreditada. |
| P6 | Posterior: DOC19 Centro Ejecutivo/ULi | Avanzar por las fases expresas de DOC19. Fase de contratos/fixtures puede ir en paralelo; vistas ejecutivas dependen de finanzas, BI, seguridad y gobierno de automatización. | M19/ULi PARTIAL/PENDING según fases; FinanceView no equivale a ULi. |
| P7 | Módulos/requisitos restantes DOC00–19 y cierre DOC12 | Descomponer contra documentos e IDs oficiales; ejecutar regresión, UAT, rollback y aceptación completa. No usar P7 para postergar requisitos silenciosamente. | Cobertura restante y aceptación formal pendientes. |

## Dependencias transversales

- DOC01/02: arquitectura, seguridad y permisos son gates de todos los paquetes.
- DOC11: identidad, ownership y fuentes canónicas deben permanecer coherentes.
- DOC12: registro y ejecución formal de ACC/IT/INT; pruebas técnicas no implican aceptación.
- Plan vigente E0–E8: E0 trazabilidad; E1 seguridad; E2 operaciones/atención;
  E3 comercial/financiero; E4 BI; E5 IA gobernada; E6 DOTS; E7 DOC19; E8
  aceptación y release. No renumerar ni sustituir estos entregables.
- P3 no tiene una dependencia funcional global de P4. Antes de BI pueden
  desarrollarse con sintéticos la experiencia DOTS, modos, preparación,
  reflexión privada, enseñanza, misión/guardian como interacción y contratos
  de eventos; no presentar resultados no implementados como capacidad lista.
  Fuente: DOC13 §§3–9, 13, 16, 17, 45–47. La consulta/contexto real exige
  identidad, alcance y filtro previos de E1/DOC02/DOC11.
- La integración con métricas gobernadas, tendencias, reconocimientos basados
  en métricas y cualquier lectura oficial de BI espera P4/E4. DOTS presenta el
  NBA oficial; no recalcula Top-N (DOC13 §27; DOC12 Tabla 14, ACC-DOTS-005).
  La reflexión privada no se entrega automáticamente a BI (DOC13 §45; DOC12
  Tabla 14, ACC-DOTS-003).
- E6 (DOTS/eQ/automatización con acciones integradas) mantiene dependencia
  completa de E1, E2, E4 y E5. E5/DOC14–18 gobierna memoria, política de
  autonomía, evaluación, costos y observabilidad; las acciones que cambian la
  realidad deben pasar por el módulo propietario y sus permisos, con
  confirmación según política (DOC13 §§5, 16, 46; DOC12 Tabla 14, ACC-DOTS-001/002).
  Jobs/eventos pueden diseñarse y probarse con sintéticos antes, pero la
  operación persistente fuera del navegador requiere runtime autorizado,
  límites de costo, observabilidad, política y revisión. Hasta cumplir esos
  gates, la ejecución autónoma sensible queda inhabilitada.
- DOC19 fase 0 puede prepararse con datos sintéticos. Sus fases financieras,
  ejecutivas y de gestión dependen de sus fuentes y gates; consultar el plan
  E0–E8 para detalle.

## Paralelismo y continuidad

Pueden prepararse contratos/fixtures sintéticos de BI y DOC19 en paralelo con
P1/P2. P3 solo desarrolla contra límites simulados hasta cumplir dependencias.
No ejecutar paquete siguiente automáticamente salvo aprobación del alcance,
cierre evidenciado, entorno disponible y mecanismo compatible habilitado. No
hay mecanismo de continuidad automática comprobado en este checkout.

Las prioridades son de negocio; si una dependencia técnica cambia el orden
posible, registrar el bloqueo y proponer decisión a Daniel/Derlis sin eliminar
alcance. Los paquetes P2–P7 se detallan antes de comenzar cada uno contra los
DOC completos; la tabla no sustituye especificaciones rectoras.

## Referencias

- docs/relaunch/RELEASE_CLOSURE_PLAN_00_19_2026-10-08.md
- docs/relaunch/MODULE_COVERAGE_00_19_2026-10-08.md
- docs/relaunch/acceptance/REQUIREMENTS_TRACEABILITY_00_19_2026-10-08.csv
