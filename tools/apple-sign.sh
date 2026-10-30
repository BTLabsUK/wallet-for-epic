#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Signs, notarises, staples, checks and uploads the Apple builds on the signer's Linux machine,
# so the signing keys and the App Store Connect key never leave it. The release Mac builds
# unsigned (tools/build-apple.sh release) and makes the .dmg of the signed app
# (build-apple.sh dmg-signed); everything that needs a key happens here. Runbook:
# tools/apple-release.md.
#
# Usage: tools/apple-sign.sh <command> [args]
#   doctor                    the tools, the settings file and the key files (no secrets shown)
#   csr <devid|dist>          a new RSA 2048 key (encrypted with a passphrase you type) and its
#                             certificate signing request, for the Developer ID Application (devid)
#                             or Apple Distribution (dist) certificate
#   p12 <devid|dist> <.cer>   Apple's certificate + the key from `csr` -> the .p12 used to sign
#   api-key                   the App Store Connect API key (.p8) -> rcodesign's JSON key file
#   check <handoff dir>       the hand-off from the release Mac: SHA256SUMS, PROVENANCE.txt, and
#                             the files of both apps against the lists in PROVENANCE.txt
#   macos-app <handoff dir>   sign the macOS app (hardened runtime, timestamp), notarise and staple
#                             it; writes EpicCashDesktop-<v>-macos-signed.tar.gz for the Mac
#   macos-dmg <handoff dir> <.dmg>   the .dmg the Mac made: its app must be exactly the signed one;
#                             (<v> in file names is the version with the variant mark of the
#                             build without Tor, e.g. 26.10.24 or 26.10.24-notor)
#                             sign, notarise and staple the .dmg -> the file to publish
#   ios <handoff dir>         sign Runner.app with the App Store profile -> EpicCashMobile-<v>-ios.ipa
#   ios-upload <.ipa>         upload the .ipa to App Store Connect (TestFlight), through the App
#                             Store Connect API (tools/asc_upload.py)
#   verify <.app|.dmg|file>   the signature of everything in it: team, hardened runtime, timestamp
#   test-identity <dir>       self-signed stand-ins for both certificates and a fake profile, with
#                             a settings file for a dry run (APPLE_SIGN_TEST=1): the whole flow
#                             runs, nothing goes to Apple, and the result only proves the tooling
#
# Exit status: 0 done, 1 a check or tool failed, 2 usage, 3 Apple refused it (notarisation or the
# upload), so a runner can tell Apple's answer from a local problem.
#
# Settings: $APPLE_SIGNING_ENV (default ~/.config/epic-apple-signing/signing.env), a shell file of
# variables, mode 600, never in a repository. tools/apple-signing.env.example lists them. Output
# goes to $APPLE_SIGN_OUT (default ./apple-signed), one folder per hand-off.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
settings="${APPLE_SIGNING_ENV:-$HOME/.config/epic-apple-signing/signing.env}"
desktop_name="Epic Cash Desktop"
# The bundle ids are fixed: they must never change after the first signed release
# (tools/apple-release.md, "What freezes").
desktop_id=uk.btlabs.epiccashwallet.macos
phone_id=uk.btlabs.epiccashwallet.ios
rcodesign_min=0.29.0

die() { echo "apple-sign.sh: $*" >&2; exit 1; }
say() { printf '\n== %s\n' "$*"; }
sha256() { sha256sum "$1" | cut -d' ' -f1; }

load_settings() {
  if [ -f "$settings" ]; then
    # shellcheck source=/dev/null
    . "$settings"
  fi
  APPLE_KEYS_DIR="${APPLE_KEYS_DIR:-$(dirname "$settings")/keys}"
  RCODESIGN="${RCODESIGN:-rcodesign}"
  SEVENZIP="${SEVENZIP:-7zz}"
  out_root="${APPLE_SIGN_OUT:-$PWD/apple-signed}"
  test_mode="${APPLE_SIGN_TEST:-0}"
}

need() { [ -n "${!1:-}" ] || die "$1 is not set (in $settings)"; }
need_file() { need "$1"; [ -f "${!1}" ] || die "$1: no file ${!1}"; }

# The rcodesign arguments for a .p12 ($1) and its password file ($2, optional: else it asks).
p12_args() {
  printf '%s\n' --p12-file "$1"
  if [ -n "${2:-}" ]; then printf '%s\n' --p12-password-file "$2"; fi
}

# Same lines as build-apple.sh's manifest(): "<sha256> <x|-> <path>" or "link <path> -> <target>".
manifest() {
  (cd "$1" && LC_ALL=C find . \( -type f -o -type l \) | LC_ALL=C sort | while IFS= read -r f; do
    if [ -L "$f" ]; then
      printf 'link %s -> %s\n' "${f#./}" "$(readlink "$f")"
    else
      x=-; if [ -x "$f" ]; then x=x; fi
      printf '%s %s %s\n' "$(sha256 "$f")" "$x" "${f#./}"
    fi
  done)
}

