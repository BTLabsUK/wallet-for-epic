#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Builds BT Wallet for macOS and for iOS on a Mac, from a clean checkout
# of this repository: LEPIC for the Apple targets, an ad-hoc-signed .app and .dmg, a Simulator
# .app, the smoke run, and the releases (tools/apple-release.md): `mac-release` makes the
# notarised .dmg for the download page with the team's Developer ID certificate on this Mac, and
# `ios-prepare` readies the iOS build that Xcode archives and uploads to TestFlight. Every step
# but those two works without an Apple account. The backup route (an unsigned hand-off signed on
# Linux with tools/apple-sign.sh) keeps its steps: release, handoff, dmg-signed.
#
# macOS builds are Apple silicon (arm64) only: the built-in node has no Intel build.
#
# iOS is only built without Tor (iOS cannot start a bundled tor): ios-sim, ipa and ios-prepare
# refuse to run unless WFE_TOR=0, and with Tor the other steps leave iOS out (lepic builds the
# macOS library only, smoke and live skip the Simulator, release and handoff carry the macOS app).
#
# Usage: tools/build-apple.sh [step...]   default: doctor sources lepic macos dmg (and ios-sim with WFE_TOR=0)
#        tools/build-apple.sh all         both variants, one after the other, in one command
#   doctor    print and check the toolchain (Xcode, SDKs, Simulator runtime, Flutter, Rust)
#   sources   the LEPIC and lepic-flutter clones in app/third_party at tools/lepic.rev and
#             tools/lepic-flutter.rev (cloned when missing from LEPIC_REPO / LEPIC_FLUTTER_REPO,
#             default the public GitHub copies, as tools/lepic.sh does)
#   lepic     liblepic_ffi.dylib for aarch64-apple-darwin and, with WFE_TOR=0, aarch64-apple-ios(-sim)
#             into app/third_party/lepic-flutter/native/<target>/ beside a SHA256SUMS, and a copy
#             kept in the variant's out dir (native/<target>/). The steps that build or test against
#             LEPIC (macos, ios-sim, ipa, smoke, live) first put the variant's copy back into the
#             shared native/ (a missing copy is built again by cargo, from its cache when that
#             variant was built before), so after `all` either variant's tests run with no rebuild:
#             tools/build-apple.sh smoke live; WFE_TOR=0 tools/build-apple.sh smoke live
#   macos     flutter build macos --release (arm64); the node and tor go into the bundle, then it
#             is signed ad hoc
#   dmg       the .app in a compressed .dmg with an Applications link
#   ios-sim   flutter build ios --simulator --debug; installed and started on a Simulator, with
#             a screenshot; the .app zipped
#   ipa       flutter build ios --release --no-codesign, zipped as an unsigned .ipa (a device
#             install needs it signed with a team first)
#   smoke     integration_test/simple_test.dart (PIN vault through LEPIC, secure storage, first
#             run) on macOS and on the Simulator, and a start of the built .app; neither touches
#             the login keychain (no secure storage probe on macOS, the .app with its own HOME)
#   live      integration_test/apple_live_test.dart on macOS and on the Simulator, on mainnet: a
#             new wallet on node.btlabs.uk (then node.epicnet.us, node.epiccash.com), its scan to
#             the tip, a restore from its phrase, the Epicbox listener connected (needs internet)
#   all       alone, no other step: both variants, each in its own run of this script (own WFE_TOR,
#             own out dir), the one with Tor first: doctor sources lepic macos dmg smoke live; then
#             WFE_TOR=0: the same and ios-sim. The without-Tor run happens even when the one with
#             Tor failed; the exit is non-zero if either failed. Ends with both results.txt.
#             APPLE_OUT, when set, is the parent: its tor/ and notor/ get the variants. Each
#             variant's results.txt starts empty. WFE_TOR is ignored (all sets it itself).
# Release steps (tools/apple-release.md), run on the release Mac from a clean checkout:
#   mac-release  release-check, a check of the signing set-up (Team ID in app/Signing.xcconfig,
#             its Developer ID Application certificate in the keychain, the notarytool profile),
#             doctor, sources, lepic (macOS), macos; then the app signed with Developer ID
#             (hardened runtime, timestamp, each Mach-O inside out), notarised, stapled; the .dmg
#             signed, notarised, stapled; gatekeeper. Out: mac-release/bt-wallet-<v>-macos.dmg,
#             .dmg.sha256 and .REPORT.txt, which go to the owner
#   ios-prepare  release-check, doctor, sources, lepic (iOS), flutter build ios --config-only;
#             then Xcode archives and uploads (Product > Archive). Needs WFE_TOR=0 (the App Store
#             build is the one without Tor) and WFE_DIST=appstore (no in-app updater)
# Backup route steps (signing on Linux, tools/apple-release.md appendix):
#   release   the build to sign, from a clean checkout: checks (release-check), then sources,
#             lepic, macos, ipa and handoff
#   release-check  the tree is clean, at version $RELEASE_VERSION and its tag v<version> (or at
#             RELEASE_COMMIT when set), Flutter is exactly the pinned version, the built-in
#             node is fetched by its pin
#   handoff   handoff/<name>/: the unsigned .app and (WFE_TOR=0) iOS Runner.app as tar files, PROVENANCE.txt
#             (commit, toolchain, pins, the SHA-256 of every file in both apps) and SHA256SUMS
#   dmg-signed <signed .app tar>   the .dmg of the app the signer signed and notarised (the
#             signer's SHA256SUMS beside the tar is checked first); Gatekeeper must accept the
#             app; the .dmg goes back to the signer, who signs and notarises it
#   gatekeeper <final .dmg>   Gatekeeper's verdict on the signed, notarised .dmg and on the app in
#             it, as a user's Mac would give it (spctl, stapler, codesign)
# A failing step leaves a FAIL line in results.txt before the script exits.
# Env:
#   APPLE_OUT=<dir>            results (default build-apple/tor, or build-apple/notor with WFE_TOR=0,
#                              at the repo root): the .app, .dmg, screenshots, logs and results.txt
#                              with one PASS/FAIL line per step (with `all`: the parent of tor/, notor/)
#   LEPIC_REPO, LEPIC_FLUTTER_REPO   where `sources` clones from (a git URL or path)
#   WFE_NODE_BIN_MAC_ARM64     the built-in node's epic binary (epic 4.1 or newer: the app's
#                              epic-server.toml has no foundation_path, which 4.0 needs), copied to
#                              Contents/Resources/bin/epic. Without it the app has no built-in node.
#   WFE_NODE_FETCH=1           fetch the node release pinned below (by SHA-256) when
#                              WFE_NODE_BIN_MAC_ARM64 is not set (the release step sets it)
#   CARGO_TARGET_DIR           LEPIC's cargo output (default app/third_party/lepic/target)
#   WFE_TOR=0                  the build without Tor (https://docs.btlabs.uk/developers/build/variants/): LEPIC without its
#                              tor feature, no tor in the .app, --dart-define=WFE_TOR=false
#   WFE_DIST=appstore          the App Store build (https://docs.btlabs.uk/developers/build/variants/): --dart-define=
#                              WFE_DIST=appstore, so no update check or Check for updates button
#                              and About says the App Store updates the app. iOS steps only
#                              (ios-sim, ipa, ios-prepare); unset or web, the builds are as before
#   SIM_DEVICE=<name or udid>  the Simulator (default: a booted iPhone, else the first available
#                              iPhone that is not an "iPhone Duo")
#   RELEASE_VERSION=<version>  release-check (required): the release, e.g. 26.10.25; the app's
#                              version must be it, and HEAD its tag v<version> (or RELEASE_COMMIT)
#   RELEASE_COMMIT=<sha>       release-check: the commit the owner asked for (full or short)
#   APPLE_TEAM_ID=<id>         the team for mac-release (default: DEVELOPMENT_TEAM in
#                              app/Signing.xcconfig)
#   NOTARY_PROFILE=<name>      the notarytool keychain profile (default epic-notary)
#
# Written for the bash 3.2 macOS ships: no mapfile, no ${x,,}, no associative arrays.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
app="$root/app"
lepic="$app/third_party/lepic"
binding="$app/third_party/lepic-flutter"
out="${APPLE_OUT:-$root/build-apple/$(if [ "${WFE_TOR:-1}" = 0 ]; then echo notor; else echo tor; fi)}"
results="$out/results.txt"
flutter_version=3.47.5
# Must match MACOSX_DEPLOYMENT_TARGET and IPHONEOS_DEPLOYMENT_TARGET in the Xcode projects, so
# the libraries never ask for a newer system than the app.
macos_min=12.0
ios_min=15.0
darwin_targets=aarch64-apple-darwin
ios_targets="aarch64-apple-ios aarch64-apple-ios-sim"
desktop_name="BT Wallet"
desktop_exe="btwallet"   # CFBundleExecutable: the file in Contents/MacOS
phone_id=uk.btlabs.btwallet.ios
# The built-in node for WFE_NODE_FETCH: the Epic Cash node release the Linux and Windows builds
# bundle (epic 4.1.1), its macOS zip. arm64 only: there is no x86_64 macOS release of 4.1, which
# is why the macOS app is arm64 only (the GUI 6.1.6's macOS binaries are epic 4.0.0, which stops
# at once on the app's toml: "missing field `foundation_path`", exit 101).
node_version=4.1.1
node_zip_url=https://github.com/EpicCash/epic/releases/download/v4.1.1/MacOS-aarch64-v4.1.1.zip
node_zip_sha=35bacc695c251723ecb4379b4a50270a8118fc140373723bb80fb73c65e36133

