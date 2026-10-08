# Circuito comercial-financiero — evidencia local

Fecha UTC: 2026-10-08. Candidato validado: 620999c.
Migracion CLI: 20261008031852_commercial_flow_v3.sql.

## Implementacion

Finanzas incorpora propuesta nueva para una entidad existente, aprobacion
fiscal explicita y comision, cierre a venta, factura parcial y cobro.
El resumen financiero se recarga despues de operar. La politica fiscal elegida
al crear aplica a todas las partidas; una decision distinta se puede aprobar
por partida desde el panel de politicas antes del cierre.

Las nuevas RPC son SECURITY INVOKER. RLS limita escrituras a Master activo
con financial_info. financial_info por si solo permite consulta. UPDATE se
limita a columnas necesarias para cierres, bloqueos y estados derivados.
No se otorga DELETE ni se usan claves secretas/service_role en el navegador.

La solicitud de propuesta usa UUID y compara datos al reintentar. El cierre
mantiene una venta por oportunidad; factura exige numero, fecha y limites
de neto/impuesto restante. El cobro usa referencia unica. Reasignar comision
despues del cierre se rechaza incluso por UPDATE directo.
Pagos sin fecha ya no interrumpen la carga del resumen.

## Evidencia aprobada

- Restore baseline: 11 conteos reconciliados, Vault excluido explicitamente.
- Runner oficial en equantum_flow_rehearsal: 22/22 migraciones, FAIL=0.
- Cinco cuerpos de funciones instaladas coinciden con la plantilla ensayada.
- Regresion completa del mismo restore: 28/28 pruebas SQL.
- Master authenticated sin bypass RLS ejecuta el circuito PYG/USD completo.
- Golden PYG: 14M vendido, 10M facturado, 7M cobrado, 4M por facturar y 3M por cobrar.
- Reintentos sin duplicar propuesta, venta, factura o cobro; sobrefacturacion rechazada.
- Usuario restringido sin operaciones; lector financiero consulta sin facturar.
- Comision historica y seleccion cerrada protegidas.
- Fixtures y cambios temporales revertidos mediante ROLLBACK.
- Node: 9/9 PASS; TypeScript, bash -n y git diff --check PASS.
- Build Next.js 15.5.27: PASS, 11/11 paginas estaticas.
- Tres pruebas de circuito/comision tambien pasaron en equantum_restore_clean.
- Log: /home/equantumg/equantum-commercial-flow-validacion.txt.

El test inicial de asignacion combinaba escritura y lectura en una expresion.
Se separaron en sentencias consecutivas manteniendo ambas aserciones.
La correccion paso sin cambiar migracion, funciones ni permisos, conservando
el restore y la evidencia previa 22/22.

## Limites

JWT/UID simulado en PostgreSQL no valida Auth remoto, Data API con sesion real
ni recorrido visual de navegador. Advisors, configuracion fiscal operativa y
matriz ACC/IT/INT siguen pendientes; no se certifica todo Finanzas/Documento 19.

Master conserva escritura directa autorizada por RLS: las RPC invoker no son
un canal exclusivo. Las validaciones nuevas no sustituyen automaticamente
contratos legados como create_invoice_v2; falta revision integral de esas APIs.
Versiones posteriores de propuestas, Quick Sale sin oportunidad y conversion
multimoneda gobernada no quedan certificados.

La plantilla y los instaladores preparatorios quedan en el historial Git.
El runner final referencia la migracion generada por CLI y conserva modo ejecutable.
Main y produccion no se modificaron. Release no autorizado.
