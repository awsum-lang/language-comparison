#!/bin/sh
# Expected: crashes at runtime — Roslyn emits no tail. prefix and RyuJIT does
# not loop-rewrite the self-tail calls; BuildLeft's 100k frames happen to fit
# the macOS main stack, Mirror's non-tail descent under the default tiered JIT
# does not, and .NET prints "Stack overflow." and aborts before any output.
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
grep -qF -- 'at Demo.Mirror' "$err" \
  || fail "expected the overflow to happen inside Mirror"
if grep -qF -- '100000' "$out"; then
  fail "stdout unexpectedly contains the result 100000"
fi
echo "OK: runtime failure (exit $status) — Stack overflow. process abort, in Mirror"