die() { echo "build-apple.sh: $*" >&2; exit 1; }
say() { printf '\n== %s\n' "$*"; }
result() { mkdir -p "$out"; printf '%s %s %s\n' "$1" "$2" "${3:-}" | tee -a "$results"; recorded="$2"; }
sha256() { shasum -a 256 "$1" | cut -d' ' -f1; }
build_id() { git -C "$root" rev-parse --short=8 HEAD; }
# The dart-define of the build without Tor (WFE_TOR=0), else empty: pass it as ${tor_def:+"$tor_def"}.
tor_def=""
if [ "${WFE_TOR:-1}" = 0 ]; then tor_def=--dart-define=WFE_TOR=false; fi
# The file name mark of the build without Tor, as the other platforms' packages have it.
variant() { if [ "${WFE_TOR:-1}" = 0 ]; then echo -notor; fi; }
# iOS is only built without Tor: true when this run builds iOS (WFE_TOR=0).
ios_built() { [ "${WFE_TOR:-1}" = 0 ]; }
ios_only_without_tor() { ios_built || die "$1: iOS is only built without Tor: WFE_TOR=0 tools/build-apple.sh $1"; }
# The dart-define of the App Store build (WFE_DIST=appstore), else empty: pass it as ${dist_def:+"$dist_def"}.
dist="${WFE_DIST:-web}"
case "$dist" in web|appstore) ;; *) echo "WFE_DIST=$dist: use web or appstore on Apple" >&2; exit 2 ;; esac
dist_def=""
if [ "$dist" = appstore ]; then dist_def=--dart-define=WFE_DIST=appstore; fi
app_version() { sed -n 's/^version: *\([0-9.]*\(-rc[0-9]*\)\{0,1\}\).*/\1/p' "$app/pubspec.yaml"; }

doctor() {
  say doctor
  [ "$(uname -s)" = Darwin ] || die "runs on macOS only (this is $(uname -s))"
  local ok=1
  sw_vers || ok=0
  echo "arch: $(uname -m)"
  xcode-select -p || { echo "no Xcode: install Xcode 27 (26 or newer) and run xcode-select -s" >&2; ok=0; }
  xcodebuild -version || ok=0
  echo "macOS SDK: $(xcrun --sdk macosx --show-sdk-path 2>/dev/null || echo missing)"
  echo "iOS Simulator SDK: $(xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null || echo missing)"
  if ! xcrun simctl list runtimes 2>/dev/null | grep -q '^iOS'; then
    echo "no iOS Simulator runtime: xcodebuild -downloadPlatform iOS (several GB)" >&2
    ok=0
  fi
  for tool in git curl jq lipo codesign hdiutil rustup cargo flutter; do
    command -v "$tool" >/dev/null || { echo "missing: $tool" >&2; ok=0; }
  done
  if command -v flutter >/dev/null; then
    local v
    v="$(flutter --version 2>/dev/null | sed -n 's/^Flutter \([0-9.]*\).*/\1/p')"
    echo "flutter: $v"
    [ "$v" = "$flutter_version" ] || echo "warning: the app is built with Flutter $flutter_version" >&2
  fi
  # Swift Package Manager is on by default in Flutter 3.47; CocoaPods only when it is turned off.
  if flutter config --list 2>/dev/null | grep -q 'enable-swift-package-manager: false'; then
    command -v pod >/dev/null || { echo "SPM is off and CocoaPods is missing" >&2; ok=0; }
  fi
  df -h "$root" | tail -1
  if [ "$ok" = 1 ]; then result PASS doctor; else result FAIL doctor; die "fix the toolchain first"; fi
}

# Clones (when missing) $1 from $2 and checks it out at $3, clean.
clone_at() {
  if [ ! -d "$1/.git" ]; then
    [ -n "$2" ] || die "no clone at $1: set $4 to clone it, or copy it there"
    git clone --quiet --no-checkout "$2" "$1"
  fi
  git -C "$1" cat-file -e "$3^{commit}" 2>/dev/null || git -C "$1" fetch --quiet origin
  git -C "$1" checkout --quiet --detach "$3"
  [ -z "$(git -C "$1" status --porcelain --untracked-files=no)" ] || die "$1 has local changes"
  echo "$(basename "$1") at $(git -C "$1" log --oneline -1)"
}

sources() {
  say sources
  local rev binding_rev
  rev="$(tr -d '[:space:]' < "$root/tools/lepic.rev")"
  binding_rev="$(tr -d '[:space:]' < "$root/tools/lepic-flutter.rev")"
  mkdir -p "$app/third_party"
  clone_at "$binding" "${LEPIC_FLUTTER_REPO:-https://github.com/BTLabsUK/lepic-flutter.git}" "$binding_rev" LEPIC_FLUTTER_REPO
  [ "$(tr -d '[:space:]' < "$binding/lepic.rev")" = "$rev" ] \
    || die "tools/lepic.rev differs from lepic-flutter's own lepic.rev"
  clone_at "$lepic" "${LEPIC_REPO:-https://github.com/BTLabsUK/lepic.git}" "$rev" LEPIC_REPO
  result PASS sources "lepic $(git -C "$lepic" rev-parse --short=8 HEAD)"
}

# Copies the release library of $1 into the binding's native/$1/ with its SHA256SUMS, the layout
# package:lepic's hook (iOS) and app/hook/build.dart (macOS) read; then keeps a copy of that
# folder in the variant's $out/native/$1/, which use_native puts back.
package_library() {
  local dir="$binding/native/$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  cp "${CARGO_TARGET_DIR:-$lepic/target}/$1/release/liblepic_ffi.dylib" "$dir/"
  (cd "$dir" && printf '%s  liblepic_ffi.dylib\n' "$(sha256 liblepic_ffi.dylib)" > SHA256SUMS)
  # LEPIC's xtask writes the features beside each library; `tor` unless built without it.
  if [ "${WFE_TOR:-1}" = 0 ]; then : > "$dir/FEATURES"; else echo tor > "$dir/FEATURES"; fi
  # And SOURCE, which package:lepic's hook checks against its lepic.rev (SOURCE_FILE in LEPIC's
  # xtask/src/mobile.rs): the commit, whether the tree had local changes, the compiler.
  local tree=clean
  [ -z "$(git -C "$lepic" status --porcelain --untracked-files=no)" ] || tree=modified
  printf 'lepic %s\ntree %s\n%s\n' "$(git -C "$lepic" rev-parse HEAD)" "$tree" \
    "$(cd "$lepic" && rustc --version)" > "$dir/SOURCE"
  rm -rf "$out/native/$1"
  mkdir -p "$out/native"
  cp -R "$dir" "$out/native/$1"
  echo "packaged $dir/liblepic_ffi.dylib (kept in $out/native/$1)"
}

