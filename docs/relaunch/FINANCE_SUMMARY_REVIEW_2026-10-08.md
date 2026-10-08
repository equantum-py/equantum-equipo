# Resumen financiero por moneda — candidato de revisión

Base: adf3574, rama relanzamiento-2026.

La vista Finanzas muestra vendido, facturado, cobrado, pendiente de facturar y pendiente de cobro por moneda. El pendiente de facturar se calcula por Sale; una sobrefacturación no compensa otra venta sin factura. Se excluyen facturas draft/void y cobros pendientes/revertidos conforme al helper existente. Las consultas se paginan y los errores muestran valores no disponibles.

Verificación realizada: 9/9 tests Node del helper, incluyendo DOC12 FIN001, importes PYG FIN008, separación de moneda FIN003 y exceso de facturación. La muestra USD 500/300/100 es un caso adicional de prueba, no una cifra Golden oficial. Sintaxis TS/TSX verificada.

Pendiente: TypeScript del repo completo, production build, QA SQL y E2E con permisos reales y datos de la base local. Las pruebas del helper no certifican los ACC completos ni las políticas fiscales/comisiones. No se cambia el estado de los registros de aceptación.

Este candidato no modifica migraciones, main ni producción. No se invocaron servicios pagos.

## Validación adicional

La primera ejecución en Cloud Shell aprobó 9/9 tests y diff --check, pero TypeScript detuvo la validación con TS2352 por select dinámico. Se reemplazó por consultas con columnas literales y paginación genérica tipada sin conversiones forzadas. La comprobación aislada de tipos de la carga con el cliente Supabase y los 9 tests pasaron después del cambio. Sigue pendiente la repetición de TypeScript del repo completo, build y QA SQL en Cloud Shell; no se marcaron PASS esos pasos.

## Resultado final de validación local

El candidato 1891cf7 fue validado en Cloud Shell: tests del helper 9/9, TypeScript completo, build Next.js 15.5.27 (11/11 páginas) y QA SQL 23/23 aprobados. git diff --check sin errores. Evidencia: /home/equantumg/equantum-finance-validacion.txt. La validación fue en un worktree separado, con la base equantum_restore_clean del contenedor equantum-staging.

Esta evidencia reemplaza el estado pendiente de repetición indicado arriba. El E2E de la vista con datos y permisos reales sigue pendiente. El cambio se integra únicamente a relanzamiento-2026; no se cierran globalmente FIN001/FIN003/FIN008 ni Finanzas.
