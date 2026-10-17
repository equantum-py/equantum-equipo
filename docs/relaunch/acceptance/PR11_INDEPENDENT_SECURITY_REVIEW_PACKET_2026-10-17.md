# PR #11 — paquete para revisión independiente de seguridad y preparación funcional

**Fecha de preparación:** 17/10/2026  
**PR:** https://github.com/equantum-py/equantum-equipo/pull/11  
**Rama:** `codex/p1-smart-close-gap-fix-20261014`  
**Código funcional revisado por este paquete:** `4233b3ed3cd18b74cc779b30135c98438a3012ad`  
**Migración:** `supabase/migrations/20261014190000_p1_smart_close_result_continuity_v2.sql`  
**Estado:** paquete de revisión; **no es una aprobación**. La migración no debe aplicarse hasta que firme un revisor distinto del implementador.

## 1. Alcance del dictamen independiente

Revisar el diff completo de la PR #11 contra su base y emitir uno de estos dictámenes:

- **APROBADO PARA APLICAR SOLO EN EL LABORATORIO**
- **RECHAZADO**, con hallazgos, severidad y corrección requerida
- **APROBADO CON CONDICIONES**, enumerando cada condición y quién verificará su cierre

La persona revisora debe ser distinta de quien implementó la PR. Un informe de auto-revisión, CI, un despliegue Vercel READY o pruebas SQL escritas no sustituyen este dictamen.

No se solicita aprobar producción, integrar la PR ni cambiar permisos en el proyecto.

## 2. Archivos del candidato

| Archivo | Propósito |
|---|---|
| `supabase/migrations/20261014190000_p1_smart_close_result_continuity_v2.sql` | Tablas, RLS y RPC transaccionales A/B/C |
| `supabase/tests/task_smart_close_integrity_contract_v2.sql` | Comprobaciones estructurales de RLS, privilegios y endurecimiento de funciones |
| `supabase/tests/task_outcome_followup_decisions_v1.sql` | Regresión SQL de B, decisiones, permisos, historial y sincronización Radar |
| `app/dashboard/page.tsx` | Captura/visualización de resultado B y decisiones explícitas |

La migración declara que no cambia las políticas de tablas existentes ni las transiciones de estado de Tareas. El revisor debe comprobarlo contra el diff y la migración, no tomar esta declaración como evidencia.

## 3. Superficie de seguridad que requiere revisión

### Funciones privilegiadas

Verificar las definiciones, propietario efectivo, `SECURITY DEFINER`, `search_path`, ACL efectiva (incluido PUBLIC), manejo de errores y privilegios de helpers:

- `public.create_task_continuity(uuid,text,uuid,text,text,timestamptz,text,text,text,text,text,date)`
- `public.record_task_outcome_verification(uuid,uuid,text,text,text,text)`
- `public.decide_task_outcome_followup(uuid,uuid,text,text,text,timestamptz,text,text,date)`

El SQL propuesto fija propietario `postgres`, establece `search_path = ''`, revoca EXECUTE de PUBLIC/anon y concede EXECUTE a authenticated. Confirmar esos valores después de la migración y comprobar que los helpers `is_internal_user()`, `is_active_user()` y `can_write_task(uuid)` tienen contratos seguros y efectivos para estas llamadas.

Inspeccionar en especial:
- Que `auth.uid()` sea la identidad usada y que Portal, perfil inactivo o JWT sin sujeto no puedan ejecutar acciones.
- Que `can_write_task` aplique alcance vigente y no permita escritura sobre tarea ajena.
- Que la opción C exija `user_permissions.create_tasks IS TRUE`.
- Que toda fila hija use la misma Task, Followup y actor autorizados.
- Que ninguna decisión se ejecute solo por existir EXECUTE en la RPC.

### Tablas, RLS y lectura

La migración crea:

- `task_continuity_actions`
- `task_outcome_verifications`
- `task_outcome_verification_events`
- `task_outcome_followup_decisions`

Verificar RLS habilitado en las cuatro tablas, SELECT autenticado sujeto a usuario interno y visibilidad de la Task origen bajo las políticas existentes, y ausencia de DML directo para authenticated/anon. Confirmar que Portal y anon no puedan leer resultados, eventos o decisiones mediante Data API, vistas u otra ruta.

