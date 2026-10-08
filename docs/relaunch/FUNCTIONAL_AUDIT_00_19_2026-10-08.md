# Auditoría funcional y trazabilidad rectora 00–19

Fecha de corte: 2026-10-08
Rama/HEAD de entrada: `relanzamiento-2026` / `bc15f2ca6c89c747000ea32b23d678c015613e59`
Alcance: auditoría documental y de código del candidato local; no autoriza cambios funcionales, despliegue ni uso de producción.

## Conclusión ejecutiva

El repositorio contiene un núcleo operativo y comercial real, además de pruebas SQL, UI y contratos financieros. No representa todavía la visión integral de los documentos rectores. En especial, Business Intelligence (07), Chat V2 (10) y los módulos DOTS/IA 13–18 no están implementados como capacidades completas; el Centro de Dirección Ejecutiva con ULi (19) tiene una base financiera/comercial reutilizable, pero carece de gran parte del flujo ejecutivo definido. No se debe reconstruir el núcleo existente: se debe cerrar por contratos y responsabilidades de datos, luego integrar y validar.

La fuente formal versionada tiene **401 registros**: 361 ACC + 24 IT + 16 INT. En la matriz actual los 401 conservan `NO EJECUTADO`; las categorías “CUBIERTO / LISTO PARA EJECUTAR” y “STAGING” son preparación/clasificación, no aceptación. El inventario clasifica 44 listos para ejecutar, 49 que requieren staging y 308 que dependen de función pendiente. Ningún criterio se convierte en PASS por tener código, una prueba relacionada o un build.

Hay un límite de trazabilidad que debe resolverse antes de declarar la cobertura original completa: los documentos 00–11 tienen **cero IDs de aceptación propios** en el inventario de versiones; sus reglas se relacionan con criterios DOC12/P01/P02 cuando hay correspondencia, pero no todas las frases normativas de esos documentos están atomizadas como casos verificables. La matriz registra íntegramente los 401 criterios/casos formales y el índice enlaza las secciones fuente de los 20 documentos. El trabajo de validación deberá añadir referencias a la regla fuente exacta y abrir criterios complementarios para requisitos comprobables sin caso formal, conservando IDs rectores y sin inventar IDs ACC.

## Fuentes y método

Se revisaron los 20 DOCX rectores 00–19 del paquete `DOCUMENTOS_RECTORES(4).zip`, la guía de implementación y anexos del paquete de entrega: auditoría general 00–19, auditoría conjunta 13–19, P01 compatibilidad 13–19 y P02 compatibilidad 00–19. Los SHA-256 de los 20 DOCX coinciden con `docs/relaunch/acceptance/source/INVENTARIO_VERSIONES_00_19.csv`. También se revisaron los registros fuente de criterios/casos, la matriz de clasificación, el estado oficial, la matriz de evidencias, el inventario de módulos, migraciones, pruebas y código del candidato.

La matriz detallada contiene una fila por cada ID oficial del registro (401 filas, orden y claves verificados). Incluye fuente/localizador, comportamiento esperado, clasificación de release, componentes y evidencia asociada, resultado de esta auditoría, brecha, dependencia y validación de cierre. Las relaciones test↔criterio se aceptan solo cuando el comportamiento probado coincide; la asociación no significa que el criterio se haya ejecutado o aprobado.

### Estados de esta auditoría

- **Implementado y verificado:** comportamiento probado ahora contra el criterio exacto; no se asignó este estado a los 401 registros.
- **Implementado sin verificar:** existe evidencia de implementación relacionada, pero falta ejecutar una prueba suficiente para el criterio.
- **Parcial:** hay una porción funcional; faltan capacidades, integración o aceptación.
- **Faltante:** no se encontró implementación de la capacidad definida.
- **Defectuoso:** se encontró una implementación que contradice el comportamiento esperado. No se atribuye este estado sin una reproducción concreta.
- **Bloqueado:** la comprobación depende de infraestructura, acceso o decisión externa no disponible.

## Inventario de cobertura por documento

