#!/bin/sh
# Expected: crashes at runtime — Roslyn emits no tail. prefix and the default
# tiered JIT's tier-0 frames own the first descent, so even BuildLeft's plain
# tail recursion exhausts the stack; .NET prints "Stack overflow." and aborts
# before any output.
set -eu
cd "$(dirname "$0")"

out=$(mktemp); err=$(mktemp)
trap 'rm -f "$out" "$err"' EXIT

status=0
dotnet run -c Release >"$out" 2>"$err" || status=$?

fail() {
  echo "FAIL: $1"
  echo "exit code: $status"
  echo "--- stdout (first 60 lines) ---"; sed 60q "$out"
  echo "--- stderr (first 60 lines) ---"; sed 60q "$err"
  exit 1
}

[ "$status" -ne 0 ] || fail "expected non-zero exit, got 0"
grep -qF -- 'Stack overflow.' "$err" \
  || fail "expected the CLR stack-overflow message in stderr"
grep -qF -- 'at Demo.BuildLeft' "$err" \
  || fail "expected the overflow to happen already inside BuildLeft"
if grep -qF -- '500000' "$out"; then
  fail "stdout unexpectedly contains the result 500000"
fi
echo "OK: runtime failure (exit $status) — Stack overflow. process abort, already in BuildLeft"