# Puts this variant's LEPIC for the targets $@ (kept by the lepic step in $out/native/) into the
# shared native/ the builds and tests read, so they never use the other variant's library. A
# target with no kept copy is built first: cargo keeps both variants' artifacts in its target
# dir, so for a variant built before only lepic-ffi itself is compiled again.
use_native() {
  local t missing=""
  for t in "$@"; do
    [ -f "$out/native/$t/liblepic_ffi.dylib" ] || missing="$missing $t"
  done
  if [ -n "$missing" ]; then
    echo "no LEPIC kept in $out/native for$missing: building it (cargo's cache)"
    lepic_libs "${missing# }"
  fi
  for t in "$@"; do
    rm -rf "$binding/native/$t"
    mkdir -p "$binding/native"
    cp -R "$out/native/$t" "$binding/native/$t"
  done
  echo "LEPIC $(if [ "${WFE_TOR:-1}" = 0 ]; then echo without; else echo with; fi) Tor from $out/native: $*"
}

# LEPIC for the targets $1 (default: macOS, and iOS when it is built: WFE_TOR=0).
lepic_libs() {
  local targets="${1:-$darwin_targets}"
  if [ -z "${1:-}" ] && ios_built; then targets="$darwin_targets $ios_targets"; fi
  say "LEPIC for $targets"
  [ -f "$lepic/Cargo.toml" ] || die "no LEPIC clone: run the sources step"
  # rust-toolchain.toml picks LEPIC's Rust; its targets list has the iOS ones, not macOS.
  local t features=""
  [ "${WFE_TOR:-1}" = 0 ] && features=--no-default-features
  # shellcheck disable=SC2086 # the target lists split into words
  (cd "$lepic" && rustup target add $targets)
  # A plain cargo build per target: LEPIC's xtask packages iOS but has no macOS targets yet.
  for t in $targets; do
    (cd "$lepic" && MACOSX_DEPLOYMENT_TARGET=$macos_min IPHONEOS_DEPLOYMENT_TARGET=$ios_min \
      cargo build --package lepic-ffi --lib --locked --release --target "$t" $features)
    package_library "$t"
  done
  result PASS lepic "$(for t in $targets; do printf '%s ' "$t"; done)${features:+(without tor)}"
}

# Copies the Mach-O file $1 to $2 as an executable, after checking it is arm64 only.
copy_arm64() {
  [ "$(lipo -archs "$1")" = arm64 ] || die "$1 is $(lipo -archs "$1"), not arm64 only"
  cp "$1" "$2"
  chmod 755 "$2"
}

# Downloads the node release zip, checks it against its pinned SHA-256 and puts its epic at $1.
fetch_node() {
  local tmp="$out/node-zip"
  rm -rf "$tmp"
  mkdir -p "$tmp" "$(dirname "$1")"
  curl -fsSL --retry 3 -o "$tmp/node.zip" "$node_zip_url"
  [ "$(sha256 "$tmp/node.zip")" = "$node_zip_sha" ] || die "the node zip does not match its pinned SHA-256"
  ditto -x -k "$tmp/node.zip" "$tmp"
  cp "$tmp"/MacOS-aarch64-v$node_version/epic "$1"
  chmod 755 "$1"
  rm -rf "$tmp"
}

# Stages the built-in node and tor in app/build/apple-bin, where the macOS project's build phase
# "Bundle node and tor" (app/macos/Runner/bundle-bin.sh) copies them to Contents/Resources/bin and
# signs them before Xcode signs the app: in this script's builds and in an Xcode Archive alike.
stage_bin() {
  local res="$app/build/apple-bin"
  # A tor from an earlier build with Tor must not stay in a build without it.
  rm -rf "$res"
  mkdir -p "$res"
  # The built-in node: Contents/Resources/bin/epic (lib/src/builtin_node_provider.dart).
  if [ "${WFE_NODE_FETCH:-0}" = 1 ] && [ -z "${WFE_NODE_BIN_MAC_ARM64:-}" ]; then
    fetch_node "$out/node/arm64/epic"
    WFE_NODE_BIN_MAC_ARM64="$out/node/arm64/epic"
  fi
  if [ -n "${WFE_NODE_BIN_MAC_ARM64:-}" ]; then
    copy_arm64 "$WFE_NODE_BIN_MAC_ARM64" "$res/epic"
    # epic 4.0 needs foundation_path, which the app's toml leaves out: it would stop at once.
    local nv
    nv="$("$res/epic" --version 2>/dev/null | sed -n 's/^epic \([0-9.]*\).*/\1/p')"
    echo "node version: ${nv:-unknown (cannot run here)}"
    case "$nv" in 4.0.*|[0-3].*) die "the built-in node is epic $nv; the app needs 4.1 or newer" ;; esac
  else
    echo "no WFE_NODE_BIN_MAC_ARM64: no built-in node"
  fi
  # Tor: Contents/Resources/bin/tor-bundle/tor beside its libevent (lib/src/tor_location.dart);
  # tor finds libevent at @executable_path.
  if [ "${WFE_TOR:-1}" = 1 ]; then
    local tmp="$out/tor"
    rm -rf "$tmp"
    "$root/tools/fetch-tor.sh" macsilicon "$tmp/arm64"
    mkdir -p "$res/tor-bundle"
    copy_arm64 "$tmp/arm64/tor" "$res/tor-bundle/tor"
    copy_arm64 "$tmp/arm64/libevent-2.1.7.dylib" "$res/tor-bundle/libevent-2.1.7.dylib"
    cp "$tmp/arm64/LICENSE.tor.txt" "$tmp/arm64/VERSION" "$res/tor-bundle/"
    rm -rf "$tmp"
    echo "tor: $(cat "$res/tor-bundle/VERSION"), $(lipo -archs "$res/tor-bundle/tor")"
  fi
}

