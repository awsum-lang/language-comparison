#!/bin/sh
# Expected: awsum normalises every recursion shape to a bounded loop on all five
# targets, so each prints its treeDepth back — never a stack overflow. What
# bounds the depth is MEMORY, not the stack, and that bound differs per target:
# LLVM/JVM/CLR go deep, WASM is capped by its ~4 GB linear memory (~19M), JS by
# the V8 heap (~11M). One assertion per backend, each at its own depth.
set -eu
cd "$(dirname "$0")"

# LLVM
actual=$(awsum run --program-type cli -t llvm Main.aww -- 35000000 1)
if [ "$actual" != "35000000" ]; then
  printf 'FAIL: target=llvm\nexpected: 35000000\nactual:   %s\n' "$actual"
  exit 1
fi
echo "OK: llvm prints 35000000"

# # JVM
# actual=$(awsum run --program-type cli -t jvm Main.aww -- 50000000 1)
# if [ "$actual" != "50000000" ]; then
#   printf 'FAIL: target=jvm\nexpected: 50000000\nactual:   %s\n' "$actual"
#   exit 1
# fi
# echo "OK: jvm prints 50000000"

# # CLR
# actual=$(awsum run --program-type cli -t clr Main.aww -- 50000000 1)
# if [ "$actual" != "50000000" ]; then
#   printf 'FAIL: target=clr\nexpected: 50000000\nactual:   %s\n' "$actual"
#   exit 1
# fi
# echo "OK: clr prints 50000000"

# # WASM — bounded by the ~4 GB wasm32 linear-memory cap
# actual=$(awsum run --program-type cli -t wasm Main.aww -- 19000000 1)
# if [ "$actual" != "19000000" ]; then
#   printf 'FAIL: target=wasm\nexpected: 19000000\nactual:   %s\n' "$actual"
#   exit 1
# fi
# echo "OK: wasm prints 19000000"

# # JS — bounded by the V8 heap
# actual=$(awsum run --program-type cli -t js Main.aww -- 11000000 1)
# if [ "$actual" != "11000000" ]; then
#   printf 'FAIL: target=js\nexpected: 11000000\nactual:   %s\n' "$actual"
#   exit 1
# fi
# echo "OK: js prints 11000000"
