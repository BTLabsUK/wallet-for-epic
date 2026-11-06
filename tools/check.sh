#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Repository gate. Two modes:
#   tools/check.sh           fast, the default (a branch before review, main after a merge):
#                            version, install contract, LEPIC at the pin, no hosts, workflows,
#                            the plain-Dart core, flutter analyze, and only the Flutter tests the
#                            change reaches (tools/t affected); the bot's tests only when bot/
#                            changed; the smaller release-tool tests (the nightly, sbom, test order,
#                            check-workflow, tools/t, the incremental publisher, the screens
#                            feedback service) only when tools/ changed; tools/rel's own suite
#                            (tools/rellib/tests, 743 tests) only when a file it runs or reads
#                            changed: tools/rel, tools/env.sh, tools/rellib/, tools/signer/,
#                            tools/releases/, tools/release-files.py, tools/publish-update-json.sh,
#                            tools/push-github.sh, release/, app/assets/config/app-config.toml.
#   tools/check.sh --full    everything: the whole flutter test suite, the integration tests and
#                            the web build and LEPIC's golden-vector replay too. Once per release candidate: tools/rel's source
#                            gate runs it, or the nightly, or the release lead on the candidate.
#                            Green on a clean tree, it records /tmp/epic-build/green/<sha>.json
#                            (tools/rellib/green.py; tools/t full ran both passes, with and
#                            without Tor), which G2 reuses for that content; without one G2 runs
#                            first in the release run.
#                            Between releases nobody else runs --full.
#   tools/check.sh --list    print the mode, the rule and the tests the fast mode would run; run
#                            nothing.
# Which Flutter tests the fast mode runs is tools/t's selection (tools/tlib/select.py,
# docs/TESTING.md): the change is every file that differs from the merge base with main
# (committed, staged, unstaged and untracked); the tests whose import closure holds a changed file
# run, plus a fixed set of sentinels. CHECK_BASE=<ref> compares with another ref.
# Usage: tools/check.sh [--full | --list]   (from anywhere inside the main checkout or a worktree)
set -euo pipefail
started_epoch="$(date +%s)"
root="$(git rev-parse --show-toplevel)"
. "$(cd "$(dirname "$0")" && pwd)/env.sh"

mode=fast
case "${1:-}" in
  "") ;;
  --full) mode=full ;;
  --list) mode=list ;;
  *) echo "usage: tools/check.sh [--full | --list]" >&2; exit 64 ;;
esac

