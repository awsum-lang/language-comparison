#!/bin/sh
# Expected: every recursion shape in the demo is stack-safe under GHC;
# the program prints exactly "5000000".
set -eu
cd "$(dirname "$0")"

actual=$(stack run)
if [ "$actual" != "5000000" ]; then
  printf 'FAIL:\nexpected: 5000000\nactual:   %s\n' "$actual"
  exit 1
fi
echo "OK: prints 5000000"
