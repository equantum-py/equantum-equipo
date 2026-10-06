# Migración de Identidad Comercial V2

## Alcance

La primera migración de datos convierte cada fila existente de `clients` en exactamente una `commercial_entity`, manteniendo el registro original y su ID como referencia histórica.

No fusiona, borra ni renombra clientes.

## Mapeo

| clients | commercial_entities |
|---|---|
| id | legacy_client_id |
| name | display_name |
| email | email |
| phone, o whatsapp si phone es NULL | phone |
| website | website |
| status | status |
| created_by | created_by |
| created_at | created_at |
| updated_at | updated_at |
| — | entity_type = company |

El nuevo `commercial_entities.id` es un ID canónico nuevo. El ID histórico no se pierde: queda en `legacy_client_id`, y `clients.commercial_entity_id` apunta a la nueva identidad.

## Corte actual

La reconciliación previa encontró 3 clients y 0 duplicados exactos normalizados. Por lo tanto, en un ensayo limpio se esperan 3 identidades provenientes de clients, una por cada registro legado.

No se codifican UUIDs de esos tres clientes dentro de la migración: se migra el conjunto real de `clients`. Así el script es repetible y no depende de una foto rígida de producción.

## Campos que deliberadamente NO migran todavía

- `service`: no se convierte automáticamente a Catalog porque requiere reconciliar catálogo.
- `owner_name`: no se convierte automáticamente en persona/contacto.
- `contact_name`: no se interpreta como nombre. En los datos actuales puede contener un teléfono.
- `notes`: permanece en clients hasta definir su destino contractual.

No inventamos RUC, razón social ni datos faltantes.

## Casos ambiguos

Las Tasks “Contenidos Portal Verde” y “Propuesta Ecotritura” conservan `client_id = NULL`. La migración de identidad no usa títulos de Tasks para crear o inferir relaciones.

## Idempotencia

`commercial_entities.legacy_client_id` es UNIQUE. El INSERT usa la existencia de ese ID como llave de migración y el UPDATE solo completa `clients.commercial_entity_id` cuando está NULL.

La migración incluye validaciones bloqueantes: faltantes, duplicados o enlaces inconsistentes provocan rollback.

## Condición de aceptación

Antes y después:
- cantidad de clients: sin cambios;
- exactamente una commercial_entity por client legado;
- cero duplicados por legacy_client_id;
- cero clients sin commercial_entity;
- relaciones existentes de Tasks/Tickets/Portal intactas;
- casos ambiguos sin auto-link.
