// SPDX-License-Identifier: Apache-2.0
/// A recovery phrase, or other secret text, on the clipboard, phone and desktop: copied on
/// request, cleared after [phraseClipboardLifetime] ([secretClipboardLifetime]) and when the
/// wallet locks. On Android the clear also survives the app being killed: Android stores when
/// it was copied and clears it when the app next comes to the front (MainActivity.kt). Clearing removes only the current clip,
/// so the copy is marked private where the system allows it: sensitive on Android 13+ (no
/// preview, left out of keyboards' clipboard history), out of the clipboard history and the
/// cloud clipboard on Windows. Desktop clipboard managers on Linux and macOS may still keep it.
library;

import 'dart:async';

import 'package:flutter/services.dart';

import 'secure_screen.dart' show clearSensitiveText, copySensitiveText;
import 'private_clipboard_io.dart' if (dart.library.js_interop) 'private_clipboard_web.dart';

/// How long a copied recovery phrase stays on the clipboard (the help says 60 seconds).
const Duration phraseClipboardLifetime = Duration(seconds: 60);

/// How long other secret text stays: payment files and pairing words and links, which are
/// pasted into a chat.
const Duration secretClipboardLifetime = Duration(minutes: 2);

Timer? _timer;
String? _copied;

/// Whether Android holds the copy's clear (copied through MainActivity).
bool _nativeClear = false;

/// Copies [phrase]; false when the clipboard refused it. One timer for the app, outliving the
/// screen that copied.
Future<bool> copyPhraseToClipboard(String phrase) =>
    copySecretToClipboard(phrase, lifetime: phraseClipboardLifetime);

/// Copies secret [text] as [copyPhraseToClipboard] does, cleared after [lifetime]; false when
/// the clipboard refused it.
Future<bool> copySecretToClipboard(
  String text, {
  Duration lifetime = secretClipboardLifetime,
}) async {
  var native = false;
  try {
    native = onAndroidDevice && await copySensitiveText(text, clearAfter: lifetime);
    if (!native && !copyPrivateText(text)) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  } on Object {
    return false;
  }
  _timer?.cancel();
  _copied = text;
  _nativeClear = native;
  _timer = Timer(lifetime, () => unawaited(clearCopiedPhrase()));
  return true;
}

/// Clears the clipboard if it still holds the copied phrase. Android 10+ gives an app in the
/// background nothing on a read: an unreadable clipboard is cleared too, as the phrase may still
/// be on it. Nothing happens when no phrase was copied.
Future<void> clearCopiedPhrase() async {
  final phrase = _copied;
  _timer?.cancel();
  _timer = null;
  _copied = null;
  if (phrase == null) return;
  // Android knows which clip it put there (its time), without reading the text.
  if (_nativeClear) return clearSensitiveText();
  try {
    final now = await Clipboard.getData(Clipboard.kTextPlain);
    if (now?.text == null || now!.text == phrase) {
      await Clipboard.setData(const ClipboardData(text: ''));
    }
  } on Object {
    // Nothing more to do.
  }
}
