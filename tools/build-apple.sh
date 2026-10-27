#!/usr/bin/env bash
# Builds Epic Cash Desktop for macOS and Epic Cash Mobile for the iOS Simulator on a Mac, from a
# clean checkout of this repository: LEPIC for the four Apple targets, an ad-hoc-signed .app and
# .dmg, a Simulator .app, and the smoke run. No Apple account is needed for any of it. Prototype
# (branch proto/apple); notes and what is still open in docs/apple-port-notes.md.
#
# Usage: tools/build-apple.sh [step...]          default: doctor sources lepic macos dmg ios-sim
#   doctor    print and check the toolchain (Xcode, SDKs, Simulator runtime, Flutter, Rust)
#   sources   the LEPIC and lepic-flutter clones in app/third_party at tools/lepic.rev and
#             tools/lepic-flutter.rev (cloned from LEPIC_REPO / LEPIC_FLUTTER_REPO when missing)
#   lepic     liblepic_ffi.dylib for aarch64/x86_64-apple-darwin and aarch64-apple-ios(-sim)
#             into app/third_party/lepic-flutter/native/<target>/ beside a SHA256SUMS
#   macos     flutter build macos --release; the node and tor go into the bundle, then it is
#             signed ad hoc
#   dmg       the .app in a compressed .dmg with an Applications link
#   ios-sim   flutter build ios --simulator --debug; installed and started on a Simulator, with
#             a screenshot
#   smoke     integration_test/simple_test.dart (PIN vault through LEPIC, secure storage, first
#             run) on macOS and on the Simulator, and a start of the built .app
#   all       every step above
# Env:
#   APPLE_OUT=<dir>            results (default build-apple/ at the repo root): the .app, .dmg,
#                              screenshots, logs and results.txt with one PASS/FAIL line per step
#   LEPIC_REPO, LEPIC_FLUTTER_REPO   where `sources` clones from (a git URL or path)
#   WFE_NODE_BIN_MAC_ARM64, WFE_NODE_BIN_MAC_X64
#                              the built-in node's epic binary per architecture (the GUI 6.1.6's
#                              resources/bin/macsilicon/epic and mac/epic); joined with lipo into
#                              Contents/Resources/bin/epic. Without them the app has no built-in node.
#   WFE_TOR=0                  leave out tor (tools/fetch-tor.sh mac + macsilicon, in by default)
#   SIM_DEVICE=<name or udid>  the Simulator (default: the first available iPhone)
#
# Written for the bash 3.2 macOS ships: no mapfile, no ${x,,}, no associative arrays.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
app="$root/app"
lepic="$app/third_party/lepic"
binding="$app/third_party/lepic-flutter"
out="${APPLE_OUT:-$root/build-apple}"
results="$out/results.txt"
flutter_version=3.47.5
# Must match MACOSX_DEPLOYMENT_TARGET and IPHONEOS_DEPLOYMENT_TARGET in the Xcode projects, so
# the libraries never ask for a newer system than the app.
macos_min=12.0
ios_min=15.0
darwin_targets="aarch64-apple-darwin x86_64-apple-darwin"
ios_targets="aarch64-apple-ios aarch64-apple-ios-sim"
desktop_name="Epic Cash Desktop"
phone_id=uk.btlabs.epiccash.mobile

die() { echo "build-apple.sh: $*" >&2; exit 1; }
say() { printf '\n== %s\n' "$*"; }
result() { mkdir -p "$out"; printf '%s %s %s\n' "$1" "$2" "${3:-}" | tee -a "$results"; }
sha256() { shasum -a 256 "$1" | cut -d' ' -f1; }
build_id() { git -C "$root" rev-parse --short=8 HEAD; }

doctor() {
  say doctor
  [ "$(uname -s)" = Darwin ] || die "runs on macOS only (this is $(uname -s))"
  local ok=1
  sw_vers || ok=0
  echo "arch: $(uname -m)"
  xcode-select -p || { echo "no Xcode: install Xcode 26+ and run xcode-select -s" >&2; ok=0; }
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
  clone_at "$binding" "${LEPIC_FLUTTER_REPO:-}" "$binding_rev" LEPIC_FLUTTER_REPO
  [ "$(tr -d '[:space:]' < "$binding/lepic.rev")" = "$rev" ] \
    || die "tools/lepic.rev differs from lepic-flutter's own lepic.rev"
  clone_at "$lepic" "${LEPIC_REPO:-}" "$rev" LEPIC_REPO
  result PASS sources "lepic $(git -C "$lepic" rev-parse --short=8 HEAD)"
}

