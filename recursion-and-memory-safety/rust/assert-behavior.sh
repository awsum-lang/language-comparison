#!/bin/sh
# Expected: crashes at runtime — Rust has no guaranteed TCO (Drop keeps frames
# alive even for tail calls), so the depth-100_000 build overflows the thread
# stack and the runtime aborts. The abort message names no function, so only
# the message itself is asserted.
set -eu
cd "$(dirname "$0")"

out=$(mktemp); err=$(mktemp)
trap 'rm -f "$out" "$err"' EXIT

# The subshell (held open by the trailing exit, or the shell would exec cargo
# into it) keeps the shell's own "Abort trap" job notice — cargo re-raises the
# program's SIGABRT — out of the suite output; cargo's stderr still lands in $err.
status=0
(cargo run --release >"$out" 2>"$err"; exit $?) 2>/dev/null || status=$?

fail() {
  echo "FAIL: $1"
  echo "exit code: $status"
  echo "--- stdout (first 60 lines) ---"; sed 60q "$out"
  echo "--- stderr (first 60 lines) ---"; sed 60q "$err"
  exit 1
}

[ "$status" -ne 0 ] || fail "expected non-zero exit, got 0"
grep -qF -- 'fatal runtime error: stack overflow' "$err" \
  || fail "expected the stack-overflow abort message in stderr"
if grep -qF -- '100000' "$out"; then
  fail "stdout unexpectedly contains the result 100000"
fi
echo "OK: runtime failure (exit $status) — fatal runtime error: stack overflow"
