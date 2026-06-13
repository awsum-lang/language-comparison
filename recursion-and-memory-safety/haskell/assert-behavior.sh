#!/bin/sh
# Expected: every recursion shape in the demo is stack-safe under GHC;
# the program prints exactly "300000".
set -eu
cd "$(dirname "$0")"

actual=$(stack run)
if [ "$actual" != "300000" ]; then
  printf 'FAIL:\nexpected: 300000\nactual:   %s\n' "$actual"
  exit 1
fi
echo "OK: prints 300000"