| Doc | Estado de alcance | Capacidades existentes observadas | Brecha principal respecto del rector |
|---:|---|---|---|
| 00 | PARCIAL transversal | Principios parcialmente expresados en módulos, permisos y flujos existentes. | La visión no es una feature independiente; varios pilares de inteligencia, continuidad, aprendizaje y centro ejecutivo aún faltan. |
| 01 | PARCIAL | Next.js/Supabase, auth, RLS, MFA parcial, backups y runner local. | Doble control y expiración Master, MFA de cuentas sensibles, audit log central protegido, revocación remota y salud/alertas siguen abiertos; la validación administrada no se sustituyó por PostgreSQL local. |
| 02 | PARCIAL | Perfiles, roles/permisos y controles por tablas/RPC. | Ciclo de persona, onboarding, gestión completa de capacidades/desarrollo y aceptación por alcance todavía incompletos. |
| 03 | PARCIAL | Tareas, historial, permisos, asignación, vínculo Ticket/Proyecto y Triage. | Cierre de Proyecto, estados de espera/bloqueo y demás casos de extremo a extremo deben mapearse y aceptarse. |
| 04 | PARCIAL | Cálculo persistido de Triage y trigger; pruebas golden y de integración local registradas. | Situaciones multiobjeto, métricas/agrupación y overrides auditables no acreditan el módulo completo. |
| 05 | PARCIAL | Motor y sincronización Radar, cierre y lectura de dashboard. | E2E visual, canales, ciclo completo y operación de jobs/alertas deben validarse. |
| 06 | PARCIAL | Handler eQ/assistant y frontera financiera local. | Asistente integral de decisión, contexto y acciones autorizadas no se ha aceptado de punta a punta. |
| 07 | FALTANTE como BI | Dashboard contiene contadores de tareas/horas y carga por área; hay datos financieros consumibles. | Falta catálogo semántico de KPIs, calidad/frescura, descubrimientos, comparativos, drill-down autorizado, reportes/exportación y proyecciones definidos por DOC07. |
| 08 | PARCIAL | Identidad comercial, prospectos/oportunidades, catálogo, propuestas, ventas y flujo comercial-financiero. | Criterios de borde, integración y recorridos completos del ciclo comercial pendientes de aceptación. |
| 09 | PARCIAL | Portal/Tickets, mensajes/eventos, relación con Tasks y políticas locales. | Prueba con Auth/Data API/Storage administrados, aislamiento end-to-end y recorridos de cliente interno pendientes. |
| 10 | FALTANTE como Chat V2 | `chat_messages` legado preservado. | Conversaciones/membresías, permisos, hilos, contexto, búsqueda, retención y flujos del DOC10 no están demostrados como Chat V2. |
| 11 | PARCIAL | Migraciones V2/V3, tablas y relaciones operativas, reconciliación y pruebas. | El contrato canónico completo debe cerrar entidades/estados, ownership, procedencia, retención y extensiones requeridas por 13–19; no duplicar fuentes existentes. |
| 12 | PARCIAL como aceptación | Registros formales de 361 ACC + 40 IT/INT y suite local existente. | Los 401 registros siguen sin ejecución formal actual; falta vincular cada evidencia sanitizada y aprobación al ID. |
| 13 | FALTANTE como DOTS | Sugerencias/mejoras y componentes operativos que pueden alimentar capacidades futuras. | No existe agente DOTS persistente con ciclo, autonomía A–F, modos, personalización, aprendizaje y límites definidos. `improvement_suggestions` no equivale a DOTS. |
| 14 | FALTANTE | No se encontró capa de orquestación gobernada ni `supabase/functions` del módulo. | Enrutamiento de flujos, herramientas, políticas de ejecución, estados/reintentos e idempotencia propios de IA. |
| 15 | FALTANTE | No se encontró servicio/ciclo de memoria y conocimiento con su modelo de permisos. | Fuentes, procedencia, retención, recuperación, corrección/borrado y separación personal/gerencial. |
| 16 | FALTANTE | No se identificó plano de gobernanza de IA conforme al documento. | Políticas versionadas, riesgos, aprobaciones, límites y revocación de acciones/modelos. |
| 17 | FALTANTE | No se identificó plataforma completa de evaluación continua. | Dataset/fixtures, evaluación separada por dominios, umbrales, regresión y ciclo de mejora. |
| 18 | FALTANTE | Hay logs de aplicación puntuales, no observabilidad del ciclo IA según DOC18. | Correlación, trazas, métricas, costos/límites, retención, alertas, diagnóstico y salud operativa. |
| 19 | PARCIAL | `FinanceView`, resumen por moneda, políticas fiscales/comisiones y `CommercialWorkflow`; datos comerciales/financieros básicos. | No hay Centro Ejecutivo configurable completo, caja real/proyectada 13 semanas, cuentas/conciliación, escenarios, cierre/forecast, ULi, informes/voz/comunicados ni gobierno integral de indicadores. |

