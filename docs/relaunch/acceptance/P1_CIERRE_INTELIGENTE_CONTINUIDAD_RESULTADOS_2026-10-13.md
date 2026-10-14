# Sistema de Gestión Inteligente eQuantum

## P1 — Contrato funcional aprobado: Cierre Inteligente y Continuidad de Resultados

**Fecha:** 13 de octubre de 2026  
**Decisión de Dirección:** DISEÑO FUNCIONAL APROBADO  
**Estado técnico:** POR IMPLEMENTAR Y VALIDAR; NO DECLARADO PASS  
**Prioridad:** P1 (DOC03 Tareas, DOC04 Triage, DOC05 Radar)  
**Separación de trabajo:** rama/PR independiente; no modificar PR #8 de Prospectos, main ni producción.

### 1. Origen documental y promesa

El DOC03_TAREAS_FINAL establece expresamente en sus §§17–22 que completar una tarea significa que la acción fue realizada, **no** que se consiguió el resultado empresarial. Ordena registrar el cierre, conservar contexto, comprobar seguimiento o nueva acción, derivar cada elemento a su dueño y recalcular NBA. El cierre debe seguir siendo **de un clic**; la pregunta posterior no constituye un formulario obligatorio. Los §§107–109 refuerzan la continuidad del resultado: lo que debe esperarse va a Radar y la acción nueva va a una Tarea vinculada.

**Problema que resuelve:** el equipo termina acciones valiosas —enviar una oferta, prestar un servicio, ejecutar una mejora—, pero olvida comprobar el efecto, recuperar respuestas o realizar el siguiente movimiento.

**Promesa aprobada:** completar sin fricción, conservar compromisos y ofrecer una recomendación contextual priorizada de cómo avanzar o verificar valor. La IA complementa, pero no condiciona el funcionamiento básico.

### 2. Comportamiento aprobado de extremo a extremo

1. Una persona autorizada pulsa **Completar**. La transición oficial registra el estado, fecha, actor e historial; la tarea queda Completada inmediatamente si la operación tuvo éxito.
2. Después aparece, sin bloquear el uso de la aplicación, la pregunta: **«¿Queda algo por hacer, esperar o comprobar?»**
3. eQuantum presenta **una recomendación principal**, su justificación contextual breve y acceso a cinco opciones. La persona puede **aceptar, modificar, cambiar de opción o ignorar**.
4. Las opciones A–D se guardan exclusivamente mediante el módulo propietario y la autorización correspondiente. La opción E no añade obligaciones.
5. La pregunta y el botón **Próximo paso / Revisar continuidad** permanecen accesibles en la ficha de una tarea ya completada.
6. Ignorar la sugerencia **no** equivale a declarar que se obtuvo el resultado ni elimina obligaciones previamente registradas.
7. Una verificación posterior mantiene el estado Completada de la tarea; el resultado observado se documenta con evidencia, con la posibilidad de quedar pendiente o no concluyente.

### 3. Cinco opciones de continuidad

| Opción visible | Cuándo recomendar | Acción autorizada / fuente de verdad |
|---|---|---|
| **A. Esperar respuesta** | Presupuesto enviado, solicitud pendiente, cliente/proveedor debe responder. | Crear o actualizar en **Radar** el compromiso, responsable y fecha o condición; la negociación sigue siendo propiedad de Comercial. |
| **B. Verificar resultados** | Servicio entregado, sistema instalado, campaña optimizada o mejora cuya eficacia se conocerá después. | Crear en **Radar** una verificación posterior con resultado esperado, responsable y fecha/condición; guardar después evidencia observada y fuente legítima. |
| **C. Crear próxima tarea** | Aparece una nueva acción ejecutable distinta de la tarea terminada. | Crear **Tarea vinculada**, con contexto y permisos; **Triage** determina la prioridad oficial. |
| **D. Actualizar proceso** | La acción produjo un hecho del negocio: avance en Oportunidad, venta, entrega, resolución o proyecto. | Abrir o iniciar una operación en el **módulo dueño**, con sus controles. Completar no crea automáticamente una venta ni resuelve un Ticket. |
| **E. Nada más por ahora** | No se identifica continuidad nueva o el usuario no desea agregarla. | No crear registros. Preservar todos los seguimientos anteriores y el historial. No declarar resultados verificados. |

