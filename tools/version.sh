#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# The app's version (https://docs.btlabs.uk/developers/releases/). pubspec.yaml's `version:` is the one source of truth:
# calendar versioning YY.MM.patch (a test build adds -rcN), and a build number derived from it,
#   YY*1000000 + MM*10000 + patch*100 + rebuild   (26.10.0 -> 26100000, 26.10.1 -> 26100100),
# which is Android's versionCode. Windows gets YY.MM.patch.0, Linux and iOS YY.MM.patch.
#
# Usage: tools/version.sh set <YY.MM.patch[-rcN]> [rebuild]   write pubspec.yaml and app_version.dart
#        tools/version.sh core          write coreVersion from LEPIC's Cargo.toml at tools/lepic.rev
#        tools/version.sh check         every place agrees with pubspec.yaml; non-zero on drift
#        tools/version.sh show          the numbers per platform
#        tools/version.sh name|code     pubspec.yaml's version / build number
# Only the release lead runs `set`, when the owner cuts a release; ordinary changes never do.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pubspec="$root/app/pubspec.yaml"
dart_file="$root/app/lib/src/app_version.dart"
lepic_repo="${LEPIC_REPO:-$HOME/lepic}"   # read only; a missing checkout falls back to app/third_party/lepic

die() { echo "version.sh: $*" >&2; exit 1; }