El estado describe alcance encontrado, no aprobación de módulo ni de release. El índice por documento, versión, hash y encabezados principales está en `acceptance/SOURCE_SECTION_COVERAGE_00_19_2026-10-08.csv`.

## Requisitos estratégicos y brechas funcionales

### DOC07 — Business Intelligence

DOC07 define un sistema analítico, no una pantalla resumen: medir, comparar, descubrir, explicar, aprender, proyectar y reportar. Incluye catálogo de KPI con propietario, fórmula, unidad, fuente, período, dimensiones, alcance, permisos y frescura; controles de calidad y “información insuficiente”; análisis temporal/estacional y segmentado; descubrimientos con nivel de certeza y distinción entre correlación, hipótesis y causa; exploración/drill-down; comentarios; BI conversacional; reportes ad hoc/programados y exportación; proyecciones/indicadores líderes; capacidad, calidad y desempeño autorizado; trazabilidad de conclusiones y pruebas de invariantes.

El dashboard actual muestra una fracción operativa (tareas, horas y carga). No se encontró el catálogo BI, una capa de métricas versionadas, motor de descubrimientos, control de frescura/calidad, centro de reportes o proyección integral. Finanzas ya tiene hechos/contratos útiles, pero no debe duplicar cálculos: cada KPI necesita owner, fórmula aprobada y contrato de datos; los filtros, agregados, cache, exportación y jobs deben respetar el mismo scope de permisos.

### DOC13 — DOTS y automatizaciones

DOTS debe persistir y reaccionar a eventos/jobs/reglas con capacidad 24/7 en sentido operativo; no implica inferencia generativa continua. El flujo rector es observar, preparar, acompañar, proteger, actuar, cerrar, aprender y desarrollar. Incluye modos Discreto/Equilibrado/Proactivo, DOTS personal, preparación del día y reuniones, misiones/guardían, enseñanza contextual, patrones, cuestionamiento no punitivo, atribución de valor y acciones por módulos propietarios. La autonomía A–F distingue observación/análisis/preparación/propuesta/acción reversible/acción sensible; esta última exige aprobación humana y owner module. No se encontró el motor/event bus/job scheduler/estado de ejecución y control de autonomía de DOTS. Los triggers existentes son automatización de dominio local, no sustituyen colas, reintentos, salud, pausado, trazabilidad o política DOTS.

P01/P02 añaden idempotencia/reconciliación tras resultado incierto, estados explícitos, límites de privacidad, consentimiento, retención y aprobaciones exactas. `score DOTS` permanece deshabilitado hasta validarse. ULi es la identidad personal de Daniel dentro de DOTS; no es motor ni permiso elevado.

### DOC19 — Centro de Dirección Ejecutiva y ULi

El objetivo incluye resumen configurable, filtros y vistas guardadas, drill-down autorizado y accesible; catálogo/gráficos/reportes con fuente y corte; estado financiero real; cuentas, movimientos y conciliación; caja actual/comparativa/proyectada a 13 semanas; escenarios/decisiones y verificación posterior de beneficios; ratios solo con balance validado; rentabilidad, cobranza y economía del servicio; pipeline vs venta; presupuestos/cierres/forecast; briefing ejecutivo de ULi, narrativa y reports; voz opt-in con campos visibles y corregibles, fallback de texto y sin conservar audio por defecto; PDF/impresión/envío con aprobación exacta; comunicados; lectura gerencial autorizada; roadmap y calidad con propietario; monedas, impuestos y precisión; auditoría y controles sensibles.

El candidato solo soporta una parte de los hechos comerciales y reglas fiscales/financieras. Falta el subledger/cuentas/movimientos/conciliación fuente del saldo real, previsión 13 semanas, presupuestos/cierres, escenarios, catálogo completo de métricas, reportería y aprobación de acciones. P02 indica que los reportes deben reutilizar BI y que las fórmulas financieras pertenecen al owner financiero, no a BI/eQ. Si faltan contratos validados de balance, cash, objetivos, RRHH o calidad, el indicador correspondiente debe permanecer deshabilitado; nunca debe sustituirse por cero o inferencia.

