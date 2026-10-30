#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# The whole flutter test suite, slowest files first (tools/check.sh --full).
# `flutter test` runs its files a few at a time (--concurrency, by default half the cores) in the
# order given. A few files take minutes; started last, they ran alone at the end of the run. So
# the files go in slowest first, by their times in earlier runs on this machine
# (tools/flutter_test_order.py, times in WFE_TEST_TIMES, default ~/.cache/wfe-test-times.json),
# files with no time yet first of all. The files are the ones a plain `flutter test` finds (every
# test/**/*_test.dart); only their order changes, each still runs in its own test process, and
# the output is a plain run's. This run's times are kept for the next one, pass or fail.
# FLUTTER_TEST_JOBS=<n> passes --concurrency=<n>; FLUTTER_TEST_JSON=<file> keeps flutter's json
# report of the run there.
# Usage: tools/flutter-test-all.sh   (from app/, after `flutter pub get`)
set -euo pipefail

tools="$(cd "$(dirname "$0")" && pwd)"
times="${WFE_TEST_TIMES:-$HOME/.cache/wfe-test-times.json}"
if [[ -n "${FLUTTER_TEST_JSON:-}" ]]; then
  run_json="$FLUTTER_TEST_JSON"
else
  run_json="$(mktemp)"
  trap 'rm -f "$run_json"' EXIT
fi

mapfile -t found < <(find test -name '*_test.dart' -type f)
mapfile -t files < <(printf '%s\n' "${found[@]}" | python3 -I "$tools/flutter_test_order.py" order "$times") || true
if [[ ${#files[@]} -ne ${#found[@]} ]]; then
  echo "flutter-test-all: could not order the files; they run in the order found" >&2
  files=("${found[@]}")
fi
jobs=()
[[ -n "${FLUTTER_TEST_JOBS:-}" ]] && jobs=(--concurrency="$FLUTTER_TEST_JOBS")

rc=0
flutter test --no-pub "${jobs[@]}" --file-reporter "json:$run_json" "${files[@]}" || rc=$?
python3 -I "$tools/flutter_test_order.py" record "$times" "$run_json" \
  || echo "flutter-test-all: could not keep this run's times (the next run's order is older)" >&2
exit $rc
