#!/bin/sh
# Expected: crashes at runtime — `roc main.roc` interprets the program, and this
# deep recursion overflows the interpreter's stack.
# Asserts the stable core of the overflow message: nightlies reword everything
# around it ("Roc crashed: This Roc program overflowed…", "Roc application
# crashed with this message: …", "Roc application overflowed…"), so match only
# the invariant `overflowed its stack memory`, not the surrounding text.
set -eu
cd "$(dirname "$0")"

out=$(mktemp); err=$(mktemp)
trap 'rm -f "$out" "$err"' EXIT

status=0
roc main.roc -- 100000 1 >"$out" 2>"$err" || status=$?

fail() {
  echo "FAIL: $1"
  echo "exit code: $status"
  echo "--- stdout (first 60 lines) ---"; sed 60q "$out"
  echo "--- stderr (first 60 lines) ---"; sed 60q "$err"
  exit 1
}

[ "$status" -ne 0 ] || fail "expected non-zero exit, got 0"
grep -qF -- 'overflowed its stack memory' "$err" \
  || fail "expected the runtime stack-overflow message in stderr"
if grep -qF -- '100000' "$out"; then
  fail "stdout unexpectedly contains the result 100000"
fi
echo "OK: runtime failure (exit $status) — overflowed its stack memory"
