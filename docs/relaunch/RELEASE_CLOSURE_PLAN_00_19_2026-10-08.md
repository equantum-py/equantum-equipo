# Plan de cierre de la visión 00–19

Fecha: 2026-10-08
Base: auditoría funcional `FUNCTIONAL_AUDIT_00_19_2026-10-08.md`; documentos rectores 00–19 y anexos P01/P02.
Este documento propone orden de ejecución; no cambia alcance, no declara exclusiones ni autoriza producción.

## Principios para ordenar el trabajo

1. Conservar los módulos y las fuentes de verdad existentes; ampliar por contrato y migración compatible.
2. Cerrar primero los controles que permiten trabajar con identidades, datos y acciones sin riesgo. No esperar a que todos los módulos terminen para desarrollar en paralelo contratos/determinística del DOC19.
3. No habilitar automatización sensible antes de política, actor autorizado, confirmación/segunda aprobación cuando aplique, idempotencia, trazabilidad, revocación y observabilidad.
4. Tratar “listo para ejecutar” como cola de aceptación, no como PASS. Mantener identificadores oficiales exactos y evidenciar resultado por ID.
5. No reducir los requisitos originales por fases. Las fases del DOC19 ordenan entrega; los elementos que el documento llama optativos son fases posteriores, no eliminaciones del alcance aprobado.

## Entregables, prioridad, dependencias y cierre

| Orden / prioridad | Entregable | Requisitos originales incluidos | Dependencias | Aceptación y condición de cierre |
|---|---|---|---|---|
| E0 · P0 habilitante | Trazabilidad rectora y contratos de datos | Reglas 00–12 transversales; contratos de identidad/ownership del 11; todos los 401 ACC/IT/INT; huecos de aceptación 00–11 | PO/arquitecto de datos; decisión de severidad para IT/INT; preservar IDs DOC12 y parches | Cada regla verificable enlaza a fuente/localizador y prueba; criterios nuevos se aprueban sin renumerar; ninguna decisión “no aplica” sin autorización. Mantener esta matriz como fuente de ejecución. |
| E1 · P0 seguridad/identidad | Identidad, permisos, MFA, Master, auditoría, sesión, secretos e integración | DOC01/02, ACC-SEC, ACC-DATA y contratos P01/P02; límites de sesión y revocación | E0; Auth/Supabase staging independiente; dos aprobadores reales autorizados para aceptación operativa | Pruebas negativas API/RPC/RLS por rol; autoaprobación rechazada; elevación expira/revoca; MFA real y sesión remota efectiva en staging; log protegido; separación Master/servicio. Cierre solo con revisión de seguridad y criterio formal. |
| E2 · P1 verdad operacional y atención | Tareas, Tickets, Portal, historial, dependencias, cierre, Chat V2, identidad comercial | DOC03/05/08/09/10/11 y contratos 02; compatibilidad P02 | E0/E1; datos sintéticos; cuentas Portal A/B e interno en staging para el recorrido cliente | Flujos 0/1/N tareas por ticket, notas internas no salen, cliente no enumera otro; Chat memberships/threads/retención; trazabilidad del ciclo y estados; pruebas UI/API/RLS integradas. Reutilizar tickets/tareas existentes, no duplicar. |
| E3 · P1 verdad comercial/financiera | Prospecto→oportunidad→venta; propuesta; factura/cobro; caja/cuentas/movimientos; impuestos/comisiones; conciliación | DOC08/19 y contratos financieros DOC12/P02 | E0/E1; owner financiero define ledger/cuentas, moneda/fiscal; synthetic fixtures; no datos reales | Golden comercial y financiero más prueba de invariantes: venta≠factura≠cobro; monedas aisladas; pagos/reintentos idempotentes; comisión snapshot; conciliación no duplica cobro; saldos trazables. Aceptación con cortes y fórmulas aprobadas. |
| E4 · P1 BI determinístico y reportes base | Catálogo KPI, calidad/frescura, permisos dimensionales, filtros, comparativos, descubrimientos, drill-down, reportes y exportación | DOC07; requisitos BI de 00/01/08/13/19; P02 scope end-to-end | E0/E1; fuentes de E2/E3; owner de cada métrica; contratos para HR/objetivos/calidad | Fórmulas/versiones validadas, discrepancia “información insuficiente” visible, permisos constantes en query/cache/export/job, drill-down auditado, informes reproducibles con fuente/corte. No crear un segundo motor de reportes para 19. |
| E5 · P1 base IA gobernada (antes de agentes) | Orquestación, políticas, memoria/conocimiento, evaluación y observabilidad | DOC14–18, interfaces de 06/13/19 y compatibilidad P01/P02 | E0/E1; redacción/retención definida; catálogo de herramientas propietarias; contratos de costo/latencia | Evaluación separada por los cuatro dominios definidos; trazas correlacionadas, versiones, políticas, rechazo seguro, kill switch, memoria con consentimiento/retención/borrado; ninguna herramienta elude owner module. Sin activar despliegues sensibles hasta gates. |
| E6 · P2 DOTS / eQ / automatización | Ciclo DOTS, modos, preparaciones, misiones, guardián, aprendizaje, autonomía A–F y ejecución de acciones | DOC06/13–18; compatibilidad 02/03/04/05/07/08/09/10/19 | E1, E2, E4, E5; eventos/jobs idempotentes; responsable de operación y alertas | Pruebas por nivel A–F; A–C no escriben, D propone, E solo reversible preautorizado y F pide confirmación; expiración/revocación en cada paso; 24/7 por eventos/jobs sin LLM permanente; pausa/fallo/reintento con estado. No convertir sugerencias existentes en DOTS por etiqueta. |
| E7 · P1→P2 DOC19: Centro Ejecutivo / ULi | Fase 0 contratos; fase 1 finanzas; fase 2 dirección/ULi; fase 3 gestión profunda; fase 4 integraciones/evolución | DOC19 completo y 00/01/02/07/08/11/13–18; aceptación ACC-FIN y P02 | Fase 0 puede iniciar en paralelo con E1–E5 usando datos sintéticos; fase 1 depende de E3 y E4; fase 2 depende de métricas, permisos y DOTS gobernado; fases 3/4 además requieren objetivos/HR, aprobaciones y servicios autorizados | Ver el orden de trabajo de M19 abajo. Cerrar cada fase con cifras reconciliadas, filtros/roles, fuentes/corte, narrativas comprobables y pruebas negativas; jamás mostrar ratios sin balance válido. |
| E8 · P0 continuo de integración/aceptación/release | 361 ACC + 40 IT/INT, smoke, E2E, regresión completa, backup/restore/rollback, Advisors, preview y decisión release | DOC12 + todos los gates de 01 y requisitos del release | Se inicia con E0; se ejecuta progresivamente tras cada E; staging Auth/DB/Storage/Vercel y usuarios de prueba; QA owner y sign-off funcional/seguridad | Resultado explícito PASS/FAIL/BLOCKED/NO EJECUTADO por ID con log; críticos positivos/negativos; regresión en candidato congelado; restore/rollback; aceptación UAT y autorización formal. `main`/producción solo después de autorización, fuera de este plan. |

