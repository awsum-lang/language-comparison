#!/bin/sh
# Expected: compiles fine, then crashes at runtime — purs emits a loop only for
# self-recursive tail calls, so mirror's multi-child non-tail recursion
# overflows the JS engine's call stack before any output.
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
grep -qF -- 'at mirror (' "$err" \
  || fail "expected the overflow to happen inside mirror"
if grep -qF -- '100000' "$out"; then
  fail "stdout unexpectedly contains the result 100000"
fi
echo "OK: runtime failure (exit $status) — RangeError: Maximum call stack size exceeded, in mirror"