macos() {
  say "flutter build macos"
  [ "$dist" = web ] || die "WFE_DIST=$dist is for the iOS steps; the macOS app is the web build"
  local bundle="$app/build/macos/Build/Products/Release/$desktop_name.app"
  local res="$bundle/Contents/Resources/bin"
  use_native $darwin_targets
  stage_bin
  # FLUTTER_MACOS_ARM64_ONLY: Flutter's switch for an arm64-only release build (ARCHS=arm64);
  # the project also excludes x86_64 (macos/Runner/Configs/AppInfo.xcconfig).
  (cd "$app" && flutter pub get && FLUTTER_MACOS_ARM64_ONLY=1 flutter build macos --release \
    -t lib/main_desktop.dart --dart-define=WFE_BUILD_ID="$(build_id)" ${tor_def:+"$tor_def"})
  [ -d "$bundle" ] || die "no $bundle"
  [ -f "$bundle/Contents/Frameworks/lepic_ffi.framework/lepic_ffi" ] \
    || die "the bundle has no lepic_ffi.framework (app/hook/build.dart)"
  # The build phase "Bundle node and tor" copied exactly what stage_bin staged (the files only:
  # the signatures differ).
  [ -d "$res" ] || die "no $res (build phase \"Bundle node and tor\", app/macos/Runner/bundle-bin.sh)"
  [ "$(cd "$app/build/apple-bin" && find . -type f | LC_ALL=C sort)" = "$(cd "$res" && find . -type f | LC_ALL=C sort)" ] \
    || die "Contents/Resources/bin is not what app/build/apple-bin staged"
  # Ad hoc for this Mac (mac-release signs everything again with Developer ID); Xcode and the
  # build phase signed the same way, as the macOS project has no team (AppInfo.xcconfig), so no
  # Apple Development certificate is needed. No hardened runtime: an ad-hoc
  # framework would fail library validation under it.
  codesign --force --sign - --entitlements "$app/macos/Runner/Release.entitlements" "$bundle"
  codesign --verify --deep --strict --verbose=2 "$bundle"
  [ "$(lipo -archs "$bundle/Contents/MacOS/$desktop_exe")" = arm64 ] || die "the app is not arm64 only"
  mkdir -p "$out"
  rm -rf "$out/$desktop_name.app"
  ditto "$bundle" "$out/$desktop_name.app"
  result PASS macos "$(lipo -archs "$bundle/Contents/MacOS/$desktop_exe") $(du -sh "$bundle" | cut -f1)"
}

dmg() {
  say dmg
  local bundle="$out/$desktop_name.app" version stage
  [ -d "$bundle" ] || die "no $bundle: run the macos step"
  version="$(app_version)"
  stage="$out/dmg-stage"
  rm -rf "$stage"
  mkdir -p "$stage"
  ditto "$bundle" "$stage/$desktop_name.app"
  ln -s /Applications "$stage/Applications"
  hdiutil create -quiet -volname "$desktop_name" -srcfolder "$stage" -ov -format UDZO \
    "$out/bt-wallet-$version$(variant)-macos.dmg"
  rm -rf "$stage"
  result PASS dmg "bt-wallet-$version$(variant)-macos.dmg $(du -h "$out/bt-wallet-$version$(variant)-macos.dmg" | cut -f1)"
}

# The udid of SIM_DEVICE (a name or udid), else of a booted iPhone, else of the first available
# iPhone that is not an "iPhone Duo" (Xcode 27.2 made one on which the launch fails, exit 22).
simulator() {
  local want="${SIM_DEVICE:-}"
  xcrun simctl list devices available -j | jq -r --arg want "$want" '
    [.devices | to_entries[] | select(.key | test("iOS")) | .value[]] as $all
    | if $want != "" then [$all[] | select(.name == $want or .udid == $want)]
      else [$all[] | select(.name | startswith("iPhone")) | select(.name | startswith("iPhone Duo") | not)]
           | [.[] | select(.state == "Booted")] + .
      end
    | first | .udid // empty'
}

# The LEPIC targets smoke and live run against: macOS, and the Simulator when iOS is built.
test_native() {
  if ios_built; then use_native $darwin_targets aarch64-apple-ios-sim; else use_native $darwin_targets; fi
}

ios_sim() {
  say "flutter build ios --simulator"
  [ "$(uname -m)" = arm64 ] || die "the Simulator build needs an Apple silicon Mac (LEPIC has no x86_64 Simulator library)"
  use_native aarch64-apple-ios-sim
  (cd "$app" && flutter pub get && flutter build ios --simulator --debug -t lib/main.dart \
    --dart-define=WFE_BUILD_ID="$(build_id)" ${tor_def:+"$tor_def"} ${dist_def:+"$dist_def"})
  local bundle="$app/build/ios/iphonesimulator/Runner.app" udid
  [ -d "$bundle" ] || die "no $bundle"
  udid="$(simulator)"
  [ -n "$udid" ] || die "no Simulator found (xcrun simctl list devices available)"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl install "$udid" "$bundle"
  xcrun simctl launch "$udid" "$phone_id"
  sleep 15
  mkdir -p "$out"
  xcrun simctl io "$udid" screenshot "$out/ios-sim.png"
  ditto -c -k --keepParent "$bundle" "$out/bt-wallet-$(app_version)$(variant)-ios-simulator.zip"
  result PASS ios-sim "$udid, screenshot ios-sim.png"
}

# The device build without signing: Payload/Runner.app zipped as an .ipa. Not installable as it
# is; a team's certificate and profile have to sign it first.
ipa() {
  say "flutter build ios --no-codesign"
  use_native aarch64-apple-ios
  (cd "$app" && flutter pub get && flutter build ios --release --no-codesign -t lib/main.dart \
    --dart-define=WFE_BUILD_ID="$(build_id)" ${tor_def:+"$tor_def"} ${dist_def:+"$dist_def"})
  local bundle="$app/build/ios/iphoneos/Runner.app" stage="$out/ipa-stage"
  local ipa_file
  ipa_file="$out/bt-wallet-$(app_version)$(variant)-ios-unsigned.ipa"
  [ -d "$bundle" ] || die "no $bundle"
  [ -f "$bundle/Frameworks/lepic_ffi.framework/lepic_ffi" ] || die "the .app has no lepic_ffi.framework"
  # The framework Flutter makes from LEPIC has no privacy manifest; App Store Connect wants the
  # reasons for its file-timestamp and disk-space calls (ios/lepic_ffi.PrivacyInfo.xcprivacy).
  cp "$app/ios/lepic_ffi.PrivacyInfo.xcprivacy" "$bundle/Frameworks/lepic_ffi.framework/PrivacyInfo.xcprivacy"
  rm -rf "$stage" "$ipa_file"
  mkdir -p "$stage/Payload"
  ditto "$bundle" "$stage/Payload/Runner.app"
  (cd "$stage" && ditto -c -k --keepParent Payload "$ipa_file")
  rm -rf "$stage"
  result PASS ipa "$(basename "$ipa_file") $(du -h "$ipa_file" | cut -f1)"
}

# The tor inside the release .app $1, run as it is: its ad-hoc signature passes (no "Killed: 9"),
# it bootstraps to 100% and carries one node get_tip (node.btlabs.uk by its onion as the app
# routes it, then through an exit, then node.epicnet.us, then node.epiccash.com). Also logs the
# app's and tor's signatures and entitlements. Log: smoke-tor.log.
tor_check() {
  local tor="$1/Contents/Resources/bin/tor-bundle/tor" data="$out/tor-check-data"
  local log="$out/smoke-tor.log" port=19150 pid i rc target via url answered=""
  local onion=5drwoknehnzducfsxsl45dazaw3cwcmpx3ycamynagmcpv6aalrbrtqd.onion
  local tip='{"jsonrpc":"2.0","id":1,"method":"get_tip","params":[]}'
  rm -rf "$data"
  mkdir -p "$data"
  chmod 700 "$data"
  {
    echo "== codesign of the app"; codesign -dv --entitlements - "$1" 2>&1 || true
    echo "== codesign of tor"; codesign -dv --entitlements - "$tor" 2>&1 || true
    echo "== tor --version"; "$tor" --version 2>&1 || echo "tor --version exit $?"
    echo "== tor run"
  } > "$log"
  "$tor" --SocksPort "$port" --DataDirectory "$data" --Log "notice stdout" >> "$log" 2>&1 &
  pid=$!
  for i in $(seq 1 240); do
    grep -q 'Bootstrapped 100%' "$log" && break
    kill -0 "$pid" 2>/dev/null || break
    sleep 1
  done
  if ! grep -q 'Bootstrapped 100%' "$log"; then
    rc=0
    if kill -0 "$pid" 2>/dev/null; then kill "$pid"; fi
    wait "$pid" || rc=$?
    echo "== tor exit $rc (137 = SIGKILL, as from a code signature refusal)" >> "$log"
    result FAIL smoke-tor "no Bootstrapped 100% after ${i}s, tor exit $rc"
    return 1
  fi
  echo "== bootstrapped after ${i}s" >> "$log"
  for target in "node.btlabs.uk:onion" https://node.btlabs.uk https://node.epicnet.us:3413 \
      https://node.epiccash.com:3413; do
    echo "== get_tip $target" >> "$log"
    case "$target" in
      *:onion) via="node.btlabs.uk:443:$onion:443" url=https://node.btlabs.uk ;;
      *) via="" url="$target" ;;
    esac
    # shellcheck disable=SC2086
    if curl -fsS --max-time 90 --socks5-hostname "127.0.0.1:$port" ${via:+--connect-to $via} \
        -H 'Content-Type: application/json' -d "$tip" "$url/v2/foreign" >> "$log" 2>&1; then
      answered="$target"
      break
    fi
    echo >> "$log"
  done
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  if [ -n "$answered" ]; then
    result PASS smoke-tor "tor from the .app bootstrapped in ${i}s; get_tip over tor: $answered"
  else
    result FAIL smoke-tor "bootstrapped in ${i}s but no node answered over tor"
    return 1
  fi
}