# The section of PROVENANCE.txt ($1) listing the files of the app named $2.
provenance_files() {
  awk -v want="== files of $2 " 'index($0, want) == 1 { on = 1; next } on && /^$/ { exit } on { print }' "$1"
}

# Whether $1 is a Mach-O file (thin or universal).
is_macho() {
  case "$(head -c 4 "$1" | od -An -tx1 | tr -d ' \n')" in
    cffaedfe|cefaedfe|feedfacf|feedface|cafebabe|bebafeca) return 0 ;;
    *) return 1 ;;
  esac
}

# The Mach-O files under the bundle $1, as bundle-relative paths.
macho_files() {
  (cd "$1" && LC_ALL=C find . -type f | LC_ALL=C sort | while IFS= read -r f; do
    if is_macho "$f"; then echo "${f#./}"; fi
  done)
}

# The handoff folder $1: its SHA256SUMS hold, PROVENANCE.txt is shown, and the commit is the one
# asked for (RELEASE_COMMIT). Sets name, version, mac_tar, ios_tar.
check_handoff() {
  local dir="$1" head
  [ -d "$dir" ] || die "no hand-off folder $dir"
  if [ ! -f "$dir/SHA256SUMS" ] || [ ! -f "$dir/PROVENANCE.txt" ]; then die "$dir has no SHA256SUMS or PROVENANCE.txt"; fi
  (cd "$dir" && sha256sum -c --strict SHA256SUMS) || die "$dir does not match its SHA256SUMS"
  name="$(basename "$(cd "$dir" && pwd)")"
  mac_tar="$(cd "$dir" && ls EpicCashDesktop-*-macos-unsigned.tar.gz)"
  ios_tar="$(cd "$dir" && ls EpicCashMobile-*-ios-unsigned.tar.gz)"
  version="${mac_tar#EpicCashDesktop-}"
  version="${version%-macos-unsigned.tar.gz}"
  sed -n '1,/^== files of/p' "$dir/PROVENANCE.txt" | sed '$d'
  head="$(sed -n 's/^commit: *//p' "$dir/PROVENANCE.txt")"
  if [ -n "${RELEASE_COMMIT:-}" ]; then
    case "$head" in "$RELEASE_COMMIT"*) ;; *) die "built from $head, not RELEASE_COMMIT $RELEASE_COMMIT" ;; esac
  fi
  grep -q '^variant: *with Tor' "$dir/PROVENANCE.txt" || grep -q '^variant: *without Tor' "$dir/PROVENANCE.txt" \
    || die "PROVENANCE.txt names no variant"
}

# Unpacks the tar $1 into $2 and checks its files against the list for the app $3 in $4.
unpack_checked() {
  rm -rf "$2"
  mkdir -p "$2"
  tar -xzf "$1" -C "$2" --no-same-owner
  diff -u <(provenance_files "$4" "$3") <(manifest "$2/$3") > "$2.diff" \
    || die "the files of $3 differ from PROVENANCE.txt (see $2.diff)"
  rm -f "$2.diff"
}

check_cmd() {
  load_settings
  check_handoff "$1"
  local work
  work="$(mktemp -d "${TMPDIR:-/tmp}/apple-check.XXXXXX")"
  unpack_checked "$1/$mac_tar" "$work/mac" "$desktop_name.app" "$1/PROVENANCE.txt"
  unpack_checked "$1/$ios_tar" "$work/ios" Runner.app "$1/PROVENANCE.txt"
  echo "macOS Mach-O files:"
  macho_files "$work/mac/$desktop_name.app" | sed 's/^/  /'
  echo "iOS Mach-O files:"
  macho_files "$work/ios/Runner.app" | sed 's/^/  /'
  rm -rf "$work"
  echo "PASS check: $name, the files of both apps match PROVENANCE.txt"
}

