#!/usr/bin/env bash
# Backend testleri: her test dosyası kendi geçici SQLite veritabanıyla çalışır.
# Kullanım (server_api/ içinden veya her yerden):  server_api/tests/run_all.sh
set -uo pipefail
cd "$(dirname "$0")/.."
PY=${PYTHON:-.venv/bin/python}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

total_pass=0; total_fail=0
for t in tests/test_*.py; do
  name=$(basename "$t" .py)
  out=$(APP_ENV=development DATABASE_URL="sqlite:///$TMP/$name.db" SECRET_KEY=test-secret \
        JWT_SECRET_KEY=test-jwt FIREBASE_CREDENTIALS_PATH=/nonexistent MAIL_USERNAME= SENTRY_DSN= \
        "$PY" "$t" 2>&1)
  pass=$(grep -c '^PASS' <<<"$out" || true)
  fail=$(grep -cE '^FAIL|Traceback' <<<"$out" || true)
  total_pass=$((total_pass + pass)); total_fail=$((total_fail + fail))
  printf '%-28s %3d geçti  %d hata\n' "$name" "$pass" "$fail"
  if [ "$fail" -gt 0 ]; then grep -E '^FAIL|Traceback|Error' <<<"$out" | sed 's/^/    /'; fi
done
echo "Toplam: $total_pass geçti, $total_fail hata"
[ "$total_fail" -eq 0 ]
