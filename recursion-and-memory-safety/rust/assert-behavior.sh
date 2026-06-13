#!/bin/sh
# Expected: crashes at runtime — Rust does no TCO (Drop keeps even tail-call
# frames alive), and at depth 300_000 the recursion's stack peak (~24-29 MB)
# is more than three times any default 8 MB thread stack; the runtime aborts
# inside build_left. See the header in src/main.rs.
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
if grep -qF -- '300000' "$out"; then
  fail "stdout unexpectedly contains the result 300000"
fi
echo "OK: runtime failure (exit $status) — fatal runtime error: stack overflow"