### Chat/eQ y plataforma de IA (10, 06, 14–18)

Chat V2, eQ y DOTS son consumidores/productores distintos. La automatización no debe ejecutarse directamente desde texto sin orquestación, permiso del actor, confirmación según riesgo, idempotencia, auditoría y respuesta verificable. Antes de habilitar contexto personal/gerencial se necesitan política de datos y memoria, límites de scope y retención, gobernanza, evaluación por dominio y observabilidad. La capa determinística debe preceder IA generativa en cálculos/controles sensibles; acceso financiero se mantiene bajo `financial_info` e igualmente debe cubrir inferencias, filtros, cache y exportación.

## Clasificación formal del registro y calidad de evidencia

| Clase oficial | Cantidad | Lectura correcta |
|---|---:|---|
| CUBIERTO / LISTO PARA EJECUTAR | 44 | Hay base/evidencia relacionada suficiente para intentar el criterio; no ejecutado formalmente. |
| STAGING | 49 | Requiere una sesión/servicio real de staging o validación de integración externa. |
| BLOQUEADO POR FUNCIÓN PENDIENTE | 308 | La función/prerrequisito no está implementado o no existe contrato suficiente. |
| NO APLICA aprobado | 0 | No se halló exclusión autorizada; no se quitó alcance rector. |
| Formalmente ejecutado en esta auditoría | 0/401 | La columna formal de los 401 permanece NO EJECUTADO. |

Los bloqueantes oficiales son 131 ACC (23 listos aún no ejecutados, 22 que requieren staging y 86 dependientes de funciones pendientes). Los 40 IT/INT no tienen severidad individual en el registro. No se atribuye un conteo inventado de bloqueantes a esos casos. Los estados no reemplazan los gates generales: E2E real, Auth/Data API/Storage, revisión de Advisors/APIs aplicables, rollback final, aceptación y autorización explícita.

### Pruebas ejecutadas en esta auditoría

- `node --test scripts/relaunch/finance-summary.test.cjs`: **PASS, 1 archivo / 1 suite** (sin convertirlo en aprobación ACC; el archivo contiene subtests del resumen financiero).
- `npx --no-install tsc --noEmit`: **PASS**.
- `npm run build`: **PASS**; Next.js compiló y generó 11/11 páginas estáticas. La corrida necesitó placeholders locales para variables de build; no se conectó a Supabase y no es E2E.
- Regresión SQL: **NO EJECUTADA**. No había servidor PostgreSQL respondiendo, Docker ni dump `staging-baseline.dump` disponible en el runtime de esta sesión. Los 28/28 informados por el estado oficial son evidencia histórica registrada, no ejecución de esta auditoría.
- `git diff --check` se ejecutará sobre el cambio documental antes de publicar.

No se modificaron código, esquema, permisos, datos, credenciales ni servicios. No se ejecutó contra Supabase administrado o producción.

## Decisión de preparación

El repositorio está **listo para ordenar el cierre funcional y comenzar el próximo entregable de implementación tras revisar este plan**, pero la visión completa no está terminada y no está lista para producción. El primer trabajo debe cerrar la trazabilidad/contratos y seguridad habilitante, a la vez que permite avanzar en contratos de datos financieros/BI/M19 con fixtures sintéticos. No iniciar desarrollo estratégico de agentes ni habilitar acciones gerenciales hasta cerrar sus controles y gates.

## Archivos de trazabilidad

- [Matriz por criterio/caso (401 filas)](acceptance/REQUIREMENTS_TRACEABILITY_00_19_2026-10-08.csv)
- [Índice de documentos, versiones, hash y secciones](acceptance/SOURCE_SECTION_COVERAGE_00_19_2026-10-08.csv)
- [Registro fuente de clasificación](acceptance/FINAL_CLASIFICACION_ACC_IT_INT_2026-10-08.csv)
- [Matriz de cobertura inicial 00–19](MODULE_COVERAGE_00_19_2026-10-08.md)
- [Plan de cierre y cronograma](RELEASE_CLOSURE_PLAN_00_19_2026-10-08.md)
