# Asignacion de comision a propuestas — candidato local

Base: a3d0c0e, relanzamiento-2026. No integrar sin evidencia local.

La interfaz permite seleccionar una version explicita de comision o retirar
la seleccion antes del cierre. Usa assign_proposal_commission_v3 con la sesion
del usuario. Requiere Master activo con financial_info.

La plantilla agrega SELECT para propuestas, oportunidades y ventas, sujeto a
sus politicas RLS financieras existentes, y UPDATE solo de commission_policy_id
en propuestas. La politica Master UPDATE ya instalada en fiscalidad sigue
controlando las filas. No se agrega SECURITY DEFINER ni bypass de RLS.

Un trigger bloquea cambios de seleccion en propuestas aceptadas/rechazadas,
oportunidades cerradas y oportunidades con venta. Un reintento con la misma
seleccion no modifica nada. El cierre copia la version/base/importe existentes
al snapshot historico de la venta. La prueba previa de snapshots se adapta
para exigir rechazo de reasignacion posterior al cierre.

El instalador genera la migracion usando el CLI ya instalado, ensaya el runner
desde un nuevo restore con las exclusiones Vault previamente validadas, ejecuta
27 pruebas SQL y luego actualiza exclusivamente la base PostgreSQL local habitual.
Tambien ejecuta pruebas financieras, TypeScript y build.

Preparacion revisada; validacion PostgreSQL completa, build del candidato,
advisors y recorrido real de navegador/Data API: PENDIENTES.
La plantilla no es una migracion aplicada ni una configuracion operativa de tasas.
Main y produccion no se modifican.
