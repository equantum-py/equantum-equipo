# Política fiscal gobernada — candidato local

Base: e397eac (restaura ejecutabilidad del runner). SQL preparatorio: scripts/relaunch/sql/fiscal_policy_governance_v3.sql. No aplicado a producción.

Políticas: código/versión inmutables, clasificación y tasa explícitas, referencia de fundamento y autor. Clasificaciones de ingeniería: taxable, export_zero, exempt. Las configuraciones se introducen por Master activo; no hay tasas ni políticas productivas precargadas. Las referencias guardadas no constituyen por sí mismas verificación legal del tratamiento.

Aprobación: Master activo con financial_info usa approve_proposal_item_fiscal_v3 para indicar política, motivo y referencia de evidencia por Proposal Item. La base/currency/autor/hora se calculan y estampan en backend. El RPC actualiza el Item y los totales de Proposal. La moneda no decide impuesto. La política aprobada calcula el impuesto sobre quantity*unit_price menos descuento; export_zero/exempt requieren tasa cero. Cambios de base/currency requieren una nueva versión de propuesta/decisión compatible.

Histórico: Sale Items guardan decisión, código/versión/tasa, aprobador/hora/evidencia. Trigger valida que los importes copiados concuerden con la decisión y bloquea modificaciones del snapshot. Nuevas versiones de política no recalculan ventas anteriores. Items legacy sin aprobación conservan tratamiento explícito previo, sin inventar aprobaciones ni certificar su validez fiscal.

Seguridad: tablas nuevas con RLS, creación de políticas/aprobaciones limitada a Master, lectura a Master o financial_info, funciones SECURITY INVOKER. Se agregan políticas UPDATE restringidas a Master con financial_info en proposals/proposal_items y grants de columnas para el RPC. Las políticas existentes se conservan; los grants restaurados/administrados y la revisión final de advisors deben verificarse antes de release.

Tests preparados: Master autenticado crea políticas y aprueba cuatro escenarios PYG gravada, USD gravada, USD export_zero y USD exempt; rechaza export con tasa no cero y motivo vacío; importa original inconsistente reemplazado por cálculo; totales de propuesta, cierre real, evidencia de snapshot, protección de base/histórico, nueva política y actor restringido. ROLLBACK comprueba cero fixtures. Tasas 10/15 son únicamente fixtures de ingeniería, no tasas legales configuradas.

Validación pendiente: SQL, baseline restore, 21 migraciones y 26 tests. validate-fiscal-local.py genera migración con CLI, ensaya sobre una base nueva equantum_fiscal_rehearsal desde baseline (Vault excluido), y solo después de aprobar actualiza equantum_restore_clean y ejecuta allí el test fiscal. No hace commit/push/merge/despliegue; no sobrescribe bases existentes.

Pendientes de producto: UI, E2E, configuración/aprobación operativa con referencias reales, seguridad final/advisors y rollback de release. No se marca PASS FIN005 ni el conjunto de Finanzas antes de ejecutar y evaluar alcance.
