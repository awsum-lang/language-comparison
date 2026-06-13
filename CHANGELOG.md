# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

`language-comparison` is tagged in lockstep with the `awsum` compiler — the tag `vA.B.C` bookmarks the commit at which the Awsum entry in this repo was verified to run cleanly under `awsum A.B.C`. The compiler version this repo targets lives in [`AWSUM_VERSION`](.github/workflows/ci.yml). Only the latest tag is supported.

Until `awsum 1.0.0`, the project does not follow SemVer — every release increments only the patch (`0.0.1 → 0.0.2 …`), and any release may break.

## [Unreleased]

### Added

- CI plus standard repository scaffolding (`CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `LICENSE`, `NOTICE`, `.gitignore`, and a `justfile` with `setup-dev` / `format` / `test` / `fix` / `release`, backed by the DCO `prepare-commit-msg` hook).
- Each language directory in `recursion-and-memory-safety/` carries an `assert-behavior.sh` asserting its recorded outcome — Awsum and Haskell print `300000`, the other ten crash. Each crash assertion checks the language's stack-overflow signature and the absent result, not the function it dies in — that site can shift with toolchain, platform, or JIT timing (as C#'s does), while the overflow-and-no-output outcome is invariant. `just test` runs them all, `just test <language>` runs one.
- CI runs one job per language against its latest stable release (Roc: latest nightly; Awsum: the lockstep-tagged release); an outcome-changing release turns the job red until the entry is re-recorded.
- New Java and C# entries; Roc re-recorded against nightly 2026-06-12 — now compiles and dies at runtime instead (no TCO in the interpreter). Mechanics in the source headers.
- The scenario runs at tree depth 300_000 — above the floor where every crashing language still crashes (Rust, the deepest survivor, completes at depth 100_000 on the Linux runner's stack budget; 300_000 clears that comfortably). Deep enough that the *outcome* never flips: Rust aborts on Linux runners too, and C# always hits `Stack overflow.` even though the function it dies in (BuildLeft's tail recursion or Mirror's non-tail) stays a tiered-JIT race. The Haskell entry drops its perf figures — performance is not the topic, safety is.
