# Language Comparison

Reproducible demonstrations of how different programming languages handle specific scenarios. Each scenario is one concrete situation; each language shows what it actually does in that situation, with the exact toolchain version recorded so anyone can replay the result.

## Structure

```
proofs/
└── <topic>/
    ├── README.md           # scenario + observed behavior per language
    └── <language>/
        ├── README.md       # exact toolchain version + one-line run
        └── <code>          # minimal standalone program
```

Topic names describe the **scenario**, not the behavior. Different languages do different things in the same scenario — silent wrap, panic, typed error, correct result — and recording them side by side is the point. The per-topic README tabulates each language's outcome.
