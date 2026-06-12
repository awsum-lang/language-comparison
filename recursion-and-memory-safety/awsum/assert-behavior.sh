#!/bin/sh
# Expected: compiles and runs on every backend; each prints exactly "500000"
# (identical stdout across llvm/jvm/clr/wasm/js).
set -eu
cd "$(dirname "$0")"

for target in llvm jvm clr wasm js; do
  actual=$(awsum run --program-type cli -t "$target" Main.aww)
  if [ "$actual" != "500000" ]; then
    printf 'FAIL: target=%s\nexpected: 500000\nactual:   %s\n' "$target" "$actual"
    exit 1
  fi
done
echo "OK: all five targets print 500000"
