#!/usr/bin/env bash
# Checks a built APK or App Bundle against what its distribution must and must not contain
# (https://docs.btlabs.uk/developers/build/variants/). app/tool/build_android_release.sh runs it on every build; it also runs
# by hand on any APK or AAB, for example one F-Droid built.
#
# Usage: tools/dist-check.sh <web|play|fdroid> <file.apk|file.aab>
#
#   every   no Firebase (removed in 26.10.20): not in the manifest, the dex strings or the
#           resources; no notification permission.
#   web     the in-app updater's install permission is there.
#   play    no install permissions, no installer code, no update feed (Google Play updates the app).
#   fdroid  as play, and nothing of Google Play services, ML Kit, Google's data transport or Play
#           Core: not in the manifest, the dex strings or META-INF, and no ML Kit library. With
#           FDROID=<path to fdroid> (from fdroidserver) it also runs `fdroid scanner` on an APK,
#           the check F-Droid itself runs. (web and play keep the ML Kit scanner, which brings
#           Play services' base library with it.)
#
# Dex code may be renamed by R8, so the class checks read what renaming keeps: the manifest's
# component names, the strings in the dex files (class names in reflection, keep rules and log
# tags, library version names) and the resources.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=tools/env.sh
. "$root/tools/env.sh"
usage="usage: $0 <web|play|fdroid> <file.apk|file.aab>"
dist="${1:-}" file="${2:-}"
case "$dist" in web|play|fdroid) ;; *) echo "$usage" >&2; exit 2 ;; esac
[[ -f "$file" ]] || { echo "$usage" >&2; exit 2; }

bt="$(find "$ANDROID_HOME/build-tools" -maxdepth 1 -mindepth 1 -type d | sort -V | tail -1)"
aapt2="$bt/aapt2"

fail=0
check() { # description, condition result (0 = ok)
  if [[ "$2" == 0 ]]; then echo "  ok   $1"; else echo "  FAIL $1"; fail=1; fi
}
has() { grep -qiE "$1" <<<"$2"; } # pattern, text
# The distinct matches of $1 in the dex files, on one line.
dex_hits() { find "$work/x" -name '*.dex' -exec env LC_ALL=C grep -aohiE "$1" {} + | sort -u | tr '\n' ' ' || true; }

work="$(mktemp -d)"
trap 'rm -r -- "$work"' EXIT
unzip -q "$file" -d "$work/x"

# The manifest as text: aapt2 for an APK; an App Bundle keeps it as protobuf, whose names and
# values are plain strings.
case "$file" in
  *.apk) manifest="$("$aapt2" dump xmltree --file AndroidManifest.xml "$file")"
         resources="$("$aapt2" dump resources "$file" 2>/dev/null || true)" ;;
  *.aab) manifest="$(LC_ALL=C strings -n 6 "$work/x/base/manifest/AndroidManifest.xml")"
         resources="$(LC_ALL=C strings -n 6 "$work/x/base/resources.pb" 2>/dev/null || true)" ;;
  *) echo "$usage" >&2; exit 2 ;;
esac

install_perm='android\.permission\.(REQUEST_INSTALL_PACKAGES|UPDATE_PACKAGES_WITHOUT_USER_ACTION)'
firebase='com[./]google[./]firebase|firebase-(messaging|common|installations|iid)|com\.google\.android\.c2dm'
firebase_config='google_app_id|gcm_defaultSenderId|google_api_key'
proprietary='com[./]google[./](android[./]gms|mlkit|android[./]datatransport|android[./]play[./]core)|play-services-|barhopper|libmlkit'

echo "$(basename "$file") as WFE_DIST=$dist"
# Every build: no Firebase, no notifications.
hits="$(grep -oiE "$firebase" <<<"$manifest" | sort -u | tr '\n' ' ' || true)"
[[ -z "$hits" ]] && r=0 || r=1; check "manifest names no Firebase ${hits:+($hits)}" "$r"
hits="$(dex_hits "$firebase")"
[[ -z "$hits" ]] && r=0 || r=1; check "dex strings name no Firebase ${hits:+($hits)}" "$r"
has "$firebase_config" "$resources" && r=1 || r=0; check "no Firebase config in the resources" "$r"
has 'android\.permission\.POST_NOTIFICATIONS' "$manifest" && r=1 || r=0; check "no notification permission" "$r"

case "$dist" in
  web)
    has "$install_perm" "$manifest" && r=0 || r=1; check "install permission (in-app updater)" "$r"
    ;;
  play|fdroid)
    has "$install_perm" "$manifest" && r=1 || r=0; check "no install permission" "$r"
    has 'InstallResultReceiver' "$manifest" && r=1 || r=0; check "no install result receiver" "$r"
    # The updater is in the web build only: neither its Kotlin side (the install result
    # receiver, the "install unknown apps" settings screen) nor its Dart side (the update feed's
    # address in libapp.so, which the compiler leaves out with the updater).
    hits="$(dex_hits 'InstallResultReceiver|MANAGE_UNKNOWN_APP_SOURCES')"
    [[ -z "$hits" ]] && r=0 || r=1; check "no installer code in the dex ${hits:+($hits)}" "$r"
    hits="$(find "$work/x" -name libapp.so -exec env LC_ALL=C grep -aolF 'btlabs-epic.github.io/update.json' {} + | sed "s|$work/x/||" | tr '\n' ' ' || true)"
    [[ -z "$hits" ]] && r=0 || r=1; check "no update feed in the Dart code ${hits:+($hits)}" "$r"
    ;;
esac

if [[ "$dist" == fdroid ]]; then
  hits="$(grep -oiE "$proprietary" <<<"$manifest" | sort -u | tr '\n' ' ' || true)"
  [[ -z "$hits" ]] && r=0 || r=1; check "manifest names nothing proprietary ${hits:+($hits)}" "$r"
  hits="$(dex_hits "$proprietary")"
  [[ -z "$hits" ]] && r=0 || r=1; check "dex strings name nothing proprietary ${hits:+($hits)}" "$r"
  hits="$(find "$work/x" -path '*/lib/*' -name '*.so' | grep -iE 'barhopper|mlkit|firebase|gms' | sed "s|$work/x/||" | tr '\n' ' ' || true)"
  [[ -z "$hits" ]] && r=0 || r=1; check "no proprietary native library ${hits:+($hits)}" "$r"
  hits="$(find "$work/x" -name '*.properties' -path '*META-INF*' | grep -iE 'firebase|play-services|mlkit|datatransport' | sed "s|$work/x/||" | tr '\n' ' ' || true)"
  [[ -z "$hits" ]] && r=0 || r=1; check "no Google library version files in META-INF ${hits:+($hits)}" "$r"
  if [[ -n "${FDROID:-}" && "$file" == *.apk ]]; then
    "$FDROID" scanner --exit-code "$file" && r=0 || r=1; check "fdroid scanner $(basename "$file")" "$r"
  fi
fi
[[ $fail == 0 ]] || { echo "dist check FAILED" >&2; exit 1; }
echo "dist check passed"