# Copies the release library of $1 into the binding's native/$1/ with its SHA256SUMS, the layout
# package:lepic's hook (iOS) and app/hook/build.dart (macOS) read.
package_library() {
  local dir="$binding/native/$1"
  mkdir -p "$dir"
  cp "$lepic/target/$1/release/liblepic_ffi.dylib" "$dir/"
  (cd "$dir" && printf '%s  liblepic_ffi.dylib\n' "$(sha256 liblepic_ffi.dylib)" > SHA256SUMS)
  echo "packaged $dir/liblepic_ffi.dylib"
}

lepic_libs() {
  say "LEPIC for $darwin_targets $ios_targets"
  [ -f "$lepic/Cargo.toml" ] || die "no LEPIC clone: run the sources step"
  # rust-toolchain.toml picks LEPIC's Rust; its targets list has the iOS ones, not macOS.
  local t
  (cd "$lepic" && rustup target add $darwin_targets $ios_targets)
  # A plain cargo build per target: LEPIC's xtask packages iOS but has no macOS targets yet.
  for t in $darwin_targets $ios_targets; do
    (cd "$lepic" && MACOSX_DEPLOYMENT_TARGET=$macos_min IPHONEOS_DEPLOYMENT_TARGET=$ios_min \
      cargo build --package lepic-ffi --lib --locked --release --target "$t")
    package_library "$t"
  done
  result PASS lepic "$(for t in $darwin_targets $ios_targets; do printf '%s ' "$t"; done)"
}

