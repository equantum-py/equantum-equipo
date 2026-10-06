# Catálogo + Prospectos + Oportunidades V2

## Catálogo inicial real

La fuente actual `clients.service` contiene dos valores normalizados:
- **Ecommerce a medida** — usado por 2 clientes.
- **Ecommerce Shopify** — usado por 1 cliente.

No se crean variantes artificiales. Catalog usa `item_type + normalized_name` como unicidad, mientras el texto original de `clients.service` se conserva.

## Migración de servicio legado

Se crea `client_legacy_services` como puente. Esto permite vincular cada texto actual con Catalog sin borrar ni reinterpretar `clients.service`.

No se crean Active Services automáticamente en este bloque: que un cliente tenga un texto de servicio legado no prueba por sí solo fechas, contrato, estado comercial o Sale de origen.

## Prospecto → Oportunidad

La conversión es explícita e idempotente:
- un Prospect puede originar como máximo una Opportunity mediante `prospect_id`;
- convertir dos veces el mismo Prospect no crea dos oportunidades;
- la identidad comercial se conserva;
- no se crea Client/Sale solo por abrir una Opportunity.

## WON / LOST

- **WON**: debe crear exactamente una Sale ligada a la Opportunity, en la misma operación transaccional.
- **LOST**: cierra la Opportunity con motivo cuando corresponda y crea **0 Sales** y **0 Clients** por ese cierre.
- `sales.opportunity_id UNIQUE` protege contra venta duplicada.

La función transaccional de cierre se implementará con las políticas/RLS correspondientes; esta migración prepara constraints y pruebas sin tocar producción.

## Venta Rápida

Venta Rápida no es un atajo fuera del pipeline.

Equivalencia V2 preparada: misma `commercial_entity_id + catalog_item_id` con Opportunity todavía abierta.

Flujo:
1. buscar Opportunity abierta equivalente;
2. si existe, reutilizar/cerrar esa Opportunity;
3. si no existe, crear una Opportunity mínima con `is_quick_sale=true`;
4. cerrar WON;
5. crear exactamente una Sale.

Cuando falta `catalog_item_id`, el sistema **no adivina equivalencia por título o texto**. Debe pedirse/definirse el item antes del cierre rápido.

## Lo que no se inventa

- Los servicios legacy no generan Sales históricas.
- No se crean Prospectos históricos para los 3 Clients actuales.
- No se generan Opportunities históricas.
- No se infieren importes, moneda, fechas de cierre o comisiones.
- Facturas/Pagos siguen fuera de este bloque.
