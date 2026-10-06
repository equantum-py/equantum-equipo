# Modelo de Datos V2 — Current → New Model → Action

Basado en Documento 11 y criterios bloqueantes del Documento 12; contrastado con el esquema real de Supabase.

| Actual | Modelo V2 | Acción | Regla |
|---|---|---|---|
| profiles | profiles | PRESERVAR / AMPLIAR | Auth separado del perfil interno |
| user_permissions | user_permissions | PRESERVAR / AMPLIAR | RLS y permisos antes de UI/IA |
| clients | commercial_entities + clients | MIGRAR / AMPLIAR | Identidad canónica; no duplicar empresa/persona |
| projects | projects | PRESERVAR / AMPLIAR | Implementación; no crear proyecto innecesario |
| tasks | tasks + task_status_history | PRESERVAR / AMPLIAR | Estado actual + historia |
| followups | radar_items | MIGRAR | Radar conserva historia del seguimiento |
| task_events | task_events | PRESERVAR / ALINEAR | Evento de dominio, no Audit Log |
| tickets | tickets | PRESERVAR / AMPLIAR | Ticket separado de Task |
| chat_messages | conversation/thread futuro | MIGRAR DESPUÉS | Preservar autor, fecha y contenido |
| improvement_suggestions | pendiente docs 13–18 | REVISAR | No inventar semántica futura |
| — | commercial_entities | CREAR | Identidad comercial company/person |
| — | catalog_items | CREAR | Catálogo maestro producto/servicio |
| — | prospects | CREAR | Prospección |
| — | opportunities | CREAR | Oportunidad; pipeline no es ingreso |
| — | proposals/proposal_items | CREAR | Propuestas versionadas |
| — | sales | CREAR | Venta separada, snapshot de cierre |
| — | active_services | CREAR | Servicio persiste independientemente del proyecto |
| — | invoices/payments | BLOQUE POSTERIOR | Sale != Invoice != Payment |

## Reglas de migración

1. No recrear producción: expandir → migrar → verificar → retirar legado después.
2. Clients se reconcilia por identidad antes de crear vínculos; no se inventan RUC/origen/historia.
3. Followups conserva fila original y Radar usa legacy_followup_id.
4. El enum actual de tasks.status no cambia en esta primera expansión; el mapeo oficial va separado.
5. Ticket puede generar 0, 1 o N Tasks; completar Task no cierra Ticket.
6. Prospect→Opportunity debe ser idempotente.
7. WON crea exactamente una Sale; LOST no crea Sale/Client.
8. Sale no es Invoice ni Payment.
9. Multimoneda no se suma sin conversión gobernada.
10. La política definitiva de comisiones/Finanzas no se inventa antes de su documento.

La migración 20261006_model_data_v2_expand.sql es deliberadamente aditiva y NO se aplica aún a producción.
