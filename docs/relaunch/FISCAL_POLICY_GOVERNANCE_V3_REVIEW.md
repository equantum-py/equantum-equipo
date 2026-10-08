# Política fiscal gobernada — validación local aprobada

Migración real generada por CLI: supabase/migrations/20261008024203_fiscal_policy_governance_v3.sql. Base: e397eac.

Políticas versionadas e inmutables: código, clasificación, tasa explícita, referencia de fundamento y autor. Master activo las crea; Master con financial_info aprueba por Proposal Item mediante approve_proposal_item_fiscal_v3, con motivo y evidencia. Backend valida y estampa base/moneda/autor/hora, aplica la tasa y actualiza totales de Proposal. No infiere impuesto por moneda ni usa IA. Referencias registradas no constituyen validación legal automática.

Histórico: Sale Items conservan aprobación, código/versión/tasa y autor/hora/evidencia. Se comprueba que el cierre copia importes aprobados y se bloquea modificación del snapshot. Nuevas políticas/aprobaciones no recalculan ventas anteriores. Items legacy sin aprobación mantienen el comportamiento explícito previo.

Seguridad: nuevas tablas con RLS; Master crea/aprueba, Master o financial_info leen; funciones SECURITY INVOKER. Grants de columnas y políticas UPDATE Master con financial_info habilitan el RPC sin ampliar permisos al actor restringido. Políticas existentes conservadas; revisión final de advisors/grants y E2E pendientes.

## Evidencia

Candidato 6500d81. Archivo /home/equantumg/equantum-fiscal-governance-validacion.txt.

Restore nuevo equantum_fiscal_rehearsal: baseline 11 tablas reconciliado, 21/21 migraciones y 26/26 tests aprobados. Vault excluido con lista del restore validado. Luego se aplicó solo la nueva migración a equantum_restore_clean y se repitió allí el test fiscal, aprobado.

Tests: Master autenticado aprueba cuatro escenarios PYG gravada, USD gravada, USD export_zero y USD exempt; se prueban cálculo/totales/snapshot, rechazo de configuración inválida/motivo vacío, integridad de base e histórico, nueva política y actor restringido. ROLLBACK verifica cero fixtures. Tasas 10/15 son fixtures de ingeniería; no tasas legales configuradas.

El SQL preparatorio y el instalador de una sola ejecución se retiran tras generar/probar la migración real. Runner mantiene permiso 100755 e incluye su nombre.

## Pendientes

UI, E2E, configuración/aprobación operativa con referencias reales, advisors/seguridad final y rollback de release. No se certifica Finanzas completo ni producción. Main y producción sin cambios.
