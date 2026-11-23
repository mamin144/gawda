#!/usr/bin/env bash
# Runs the pgTAP files in supabase/tests/database against the linked remote
# project with psql (fallback for `supabase test db --remote`, which needs
# Docker). Each test file wraps itself in begin; ... rollback;.
#
# Connection: host and user come from supabase/.temp/pooler-url (written by
# `supabase link`, git-ignored, holds no password). The password is read by
# psql from the owner's pgpass file (%APPDATA%\postgresql\pgpass.conf); it is
# never passed on the command line or stored in this repo.
#
# Usage: bash supabase/tests/run_remote.sh [test files...]
set -u

root="$(cd "$(dirname "$0")/../.." && pwd)"
url_file="$root/supabase/.temp/pooler-url"
psql_bin="${PSQL:-/c/Program Files/PostgreSQL/17/bin/psql.exe}"

if [[ ! -f "$url_file" ]]; then
  echo "error: $url_file missing; run 'supabase link' first" >&2
  exit 2
fi
url="$(tr -d '\r\n' < "$url_file")"
if [[ "$url" =~ ://[^/@]+:[^/@]+@ ]]; then
  echo "error: pooler-url contains a password; refusing to use it" >&2
  exit 2
fi

if [[ $# -gt 0 ]]; then
  files=("$@")
else
  files=("$root"/supabase/tests/database/*.test.sql)
fi

export PGSSLMODE=require
failed=0
total=0
for f in "${files[@]}"; do
  name="$(basename "$f" .test.sql)"
  out="$("$psql_bin" "$url" -w -X -q -t -A -v ON_ERROR_STOP=1 -f "$f" 2>&1)"
  rc=$?
  passed="$(grep -cE '^ok [0-9]+' <<<"$out")"
  planned="$(grep -oE '^1\.\.[0-9]+' <<<"$out" | head -1 | cut -d. -f3)"
  if [[ $rc -ne 0 ]] || grep -qE '^not ok|Looks like you|ERROR:' <<<"$out" \
     || [[ -z "$planned" || "$passed" != "$planned" ]]; then
    echo "$name ... FAIL"
    grep -E '^not ok|^#|ERROR:|FATAL:|psql:' <<<"$out" | sed 's/^/    /'
    failed=$((failed + 1))
  else
    echo "$name ... ok ($passed tests)"
  fi
  total=$((total + 1))
done

if [[ $failed -eq 0 ]]; then
  echo "Files=$total, Result: PASS"
else
  echo "Files=$total, Failed=$failed, Result: FAIL"
  exit 1
fi
