#!/bin/sh
# Expected: every recursion shape in the demo is stack-safe under GHC;
# the program prints exactly "100000".
set -eu
cd "$(dirname "$0")"

actual=$(stack run)
if [ "$actual" != "100000" ]; then
  printf 'FAIL:\nexpected: 100000\nactual:   %s\n' "$actual"
  exit 1
fi
echo "OK: prints 100000"