# The signature of every Mach-O file under $1 (a bundle or one file), every architecture in it:
# signed by the team $2, hardened runtime when $3 = runtime, a secure timestamp, no
# get-task-allow, and rcodesign's own verification. (Here-strings, not `echo | grep -q`: with
# pipefail, grep -q stopping early makes a long echo fail.)
verify_tree() {
  local target="$1" team="$2" want_runtime="${3:-}" f info status=0 files bad slices
  if [ -d "$target" ]; then files="$(macho_files "$target")"; else files="$(basename "$target")"; target="$(dirname "$target")"; fi
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    info="$("$RCODESIGN" print-signature-info "$target/$f" 2>&1)" || { echo "FAIL $f: $info"; status=1; continue; }
    bad=""
    slices="$(grep -c 'sub_path: macho-index:' <<< "$info" || true)"
    [ "$slices" -gt 0 ] || slices=1
    [ "$(grep -c "subject: '*CN=[^,]*, OU=$team," <<< "$info" || true)" -ge "$slices" ] || bad="$bad, not signed by team $team"
    if [ "$want_runtime" = runtime ] && [ "$(grep -c 'flags: CodeSignatureFlags(.*RUNTIME' <<< "$info" || true)" -lt "$slices" ]; then
      bad="$bad, no hardened runtime"
    fi
    # Apple's timestamp server answers any signature, so the dry run checks this too.
    [ "$(grep -c 'time_stamp_token:' <<< "$info" || true)" -ge "$slices" ] || bad="$bad, no secure timestamp"
    if grep -q 'get-task-allow</key> *<true' <<< "$info"; then bad="$bad, get-task-allow"; fi
    "$RCODESIGN" verify "$target/$f" > /dev/null 2>&1 || bad="$bad, rcodesign verify fails"
    if [ -n "$bad" ]; then echo "FAIL $f:${bad#,}"; status=1; else echo "ok   $f ($slices architecture(s))"; fi
  done <<< "$files"
  return "$status"
}

verify_cmd() {
  load_settings
  local target="$1"
  [ -e "$target" ] || die "usage: apple-sign.sh verify <.app|.dmg|file>"
  case "$target" in
    *.dmg)
      "$RCODESIGN" print-signature-info "$target" | grep -E 'subject:|time_stamp_token:|identifier:' | head -8
      ;;
    *)
      need APPLE_TEAM_ID
      verify_tree "$target" "$APPLE_TEAM_ID" "$(case "$target" in *.app|*.app/) echo runtime ;; esac)"
      ;;
  esac
}

# The resource seal of the bundle whose _CodeSignature is in $1 (an app's Contents, or a flat iOS
# app), as codesign --verify --strict checks it on a Mac: every file is sealed with its SHA-256,
# every link with its target, nested code is referenced, and no file is outside the seal.
seal_check() {
  python3 -I - "$1" <<'PY'
import hashlib, os, plistlib, re, sys
base = sys.argv[1]
seal = plistlib.load(open(os.path.join(base, "_CodeSignature", "CodeResources"), "rb"))
files, rules = seal["files2"], seal.get("rules2", {})
omit = [re.compile(k) for k, v in rules.items() if isinstance(v, dict) and v.get("omit")]
nested = [k for k, v in files.items() if isinstance(v, dict) and "cdhash" in v]
main = plistlib.load(open(os.path.join(base, "Info.plist"), "rb"))["CFBundleExecutable"]
problems = []
for key, v in files.items():
    path = os.path.join(base, key)
    if not isinstance(v, dict):
        continue
    if "symlink" in v:
        if not os.path.islink(path) or os.readlink(path) != v["symlink"]:
            problems.append(f"link {key} differs from its seal")
    elif "hash2" in v:
        if os.path.islink(path) or not os.path.isfile(path):
            problems.append(f"sealed file missing: {key}")
        elif hashlib.sha256(open(path, "rb").read()).digest() != v["hash2"]:
            problems.append(f"sealed file changed: {key}")
    elif "cdhash" in v and not os.path.exists(path):
        problems.append(f"nested code missing: {key}")
for top, dirs, names in os.walk(base):
    for n in names + [d for d in dirs if os.path.islink(os.path.join(top, d))]:
        rel = os.path.relpath(os.path.join(top, n), base)
        if rel in files or rel.startswith("_CodeSignature/") or rel in (main, f"MacOS/{main}"):
            continue
        if any(rel.startswith(k + "/") for k in nested) or any(r.search(rel) for r in omit):
            continue
        problems.append(f"file outside the seal: {rel}")
if problems:
    print("\n".join("FAIL seal: " + p for p in problems[:40]))
    sys.exit(1)
print(f"ok   seal: {len(files)} entries, every file sealed and unchanged")
PY
}

# Notarises and staples $1 (an .app folder or a .dmg), unless this is a dry run.
notarise() {
  if [ "$test_mode" = 1 ]; then
    echo "dry run: not notarised (would run: rcodesign notary-submit --api-key-file \$ASC_API_KEY_JSON --staple $(basename "$1"))"
    return 0
  fi
  need_file ASC_API_KEY_JSON
  if ! "$RCODESIGN" notary-submit --api-key-file "$ASC_API_KEY_JSON" --max-wait-seconds 3600 --staple "$1"; then
    echo "apple-sign.sh: notarisation failed for $1; the log: rcodesign notary-log --api-key-file \$ASC_API_KEY_JSON <submission id>" >&2
    exit 3
  fi
}

