#!/usr/bin/env bash

run_sql_qa() {
  local qa_db="${1:-equantum_restore_clean}"
  local qa_container="equantum-staging"
  local qa_root branch commit container_state identity actual_db actual_user qa_log qa_rc
  qa_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  branch="$(git -C "$qa_root" branch --show-current 2>/dev/null)"
  commit="$(git -C "$qa_root" rev-parse --short HEAD 2>/dev/null)"

  if [ "$branch" != "relanzamiento-2026" ]; then
    echo "FAIL: QA requiere rama relanzamiento-2026; rama actual=${branch:-desconocida}"
    return 1
  fi
  if [ "$qa_db" != "equantum_restore_clean" ]; then
    echo "FAIL: este runner solo admite database=equantum_restore_clean"
    return 1
  fi

  container_state="$(docker inspect -f '{{.State.Running}}' "$qa_container" 2>/dev/null)"
  if [ "$container_state" != "true" ]; then
    echo "FAIL: contenedor local $qa_container no está activo"
    return 1
  fi

  identity="$(docker exec "$qa_container" psql -U postgres -d "$qa_db" -X -At -F '|' -c 'SELECT current_database(), current_user' 2>&1)"
  qa_rc=$?
  if [ "$qa_rc" -ne 0 ]; then
    echo "FAIL: no se pudo abrir la base QA; container=$qa_container database=$qa_db"
    echo "$identity"
    return 1
  fi
  IFS='|' read -r actual_db actual_user <<< "$identity"
  if [ "$actual_db" != "$qa_db" ] || [ "$actual_user" != "postgres" ]; then
    echo "FAIL: identidad inesperada; pedido=$qa_db/postgres recibido=$actual_db/$actual_user"
    return 1
  fi

  shopt -s nullglob
  local qa_tests=("$qa_root"/supabase/tests/*.sql)
  local qa_pass=0 qa_fail=0
  qa_log="$(mktemp /tmp/equantum-qa-sql.XXXXXX)"
  if [ -z "$qa_log" ] || [ "${#qa_tests[@]}" -eq 0 ]; then
    echo "FAIL: no hay tests SQL o no se pudo crear el log temporal"
    return 1
  fi

  echo "QA LOCAL | branch=$branch commit=$commit container=$qa_container database=$actual_db user=$actual_user tests=${#qa_tests[@]}"

  for qa_file in "${qa_tests[@]}"; do
    docker exec -i "$qa_container" psql \
      -U postgres -d "$qa_db" -X -v ON_ERROR_STOP=1 -P pager=off \
      < "$qa_file" > "$qa_log" 2>&1
    qa_rc=$?

    if [ "$qa_rc" -eq 0 ]; then
      echo "PASS | ${qa_file##*/}"
      qa_pass=$((qa_pass+1))
    else
      echo "FAIL | ${qa_file##*/} | code=$qa_rc"
      cat "$qa_log"
      qa_fail=$((qa_fail+1))
    fi
  done

  rm -f "$qa_log"
  echo "PASS=$qa_pass FAIL=$qa_fail TOTAL=${#qa_tests[@]}"
  [ "$qa_fail" -eq 0 ]
}

run_sql_qa "$@"