Las opciones **no son mutuamente excluyentes**: una acción puede generar una respuesta pendiente y una verificación posterior. Si ya existe un seguimiento equivalente, eQuantum debe proponer revisarlo, no duplicarlo.

### 4. Recomendación contextual priorizada

**Regla principal:** mostrar primero los compromisos ya existentes; no crear recordatorios repetidos. Después, con información fiable y permisos vigentes, priorizar:

1. **B** cuando haya efecto futuro no comprobado (entrega de servicio, implementación, campaña, mejora).
2. **A** cuando el progreso dependa de respuesta/confirmación de un tercero.
3. **C** cuando la próxima acción ejecutable sea claramente diferente.
4. **D** cuando se deba registrar un hecho en un dominio propietario.
5. **E** cuando no haya señales suficientes para una continuidad nueva.

Esta secuencia es una **regla determinística candidata de P1**, sujeta a prueba contextual; si coexisten señales, la sugerencia debe explicar por qué eligió una y permitir cambiarla. No se inventarán respuestas, ventas, fechas, compromisos ni indicadores. Si faltan datos, la sugerencia será discreta y neutra.

La IA/DOTS podrá ayudar a redactar y evaluar opciones futuras, bajo sus políticas; **sin IA generativa el cierre, la consulta de compromisos y la recomendación básica siguen funcionando**.

### 5. Contrato de registros y propietarios

| Hecho / decisión | Dueño | Restricción |
|---|---|---|
| Ejecución completada y reapertura | **Tareas** | Estado oficial Completada, historial de actor, fecha y cambios; no se agregan estados artificiales. |
| Espera, compromiso o verificación futura | **Radar** | Responsable y fecha o condición, fuente y prevención de duplicados; sobrevive al cierre. |
| Nueva acción ejecutable | **Tareas** | ID distinto, origen vinculado, contexto, permisos y responsabilidad. |
| Priorización | **Triage** | eQuantum/DOTS no inventa una prioridad oficial paralela. |
| Siguiente mejor acción | **NBA** | Se recalcula según el contrato existente; su sugerencia no crea hechos automáticamente. |
| Estado de oportunidad, venta o contrato | **Comercial/Servicios** | Se actualiza solo cuando existe hecho confirmado y permiso para esa operación. |
| Atención al cliente | **Tickets** | Completar una tarea vinculada no resuelve automáticamente el Ticket. |
| Efectividad, métricas, patrones | **BI** | Solo evidencia verificada, fuentes, períodos, definiciones e información suficiente. |
| Acompañamiento inteligente | **DOTS/eQ** | Propone y explica; respeta autorización humana, privacidad, trazabilidad y límites de autonomía. |

La **verificación de resultado** es un compromiso o resultado observado relacionado con un proceso; no es un séptimo estado de Tareas. Estados descriptivos de evidencia (pendiente / verificado / no logrado / no concluyente) deben revisarse como contrato de dato antes de programar, sin duplicar verdades ajenas.

### 6. Reglas UX, seguridad y fallos

- **Un clic real:** Completar no abre un formulario obligatorio y no espera respuesta del motor de IA.
- **Posterior y no intrusivo:** la pregunta aparece solo después de confirmar el cambio de estado; se puede omitir o reabrir.
- **Sin pérdida:** un fallo al guardar Radar o la tarea siguiente deja el cierre completado intacto, informa el problema y permite reintentar sin afirmar éxito falso.
- **Sin pérdida de continuidad previa:** ignorar, cerrar o elegir E nunca suprime obligaciones existentes.
- **Sin duplicados:** reintentos y concurrencia no crean múltiples seguimientos/tareas equivalentes ni eventos falsos.
- **Permisos efectivos:** validar Auth, RPC, RLS y ámbito del actor; Portal y colaboradores sin permiso no pueden modificar datos ajenos. Un botón oculto no equivale a seguridad.
- **Resultados honestos:** no confundir acción ejecutada con objetivo logrado; si la evidencia es insuficiente, resultado **no concluyente**, no «éxito».
- **Criterios de medición:** registrar resultado esperado, responsable, cuándo/condición, cómo se observará y fuente cuando el contexto lo justifique, sin exigir esos campos a todas las tareas.
- **Compatibilidad:** preservar los estados, tareas y seguimientos preexistentes; cambios sensibles de RPC/RLS requieren revisión independiente.

