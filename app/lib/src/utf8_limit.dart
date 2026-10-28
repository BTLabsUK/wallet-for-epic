// SPDX-License-Identifier: Apache-2.0
/// Byte limits on text the wallet signs: LEPIC counts a slate message in UTF-8 bytes, so the
/// phone's and the desktop's fields count and stop the same way.
library;

import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter/services.dart';

/// The length of [text] in UTF-8 bytes, as LEPIC counts a slate message.
int utf8Length(String text) => utf8.encode(text).length;

/// Keeps a field's text within [maxBytes] UTF-8 bytes. An edit that would pass it keeps the
/// text around the edit and as many whole characters of what was typed or pasted as fit, with
/// the cursor after them, so a long paste is cut, never refused, and nothing already written
/// is lost.
class Utf8LengthLimiter extends TextInputFormatter {
  const Utf8LengthLimiter(this.maxBytes);

  final int maxBytes;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (utf8Length(newValue.text) <= maxBytes) return newValue;
    final old = oldValue.text;
    final edited = oldValue.selection;
    // The edit replaced the old selection with the inserted text, when it reads that way.
    if (edited.isValid && edited.start >= 0 && edited.end <= old.length) {
      final before = old.substring(0, edited.start);
      final after = old.substring(edited.end);
      final text = newValue.text;
      if (text.length >= before.length + after.length &&
          text.startsWith(before) &&
          text.endsWith(after)) {
        final inserted = text.substring(
          before.length,
          text.length - after.length,
        );
        final room = maxBytes - utf8Length(before) - utf8Length(after);
        final kept = _fit(inserted, room);
        return TextEditingValue(
          text: '$before$kept$after',
          selection: TextSelection.collapsed(
            offset: before.length + kept.length,
          ),
        );
      }
    }
    final kept = _fit(newValue.text, maxBytes);
    return TextEditingValue(
      text: kept,
      selection: TextSelection.collapsed(offset: kept.length),
    );
  }

  /// The longest run of whole characters from the start of [text] within [room] bytes.
  static String _fit(String text, int room) {
    final kept = StringBuffer();
    var bytes = 0;
    for (final c in text.characters) {
      final n = utf8Length(c);
      if (bytes + n > room) break;
      kept.write(c);
      bytes += n;
    }
    return kept.toString();
  }
}