smoke() {
  say smoke
  test_native
  mkdir -p "$out"
  local status=0 udid
  if (cd "$app" && flutter test integration_test/simple_test.dart -d macos --dart-define=WFE_TEST_NO_KEYCHAIN=true) > "$out/smoke-macos.log" 2>&1; then
    result PASS smoke-macos simple_test
  else
    result FAIL smoke-macos "simple_test, see smoke-macos.log"; status=1
  fi
  if ! ios_built; then
    result SKIP smoke-ios-sim "iOS is only built without Tor (WFE_TOR=0)"
  elif udid="$(simulator)" && [ -n "$udid" ] && (cd "$app" && flutter test integration_test/simple_test.dart -d "$udid") \
      > "$out/smoke-ios-sim.log" 2>&1; then
    result PASS smoke-ios-sim simple_test
  else
    result FAIL smoke-ios-sim "simple_test, see smoke-ios-sim.log"; status=1
  fi
  # The release .app starts and stays up; a screenshot when the session allows it.
  local bundle="$out/$desktop_name.app"
  if [ -d "$bundle" ]; then
    # Started with a home of its own: no keychain in its search list, so the ad-hoc build (a
    # new identity each build) never asks for the login keychain, and its data folder is there.
    local home="$out/smoke-home" pid
    rm -rf "$home"
    mkdir -p "$home"
    HOME="$home" CFFIXED_USER_HOME="$home" "$bundle/Contents/MacOS/$desktop_exe" > "$out/smoke-macos-app.log" 2>&1 &
    pid=$!
    sleep 20
    if kill -0 "$pid" 2>/dev/null; then
      screencapture -x "$out/macos.png" 2>/dev/null || echo "no screenshot (Screen Recording permission)"
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      result PASS smoke-macos-app "started and stayed up 20 s"
    else
      result FAIL smoke-macos-app "not running 20 s after start, see smoke-macos-app.log"; status=1
    fi
  fi
  # Tor from the release .app: on its own, then started through LEPIC in the app's code.
  local tor="$bundle/Contents/Resources/bin/tor-bundle/tor"
  if [ -x "$tor" ] && [ "${WFE_TOR:-1}" = 0 ]; then
    result FAIL smoke-tor "tor in the build without Tor"; status=1
  elif [ -x "$tor" ]; then
    tor_check "$bundle" || status=1
    if (cd "$app" && flutter test integration_test/tor_apple_test.dart -d macos --dart-define-from-file=integration_test/live-hosts.json \
        --dart-define=WFE_TEST_TOR="$tor") > "$out/smoke-tor-app.log" 2>&1; then
      result PASS smoke-tor-app "$(grep -m1 'over tor: height' "$out/smoke-tor-app.log" | sed 's/.*TOR-CHECK //')"
    else
      result FAIL smoke-tor-app "see smoke-tor-app.log"; status=1
    fi
  else
    # The build without Tor must have none; any other build must.
    if [ "${WFE_TOR:-1}" = 0 ]; then result PASS smoke-tor "no tor in the .app (build without Tor)"
    else result FAIL smoke-tor "no tor in the .app"; status=1; fi
  fi
  return "$status"
}

live() {
  say live
  test_native
  mkdir -p "$out"
  local status=0 udid
  if (cd "$app" && flutter test integration_test/apple_live_test.dart -d macos --dart-define-from-file=integration_test/live-hosts.json ${tor_def:+"$tor_def"}) \
      > "$out/live-macos.log" 2>&1; then
    result PASS live-macos "$(grep 'LIVE-CHECK' "$out/live-macos.log" | sed 's/.*LIVE-CHECK //' | tr '\n' ';')"
  else
    result FAIL live-macos "see live-macos.log"; status=1
  fi
  if ! ios_built; then
    result SKIP live-ios-sim "iOS is only built without Tor (WFE_TOR=0)"
  elif udid="$(simulator)" && [ -n "$udid" ] && (cd "$app" && flutter test integration_test/apple_live_test.dart -d "$udid" --dart-define-from-file=integration_test/live-hosts.json ${tor_def:+"$tor_def"}) \
      > "$out/live-ios-sim.log" 2>&1; then
    result PASS live-ios-sim "$(grep 'LIVE-CHECK' "$out/live-ios-sim.log" | sed 's/.*LIVE-CHECK //' | tr '\n' ';')"
  else
    result FAIL live-ios-sim "see live-ios-sim.log"; status=1
  fi
  return "$status"
}

# One line per file and symlink under $1, sorted by path: "<sha256> <x|-> <path>" (x: executable)
# or "link <path> -> <target>". tools/apple-sign.sh writes the same lines on Linux, so the
# signer compares the trees it gets, signs and gets back with these lists.
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

# A tar.gz at $3 of the folder $2 inside $1: no macOS metadata (no ._ files, no extended
# attributes such as quarantine or provenance), owner root, so it unpacks the same on Linux.
pack() {
  rm -f "$3"
  COPYFILE_DISABLE=1 tar --no-mac-metadata --no-xattrs --uid 0 --gid 0 --uname root --gname wheel \
    -czf "$3" -C "$1" "$2"
}

# The checks before a release build: the commit is the one asked for and has no local changes,
# the toolchain is the pinned one, and the built-in node comes from its pin.
release_check() {
  say release-check
  local head dirty v tag
  head="$(git -C "$root" rev-parse HEAD)"
  dirty="$(git -C "$root" status --porcelain --untracked-files=normal -- . ':!build-apple')"
  if [ -n "$dirty" ]; then
    echo "$dirty" >&2
    die "the checkout has local changes or untracked files: release builds come from a clean clone"
  fi
  if [ -n "${RELEASE_COMMIT:-}" ]; then
    case "$head" in "$RELEASE_COMMIT"*) ;; *) die "HEAD is $head, not RELEASE_COMMIT $RELEASE_COMMIT" ;; esac
  fi
  # One release, one commit: main moves on to the next version right after a publish, so the
  # Mac and iOS builds both come from the release's tag, never from wherever main is now.
  [ -n "${RELEASE_VERSION:-}" ] || die "set RELEASE_VERSION=<version> (the release's tag without the v)"
  [ "$(app_version)" = "$RELEASE_VERSION" ] \
    || die "the checkout is version $(app_version), not RELEASE_VERSION $RELEASE_VERSION: git fetch --tags origin && git checkout --detach v$RELEASE_VERSION"
  # Without RELEASE_COMMIT (the release runner's hand-offs give its own commit id), HEAD is the tag.
  if [ -z "${RELEASE_COMMIT:-}" ]; then
    tag="$(git -C "$root" rev-parse -q --verify "refs/tags/v$RELEASE_VERSION^{commit}")" \
      || die "no tag v$RELEASE_VERSION here: git fetch --tags origin && git checkout --detach v$RELEASE_VERSION"
    [ "$head" = "$tag" ] || die "HEAD is $head, not the tag v$RELEASE_VERSION ($tag): git checkout --detach v$RELEASE_VERSION"
  fi
  v="$(flutter --version 2>/dev/null | sed -n 's/^Flutter \([0-9.]*\).*/\1/p')"
  [ "$v" = "$flutter_version" ] || die "Flutter is $v; release builds use exactly $flutter_version"
  [ "$(uname -m)" = arm64 ] || die "release builds run on an Apple silicon Mac"
  if [ -z "${WFE_NODE_BIN_MAC_ARM64:-}" ]; then WFE_NODE_FETCH=1; fi
  result PASS release-check "$(git -C "$root" rev-parse --short=9 HEAD) $(app_version) flutter $v"
}