Evaluar si las políticas basadas en `EXISTS ... public.tasks` conservan el aislamiento esperado al ejecutarse con el invocador y que no revelan existencia, conteos o datos de tareas fuera de alcance.

### Integridad, reintentos y concurrencia

Revisar que las restricciones UNIQUE/FK/CHECK y bloqueos transaccionales resuelvan las carreras en la base de datos, no solo en la interfaz:

- Clave idempotente por actor/request y rechazo de reutilizar una clave con otro payload.
- Serialización por Task origen para crear continuidades.
- Orden de bloqueos entre Task, verificación y Followup compartido por registro de resultado y decisión.
- Dos operaciones simultáneas idénticas producen una sola fila/acción y un replay.
- Dos acciones legítimas diferentes sobre la misma Task completada pueden coexistir.
- Registro B concurrente con cierre/revisión/corrección no deja resultado o decisión parcial.
- Error tras cualquier escritura revierte Followup, Task hija, eventos, vínculo, verificación y decisión como una unidad.
- Los eventos de evidencia conservan su historial y no se pueden editar/borrar mediante roles de aplicación.
- Las claves idempotentes y los índices únicos cubren los casos previstos, incluidos reintentos después de cierre.

Comprobar posibles bloqueos cruzados, serialización excesiva y conducta ante rollback/timeout; la existencia de advisory locks por sí sola no demuestra ausencia de deadlocks.

### Compatibilidad de producto

Comprobar que:
- Guardar una medición no cambia `tasks.status` de Completada ni cierra el Followup.
- Las conclusiones `achieved`, `not_achieved` e `inconclusive` no generan conclusión automática ni cierre automático.
- `close` cierra únicamente el Followup B elegido; otros compromisos siguen abiertos y Radar refleja el total pendiente.
- `review` modifica el mismo Followup, conserva notas/evidencia previa y vuelve a sincronizar Radar.
- `corrective_task` requiere permiso de creación, crea una Task vinculada y deja abierto el Followup B.
- La sincronización reutiliza el trigger existente de Followups/Radar sin crear un segundo motor ni modificar el estado del Ticket.
- D y E no se implementan por esta migración: D delega al proceso/módulo propietario y E no debe crear compromiso ni declarar éxito. Revisar que las piezas UI/funcionales no hagan escrituras fuera del contrato para esos casos.

## 4. Matriz de ejecución pendiente (no marcar PASS antes de evidencia)

| Caso | Actor/sesión | Resultado que debe comprobarse | Evidencia mínima |
|---|---|---|---|
| A — esperar respuesta | Interno autorizado | Crea un Followup pendiente; Radar muestra continuidad; Task permanece Completada | ID Task/Followup/Radar, actor, consulta antes/después |
| B1 — registrar logrado | Interno autorizado | Guarda observado/evidencia/fuente/conclusión; Task sigue Completada y Followup pendiente | Evento append-only y fila de verificación |
| B2 — registrar no logrado | Interno autorizado | Mismas garantías, sin cierre automático | Consulta de Task, Followup y evento |
| B3 — registrar no concluyente | Interno autorizado | Mismas garantías, sin cierre automático | Consulta de Task, Followup y evento |
| B4 — cerrar explícitamente | Interno autorizado | Cierra solo el Followup elegido; conserva evidencia y restantes; Radar no cierra si quedan pendientes | Decisión, filas y conteo pendiente |
| B5 — reprogramar | Interno autorizado | Actualiza la misma fila; no duplica seguimiento; Radar refleja la nueva fecha/condición | Mismo followup_id antes/después |
| B6 — acción correctiva | Interno autorizado con create_tasks | Crea Task hija enlazada y eventos; deja B pendiente | Task origen/hija, decisión y Followup |
| C — varias tareas legítimas | Interno autorizado con create_tasks | Solicitudes distintas crean varias tareas hijas vinculadas; replay igual no duplica | Dos request_id distintos y un replay exacto |
| D — proceso propietario | Actor autorizado del módulo dueño | Llama al proceso existente; no cambia datos propietarios fuera de contrato | ID/resultado del módulo y estado antes/después |
| E — omitir | Interno autorizado | No crea Followup/Tarea/Radar nuevo ni marca resultado logrado | Conteo antes/después igual y Task intacta |
| Reintento/clave reutilizada | Interno autorizado | Replay exacto idempotente; mismo request_id con payload distinto se rechaza | Salida RPC y conteos |
| Concurrencia igual/distinta | Dos sesiones Auth independientes | Igual: una sola acción; distinta: ambas legítimas; sin deadlock ni residuos | Logs por sesión, request IDs y conteo final |
| Error parcial | Interno autorizado | Transacción completa revierte al fallar en punto intermedio | Inyección controlada, ROLLBACK y residuo cero |
| Permiso denegado | Interno real sin alcance/permiso | Sin lectura ni escritura fuera de alcance | JWT real, respuesta y consulta del owner |
| Portal y anónimo | Auth Portal real y anon | Sin lectura de datos internos ni ejecución de RPC | Token/sesión y respuesta denegada |

