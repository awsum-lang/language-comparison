# Language Comparison

Reproducible demonstrations of how different programming languages handle specific scenarios. Each scenario is one concrete situation; each language shows what it actually does in that situation.

The comparison runs against the **latest stable release** of each language (for Roc, which has no stable release yet, the latest nightly): CI installs each language's current toolchain and re-asserts every recorded outcome. When a new release changes an outcome, the assertion goes red and the entry gets re-recorded — the comparison shows what languages do today, not what some legacy version once did.

## Structure

```
<topic>/
└── <language>/
    ├── README.md           # exact toolchain version + one-line run
    ├── assert-behavior.sh  # runs that command and asserts the recorded outcome
    └── <code>              # minimal standalone program
```

Topic names describe the **scenario**, not the behavior. Different languages do different things in the same scenario — silent wrap, panic, typed error, correct result — and recording them side by side is the point. Each outcome is executable, not just prose: `assert-behavior.sh` re-runs the program and asserts what was recorded — the success output, the compile-time failure, or a substring of the exact runtime error. `just test` runs every assertion in the repo.