# What the release was built from and with, and the SHA-256 of every file in both apps (the
# macOS app only when $2 is empty: the build with Tor has no iOS app).
provenance() {
  local mac_app="$1" ios_app="$2" tor_pin
  echo "Epic Cash Apple release build: what it was built from and with"
  echo "app version:      $(app_version) ($(sed -n 's/^version: *//p' "$app/pubspec.yaml"))"
  if [ "${WFE_TOR:-1}" = 0 ]; then echo "variant:          without Tor (WFE_TOR=0)"; else echo "variant:          with Tor"; fi
  echo "commit:           $(git -C "$root" rev-parse HEAD)"
  echo "commit date:      $(git -C "$root" log -1 --format=%cI)"
  echo "built at:         $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "lepic:            $(git -C "$lepic" rev-parse HEAD)"
  echo "lepic-flutter:    $(git -C "$binding" rev-parse HEAD)"
  echo "macOS:            $(sw_vers -productVersion) ($(sw_vers -buildVersion)) $(uname -m)"
  echo "Xcode:            $(xcodebuild -version | tr '\n' ' ')"
  echo "macOS SDK:        $(xcrun --sdk macosx --show-sdk-version)"
  echo "iOS SDK:          $(xcrun --sdk iphoneos --show-sdk-version)"
  echo "Flutter:          $(flutter --version 2>/dev/null | head -4 | tr -s ' ' | tr '\n' ' ')"
  echo "Rust:             $(cd "$lepic" && rustc --version) / $(cd "$lepic" && cargo --version)"
  echo "pubspec.lock:     $(sha256 "$app/pubspec.lock")"
  echo "LEPIC Cargo.lock: $(sha256 "$lepic/Cargo.lock")"
  echo "node:             epic $node_version, $node_zip_url sha256 $node_zip_sha"
  if [ "${WFE_TOR:-1}" = 1 ]; then
    tor_pin="$(jq -r '.platforms.macsilicon.tarball + " sha256 " + .platforms.macsilicon.sha256' \
      "$root/tools/tor-bundle.json" 2>/dev/null || echo "see tools/tor-bundle.json")"
    echo "tor:              $tor_pin"
  fi
  echo
  echo "== files of $desktop_name.app (unsigned)"
  manifest "$mac_app"
  if [ -n "$ios_app" ]; then
    echo
    echo "== files of Runner.app (iOS, unsigned)"
    manifest "$ios_app"
  fi
}

# The folder that goes to the signer: the unsigned apps as tar.gz (the iOS one only without Tor),
# PROVENANCE.txt and SHA256SUMS.
handoff() {
  say handoff
  local mac_app="$out/$desktop_name.app" ios_app="" name dir mac_tar ios_tar=""
  [ -d "$mac_app" ] || die "no $mac_app: run the macos step"
  if ios_built; then
    ios_app="$app/build/ios/iphoneos/Runner.app"
    [ -d "$ios_app" ] || die "no $ios_app: run the ipa step"
  fi
  name="EpicCash-$(app_version)$(variant)-$(git -C "$root" rev-parse --short=9 HEAD)"
  dir="$out/handoff/$name"
  rm -rf "$dir"
  mkdir -p "$dir"
  mac_tar="bt-wallet-$(app_version)$(variant)-macos-unsigned.tar.gz"
  pack "$(dirname "$mac_app")" "$(basename "$mac_app")" "$dir/$mac_tar"
  if [ -n "$ios_app" ]; then
    ios_tar="bt-wallet-$(app_version)$(variant)-ios-unsigned.tar.gz"
    pack "$(dirname "$ios_app")" Runner.app "$dir/$ios_tar"
  fi
  provenance "$mac_app" "$ios_app" > "$dir/PROVENANCE.txt"
  (cd "$dir" && shasum -a 256 "$mac_tar" ${ios_tar:+"$ios_tar"} PROVENANCE.txt > SHA256SUMS)
  cat "$dir/SHA256SUMS"
  result PASS handoff "$dir"
}

# The .dmg of the app the signer signed, notarised and stapled ($1, a tar.gz with the signer's
# SHA256SUMS beside it). Nothing is signed here: the .dmg goes back to the signer.
dmg_signed() {
  say dmg-signed
  local tar="$1" dir stage app_dir version name
  [ -f "$tar" ] || die "usage: build-apple.sh dmg-signed <signed .app tar.gz>"
  dir="$(cd "$(dirname "$tar")" && pwd)"
  [ -f "$dir/SHA256SUMS" ] || die "no SHA256SUMS beside $tar"
  (cd "$dir" && grep " $(basename "$tar")\$" SHA256SUMS | shasum -a 256 -c -) \
    || die "$tar does not match SHA256SUMS"
  # bt-wallet-<version>-…; a signer's tar from before the rename is EpicCashDesktop-<version>-….
  version="$(basename "$tar" | sed -n -e 's/^bt-wallet-\(.*\)-macos-signed\.tar\.gz$/\1/p' -e 's/^EpicCashDesktop-\(.*\)-macos-signed\.tar\.gz$/\1/p')"
  [ -n "$version" ] || die "$tar is not named bt-wallet-<version>-macos-signed.tar.gz"
  stage="$out/dmg-signed-stage"
  rm -rf "$stage"
  mkdir -p "$stage"
  tar -xzf "$tar" -C "$stage"
  app_dir="$stage/$desktop_name.app"
  [ -d "$app_dir" ] || die "no $desktop_name.app in $tar"
  # The signer's signature, the notarisation ticket and Gatekeeper, as a downloaded app gets them.
  codesign --verify --deep --strict --verbose=2 "$app_dir"
  xcrun stapler validate "$app_dir"
  spctl --assess --type execute --verbose=4 "$app_dir"
  ln -s /Applications "$stage/Applications"
  name="bt-wallet-$version-macos.dmg"
  mkdir -p "$out/dmg-signed"
  hdiutil create -quiet -volname "$desktop_name" -srcfolder "$stage" -ov -format UDZO "$out/dmg-signed/$name"
  rm -rf "$stage"
  (cd "$out/dmg-signed" && shasum -a 256 "$name" > "$name.sha256")
  result PASS dmg-signed "$out/dmg-signed/$name (the .dmg of the signed app: back to the signer)"
}

