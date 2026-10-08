# Comisión versionada — candidato local

Base: b9739f3. SQL preparatorio: scripts/relaunch/sql/commission_policies_v3.sql.

Cada versión registra código, versión, porcentaje explícito y autor. RLS permite crear a Master activo y leer a Master o usuario con financial_info. Se revocan UPDATE/DELETE/TRUNCATE del rol authenticated y un trigger bloquea cambios de versiones históricas. No se agrega SECURITY DEFINER.

Proposal elige commission_policy_id; el cierre existente WON crea Sale y el trigger guarda código, versión, porcentaje, base sin IVA e importe redondeado a dos decimales. Los campos históricos no pueden editarse. Si no hay política explícita, porcentaje/importe quedan NULL: no se impone 5% ni se inventa historial. No se configuran políticas productivas.

Prueba SQL: Master autenticado crea versiones QA 5% y 7%; cierre real con base 10M/IVA 1M produce 500000 y 700000; retry y cambio de Proposal preservan la comisión histórica; snapshot/políticas rechazan modificaciones; usuario restringido no lee/crea políticas; ROLLBACK comprueba cero fixtures. El 5% y el 7% son fixtures oficiales de aceptación, no tasas generales.

Validación: sintaxis Python del instalador y revisión del código. SQL todavía sin ejecutar. No se marcan PASS FIN006/FIN007. El instalador local genera la migración con Supabase CLI, agrega su nombre al runner ordenado, aplica solo a equantum_restore_clean y ejecuta prueba+QA. No hace commit, push, merge ni despliegue.

Pendiente antes de integrar: nombre real generado por CLI, ejecución SQL, QA completo, inspección de advisors y ensayo desde restore limpio. Pendiente de producto: interfaz para gestionar/elegir las políticas, E2E y definición operativa/fiscal completa. No se migra producción.
