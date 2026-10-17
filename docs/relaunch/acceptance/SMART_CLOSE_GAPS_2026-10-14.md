# P1 — cierre de brechas de continuidad (borrador)

Fecha: 14/10/2026  
Base: PR #9, commit `c5dc27e8de693f4edbbe7d21995f597494c7e445`  
Estado: propuesta para revisión; no aplicar la migración antes de aprobación independiente.

## Cambios preparados

| Brecha | Cambio en el candidato | Garantía buscada | Evidencia actual |
|---|---|---|---|
| B — Verificar resultado | Flujo en Radar para resultado observado, fuente de evidencia y conclusión: logrado, no logrado o no concluyente. Conserva expectativa, método y fuente prevista. | Guardar evento de verificación y último estado sin cambiar `tasks.status`; la tarea sigue Completada. | Código UI preparado; contrato SQL pendiente de revisión y ejecución. |
| C — Más de una tarea | El RPC crea una tarea hija por acción distinta y enlaza origen/hija en `task_continuity_actions` y en los eventos de ambas tareas. | La relación no depende de leer eventos desde la interfaz. Reintentar la misma solicitud devuelve la tarea ya creada. Acciones distintas pueden crear tareas adicionales. | Código UI preparado; contrato SQL pendiente de revisión y ejecución. |
| Idempotencia y errores parciales | RPC transaccionales, llave idempotente única por actor, bloqueo por tarea de origen y rechazo de duplicados equivalentes abiertos. | Tarea hija, seguimiento, vínculo y eventos se confirman juntos o se revierten juntos. Las verificaciones conservan una bitácora append-only. | Contrato preparado; concurrencia todavía requiere prueba en el laboratorio. |

## Seguridad propuesta

- Tablas nuevas con RLS y lectura autenticada condicionada a que la tarea de origen sea visible bajo las políticas actuales.
- Sin DML directo para `authenticated` y sin acceso anónimo.
- Dos RPC `SECURITY DEFINER` con `search_path` vacío; validan identidad interna activa y `can_write_task`. La creación de tarea C requiere además `create_tasks`.
- La UI no concede permisos ni simula usuarios.
- No se modifican las políticas RLS ni permisos de tablas existentes.
- La recomendación sigue siendo determinística local. No se declara integración NBA.

## Archivos del candidato

- `app/dashboard/page.tsx`: capturar y enviar datos de verificación; A/B/C usan los RPC, mantienen la llave de reintento tras error y muestran fallos de carga.
- `supabase/migrations/20261014190000_p1_smart_close_result_continuity_v2.sql`: borrador versionado, **no aplicado**.
- `supabase/tests/task_smart_close_integrity_contract_v2.sql`: controles de RLS, grants y endurecimiento de RPC para correr después de aprobar/aplicar el contrato.
- Este documento: estados y plan de aceptación.

## Aceptación pendiente

| Prueba | Resultado |
|---|---|
| Revisor independiente aprueba las dos funciones privilegiadas, las políticas y las restricciones | PENDIENTE |
| Aplicación de migración únicamente en `rqisyolaffwktxhjwpqq` tras aprobación | PENDIENTE |
| Resultado B con cada conclusión; la tarea continúa Completada | PENDIENTE |
| Reintento de la misma llave A/B/C; no duplica seguimiento, verificación ni tarea hija | PENDIENTE |
| Dos sesiones concurrentes con la misma solicitud; exactamente un registro | PENDIENTE |
| Dos acciones C distintas desde la misma tarea; dos tareas hijas vinculadas | PENDIENTE |
| Error forzado después de crear tarea/seguimiento; rollback sin residuos parciales | PENDIENTE |
| Interno con acceso permitido: PASS; interno sin acceso: denegado | PENDIENTE |
| Portal y anónimo: sin lectura de resultados internos ni ejecución RPC | PENDIENTE |
| Preview protegida: ejecutar las opciones A–E y revisar Radar/Tareas | PENDIENTE |

La prueba SQL estructural no emula un token real de Supabase Auth ni cuenta como prueba de permisos de usuario. La aceptación requiere usuarios ficticios autenticados de laboratorio y verificación visual en la Preview.

## Evidencia heredada, no reutilizada como aceptación de estas brechas

PR #9 registró anteriormente 12 pruebas operativas, 9 financieras, TypeScript y build local aprobados para su propio commit. Esos resultados no verifican este nuevo código, contrato, RLS, concurrencia ni Preview. El pipeline de esta rama debe compilar y ejecutar las pruebas otra vez.

## Límite

No se ejecutó ningún SQL remoto, no se hizo despliegue, no se tocó producción y no se integraron PR #8, #9 ni #10.

## B — decisiones posteriores al resultado (17/10/2026)

La revisión de Dirección autorizó que guardar un resultado nunca cierre Radar automáticamente. El candidato actualizado conserva la Tarea Completada y el Followup B pendiente tras registrar «logrado», «no logrado» o «no concluyente». Después permite decidir explícitamente:

- Cerrar este Followup: cierra solo su fila; conserva evidencia e historial y devuelve el conteo de otros pendientes.
- Programar otra revisión: modifica la misma fila y la sincronización existente la refleja en Radar.
- Crear acción correctiva: crea una Tarea vinculada con permiso `create_tasks`; deja abierto el Followup B.

La decisión usa idempotencia por actor/solicitud, bloqueos transaccionales y RPC autorizada. Se agregaron regresiones estructurales y transaccionales; todavía requieren CI y revisión/aplicación aprobada para poder ejecutarse.

**Evidencia B:** el formulario actualizado separa resultado observado, evidencia concreta o referencia, fuente y conclusión. La evidencia se conserva en el evento append-only; no hay adjunto binario ni dependencia de Storage.
