#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Uploads a Play App Bundle to a Google Play testing track (tools/play-upload.sh, https://docs.btlabs.uk/developers/build/variants/).

One edit: edits.insert, bundles.upload, tracks.update (one release, status completed), then
edits.commit; with --validate, edits.validate and the edit is deleted instead. Signs in as the
service account in the key file (OAuth JWT bearer, RS256), so it needs only the standard library
and `cryptography`. The key is read, never printed.
"""
import argparse
import base64
import json
import sys
import time
import urllib.error
import urllib.request

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding

API = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications'
UPLOAD = 'https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications'
SCOPE = 'https://www.googleapis.com/auth/androidpublisher'


def b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()


def token(key_file: str) -> str:
    sa = json.load(open(key_file))
    now = int(time.time())
    head = b64(json.dumps({'alg': 'RS256', 'typ': 'JWT'}).encode())
    claims = b64(json.dumps({'iss': sa['client_email'], 'scope': SCOPE, 'aud': sa['token_uri'],
                             'iat': now, 'exp': now + 3600}).encode())
    key = serialization.load_pem_private_key(sa['private_key'].encode(), password=None)
    sig = key.sign(f'{head}.{claims}'.encode(), padding.PKCS1v15(), hashes.SHA256())
    body = ('grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion='
            f'{head}.{claims}.{b64(sig)}').encode()
    req = urllib.request.Request(sa['token_uri'], body, {'Content-Type': 'application/x-www-form-urlencoded'})
    return json.load(urllib.request.urlopen(req, timeout=60))['access_token']


def call(tok, method, url, body=None, data=None, ctype='application/json', timeout=60):
    if body is not None:
        data = json.dumps(body).encode()
    req = urllib.request.Request(url, data, {'Authorization': f'Bearer {tok}', 'Content-Type': ctype},
                                 method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors='replace')
        try:
            detail = json.loads(detail)['error']['message']
        except Exception:
            pass
        sys.exit(f'play-upload: {method} {url.split("/applications/")[-1]}: HTTP {e.code}: {detail}')


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument('--key', required=True, help='service account JSON key')
    p.add_argument('--package', required=True)
    p.add_argument('--aab', required=True)
    p.add_argument('--track', default='internal')
    p.add_argument('--name', required=True, help='release name, e.g. "26.10.20 (26102000)"')
    p.add_argument('--notes-file', help='release notes, one language: the text of the file')
    p.add_argument('--lang', default='en-GB')
    p.add_argument('--validate', action='store_true', help='validate the edit, then delete it')
    a = p.parse_args()

    tok = token(a.key)
    base = f'{API}/{a.package}/edits'
    edit = call(tok, 'POST', base, {})['id']
    print(f'edit {edit}')
    with open(a.aab, 'rb') as f:
        up = call(tok, 'POST', f'{UPLOAD}/{a.package}/edits/{edit}/bundles?uploadType=media',
                  data=f.read(), ctype='application/octet-stream', timeout=900)
    code = up['versionCode']
    print(f'bundle uploaded: versionCode {code}, sha256 {up.get("sha256", "?")}')
    release = {'name': a.name, 'versionCodes': [str(code)], 'status': 'completed'}
    if a.notes_file:
        release['releaseNotes'] = [{'language': a.lang, 'text': open(a.notes_file).read().strip()}]
    call(tok, 'PUT', f'{base}/{edit}/tracks/{a.track}', {'track': a.track, 'releases': [release]})
    print(f'track {a.track}: release "{a.name}" ({code}), completed')
    if a.validate:
        call(tok, 'POST', f'{base}/{edit}:validate')
        call(tok, 'DELETE', f'{base}/{edit}')
        print('validated; edit deleted, nothing published')
        return
    call(tok, 'POST', f'{base}/{edit}:commit')
    print(f'committed: {a.track} track now has {a.name}')


if __name__ == '__main__':
    main()
