#!/bin/sh
# Expected: crashes at runtime — the CLR honours F#'s tail. prefix, but
# mirror's two recursive calls aren't in tail position; .NET prints
# "Stack overflow." and aborts the process before any output.
# The recorded command is `dotnet run` (Debug), which crashes
# deterministically; in Release the outcome is a JIT tier-up race — see the
# header in Program.fs.
set -eu
cd "$(dirname "$0")"

out=$(mktemp); err=$(mktemp)
trap 'rm -f "$out" "$err"' EXIT

status=0
dotnet run >"$out" 2>"$err" || status=$?

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
grep -qF -- 'at Main.mirror' "$err" \
  || fail "expected the overflow to happen inside mirror"
if grep -qF -- '100000' "$out"; then
  fail "stdout unexpectedly contains the result 100000"
fi
echo "OK: runtime failure (exit $status) — Stack overflow. process abort, in mirror"
