#!/usr/bin/env bash
# Runs inside the build container (see scripts/build-linux.sh). /work is the repo.
set -euo pipefail
target="${WFE_TARGET:-lib/main_desktop.dart}"
# pubspec.yaml's YY.MM.patch, with a test build's -rcN; never the +build (https://docs.btlabs.uk/developers/releases/).
version="$(sed -n 's/^version: *\([0-9.]*\(-rc[0-9]*\)\{0,1\}\).*/\1/p' /work/app/pubspec.yaml)"

if [[ "${WFE_BUILD_LEPIC:-1}" = 1 ]]; then
  echo "== LEPIC release (rust $RUSTUP_TOOLCHAIN)"
  (cd /work/app/third_party/lepic && cargo xtask mobile --package --target x86_64-unknown-linux-gnu \
    --out /work/app/third_party/lepic-flutter/native)
fi

echo "== flutter build linux --release -t $target"
cd /work/app
flutter pub get
flutter build linux --release -t "$target" ${WFE_BUILD_ID:+--dart-define=WFE_BUILD_ID="$WFE_BUILD_ID"} "$@"

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
exec "$HERE/usr/bin/epic_wallet" "$@"
RUN
chmod +x "$appdir/AppRun"
cat > "$appdir/uk.btlabs.epiccash.desktop.desktop" <<'DESK'
[Desktop Entry]
Type=Application
Name=Epic Cash Desktop
Exec=epic_wallet
Icon=epic-cash-desktop
StartupWMClass=uk.btlabs.epiccash.desktop
Categories=Finance;Utility;
Terminal=false
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
ARCH=x86_64 /opt/appimagetool/AppRun --runtime-file /opt/runtime-x86_64 "$appdir" "$out/EpicCashDesktop-$version-x86_64.AppImage"
ls -l "$out"