# Joins the per-architecture Mach-O files $2... into $1 (one input is copied as it is).
join_arches() {
  local dest="$1"; shift
  if [ $# -eq 1 ]; then cp "$1" "$dest"; else lipo -create "$@" -output "$dest"; fi
  chmod 755 "$dest"
}

macos() {
  say "flutter build macos"
  local bundle="$app/build/macos/Build/Products/Release/$desktop_name.app"
  local res="$bundle/Contents/Resources/bin"
  (cd "$app" && flutter pub get && flutter build macos --release -t lib/main_desktop.dart \
    --dart-define=WFE_BUILD_ID="$(build_id)")
  [ -d "$bundle" ] || die "no $bundle"
  [ -f "$bundle/Contents/Frameworks/lepic_ffi.framework/lepic_ffi" ] \
    || die "the bundle has no lepic_ffi.framework (app/hook/build.dart)"
  mkdir -p "$res"
  # The built-in node: Contents/Resources/bin/epic (lib/src/builtin_node_provider.dart).
  local nodes=""
  [ -n "${WFE_NODE_BIN_MAC_ARM64:-}" ] && nodes="$nodes $WFE_NODE_BIN_MAC_ARM64"
  [ -n "${WFE_NODE_BIN_MAC_X64:-}" ] && nodes="$nodes $WFE_NODE_BIN_MAC_X64"
  if [ -n "$nodes" ]; then
    join_arches "$res/epic" $nodes
    echo "node: $(lipo -archs "$res/epic")"
  else
    echo "no WFE_NODE_BIN_MAC_*: no built-in node"
  fi
  # Tor: Contents/Resources/bin/tor-bundle/tor beside its libevent (lib/src/tor_location.dart);
  # tor finds libevent at @executable_path.
  if [ "${WFE_TOR:-1}" = 1 ]; then
    local tmp="$out/tor"
    rm -rf "$tmp"
    "$root/tools/fetch-tor.sh" mac "$tmp/x86_64"
    "$root/tools/fetch-tor.sh" macsilicon "$tmp/arm64"
    mkdir -p "$res/tor-bundle"
    join_arches "$res/tor-bundle/tor" "$tmp/arm64/tor" "$tmp/x86_64/tor"
    join_arches "$res/tor-bundle/libevent-2.1.7.dylib" \
      "$tmp/arm64/libevent-2.1.7.dylib" "$tmp/x86_64/libevent-2.1.7.dylib"
    cp "$tmp/arm64/LICENSE.tor.txt" "$tmp/arm64/VERSION" "$res/tor-bundle/"
    rm -rf "$tmp"
    echo "tor: $(cat "$res/tor-bundle/VERSION"), $(lipo -archs "$res/tor-bundle/tor")"
  fi
  # Ad hoc, inside out: what was added after Xcode signed, then the app with its entitlements.
  # No hardened runtime: an ad-hoc framework would fail library validation under it.
  local f
  for f in "$res/epic" "$res/tor-bundle/libevent-2.1.7.dylib" "$res/tor-bundle/tor"; do
    if [ -f "$f" ]; then codesign --force --sign - "$f"; fi
  done
  codesign --force --sign - --entitlements "$app/macos/Runner/Release.entitlements" "$bundle"
  codesign --verify --deep --strict --verbose=2 "$bundle"
  mkdir -p "$out"
  rm -rf "$out/$desktop_name.app"
  ditto "$bundle" "$out/$desktop_name.app"
  result PASS macos "$(lipo -archs "$bundle/Contents/MacOS/$desktop_name") $(du -sh "$bundle" | cut -f1)"
}

dmg() {
  say dmg
  local bundle="$out/$desktop_name.app" version stage
  [ -d "$bundle" ] || die "no $bundle: run the macos step"
  version="$(sed -n 's/^version: *\([0-9.]*\(-rc[0-9]*\)\{0,1\}\).*/\1/p' "$app/pubspec.yaml")"
  stage="$out/dmg-stage"
  rm -rf "$stage"
  mkdir -p "$stage"
  ditto "$bundle" "$stage/$desktop_name.app"
  ln -s /Applications "$stage/Applications"
  hdiutil create -quiet -volname "$desktop_name" -srcfolder "$stage" -ov -format UDZO \
    "$out/EpicCashDesktop-$version-macos.dmg"
  rm -rf "$stage"
  result PASS dmg "EpicCashDesktop-$version-macos.dmg $(du -h "$out/EpicCashDesktop-$version-macos.dmg" | cut -f1)"
}

# The udid of SIM_DEVICE (a name or udid), else of the first available iPhone.
simulator() {
  local want="${SIM_DEVICE:-}"
  xcrun simctl list devices available -j | jq -r --arg want "$want" '
    [.devices | to_entries[] | select(.key | test("iOS")) | .value[]
     | select(if $want == "" then (.name | startswith("iPhone"))
              else (.name == $want or .udid == $want) end)] | first | .udid // empty'
}

ios_sim() {
  say "flutter build ios --simulator"
  [ "$(uname -m)" = arm64 ] || die "the Simulator build needs an Apple silicon Mac (LEPIC has no x86_64 Simulator library)"
  (cd "$app" && flutter pub get && flutter build ios --simulator --debug -t lib/main.dart \
    --dart-define=WFE_BUILD_ID="$(build_id)")
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
  result PASS ios-sim "$udid, screenshot ios-sim.png"
}

smoke() {
  say smoke
  mkdir -p "$out"
  local status=0 udid
  if (cd "$app" && flutter test integration_test/simple_test.dart -d macos) > "$out/smoke-macos.log" 2>&1; then
    result PASS smoke-macos simple_test
  else
    result FAIL smoke-macos "simple_test, see smoke-macos.log"; status=1
  fi
  udid="$(simulator)"
  if [ -n "$udid" ] && (cd "$app" && flutter test integration_test/simple_test.dart -d "$udid") \
      > "$out/smoke-ios-sim.log" 2>&1; then
    result PASS smoke-ios-sim simple_test
  else
    result FAIL smoke-ios-sim "simple_test, see smoke-ios-sim.log"; status=1
  fi
  # The release .app starts and stays up; a screenshot when the session allows it.
  local bundle="$out/$desktop_name.app"
  if [ -d "$bundle" ]; then
    open -n "$bundle"
    sleep 20
    if pgrep -f "$desktop_name.app/Contents/MacOS/" >/dev/null; then
      screencapture -x "$out/macos.png" 2>/dev/null || echo "no screenshot (Screen Recording permission)"
      osascript -e "quit app \"$desktop_name\"" 2>/dev/null || pkill -f "$desktop_name.app/Contents/MacOS/" || true
      result PASS smoke-macos-app "started and stayed up 20 s"
    else
      result FAIL smoke-macos-app "not running 20 s after open"; status=1
    fi
  fi
  return "$status"
}

[ $# -gt 0 ] || set -- doctor sources lepic macos dmg ios-sim
for step in "$@"; do
  case "$step" in
    doctor) doctor ;;
    sources) sources ;;
    lepic) lepic_libs ;;
    macos) macos ;;
    dmg) dmg ;;
    ios-sim) ios_sim ;;
    smoke) smoke ;;
    all) doctor; sources; lepic_libs; macos; dmg; ios_sim; smoke ;;
    *) sed -n '2,32p' "$0" >&2; exit 2 ;;
  esac
done
echo "results: $results"