# Gatekeeper's verdict on the final .dmg ($1) and on the app inside, on this Mac: what a user who
# downloads it gets. Needs the signed, notarised and stapled .dmg from the signer.
gatekeeper() {
  say gatekeeper
  local dmg_file="$1" mnt log="$out/gatekeeper.log" status=0
  [ -f "$dmg_file" ] || die "usage: build-apple.sh gatekeeper <final .dmg>"
  mkdir -p "$out"
  if ! {
    echo "== $(basename "$dmg_file") sha256 $(sha256 "$dmg_file")"
    codesign --verify --verbose=2 "$dmg_file"
    xcrun stapler validate "$dmg_file"
    spctl --assess --type open --context context:primary-signature --verbose=4 "$dmg_file"
  } > "$log" 2>&1; then
    cat "$log"
    result FAIL gatekeeper "the .dmg, see gatekeeper.log"
    return 1
  fi
  mnt="$(mktemp -d "${TMPDIR:-/tmp}/epic-dmg.XXXXXX")"
  hdiutil attach -quiet -nobrowse -readonly -mountpoint "$mnt" "$dmg_file"
  {
    codesign --verify --deep --strict --verbose=2 "$mnt/$desktop_name.app" &&
    codesign -dv --verbose=4 "$mnt/$desktop_name.app" 2>&1 \
      | grep -E '^(Identifier|Format|Authority|TeamIdentifier|Timestamp|Runtime Version)' &&
    xcrun stapler validate "$mnt/$desktop_name.app" &&
    spctl --assess --type execute --verbose=4 "$mnt/$desktop_name.app"
  } >> "$log" 2>&1 || status=1
  hdiutil detach -quiet "$mnt" || true
  rmdir "$mnt" 2>/dev/null || true
  cat "$log"
  if [ "$status" = 0 ]; then
    result PASS gatekeeper "$(basename "$dmg_file"): accepted, notarised, stapled"
  else
    result FAIL gatekeeper "the app in $(basename "$dmg_file"), see gatekeeper.log"
    return 1
  fi
}

# ---- The release route (tools/apple-release.md): the release Mac signs with the BT Labs team ----

# The notarytool keychain profile (made once: xcrun notarytool store-credentials).
notary_profile="${NOTARY_PROFILE:-epic-notary}"

# The Team ID: APPLE_TEAM_ID, else DEVELOPMENT_TEAM of app/Signing.xcconfig.
team_id() {
  local t="${APPLE_TEAM_ID:-}"
  if [ -z "$t" ] && [ -f "$app/Signing.xcconfig" ]; then
    t="$(sed -n 's/^[[:space:]]*DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*\([A-Z0-9]*\).*/\1/p' "$app/Signing.xcconfig" | head -1)"
  fi
  case "$t" in
    [A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]) ;;
    *) die "no Team ID: copy app/Signing.xcconfig.example to app/Signing.xcconfig and set DEVELOPMENT_TEAM" ;;
  esac
  [ "$t" != ABCDE12345 ] || die "app/Signing.xcconfig still has the example Team ID"
  echo "$t"
}

# The SHA-1 of the Developer ID Application identity of team $1 in the keychain (the first, if
# there are several: a hash, so codesign never finds the name ambiguous).
devid_identity() {
  local ids
  ids="$(security find-identity -v -p codesigning)"
  awk -v t="($1)\"" 'index($0, "\"Developer ID Application:") && index($0, t) { print $2; exit }' <<< "$ids"
}

is_macho() { case "$(file -b "$1")" in Mach-O*) return 0 ;; *) return 1 ;; esac; }

# Signs the app $1 with the identity $2 as Apple's "Creating distribution-signed code for Mac" has
# it: every code item on its own, inside out, hardened runtime and Apple's timestamp on each; the
# app last, with its entitlements. No --deep. The plugins' resource bundles hold no code and stay
# sealed as resources of the app, as Xcode leaves them.
devid_sign() {
  local bundle="$1" id="$2" rel fw name
  local main="Contents/MacOS/$desktop_exe"
  # Loose Mach-O files first (the node, tor, libevent, anything nested in a framework that is not
  # its own binary), deepest path first.
  while IFS= read -r rel; do
    is_macho "$bundle/$rel" || continue
    [ "$rel" != "$main" ] || continue
    case "$rel" in
      Contents/Frameworks/*.framework/Versions/*/*)
        fw="${rel%%.framework/*}.framework"
        name="$(basename "$fw" .framework)"
        case "$rel" in "$fw"/Versions/*/"$name") continue ;; esac
        ;;
    esac
    codesign --force --timestamp --options runtime --sign "$id" "$bundle/$rel"
  done < <(cd "$bundle" && find Contents -type f -not -path 'Contents/Resources/*.bundle/*' \
             | awk '{ print length($0) " " $0 }' | LC_ALL=C sort -rn | cut -d' ' -f2-)
  for fw in "$bundle"/Contents/Frameworks/*.framework; do
    if [ -d "$fw" ]; then codesign --force --timestamp --options runtime --sign "$id" "$fw"; fi
  done
  codesign --force --timestamp --options runtime --sign "$id" \
    --entitlements "$app/macos/Runner/Release.entitlements" "$bundle"
}

# Every Mach-O file of the app $1 carries team $2, the hardened runtime and a secure timestamp:
# what notarisation checks, so a miss shows here and not after an upload.
devid_check() {
  local bundle="$1" team="$2" rel info bad=0
  codesign --verify --deep --strict --verbose=2 "$bundle"
  while IFS= read -r rel; do
    is_macho "$bundle/$rel" || continue
    info="$(codesign -dv --verbose=4 "$bundle/$rel" 2>&1 || true)"
    if ! grep -q "^TeamIdentifier=$team\$" <<< "$info" || ! grep -q 'runtime' <<< "$info" \
      || ! grep -q '^Timestamp=' <<< "$info"; then
      echo "not signed for notarisation: $rel" >&2
      bad=1
    fi
  done < <(cd "$bundle" && find Contents -type f -not -path 'Contents/Resources/*.bundle/*' | LC_ALL=C sort)
  [ "$bad" = 0 ] || die "some Mach-O files lack the team, the hardened runtime or the timestamp"
}

# Notarises $1 (a .zip or .dmg) and waits; Apple's log goes to $2. Dies unless Apple accepts it.
notarise() {
  local file="$1" log="$2" json id status
  json="$(xcrun notarytool submit "$file" --keychain-profile "$notary_profile" --wait --output-format json)" || true
  id="$(jq -r '.id // empty' <<< "$json")"
  status="$(jq -r '.status // empty' <<< "$json")"
  if [ -n "$id" ]; then
    xcrun notarytool log "$id" --keychain-profile "$notary_profile" "$log" || true
  fi
  echo "notarisation of $(basename "$file"): ${status:-no answer} ${id:+(id $id)}"
  [ "$status" = Accepted ] || die "Apple did not accept $(basename "$file"): ${status:-no answer} (log: $log)"
}

# Before the long build: the team, its Developer ID certificate in the keychain, the notary profile.
mac_release_ready() {
  say "mac-release: signing set-up"
  local team id
  team="$(team_id)"
  id="$(devid_identity "$team")"
  [ -n "$id" ] || die "no \"Developer ID Application: ... ($team)\" identity in the keychain (security find-identity -v -p codesigning)"
  xcrun notarytool history --keychain-profile "$notary_profile" >/dev/null 2>&1 \
    || die "no working notarytool profile \"$notary_profile\" (xcrun notarytool store-credentials $notary_profile ...)"
  result PASS mac-release-ready "team $team, Developer ID $id, notary profile $notary_profile"
}

# The release .dmg for the download page: the app built by the macos step, signed with Developer
# ID, notarised and stapled, in a .dmg that is signed, notarised and stapled too; Gatekeeper's
# verdict on both; then the .sha256 and the REPORT the owner checks before publishing.
mac_release_sign() {
  say "mac-release: sign, notarise, staple, dmg"
  local team id dir v name stage app_dir dmg_file
  team="$(team_id)"
  id="$(devid_identity "$team")"
  [ -n "$id" ] || die "no Developer ID Application identity for team $team"
  [ -d "$out/$desktop_name.app" ] || die "no $out/$desktop_name.app: run the macos step"
  v="$(app_version)$(variant)"
  name="bt-wallet-$v-macos"
  dir="$out/mac-release"
  stage="$dir/stage"
  rm -rf "$stage"
  rm -f "$dir/$name.dmg" "$dir/$name.dmg.sha256" "$dir/$name.REPORT.txt"
  mkdir -p "$stage"
  app_dir="$stage/$desktop_name.app"
  ditto "$out/$desktop_name.app" "$app_dir"
  devid_sign "$app_dir" "$id"
  devid_check "$app_dir" "$team"
  ditto -c -k --keepParent "$app_dir" "$dir/$name-app.zip"
  notarise "$dir/$name-app.zip" "$dir/$name-app.notary-log.json"
  rm -f "$dir/$name-app.zip"
  xcrun stapler staple "$app_dir"
  ln -s /Applications "$stage/Applications"
  dmg_file="$dir/$name.dmg"
  hdiutil create -quiet -volname "$desktop_name" -srcfolder "$stage" -ov -format UDZO "$dmg_file"
  rm -rf "$stage"
  codesign --force --timestamp --sign "$id" "$dmg_file"
  notarise "$dmg_file" "$dir/$name.notary-log.json"
  xcrun stapler staple "$dmg_file"
  (cd "$dir" && shasum -a 256 "$name.dmg" > "$name.dmg.sha256")
  gatekeeper "$dmg_file"
  mac_report "$dmg_file" "$team" > "$dir/$name.REPORT.txt"
  cat "$dir/$name.REPORT.txt"
  result PASS mac-release "$dmg_file (+ .sha256, .REPORT.txt: send all three to the owner)"
}

# What the owner checks before publishing the .dmg: the commit, the hash, the team and
# Gatekeeper's verdict, Apple's notarisation answers.
mac_report() {
  local dmg_file="$1" team="$2" mnt
  echo "BT Wallet release .dmg: what was built and how it is signed"
  echo "file:             $(basename "$dmg_file")"
  echo "sha256:           $(sha256 "$dmg_file")"
  echo "app version:      $(sed -n 's/^version: *//p' "$app/pubspec.yaml")"
  if [ "${WFE_TOR:-1}" = 0 ]; then echo "variant:          without Tor (WFE_TOR=0)"; else echo "variant:          with Tor"; fi
  echo "commit:           $(git -C "$root" rev-parse HEAD)"
  echo "built at:         $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "lepic:            $(git -C "$lepic" rev-parse HEAD)"
  echo "lepic-flutter:    $(git -C "$binding" rev-parse HEAD)"
  echo "macOS:            $(sw_vers -productVersion) ($(sw_vers -buildVersion)) $(uname -m)"
  echo "Xcode:            $(xcodebuild -version | tr '\n' ' ')"
  echo "Flutter:          $(flutter --version 2>/dev/null | head -1)"
  echo "team expected:    $team"
  echo
  echo "== the .dmg"
  codesign -dv --verbose=2 "$dmg_file" 2>&1 | grep -E '^(Authority|TeamIdentifier|Timestamp)=' || true
  mnt="$(mktemp -d "${TMPDIR:-/tmp}/epic-dmg.XXXXXX")"
  hdiutil attach -quiet -nobrowse -readonly -mountpoint "$mnt" "$dmg_file"
  echo
  echo "== the app in it"
  codesign -dv --verbose=4 "$mnt/$desktop_name.app" 2>&1 \
    | grep -E '^(Identifier|Format|Authority|TeamIdentifier|Timestamp|Runtime Version|CodeDirectory)' || true
  hdiutil detach -quiet "$mnt" || true
  rmdir "$mnt" 2>/dev/null || true
  echo
  echo "== Gatekeeper (build-apple.sh gatekeeper)"
  cat "$out/gatekeeper.log"
}

