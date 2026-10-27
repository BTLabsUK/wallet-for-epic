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
#             a screenshot; the .app zipped
#   ipa       flutter build ios --release --no-codesign, zipped as an unsigned .ipa (a device
#             install needs it signed with a team first)
#   smoke     integration_test/simple_test.dart (PIN vault through LEPIC, secure storage, first
#             run) on macOS and on the Simulator, and a start of the built .app
#   live      integration_test/apple_live_test.dart on macOS and on the Simulator, on mainnet: a
#             new wallet on node.btlabs.uk (then node.epicnet.us, node.epiccash.com), its scan to
#             the tip, a restore from its phrase, the Epicbox listener connected (needs internet)
#   all       every step above but live
# A failing step leaves a FAIL line in results.txt before the script exits.
# Env:
#   APPLE_OUT=<dir>            results (default build-apple/ at the repo root): the .app, .dmg,
#                              screenshots, logs and results.txt with one PASS/FAIL line per step
#   LEPIC_REPO, LEPIC_FLUTTER_REPO   where `sources` clones from (a git URL or path)
#   WFE_NODE_BIN_MAC_ARM64, WFE_NODE_BIN_MAC_X64
#                              the built-in node's epic binary per architecture (the GUI 6.1.6's
#                              resources/bin/macsilicon/epic and mac/epic); joined with lipo into
#                              Contents/Resources/bin/epic. Without them the app has no built-in node.
#   WFE_NODE_FETCH=1           fetch both from the GUI 6.1.6 build commit pinned below (by SHA-256)
#                              when WFE_NODE_BIN_MAC_* are not set (CI does this)
#   CARGO_TARGET_DIR           LEPIC's cargo output (default app/third_party/lepic/target)
#   WFE_TOR=0                  the build without Tor (https://docs.btlabs.uk/developers/build/variants/): LEPIC without its
#                              tor feature, no tor in the .app, --dart-define=WFE_TOR=false
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
# The built-in node for WFE_NODE_FETCH: the GUI wallet 6.1.6's macOS binaries (epic 4.1.0), x86_64
# and arm64, at the commit that last changed them.
node_base=https://raw.githubusercontent.com/blacktyger/epic-gui-wallet/7b56cdbb2638bd3a877b2a35074fc54b278cdb92/resources/bin
node_sha_x64=9ee8a4704a65acc40ed75376fdf28d6ede4308d73cdd8cc06876361bb85b3400
node_sha_arm64=e3e7c83a5a4a3461bafcb5278be8d6f61d2e7fc3b378e77a920cb6dac458bf2c

die() { echo "build-apple.sh: $*" >&2; exit 1; }
say() { printf '\n== %s\n' "$*"; }
result() { mkdir -p "$out"; printf '%s %s %s\n' "$1" "$2" "${3:-}" | tee -a "$results"; recorded="$2"; }
sha256() { shasum -a 256 "$1" | cut -d' ' -f1; }
build_id() { git -C "$root" rev-parse --short=8 HEAD; }
# The dart-define of the build without Tor (WFE_TOR=0), else nothing.
tor_define() { if [ "${WFE_TOR:-1}" = 0 ]; then echo --dart-define=WFE_TOR=false; fi; }
# The file name mark of the build without Tor, as the other platforms' packages have it.
variant() { if [ "${WFE_TOR:-1}" = 0 ]; then echo -notor; fi; }
app_version() { sed -n 's/^version: *\([0-9.]*\(-rc[0-9]*\)\{0,1\}\).*/\1/p' "$app/pubspec.yaml"; }

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
  cp "${CARGO_TARGET_DIR:-$lepic/target}/$1/release/liblepic_ffi.dylib" "$dir/"
  (cd "$dir" && printf '%s  liblepic_ffi.dylib\n' "$(sha256 liblepic_ffi.dylib)" > SHA256SUMS)
  # LEPIC's xtask writes the features beside each library; `tor` unless built without it.
  if [ "${WFE_TOR:-1}" = 0 ]; then : > "$dir/FEATURES"; else echo tor > "$dir/FEATURES"; fi
  echo "packaged $dir/liblepic_ffi.dylib"
}

