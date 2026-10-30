#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Makes the staging folder install.ps1 installs from, on a Linux machine with network access:
# the embeddable Python (checked with sigstore against its release manager's identity), the
# hash-pinned wheels of requirements-windows.txt, apksigner.jar from the Android build-tools (its
# SHA-256 is pinned into btsign.toml by install.ps1) and the signer's code without its tests.
# Usage: stage.sh <out dir> [<python version, default 3.14.2>]
#   then: scp -r <out dir> <windows host>:<dir> and, as an Administrator there,
#   powershell -ExecutionPolicy Bypass -File <dir>\app\windows\install.ps1 -Stage <dir> -Listen <tailnet ip> -BotUrl <url>
set -euo pipefail
out="${1:?usage: $0 <out dir> [python version]}"
pyver="${2:-3.14.2}"
here="$(cd "$(dirname "$0")" && pwd)"
signer="$(dirname "$here")"
sdk="${ANDROID_HOME:-$HOME/Android/Sdk}"
bt="$(ls -d "$sdk"/build-tools/* | sort -V | tail -1)"
mkdir -p "$out/wheels"
zip="python-$pyver-embed-amd64.zip"
curl -fsSL -o "$out/$zip" "https://www.python.org/ftp/python/$pyver/$zip"
curl -fsSL -o "$out/$zip.sigstore" "https://www.python.org/ftp/python/$pyver/$zip.sigstore"
# 3.14's release manager (https://www.python.org/downloads/metadata/sigstore/).
uvx -q sigstore verify identity --cert-identity hugo@python.org \
  --cert-oidc-issuer https://github.com/login/oauth --bundle "$out/$zip.sigstore" "$out/$zip"
python3 -m pip download -q --only-binary=:all: --no-deps --platform win_amd64 --python-version 3.14 \
  --implementation cp -d "$out/wheels" --require-hashes -r "$here/requirements-windows.txt"
cp "$here/requirements-windows.txt" "$out/"
cp "$bt/lib/apksigner.jar" "$out/apksigner.jar"
sha256sum "$out/apksigner.jar" | cut -d' ' -f1 >"$out/apksigner.jar.sha256"
mkdir -p "$out/app"
cp -r "$signer/btsign.py" "$signer/btsign" "$signer/vendor" "$signer/selftest" "$signer/windows" "$out/app/"
find "$out/app" -name __pycache__ -prune -exec rm -rf {} +
echo "staged in $out (apksigner.jar $(cat "$out/apksigner.jar.sha256"), build-tools $(basename "$bt"))"
