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
- **Bloqueo pendiente**: resultado B registra conclusión pero no cambia estado del seguimiento asociado. Es necesario un contrato explícito: conservar seguimiento cuando el resultado sea no logrado/no concluyente o subsista compromiso; cerrar únicamente con resolución explícita y evidencia, sin cierre automático por conclusión 'achieved'.
- **Bloqueo pendiente**: pruebas funcionales de equivalencia A/B, concurrencia de dos sesiones, rollback y autorización; el test SQL estructural no las sustituye.
- **Revisión independiente**: pendiente de aprobación explícita por revisor diferente del implementador; sin esa aprobación NO aplicar migración.

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
