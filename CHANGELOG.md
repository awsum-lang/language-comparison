# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

`language-comparison` is tagged in lockstep with the `awsum` compiler — the tag `vA.B.C` bookmarks the commit at which the Awsum entry in this repo was verified to run cleanly under `awsum A.B.C`. The compiler version this repo targets lives in [`AWSUM_VERSION`](.github/workflows/ci.yml). Only the latest tag is supported.

Until `awsum 1.0.0`, the project does not follow SemVer — every release increments only the patch (`0.0.1 → 0.0.2 …`), and any release may break.

## [Unreleased]

### Added

- CI plus standard repository scaffolding (`CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `LICENSE`, `NOTICE`, `.gitignore`, and a `justfile` with `setup-dev` / `format` / `test` / `fix` / `release`, backed by the DCO `prepare-commit-msg` hook).
- Each language directory in `recursion-and-memory-safety/` carries an `assert-behavior.sh` asserting its recorded outcome — Awsum and Haskell print `200000`, the other ten crash. `just test` runs them all, `just test <language>` runs one.
- CI runs one job per language against its latest stable release (Roc: latest nightly; Awsum: the lockstep-tagged release); an outcome-changing release turns the job red until the entry is re-recorded.
- New Java and C# entries; Roc re-recorded against nightly 2026-06-12 — now compiles and dies at runtime instead (no TCO in the interpreter). Mechanics in the source headers.
- The scenario runs at tree depth 200_000 — set just above the floor where every crashing language still crashes (Rust, the deepest survivor, completes at depth 100_000 on the Linux runner's stack budget; 200_000 clears that with ~2× margin). Deep enough that stack-budget and JIT-tier luck stop changing outcomes: Rust aborts on Linux runners too, C# dies already in `BuildLeft`, and F# aborts inside `mirror` in every configuration. The Haskell entry drops its perf figures — performance is not the topic, safety is.
