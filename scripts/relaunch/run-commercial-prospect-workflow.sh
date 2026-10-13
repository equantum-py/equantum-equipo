#!/usr/bin/env bash
set -euo pipefail
umask 077

readonly expected_ref="rqisyolaffwktxhjwpqq"
readonly expected_pooler="aws-1-us-west-2.pooler.supabase.com"
readonly expected_db_user="postgres.rqisyolaffwktxhjwpqq"

if [[ "${P1_TEST_PROJECT_REF:-}" != "$expected_ref" ]]; then
  echo "BLOCKED: P1_TEST_PROJECT_REF must identify the isolated P1 test project."
  exit 2
fi
if [[ -z "${P1_TEST_DATABASE_URL:-}" ]]; then
  echo "BLOCKED: set the test database connection in this private shell."
  exit 2
fi
if ! command -v psql >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; then
  echo "BLOCKED: psql and python3 are required."
  exit 2
fi

python3 - <<'PY'
from urllib.parse import unquote, urlsplit
import os, sys
u = urlsplit(os.environ.get("P1_TEST_DATABASE_URL", ""))
ok = (u.scheme in ("postgres", "postgresql")
      and u.hostname == "aws-1-us-west-2.pooler.supabase.com"
      and unquote(u.username or "") == "postgres.rqisyolaffwktxhjwpqq"
      and u.port == 5432 and u.path == "/postgres")
if not ok:
    print("BLOCKED: the connection target is not the authorized test-project pooler.")
    sys.exit(2)
print("PASS: database URL identifies only the isolated test-project pooler.")
PY

fixture_file="${P1_FIXTURE_STATE_FILE:-$HOME/.cache/equantum-p1/${expected_ref}-auth-fixtures.json}"
mapfile -t actor_ids < <(python3 - "$fixture_file" <<'PY'
import json, pathlib, sys
p=pathlib.Path(sys.argv[1])
try:
    st=p.stat()
    if st.st_mode & 0o077:
        raise ValueError("fixture file permissions must be 0600")
    data=json.loads(p.read_text())
    if data.get("project_ref") != "rqisyolaffwktxhjwpqq":
        raise ValueError("fixture file is for another project")
    users={u.get("actor"):u.get("id") for u in data.get("users",[])}
    required=("internal_owner","internal_peer","portal_a")
    if any(not users.get(actor) for actor in required):
        raise ValueError("fixture file is missing required synthetic actors")
    for actor in required:
        print(users[actor])
except Exception as e:
    print(f"BLOCKED: synthetic fixture state is unavailable or invalid ({e}).", file=sys.stderr)
    sys.exit(2)
PY
)
if [[ "${#actor_ids[@]}" -ne 3 ]]; then
  echo "BLOCKED: could not load the three required synthetic Auth identities."
  exit 2
fi

preflight=$(psql --no-password "$P1_TEST_DATABASE_URL" -X -A -t -F '|' \
  -v ON_ERROR_STOP=1 \
  -c "SELECT current_database(), current_user, to_regclass('auth.users') IS NOT NULL, to_regprocedure('public.save_prospect(uuid,uuid,jsonb,jsonb,jsonb,boolean)') IS NOT NULL" 2>/dev/null) || {
  echo "BLOCKED: read-only database preflight failed; connection details were suppressed."
  exit 2
}
if [[ "$preflight" != "postgres|postgres|t|t" ]]; then
  echo "BLOCKED: database identity or reviewed Prospect workflow migration is absent."
  exit 2
fi
echo "PASS: connected to the authorized test database; migration RPC and Auth schema are present."

exec psql --no-password "$P1_TEST_DATABASE_URL" -X -P pager=off -v ON_ERROR_STOP=1 \
  -v manager_id="${actor_ids[0]}" -v denied_id="${actor_ids[1]}" -v portal_id="${actor_ids[2]}" \
  -f supabase/tests/commercial_prospect_workflow_v1.sql
