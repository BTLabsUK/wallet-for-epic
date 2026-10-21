#!/usr/bin/env bash
# Runs inside the build container (see scripts/build-linux.sh). /work is the repo.
set -euo pipefail
target="${WFE_TARGET:-lib/main_desktop.dart}"
version="$(sed -n 's/^version: *\([0-9.]*\).*/\1/p' /work/app/pubspec.yaml)"

if [[ "${WFE_BUILD_LEPIC:-1}" = 1 ]]; then
  echo "== LEPIC release (rust $RUSTUP_TOOLCHAIN)"
  (cd /work/app/third_party/lepic && cargo xtask mobile --package --target x86_64-unknown-linux-gnu)
fi

echo "== flutter build linux --release -t $target"
cd /work/app
flutter pub get
flutter build linux --release -t "$target" "$@"

echo "== AppImage"
bundle=/work/app/build/linux/x64/release/bundle
appdir="$(mktemp -d)/WalletForEpic.AppDir"
mkdir -p "$appdir/usr/bin"
cp -a "$bundle/." "$appdir/usr/bin/"
cat > "$appdir/AppRun" <<'RUN'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/epic_wallet" "$@"
RUN
chmod +x "$appdir/AppRun"
cat > "$appdir/epic-wallet.desktop" <<'DESK'
[Desktop Entry]
Type=Application
Name=Wallet for Epic
Exec=epic_wallet
Icon=epic-wallet
Categories=Finance;Utility;
Terminal=false
DESK
icon=/work/app/web/icons/Icon-512.png
if [[ -f "$icon" ]]; then cp "$icon" "$appdir/epic-wallet.png"; else
  # 1x1 placeholder so appimagetool is satisfied when the repo has no icon
  base64 -d > "$appdir/epic-wallet.png" <<'PNG'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==
PNG
fi
out=/work/build-linux
mkdir -p "$out"
ARCH=x86_64 /opt/appimagetool/AppRun --runtime-file /opt/runtime-x86_64 "$appdir" "$out/WalletForEpic-$version-x86_64.AppImage"
ls -l "$out"
