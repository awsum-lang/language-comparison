#!/bin/sh
# Expected: runtime StackOverflowError inside mirror's non-tail recursion.
# sbt runs main on a background thread and still reports [success] / exit 0
# after the thread dies, so the exit code is meaningless here — the assertion
# reads the JVM's stack trace on stderr and the absence of a result instead.
set -eu
cd "$(dirname "$0")"

out=$(mktemp); err=$(mktemp)
trap 'rm -f "$out" "$err"' EXIT

status=0
sbt run >"$out" 2>"$err" || status=$?

fail() {
  echo "FAIL: $1"
  echo "exit code: $status"
  echo "--- stdout (first 60 lines) ---"; sed 60q "$out"
  echo "--- stderr (first 60 lines) ---"; sed 60q "$err"
  exit 1
}

grep -qF -- 'java.lang.StackOverflowError' "$err" \
  || fail "expected java.lang.StackOverflowError in stderr"
grep -qF -- '.mirror(Main.scala' "$err" \
  || fail "expected the overflow to happen inside mirror"
if grep -qF -- '200000' "$out"; then
  fail "stdout unexpectedly contains the result 200000"
fi
echo "OK: runtime failure (exit $status) — java.lang.StackOverflowError in mirror (sbt still reports success)"
