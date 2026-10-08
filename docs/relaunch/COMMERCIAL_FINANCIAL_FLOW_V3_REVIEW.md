# Circuito comercial-financiero agrupado — candidato

Base a3d0c0e. No aplicado ni validado en PostgreSQL al preparar el candidato.

La seccion Finanzas incorpora una pantalla de operaciones para Master activo
con financial_info: propuesta nueva sobre una entidad comercial existente,
aprobacion fiscal explicita, seleccion de comision, cierre a venta, factura parcial
y cobro confirmado. El resumen existente se recarga despues de cada operacion.
La politica fiscal seleccionada al crear se aplica a todas las partidas; se puede
aprobar una decision distinta por partida desde el panel de politicas antes del cierre.

La migracion agrega permisos INSERT a las tablas del circuito con politicas RLS
Master y permisos UPDATE limitados a columnas usadas por los cierres, bloqueos
y estados derivados. financial_info por si solo no concede escritura. Las RPC
nuevas son SECURITY INVOKER y anon no tiene EXECUTE. No se otorga DELETE.
No se usan service_role ni claves secretas en el navegador.

La creacion de propuesta usa un UUID de solicitud y compara el payload para
rechazar reuso con otros datos; el cierre reusa la venta existente. La factura
requiere numero, fecha e importes y conserva la misma operacion al reintentar.
No admite superar el neto/impuesto restante de la venta. El cobro usa el contrato
de referencia unica ya instalado. La seleccion de comision queda protegida tras
el cierre tanto por RPC como por UPDATE directo.

El rol Master conserva facultad de escribir directamente las tablas autorizadas
por RLS; las RPC invoker no constituyen un canal exclusivo de escritura. Los
controles de las RPC nuevas no modifican automaticamente todos los contratos
legados (por ejemplo create_invoice_v2). Esto requiere revision final de la API.

Pruebas preparadas: comision antes/despues del cierre; circuito completo con el
mismo rol authenticated Master en PYG/USD; PYG 14M vendido, 10M facturado,
7M cobrado, 4M pendiente de facturar y 3M de cobro; reintentos; rechazo de
sobrefacturacion; usuario restringido; lector financiero sin escritura; ROLLBACK.
La simulacion de lector interno desactiva su vinculo Portal solo dentro del test
y se revierte. No se conceden escrituras temporales para hacer pasar el circuito.

Preparacion: TypeScript estricto de los componentes nuevos y sintaxis Python
revisados. El instalador local debe demostrar restore baseline, 22 migraciones,
28 pruebas SQL, nueve pruebas financieras, TypeScript y build completo antes de
integrar. CLI genera el nombre real de la migracion; la plantilla no se aplica
al preparar la rama. El runner conserva su modo ejecutable.

Pendientes: validacion PostgreSQL y compilacion completas del candidato,
recorrido real navegador/Data API, advisors, politica fiscal operativa aprobada,
versiones posteriores de propuestas, Quick Sale sin oportunidad, conversion
multimoneda gobernada y cierre de todos los criterios ACC/IT/INT.
No representa cierre completo de Finanzas/Documento 19 ni autorizacion de release.
Main y produccion no se modifican.
