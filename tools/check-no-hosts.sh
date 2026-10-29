#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Fails when a host name, a URL with a literal host, an IP address or an onion address appears
# in the wallet's code: app/lib and app/bin here, LEPIC's crates/*/src and bindings,
# lepic-flutter's lib. Every address lives in a settings file (docs/settings-file.md).
#
# Usage: tools/check-no-hosts.sh [--lepic <LEPIC checkout>] [--lepic-flutter <checkout>]
#   Without a flag, LEPIC is app/third_party/lepic and lepic-flutter is the path pubspec.yaml
#   names, when they exist. A tree that is missing is skipped with a note.
#
# Allowed: loopback and every-interface (127.x, localhost, ::1, 0.0.0.0), the Android
# emulator's host 10.0.2.2, RFC 2606 names (example.com/.org/.net, *.example, *.invalid,
# *.test, *.localhost) and RFC 5737 documentation ranges. Other exceptions: tools/no-hosts.allow.
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
lepic=""
lepic_flutter=""
while [ $# -gt 0 ]; do
  case "$1" in
    --lepic) lepic="$2"; shift 2 ;;
    --lepic-flutter) lepic_flutter="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
if [ -z "$lepic" ] && [ -d "$root/app/third_party/lepic/crates" ]; then lepic="$root/app/third_party/lepic"; fi
if [ -z "$lepic_flutter" ]; then
  p="$(sed -n '/^  lepic:/,/^  [a-z_]*:/{s/^ *path: *//p}' "$root/app/pubspec.yaml" | head -n1)"
  if [ -n "$p" ] && [ -d "$root/app/$p/lib" ]; then lepic_flutter="$(cd "$root/app/$p" && pwd)"; fi
fi

fail=0
scan() { # <label> <dir> <pathspec...>
  local label="$1" dir="$2"; shift 2
  if [ ! -d "$dir" ]; then echo "skip $label: $dir not found"; return; fi
  if (cd "$dir" && git ls-files -z -- "$@") | python3 -I "$root/tools/no_hosts.py" "$label" "$dir" "$root/tools/no-hosts.allow"; then
    echo "ok   $label"
  else
    fail=1
  fi
}

scan app "$root/app" 'lib/**' 'bin/**'
if [ -n "$lepic" ]; then scan lepic "$lepic" 'crates/*/src/**' 'bindings/**'; else echo "skip lepic: no checkout (--lepic)"; fi
if [ -n "$lepic_flutter" ]; then scan lepic-flutter "$lepic_flutter" 'lib/**'; else echo "skip lepic-flutter: no checkout (--lepic-flutter)"; fi

if [ "$fail" -ne 0 ]; then
  echo "Addresses belong in the settings file (docs/settings-file.md), not in code." >&2
  exit 1
fi
echo "no hosts in code"
