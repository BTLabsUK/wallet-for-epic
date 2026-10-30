#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Xcode build phase "lepic_ffi privacy manifest" of the iOS Runner target, after Flutter's
# "Thin Binary" has embedded the wallet library. Flutter makes lepic_ffi.framework without a
# privacy manifest, and App Store Connect wants the reasons for its file-timestamp and disk-space
# calls (app/ios/lepic_ffi.PrivacyInfo.xcprivacy). Adding a file breaks the framework's signature,
# so it is signed again with the identity Xcode uses (the export re-signs it for the App Store).
set -eu
fw="$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH/lepic_ffi.framework"
if [ ! -d "$fw" ]; then
  if [ "${CONFIGURATION:-}" = Release ]; then
    echo "error: no lepic_ffi.framework in the app (run tools/build-apple.sh ios-prepare first)"
    exit 1
  fi
  echo "warning: no lepic_ffi.framework in the app"
  exit 0
fi
cp "$SRCROOT/lepic_ffi.PrivacyInfo.xcprivacy" "$fw/PrivacyInfo.xcprivacy"
if [ "${CODE_SIGNING_ALLOWED:-NO}" = YES ] && [ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]; then
  codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --preserve-metadata=identifier,entitlements "$fw"
fi
