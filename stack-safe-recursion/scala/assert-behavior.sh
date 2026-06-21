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
sbt "run 5000000 1" >"$out" 2>"$err" || status=$?

fail() {
  echo "FAIL: $1"
  echo "exit code: $status"
  echo "--- stdout (first 60 lines) ---"; sed 60q "$out"
  echo "--- stderr (first 60 lines) ---"; sed 60q "$err"
  exit 1
}

grep -qF -- 'java.lang.StackOverflowError' "$err" \
  || fail "expected java.lang.StackOverflowError in stderr"
# Crash site (mirror) is not asserted — only the StackOverflowError signature.
# Whole-line match (-x): sbt echoes "[info] running main 5000000 1" to stdout,
# so a substring check would false-positive on the arg; the program's result
# would be a bare "5000000" line.
if grep -qxF -- '5000000' "$out"; then
  fail "stdout unexpectedly contains the result 5000000"
fi
echo "OK: runtime failure (exit $status) — java.lang.StackOverflowError (sbt still reports success)"
