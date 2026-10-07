#!/usr/bin/env bash

qa_db="${1:-equantum_restore_clean}"
qa_container="equantum-staging"

if [ "$qa_db" = "equantum_restore_clean" ]; then
  qa_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  shopt -s nullglob
  qa_tests=("$qa_root"/supabase/tests/*.sql)
  qa_pass=0
  qa_fail=0
  qa_log="$(mktemp /tmp/equantum-qa-sql.XXXXXX)"

  if [ -n "$qa_log" ] && [ "${#qa_tests[@]}" -gt 0 ]; then
    echo "QA LOCAL | container=$qa_container | database=$qa_db"

    for qa_file in "${qa_tests[@]}"; do
      docker exec -i "$qa_container" psql \
        -U postgres -d "$qa_db" -X \
        -v ON_ERROR_STOP=1 -P pager=off \
        < "$qa_file" > "$qa_log" 2>&1
      qa_rc=$?

      if [ "$qa_rc" -eq 0 ]; then
        echo "PASS | ${qa_file##*/}"
        qa_pass=$((qa_pass + 1))
      else
        echo "FAIL | ${qa_file##*/} | code=$qa_rc"
        cat "$qa_log"
        qa_fail=$((qa_fail + 1))
      fi
    done

    rm -f "$qa_log"
    echo "PASS=$qa_pass FAIL=$qa_fail TOTAL=${#qa_tests[@]}"
    [ "$qa_fail" -eq 0 ]
  else
    echo "FAIL: no hay tests SQL o no se pudo crear el log temporal"
    false
  fi
else
  echo "FAIL: este runner solo admite equantum_restore_clean"
  false
fi