### Camino crítico

**E0 contratos y trazabilidad → E1 identidad/permisos/auditoría → fuentes canónicas E2/E3 → E4 catálogo BI y reporte → E5 gobernanza/memoria/evaluación/observabilidad → integración DOTS/eQ E6 y dirección ULi E7 → E8 aceptación completa, staging, rollback y autorización.**

E2 y E3 pueden desarrollarse en paralelo una vez acordados E0/E1; E4 puede empezar con contratos de KPI y métricas sintéticas antes de terminar todos los módulos fuente; M19 fases 0–1 puede avanzar de manera acotada en paralelo como se detalla abajo. La integración final y la aceptación necesitan la secuencia completa.

## DOC19 antes del cierre de módulos anteriores

Sí, se puede avanzar y probar partes de M19 sin falsear datos ni esperar toda la plataforma:

| Fase DOC19 | Se puede avanzar ahora | Prerrequisitos y límite |
|---|---|---|
| 0 — contratos y modelo de datos | Catálogo de métricas/owner/fórmula, contrato de corte/frescura, modelo de vistas configurables, definición de movimientos, moneda, fiscalidad, fixtures y reconciliación. Diseñar navegación accesible con datos sintéticos. | Aprobación del owner financiero y de arquitectura; no crear un saldo real ni un “ratio” sin fuente. |
| 1 — núcleo financiero | Ledger/subledger y movimientos gobernados, entrada de cuentas, aplicación de pago, conciliación e idempotencia; tests exactos de dinero y moneda. | E3 y aprobaciones de fórmulas/retención; solo fixture sintético local. Sin banco real ni conexión externa. |
| 2 — Centro Ejecutivo y ULi | Resumen y consultas basadas en BI ya validado; ULi/DOTS como identidad, narrativas con cita de fuente y permisos. | E4 + E5 + controles de 02/13–18. Antes pueden construirse contratos/prototipos, pero no generar conclusión gerencial con datos productivos ni ejecutar acciones. |
| 3 — gestión profunda | Presupuesto/cierre/escenarios, calidad/capacidad, desempeño, beneficios de decisiones y roadmap. | Dueños aprobados para HR, objetivos y calidad; separación de privacidad; datos y procesos medibles. Si falta contrato, componente deshabilitado, no simulado. |
| 4 — opcional/evolución | Conectores, voz, predicción avanzada y canales externos según DOC19. | Autorización y cuentas de prueba, gobierno de datos/costo, opt-in de voz, consentimiento, aprobaciones de envío y rollback. “Opcional” es fase del plan, no borrado del alcance rector. |

