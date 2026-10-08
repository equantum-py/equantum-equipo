# Comisión versionada — implementación validada localmente

Base de implementación: b9739f3. Migración generada con CLI: supabase/migrations/20261008021415_commission_policies_v3.sql.

Cada versión registra código, versión, porcentaje explícito y autor. RLS permite crear a Master activo y leer a Master o usuario con financial_info. Se revocan UPDATE/DELETE/TRUNCATE del rol authenticated y un trigger bloquea cambios de versiones históricas. No se agregó SECURITY DEFINER.

Proposal elige commission_policy_id; el cierre WON existente crea Sale y el trigger guarda código, versión, porcentaje, base sin IVA e importe redondeado a dos decimales. Los campos históricos no pueden editarse. Sin política explícita, porcentaje/importe quedan NULL: no se impone 5% ni se inventa historial. No se configuraron políticas productivas.

Prueba: supabase/tests/commission_policy_snapshot_v3.sql. Master autenticado crea versiones QA 5% y 7%; base 10M/IVA 1M produce 500000 y 700000; retry y cambio de Proposal preservan comisión histórica; snapshot/políticas rechazan modificaciones; usuario restringido no lee/crea políticas; ROLLBACK comprueba cero fixtures. Los porcentajes son fixtures de aceptación.

## Evidencia

Aplicación y QA local: equantum_restore_clean, PASS=25 FAIL=0 TOTAL=25. Archivo /home/equantumg/equantum-commission-validacion.txt.

Ensayo desde restore nuevo: candidato 05bfe23; equantum_commission_rehearsal, contenedor equantum-staging. Baseline 11 tablas reconciliado, runner 20/20, pruebas SQL 25/25. Archivo /home/equantumg/equantum-commission-rehearsal.txt. Vault excluido explícitamente. Base previa conservada; no se borraron bases existentes.

El SQL preparatorio y el instalador de una sola ejecución se retiran del repo después de convertirlos en migración real. El runner contiene el nombre generado. El script rehearse-commission-local.py conserva el contrato del checkpoint (20 migraciones/25 tests); no es un runner genérico para futuras versiones.

## Alcance pendiente

UI para gestionar/elegir políticas, E2E, revisión final de seguridad/advisors, configuración fiscal/operativa completa y rollback final de release. Evidencia aprobada dentro de PostgreSQL/RLS local; no certifica Finanzas completo ni autoriza producción.
