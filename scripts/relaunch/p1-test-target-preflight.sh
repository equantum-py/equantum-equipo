#!/usr/bin/env bash

# Read-only safety check before using a direct PostgreSQL connection for P1–P7.
# The connection URL is read from the environment and is never printed.
readonly expected_ref="rqisyolaffwktxhjwpqq"

main() {
  if [ "${P1_TEST_PROJECT_REF:-}" != "$expected_ref" ]; then
    echo "BLOCKED: set P1_TEST_PROJECT_REF to the authorized test project reference."
    return 1
  fi

  if [ -z "${P1_TEST_DATABASE_URL:-}" ]; then
    echo "BLOCKED: P1_TEST_DATABASE_URL is not configured in this shell."
    return 1
  fi

  if ! command -v psql >/dev/null 2>&1; then
    echo "BLOCKED: psql is not installed."
    return 1
  fi

  local authority host query_result query_rc
  authority="${P1_TEST_DATABASE_URL#*://}"
  authority="${authority##*@}"
  host="${authority%%/*}"
  host="${host%%:*}"
  if [ "$host" != "db.${expected_ref}.supabase.co" ]; then
    echo "BLOCKED: database host does not identify the authorized P1 test project."
    return 1
  fi

  query_result=$(psql --no-password "$P1_TEST_DATABASE_URL" -X -A -t -F '|' \
    -v ON_ERROR_STOP=1 \
    -c "SELECT current_database(), current_user, current_setting('server_version_num')::int >= 170000, to_regclass('auth.users') IS NOT NULL, to_regclass('storage.objects') IS NOT NULL" \
    2>/dev/null)
  query_rc=$?
  if [ "$query_rc" -ne 0 ]; then
    echo "BLOCKED: read-only database preflight failed; connection details were suppressed."
    return 1
  fi

  if [ "$query_result" != "postgres|postgres|t|t|t" ]; then
    echo "BLOCKED: database identity or managed Auth/Storage prerequisites did not match."
    return 1
  fi

  echo "PASS: connected to the authorized test ref, PostgreSQL 17, as postgres; Auth and Storage are present."
}

main "$@"
