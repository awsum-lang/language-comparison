#!/bin/sh
# Expected: prints exactly "50000000". Every recursion shape is stack-safe under
# GHC (TCO + laziness), bounded by memory, not stack — so it clears 50_000_000,
# past where OCaml's growable stack gives out (~45M).
set -eu
cd "$(dirname "$0")"

actual=$(stack run -- 50000000 1)
if [ "$actual" != "50000000" ]; then
  printf 'FAIL:\nexpected: 50000000\nactual:   %s\n' "$actual"
  exit 1
fi
echo "OK: prints 50000000 (stack-safe past OCaml's ceiling)"