macos_app_cmd() {
  load_settings
  need APPLE_TEAM_ID
  need_file DEVID_P12
  check_handoff "$1"
  local dir out work unsigned signed app_rel f entitlements flags=() signed_tar
  dir="$(cd "$1" && pwd)"
  out="$out_root/$name"
  work="$out/work"
  mkdir -p "$out"
  unsigned="$work/unsigned"
  signed="$work/signed"
  say "unpack and check"
  unpack_checked "$dir/$mac_tar" "$unsigned" "$desktop_name.app" "$dir/PROVENANCE.txt"
  app_rel="$desktop_name.app"
  [ "$(plist_get "$unsigned/$app_rel/Contents/Info.plist" CFBundleIdentifier)" = "$desktop_id" ] \
    || die "the app's CFBundleIdentifier is not $desktop_id"
  # Hardened runtime on every Mach-O: the main executable, the frameworks' binaries, and the loose
  # files the app adds (the node, tor, libevent). rcodesign signs nested code first (inside out)
  # and seals it into the app's CodeResources; settings other than the certificate are not
  # inherited (a framework's scope does not reach its Versions/A binary either), so each Mach-O
  # gets the runtime flag by its path. --for-notarization (real certificates only) checks the
  # same and refuses a missing timestamp.
  flags+=(--code-signature-flags runtime)
  # The plugins' resource bundles (Contents/Resources/*.bundle) hold no code: Xcode leaves them
  # unsigned and seals their files in the app's CodeResources. rcodesign would sign them as nested
  # bundles and leave their new seals outside the app's own, which codesign --strict reports.
  flags+=(--exclude 'Contents/Resources/*.bundle')
  while IFS= read -r f; do
    if [ "$f" != "Contents/MacOS/$desktop_name" ]; then flags+=(--code-signature-flags "$f:runtime"); fi
  done < <(macho_files "$unsigned/$app_rel")
  entitlements="$root/app/macos/Runner/Release.entitlements"
  say "sign $app_rel"
  rm -rf "$signed"
  mkdir -p "$signed"
  local p12
  mapfile -t p12 < <(p12_args "$DEVID_P12" "${DEVID_P12_PASSWORD_FILE:-}")
  if [ "$test_mode" = 1 ]; then
    "$RCODESIGN" sign "${p12[@]}" "${flags[@]}" -e "$entitlements" \
      "$unsigned/$app_rel" "$signed/$app_rel"
  else
    "$RCODESIGN" sign "${p12[@]}" --for-notarization "${flags[@]}" -e "$entitlements" \
      "$unsigned/$app_rel" "$signed/$app_rel"
  fi
  say "verify the signatures"
  verify_tree "$signed/$app_rel" "$APPLE_TEAM_ID" runtime
  seal_check "$signed/$app_rel/Contents"
  # Signing changes only Mach-O files and adds the seals: every other file is as built.
  diff -u <(manifest "$unsigned/$app_rel" | grep -v -F -f <(macho_files "$unsigned/$app_rel") | grep -v '_CodeSignature/CodeResources$') \
    <(manifest "$signed/$app_rel" | grep -v -F -f <(macho_files "$signed/$app_rel") | grep -v '_CodeSignature/CodeResources$') \
    || die "signing changed files other than code and seals"
  say "notarise and staple"
  notarise "$signed/$app_rel"
  say "pack for the release Mac"
  signed_tar="EpicCashDesktop-$version-macos-signed.tar.gz"
  tar --owner=0 --group=0 --numeric-owner --sort=name -czf "$out/$signed_tar" -C "$signed" "$app_rel"
  manifest "$signed/$app_rel" > "$out/EpicCashDesktop-$version-macos-signed.files.txt"
  (cd "$out" && sha256sum "$signed_tar" "EpicCashDesktop-$version-macos-signed.files.txt" > SHA256SUMS)
  cat "$out/SHA256SUMS"
  echo "PASS macos-app: give $out/$signed_tar and $out/SHA256SUMS to the release Mac (build-apple.sh dmg-signed)"
}

