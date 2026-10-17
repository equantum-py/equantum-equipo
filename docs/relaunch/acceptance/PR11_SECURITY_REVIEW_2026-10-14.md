# PR #11 — revisión de seguridad y cierre de integración (14/10/2026)

**Dictamen técnico: RECHAZO TEMPORAL para aplicación de la migración.** Este documento registra una revisión técnica del candidato; **no constituye aprobación de un revisor humano independiente**. PR permanece draft.

## Fallos corregidos en rama PR #11
- JSX RadarView: commits 20947a6, 7211656 y bd6d6dc; despliegue bd6d6dc = READY en listado Vercel.
- Opción C: se reemplazó la llamada a `has_task_permission('create_tasks')`, no soportada por la función real del laboratorio, por consulta de `user_permissions.create_tasks IS TRUE` para `auth.uid()`. Commit 6303ec1.
- A/B: equivalencia de seguimientos ahora compara opción, acción normalizada, condición, fecha y, para B, plan de verificación; no rechaza por texto idéntico únicamente. Commit 6303ec1.
- Prueba estructural ampliada para ambos contratos en commit 99ac1cd.

## Seguridad y compatibilidad
- Funciones `create_task_continuity` y `record_task_outcome_verification`: SECURITY DEFINER, propietario postgres, search_path vacío, autenticación interna activa, autorización sobre tarea, bloqueos transaccionales y clave de reintento. Las tablas nuevas tienen RLS, SELECT autenticado y DML directo revocado.
- Revisión de lectura: políticas nuevas requieren `is_internal_user()` y una tarea de origen visible bajo RLS de `tasks`; los eventos atraviesan verificación y tarea. Deben probarse perfiles internos autorizados, internos sin acceso, Portal y anon mediante tokens reales.
- **Cambio propuesto para B**: `record_task_outcome_verification` conserva estado Completada y deja pendiente el Followup, cualquiera sea la conclusión. `decide_task_outcome_followup` agrega únicamente una decisión expresa: cerrar ese Followup, reprogramar el mismo Followup o crear una tarea correctiva dejando el Followup abierto. Al cerrar, devuelve el número de otros Followups pendientes. La escritura del Followup usa el trigger de sincronización existente hacia Radar.
- **Regresiones preparadas**: prueba estructural de ACL/RLS y prueba SQL transaccional para tres conclusiones, cierre explícito, reprogramación, tarea correctiva, reintentos, rechazo de permisos y sincronización Radar. Ninguna prueba SQL de esta versión ha sido ejecutada todavía; además se requiere la prueba concurrente de dos sesiones reales.
- **Revisión independiente**: sigue pendiente de aprobación explícita por revisor diferente del implementador. Esta nota y las comprobaciones del autor no sustituyen esa revisión; sin ella NO aplicar migración.

## CI / Vercel
- 5e66c97, 20947a6 y 7211656: ERROR en listado de despliegues; logs de sintaxis JSX aportados en la conversación.
- bd6d6dc: READY, Preview `equipoequantum-qqtqob586-equantum-pys-projects.vercel.app`.
- API de eventos Vercel devuelve 404 incluso con teamId confirmado; logs históricos completos no recuperados por ese endpoint.
- Commit actualizado 99ac1cd: **build, TypeScript y pruebas no ejecutados ni comprobados**. READY del commit anterior no equivale a PASS del nuevo.

## Laboratorio
- Consultas SELECT de definiciones de funciones, columna `create_tasks` y políticas RLS realizadas solo en `rqisyolaffwktxhjwpqq`; sin escrituras.
- Migración NO aplicada; A–E, usuarios ficticios, concurrencia, reintentos, rollback y Preview protegida PENDIENTES.
- PR #8 y producción intactas. Los 59 escenarios P1, 401 criterios y 42 escenarios DOC08 no se confunden ni se dan por aceptados.

**Puerta siguiente:** definir y probar ciclo de vida del seguimiento B, obtener revisión humana independiente de SECURITY DEFINER/RLS/privilegios y autorización escrita; solo después migración autorizada al laboratorio y pruebas completas.


## B — ciclo explícito de verificación actualizado (17/10/2026)

- Registrar observado/fuente/conclusión crea el evento append-only y actualiza el último resultado sin tocar `tasks.status` ni cerrar `followups`.
- La nueva RPC `decide_task_outcome_followup` exige identidad interna activa, `can_write_task` y resultado ya registrado. Las decisiones son `close`, `review` o `corrective_task`.
- `close` cambia a `done` solo el Followup vinculado. `review` modifica la misma fila. `corrective_task` exige `create_tasks`, crea tarea vinculada y mantiene abierto el Followup B.
- Las decisiones tienen clave idempotente por actor, payload inmutable, lock del Task/verification/Followup y transacción única. El resultado reporta cuántos otros seguimientos siguen pendientes.
- UI: las opciones aparecen después de registrar una conclusión; el cierre requiere confirmación, y si no se puede confirmar el estado del Followup se bloquean las acciones.

**Estado:** implementado en borrador; revisión independiente, CI del commit actualizado y pruebas remotas siguen pendientes. La migración continúa sin aplicar.


## Captura de evidencia separada

La verificación B almacena cuatro datos distintos: resultado observado, evidencia concreta (texto o referencia), fuente de esa evidencia y conclusión. La evidencia queda en la bitácora append-only de cada registro y se muestra por separado en Radar. No se suben archivos ni se declara Storage como integrado. La Tarea sigue en estado Completada; ninguna conclusión cierra el Followup automáticamente.


## Revisión correctiva del ciclo B — 17/10/2026

- Después del cierre explícito, un resultado nuevo se rechaza; repetir exactamente una solicitud de resultado ya aceptada devuelve replay y no duplica el evento.
- El formulario de Radar oculta el cierre genérico para una verificación B. Si el seguimiento está cerrado o su estado no se pudo cargar, no permite enviar otra verificación.
- La prueba transaccional ahora sigue las transiciones oficiales, comprueba logrado/no logrado/no concluyente sin cierre automático, la persistencia de resultado/evidencia/fuente tras cerrar, la reprogramación, acción correctiva, reintentos, actor interno fuera de alcance, Portal y anon.
- La consulta de solo lectura del laboratorio confirmó que la tabla de decisiones B no existe todavía. La migración no se aplicó.
- Estas comprobaciones son del implementador y no equivalen a revisión independiente. El dictamen sigue siendo NO APROBADO PARA APLICACIÓN hasta una aprobación explícita de otro revisor.
