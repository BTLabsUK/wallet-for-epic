// SPDX-License-Identifier: Apache-2.0
/// Sealed payment text, without Flutter: the wallet core reads it under plain Dart.
library;

/// The file extension, without the dot, LEPIC gives sealed [text] (`sealedFileExtension`): set by
/// the LEPIC service, which this file cannot import. Unset (fakes), [sealedExtensionOf] reads the
/// armor line itself.
String Function(String text)? sealedExtensionHook;

/// The extension to save sealed [text] under: `epictx` for a native slate (`BEGINEPICTX.`),
/// `epicsealed` for any other, or when the text is not at hand.
String sealedExtensionOf(String? text) {
  if (text == null) return 'epicsealed';
  final hook = sealedExtensionHook;
  if (hook != null) {
    try {
      return hook(text);
    } catch (_) {
      // Over the limit the core takes: the armor line decides.
    }
  }
  return text.trimLeft().startsWith('BEGINEPICTX.') ? 'epictx' : 'epicsealed';
}

/// Sealed text (RFC 3.5): armored, `BEGINEPICSEALED` or `BEGINEPICTX.` after optional whitespace.
bool isSealedText(String text) {
  final t = text.trimLeft();
  return t.startsWith('BEGINEPICSEALED') || t.startsWith('BEGINEPICTX.');
}
