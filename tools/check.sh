#!/usr/bin/env bash
# Repository gate: a branch passes it before review, and main passes it after every merge.
# Usage: tools/check.sh   (from anywhere inside a checkout or worktree)
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
. "$(cd "$(dirname "$0")" && pwd)/env.sh"

step() { printf '\n== %s\n' "$1"; }

step "version (https://docs.btlabs.uk/developers/releases/)"
"$root/tools/version.sh" check

step "LEPIC at the pin (tools/lepic.rev)"
"$root/tools/lepic.sh" build linux

step "wallet core under plain Dart (no Flutter on its path)"
(cd "$root/app" && dart run bin/core_check.dart)

step "flutter analyze"
(cd "$root/app" && flutter pub get >/dev/null && flutter analyze --no-pub)

step "flutter test"
(cd "$root/app" && flutter test --no-pub)

step "integration tests on LEPIC (Linux, offline)"
# One run per file: a second app start in one `flutter test` run fails on Linux now and then.
for t in simple_test history_test; do
  (cd "$root/app" && xvfb-run -a flutter test --no-pub -d linux "integration_test/$t.dart")
done

step "web build (the demo's flags, tool/build_web.sh)"
(cd "$root/app" && tool/build_web.sh >/dev/null)

printf '\ncheck passed\n'
