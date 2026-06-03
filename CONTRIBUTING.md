# Contributing to `language-comparison`

Thanks for your interest in contributing.

## Development setup

Each language in a comparison is built and run with its own toolchain — see the `README.md` in each subdirectory (for example, [recursion-and-memory-safety/awsum/README.md](recursion-and-memory-safety/awsum/README.md)).

The Awsum entry is additionally wired into `just` and CI. Install the [Awsum compiler](https://github.com/awsum-lang/awsum) plus the target runtimes, then from a checkout:

```bash
just format    # awsum format -i over every .aww file
just test      # run the Awsum entry through llvm / jvm / clr / wasm / js, assert identical stdout
just fix       # format + test
```

`just test` requires the same five backend runtimes that the Awsum compiler's CI uses — LLVM 15 (`clang`), JDK 11, .NET 9, `wasmtime`, Node 22. See [.github/workflows/ci.yml](.github/workflows/ci.yml) for the matching install scripts. Only the Awsum entry is wired into `just` / CI so far; the other languages are added the same way over time.

## Developer Certificate of Origin

By contributing to `language-comparison` you certify the [Developer Certificate of Origin](https://developercertificate.org/) (DCO) for your contribution — a short statement that you wrote the patch yourself, or otherwise have the right to submit it under the project's [Apache-2.0 license](LICENSE). The full text is at the link above.

After cloning, run once:

```bash
just setup-dev
```

This installs the `prepare-commit-msg` hook from [scripts/git-hooks/](scripts/git-hooks/) (via per-clone `core.hooksPath`), which adds a `Signed-off-by` trailer to every commit you make in this clone:

```
Signed-off-by: Your Name <you@example.com>
```

The trailer uses the name and email from your `[user]` section in `~/.gitconfig` (the same one used for signed commits below). No manual flags, no global gitconfig changes. The setup is per-clone — repeat in each clone of the repo.

## Signed commits

Separately from the DCO trailer above, the `main` branch requires signed commits — every commit you push to a PR needs a verified signature (GPG or SSH), otherwise the merge button stays grey.

Minimal `~/.gitconfig` for SSH signing:

```ini
[user]
	email = ...
	name = ...
	signingkey = ~/.ssh/id_ed25519.pub
[commit]
	gpgsign = true
[gpg]
	format = ssh
```

For GPG signing instead, set `gpg.format = openpgp` (or omit — that's the default) and point `signingkey` at your GPG key ID. The option name `gpgsign` is git's historical name for "sign this thing" and applies regardless of format.

The same key file must be added to GitHub Settings → SSH and GPG keys as a **Signing Key** (a separate category from Authentication Key, even if you reuse the same file). Verify locally:

```bash
git commit -S -m "test" --allow-empty
git log --show-signature -1
```

If you already made unsigned commits on a feature branch, retroactively sign with:

```bash
git rebase --exec 'git commit --amend --no-edit -S' <range>
```

then force-push your branch.

## Pull requests

- Open against `main`. CI must be green before merge.
- For user-visible changes, add a bullet under `## [Unreleased]` in [CHANGELOG.md](CHANGELOG.md). Infrastructure-only changes (CI, dev tooling) still get an entry so the next release notes are complete.
- Releases of `language-comparison` are tagged whenever the Awsum entry here has been verified against a fresh `awsum` release; the tag matches the compiler's version (`vA.B.C`). [`AWSUM_VERSION`](.github/workflows/ci.yml) is the source of truth — `just release` reads from it.
