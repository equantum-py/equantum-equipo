#!/usr/bin/env bash

# Repeatable local application checks for the P1 candidate.
# Uses deliberately invalid public Supabase values for build-time initialization.
# This script does not connect to Supabase and does not run SQL.

set -u

main() {
  local repo_root branch commit failed passed
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  cd "$repo_root" || return 1

  branch="$(git branch --show-current 2>/dev/null || printf 'unknown')"
  commit="$(git rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
  failed=0
  passed=0

  run_check() {
    local label="$1"
    shift
    printf '=== %s | branch=%s commit=%s ===\n' "$label" "$branch" "$commit"
    "$@"
    local rc=$?
    if [ "$rc" -eq 0 ]; then
      printf 'PASS | %s\n' "$label"
      passed=$((passed + 1))
    else
      printf 'FAIL | %s | code=%s\n' "$label" "$rc"
      failed=$((failed + 1))
    fi
  }

  run_check "P1 operations + finance Node tests" npm run test:operations
  run_check "TypeScript" npx --no-install tsc --noEmit
  run_check "Next.js build with non-routable Supabase placeholders" \
    env \
    NEXT_PUBLIC_SUPABASE_URL="https://example.invalid" \
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY="sb_publishable_local_test_placeholder" \
    npm run build

  printf 'APP_LOCAL_PASS=%s APP_LOCAL_FAIL=%s TOTAL=%s\n' \
    "$passed" "$failed" "$((passed + failed))"
  printf 'SQL=NOT_RUN (requires the project\x27s isolated PostgreSQL baseline)\n'

  [ "$failed" -eq 0 ]
}

main "$@"
