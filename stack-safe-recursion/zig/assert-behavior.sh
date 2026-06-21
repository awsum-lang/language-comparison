#!/bin/sh
# Expected: Segmentation fault — a stack overflow. Zig gives no TCO guarantee
# for ordinary recursion, so buildLeft's 5_000_000-deep tail recursion overflows
# the stack before the first tree is built. Asserts the crash signature and the
# absent result, not the site. See the header in main.zig.
set -eu
cd "$(dirname "$0")"

out=$(mktemp); err=$(mktemp)
trap 'rm -f "$out" "$err"' EXIT

status=0
zig run main.zig -- 5000000 1 >"$out" 2>"$err" || status=$?

fail() {
  echo "FAIL: $1"
  echo "exit code: $status"
  echo "--- stdout (first 60 lines) ---"; sed 60q "$out"
  echo "--- stderr (first 60 lines) ---"; sed 60q "$err"
  exit 1
}

[ "$status" -ne 0 ] || fail "expected non-zero exit, got 0"
grep -qF -- 'Segmentation fault' "$err" \
  || fail "expected the segfault (stack-overflow) message in stderr"
if grep -qF -- '5000000' "$out"; then
  fail "stdout unexpectedly contains the result 5000000"
fi
echo "OK: runtime failure (exit $status) — Segmentation fault (stack overflow, no TCO)"
