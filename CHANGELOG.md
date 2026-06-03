# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

`language-comparison` is tagged in lockstep with the `awsum` compiler — the tag `vA.B.C` bookmarks the commit at which the Awsum entry in this repo was verified to run cleanly under `awsum A.B.C`. The compiler version this repo targets lives in [`AWSUM_VERSION`](.github/workflows/ci.yml). Only the latest tag is supported.

Until `awsum 1.0.0`, the project does not follow SemVer — every release increments only the patch (`0.0.1 → 0.0.2 …`), and any release may break.

## [Unreleased]

### Added

- CI plus standard repository scaffolding (`CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `LICENSE`, `NOTICE`, `.gitignore`, and a `justfile` with `setup-dev` / `format` / `test` / `fix` / `release`, backed by the DCO `prepare-commit-msg` hook). CI runs the Awsum entry of `recursion-and-memory-safety/` through every backend (`llvm`, `jvm`, `clr`, `wasm`, `js`) and asserts identical stdout. Only the Awsum entry is wired into CI / `just` so far; the other languages are added the same way over time.
