# Servicios Activos + Proyectos + Tareas V2

## Principio

**Venta, Servicio Activo, Proyecto, Tarea y Ticket son objetos distintos.** Estar relacionados no significa compartir automáticamente el mismo estado.

## Después de WON

WON crea Sale mediante el bloque comercial. Eso no significa crear siempre un Project.

Cuando una línea vendida representa un servicio que debe operar, puede originar un **Active Service**. `sale_item_id UNIQUE` hace idempotente esa materialización: reintentar la operación no crea dos servicios desde la misma línea.

No se generan Active Services históricos a partir de `clients.service`; esos textos siguen en el puente legado hasta reconciliación.

## Cuándo crear Project

Project se crea únicamente cuando el servicio requiere una implementación/proyecto con principio, ejecución y cierre propios.

Un servicio recurrente puede permanecer activo sin Project. Por eso `projects.active_service_id` es opcional y cerrar Project **no termina Active Service**.

## Tasks

Task representa trabajo ejecutable.

Puede quedar vinculada a Project y/o Active Service según el origen real. Las relaciones existentes se preservan; no se infieren vínculos por títulos.

Se prepara historial de estados en el bloque anterior. El mapping definitivo de estados legacy a V2 continúa separado para no reinterpretar datos actuales.

## Reglas de cierre

- Project con Tasks abiertas no debe cerrarse silenciosamente.
- Terminar todas las Tasks no cierra automáticamente Project.
- Cerrar Project no pausa/finaliza Active Service.
- Completar Task no finaliza Active Service.
- Completar Task ligada a Ticket no cierra Ticket.
- Cerrar Ticket no elimina ni completa Tasks.
- Finalizar Active Service es una operación explícita y conserva historia.

Se agrega `active_service_events` para historia de ciclo de vida. No reemplaza el Audit Log de seguridad.

## Ticket 0/1/N Tasks

El modelo conserva la relación mediante `tasks.ticket_id`, que naturalmente permite muchas Tasks apuntando al mismo Ticket. La lógica actual de aplicación que evita una segunda Task por Ticket deberá retirarse/ajustarse en el bloque de aplicación. La base V2 no debe imponer unicidad sobre `ticket_id`.

## Seguridad de cierre

La migración prepara `project_has_open_tasks(project_id)` como verificación. No se agrega un trigger que cierre otros objetos automáticamente.

La operación real de cerrar Project deberá:
1. bloquear/leer Project;
2. verificar Tasks abiertas;
3. si existen, rechazar el cierre con mensaje entendible;
4. si no existen, cerrar solamente Project;
5. no modificar Active Service ni Ticket.

La finalización de Active Service tendrá su propia operación explícita.

## Pendiente deliberado

No se inventa qué tipos exactos de Catalog generan Active Service automáticamente ni reglas contractuales de renovación/finalización que no estén definidas en los documentos disponibles. El backend debe requerir una decisión explícita hasta que esa política esté cerrada.

Producción no se toca hasta ensayo, reconciliación, RLS y pruebas E2E.
