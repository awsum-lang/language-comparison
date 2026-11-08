# stack-safe-recursion — Roc

```sh
roc main.roc 5000000 1
```

Roc has no stable release yet — nightlies are its only channel — so CI tracks the latest one from [roc-lang/nightlies](https://github.com/roc-lang/nightlies/releases). Because the nightly is unpinned (and old nightlies are garbage-collected, so pinning would eventually break the download), the assert matches the stable core `overflowed its stack memory` rather than its exact wording — nightlies reword the text around it. The program compiles, then dies at runtime — `roc main.roc` uses the default dev backend, and this deep recursion overflows the stack; see the header comment in [main.roc](main.roc).
