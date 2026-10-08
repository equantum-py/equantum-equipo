#!/usr/bin/env bash

DB="${1:-equantum_restore_clean}"
CONTAINER="${2:-equantum-staging}"

MIGRATIONS=(
  "20261006_model_data_v2_expand.sql"
  "20261006_identity_commercial_v2_data.sql"
  "20261006_catalog_pipeline_v2.sql"
  "20261006_proposals_sales_v2.sql"
  "20261006_active_services_projects_tasks_v2.sql"
  "20261006_security_permissions_v2.sql"
  "20261007_security_internal_boundary_v31.sql"
  "20261007_security_functions_v32.sql"
  "20261007_commercial_operations_v2.sql"
  "20261007_financial_core_v2.sql"
  "20261007_financial_operations_v2.sql"
  "20261007_sensitive_financial_permission_v2.sql"
  "20261007_radar_engine_v2.sql"
  "20261007_radar_operational_access_v2.sql"
  "20261007_triage_engine_v2.sql"
  "20261007_tasks_security_history_v2.sql"
  "20261007_rls_model_v2.sql"
  "20261007_security_portal_rls_v3.sql"
  "20261008013538_release_guards_v3.sql"
)

PASS=0
FAIL=0

for name in "${MIGRATIONS[@]}"; do
  file="supabase/migrations/$name"

  docker exec -i "$CONTAINER" \
    psql -U postgres -d "$DB" -v ON_ERROR_STOP=1 -q \
    < "$file" \
    > /tmp/equantum-migration.out \
    2> /tmp/equantum-migration.err

  rc=$?

  if [ "$rc" -eq 0 ]; then
    echo "PASS | $name"
    PASS=$((PASS+1))
  else
    echo "FAIL | $name"
    cat /tmp/equantum-migration.err
    FAIL=$((FAIL+1))
    break
  fi
done

echo "ATTEMPTED=$((PASS+FAIL))"
echo "PASS=$PASS"
echo "FAIL=$FAIL"
echo "TOTAL=${#MIGRATIONS[@]}"

if [ "$FAIL" -gt 0 ]; then
  false
fi
