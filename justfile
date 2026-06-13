_default:
  @ just --list --unsorted

# One-time post-clone setup: installs the prepare-commit-msg hook from
# scripts/git-hooks/ so every commit in this clone auto-adds the DCO
# Signed-off-by trailer. See CONTRIBUTING.md ("Developer Certificate of Origin").
setup-dev:
  #!/bin/sh
  set -eu
  git config core.hooksPath scripts/git-hooks
  chmod +x scripts/git-hooks/prepare-commit-msg
  echo "✅ DCO prepare-commit-msg hook installed for this clone"

# Format every .aww in this repo via `awsum format -i`
format:
  #!/bin/sh
  set -eu
  find . -name '*.aww' -not -path './.git/*' -print0 | xargs -0 -n1 awsum format -i
  echo "\n\n✅ Formatting completed!\n\n"

# Assert recorded behavior via each language's assert-behavior.sh — every language by default, one with e.g. `just test scala` (Awsum succeeds on every backend, Roc fails to compile, the rest crash at runtime)
test lang='*':
  #!/bin/sh
  set -eu
  matched=0
  failed=""
  for dir in stack-safe-recursion/{{ lang }}/; do
    [ -d "$dir" ] || continue
    matched=1
    name=$(basename "$dir")
    echo "=== stack-safe-recursion / $name ==="
    if [ ! -x "${dir}assert-behavior.sh" ]; then
      echo "FAIL: ${dir}assert-behavior.sh is missing or not executable"
      failed="$failed $name"
      continue
    fi
    if ! "${dir}assert-behavior.sh"; then
      failed="$failed $name"
    fi
  done
  if [ "$matched" -eq 0 ]; then
    echo "❌ No language directory matches stack-safe-recursion/{{ lang }}/"
    exit 1
  fi
  if [ -n "$failed" ]; then
    echo "\n\n❌ Recorded behavior not reproduced by:$failed\n\n"
    exit 1
  fi
  echo "\n\n✅ Recorded behavior reproduced.\n\n"

# Full precommit: format → test
fix: format test

# Confirm potentially dangerous actions with a specific confirmation input (e.g. version, environment name)
[private]
manual-confirmation-input message required_confirmation:
  #!/bin/sh
  set -eu

  message="{{ message }}"
  required_confirmation="{{ required_confirmation }}"

  echo "$message"
  echo "Type '$required_confirmation' to confirm:"
  read response

  if [ "$response" != "$required_confirmation" ]; then
    echo "Confirmation failed. Exiting..."
    exit 1
  fi

# Tag and push the version currently in .github/workflows/ci.yml (AWSUM_VERSION).
# Run after the prep PR is merged into main.
release:
  #!/bin/sh
  set -eu
  git checkout main
  git pull
  version=$(awk '/^[[:space:]]*AWSUM_VERSION:/ {print $2; exit}' .github/workflows/ci.yml)
  just manual-confirmation-input "About to tag and push v$version" "$version"
  git tag -a "v$version" -m "Release $version"
  git push origin "v$version"