macos_dmg_cmd() {
  load_settings
  need APPLE_TEAM_ID
  need_file DEVID_P12
  check_handoff "$1"
  local dmg_in="$2" out work files_txt final p12
  [ -f "$dmg_in" ] || die "usage: apple-sign.sh macos-dmg <handoff dir> <.dmg>"
  command -v "$SEVENZIP" > /dev/null || die "no $SEVENZIP (7-Zip 23 or newer reads APFS and HFS+ disk images)"
  out="$out_root/$name"
  files_txt="$out/EpicCashDesktop-$version-macos-signed.files.txt"
  [ -f "$files_txt" ] || die "no $files_txt: run macos-app on this hand-off first"
  work="$out/work/dmg"
  rm -rf "$work"
  mkdir -p "$work"
  say "the app in $(basename "$dmg_in")"
  "$SEVENZIP" x -y -snl -o"$work" "$dmg_in" > /dev/null
  local top
  top="$(cd "$work" && LC_ALL=C find . -mindepth 1 -maxdepth 1 ! -name '.*' | sed 's|^\./||' | LC_ALL=C sort)"
  [ "$top" = "$(printf 'Applications\n%s.app' "$desktop_name")" ] \
    || die "the .dmg holds something else than the app and an Applications link: $top"
  # 7-Zip writes an absolute link target below the folder it unpacks into, for safety.
  case "$(readlink "$work/Applications")" in
    /Applications|"$work/Applications") ;;
    *) die "Applications in the .dmg is not a link to /Applications" ;;
  esac
  diff -u "$files_txt" <(manifest "$work/$desktop_name.app") > "$work.diff" \
    || die "the app in the .dmg is not the app signed here (see $work.diff)"
  rm -f "$work.diff"
  echo "the app in the .dmg is file for file the signed, stapled app"
  final="$out/EpicCashDesktop-$version-macos.dmg"
  cp "$dmg_in" "$final"
  say "sign the .dmg"
  mapfile -t p12 < <(p12_args "$DEVID_P12" "${DEVID_P12_PASSWORD_FILE:-}")
  "$RCODESIGN" sign "${p12[@]}" "$final"
  grep -q "OU=$APPLE_TEAM_ID" <<< "$("$RCODESIGN" print-signature-info "$final")" || die "the .dmg is not signed by $APPLE_TEAM_ID"
  say "notarise and staple the .dmg"
  notarise "$final"
  (cd "$out" && sha256sum "$(basename "$final")" > "$(basename "$final").sha256")
  cat "$final.sha256"
  echo "PASS macos-dmg: $final"
  echo "Next: the release Mac runs build-apple.sh gatekeeper on this file before it is published."
}

# A value from the plist $1 (XML or binary): the key $2.
plist_get() {
  python3 -I -c 'import plistlib,sys; v=plistlib.load(open(sys.argv[1],"rb")).get(sys.argv[2]); print("" if v is None else v)' "$1" "$2"
}

# The App Store profile $1 checked for the team $2, the bundle id $3 and the certificate in the
# .p12 $4 (password file $5); writes its entitlements for signing to $6.
profile_entitlements() {
  local profile="$1" team="$2" bundle="$3" cert_der
  cert_der="$(mktemp "${TMPDIR:-/tmp}/apple-cert.XXXXXX")"
  if [ -n "${5:-}" ]; then
    openssl pkcs12 -in "$4" -passin "file:$5" -nokeys -clcerts 2>/dev/null | openssl x509 -outform DER -out "$cert_der" \
      || openssl pkcs12 -legacy -in "$4" -passin "file:$5" -nokeys -clcerts | openssl x509 -outform DER -out "$cert_der"
  else
    openssl pkcs12 -in "$4" -nokeys -clcerts | openssl x509 -outform DER -out "$cert_der"
  fi
  openssl cms -verify -noverify -inform DER -in "$profile" -out "$cert_der.plist" 2>/dev/null \
    || openssl smime -verify -noverify -inform DER -in "$profile" -out "$cert_der.plist" 2>/dev/null \
    || die "cannot read the profile $profile"
  python3 -I - "$cert_der.plist" "$team" "$bundle" "$cert_der" "$6" "${APPLE_SIGN_TEST:-0}" <<'PY'
import datetime, plistlib, sys
src, team, bundle, cert_path, out, test = sys.argv[1:7]
p = plistlib.load(open(src, "rb"))
cert = open(cert_path, "rb").read()
problems = []
ent = p.get("Entitlements", {})
if team not in p.get("TeamIdentifier", []):
    problems.append(f"profile team {p.get('TeamIdentifier')} is not {team}")
if ent.get("application-identifier") != f"{team}.{bundle}":
    problems.append(f"application-identifier {ent.get('application-identifier')} is not {team}.{bundle}")
if ent.get("get-task-allow"):
    problems.append("get-task-allow is true: a development profile, not App Store")
if p.get("ProvisionedDevices") or p.get("ProvisionsAllDevices"):
    problems.append("the profile lists devices: an ad hoc or enterprise profile, not App Store")
if cert not in p.get("DeveloperCertificates", []):
    problems.append("the profile does not contain the certificate in the .p12")
exp = p.get("ExpirationDate")
if exp and exp.replace(tzinfo=None) < datetime.datetime.utcnow():
    problems.append(f"the profile expired on {exp}")
if problems:
    sys.exit("profile: " + "; ".join(problems))
# The entitlements Xcode signs an App Store build with: the app id, the team, no debugging, and
# TestFlight. No keychain-access-groups: the app's own id is its keychain group, and it must not
# change after the first release.
keep = {k: ent[k] for k in ("application-identifier", "com.apple.developer.team-identifier",
                             "get-task-allow", "beta-reports-active") if k in ent}
keep["get-task-allow"] = False
plistlib.dump(keep, open(out, "wb"))
print(f"profile {p.get('Name')!r}, team {team}, expires {exp}, entitlements: {sorted(keep)}")
PY
  rm -f "$cert_der" "$cert_der.plist"
}

