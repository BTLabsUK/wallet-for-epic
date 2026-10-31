#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Step `key-copies` of tools/rel, after G6 (Q-DEL, docs/RELEASING.md "Signer", "The key copies on
# the build machine"). the owner's yes (2026-10-31): the key files on the build machine go once a release
# signed through the signer is live. When this run signed through the signer (<run>/signer.json)
# and key files named in [host.signer] are still here, it sends the owner one notice asking for his
# yes. It deletes nothing: the lead does, by hand, after that yes. A TEST run asks nothing.
# Usage: key-copies.sh <stage dir>
set -euo pipefail
stage="${1:?usage: $0 <stage dir>}"
if [[ "${REL_TEST:-0}" == 1 ]]; then echo "TEST run: nothing to ask"; exit 0; fi
if [[ ! -f "${REL_RUN:?}/signer.json" ]]; then echo "not signed through the signer: the key copies stay"; exit 0; fi
left=()
for f in "${REL_SIGNER_SIGNING_KEY:-}" "${REL_SIGNER_ANDROID_KEY_PROPERTIES:-}"; do
  [[ -n "$f" ]] || continue
  f="${f/#\~/$HOME}"
  if [[ -e "$f" ]]; then left+=("$f"); fi
done
if [[ ${#left[@]} -eq 0 ]]; then echo "no key copies left on this machine"; exit 0; fi
mkdir -p "$stage"
printf '%s\n' "${left[@]}" > "$stage/left.txt"
python3 - "$stage" "${REL_VERSION:?}" "${left[@]}" <<'PY'
import json, os, sys
stage, version, left = sys.argv[1], sys.argv[2], sys.argv[3:]
with open(os.path.join(stage, "notice.json"), "w", encoding="utf-8") as f:
    json.dump({"title": f"Epic Cash {version} was signed by the signer: delete the key copies on the build machine?",
               "detail": "Still here: " + ", ".join(left) + " (and the keystore file key.properties names). "
                         "The bundle copies and the bundle key stay. docs/RELEASING.md, Signer.",
               "expects": "yes or no to the release lead; nothing is deleted without your yes"}, f)
PY
printf 'asked the owner: %s\n' "${left[*]}"
