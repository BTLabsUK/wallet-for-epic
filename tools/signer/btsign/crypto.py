# SPDX-License-Identifier: Apache-2.0
"""The signer's own primitives: TOTP (RFC 6238), the portable bundle (scrypt + AES-256-GCM),
minisign signatures (the bytes tools/gitlab-release.py writes) and btlabs-public key ids.

Nothing here logs or returns key material in an error message."""
from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import struct
import time

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

TOTP_STEP = 30
TOTP_DIGITS = 6
TOTP_WINDOW = 1          # ±1 step
BUNDLE_FORMAT = "btsign-bundle-1"
SCRYPT_N, SCRYPT_R, SCRYPT_P = 2 ** 17, 8, 1


class CryptoError(Exception):
    """A user-facing error; never carries secret bytes."""


# ---------------------------------------------------------------- TOTP (RFC 6238 / 4226)

def new_totp_secret() -> str:
    """20 random bytes (SHA-1's block of RFC 4226), base32 without padding."""
    return base64.b32encode(os.urandom(20)).decode("ascii").rstrip("=")


def _b32(secret: str) -> bytes:
    s = secret.strip().replace(" ", "").upper()
    return base64.b32decode(s + "=" * (-len(s) % 8))


def hotp(secret: str, counter: int, digits: int = TOTP_DIGITS) -> str:
    mac = hmac.new(_b32(secret), struct.pack(">Q", counter), hashlib.sha1).digest()
    off = mac[-1] & 0x0F
    value = struct.unpack(">I", mac[off:off + 4])[0] & 0x7FFFFFFF
    return str(value % 10 ** digits).zfill(digits)


def totp_step(now: float | None = None) -> int:
    return int((time.time() if now is None else now) // TOTP_STEP)


def totp_now(secret: str, now: float | None = None) -> str:
    return hotp(secret, totp_step(now))


def totp_match(secret: str, code: str, now: float | None = None,
               window: int = TOTP_WINDOW) -> int | None:
    """The time step the code belongs to (within ±window of now), else None. Every candidate
    is compared, in constant time, so the timing does not say which step matched."""
    if not isinstance(code, str) or len(code) != TOTP_DIGITS or not code.isdigit():
        return None
    step, found = totp_step(now), None
    for s in range(step - window, step + window + 1):
        if hmac.compare_digest(hotp(secret, s), code) and found is None:
            found = s
    return found


def otpauth_uri(secret: str, account: str, issuer: str) -> str:
    from urllib.parse import quote
    return (f"otpauth://totp/{quote(issuer)}:{quote(account)}?secret={secret}"
            f"&issuer={quote(issuer)}&algorithm=SHA1&digits={TOTP_DIGITS}&period={TOTP_STEP}")


# ---------------------------------------------------------------- bundle

def new_bundle_key() -> str:
    """32 random bytes, base64url without padding (43 characters)."""
    return base64.urlsafe_b64encode(os.urandom(32)).decode("ascii").rstrip("=")


def _kdf(bundle_key: str, salt: bytes, n: int, r: int, p: int) -> bytes:
    if not bundle_key or len(bundle_key.strip()) < 16:
        raise CryptoError("the bundle key is missing or too short")
    return hashlib.scrypt(bundle_key.strip().encode("utf-8"), salt=salt, n=n, r=r, p=p,
                          maxmem=256 * 1024 * 1024, dklen=32)


def seal_bundle(content: dict, bundle_key: str) -> bytes:
    """The bundle file: a JSON header (format, KDF parameters, salt, nonce) bound to the
    AES-256-GCM ciphertext of `content` as associated data."""
    salt, nonce = os.urandom(16), os.urandom(12)
    header = {"format": BUNDLE_FORMAT, "kdf": "scrypt", "n": SCRYPT_N, "r": SCRYPT_R,
              "p": SCRYPT_P, "salt": base64.b64encode(salt).decode(),
              "aead": "AES-256-GCM", "nonce": base64.b64encode(nonce).decode()}
    aad = json.dumps(header, sort_keys=True, separators=(",", ":")).encode()
    key = _kdf(bundle_key, salt, SCRYPT_N, SCRYPT_R, SCRYPT_P)
    ct = AESGCM(key).encrypt(nonce, json.dumps(content, sort_keys=True).encode("utf-8"), aad)
    return (json.dumps(dict(header, ciphertext=base64.b64encode(ct).decode()), indent=1)
            + "\n").encode("ascii")


def open_bundle(data: bytes, bundle_key: str) -> dict:
    try:
        obj = json.loads(data.decode("ascii"))
        header = {k: obj[k] for k in ("format", "kdf", "n", "r", "p", "salt", "aead", "nonce")}
        ct = base64.b64decode(obj["ciphertext"], validate=True)
        salt = base64.b64decode(header["salt"], validate=True)
        nonce = base64.b64decode(header["nonce"], validate=True)
    except (ValueError, KeyError, TypeError, UnicodeDecodeError):
        raise CryptoError("not a btsign bundle") from None
    if header["format"] != BUNDLE_FORMAT or header["kdf"] != "scrypt" or header["aead"] != "AES-256-GCM":
        raise CryptoError("unsupported bundle format")
    if not all(type(header[k]) is int for k in ("n", "r", "p")) or header["n"] > 2 ** 20:
        raise CryptoError("bundle KDF parameters out of range")
    aad = json.dumps(header, sort_keys=True, separators=(",", ":")).encode()
    key = _kdf(bundle_key, salt, header["n"], header["r"], header["p"])
    try:
        plain = AESGCM(key).decrypt(nonce, ct, aad)
    except InvalidTag:
        raise CryptoError("wrong bundle key, or the bundle was changed") from None
    return json.loads(plain.decode("utf-8"))


# ---------------------------------------------------------------- Ed25519 / minisign

def load_ed25519_pem(pem: str) -> Ed25519PrivateKey:
    try:
        key = serialization.load_pem_private_key(pem.encode("ascii"), password=None)
    except Exception:  # never the exception text: it could echo key bytes
        raise CryptoError("the stored update key is not a valid PKCS#8 PEM key") from None
    if not isinstance(key, Ed25519PrivateKey):
        raise CryptoError("the stored update key is not Ed25519")
    return key


def raw_public(key: Ed25519PrivateKey) -> bytes:
    return key.public_key().public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)


def keyid_of(raw_pub: bytes) -> str:
    """btlabs-public's keyid: the first 16 hex characters of SHA-256 over the raw key."""
    return hashlib.sha256(raw_pub).hexdigest()[:16]


def minisign_sign(key: Ed25519PrivateKey, data: bytes, trusted: str) -> str:
    """minisign's ED format (Ed25519 over BLAKE2b-512 of the file), byte for byte what
    tools/gitlab-release.py minisign_sign writes for the same key, file and comment."""
    keyid = keyid_of(raw_public(key))
    sig = key.sign(hashlib.blake2b(data, digest_size=64).digest())
    glob = key.sign(sig + trusted.encode())
    return (
        f"untrusted comment: signature from BT Labs key {keyid}\n"
        f"{base64.b64encode(b'ED' + bytes.fromhex(keyid) + sig).decode()}\n"
        f"trusted comment: {trusted}\n"
        f"{base64.b64encode(glob).decode()}\n"
    )




def sha256_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()
