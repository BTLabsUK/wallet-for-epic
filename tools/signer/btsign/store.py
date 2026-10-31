# SPDX-License-Identifier: Apache-2.0
"""Where the signer keeps its secrets and its state.

secrets.bin holds one JSON object (the update key, the Android keystore and its passwords, the
bundle key, the TOTP secret, the bot and client tokens):
  * Windows: protected with DPAPI under the service account (btsigner), in a data folder whose
    ACL grants btsigner alone (tools/signer/windows/install.ps1 sets it);
  * Linux: a 0600 file in a 0700 folder owned by the signer user (systemd-creds can wrap it
    later; see docs/RELEASING.md "Signer").
state.json is not secret (used TOTP step, failure times, lock) but lives beside it, so only the
service account can change it."""
from __future__ import annotations

import ctypes
import json
import os
import sys
import tempfile
import threading

ENTROPY = b"btsign secrets v1"


class StoreError(Exception):
    pass


def atomic_write(path: str, data: bytes, mode: int = 0o600) -> None:
    d = os.path.dirname(path) or "."
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".tmp-", suffix=".part")
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        if os.name != "nt":
            os.chmod(tmp, mode)
        os.replace(tmp, path)
    except BaseException:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise


# ---------------------------------------------------------------- DPAPI (Windows)

class _Blob(ctypes.Structure):
    _fields_ = [("cbData", ctypes.c_uint32), ("pbData", ctypes.POINTER(ctypes.c_char))]


def _blob(data: bytes):
    buf = ctypes.create_string_buffer(data, len(data))
    return _Blob(len(data), ctypes.cast(buf, ctypes.POINTER(ctypes.c_char))), buf


def _dpapi(data: bytes, protect: bool) -> bytes:
    crypt32 = ctypes.WinDLL("crypt32", use_last_error=True)
    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel32.LocalFree.argtypes = [ctypes.c_void_p]
    inp, _keep1 = _blob(data)
    ent, _keep2 = _blob(ENTROPY)
    out = _Blob()
    flags = 0x1  # CRYPTPROTECT_UI_FORBIDDEN; user scope (not LOCAL_MACHINE)
    if protect:
        ok = crypt32.CryptProtectData(ctypes.byref(inp), "btsign", ctypes.byref(ent), None, None,
                                      flags, ctypes.byref(out))
    else:
        ok = crypt32.CryptUnprotectData(ctypes.byref(inp), None, ctypes.byref(ent), None, None,
                                        flags, ctypes.byref(out))
    if not ok:
        raise StoreError(f"DPAPI {'protect' if protect else 'unprotect'} failed "
                         f"(Windows error {ctypes.get_last_error()})")
    try:
        return ctypes.string_at(out.pbData, out.cbData)
    finally:
        kernel32.LocalFree(ctypes.cast(out.pbData, ctypes.c_void_p))


class Store:
    """secrets.bin and state.json in `data_dir`. One lock for both; every write is atomic."""

    def __init__(self, data_dir: str, backend: str | None = None):
        self.dir = data_dir
        self.backend = backend or ("dpapi" if os.name == "nt" else "file")
        self.secrets_path = os.path.join(data_dir, "secrets.bin")
        self.state_path = os.path.join(data_dir, "state.json")
        self.lock = threading.RLock()
        os.makedirs(data_dir, exist_ok=True)
        if self.backend == "file":
            st = os.stat(data_dir)
            if st.st_mode & 0o077:
                raise StoreError(f"{data_dir} is open to group/other (mode {st.st_mode & 0o777:o}); "
                                 "chmod 700 it")
            if hasattr(os, "getuid") and st.st_uid != os.getuid():
                raise StoreError(f"{data_dir} is not owned by the signer user")

    # secrets
    def _wrap(self, plain: bytes) -> bytes:
        return _dpapi(plain, True) if self.backend == "dpapi" else plain

    def _unwrap(self, data: bytes) -> bytes:
        return _dpapi(data, False) if self.backend == "dpapi" else data

    def has_secrets(self) -> bool:
        return os.path.isfile(self.secrets_path)

    def secrets(self) -> dict:
        with self.lock:
            if not self.has_secrets():
                return {}
            with open(self.secrets_path, "rb") as f:
                raw = f.read()
            try:
                return json.loads(self._unwrap(raw).decode("utf-8"))
            except (ValueError, UnicodeDecodeError):
                raise StoreError("secrets.bin cannot be read") from None

    def save_secrets(self, secrets: dict) -> None:
        with self.lock:
            atomic_write(self.secrets_path, self._wrap(json.dumps(secrets, sort_keys=True).encode()))

    def update_secrets(self, **kv) -> dict:
        with self.lock:
            s = self.secrets()
            s.update(kv)
            self.save_secrets(s)
            return s

    # state
    def state(self) -> dict:
        with self.lock:
            try:
                with open(self.state_path, "r", encoding="utf-8") as f:
                    return json.load(f)
            except FileNotFoundError:
                return {}

    def save_state(self, state: dict) -> None:
        with self.lock:
            atomic_write(self.state_path, (json.dumps(state, indent=1, sort_keys=True) + "\n").encode())


def platform_name() -> str:
    return "windows" if os.name == "nt" else sys.platform
