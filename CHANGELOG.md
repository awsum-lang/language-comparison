# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

`language-comparison` is tagged in lockstep with the `awsum` compiler — the tag `vA.B.C` bookmarks the commit at which the Awsum entry in this repo was verified to run cleanly under `awsum A.B.C`. The compiler version this repo targets lives in [`AWSUM_VERSION`](.github/workflows/ci.yml). Only the latest tag is supported.

Until `awsum 1.0.0`, the project does not follow SemVer — every release increments only the patch (`0.0.1 → 0.0.2 …`), and any release may break.

## [Unreleased]

### Added

- CI plus standard repository scaffolding (`CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `LICENSE`, `NOTICE`, `.gitignore`, and a `justfile` with `setup-dev` / `format` / `test` / `fix` / `release`, backed by the DCO `prepare-commit-msg` hook).
- Each language directory in `recursion-and-memory-safety/` carries an `assert-behavior.sh` asserting its recorded outcome — Awsum and Haskell print `5000000`, the other twelve crash. Each crash assertion checks the language's stack-overflow signature and the absent result, not the function it dies in — that site can shift with toolchain, platform, or JIT timing (as C#'s does), while the overflow-and-no-output outcome is invariant. `just test` runs them all, `just test <language>` runs one.
- CI runs one job per language against its latest stable release (Roc: latest nightly; Awsum: the lockstep-tagged release); an outcome-changing release turns the job red until the entry is re-recorded.
- New Java, C#, Go, and Zig entries; Roc re-recorded against nightly 2026-06-12 — now compiles and dies at runtime instead (no TCO in the interpreter). Zig has no TCO guarantee for ordinary recursion and segfaults in buildLeft like Rust. Go is the outlier — no TCO either, but its goroutine stack grows on demand to a ~1 GB cap, so it survives far deeper than the fixed-stack crashers before aborting with `goroutine stack exceeds 1000000000-byte limit`. Mechanics in the source headers.
- The scenario runs at tree depth 5_000_000 — set so the deepest survivor among the crashers still crashes. Go's growable goroutine stack postpones its overflow far past the fixed-stack languages (which die in the tens-to-hundreds of thousands), so the depth is driven up to where Go's ~1 GB cap is exceeded on both macOS and the Linux CI runner; every crashing language then aborts on both platforms (Rust on Linux too, C# with `Stack overflow.` regardless of the tiered-JIT race over which function dies). Awsum and Haskell still print `5000000` — genuinely stack-safe (Awsum by compiler, Haskell by GHC TCO + laziness), handling far deeper. The Haskell entry drops its perf figures — performance is not the topic, safety is.