# The iOS build for Xcode's Archive: LEPIC for iOS and Flutter's generated settings for the App
# Store build (without Tor, WFE_DIST=appstore, this commit's build id). Then Xcode: Product >
# Archive > Distribute App > App Store Connect, which signs with the team and uploads to
# TestFlight.
ios_prepare() {
  say "ios-prepare"
  local team
  team="$(team_id)"
  (cd "$app" && flutter pub get && flutter build ios --release --config-only -t lib/main.dart \
    --dart-define=WFE_BUILD_ID="$(build_id)" ${tor_def:+"$tor_def"} ${dist_def:+"$dist_def"})
  result PASS ios-prepare "team $team; now open app/ios/Runner.xcworkspace in Xcode, scheme Runner, Product > Archive"
}

# `all`: both variants, each in a run of this script of its own, so nothing of the first variant
# (WFE_TOR, the dart-define, the out dir, the node it fetched) reaches the second. Both runs
# happen whatever the first did; the exit is non-zero if either failed.
all_variants() {
  local parent="${APPLE_OUT:-$root/build-apple}" rc_tor=0 rc_notor=0
  say "all: with Tor ($parent/tor)"
  rm -f "$parent/tor/results.txt"
  env -u WFE_TOR APPLE_OUT="$parent/tor" "$root/tools/build-apple.sh" doctor sources lepic macos dmg smoke live || rc_tor=$?
  say "all: without Tor ($parent/notor)"
  rm -f "$parent/notor/results.txt"
  env WFE_TOR=0 APPLE_OUT="$parent/notor" "$root/tools/build-apple.sh" doctor sources lepic macos dmg ios-sim smoke live || rc_notor=$?
  say "all: summary"
  local v
  for v in tor notor; do
    echo "-- $v ($parent/$v/results.txt)"
    cat "$parent/$v/results.txt" 2>/dev/null || echo "(no results.txt)"
  done
  echo "with Tor: exit $rc_tor; without Tor: exit $rc_notor"
  [ "$rc_tor" = 0 ] && [ "$rc_notor" = 0 ]
}
if [ $# -ge 1 ] && [ "$1" = all ]; then
  [ $# -eq 1 ] || die "all runs alone: tools/build-apple.sh all"
  all_variants && exit 0 || exit 1
fi

# A step that dies (or fails a command) gets its FAIL line here unless it wrote one itself.
recorded="" step=""
trap 'rc=$?; if [ "$rc" != 0 ] && [ -n "$step" ] && [ "$recorded" != "$step" ]; then result FAIL "$step" "exit $rc"; fi' EXIT

if [ $# -eq 0 ]; then
  set -- doctor sources lepic macos dmg
  if ios_built; then set -- "$@" ios-sim; fi
fi
while [ $# -gt 0 ]; do
  step="$1"
  shift
  recorded=""
  case "$step" in
    doctor) doctor ;;
    sources) sources ;;
    lepic) lepic_libs ;;
    macos) macos ;;
    dmg) dmg ;;
    ios-sim) ios_only_without_tor ios-sim; ios_sim ;;
    ipa) ios_only_without_tor ipa; ipa ;;
    smoke) smoke ;;
    live) live ;;
    all) die "all runs alone: tools/build-apple.sh all" ;;
    release-check) release_check ;;
    mac-release) release_check; mac_release_ready; doctor; sources; lepic_libs "$darwin_targets"; macos; mac_release_sign ;;
    ios-prepare)
      [ "${WFE_TOR:-1}" = 0 ] && [ "$dist" = appstore ] \
        || die "the App Store build is the one without Tor and updater: WFE_TOR=0 WFE_DIST=appstore tools/build-apple.sh ios-prepare"
      release_check; doctor; sources; lepic_libs "$ios_targets"; ios_prepare ;;
    release) release_check; doctor; sources; lepic_libs; macos; if ios_built; then ipa; fi; handoff ;;
    handoff) handoff ;;
    dmg-signed) [ $# -gt 0 ] || die "dmg-signed needs the signed .app tar.gz"; dmg_signed "$1"; shift ;;
    gatekeeper) [ $# -gt 0 ] || die "gatekeeper needs the final .dmg"; gatekeeper "$1"; shift ;;
    *) step=""; sed -n '2,98p' "$0" >&2; exit 2 ;;
  esac
done
echo "results: $results"
