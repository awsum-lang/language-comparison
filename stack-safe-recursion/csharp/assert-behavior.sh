#!/bin/sh
# Expected: crashes at runtime — Roslyn emits no tail. prefix, so .NET prints
# "Stack overflow." and aborts before any output. The function it dies in
# (BuildLeft's tail recursion or Mirror's non-tail) is a tiered-JIT race that
# shifts with platform/depth/run, so only the abort is asserted, not the site.
# See the header in Program.cs.
set -eu
cd "$(dirname "$0")"

out=$(mktemp); err=$(mktemp)
trap 'rm -f "$out" "$err"' EXIT

status=0
dotnet run -c Release -- 5000000 1 >"$out" 2>"$err" || status=$?

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
# Crash site (Demo.BuildLeft or Demo.Mirror) is a tiered-JIT race — not asserted.
if grep -qF -- '5000000' "$out"; then
  fail "stdout unexpectedly contains the result 5000000"
fi
echo "OK: runtime failure (exit $status) — Stack overflow. process abort"