## Trabajo en paralelo

- **Seguridad / Auth y aceptación administrada:** especialista Supabase + QA puede habilitar entorno staging y definir usuarios A/B mientras se implementan contratos E0.
- **Operaciones y comercial:** dos frentes pueden cerrar UX/API/SQL de Tasks/Tickets/Portal y CRM/comercial siempre que compartan identidad/ownership del E0.
- **Finanzas y BI:** owner financiero define fórmulas/fuentes; analista BI construye catálogo/golden de métricas sintéticas. El reporte consume métricas del owner; no duplica fórmula.
- **IA governance y observabilidad:** contratos, threat model, dataset sintético y telemetry design pueden trabajarse en paralelo; la ejecución de agente espera esos controles.
- **DOC19 fase 0/1:** diseño de ledger y catálogo de KPIs en paralelo con otras áreas; ejecución contra integración real espera E1/E3/E4.

No se recomienda paralelizar cambios que compitan por perfiles/estados canónicos, fórmulas financieras, RLS, retención o la semántica del mismo KPI. Esos contratos requieren una sola decisión de owner primero.

## Cronograma estimado y supuestos

No hay información confirmada de tamaño/dedicación del equipo; estos rangos son para planificar, no promesa de fechas. El esfuerzo excluye espera de decisiones o alta de cuentas externas. Estimación suponiendo dos desarrolladores senior full-stack (1.5–2 FTE netos), un QA (0.5–1 FTE), PO/owner funcional 0.25–0.5 FTE y responsables de Finanzas/Seguridad disponibles; incluye integración y regresión, no aceptación externa retrasada.

| Fase | Entrega verificable | Esfuerzo estimado | Duración calendario con supuestos | Gate de salida |
|---|---|---:|---:|---|
| F0 | Trazabilidad + decisiones/contratos faltantes + fixture strategy | 3–5 persona-semanas | 2–3 semanas | Requisitos de 00–11 no cubiertos por IDs formalmente conciliados; ownership acordado. |
| F1 | Seguridad/identidad y staging preparado | 6–10 persona-semanas | 4–7 semanas | Controles locales y E2E Supabase de Auth/RLS/MFA/sesión, dos actores y rollback documentados. |
| F2 | Flujos operativos, Portal/Chat y aceptación integrada | 8–14 persona-semanas | 5–9 semanas | Flujos por actor, casos negativos, retención y E2E de tickets/tareas/chat. |
| F3 | Comercial/finanzas core y contratos de KPI | 9–15 persona-semanas | 6–10 semanas | Datos financieros reconciliados, golden aprobado por owner, métricas con cortes/versiones. |
| F4 | BI base y reporting; DOC19 fase 0/1 | 9–15 persona-semanas | 6–10 semanas, en parte paralelo con F2/F3 | Catálogo y permisos end-to-end, reportes reproducibles; ledger/cash no ficticios. |
| F5 | Gobernanza, memoria, evaluación y observabilidad IA | 10–18 persona-semanas | 7–12 semanas | Cuatro dominios de evaluación, telemetry/privacy/policies y gates para ejecutar. |
| F6 | DOTS/eQ y DOC19 fase 2/3; integraciones fase 4 | 12–22 persona-semanas | 8–14 semanas, con paralelismo | Pruebas de autonomía, ULi auditado, reportes/voz/aprobaciones y funciones de fase 3. |
| F7 | Matriz completa, UAT, staging/restore/rollback y decisión | 8–14 persona-semanas | 5–9 semanas | 401 resultados formalizados, todos los gates críticos aprobados y autorización explícita. |

