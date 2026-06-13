#!/bin/sh
# Expected: crashes at runtime — `roc main.roc` interprets the program, the
# interpreter does no TCO, and build_left's plain tail recursion overflows at
# depth 100_000; the crash message carries no location.
set -eu
cd "$(dirname "$0")"

out=$(mktemp); err=$(mktemp)
trap 'rm -f "$out" "$err"' EXIT

status=0
roc main.roc >"$out" 2>"$err" || status=$?

fail() {
  echo "FAIL: $1"
  echo "exit code: $status"
  echo "--- stdout (first 60 lines) ---"; sed 60q "$out"
  echo "--- stderr (first 60 lines) ---"; sed 60q "$err"
  exit 1
}

[ "$status" -ne 0 ] || fail "expected non-zero exit, got 0"
grep -qF -- 'Roc crashed: This Roc program overflowed its stack memory' "$err" \
  || fail "expected the runtime stack-overflow message in stderr"
if grep -qF -- '5000000' "$out"; then
  fail "stdout unexpectedly contains the result 5000000"
fi
echo "OK: runtime failure (exit $status) — Roc crashed: This Roc program overflowed its stack memory (no TCO in the interpreter)"
