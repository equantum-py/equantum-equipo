# Fiscalidad y comisión — contrato existente

Base: 9437f36. Prueba: supabase/tests/financial_fiscal_snapshot_v3.sql.

La prueba usa el cierre real Opportunity→Proposal→Sale en PostgreSQL y termina con ROLLBACK. Verifica configuraciones explícitas de prueba PYG gravada, USD gravada y USD sin impuesto; moneda, impuesto, importe bruto, importe neto, base de comisión sin IVA y snapshot por línea. Modifica la propuesta después del cierre y reintenta WON para comprobar que no recalcula el snapshot. Comprueba ausencia de fixtures residuales.

Las tasas y etiquetas son fixtures de ingeniería, no políticas legales. El test se ejecuta como postgres y no certifica permisos de administración fiscal.

Gap confirmado al revisar las 19 migraciones versionadas: existe commission_base_amount pero no una política/version/porcentaje histórico de comisión; tax_treatment es texto explícito sin registro de políticas fiscales y clasificación gobernada.

Estado: test preparado; ejecución local pendiente. FIN004 tiene cobertura directa preparada del cierre con moneda independiente del impuesto. FIN005 continúa pendiente de política/clasificación gobernada; FIN006 tiene base sin IVA pero no cálculo persistido de comisión; FIN007 continúa pendiente de versión y porcentaje histórico. No se marca PASS ni se infiere una comisión global del 5%.
