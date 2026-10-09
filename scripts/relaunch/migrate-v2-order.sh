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
  "20261008021415_commission_policies_v3.sql"
  "20261008024203_fiscal_policy_governance_v3.sql"
  "20261008031852_commercial_flow_v3.sql"
  "20261008120000_tasks_radar_workflow_v3.sql"
  "20261008143000_p1_task_write_scope_archive_radar_v1.sql"
)

run_migrations() {
  local script_dir repo_root branch commit docker_context container_state identity actual_db actual_user sql_tests name file rc
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(cd "$script_dir/../.." && pwd)"
  branch="$(git -C "$repo_root" branch --show-current 2>/dev/null)"
  commit="$(git -C "$repo_root" rev-parse --short HEAD 2>/dev/null)"

  if [ "$branch" != "relanzamiento-2026" ]; then
    echo "FAIL: rama requerida relanzamiento-2026; rama actual=${branch:-desconocida}"
    return 1
  fi

  if [ "$CONTAINER" != "equantum-staging" ]; then
    echo "FAIL: contenedor permitido=equantum-staging; recibido=$CONTAINER"
    return 1
  fi

  case "$DB" in
    equantum_restore_clean|equantum_staging) ;;
    *)
      echo "FAIL: DB permitida=equantum_restore_clean o equantum_staging; recibido=$DB"
      return 1
      ;;
  esac

  container_state="$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)"
  if [ "$container_state" != "true" ]; then
    echo "FAIL: contenedor local $CONTAINER no está activo"
    return 1
  fi

  identity="$(docker exec "$CONTAINER" psql -U postgres -d "$DB" -X -At -F '|' -c 'SELECT current_database(), current_user' 2>&1)"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "FAIL: no se pudo abrir la base objetivo; container=$CONTAINER database=$DB"
    echo "$identity"
    return 1
  fi

  IFS='|' read -r actual_db actual_user <<< "$identity"
  if [ "$actual_db" != "$DB" ] || [ "$actual_user" != "postgres" ]; then
    echo "FAIL: identidad inesperada; pedido=$DB/postgres recibido=$actual_db/$actual_user"
    return 1
  fi

  docker_context="$(docker context show 2>/dev/null)"
  docker_context="${docker_context:-desconocido}"
  sql_tests="$(find "$repo_root/supabase/tests" -maxdepth 1 -type f -name '*.sql' 2>/dev/null | wc -l | tr -d '[:space:]')"
  echo "MIGRATIONS LOCAL | branch=$branch commit=$commit docker_context=$docker_context container=$CONTAINER database=$actual_db user=$actual_user migrations=${#MIGRATIONS[@]} sql_tests=${sql_tests:-0}"

  for name in "${MIGRATIONS[@]}"; do
    file="$repo_root/supabase/migrations/$name"
    if [ ! -f "$file" ]; then
      echo "FAIL: falta migración versionada $file"
      return 1
    fi
  done

  local pass=0 fail=0
  for name in "${MIGRATIONS[@]}"; do
    file="$repo_root/supabase/migrations/$name"
    docker exec -i "$CONTAINER" \
      psql -U postgres -d "$DB" -X -v ON_ERROR_STOP=1 -q \
      < "$file" > /tmp/equantum-migration.out 2> /tmp/equantum-migration.err
    rc=$?

    if [ "$rc" -eq 0 ]; then
      echo "PASS | $name"
      pass=$((pass+1))
    else
      echo "FAIL | $name"
      cat /tmp/equantum-migration.err
      fail=$((fail+1))
      break
    fi
  done

  echo "ATTEMPTED=$((pass+fail))"
  echo "PASS=$pass"
  echo "FAIL=$fail"
  echo "TOTAL=${#MIGRATIONS[@]}"

  if [ "$fail" -gt 0 ]; then
    return 1
  fi
  return 0
}

run_migrations "$@"
