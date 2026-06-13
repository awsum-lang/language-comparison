#!/bin/sh
# Expected: compiles fine, then the compiled binary dies of SIGSEGV — Koka's
# TCO covers self and mutual tail calls, but mirror's multi-child non-tail
# recursion grows the C stack until it runs out. The koka driver reports the
# child's signal as "exit code -11" and exits non-zero itself.
set -eu
cd "$(dirname "$0")"

out=$(mktemp); err=$(mktemp)
trap 'rm -f "$out" "$err"' EXIT

status=0
koka -O2 -e main.kk >"$out" 2>"$err" || status=$?

fail() {
  echo "FAIL: $1"
  echo "exit code: $status"
  echo "--- stdout (first 60 lines) ---"; sed 60q "$out"
  echo "--- stderr (first 60 lines) ---"; sed 60q "$err"
  exit 1
}

[ "$status" -ne 0 ] || fail "expected non-zero exit, got 0"
grep -qF -- 'command failed (exit code -11)' "$err" \
  || fail "expected the SIGSEGV report (exit code -11) in stderr"
grep -qF -- 'main__main' "$err" \
  || fail "expected the failing command to be the compiled binary"
if grep -qF -- '5000000' "$out"; then
  fail "stdout unexpectedly contains the result 5000000"
fi
echo "OK: runtime failure (exit $status) — compiled binary segfaulted: command failed (exit code -11)"
