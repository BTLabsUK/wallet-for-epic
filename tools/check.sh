#!/usr/bin/env bash
# Repository gate: a branch passes it before review, and main passes it after every merge.
# Usage: tools/check.sh   (from anywhere inside a checkout or worktree)
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
. "$(git rev-parse --show-toplevel)/tools/env.sh"

step() { printf '\n== %s\n' "$1"; }

if [ ! -d "$root/playground/src/epic-wallet" ]; then
  echo "playground/src is missing: run ./pg sync in the main checkout (worktrees link to it)" >&2
  exit 1
fi

step "flutter analyze"
(cd "$root/app" && flutter pub get >/dev/null && flutter analyze --no-pub)

step "flutter test"
(cd "$root/app" && flutter test --no-pub)

step "cargo test (app/rust, offline)"
(cd "$root/app/rust" && cargo test --locked -q)

printf '\ncheck passed\n'