lepic_libs() {
  say "LEPIC for $darwin_targets $ios_targets"
  [ -f "$lepic/Cargo.toml" ] || die "no LEPIC clone: run the sources step"
  # rust-toolchain.toml picks LEPIC's Rust; its targets list has the iOS ones, not macOS.
  local t features=""
  [ "${WFE_TOR:-1}" = 0 ] && features=--no-default-features
  (cd "$lepic" && rustup target add $darwin_targets $ios_targets)
  # A plain cargo build per target: LEPIC's xtask packages iOS but has no macOS targets yet.
  for t in $darwin_targets $ios_targets; do
    (cd "$lepic" && MACOSX_DEPLOYMENT_TARGET=$macos_min IPHONEOS_DEPLOYMENT_TARGET=$ios_min \
      cargo build --package lepic-ffi --lib --locked --release --target "$t" $features)
    package_library "$t"
  done
  result PASS lepic "$(for t in $darwin_targets $ios_targets; do printf '%s ' "$t"; done)${features:+(without tor)}"
}

# Joins the per-architecture Mach-O files $2... into $1 (one input is copied as it is).
join_arches() {
  local dest="$1"; shift
  if [ $# -eq 1 ]; then cp "$1" "$dest"; else lipo -create "$@" -output "$dest"; fi
  chmod 755 "$dest"
}

# Downloads the GUI's node binary for $1 (mac or macsilicon) to $3 and checks it against $2.
fetch_node() {
  mkdir -p "$(dirname "$3")"
  curl -fsSL --retry 3 -o "$3" "$node_base/$1/epic"
  [ "$(sha256 "$3")" = "$2" ] || die "the $1 node binary does not match its pinned SHA-256"
  chmod 755 "$3"
}

macos() {
  say "flutter build macos"
  local bundle="$app/build/macos/Build/Products/Release/$desktop_name.app"
  local res="$bundle/Contents/Resources/bin"
  (cd "$app" && flutter pub get && flutter build macos --release -t lib/main_desktop.dart \
    --dart-define=WFE_BUILD_ID="$(build_id)" $(tor_define))
  [ -d "$bundle" ] || die "no $bundle"
  [ -f "$bundle/Contents/Frameworks/lepic_ffi.framework/lepic_ffi" ] \
    || die "the bundle has no lepic_ffi.framework (app/hook/build.dart)"
  # Flutter rebuilds the bundle in place and leaves Contents/Resources/bin alone: a tor from an
  # earlier build with Tor would stay in a build without it.
  rm -rf "$res"
  mkdir -p "$res"
  # The built-in node: Contents/Resources/bin/epic (lib/src/builtin_node_provider.dart).
  if [ "${WFE_NODE_FETCH:-0}" = 1 ] && [ -z "${WFE_NODE_BIN_MAC_ARM64:-}${WFE_NODE_BIN_MAC_X64:-}" ]; then
    fetch_node macsilicon "$node_sha_arm64" "$out/node/arm64/epic"
    fetch_node mac "$node_sha_x64" "$out/node/x86_64/epic"
    WFE_NODE_BIN_MAC_ARM64="$out/node/arm64/epic" WFE_NODE_BIN_MAC_X64="$out/node/x86_64/epic"
  fi
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
  version="$(app_version)"
  stage="$out/dmg-stage"
  rm -rf "$stage"
  mkdir -p "$stage"
  ditto "$bundle" "$stage/$desktop_name.app"
  ln -s /Applications "$stage/Applications"
  hdiutil create -quiet -volname "$desktop_name" -srcfolder "$stage" -ov -format UDZO \
    "$out/EpicCashDesktop-$version$(variant)-macos.dmg"
  rm -rf "$stage"
  result PASS dmg "EpicCashDesktop-$version$(variant)-macos.dmg $(du -h "$out/EpicCashDesktop-$version$(variant)-macos.dmg" | cut -f1)"
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
    --dart-define=WFE_BUILD_ID="$(build_id)" $(tor_define))
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
  ditto -c -k --keepParent "$bundle" "$out/EpicCashMobile-$(app_version)$(variant)-ios-simulator.zip"
  result PASS ios-sim "$udid, screenshot ios-sim.png"
}