### Separación de evidencias

- La prueba SQL con `SET ROLE authenticated` y claims en una transacción es una comprobación de RLS a nivel de SQL; **no reemplaza** llamadas con tokens emitidos por Supabase Auth.
- Las pruebas estructurales tampoco prueban la interacción visual.
- Cada ejecución debe registrar: ID del caso, ambiente/proyecto, SHA, actor/rol/permisos, request_id, hora UTC, resultado, evidencia sanitizada y limpieza comprobada.
- No se deben usar usuarios reales ni secretos compartidos por chat.

## 5. Estado comprobado al preparar este paquete

- CI GitHub Actions run #34 del candidato de PR #11: **SUCCESS**; 12 pruebas operativas, 9 financieras, TypeScript y build. El runner indica SQL no ejecutado.
- Check de Vercel del commit `4233b3e`: deployment **READY**.
- La llamada de acceso a Preview protegida devuelve HTTP 403 antes de llegar a la aplicación. Las APIs de proyecto/listado consultadas desde la conexión actual no exponen el proyecto `equipoequantum`; la causa observada es falta de autorización de esta conexión al equipo/proyecto, no fallo de build. Se requiere que Derlis reconecte/actualice Vercel con acceso al equipo **equantum-py's projects** y al proyecto **equipoequantum**, sin compartir tokens ni contraseñas.
- Lectura del proyecto Supabase `rqisyolaffwktxhjwpqq`: estado `ACTIVE_HEALTHY`, PostgreSQL 17.11. Consulta de solo lectura: `public.task_outcome_followup_decisions` no existe; migración no aplicada.
- Reviews de GitHub para PR #11: lista vacía al 17/10/2026. No hay dictamen independiente registrado.
- Producción intacta. PR #11 continúa en borrador y no integrada.

## 6. Formulario del revisor independiente

- Revisor (nombre y rol): ______________________________
- Confirmación de independencia del implementador: Sí / No
- SHA del código revisado: ______________________________
- Fecha: __________________
- Dictamen: APROBADO SOLO PARA LAB / RECHAZADO / APROBADO CON CONDICIONES
- Hallazgos bloqueantes y severidad: ____________________
- Condiciones que requieren corrección: __________________
- Evidencia usada: ______________________________________
- Aprobación registrada en GitHub (URL): _________________

**Regla:** si el revisor no marca independencia, no identifica SHA o deja condiciones bloqueantes sin cerrar, la migración permanece sin aplicar.

## 7. Secuencia posterior

1. Revisor independiente completa y publica el dictamen.
2. Si hay hallazgos, corregirlos en PR #11 y repetir CI.
3. Derlis actualiza la conexión Vercel para este equipo/proyecto; luego se verifica login y el recorrido en la Preview protegida.
4. Con dictamen favorable, se presenta el SQL final y se solicita autorización explícita para aplicarlo solo al laboratorio.
5. Tras la autorización, ejecutar migración, pruebas estructurales, SQL funcional, tokens Auth ficticios, concurrencia y recorrido visual A–E.
6. Publicar resultados por caso; ningún resultado se anticipa.
