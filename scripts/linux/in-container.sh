#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Runs inside the build container (see scripts/build-linux.sh). /work is the repo.
set -euo pipefail
target="${WFE_TARGET:-lib/main_desktop.dart}"
# pubspec.yaml's YY.MM.patch, with a test build's -rcN; never the +build (https://docs.btlabs.uk/developers/releases/).
version="$(sed -n 's/^version: *\([0-9.]*\(-rc[0-9]*\)\{0,1\}\).*/\1/p' /work/app/pubspec.yaml)"
# WFE_TOR=0: the build without Tor (lib/src/tor_build.dart), with LEPIC built without its tor
# feature (no lepic-tor in liblepic_ffi.so); its AppImage says so in its name.
notor=()
lepic_notor=()
variant=
if [[ "${WFE_TOR:-1}" = 0 ]]; then
  notor=(--dart-define=WFE_TOR=false)
  lepic_notor=(--no-tor)
  variant=-notor
fi

native=/work/app/third_party/lepic-flutter/native/x86_64-unknown-linux-gnu
if [[ "${WFE_BUILD_LEPIC:-1}" = 1 ]]; then
  echo "== LEPIC release (rust $RUSTUP_TOOLCHAIN)${lepic_notor[*]:+ without Tor}"
  (cd /work/app/third_party/lepic && cargo xtask mobile --package --target x86_64-unknown-linux-gnu \
    ${lepic_notor[@]+"${lepic_notor[@]}"} --out /work/app/third_party/lepic-flutter/native)
fi
# The library must match the switch, also when an earlier run built it (WFE_BUILD_LEPIC=0). LEPIC
# writes the lepic-ffi features next to it; a library from before that file has Tor.
if [[ -f "$native/liblepic_ffi.so" ]]; then
  lepic_tor=1
  [[ -f "$native/FEATURES" ]] && ! grep -qx tor "$native/FEATURES" && lepic_tor=0
  if [[ "$lepic_tor" != "$([[ ${#lepic_notor[@]} -eq 0 ]] && echo 1 || echo 0)" ]]; then
    echo "liblepic_ffi.so was built $([[ $lepic_tor = 1 ]] && echo with || echo without) Tor," \
      "but WFE_TOR=${WFE_TOR:-1}: build LEPIC again (WFE_BUILD_LEPIC=1)" >&2
    exit 1
  fi
fi

echo "== flutter build linux --release -t $target"
cd /work/app
flutter pub get
flutter build linux --release -t "$target" ${WFE_BUILD_ID:+--dart-define=WFE_BUILD_ID="$WFE_BUILD_ID"} \
  ${WFE_BUILD_TAG:+--dart-define=WFE_BUILD_TAG="$WFE_BUILD_TAG"} ${notor[@]+"${notor[@]}"} "$@"

echo "== AppImage"
bundle=/work/app/build/linux/x64/release/bundle
appdir="$(mktemp -d)/EpicWallet.AppDir"
mkdir -p "$appdir/usr/bin"
cp -a "$bundle/." "$appdir/usr/bin/"
# The built-in node (lib/src/builtin_node.dart) runs <exe dir>/bin/epic.
if [[ -s /work/node-bin/epic ]]; then
  mkdir -p "$appdir/usr/bin/bin"
  install -m 755 /work/node-bin/epic "$appdir/usr/bin/bin/epic"
fi
# Tor (lib/src/tor_location.dart) runs <exe dir>/bin/tor-bundle/tor; its licence goes with it.
if [[ -x /work/tor-bundle/tor ]]; then
  mkdir -p "$appdir/usr/bin/bin/tor-bundle"
  cp -a /work/tor-bundle/. "$appdir/usr/bin/bin/tor-bundle/"
  echo "tor bundle: $(cat /work/tor-bundle/VERSION)"
fi
cat > "$appdir/AppRun" <<'RUN'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/btwallet" "$@"
RUN
chmod +x "$appdir/AppRun"
# %u and the MimeType: a browser hands epiccash:// invite links to the app once a desktop
# integrator (appimaged, AppImageLauncher, Gear Lever) installed this file; the app reads the link
# from its arguments, and a second start passes it to the running window.
cat > "$appdir/uk.btlabs.epiccash.desktop.desktop" <<'DESK'
[Desktop Entry]
Type=Application
Name=Epic Cash Desktop
Exec=btwallet %u
Icon=epic-cash-desktop
StartupWMClass=uk.btlabs.epiccash.desktop
Categories=Finance;Utility;
Terminal=false
MimeType=x-scheme-handler/epiccash;
DESK
# The launcher icon (app/linux/icons, from the brand master): the hicolor set for desktops that
# integrate the AppImage, and the 512 px one at the root, where appimagetool looks for it.
hicolor=/work/app/linux/icons/hicolor
if [[ -d "$hicolor" ]]; then
  mkdir -p "$appdir/usr/share/icons"
  cp -a "$hicolor" "$appdir/usr/share/icons/"
  cp "$hicolor/512x512/apps/epic-cash-desktop.png" "$appdir/epic-cash-desktop.png"
  cp "$hicolor/512x512/apps/epic-cash-desktop.png" "$appdir/.DirIcon"
else
  # 1x1 placeholder so appimagetool is satisfied when the repo has no icon
  base64 -d > "$appdir/epic-cash-desktop.png" <<'PNG'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==
PNG
fi
out=/work/build-linux
mkdir -p "$out"
ARCH=x86_64 /opt/appimagetool/AppRun --runtime-file /opt/runtime-x86_64 "$appdir" "$out/bt-wallet-$version$variant-linux-x86_64.AppImage"
ls -l "$out"
