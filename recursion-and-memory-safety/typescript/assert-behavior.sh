#!/bin/sh
# Expected: crashes at runtime — V8 does no TCO at all, so even buildLeft's
# plain tail recursion overflows the call stack; mirror and the rest never run.
set -eu
cd "$(dirname "$0")"

npm install --no-audit --no-fund --loglevel=error >/dev/null

out=$(mktemp); err=$(mktemp)
trap 'rm -f "$out" "$err"' EXIT

status=0
npm start >"$out" 2>"$err" || status=$?

fail() {
  echo "FAIL: $1"
  echo "exit code: $status"
  echo "--- stdout (first 60 lines) ---"; sed 60q "$out"
  echo "--- stderr (first 60 lines) ---"; sed 60q "$err"
  exit 1
}

[ "$status" -ne 0 ] || fail "expected non-zero exit, got 0"
grep -qF -- 'RangeError: Maximum call stack size exceeded' "$err" \
  || fail "expected the stack-overflow RangeError in stderr"
grep -qF -- 'at buildLeft (' "$err" \
  || fail "expected the overflow to happen already inside buildLeft"
if grep -qF -- '500000' "$out"; then
  fail "stdout unexpectedly contains the result 500000"
fi
echo "OK: runtime failure (exit $status) — RangeError: Maximum call stack size exceeded, already in buildLeft"
