// SPDX-License-Identifier: Apache-2.0
// Catches English left in a translation by mistake: a sentence the template words in English that
// a language kept as it is, or kept partly English, or (for languages with their own script) wrote
// without a single letter of that script. test/l10n_test.dart checks keys, placeholders and plurals.
//
// A message that really stays the same (a product name with a word, a format) goes in [_same].
// `tools/l10n sync` fills a new key with the English and lists it in lib/l10n/untranslated.json;
// the list must be empty (translated) before the change lands.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keys whose English stays in this language, with why.
const Map<String, Set<String>> _same = {
  // "online" and "offline" are everyday German; Node and Epicbox are names; Server and
  // Blockchain are the German words too (the sync picture's labels); Domain is the German word.
  'de': {'statusNodeOnline', 'statusNodeOffline', 'statusEpicboxOnline', 'statusEpicboxOffline', 'syncHelpServer', 'syncHelpChain', 'contactDomain'},
  // Polish UIs write online/offline as loanwords; Epicbox is a name.
  'pl': {'statusEpicboxOnline', 'statusEpicboxOffline'},
  'ru': {},
  'zh': {},
  'th': {},
};

/// The letters of each language with its own script.
final Map<String, RegExp> _script = {
  'ru': RegExp('[Ѐ-ӿ]'),
  'zh': RegExp('[㐀-鿿]'),
  'th': RegExp('[฀-๿]'),
};

/// English words that are not words in German or Polish: one of them in a translation is English
/// left behind.
final RegExp _englishWords = RegExp(
  r"\b(the|and|your|you|with|from|this|that|these|are|have|isn[’']t|don[’']t|can[’']t|won[’']t|which|when|before|after|until|already|again|only)\b",
  caseSensitive: false,
);

Map<String, String> _messages(File file) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final e in json.entries)
      if (!e.key.startsWith('@')) e.key: e.value as String,
  };
}

/// [message] without ICU syntax and placeholders: only the words a reader sees.
String _words(String message) => message
    .replaceAll(RegExp(r'\{\w+, (plural|select),'), ' ')
    .replaceAll(RegExp(r'\b(=\d+|zero|one|two|few|many|other)\{'), ' ')
    .replaceAll(RegExp(r'\{\w+\}'), ' ')
    .replaceAll(RegExp(r'[{}]'), ' ');

/// English prose: two words or more, one of them lower case (names are capitalised).
bool _prose(String english) {
  final w = _words(english);
  return RegExp(r'[A-Za-z]{2,}\s+\S').hasMatch(w.trim()) && RegExp(r'\b[a-z]{3,}\b').hasMatch(w);
}

/// The keys `tools/l10n sync` filled with the English text, per language, until translated.
final Map<String, List<String>> _untranslated = {
  for (final e in (jsonDecode(File('lib/l10n/untranslated.json').readAsStringSync()) as Map<String, dynamic>).entries)
    e.key: (e.value as List<dynamic>).cast<String>(),
};

void main() {
  final english = _messages(File('lib/l10n/app_en.arb'));
  final files = Directory('lib/l10n').listSync().whereType<File>().where((f) => RegExp(r'app_(\w+)\.arb$').hasMatch(f.path)).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final locale = RegExp(r'app_(\w+)\.arb$').firstMatch(file.path)!.group(1)!;
    if (locale == 'en') continue;
    final tr = _messages(file);
    final same = _same[locale] ?? const {};

    group(locale, () {
      test('no sentence kept in English', () {
        final kept = [
          for (final MapEntry(:key, :value) in tr.entries)
            if (!same.contains(key) && english[key] != null && _prose(english[key]!) && value == english[key]) key,
        ];
        expect(kept, isEmpty,
            reason: '${kept.length} messages equal their English: translate them in the file '
                '`tools/l10n check` names for each, or list a key that stays English on purpose in _same');
      });

      test('nothing listed in lib/l10n/untranslated.json', () {
        final left = [
          for (final key in _untranslated[locale] ?? const <String>[])
            if (!same.contains(key) && english[key] != null && tr[key] == english[key]) key,
        ];
        expect(left, isEmpty,
            reason: '${left.length} keys still in English: translate them in the file `tools/l10n check` '
                'names for each, then run tools/l10n sync (it clears them from the list)');
      });

      if (_script[locale] case final script?) {
        test('every sentence has letters of its script', () {
          final latin = [
            for (final MapEntry(:key, :value) in tr.entries)
              if (!same.contains(key) && english[key] != null && _prose(english[key]!) && !script.hasMatch(value)) key,
          ];
          expect(latin, isEmpty, reason: '${latin.length} messages without a letter of the $locale script');
        });
      } else {
        test('no English words inside a sentence', () {
          final mixed = [
            for (final MapEntry(:key, :value) in tr.entries)
              if (!same.contains(key) && _englishWords.hasMatch(_words(value))) '$key: $value',
          ];
          expect(mixed, isEmpty, reason: mixed.join('\n'));
        });
      }
    });
  }
}
