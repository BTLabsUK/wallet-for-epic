#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Runs a release hand-off step on the Apple builder over ssh, by itself (tools/rellib/engine.py
# exec_handoff, when [host.apple] ssh is set and the step is in auto). What a person does by hand
# (tools/apple-release.md): the job goes to <workdir>/<run>/<step>/job on the Mac, the LEPIC pins
# of the commit go into the Mac's bare repos, the step's command runs there in that folder (build
# keychain unlocked, under the Mac build lock), and the expected results come back into results/
# with their SHA256SUMS. The Mac is never given a secret: the keychain it unlocks has no password.
#
# Usage: apple-remote.sh <ssh alias> <workdir> <run id> <step id> <job dir> <results dir>
#                        <commit> <repo with the commit> <timeout minutes> <result name>...
# Env: APPLE_REMOTE_CMD    the step's command (run in the folder that holds job/)
#      APPLE_REMOTE_ENV    NAME=VALUE lines for the command (a value may use $HOME)
set -euo pipefail
host="${1:?ssh alias}" workdir="${2:?workdir on the Mac}" run_id="${3:?run id}" step_id="${4:?step id}"
job="${5:?job dir}" results="${6:?results dir}" commit="${7:?commit}" src="${8:?repo with the commit}"
tmo="${9:?timeout minutes}"
shift 9
(( $# > 0 )) || { echo "apple-remote: no result names given" >&2; exit 64; }
cmd="${APPLE_REMOTE_CMD:?APPLE_REMOTE_CMD}"
fail() { echo "apple-remote: $*" >&2; exit 1; }
say() { echo "apple-remote: $*"; }

SSH=(ssh -o BatchMode=yes -o ControlPath=none -o ServerAliveInterval=30 -o ServerAliveCountMax=6)
export GIT_SSH_COMMAND="${SSH[*]}"
rdir="$workdir/$run_id/$step_id"

# 1. The Mac's folder for this step: fresh job/, nothing kept from an earlier attempt, and no
#    reuse of another commit's folder.
say "$host:$rdir ($(date -u +%H:%M:%SZ))"
"${SSH[@]}" "$host" bash -s -- "$rdir" "$commit" <<'EOF' || fail "cannot prepare the folder on $host"
set -e
d="$1"; commit="$2"
case "$d" in "~/"*) d="$HOME/${d#"~/"}" ;; esac
if [ -f "$d/COMMIT" ] && [ "$(cat "$d/COMMIT")" != "$commit" ]; then
  echo "$d holds an earlier attempt of commit $(cat "$d/COMMIT"), not $commit: remove it on the Mac first" >&2
  exit 3
fi
rm -rf "$d/job" "$d/results" "$d/src" "$d/out"
mkdir -p "$d/job"
printf %s "$commit" > "$d/COMMIT"
EOF

# 2. The script the Mac runs (kept in job/ as the record of what ran), the job, the LEPIC pins.
{
  echo "# What apple-remote.sh ran on the Mac for this step; not secret."
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    name="${line%%=*}" val="${line#*=}"
    [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "bad env name in APPLE_REMOTE_ENV: $name"
    val="${val//\\/\\\\}"; val="${val//\"/\\\"}"; val="${val//\`/\\\`}"
    printf 'export %s="%s"\n' "$name" "$val"
  done <<< "${APPLE_REMOTE_ENV:-}"
} > "$job/remote-env.sh"
cat > "$job/remote-run.sh" <<EOF
#!/bin/bash
# apple-remote.sh runs this on the Mac, in the folder that holds job/, under the Mac build lock.
set -eo pipefail
cd "\$(dirname "\$0")/.."
security unlock-keychain -p "" "\$HOME/Library/Keychains/build.keychain-db"
. job/remote-env.sh
if [ -n "\${NOTARY_KEYCHAIN:-}" ]; then security unlock-keychain -p "" "\$NOTARY_KEYCHAIN"; fi
echo "on \$(hostname), \$(date -u +%H:%M:%SZ): $step_id"
$cmd
EOF
rsync -a --delete -e "${SSH[*]}" "$job/" "$host:$rdir/job/" || fail "copying the job to $host failed"

push_pin() {  # <local repo> <bare repo on the Mac> <rev file>
  local repo="$1" bare="$2" revfile="$3" rev
  rev="$(git -C "$src" show "$commit:$revfile" 2>/dev/null | awk 'NF && $1 !~ /^#/ { print $1; exit }')"
  [[ -n "$rev" ]] || { say "$revfile: no pin at $commit"; return 0; }
  if "${SSH[@]}" "$host" "git --git-dir=\$HOME/src/$bare cat-file -e $rev^{commit}" >/dev/null 2>&1; then
    say "$bare already has ${rev:0:12}"
    return 0
  fi
  git -C "$repo" cat-file -e "$rev^{commit}" 2>/dev/null || fail "$repo has no $rev ($revfile)"
  say "pushing $(basename "$repo") ${rev:0:12} to $host:src/$bare"
  git -C "$repo" push -q "$host:src/$bare" "$rev:refs/heads/pin-${rev:0:12}" || fail "pushing $rev to $host:src/$bare failed"
}
push_pin "${LEPIC_LOCAL:-$HOME/lepic}" lepic.git tools/lepic.rev
push_pin "${LEPIC_FLUTTER_LOCAL:-$HOME/lepic-flutter}" lepic-flutter.git tools/lepic-flutter.rev

# 3. The build, under the Mac build lock (the other Mac lanes use it too), with its own time limit.
say "running on $host under the Mac build lock (limit ${tmo} min)"
rc=0
# The inner zsh expands a leading ~ of the folder; run and step ids hold no odd characters.
timeout --foreground "${tmo}m" "${SSH[@]}" -n "$host" \
  "zsh -l -c '/usr/bin/lockf -k ~/.wfe-mac-build.lock /bin/bash $rdir/job/remote-run.sh'" || rc=$?
if (( rc == 124 )); then fail "the Mac run hit its ${tmo} minute limit"; fi
(( rc == 0 )) || fail "the command failed on $host (exit $rc); see the log above"

# 4. The results come back, with their SHA256SUMS.
mkdir -p "$results"
for name in "$@"; do
  rsync -a -e "${SSH[*]}" "$host:$rdir/results/$name" "$results/" 2>/dev/null \
    || fail "the Mac produced no results/$name"
  [[ -s "$results/$name" ]] || fail "results/$name is empty"
done
(cd "$results" && sha256sum -- "$@" > SHA256SUMS)
say "done: $* ($(date -u +%H:%M:%SZ))"
