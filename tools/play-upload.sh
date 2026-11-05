#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Uploads the Play App Bundle of the version in pubspec.yaml to a Google Play testing track
# (https://docs.btlabs.uk/developers/build/variants/, "Google Play"). Production stays a click in Play Console.
#   tools/play-upload.sh <aab> [--track internal] [--notes-file <file>] [--validate]
#   tools/play-upload.sh --promote <track> [--notes-file <file>] [--validate]
#       puts this version's bundle, uploaded before (e.g. to internal), on <track> (e.g. beta)
# The release name is "<version> (<versionCode>)" from tools/version.sh; the notes default to
# play-notes/<version>.txt under docs (en-GB) when it exists. The service account key is
# WFE_PLAY_KEY (default ~/.config/btlabs/play/service-account.json, never in a repository).
# Play App Signing holds the release key and takes bundles signed with the upload key only, so a
# copy of the bundle is re-signed with WFE_PLAY_UPLOAD_KEY (default
# ~/.config/btlabs/android/play-upload.p12, alias upload, password in play-upload.pass beside it)
# and checked against play-upload-certificate.pem before it goes up. The bundle given stays as is.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
aab="${1:?usage: tools/play-upload.sh <aab> [--track T] [--notes-file F] [--validate] | --promote <track> [...]}"; shift
key="${WFE_PLAY_KEY:-$HOME/.config/btlabs/play/service-account.json}"
[[ -r "$key" ]] || { echo "no Play service account key at $key" >&2; exit 1; }
version="$("$root/tools/version.sh" name)"
code="$("$root/tools/version.sh" code)"
args=()
if [[ "$aab" == --promote ]]; then
  track="${1:?--promote <track>}"; shift
  args+=(--promote-code "$code" --track "$track")
else
  [[ -f "$aab" && "$aab" == *.aab ]] || { echo "$aab: not an App Bundle" >&2; exit 1; }
  p12="${WFE_PLAY_UPLOAD_KEY:-$HOME/.config/btlabs/android/play-upload.p12}"
  pass="${p12%.p12}.pass"; cert="${p12%.p12}-certificate.pem"
  for f in "$p12" "$pass" "$cert"; do [[ -r "$f" ]] || { echo "no Play upload key file $f" >&2; exit 1; }; done
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  signed="$tmp/$(basename "${aab%.aab}")-upload.aab"
  cp "$aab" "$signed"
  # The release key's signature goes first; the bundle's own base/root/META-INF stays.
  zip -q -d "$signed" 'META-INF/MANIFEST.MF' 'META-INF/*.SF' 'META-INF/*.RSA' 'META-INF/*.EC' \
    'META-INF/*.DSA' >/dev/null 2>&1 || true
  jarsigner -J-Duser.language=en -keystore "$p12" -storetype PKCS12 -storepass:file "$pass" \
    -sigalg SHA384withRSA -digestalg SHA-256 "$signed" upload >/dev/null
  want="$(openssl x509 -in "$cert" -noout -fingerprint -sha1 | cut -d= -f2)"
  got="$(keytool -J-Duser.language=en -printcert -jarfile "$signed" | awk '/SHA1:/ {print $2; exit}')"
  [[ -n "$want" && "$got" == "$want" ]] || { echo "upload copy signed by $got, not the upload key $want" >&2; exit 1; }
  echo "uploading $(basename "$signed"), signed with the upload key ($want), sha256 $(sha256sum "$signed" | cut -d' ' -f1)"
  args+=(--aab "$signed")
fi
notes="$root/docs/play-notes/$version.txt"
[[ " $* " == *" --notes-file "* || ! -f "$notes" ]] || args+=(--notes-file "$notes")
python3 -I "$root/tools/play_upload.py" --key "$key" --package uk.btlabs.btwallet \
  --name "$version ($code)" "${args[@]}" "$@"
