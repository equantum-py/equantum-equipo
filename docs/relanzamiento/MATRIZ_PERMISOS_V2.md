# Matriz de Permisos V2

Base: documentos rectores 00–12 del relanzamiento. Esta matriz define el contrato de acceso antes de Modelo de Datos V2.

## Regla estructural

La interfaz nunca concede seguridad. Toda lectura/escritura sensible debe quedar protegida por Auth + RLS + permisos. eQ, BI, búsquedas, resúmenes y automatizaciones reciben únicamente datos que el usuario ya está autorizado a consultar.

El usuario Master es protegido: no puede ser eliminado, desactivado ni degradado. Las operaciones administrativas siguen pasando por backend/Edge Function. Se conserva compatibilidad de admin-users con las acciones permissions y update_access.

## Roles

| Capacidad | Master | Administrador | Colaborador | Cliente Portal |
|---|---|---|---|---|
| Iniciar sesión interno | Sí | Sí | Sí | No |
| Iniciar sesión Portal | No como flujo normal | No | No | Sí |
| Ver su perfil | Sí | Sí | Sí | Sí, identidad Portal |
| Administrar usuarios internos | Sí | Según permiso administrativo | No | No |
| Crear/desactivar/restablecer usuarios | Sí | Según permiso administrativo | No | No |
| Eliminar usuario interno | Sí, excepto Master | No por defecto | No | No |
| Cambiar permisos | Sí | Según permiso administrativo y sin elevar sobre Master | No | No |
| Modificar/desactivar/eliminar Master | Nunca | Nunca | Nunca | Nunca |
| Ver clientes | Todos | Según alcance/permisos | Según alcance/permisos | Solo su empresa |
| Crear/editar clientes | Sí | Según permiso | Según permiso | No |
| Eliminar clientes | Solo cuando regla de negocio lo permita y con auditoría | No por defecto | No | No |
| Ver proyectos | Todos | Según alcance/permisos | Según alcance/permisos | No por defecto |
| Crear/editar proyectos | Sí | Según permiso | Según permiso | No |
| Ver tareas | Todas | Según alcance/permisos | Según alcance/permisos | No directamente |
| Crear tareas | Sí | Solo con create_tasks | Solo con create_tasks | No |
| Asignar tareas | Sí | Solo dentro de su permiso/alcance | Solo si su permiso lo habilita | No |
| Cambiar estado de tarea | Sí | Según alcance | Según alcance | No |
| Eliminar tarea | Acción administrativa/auditada | No por defecto | No | No |
| Ver Triage/Radar | Sí | Según alcance | Según alcance | No |
| Ver Tickets internos | Todos | Según alcance | Según alcance | No |
| Ver Tickets Portal | N/A | N/A | N/A | Solo tickets de su empresa |
| Crear Ticket | Sí | Sí según alcance | Sí según alcance | Sí para su empresa |
| Actualizar estado/responsable Ticket | Sí | Según permiso | Según permiso | No |
| Ver mensajes públicos de Ticket | Sí | Sí según alcance | Sí según alcance | Solo de sus tickets |
| Ver notas internas is_internal=true | Sí | Sí según alcance | Sí según alcance | Nunca |
| Crear nota interna | Sí | Según alcance | Según alcance | Nunca |
| Ver ticket_events internos | Sí | Según alcance | Según alcance | Nunca |
| Adjuntos | Según alcance | Según alcance | Según alcance | Solo adjuntos autorizados de sus tickets; nunca notas internas |
| Chat interno | Todos los canales autorizados | Conversaciones autorizadas | Conversaciones autorizadas | Nunca |
| BI no financiero | Todo | Según alcance | Según alcance | No salvo producto futuro explícito |
| financial_info | Sí | Solo si financial_info=true | Solo si financial_info=true | Nunca |
| Inferencias financieras por BI/eQ | Sí | Solo con financial_info | Solo con financial_info | Nunca |
| eQ | Todos los datos autorizados | Solo datos autorizados | Solo datos autorizados | Solo si se define experiencia Portal; nunca datos internos |
| DOTS privado | Según reglas DOTS | No hereda reflexiones privadas ajenas | Solo lo autorizado | No |
| Configuración global/seguridad | Sí | Limitada a permiso explícito | No | No |

## Reglas bloqueantes

1. **Master no es un rol delegable.** is_master identifica la cuenta protegida. Ningún Administrador puede convertirse en Master mediante UI, API o cambio de permisos.
2. **Administrador no significa acceso universal automático.** Las capacidades sensibles se conceden por permiso y alcance, salvo las facultades administrativas expresamente definidas.
3. **Colaborador usa mínimo privilegio.** create_tasks, asignación, datos financieros y administración no se infieren por estar autenticado.
4. **Cliente Portal no es colaborador interno.** Aunque Supabase lo represente como authenticated, las políticas internas deben exigir identidad interna activa.
5. **financial_info es una frontera de seguridad.** Sin ese permiso no se muestran importes/reports restringidos ni se permiten ratios, tendencias, búsquedas, resúmenes o inferencias que los revelen.
6. **create_tasks se valida en backend/RLS/operación propietaria.** Ocultar el botón no basta.
7. **Ticket y Task siguen separados.** Un Ticket puede generar 0, 1 o N Tasks; completar una Task no cierra automáticamente el Ticket.
8. **Notas internas nunca llegan al Portal.** Esto incluye mensajes, eventos, adjuntos, búsquedas, BI y eQ.
9. **Permisos antes que IA.** eQ/DOTS/BI no pueden usar datos fuera del alcance del usuario para luego filtrarlos.
10. **Operaciones sensibles dejan trazabilidad.** Los eventos de negocio no sustituyen el Audit Log de seguridad.

## Implementación V2

- Auth: Supabase Auth.
- Perfil interno: profiles.
- Usuario Portal: client_portal_users, sin heredar permisos internos.
- Permisos: user_permissions, ampliable sin romper compatibilidad actual.
- RLS: separación explícita entre is_active_user() y portal_client_id().
- Administración: Edge Function admin-users.
- Compatibilidad obligatoria: aceptar action=permissions y action=update_access.
- Master: guardas DB existentes + validación backend.
- Storage: privado y autorizado por relación real con Ticket/Cliente.
- IA/BI: consultas posteriores a autorización; nunca service-role para saltar el alcance del usuario.

## Casos negativos obligatorios

- Portal A consulta Cliente B -> 0 filas/denegado.
- Portal A consulta Ticket de B -> 0 filas/denegado.
- Portal consulta is_internal=true -> 0 filas/denegado.
- Portal intenta leer adjunto interno -> denegado.
- Usuario suspendido consulta información interna -> denegado.
- Colaborador sin create_tasks intenta crear Task -> denegado.
- Usuario sin financial_info consulta o pide inferir datos financieros -> denegado.
- Administrador intenta eliminar/degradar Master -> denegado.
- Usuario fuera de conversación intenta leer Chat -> denegado.
- eQ intenta responder con información fuera del alcance -> no recibe esa información.

## Pendientes que NO se inventan

Los documentos 13–19 continúan pendientes/reservados. Esta matriz no define nuevas reglas de DOTS, orquestación, memoria, gobernanza/evaluación/observabilidad de IA ni Finanzas Gerencial. Solo deja las fronteras de seguridad necesarias para integrarlos después.
