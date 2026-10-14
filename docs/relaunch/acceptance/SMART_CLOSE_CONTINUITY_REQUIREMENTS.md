# Cierre Inteligente y Continuidad de Resultados — vínculo de aceptación

**Capacidad aprobada:** eQuantum P1, según la instrucción de Derlis del
14/10/2026.

**Estado de esta nota:** preparación documental. No reemplaza el contrato
funcional ni la adenda de aplicación PRV-03 que deben gobernar los detalles de
la experiencia.

## Fuentes rectoras conservadas

- [DOC03 Tareas v1.3](../../rectores/03_TAREAS_FINAL_v1.3_2026-10-06.docx)
  — §19 «Cierre + seguimiento» y §22 «Cierre inteligente».
- [DOC05 Radar v1.1](../../rectores/05_RADAR_SEGUIMIENTO_FINAL_v1.1_2026-10-06.docx)
  — §10, §12–18, §24 y §89.
- [Inventario de secciones fuente](SOURCE_SECTION_COVERAGE_00_19_2026-10-08.csv)
  — conserva versiones, hashes y secciones originales.

## Comportamiento que ya fijan los rectores

1. Completar la tarea registra su finalización, conserva contexto relevante,
   comprueba si queda seguimiento o una acción ejecutable, deriva cada elemento
   a su módulo propietario, cierra la tarea y recalcula NBA (DOC03 §19).
2. Completar sigue siendo un clic; el cierre no se convierte en un formulario
   obligatorio. Solo cuando aporte valor se pregunta si algo debe seguirse o
   cuál es el próximo paso. El sistema puede inferir cuando sea seguro
   (DOC03 §22).
3. Una espera, compromiso futuro o revisión corresponde a Radar. Una acción
   nueva y ejecutable corresponde a una nueva tarea vinculada al mismo asunto.
   Completar una tarea no cierra por sí solo el Ticket asociado (DOC03 §19).
4. Radar admite continuidad por fecha, por condición/evento o ambas; debe
   comprobar equivalencias antes de crear y recalcular sin duplicar eventos o
   seguimientos (DOC05 §12–18 y §89).
5. La continuidad previa se conserva hasta que desaparezca legítimamente su
   motivo; el seguimiento se cierra sin borrar la historia relevante
   (DOC05 §24).

## Alcance aprobado en la solicitud de esta entrega

- Acción de cierre de un clic.
- Recomendación contextual determinística, sin dependencia de IA generativa.
- Cinco opciones de continuidad.
- Preservación de seguimientos anteriores y registro de acciones nuevas en sus
  módulos propietarios.
- Pruebas de aceptación antes de declarar la capacidad terminada.

## Contrato funcional y adenda PRV-03 incorporados

Los documentos aprobados están preservados íntegramente en esta carpeta:

- [Contrato funcional P1](P1_CIERRE_INTELIGENTE_CONTINUIDAD_RESULTADOS_2026-10-13.md).
- [Adenda de aplicación PRV-03](PRV03_ADENDA_EQ_P1_CIERRE_INTELIGENTE_2026-10-13.md).

El contrato establece las cinco opciones, su orden de recomendación, sus
propietarios de datos y 15 escenarios candidatos CIC-P1-01 a CIC-P1-15. Estos
IDs son candidatos de la adenda, no sustituyen los IDs oficiales DOC12/P1. La
implementación y aceptación siguen pendientes de evidencia.

## Matriz inicial de vínculo — no es resultado de prueba

| Requisito | Fuente | Propietario del dato/acción | Evidencia requerida | Estado |
|---|---|---|---|---|
| Cierre de tarea de un clic | DOC03 §19, §22 | Tareas (`tasks`, historial de estados) | Actor autorizado; estado, timestamp e historial antes/después | Pendiente de implementación y ejecución |
| Recomendación contextual determinística | Contrato P1 §4 y adenda PRV-03 §2–4; DOC03 §19, §22; DOC05 §10, §15–18 | NBA para orden; Radar para continuidad | Señales reales, orden B>A>C>D>E, justificación y cambio manual; sin ranking paralelo | Contrato incorporado; integrar NBA y probar |
| Cinco opciones de continuidad | Contrato P1 §3 y adenda PRV-03 §2–5 | Tareas, Radar o módulo dueño | Probar A–E sin crear hechos no confirmados y mapear CIC con IDs oficiales | Contrato incorporado; implementación parcial y prueba pendiente |
| Seguimiento anterior preservado | DOC03 §19; DOC05 §18, §24, §89 | Radar (`followups`, `radar_items`, historial/eventos existentes) | IDs previos se conservan; se reutiliza continuidad equivalente sin duplicar | Pendiente de implementación y ejecución |
| Acción nueva en módulo propietario | DOC03 §19 | Radar para seguimiento; Tareas para acción ejecutable; Ticket mantiene su ciclo | Verificar no hay escritura cruzada o cierre implícito de Ticket | Pendiente de implementación y ejecución |
| Ausencia de IA generativa requerida | Aprobación de esta entrega | Reglas determinísticas locales | Prueba sin configurar ni llamar proveedor de IA | Pendiente de implementación y ejecución |

Los IDs originales de aceptación de DOC03/DOC05 deberán vincularse cuando se
disponga del inventario que acompaña al contrato y adenda; los escenarios no se
renumerarán ni se contarán dos veces.