# Each step prints its time when it ends, one line (`== bot: ok 4s`; the name is the title up to
# " ("), so the nightly's log and the audit have per-step times.
# No failure stops the run (keep-going): a failed command marks its step failed, the step's other
# commands and the later steps still run, the step ends with `== <name>: FAILED (exit N) after Ns`
# and the check fails at the end naming every failed step. One run then shows every failure, to be
# fixed in one pass. A step cut short by the shell itself prints its FAILED line from the exit trap.
step_name="" step_t0=0 step_rc=0
failed=()
step_label() { local n="${step_name%% (*}"; printf '%s' "$n"; }
step_done() {
  [[ -n $step_name ]] || return 0
  if (( step_rc )); then
    printf '== %s: FAILED (exit %s) after %ss\n' "$(step_label)" "$step_rc" $((SECONDS - step_t0))
    failed+=("$(step_label)")
  else
    printf '== %s: ok %ss\n' "$(step_label)" $((SECONDS - step_t0))
  fi
  step_name="" step_rc=0
}
step() { step_done; printf '\n== %s\n' "$1"; step_name="$1"; step_t0=$SECONDS; }
# `<command> || step_failed $?`: the step's first failing exit code is the one it reports.
step_failed() { (( step_rc )) || step_rc="$1"; }
check_end() {
  step_done
  (( ${#failed[@]} )) || return 0
  printf '\ncheck FAILED (%s): %s\n' "$mode" "$(printf '%s; ' "${failed[@]}" | sed 's/; $//')"
  exit 1
}
on_exit() {
  local rc=$?
  [[ $rc != 0 && -n $step_name ]] && printf '== %s: FAILED (exit %s) after %ss\n' "$(step_label)" "$rc" $((SECONDS - step_t0))
  return 0
}
trap on_exit EXIT

# The change: files that differ from the merge base with main, untracked ones included.
base_ref="${CHECK_BASE:-main}"
base="$(git -C "$root" merge-base HEAD "$base_ref" 2>/dev/null || git -C "$root" rev-parse HEAD)"
changed="$( (git -C "$root" diff --name-only "$base"; git -C "$root" ls-files --others --exclude-standard) | sort -u)"
bot_changed=0
grep -q '^bot/' <<<"$changed" && bot_changed=1
tools_changed=0
grep -q '^tools/' <<<"$changed" && tools_changed=1
# What tools/rellib/tests runs or reads (checked against the tests): not lepic.rev, the vector
# scripts or the other tools.
rel_changed=0
grep -qE '^(tools/(rel|env\.sh|release-files\.py|publish-update-json\.sh|push-github\.sh)$|tools/(rellib|signer|releases)/|release/|app/assets/config/app-config\.toml$)' <<<"$changed" && rel_changed=1

if [[ $mode == full ]]; then
  echo "check mode: FULL (whole flutter test suite, integration tests, bot, release tools, web build)"
else
  echo "check mode: fast (--full runs everything: once per release candidate, by tools/rel)"
  echo "rule: tools/t affected (the tests whose imports reach the change, plus the sentinels)$([[ $bot_changed == 1 ]] && echo '; bot/ changed: bot tests run')$([[ $tools_changed == 1 ]] && echo '; tools/ changed: small tool tests run (nightly, sbom, tlib ...)')$([[ $rel_changed == 1 ]] && echo '; tools/rel inputs changed: tools/rellib/tests run (rule: tools/rel, env.sh, rellib/, signer/, releases/, release-files.py, publish-update-json.sh, push-github.sh, release/, app-config.toml)')"
  "$root/tools/t" affected --list --base "$base_ref"
fi
[[ $mode == list ]] && exit 0

step "version (https://docs.btlabs.uk/developers/releases/)"
"$root/tools/version.sh" check || step_failed $?

step "install contract (docs/install-contract.md)"
"$root/tools/check-install-contract.sh" || step_failed $?

step "no hosts in code (docs/settings-file.md)"
"$root/tools/check-no-hosts.sh" || step_failed $?

step "doc names (tools/doc-names.allow)"
names_rc=0
python3 "$root/tools/check-doc-names.py" || names_rc=$?
# The docs site (btlabs-docs) keeps its own allow file; checked when its checkout is here.
docs_site="${BTLABS_DOCS:-$HOME/btlabs-docs}"
if [[ -f "$docs_site/tools/check-doc-names.py" ]]; then
  python3 "$docs_site/tools/check-doc-names.py" || names_rc=$?
else
  echo "docs site: no checkout at $docs_site (BTLABS_DOCS), skipped"
fi
[[ $names_rc == 0 ]] || step_failed "$names_rc"

step "workflows (.github/workflows, tools/check-workflow.py)"
python3 "$root/tools/check-workflow.py" || step_failed $?

# Everything that takes seconds runs before the minutes: a release run once failed on a lint
# after the full Flutter suite had passed (docs/TESTING.md, "Order of the steps").
if [[ $mode == full || $bot_changed == 1 ]]; then
  step "bot"
  (cd "$root/bot" || exit; uvx ruff check .; r=$?; uv run pytest -q || r=$?; exit $r) || step_failed $?
fi

if [[ $mode == full || $tools_changed == 1 ]]; then
  step "release tools (tools/)"
  # tools/rel's own tests (docs/RELEASING.md), then the single-file ones, each as its file says.
  if [[ $mode == full || $rel_changed == 1 ]]; then
    (cd "$root" && python3 -m unittest discover -s tools/rellib/tests) || step_failed $?
  fi
  (cd "$root" && python3 -m unittest discover -s tools/tlib/tests) || step_failed $?
  (cd "$root" && python3 -m unittest tools/nightly/test_nightly.py tools/test_sbom.py tools/test_flutter_test_order.py \
    tools/test_check_workflow.py tools/publish/test_buildcheck.py) || step_failed $?
  # Says "skip:" and passes without git-filter-repo, gitleaks or trufflehog.
  "$root/tools/publish/test-incremental.sh" || step_failed $?
  if command -v node >/dev/null; then
    (cd "$root" && node --test tools/screens-feedback/feedback.test.mjs) || step_failed $?
  else
    echo "skip: node is not installed (tools/screens-feedback/feedback.test.mjs)"
  fi
fi

step "LEPIC at the pin (tools/lepic.rev)"
# From the shared clone of the pin (tools/lepic.sh, docs/TESTING.md); LEPIC_SHARED=0 builds in
# app/third_party/lepic instead.
LEPIC_SHARED="${LEPIC_SHARED:-1}" "$root/tools/lepic.sh" build linux || step_failed $?

if [[ $mode == full ]]; then
  step "LEPIC golden vectors (cargo xtask vectors verify)"
  # LEPIC's own replay of its golden vectors, at the pin, in the shared clone (tools/lepic.sh xtask).
  # tools/rel's source gate and the nightly both run this through --full.
  "$root/tools/lepic.sh" xtask vectors verify || step_failed $?
fi

step "wallet core under plain Dart (no Flutter on its path)"
(cd "$root/app" && dart run bin/core_check.dart) || step_failed $?

step "flutter analyze"
(cd "$root/app" && flutter pub get >/dev/null && flutter analyze --no-pub) || step_failed $?

if [[ $mode == full ]]; then
  step "flutter test (all)"
  # Every test file, slowest first, never from the result cache (green files still fill it).
  "$root/tools/t" full --no-cache || step_failed $?

  step "integration tests on LEPIC (Linux, offline)"
  # One run per file: a second app start in one `flutter test` run fails on Linux now and then.
  # The app keeps its PIN vault in the platform keyring. Run by hand (ssh, an agent's shell) there
  # is no unlocked one and the test waits on it forever, so each file gets its own session bus
  # and an unlocked throwaway keyring, as the nightly does, and a hard time limit.
  # A file whose failure is the machine's (docs/TESTING.md, "Infrastructure failures are retried
  # once": a timeout before the app started, xvfb, dbus or the keyring not starting) runs once more;
  # a file with a failing test never does.
  run_integration() {
    local t="$1" kr log rc=0
    kr="$(mktemp -d)"; log="$(mktemp)"
    (cd "$root/app" && timeout --kill-after=30 "${WFE_INTEGRATION_TIMEOUT:-600}" \
      dbus-run-session -- bash -c 'export XDG_DATA_HOME="$1"
        printf "throwaway\n" | gnome-keyring-daemon --unlock --components=secrets >/dev/null
        exec xvfb-run -a flutter test --no-pub -d linux "integration_test/$2.dart"' _ "$kr" "$t") 2>&1 \
      | tee "$log" || rc=${PIPESTATUS[0]}
    INTEGRATION_RESULT="$(python3 "$root/tools/tlib/infra.py" classify "$rc" "$log")"
    rm -rf "$kr" "$log"
    return "$rc"
  }
  for t in simple_test history_test; do
    rc=0
    run_integration "$t" || rc=$?
    if [[ $rc != 0 && $INTEGRATION_RESULT == infra* ]]; then
      echo "retried after an infrastructure failure: integration_test/$t.dart (${INTEGRATION_RESULT#infra: })"
      rc=0
      run_integration "$t" || rc=$?
    fi
    [[ $rc == 0 ]] || { [[ $rc == 124 ]] && echo "integration_test/$t.dart: timed out" >&2; step_failed "$rc"; }
  done
else
  step "flutter test (affected vs $base_ref)"
  "$root/tools/t" affected --base "$base_ref" || step_failed $?
fi

if [[ $mode == full ]]; then
  step "web build (the preview, tool/build_web.sh)"
  (cd "$root/app" && tool/build_web.sh >/dev/null) || step_failed $?
fi

check_end
printf '\ncheck passed (%s)\n' "$mode"
if [[ $mode == full ]]; then
  # For tools/rel's G2 (docs/RELEASING.md, "Reused results"); never fails the check.
  python3 "$root/tools/rellib/green.py" record --root "$root" --started "$started_epoch" || true
fi