**Total orientativo:** 65–113 persona-semanas. Con el equipo indicado y paralelismo controlado: aproximadamente **8–13 meses** de calendario, más cualquier espera por staging, cuentas o decisiones. Con una sola persona desarrolladora a tiempo completo: aproximadamente **15–26 meses**, antes de demoras externas. Rangos amplios porque DOC07/13–19 incluyen capacidades nuevas de arquitectura, no solo pantallas. Reestimar al finalizar F0, con descomposición por casos y velocidad real.

## Recursos y decisiones que hacen falta

| Recurso/decisión | Necesidad concreta | Propietario sugerido |
|---|---|---|
| Responsable funcional/PO | Aceptar prioridad, reglas no descritas, límites de fase y criterio de salida; mantener requisitos originales. | Dirección de proyecto |
| Arquitecto/PostgreSQL/Supabase | Contratos, migraciones reversibles, RLS, Auth/Storage y staging independiente. | Ingeniería |
| Dos desarrolladores | Operaciones/UI/backend e integración financiera/BI/IA por frentes compatibles. | Ingeniería |
| QA automation + UX/UAT | Conectar ACC/IT/INT a pruebas, fixtures, navegador, accesibilidad, evidencia sanitizada. | Calidad/producto |
| Owner de Finanzas | Cuenta/ledger, caja, moneda, fiscalidad, comisión, presupuesto, ratios, cierre y exactitud. | Finanzas |
| Owner de BI y dominios | Definir dueño/fórmula/calidad/frescura, especialmente objetivos/HR/calidad. | Dirección + dueños de datos |
| Staging sin producción | Proyecto Supabase y Preview identificables, separado de prod; cuentas de prueba A/B, interno, Master de prueba; MFA y sesión administrada; storage privado; política de retención. | Plataforma/cliente |
| Accesos de integraciones | Cuentas de sandbox autorizadas y scopes mínimos para correo, voz o bancos si/ cuando fase 4 se habilite. | Responsable de cuenta |
| Sign-off | Aprobación formal por criterio, rollback, aceptación y release. | Responsable designado |

No se necesitan credenciales compartidas en documentos ni chats. Las cuentas, variables y claves se provisionan en el gestor autorizado del entorno de staging.

## Mejoras opcionales separadas del alcance rector

Mejoras no exigidas expresamente que se podrían evaluar por separado: optimizaciones de rendimiento más allá de objetivos documentados, nuevas integraciones no nombradas, visualizaciones adicionales, predicciones externas más allá de DOC07/19 o funciones de personalización no requeridas. Deben mantenerse en una lista “opcional” y nunca reemplazar una función rectora. Ninguna de las capacidades de DOC00–19 se marca opcional por decisión de ingeniería; solo se respeta la clasificación por fases aprobada por DOC19.

## Condiciones de no habilitación

- No hay mutaciones de producción ni despliegue en este plan.
- El Centro Ejecutivo no presenta “hechos financieros reales” hasta aprobar fuente/ledger, moneda, corte y reconciliación.
- Ratios de solvencia/liquidez se deshabilitan si no hay balance validado.
- No hay IA con datos personales/sensibles antes de permisos, retención, evaluación y observabilidad.
- DOTS no ejecuta acciones sensibles sin autorización del módulo propietario y confirmación humana requerida.
- Comunicados/correos externos requieren destinatarios, contenido y aprobación exactos.
- Voz queda opt-in; no retener audio por defecto.
- No se cierra el release con criterio formal, IT/INT crítico, rollback o staging requerido sin ejecutar/evidenciar.

## Fuentes y estado

La auditoría funcional está en `FUNCTIONAL_AUDIT_00_19_2026-10-08.md`. Las referencias exactas de criterios/casos están en `acceptance/REQUIREMENTS_TRACEABILITY_00_19_2026-10-08.csv`; el índice de documentos/hash/secciones, en `acceptance/SOURCE_SECTION_COVERAGE_00_19_2026-10-08.csv`. El presente plan no altera registros oficiales ni declara un criterio PASS.
