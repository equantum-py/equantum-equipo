# P1 — Cierre Inteligente y Continuidad de Resultados

Fecha: 2026-10-14
Rama: `codex/p1-smart-close-impl-pr3-20261014`
Base: cabeza de revisión de PR #3, commit `43714c65204eaf796adab3094e44e6ccf234603c`. No incluye PR #8.

## Documentos aprobados

Los originales se incorporaron sin alteración en la rama documental `codex/p1-smart-close-docs-20261014`, commit `8b5342f`:

- `P1_CIERRE_INTELIGENTE_CONTINUIDAD_RESULTADOS_2026-10-13.md`
- `PRV03_ADENDA_EQ_P1_CIERRE_INTELIGENTE_2026-10-13.md`

El contrato complementa DOC03 y DOC05. Los candidatos CIC-P1-01 a CIC-P1-15 no sustituyen IDs ACC oficiales ni los 59 casos P1.

## Implementado en código — todavía sin aceptación integral

- El cierre sigue usando `transition_task_operational_status`; la sugerencia aparece después del cierre, sin formulario previo.
- La recomendación local es determinística, explica su señal y permite escoger entre A–E. Los seguimientos cargados se conservan y una acción idéntica detectada se deriva a Radar en lugar de duplicarse.
- A crea una espera/confirmación en `followups`; el trigger existente proyecta la continuidad hacia Radar. Responsable inicial: usuario que realiza la acción; fecha o condición requerida.
- B registra una verificación futura en Radar, guardando expectativa, método y fuente indicada como notas del seguimiento. Aún no existe flujo tipado para guardar la evidencia observada ni el resultado pendiente/verificado/no logrado/no concluyente.
- C crea una nueva Tarea, conserva los vínculos disponibles a Cliente/Proyecto/Ticket/Servicio y deja eventos de origen en ambas tareas. La relación está trazada mediante `task_events` y descripción; no existe una FK `parent_task_id`.
- D abre el módulo dueño disponible para Ticket o Cliente. No cambia estado ni crea Venta, Oportunidad o resolución de Ticket. Proyecto no tiene destino accesible desde esta vista.
- E e «Ignorar» no crean registros, no cierran compromisos existentes y no declaran éxito del resultado.
- La opción Próximo paso permanece accesible en la ficha de una Tarea Completada.
- No se llama IA generativa. La UI no modifica permisos ni desactiva RLS.

## Estado de los 15 candidatos aprobados

| Candidato | Estado actual | Faltante para aceptación |
|---|---|---|
| CIC-P1-01 cierre de un clic, actor/fecha/historia | IMPLEMENTADO SIN PRUEBA DE INTEGRACIÓN | Verificar con sesión Auth en laboratorio e historial real. |
| CIC-P1-02 sugerencia posterior, no bloqueante y explicable | IMPLEMENTADO SIN PRUEBA DE NAVEGADOR | Probar en Preview protegida. |
| CIC-P1-03 próximo paso en tarea completada | IMPLEMENTADO SIN PRUEBA DE NAVEGADOR | Probar persistencia al reabrir la ficha. |
| CIC-P1-04 ignorar sin declarar resultado | IMPLEMENTADO SIN PRUEBA DE INTEGRACIÓN | Comprobar que no escribe evento de resultado ni elimina continuidad. |
| CIC-P1-05 seguimiento previo y equivalencia | PARCIAL | Comprobación de duplicado en aplicación; falta garantía atómica frente a concurrencia y prueba SQL. |
| CIC-P1-06 A espera en Radar | IMPLEMENTADO SIN PRUEBA DE LABORATORIO | Confirmar trigger, propietario, permisos y no duplicación con Auth real. |
| CIC-P1-07 B verificación posterior | PARCIAL | Se guarda compromiso y método/fuente como notas; falta contrato persistente del resultado observado. |
| CIC-P1-08 C nueva Tarea vinculada | PARCIAL | Eventos en ambas tareas; falta probar permisos, RLS y consistencia transaccional. No se afirma vínculo relacional. |
| CIC-P1-09 D módulo propietario | PARCIAL | Navegación a Ticket/Cliente; Oportunidad/Venta/Servicio no se implementan por completar una tarea. |
| CIC-P1-10 E no agrega obligaciones | IMPLEMENTADO SIN PRUEBA DE LABORATORIO | Verificar registros antes/después con Auth real. |
| CIC-P1-11 recomendación por datos reales | PRUEBAS UNITARIAS LOCALES | Falta validar con filas y contexto reales de prueba. |
| CIC-P1-12 reintento/concurrencia sin duplicados | BLOQUEADO PARCIALMENTE | La interfaz evita duplicados secuenciales; una garantía de base ante concurrencia necesita diseño y revisión de integridad independiente. |
| CIC-P1-13 acceso interno/Portal/RLS | NO EJECUTADO | Pruebas negativas con sesiones Auth reales en el laboratorio. |
| CIC-P1-14 fallo de Radar no revierte Tarea ni finge éxito | IMPLEMENTADO SIN PRUEBA DE LABORATORIO | Forzar error de seguimiento y verificar cierre/historial persistente. |
| CIC-P1-15 funcionamiento sin IA y vínculos de dominio | PRUEBAS UNITARIAS LOCALES / PARCIAL | Repetir sin IA en Preview y verificar Ticket/Cliente/Proyecto/Servicio con datos ficticios. |

Los estados anteriores son de estos candidatos contractuales; ninguno se contabiliza como escenario P1 formal aceptado.

## Recomendación y NBA

La clasificación local cubre señales explícitas y el orden candidato aprobado B>A>C>D>E, dando prioridad a continuidades ya abiertas para revisarlas. No se localizó en `app`, `lib` ni `supabase/migrations` un motor NBA invocable en este checkout. Por eso este selector no se declara NBA ni sustituye su ranking oficial. La integración NBA queda pendiente del contrato y servicio propietario.

## Verificación local ejecutada

- `npm run test:operations`: PASS; 12 pruebas de operaciones y 9 pruebas financieras.
- `npx --no-install tsc --noEmit`: PASS.
- `npm run build` con URL/clave pública ficticias solo para compilación: PASS.
- `git diff --check`: PASS.

No se ejecutaron SQL/Auth/Preview ni los CIC como aceptación formal. No se aplicaron migraciones, permisos, escrituras remotas o despliegues. No se modificó producción. Cualquier cambio de esquema o permisos sigue bloqueado hasta revisión independiente.

## Próximo paso de aceptación

Revisar PR técnica en borrador; luego, con un usuario sintético del laboratorio, ejecutar A–E en Preview contra `rqisyolaffwktxhjwpqq`, forzar errores y revisar RLS. Diseñar y revisar por separado el contrato persistente para resultado observado e idempotencia concurrente antes de cualquier migración.
