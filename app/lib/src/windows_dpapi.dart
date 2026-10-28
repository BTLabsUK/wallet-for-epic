// SPDX-License-Identifier: Apache-2.0
/// The Windows halves of `windows_secret_store.dart`: DPAPI exactly as
/// flutter_secure_storage_windows 4.2.2 calls it, and an atomic write-through replace.
/// Imported only off the web; the functions resolve on first call, so this loads on any OS.
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'windows_secret_store.dart';

/// CryptProtectData / CryptUnprotectData for the current user, with [_uiForbidden] (DPAPI never
/// shows a prompt) and [_entropy], an app-specific value, so a process of the same user that
/// finds the store file cannot unprotect it with a plain DPAPI call. It can still if it reads
/// the value out of the app; same-user processes stay in scope, as for any user-scope DPAPI.
/// A file written before the entropy (and by the plugin's `DpapiJsonFileMapStorage`) still
/// reads: unprotect tries without the entropy when it fails with it, and the next write
/// protects the file with it. A build older than this one cannot read a file written since.
class DpapiCipher implements SecretCipher {
  const DpapiCipher();

  @override
  Uint8List protect(Uint8List plain) => _call(plain, protect: true, entropy: true);

  @override
  Uint8List unprotect(Uint8List encrypted) {
    try {
      return _call(encrypted, protect: false, entropy: true);
    } on WindowsException {
      return _call(encrypted, protect: false, entropy: false);
    }
  }

  Uint8List _call(Uint8List input, {required bool protect, required bool entropy}) => using((alloc) {
    final pIn = alloc<Uint8>(input.isEmpty ? 1 : input.length);
    pIn.asTypedList(input.length).setAll(0, input);
    final blobIn = alloc<CRYPT_INTEGER_BLOB>();
    blobIn.ref
      ..cbData = input.length
      ..pbData = pIn;
    final blobOut = alloc<CRYPT_INTEGER_BLOB>();
    Pointer<CRYPT_INTEGER_BLOB>? extra;
    if (entropy) {
      final pEntropy = alloc<Uint8>(_entropy.length);
      pEntropy.asTypedList(_entropy.length).setAll(0, _entropy);
      extra = alloc<CRYPT_INTEGER_BLOB>();
      extra.ref
        ..cbData = _entropy.length
        ..pbData = pEntropy;
    }
    final Win32Result(value: ok, :error) = protect
        ? CryptProtectData(blobIn, null, extra, null, _uiForbidden, blobOut)
        : CryptUnprotectData(blobIn, null, extra, null, _uiForbidden, blobOut);
    if (!ok) {
      throw WindowsException(
        error.toHRESULT(),
        message: protect
            ? 'CryptProtectData failed'
            : 'CryptUnprotectData failed',
      );
    }
    final out = blobOut.ref.pbData;
    if (out.address == NULL) {
      throw WindowsException(
        ERROR_OUTOFMEMORY.toHRESULT(),
        message: 'DPAPI returned no data',
      );
    }
    try {
      return Uint8List.fromList(out.asTypedList(blobOut.ref.cbData));
    } finally {
      LocalFree(HLOCAL(out.cast()));
    }
  });
}

/// CRYPTPROTECT_UI_FORBIDDEN: fail instead of prompting, which a background call cannot answer.
const int _uiForbidden = 0x1;

/// The optional entropy every protect passes: fixed, so every build of the app reads the file.
final Uint8List _entropy = Uint8List.fromList('epic-cash-desktop/secret-store/v1'.codeUnits);

/// [IoStoreFiles] with MoveFileEx(REPLACE_EXISTING | WRITE_THROUGH) for [replace]: atomic on
/// NTFS, and the rename is on the disk when it returns. A scanner or indexer holding the target
/// open makes the move fail for a moment, so it retries briefly before giving up.
class Win32StoreFiles extends IoStoreFiles {
  const Win32StoreFiles();

  @override
  Future<void> replace(String from, String to) async {
    for (var attempt = 1; ; attempt++) {
      final error = using((alloc) {
        final Win32Result(value: ok, :error) = MoveFileEx(
          alloc.pcwstr(from),
          alloc.pcwstr(to),
          MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH,
        );
        return ok ? null : error;
      });
      if (error == null) return;
      if (attempt >= 5 ||
          (error != ERROR_ACCESS_DENIED && error != ERROR_SHARING_VIOLATION)) {
        throw FileSystemException('MoveFileEx failed ($error)', from);
      }
      await Future<void>.delayed(Duration(milliseconds: 50 * attempt));
    }
  }
}
