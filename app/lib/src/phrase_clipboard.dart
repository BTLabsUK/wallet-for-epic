/// A recovery phrase on the clipboard, phone and desktop: copied on request, cleared after
/// [phraseClipboardLifetime] and when the wallet locks.
library;

import 'dart:async';

import 'package:flutter/services.dart';

/// How long a copied recovery phrase stays on the clipboard (the help says 60 seconds).
const Duration phraseClipboardLifetime = Duration(seconds: 60);

Timer? _timer;
String? _copied;

/// Copies [phrase]; false when the clipboard refused it. One timer for the app, outliving the
/// screen that copied.
Future<bool> copyPhraseToClipboard(String phrase) async {
  try {
    await Clipboard.setData(ClipboardData(text: phrase));
  } on Object {
    return false;
  }
  _timer?.cancel();
  _copied = phrase;
  _timer = Timer(phraseClipboardLifetime, () => unawaited(clearCopiedPhrase()));
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
  try {
    final now = await Clipboard.getData(Clipboard.kTextPlain);
    if (now?.text == null || now!.text == phrase) {
      await Clipboard.setData(const ClipboardData(text: ''));
    }
  } on Object {
    // Nothing more to do.
  }
}
