# stack-safe-recursion — Roc

```sh
roc main.roc -- 100000 1
```

Roc has no stable release yet — nightlies are its only channel — so CI tracks the latest one from [roc-lang/nightlies](https://github.com/roc-lang/nightlies/releases). Because the nightly is unpinned (and old nightlies are garbage-collected, so pinning would eventually break the download), the assert matches the stable overflow message `This Roc program overflowed its stack memory` rather than its exact wording — newer nightlies reword the wrapper around it. The program compiles, then dies at runtime — `roc main.roc` interprets it, and this deep recursion overflows the interpreter's stack; see the header comment in [main.roc](main.roc).
