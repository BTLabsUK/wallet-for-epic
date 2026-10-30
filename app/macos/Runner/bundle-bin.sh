#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Xcode build phase "Bundle node and tor" of the macOS Runner target. tools/build-apple.sh stages
# the built-in node (bin/epic) and tor with libevent (bin/tor-bundle/) in app/build/apple-bin;
# this copies them to Contents/Resources/bin (lib/src/builtin_node_provider.dart,
# lib/src/tor_location.dart) and signs each one with the identity Xcode signs the app with, before
# Xcode signs the app itself. So `flutter build macos`, an Xcode Archive and the Developer ID
# re-sign of `build-apple.sh mac-release` all seal the same files. Nothing staged (a plain
# `flutter run`): the app has no built-in node or tor, as before.
set -eu
staged="$SRCROOT/../build/apple-bin"
if [ ! -d "$staged" ]; then
  echo "no $staged: no built-in node or tor in this build"
  exit 0
fi
dest="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/bin"
# A tor from an earlier build with Tor must not stay in a build without it.
rm -rf "$dest"
mkdir -p "$dest"
ditto "$staged" "$dest"
if [ "${CODE_SIGNING_ALLOWED:-YES}" != YES ]; then
  exit 0
fi
identity="${EXPANDED_CODE_SIGN_IDENTITY:-}"
if [ -z "$identity" ]; then identity=-; fi
sign() {
  if [ "$identity" = - ]; then
    codesign --force --sign - "$1"
  else
    # A real identity (Apple Development in an Archive): hardened runtime and Apple's timestamp,
    # as notarisation wants on every Mach-O file.
    codesign --force --sign "$identity" --options runtime --timestamp "$1"
  fi
}
# Inside out: libevent before the tor that loads it.
for f in "$dest"/tor-bundle/*.dylib "$dest/tor-bundle/tor" "$dest/epic"; do
  if [ -f "$f" ]; then sign "$f"; fi
done
