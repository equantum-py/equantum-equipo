# Comisión versionada — candidato local

Base: b9739f3. SQL preparatorio: scripts/relaunch/sql/commission_policies_v3.sql.

Cada versión registra código, versión, porcentaje explícito y autor. RLS permite crear a Master activo y leer a Master o usuario con financial_info. Se revocan UPDATE/DELETE/TRUNCATE del rol authenticated y un trigger bloquea cambios de versiones históricas. No se agrega SECURITY DEFINER.

Proposal elige commission_policy_id; el cierre existente WON crea Sale y el trigger guarda código, versión, porcentaje, base sin IVA e importe redondeado a dos decimales. Los campos históricos no pueden editarse. Si no hay política explícita, porcentaje/importe quedan NULL: no se impone 5% ni se inventa historial. No se configuran políticas productivas.

Prueba SQL: Master autenticado crea versiones QA 5% y 7%; cierre real con base 10M/IVA 1M produce 500000 y 700000; retry y cambio de Proposal preservan la comisión histórica; snapshot/políticas rechazan modificaciones; usuario restringido no lee/crea políticas; ROLLBACK comprueba cero fixtures. El 5% y el 7% son fixtures oficiales de aceptación, no tasas generales.

Validación local: migración generada por CLI como 20261008021415_commission_policies_v3.sql, aplicada a equantum_restore_clean; prueba directa y QA PASS=25 FAIL=0 TOTAL=25. Se demostraron importe sin IVA, porcentaje/versionado histórico, política ausente NULL, Master autorizado y actor restringido. Evidencia: /home/equantumg/equantum-commission-validacion.txt. Alcance PostgreSQL local; E2E/UI pendientes. El instalador local genera la migración con Supabase CLI, agrega su nombre al runner ordenado, aplica solo a equantum_restore_clean y ejecuta prueba+QA. No hace commit, push, merge ni despliegue.

Pendiente antes de integrar: nombre real generado por CLI, ejecución SQL, QA completo, inspección de advisors y ensayo desde restore limpio. Pendiente de producto: interfaz para gestionar/elegir las políticas, E2E y definición operativa/fiscal completa. No se migra producción.

## Ensayo de runner pendiente

El candidato incluye la migración real generada por CLI y el runner con 20 migraciones. Falta ejecutar scripts/relaunch/rehearse-commission-local.py sobre una base nueva equantum_commission_rehearsal restaurada desde el baseline, con Vault explícitamente excluido. No se toca equantum_restore_clean ni se sobrescribe ninguna base existente. Este ensayo comprueba baseline 11 tablas, 20/20 migraciones en orden y 25/25 pruebas; no certifica todavía rollback final de release ni E2E.