# The derived build number of version $1 with rebuild $2 (default 0); fails on a version
# that is not YY.MM.patch[-rcN] or a rebuild over 99.
derive() {
  local v="$1" rebuild="${2:-0}"
  [[ "$v" =~ ^([0-9]{2})\.([0-9]{1,2})\.([0-9]{1,2})(-rc[1-9][0-9]*)?$ ]] \
    || die "$v is not YY.MM.patch or YY.MM.patch-rcN"
  local yy=$((10#${BASH_REMATCH[1]})) mm=$((10#${BASH_REMATCH[2]})) patch=$((10#${BASH_REMATCH[3]}))
  [[ "${BASH_REMATCH[2]}" == "$mm" && "${BASH_REMATCH[3]}" == "$patch" ]] || die "$v: no leading zeros"
  (( mm >= 1 && mm <= 12 )) || die "$v: month $mm is not 1 to 12"
  [[ "$rebuild" =~ ^[0-9]{1,2}$ ]] || die "rebuild $rebuild is not 0 to 99"
  echo $((yy * 1000000 + mm * 10000 + patch * 100 + 10#$rebuild))
}

pub_line() { sed -n 's/^version: *\(.*\)$/\1/p' "$pubspec"; }
pub_name() { local l; l="$(pub_line)"; echo "${l%%+*}"; }
pub_code() { local l; l="$(pub_line)"; [[ "$l" == *+* ]] || die "pubspec.yaml version $l has no +build"; echo "${l#*+}"; }
numbers() { local n="${1%%-*}"; echo "$n"; }

dart_const() { sed -n "s/^const String $1 = '\([^']*\)';$/\1/p" "$dart_file"; }

# LEPIC's workspace version at the pin, or nothing when no checkout has the pinned commit.
lepic_version() {
  local rev toml=""
  rev="$(tr -d '[:space:]' <"$root/tools/lepic.rev")"
  toml="$(git -C "$lepic_repo" show "$rev:Cargo.toml" 2>/dev/null)" \
    || toml="$(git -C "$root/app/third_party/lepic" show "$rev:Cargo.toml" 2>/dev/null)" || return 0
  awk '/^\[/{s=($0=="[workspace.package]")} s && /^version *=/{gsub(/[" ]/,"",$0); sub(/^version=/,"",$0); print; exit}' <<<"$toml"
}

cmd="${1:-}"
case "$cmd" in
  set)
    [[ $# -ge 2 && $# -le 3 ]] || die "usage: tools/version.sh set <YY.MM.patch[-rcN]> [rebuild]"
    code="$(derive "$2" "${3:-0}")"
    sed -i "s/^version: .*$/version: $2+$code/" "$pubspec"
    sed -i "s/^const String appVersion = '[^']*';$/const String appVersion = '$2';/" "$dart_file"
    echo "pubspec.yaml version: $2+$code"
    "$0" check
    ;;
  core)
    v="$(lepic_version)"
    [[ -n "$v" ]] || die "no LEPIC checkout has the pinned commit ($lepic_repo, app/third_party/lepic)"
    sed -i "s/^const String coreVersion = '[^']*';$/const String coreVersion = '$v';/" "$dart_file"
    echo "coreVersion: $v"
    ;;
  name) pub_name ;;
  code) pub_code ;;
  show)
    name="$(pub_name)" code="$(pub_code)"
    echo "app        $name  (core $(dart_const coreVersion))"
    echo "android    versionName $name, versionCode $code (every ABI)"
    echo "windows    file and installer version $(numbers "$name").0, product $name"
    echo "linux      bt-wallet-$name-linux-x86_64.AppImage (bt-wallet-$name-notor-linux-x86_64.AppImage)"
    echo "ios        CFBundleShortVersionString $(numbers "$name")"
    ;;
  check)
    fail=0
    ok() { echo "  ok   $1"; }
    bad() { echo "  FAIL $1"; fail=1; }
    name="$(pub_name)" code="$(pub_code)"
    [[ "$code" =~ ^[0-9]+$ ]] || die "pubspec.yaml build number $code is not a number"
    want="$(derive "$name" "$((code % 100))")"
    [[ "$code" == "$want" ]] && ok "pubspec.yaml $name+$code" \
      || bad "pubspec.yaml build number $code; $name derives $want (rebuild $((code % 100)))"
    v="$(dart_const appVersion)"
    [[ "$v" == "$name" ]] && ok "app_version.dart appVersion $v" || bad "app_version.dart appVersion is '$v', pubspec says $name"
    core="$(dart_const coreVersion)" lepic="$(lepic_version)"
    if [[ -z "$lepic" ]]; then
      echo "  skip coreVersion $core: no LEPIC checkout has the pinned commit"
    elif [[ "$core" == "$lepic" ]]; then ok "app_version.dart coreVersion $core (LEPIC at the pin)"
    else bad "app_version.dart coreVersion is $core, LEPIC at the pin is $lepic (tools/version.sh core)"; fi
    grep -q "^const String deskAppVersion = appVersion;$" "$root/app/lib/src/desktop/data/desk_update.dart" \
      && ok "desk_update.dart deskAppVersion = appVersion" || bad "desk_update.dart deskAppVersion is not appVersion"
    grep -q '^force-version-code-ignoring-abi=true$' "$root/app/android/gradle.properties" \
      && ok "android: versionCode without the ABI offset" || bad "android/gradle.properties lost force-version-code-ignoring-abi=true"
    grep -q '"FLUTTER_VERSION_BUILD=0"' "$root/app/windows/runner/CMakeLists.txt" \
      && ok "windows runner: file version $(numbers "$name").0" || bad "windows/runner/CMakeLists.txt passes the build number to VERSIONINFO"
    iss="$root/app/windows/installer/epic_wallet.iss"
    if grep -q '#define AppVersion "' "$iss"; then bad "epic_wallet.iss defines its own AppVersion"
    elif ! grep -q '^VersionInfoVersion={#FileVersion}' "$iss"; then bad "epic_wallet.iss has no VersionInfoVersion={#FileVersion}"
    elif ! grep -q '^AppId={{8810835E-6EE5-4989-AE20-C0D60E23800E}' "$iss"; then bad "epic_wallet.iss AppId changed"
    else ok "installer: AppVersion from the build, VersionInfoVersion, AppId unchanged"; fi
    for f in app/tool/build_android_release.sh app/tool/release_android.sh app/tool/build_windows_release.ps1 \
      scripts/linux/in-container.sh; do
      if grep -qE '^\s*\$?version\s*=\s*["'"'"']?[0-9]+\.[0-9]+' "$root/$f"; then bad "$f types a version"
      else ok "$f reads the version"; fi
    done
    [[ $fail == 0 ]] || { echo "version drift: see https://docs.btlabs.uk/developers/releases/" >&2; exit 1; }
    echo "version $name+$code agrees everywhere"
    ;;
  *) sed -n '7,12p' "${BASH_SOURCE[0]}" >&2; exit 64 ;;
esac
