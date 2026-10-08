# Resumen financiero por moneda — candidato de revisión

Base: adf3574, rama relanzamiento-2026.

La vista Finanzas muestra vendido, facturado, cobrado, pendiente de facturar y pendiente de cobro por moneda. El pendiente de facturar se calcula por Sale; una sobrefacturación no compensa otra venta sin factura. Se excluyen facturas draft/void y cobros pendientes/revertidos conforme al helper existente. Las consultas se paginan y los errores muestran valores no disponibles.

Verificación realizada: 9/9 tests Node del helper, incluyendo DOC12 FIN001, importes PYG FIN008, separación de moneda FIN003 y exceso de facturación. La muestra USD 500/300/100 es un caso adicional de prueba, no una cifra Golden oficial. Sintaxis TS/TSX verificada.

Pendiente: TypeScript del repo completo, production build, QA SQL y E2E con permisos reales y datos de la base local. Las pruebas del helper no certifican los ACC completos ni las políticas fiscales/comisiones. No se cambia el estado de los registros de aceptación.

Este candidato no modifica migraciones, main ni producción. No se invocaron servicios pagos.
