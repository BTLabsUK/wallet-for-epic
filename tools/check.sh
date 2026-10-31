#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Repository gate. Two modes:
#   tools/check.sh           fast, the default (a branch before review, main after a merge):
#                            version, install contract, LEPIC at the pin, no hosts, the plain-Dart
#                            core, flutter analyze, and only the Flutter tests the change touches
#                            (rule below); the bot's tests only when bot/ changed; the release
#                            tools' own tests (tools/rel, the nightly, sbom, test order, the
#                            incremental publisher, the screens feedback service) only when
#                            tools/ changed.
#   tools/check.sh --full    everything: the whole flutter test suite, the integration tests and
#                            the web build too. Once per release candidate: tools/rel's source
#                            gate runs it. Between releases nobody runs --full.
#   tools/check.sh --list    print the mode, the rule and the tests the fast mode would run; run
#                            nothing.
# Which tests the fast mode runs: the change is every file that differs from the merge base with
# main (committed, staged, unstaged and untracked). Test files in it under app/test/ run, and for
# each changed app/lib/.../<name>.dart every app/test/**/<name>_test.dart. Nothing else: a change
# with no matching test runs analyze only. CHECK_BASE=<ref> compares with another ref.
# Usage: tools/check.sh [--full | --list]   (from anywhere inside the main checkout or a worktree)
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
. "$(cd "$(dirname "$0")" && pwd)/env.sh"

mode=fast
case "${1:-}" in
  "") ;;
  --full) mode=full ;;
  --list) mode=list ;;
  *) echo "usage: tools/check.sh [--full | --list]" >&2; exit 64 ;;
esac

step() { printf '\n== %s\n' "$1"; }

# The change: files that differ from the merge base with main, untracked ones included.
base_ref="${CHECK_BASE:-main}"
base="$(git -C "$root" merge-base HEAD "$base_ref" 2>/dev/null || git -C "$root" rev-parse HEAD)"
changed="$( (git -C "$root" diff --name-only "$base"; git -C "$root" ls-files --others --exclude-standard) | sort -u)"
tests=()
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  case "$f" in
    app/test/*_test.dart) [[ -f "$root/$f" ]] && tests+=("${f#app/}") ;;
    app/lib/*.dart)
      name="$(basename "$f" .dart)"
      while IFS= read -r t; do tests+=("${t#"$root"/app/}"); done \
        < <(find "$root/app/test" -name "${name}_test.dart" -type f 2>/dev/null)
      ;;
  esac
done <<<"$changed"
if [[ ${#tests[@]} -gt 0 ]]; then
  mapfile -t tests < <(printf '%s\n' "${tests[@]}" | sort -u)
fi
bot_changed=0
grep -q '^bot/' <<<"$changed" && bot_changed=1
tools_changed=0
grep -q '^tools/' <<<"$changed" && tools_changed=1

rule="affected tests = changed app/test/**/*_test.dart + app/test/**/<name>_test.dart for each changed app/lib/**/<name>.dart (vs merge base with $base_ref, ${base:0:10})"
if [[ $mode == full ]]; then
  echo "check mode: FULL (whole flutter test suite, integration tests, bot, release tools, web build)"
else
  echo "check mode: fast (--full runs everything: once per release candidate, by tools/rel)"
  echo "rule: $rule"
  echo "affected tests: ${#tests[@]}$([[ $bot_changed == 1 ]] && echo '; bot/ changed: bot tests run')$([[ $tools_changed == 1 ]] && echo '; tools/ changed: release tool tests run')"
  for t in "${tests[@]}"; do echo "  $t"; done
fi
[[ $mode == list ]] && exit 0

step "version (https://docs.btlabs.uk/developers/releases/)"
"$root/tools/version.sh" check

step "install contract (docs/install-contract.md)"
"$root/tools/check-install-contract.sh"

step "LEPIC at the pin (tools/lepic.rev)"
# From the shared clone of the pin (tools/lepic.sh, docs/TESTING.md); LEPIC_SHARED=0 builds in
# app/third_party/lepic instead.
LEPIC_SHARED="${LEPIC_SHARED:-1}" "$root/tools/lepic.sh" build linux

step "no hosts in code (docs/settings-file.md)"
"$root/tools/check-no-hosts.sh"

step "wallet core under plain Dart (no Flutter on its path)"
(cd "$root/app" && dart run bin/core_check.dart)

step "flutter analyze"
(cd "$root/app" && flutter pub get >/dev/null && flutter analyze --no-pub)

if [[ $mode == full ]]; then
  step "flutter test (all)"
  # Slowest files first (tools/flutter-test-all.sh): the same files, a shorter run.
  (cd "$root/app" && "$root/tools/flutter-test-all.sh")

  step "integration tests on LEPIC (Linux, offline)"
  # One run per file: a second app start in one `flutter test` run fails on Linux now and then.
  for t in simple_test history_test; do
    (cd "$root/app" && xvfb-run -a flutter test --no-pub -d linux "integration_test/$t.dart")
  done
else
  step "flutter test (affected: ${#tests[@]})"
  if [[ ${#tests[@]} -gt 0 ]]; then
    (cd "$root/app" && flutter test --no-pub "${tests[@]}")
  else
    echo "no affected tests"
  fi
fi

if [[ $mode == full || $bot_changed == 1 ]]; then
  step "bot"
  (cd "$root/bot" && uv run pytest -q && uvx ruff check .)
fi

if [[ $mode == full || $tools_changed == 1 ]]; then
  step "release tools (tools/)"
  # tools/rel's own tests (docs/RELEASING.md), then the single-file ones, each as its file says.
  (cd "$root" && python3 -m unittest discover -s tools/rellib/tests)
  (cd "$root" && python3 -m unittest tools/nightly/test_nightly.py tools/test_sbom.py tools/test_flutter_test_order.py)
  # Says "skip:" and passes without git-filter-repo, gitleaks or trufflehog.
  "$root/tools/publish/test-incremental.sh"
  if command -v node >/dev/null; then
    (cd "$root" && node --test tools/screens-feedback/feedback.test.mjs)
  else
    echo "skip: node is not installed (tools/screens-feedback/feedback.test.mjs)"
  fi
fi

if [[ $mode == full ]]; then
  step "web build (the demo's flags, tool/build_web.sh)"
  (cd "$root/app" && tool/build_web.sh >/dev/null)
fi

printf '\ncheck passed (%s)\n' "$mode"
