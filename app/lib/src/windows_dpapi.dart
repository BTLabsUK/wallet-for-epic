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

/// CryptProtectData / CryptUnprotectData for the current user: no description, no entropy, no
/// prompt, flags 0, as the plugin's `DpapiJsonFileMapStorage`, so its files read and ours read
/// in an older build.
class DpapiCipher implements SecretCipher {
  const DpapiCipher();

  @override
  Uint8List protect(Uint8List plain) => _call(plain, protect: true);

  @override
  Uint8List unprotect(Uint8List encrypted) => _call(encrypted, protect: false);

  Uint8List _call(Uint8List input, {required bool protect}) => using((alloc) {
    final pIn = alloc<Uint8>(input.isEmpty ? 1 : input.length);
    pIn.asTypedList(input.length).setAll(0, input);
    final blobIn = alloc<CRYPT_INTEGER_BLOB>();
    blobIn.ref
      ..cbData = input.length
      ..pbData = pIn;
    final blobOut = alloc<CRYPT_INTEGER_BLOB>();
    final Win32Result(value: ok, :error) = protect
        ? CryptProtectData(blobIn, null, null, null, 0, blobOut)
        : CryptUnprotectData(blobIn, null, null, null, 0, blobOut);
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