ios_cmd() {
  load_settings
  need APPLE_TEAM_ID
  need_file DIST_P12
  need_file IOS_PROFILE
  check_handoff "$1"
  grep -q '^variant: *without Tor' "$1/PROVENANCE.txt" \
    || echo "note: this hand-off is the build with Tor; the App Store build is the one without Tor (WFE_TOR=0)" >&2
  local dir out work app ent ipa p12
  dir="$(cd "$1" && pwd)"
  out="$out_root/$name"
  work="$out/work/ios"
  mkdir -p "$out"
  say "unpack and check"
  unpack_checked "$dir/$ios_tar" "$work/unsigned" Runner.app "$dir/PROVENANCE.txt"
  app="$work/unsigned/Runner.app"
  [ "$(plist_get "$app/Info.plist" CFBundleIdentifier)" = "$phone_id" ] || die "the app's CFBundleIdentifier is not $phone_id"
  [ -f "$app/Frameworks/lepic_ffi.framework/PrivacyInfo.xcprivacy" ] \
    || die "lepic_ffi.framework has no PrivacyInfo.xcprivacy (build-apple.sh ipa adds it): App Store Connect refuses the upload"
  say "profile and entitlements"
  ent="$work/entitlements.plist"
  profile_entitlements "$IOS_PROFILE" "$APPLE_TEAM_ID" "$phone_id" "$DIST_P12" "${DIST_P12_PASSWORD_FILE:-}" "$ent"
  rm -rf "$work/stage"
  mkdir -p "$work/stage/Payload"
  cp -a "$app" "$work/stage/Payload/Runner.app"
  cp "$IOS_PROFILE" "$work/stage/Payload/Runner.app/embedded.mobileprovision"
  say "sign Runner.app"
  mapfile -t p12 < <(p12_args "$DIST_P12" "${DIST_P12_PASSWORD_FILE:-}")
  # The frameworks inside are signed first, without entitlements; the app last, with them.
  "$RCODESIGN" sign "${p12[@]}" -e "$ent" "$work/stage/Payload/Runner.app"
  verify_tree "$work/stage/Payload/Runner.app" "$APPLE_TEAM_ID"
  seal_check "$work/stage/Payload/Runner.app"
  ipa="$out/EpicCashMobile-$version-ios.ipa"
  rm -f "$ipa"
  (cd "$work/stage" && zip -qrX -y "$ipa" Payload)
  (cd "$out" && sha256sum "$(basename "$ipa")" > "$(basename "$ipa").sha256")
  cat "$ipa.sha256"
  echo "PASS ios: $ipa"
}

ios_upload_cmd() {
  load_settings
  local ipa="$1"
  [ -f "$ipa" ] || die "usage: apple-sign.sh ios-upload <.ipa>"
  need ASC_KEY_ID
  need ASC_ISSUER_ID
  need_file ASC_P8
  local args=(--key-id "$ASC_KEY_ID" --issuer-id "$ASC_ISSUER_ID" --p8 "$ASC_P8" --bundle-id "$phone_id" "$ipa")
  if [ "$test_mode" = 1 ]; then args=(--dry-run "${args[@]}"); fi
  # Its exit status passes through: 3 when Apple refused the upload.
  python3 -I "$root/tools/asc_upload.py" "${args[@]}"
}

csr_cmd() {
  load_settings
  local kind="$1" key csr subject
  case "$kind" in devid|dist) ;; *) die "usage: apple-sign.sh csr <devid|dist>" ;; esac
  need APPLE_CSR_NAME
  need APPLE_CSR_EMAIL
  mkdir -p "$APPLE_KEYS_DIR"
  chmod 700 "$APPLE_KEYS_DIR"
  key="$APPLE_KEYS_DIR/$kind.key.pem"
  csr="$APPLE_KEYS_DIR/$kind.csr"
  [ ! -e "$key" ] || die "$key exists: move it away first (it may be the key of a live certificate)"
  # Apple asks for RSA 2048. The key is encrypted with a passphrase you choose now.
  echo "A new passphrase for the $kind key (keep it with the key's backup):"
  (umask 077 && openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -aes-256-cbc -out "$key")
  subject="/emailAddress=$APPLE_CSR_EMAIL/CN=$APPLE_CSR_NAME/C=${APPLE_CSR_COUNTRY:-GB}"
  openssl req -new -key "$key" -subj "$subject" -out "$csr"
  echo "key: $key (encrypted)"
  echo "CSR: $csr -> upload it at developer.apple.com, Certificates, +, $(
    if [ "$kind" = devid ]; then echo "Developer ID Application (G2 Sub-CA)"; else echo "Apple Distribution"; fi)"
}

