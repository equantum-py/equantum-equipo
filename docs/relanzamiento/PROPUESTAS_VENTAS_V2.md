# Propuestas + Ventas V2

## Fuente y límite

Este bloque sigue el contrato de relanzamiento: Propuesta versionada, Opportunity distinta de Sale, snapshot al cierre y separación estricta entre Venta, Factura y Pago. Finanzas Gerencial permanece pendiente del Documento 19; por eso no se inventan políticas contables, fiscales ni de comisión que la fuente todavía no cierre.

## Propuestas

Una Opportunity puede tener V1, V2, V3... La clave `(opportunity_id, version)` impide repetir la misma versión. Una versión nueva no pisa la anterior.

Se conserva moneda y totales por propuesta. El tratamiento tributario se registra explícitamente por línea; **no se deduce por moneda**.

## Snapshot al ganar

Cuando una Opportunity pasa a WON, Sale debe conservar una foto comercial del cierre:
- identidad comercial visible en ese momento;
- Proposal y versión aceptada;
- moneda;
- subtotal/descuento/impuesto/total;
- líneas vendidas;
- descripción y precio unitario de cada línea;
- tratamiento tributario registrado;
- fecha de cierre.

`sale_items` existe para que cambios futuros en Catalog o Proposal no reescriban lo vendido históricamente.

## WON transaccional

La operación se prepara como un único commit:
1. bloquear Opportunity;
2. validar estado;
3. resolver versión de Proposal;
4. validar datos de cierre;
5. crear una sola Sale;
6. copiar líneas a `sale_items`;
7. guardar base de comisión sin IVA;
8. cerrar Opportunity como WON;
9. rollback completo ante cualquier error.

`sales.opportunity_id UNIQUE` mantiene la idempotencia: una Opportunity no produce dos Sales.

No se publica todavía una RPC con permisos amplios: la autorización definitiva de esta operación debe respetar la Matriz de Permisos V2 y probarse antes de habilitar EXECUTE.

## LOST

LOST cierra Opportunity y conserva su motivo cuando corresponda. No crea Sale, Client, Invoice ni Payment.

## Moneda

Cada hecho comercial conserva su moneda. No se suman monedas distintas sin una conversión gobernada. Este bloque no inventa tipo de cambio ni fuente de conversión.

## Impuestos

Moneda e impuesto son dimensiones distintas. El tratamiento tributario no puede decidirse solo porque la moneda sea PYG, USD u otra. La migración conserva campos explícitos de impuesto/tratamiento sin imponer una política fiscal no definida.

## Comisión

La base preparada para comisión excluye IVA/impuesto. No se fija aquí porcentaje, regla histórica ni momento de devengo/cobro porque Finanzas Gerencial continúa pendiente. La estructura permite conservar esos datos cuando la política sea aprobada.

## Venta ≠ Factura ≠ Pago

Sale confirma el cierre comercial. No significa que exista factura y tampoco que el dinero haya sido cobrado.

Este bloque deliberadamente **no crea** tablas Invoice/Payment ni obliga a tenerlas para registrar Sale. Esas entidades se incorporarán en el bloque correspondiente sin convertir Sales históricas en cobros ficticios.

## Producción

Nada de este archivo debe ejecutarse todavía en producción. Primero: ensayo gratuito/efímero, reconciliación, RLS y pruebas negativas.
