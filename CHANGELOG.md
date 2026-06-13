# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

`language-comparison` is tagged in lockstep with the `awsum` compiler — the tag `vA.B.C` bookmarks the commit at which the Awsum entry in this repo was verified to run cleanly under `awsum A.B.C`. The compiler version this repo targets lives in [`AWSUM_VERSION`](.github/workflows/ci.yml). Only the latest tag is supported.

Until `awsum 1.0.0`, the project does not follow SemVer — every release increments only the patch (`0.0.1 → 0.0.2 …`), and any release may break.

## [Unreleased]

### Added

- CI plus standard repository scaffolding (`CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `LICENSE`, `NOTICE`, `.gitignore`, and a `justfile` with `setup-dev` / `format` / `test` / `fix` / `release`, backed by the DCO `prepare-commit-msg` hook).
- Each language directory in `stack-safe-recursion/` carries an `assert-behavior.sh` asserting its recorded outcome — Awsum and Haskell print `5000000`, the other thirteen crash (OCaml only once pushed past its growable-stack ceiling — see below). Each crash assertion checks the language's stack-overflow signature and the absent result, not the function it dies in — that site can shift with toolchain, platform, or JIT timing (as C#'s does), while the overflow-and-no-output outcome is invariant. `just test` runs them all, `just test <language>` runs one.
- CI runs one job per language against its latest stable release (Roc: latest nightly; Awsum: the lockstep-tagged release); an outcome-changing release turns the job red until the entry is re-recorded.
- New Java, C#, Go, Zig, and OCaml entries; Roc re-recorded against nightly 2026-06-12 — now compiles and dies at runtime instead (no TCO in the interpreter). Zig has no TCO guarantee for ordinary recursion and segfaults in buildLeft like Rust. Go and OCaml share the growable-stack character — no TCO for the non-tail `mirror`, but a runtime stack that grows on demand rather than a fixed thread stack — and differ only in ceiling: Go's goroutine stack gives out by 5_000_000 (`goroutine stack exceeds 1000000000-byte limit`), while OCaml 5's higher-ceilinged managed stack clears that but raises `Fatal error: exception Stack_overflow` by 35_000_000. Both are bounded — postponed, not stack-safe. Mechanics in the source headers.
- Each program reads `treeDepth` and `mirrorCount` from argv instead of hard-coding them; every `assert-behavior.sh` passes `5000000 1`. The values are decoupled from the source, so the same program re-runs at any depth without an edit — each language reads argv its own way (`os.Args`, `Sys.argv`, `IO.Args.getArgs` across all five Awsum targets, Elm flags via the Node runner, a `process.argv` FFI for PureScript).
- The scenario runs at tree depth 5_000_000, mirrored once (one pass through the non-tail `mirror` is all the stack-safety probe needs) — the depth is set so the deepest survivor among the crashers still crashes. Go's growable goroutine stack postpones its overflow far past the fixed-stack languages (which die in the tens-to-hundreds of thousands), so the depth is driven up to where Go's ~1 GB cap is exceeded on both macOS and the Linux CI runner; every crashing language then aborts on both platforms (Rust on Linux too, C# with `Stack overflow.` regardless of the tiered-JIT race over which function dies). Awsum and Haskell still print `5000000` — genuinely stack-safe (Awsum by compiler, Haskell by GHC TCO + laziness), bounded only by memory. OCaml's growable stack clears 5_000_000 too, so its entry is pushed to 35_000_000 — past that higher ceiling, where it also raises `Stack_overflow`: postponed, not removed, not stack-safe. The Haskell entry drops its perf figures — performance is not the topic, safety is.
