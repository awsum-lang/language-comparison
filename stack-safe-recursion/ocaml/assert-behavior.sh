#!/bin/sh
# Expected: crashes at 40_000_000 with `Fatal error: exception Stack_overflow`.
# OCaml 5's growable stack carries the non-tail `mirror` far past the fixed-stack
# languages (it clears 5_000_000), but the stack is bounded, not infinite: deep
# enough, `mirror` exhausts it and raises Stack_overflow. So OCaml is not
# stack-safe — its ceiling is just higher, and platform-dependent (this macOS
# box aborts earlier than the Linux CI runner, which clears 35M), so the depth
# is set past the higher one. Asserts the overflow signature and the absent
# result, not the site. See the header in main.ml.
set -eu
cd "$(dirname "$0")"

ocamlopt main.ml -o main >/dev/null

out=$(mktemp); err=$(mktemp)
trap 'rm -f "$out" "$err"' EXIT

status=0
./main 40000000 1 >"$out" 2>"$err" || status=$?

fail() {
  echo "FAIL: $1"
  echo "exit code: $status"
  echo "--- stdout (first 60 lines) ---"; sed 60q "$out"
  echo "--- stderr (first 60 lines) ---"; sed 60q "$err"
  exit 1
}

[ "$status" -ne 0 ] || fail "OCaml survived 40_000_000 — growable-stack ceiling is higher here; raise the depth"
grep -qF -- 'Stack_overflow' "$err" \
  || fail "expected the OCaml Stack_overflow message in stderr"
if grep -qF -- '40000000' "$out"; then
  fail "stdout unexpectedly contains the result 40000000 (OCaml survived)"
fi
echo "OK: runtime failure (exit $status) — Fatal error: exception Stack_overflow (growable stack is bounded, not infinite)"