p12_cmd() {
  load_settings
  local kind="$1" cer="$2" key p12 pass pem
  case "$kind" in devid|dist) ;; *) die "usage: apple-sign.sh p12 <devid|dist> <certificate .cer>" ;; esac
  [ -f "$cer" ] || die "no certificate $cer"
  key="$APPLE_KEYS_DIR/$kind.key.pem"
  [ -f "$key" ] || die "no key $key (from: apple-sign.sh csr $kind)"
  p12="$APPLE_KEYS_DIR/$kind.p12"
  pass="$APPLE_KEYS_DIR/$kind.p12.password"
  pem="$(mktemp "${TMPDIR:-/tmp}/apple-cert.XXXXXX")"
  openssl x509 -inform DER -in "$cer" -out "$pem" 2>/dev/null || cp "$cer" "$pem"
  echo "The key's passphrase (from csr):"
  local key_pub cert_pub
  key_pub="$(openssl pkey -in "$key" -pubout)"
  cert_pub="$(openssl x509 -in "$pem" -noout -pubkey)"
  [ "$key_pub" = "$cert_pub" ] || { rm -f "$pem"; die "the certificate is not for $key"; }
  if [ ! -f "$pass" ]; then
    (umask 077 && openssl rand -base64 33 > "$pass")
  fi
  echo "The key's passphrase again, to pack the .p12:"
  (umask 077 && openssl pkcs12 -export -inkey "$key" -in "$pem" -name "$(openssl x509 -in "$pem" -noout -subject -nameopt multiline | sed -n 's/^ *commonName *= *//p')" \
    -passout "file:$pass" -out "$p12")
  rm -f "$pem"
  "$RCODESIGN" analyze-certificate --p12-file "$p12" --p12-password-file "$pass" | grep -E 'Subject CN|Team ID|Certificate Profile|Expires|not_after' || true
  echo "p12: $p12, password file: $pass"
  echo "Put them in $settings as $(if [ "$kind" = devid ]; then echo DEVID_P12 / DEVID_P12_PASSWORD_FILE; else echo DIST_P12 / DIST_P12_PASSWORD_FILE; fi)."
}

api_key_cmd() {
  load_settings
  need ASC_KEY_ID
  need ASC_ISSUER_ID
  need_file ASC_P8
  local json="${ASC_API_KEY_JSON:-$APPLE_KEYS_DIR/asc-api-key.json}"
  (umask 077 && "$RCODESIGN" encode-app-store-connect-api-key -o "$json" "$ASC_ISSUER_ID" "$ASC_KEY_ID" "$ASC_P8")
  echo "rcodesign's key file: $json (holds the private key: same care as the .p8)"
  echo "Put it in $settings as ASC_API_KEY_JSON."
}

doctor_cmd() {
  load_settings
  local ok=1 v tool
  echo "settings: $settings"
  if [ -f "$settings" ]; then
    [ "$(stat -c %a "$settings")" = 600 ] || { echo "settings file is not mode 600" >&2; ok=0; }
  else
    echo "no settings file: copy tools/apple-signing.env.example there" >&2; ok=0
  fi
  if command -v "$RCODESIGN" > /dev/null; then
    v="$("$RCODESIGN" --version | awk '{print $2}')"
    echo "rcodesign: $v"
    [ "$(printf '%s\n%s\n' "$rcodesign_min" "$v" | sort -V | head -1)" = "$rcodesign_min" ] \
      || { echo "rcodesign $rcodesign_min or newer is needed" >&2; ok=0; }
  else
    echo "missing: rcodesign (tools/apple-release.md, signer setup)" >&2; ok=0
  fi
  for tool in openssl python3 tar zip unzip sha256sum "$SEVENZIP"; do
    if command -v "$tool" > /dev/null; then echo "$tool: $(command -v "$tool")"; else echo "missing: $tool" >&2; ok=0; fi
  done
  echo "keys folder: $APPLE_KEYS_DIR"
  if [ -d "$APPLE_KEYS_DIR" ]; then
    [ "$(stat -c %a "$APPLE_KEYS_DIR")" = 700 ] || { echo "keys folder is not mode 700" >&2; ok=0; }
    if git -C "$APPLE_KEYS_DIR" rev-parse --git-dir > /dev/null 2>&1; then
      echo "the keys folder is inside a git repository: move it out" >&2; ok=0
    fi
  fi
  for v in APPLE_TEAM_ID DEVID_P12 DIST_P12 IOS_PROFILE ASC_KEY_ID ASC_ISSUER_ID ASC_P8 ASC_API_KEY_JSON; do
    if [ -z "${!v:-}" ]; then echo "$v: not set"
    elif [ "${v%_ID}" != "$v" ]; then echo "$v: set"
    elif [ -f "${!v}" ]; then echo "$v: $(basename "${!v}") (mode $(stat -c %a "${!v}"))"
    else echo "$v: missing file ${!v}" >&2; ok=0; fi
  done
  [ "$test_mode" = 1 ] && echo "APPLE_SIGN_TEST=1: dry run, test certificates, nothing goes to Apple"
  if [ "$ok" = 1 ]; then echo "PASS doctor"; else die "fix the above first"; fi
}