### 7. Ejemplos de funcionamiento

**Ejemplo comercial.** «Enviar propuesta a Martínez» → Completar. eQuantum sugiere A: «Revisar respuesta de Martínez» según compromiso real registrado. La Oportunidad conserva su estado; no nace una Venta sin contrato y operación autorizada.

**Ejemplo de servicio contratado.** «Instalar sistema» → Completar. eQuantum recomienda B: «Comprobar funcionamiento y satisfacción después de la puesta en marcha». Radar protege fecha/condición. Si hay falla, se crea una nueva Tarea o un Ticket según quién administra el caso.

**Ejemplo de trabajo interno.** «Ordenar documentos del proyecto» → Completar. Sin evidencia de obligaciones adicionales, el sistema propone E sin producir alarmas innecesarias.

### 8. Escenarios candidatos de aceptación P1

Estos códigos **CIC-P1-01 a CIC-P1-15 son etiquetas provisionales de esta especificación**, NO IDs ACC oficiales ni una suma a los inventarios existentes. El implementador debe mapearlos a DOC12, a los **59 escenarios P1** y a las secciones originales del DOC03; no declarar PASS por semejanza. **Todos: NO EJECUTADO.**

| ID candidato | Conducta a demostrar |
|---|---|
| CIC-P1-01 | Completar en un clic: estado, actor, fecha e historia, sin formulario obligatorio. |
| CIC-P1-02 | Sugerencia explicable aparece después del cierre sin bloquear. |
| CIC-P1-03 | «Próximo paso» sigue disponible en tarea Completada. |
| CIC-P1-04 | Omitir sugerencia no significa «resultado logrado». |
| CIC-P1-05 | Seguimiento Radar preexistente se conserva y no se duplica. |
| CIC-P1-06 | A guarda espera con responsable y fecha/condición y permite revisar. |
| CIC-P1-07 | B guarda verificación futura no comercial y luego evidencia real o resultado no concluyente. |
| CIC-P1-08 | C crea nueva tarea vinculada y preserva la anterior Completada. |
| CIC-P1-09 | D no inventa venta ni cierra Ticket; usa operación del módulo propietario. |
| CIC-P1-10 | E no crea nuevas obligaciones ni elimina las ya existentes. |
| CIC-P1-11 | La recomendación contextual se fundamenta en datos reales; con contexto insuficiente no alucina. |
| CIC-P1-12 | Reintento o concurrencia no duplican seguimiento, tareas o eventos. |
| CIC-P1-13 | Negativos por roles y RLS: usuario sin permiso y Portal no acceden a datos prohibidos. |
| CIC-P1-14 | Falla al guardar seguimiento se muestra correctamente y no revierte ni finge el cierre de Tareas. |
| CIC-P1-15 | Funciona sin IA y respeta vínculos con Ticket, Cliente, Oportunidad y Proyecto. |

**Evidencia mínima por prueba:** documento y regla, actor, entorno, commit, entradas, acciones, estado antes/después, resultado observado, registros de Radar/historial o dominio, resultado PASS/FAIL/BLOCKED y referencia a ID oficial.

### 9. Integración y límites de la autorización

**Aprobado ahora:** este diseño, su incorporación a la cola formal de P1 y al control de fidelidad PRV-03; no se ordena reescribir todo Tareas ni tocar PR #8.

**No hecho todavía:** programación del Cierre Inteligente, ejecución SQL, prueba en Supabase, demostración de Preview ni cierre de los nuevos escenarios candidatos.

**Secuencia:** revisión de dependencia con PR #3 y flujos P1 → especificación de datos/seguridad con dueños → implementación en PR separada → tests determinísticos y negativos → laboratorio aislado → Preview protegida y aceptación vinculada a IDs originales. No tocar main ni producción sin autorización específica.

**Regla final:** una tarea debe terminar rápido, pero el resultado no debe quedar abandonado.
