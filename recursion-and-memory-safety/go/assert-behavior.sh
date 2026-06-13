#!/bin/sh
# Expected: Go FALLS — `go run .` aborts with the goroutine-stack-cap overflow.
# Go does no TCO; its goroutine stack grows on demand but hits a ~1 GB cap, and
# at depth 5_000_000 it blows past that cap on both arm64 (macOS) and x86_64
# (the Linux CI runner). Asserts the stack-overflow signature, not the crash
# site. See the header in main.go.
set -eu
cd "$(dirname "$0")"

out=$(mktemp); err=$(mktemp)
trap 'rm -f "$out" "$err"' EXIT

status=0
go run . >"$out" 2>"$err" || status=$?

fail() {
  echo "FAIL: $1"
  echo "exit code: $status"
  echo "--- stdout (first 60 lines) ---"; sed 60q "$out"
  echo "--- stderr (first 60 lines) ---"; sed 60q "$err"
  exit 1
}

[ "$status" -ne 0 ] || fail "Go survived — depth is not past the goroutine-stack cap yet; raise it"
grep -qF -- 'goroutine stack exceeds' "$err" \
  || fail "expected the goroutine-stack-cap overflow in stderr"
if grep -qF -- '5000000' "$out"; then
  fail "stdout unexpectedly contains the result 5000000 (Go survived)"
fi
echo "OK: runtime failure (exit $status) — goroutine stack exceeds the ~1 GB cap (no TCO)"
