# Reconciliación de Datos V2

Auditoría read-only del Supabase productivo. No modifica registros.

## Conteos base

| Entidad | Registros |
|---|---:|
| clients | 3 |
| projects | 0 |
| tasks | 3 |
| followups | 0 |
| tickets | 2 |

Estos conteos son la línea base mínima para ACC-MIG-001.

## Duplicados de Clientes

Se probaron coincidencias exactas normalizadas por:
- nombre: lower(trim(name))
- email: lower(trim(email))
- teléfono: solo dígitos

Resultado actual: **0 grupos duplicados detectados** en los tres criterios.

Esto no autoriza a asumir que nombres parecidos representan la misma empresa. Cualquier fuzzy match futuro se reporta como candidato y requiere confirmación; nunca se fusiona automáticamente.

## Relaciones huérfanas

Resultado actual: **0 huérfanos** en:
- projects.client_id → clients.id
- tasks.client_id → clients.id
- tasks.project_id → projects.id
- tasks.ticket_id → tickets.id
- followups.task_id → tasks.id
- tickets.client_id → clients.id

## Inventario de Clientes

- Corpi & Cia: 1 Task, 2 Tickets, 0 Projects, 1 usuario Portal.
- Portal Verde: 0 Tasks enlazadas, 0 Tickets, 0 Projects, 0 usuarios Portal.
- Ultra Maison: 0 Tasks enlazadas, 0 Tickets, 0 Projects, 0 usuarios Portal.

Cada client existente debe generar/vincularse a una sola commercial_entity durante la migración. No se inventan tax_id, razón social, origen ni historia.

## Inconsistencias / datos a clasificar, no corregir automáticamente

1. Existe una Task titulada **Contenidos Portal Verde** con client_id NULL. El nombre sugiere relación con Portal Verde, pero **no se migrará esa relación por inferencia**. Debe quedar reportada para confirmación humana.
2. Existe una Task **Propuesta Ecotritura** con client_id NULL. No existe un Client llamado Ecotritura en el conjunto actual; no se crea Client/Prospect automáticamente.
3. La Task **AGREGAR NUEVOS PRODUCTOS** sí está enlazada a Corpi & Cia y al Ticket EQ-01002. Esa relación se preserva.
4. Actualmente hay 1 Task enlazada a Ticket y ningún Ticket con más de una Task. Esto describe los datos actuales, no una restricción futura: V2 debe permitir 0/1/N Tasks por Ticket.
5. No existen Projects ni Followups actualmente, por lo que sus migraciones deben tolerar conjunto vacío sin fabricar registros.

## Plan exacto de migración

### clients → commercial_entities
Para cada client legado, crear una commercial_entity con:
- display_name = clients.name
- legacy_client_id = clients.id
- datos existentes únicamente cuando estén presentes
- commercial_entity_id se devuelve al client original

Idempotencia: legacy_client_id es UNIQUE. Reejecutar la migración no puede crear una segunda identidad para el mismo client.

### tasks
No cambiar client_id por inferencias basadas en título/descripción. Preservar todos los IDs y relaciones existentes.
El cambio de estados se hará en una migración posterior con tabla de mapeo explícita.

### projects
Conjunto actual vacío. No crear Projects desde Tasks, Tickets o Clients durante reconciliación.

### followups → radar_items
Conjunto actual vacío. El proceso se diseña idempotente usando legacy_followup_id UNIQUE para cuando existan registros en otros entornos o antes del corte.

### tickets
Preservar IDs, ticket_number, client_id, estado, mensajes, eventos y adjuntos.
No crear/eliminar Tasks durante reconciliación.

## Reconciliación antes/después

Antes y después de una migración real se deben verificar como mínimo:
- cantidad de clients legacy sin perder filas;
- exactamente una commercial_entity por client migrado;
- cero client duplicado por legacy_client_id;
- conteos de Tasks/Tickets/Projects/Followups sin reducción inesperada;
- cero nuevas relaciones huérfanas;
- relaciones Task↔Ticket existentes intactas;
- usuarios Portal siguen asociados al mismo client;
- ninguna relación inferida fue creada sin decisión explícita.

## Bloqueadores

No ejecutar la migración V2 en producción hasta disponer de:
1. backup/recovery verificable;
2. ensayo en entorno gratuito/efímero;
3. reconciliación antes/después;
4. pruebas RLS;
5. aprobación de las relaciones ambiguas reportadas.
