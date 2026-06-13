# stack-safe-recursion — Roc

```sh
roc main.roc -- 5000000 1
```

Recorded with Roc nightly 2026-06-12 (`release-fast-f964cdab`). Roc has no stable release yet — nightlies are its only channel — so CI tracks the latest one from [roc-lang/nightlies](https://github.com/roc-lang/nightlies/releases). The program compiles, then dies at runtime — already on plain tail recursion, because the interpreter does no TCO; see the header comment in [main.roc](main.roc).