test_identity_cmd() {
  load_settings
  local dir="$1"
  [ -n "$dir" ] || die "usage: apple-sign.sh test-identity <dir>"
  mkdir -p "$dir"
  chmod 700 "$dir"
  dir="$(cd "$dir" && pwd)"
  local team=TESTTEAM01 pw="$dir/test.password"
  (umask 077 && echo dry-run-only > "$pw")
  "$RCODESIGN" generate-self-signed-certificate --profile developer-id-application --team-id "$team" \
    --person-name "Epic Cash dry run" --p12-file "$dir/devid-test.p12" --p12-password "$(cat "$pw")"
  "$RCODESIGN" generate-self-signed-certificate --profile apple-distribution --team-id "$team" \
    --person-name "Epic Cash dry run" --p12-file "$dir/dist-test.p12" --p12-password "$(cat "$pw")"
  # A stand-in App Store profile: the same plist shape, signed with the test key (the real one is
  # signed by Apple; profile_entitlements reads it without checking that signature either way).
  local key="$dir/dist-test.key" crt="$dir/dist-test.crt"
  openssl pkcs12 -in "$dir/dist-test.p12" -passin "file:$pw" -nocerts -nodes -out "$key" 2>/dev/null \
    || openssl pkcs12 -legacy -in "$dir/dist-test.p12" -passin "file:$pw" -nocerts -nodes -out "$key"
  openssl pkcs12 -in "$dir/dist-test.p12" -passin "file:$pw" -nokeys -clcerts -out "$crt" 2>/dev/null \
    || openssl pkcs12 -legacy -in "$dir/dist-test.p12" -passin "file:$pw" -nokeys -clcerts -out "$crt"
  python3 -I - "$dir/profile.plist" "$team" "$phone_id" "$crt" <<'PY'
import base64, datetime, plistlib, re, sys
out, team, bundle, crt = sys.argv[1:5]
der = base64.b64decode("".join(re.search(r"-----BEGIN CERTIFICATE-----(.*?)-----END", open(crt).read(), re.S).group(1).split()))
now = datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None, microsecond=0)
plistlib.dump({
    "Name": "Epic Cash Mobile App Store (dry run)", "TeamIdentifier": [team], "AppIDName": "Epic Cash Mobile",
    "ApplicationIdentifierPrefix": [team], "CreationDate": now, "ExpirationDate": now + datetime.timedelta(days=365),
    "DeveloperCertificates": [der], "Platform": ["iOS"], "Version": 1,
    "Entitlements": {"application-identifier": f"{team}.{bundle}", "com.apple.developer.team-identifier": team,
                     "keychain-access-groups": [f"{team}.*"], "get-task-allow": False, "beta-reports-active": True},
}, open(out, "wb"))
PY
  openssl cms -sign -nodetach -binary -outform DER -signer "$crt" -inkey "$key" -in "$dir/profile.plist" \
    -out "$dir/test.mobileprovision"
  rm -f "$key" "$dir/profile.plist"
  cat > "$dir/signing.env" <<EOF
# Dry run only: self-signed stand-ins. Nothing signed with these is trusted by any Apple device.
APPLE_SIGN_TEST=1
APPLE_TEAM_ID=$team
DEVID_P12=$dir/devid-test.p12
DEVID_P12_PASSWORD_FILE=$pw
DIST_P12=$dir/dist-test.p12
DIST_P12_PASSWORD_FILE=$pw
IOS_PROFILE=$dir/test.mobileprovision
EOF
  chmod 600 "$dir/signing.env"
  echo "dry-run identity in $dir; use it with: APPLE_SIGNING_ENV=$dir/signing.env tools/apple-sign.sh ..."
}

[ $# -gt 0 ] || { sed -n '2,37p' "$0" >&2; exit 2; }
cmd="$1"
shift
case "$cmd" in
  doctor) doctor_cmd ;;
  csr) csr_cmd "${1:-}" ;;
  p12) p12_cmd "${1:-}" "${2:-}" ;;
  api-key) api_key_cmd ;;
  check) check_cmd "${1:?usage: apple-sign.sh check <handoff dir>}" ;;
  macos-app) macos_app_cmd "${1:?usage: apple-sign.sh macos-app <handoff dir>}" ;;
  macos-dmg) macos_dmg_cmd "${1:?usage: apple-sign.sh macos-dmg <handoff dir> <.dmg>}" "${2:-}" ;;
  ios) ios_cmd "${1:?usage: apple-sign.sh ios <handoff dir>}" ;;
  ios-upload) ios_upload_cmd "${1:?usage: apple-sign.sh ios-upload <.ipa>}" ;;
  verify) verify_cmd "${1:?usage: apple-sign.sh verify <path>}" ;;
  test-identity) test_identity_cmd "${1:-}" ;;
  *) sed -n '2,37p' "$0" >&2; exit 2 ;;
esac
