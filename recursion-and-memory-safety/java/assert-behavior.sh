#!/bin/sh
# Expected: crashes at runtime — javac/HotSpot do no tail-call elimination at
# all, so even buildLeft's plain tail recursion overflows the default thread
# stack; mirror and the rest never run.
set -eu
cd "$(dirname "$0")"

out=$(mktemp); err=$(mktemp)
trap 'rm -f "$out" "$err"' EXIT

status=0
java Main.java >"$out" 2>"$err" || status=$?

fail() {
  echo "FAIL: $1"
  echo "exit code: $status"
  echo "--- stdout (first 60 lines) ---"; sed 60q "$out"
  echo "--- stderr (first 60 lines) ---"; sed 60q "$err"
  exit 1
}

[ "$status" -ne 0 ] || fail "expected non-zero exit, got 0"
grep -qF -- 'java.lang.StackOverflowError' "$err" \
  || fail "expected java.lang.StackOverflowError in stderr"
grep -qF -- 'at Main.buildLeft(Main.java' "$err" \
  || fail "expected the overflow to happen already inside buildLeft"
if grep -qF -- '100000' "$out"; then
  fail "stdout unexpectedly contains the result 100000"
fi
echo "OK: runtime failure (exit $status) — java.lang.StackOverflowError, already in buildLeft"