# The device build without signing: Payload/Runner.app zipped as an .ipa. Not installable as it
# is; a team's certificate and profile have to sign it first.
ipa() {
  say "flutter build ios --no-codesign"
  (cd "$app" && flutter pub get && flutter build ios --release --no-codesign -t lib/main.dart \
    --dart-define=WFE_BUILD_ID="$(build_id)" $(tor_define))
  local bundle="$app/build/ios/iphoneos/Runner.app" stage="$out/ipa-stage"
  local ipa_file="$out/EpicCashMobile-$(app_version)$(variant)-ios-unsigned.ipa"
  [ -d "$bundle" ] || die "no $bundle"
  [ -f "$bundle/Frameworks/lepic_ffi.framework/lepic_ffi" ] || die "the .app has no lepic_ffi.framework"
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
  # Tor from the release .app: on its own, then started through LEPIC in the app's code.
  local tor="$bundle/Contents/Resources/bin/tor-bundle/tor"
  if [ -x "$tor" ]; then
    tor_check "$bundle" || status=1
    if (cd "$app" && flutter test integration_test/tor_apple_test.dart -d macos \
        --dart-define=WFE_TEST_TOR="$tor") > "$out/smoke-tor-app.log" 2>&1; then
      result PASS smoke-tor-app "$(grep -m1 'over tor: height' "$out/smoke-tor-app.log" | sed 's/.*TOR-CHECK //')"
    else
      result FAIL smoke-tor-app "see smoke-tor-app.log"; status=1
    fi
  else
    result FAIL smoke-tor "no tor in the .app"; status=1
  fi
  return "$status"
}

live() {
  say live
  mkdir -p "$out"
  local status=0 udid
  if (cd "$app" && flutter test integration_test/apple_live_test.dart -d macos $(tor_define)) \
      > "$out/live-macos.log" 2>&1; then
    result PASS live-macos "$(grep 'LIVE-CHECK' "$out/live-macos.log" | sed 's/.*LIVE-CHECK //' | tr '\n' ';')"
  else
    result FAIL live-macos "see live-macos.log"; status=1
  fi
  udid="$(simulator)"
  if [ -n "$udid" ] && (cd "$app" && flutter test integration_test/apple_live_test.dart -d "$udid" $(tor_define)) \
      > "$out/live-ios-sim.log" 2>&1; then
    result PASS live-ios-sim "$(grep 'LIVE-CHECK' "$out/live-ios-sim.log" | sed 's/.*LIVE-CHECK //' | tr '\n' ';')"
  else
    result FAIL live-ios-sim "see live-ios-sim.log"; status=1
  fi
  return "$status"
}

# A step that dies (or fails a command) gets its FAIL line here unless it wrote one itself.
recorded="" step=""
trap 'rc=$?; if [ "$rc" != 0 ] && [ -n "$step" ] && [ "$recorded" != "$step" ]; then result FAIL "$step" "exit $rc"; fi' EXIT

[ $# -gt 0 ] || set -- doctor sources lepic macos dmg ios-sim
for step in "$@"; do
  recorded=""
  case "$step" in
    doctor) doctor ;;
    sources) sources ;;
    lepic) lepic_libs ;;
    macos) macos ;;
    dmg) dmg ;;
    ios-sim) ios_sim ;;
    ipa) ipa ;;
    smoke) smoke ;;
    live) live ;;
    all) doctor; sources; lepic_libs; macos; dmg; ios_sim; ipa; smoke ;;
    *) step=""; sed -n '2,40p' "$0" >&2; exit 2 ;;
  esac
done
echo "results: $results"
