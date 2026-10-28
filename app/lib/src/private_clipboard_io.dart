// SPDX-License-Identifier: Apache-2.0
/// A recovery phrase on the Windows clipboard, kept out of the clipboard history (Win+V), the
/// cloud clipboard and clipboard monitors: the text goes up with the formats Windows reads for
/// that (`ExcludeClipboardContentFromMonitorProcessing`, `CanIncludeInClipboardHistory` = 0,
/// `CanUploadToCloudClipboard` = 0). Elsewhere [copyPrivateText] does nothing.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Whether this runs on an Android device (not a widget test, whose target platform says Android).
bool get onAndroidDevice => Platform.isAndroid;

/// Copies [text] as described above; false when that was not possible, so the caller copies
/// plainly.
bool copyPrivateText(String text) {
  if (!Platform.isWindows) return false;
  try {
    return _copy(text);
  } on Object {
    return false;
  }
}

bool _copy(String text) => using((alloc) {
  if (!OpenClipboard(null).value) return false;
  try {
    if (!EmptyClipboard().value) return false;
    final units = text.codeUnits;
    final unicode = _global((units.length + 1) * 2, (to) {
      final chars = to.cast<Uint16>().asTypedList(units.length + 1);
      chars.setAll(0, units);
      chars[units.length] = 0;
    });
    if (unicode == null) return false;
    if (SetClipboardData(CF_UNICODETEXT, HANDLE(unicode)).value.address == NULL) {
      GlobalFree(unicode);
      return false;
    }
    // Windows reads these formats by name; a DWORD 0 says "no" for the two Can… ones, and the
    // first only has to be there.
    for (final (name, value) in const [
      ('ExcludeClipboardContentFromMonitorProcessing', 0),
      ('CanIncludeInClipboardHistory', 0),
      ('CanUploadToCloudClipboard', 0),
    ]) {
      final format = RegisterClipboardFormat(alloc.pcwstr(name)).value;
      if (format == 0) continue;
      final data = _global(4, (to) => to.cast<Uint32>().value = value);
      if (data == null) continue;
      if (SetClipboardData(format, HANDLE(data)).value.address == NULL) GlobalFree(data);
    }
    return true;
  } finally {
    CloseClipboard();
  }
});

/// Movable global memory of [bytes] filled by [fill], which the clipboard owns once set.
HGLOBAL? _global(int bytes, void Function(Pointer<Void> to) fill) {
  final mem = GlobalAlloc(GMEM_MOVEABLE, bytes).value;
  if (mem.address == NULL) return null;
  final to = GlobalLock(mem).value;
  if (to.address == NULL) {
    GlobalFree(mem);
    return null;
  }
  fill(to.cast());
  GlobalUnlock(mem);
  return mem;
}
