// Checks every translation against the English template, so a missing key, a dropped
// placeholder or a plural without the forms its language needs fails here rather than on a
// phone. gen-l10n itself only reports missing keys, and only as a warning.

import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/errors.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The plural categories CLDR defines for whole numbers in each language.
const Map<String, Set<String>> _pluralCategories = {
  'en': {'one', 'other'},
  'de': {'one', 'other'},
  'pl': {'one', 'few', 'many', 'other'},
  'ru': {'one', 'few', 'many', 'other'},
  'zh': {'other'},
  'th': {'other'},
};

/// The forms a plural must have: all of its language's, except `one` where the English has
/// none because the number is never 1 (a 6-digit PIN, 12 or 24 words).
Set<String> _neededForms(String locale, {required bool englishHasOne}) =>
    _pluralCategories[locale]!.difference({if (!englishHasOne) 'one'});

Map<String, String> _messages(File file) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final e in json.entries)
      if (!e.key.startsWith('@')) e.key: e.value as String,
  };
}

String _locale(File file) =>
    RegExp(r'app_(\w+)\.arb$').firstMatch(file.path)!.group(1)!;

/// A `{name, plural, ...}` block: its variable and the selectors of its branches.
typedef _Plural = ({String variable, List<String> selectors});

/// Placeholder names and plural blocks in an ICU message, at any depth.
({Set<String> placeholders, List<_Plural> plurals}) _parse(String message) {
  final scanner = _IcuScanner(message)..run();
  return (placeholders: scanner.placeholders, plurals: scanner.plurals);
}

class _IcuScanner {
  _IcuScanner(this.message);

  final String message;
  final Set<String> placeholders = {};
  final List<_Plural> plurals = [];

  void run() {
    var i = 0;
    while (i < message.length) {
      if (message[i] == '{') {
        i = _argument(i + 1);
      } else if (message[i] == '}') {
        throw FormatException('unmatched }', message, i);
      } else {
        i++;
      }
    }
  }

  /// Parses the argument after the `{` at [start]; returns the index after its `}`.
  int _argument(int start) {
    final head = RegExp(r'\s*(\w+)\s*(?:,\s*(\w+)\s*,)?')
        .matchAsPrefix(message, start);
    if (head == null) throw FormatException('bad argument', message, start);
    placeholders.add(head.group(1)!);
    var i = head.end;
    final kind = head.group(2);
    if (kind == null) {
      if (i >= message.length || message[i] != '}') {
        throw FormatException('expected }', message, i);
      }
      return i + 1;
    }
    final selectors = <String>[];
    while (true) {
      final selector = RegExp(r'\s*(=?\w+)\s*\{').matchAsPrefix(message, i);
      if (selector == null) break;
      selectors.add(selector.group(1)!);
      i = _branch(selector.end);
    }
    final close = RegExp(r'\s*\}').matchAsPrefix(message, i);
    if (close == null) {
      throw FormatException('expected } after branches', message, i);
    }
    if (kind == 'plural') {
      plurals.add((variable: head.group(1)!, selectors: selectors));
    }
    return close.end;
  }

  /// Reads branch text from [start] to its closing `}`; returns the index after it.
  int _branch(int start) {
    var i = start;
    while (i < message.length) {
      final c = message[i];
      if (c == '{') {
        i = _argument(i + 1);
      } else if (c == '}') {
        return i + 1;
      } else {
        i++;
      }
    }
    throw FormatException('unclosed branch', message, start);
  }
}

void main() {
  final dir = Directory('lib/l10n');
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final english = _messages(File('lib/l10n/app_en.arb'));

  test(
    'every language in settings has a translation, and nothing else does',
    () {
      final arbLocales = files.map(_locale).toSet();
      expect(arbLocales, appLanguages.map((a) => a.code).toSet());
      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
        arbLocales,
      );
      expect(AppLocalizations.supportedLocales.first, const Locale('en'));
      expect(_pluralCategories.keys.toSet(), arbLocales);
    },
  );

  for (final file in files) {
    final locale = _locale(file);
    group('app_$locale.arb', () {
      final messages = _messages(file);

      test('has exactly the template keys', () {
        expect(
          messages.keys.toSet().difference(english.keys.toSet()),
          isEmpty,
          reason: 'extra',
        );
        expect(
          english.keys.toSet().difference(messages.keys.toSet()),
          isEmpty,
          reason: 'missing',
        );
      });

      test('keeps every placeholder, and plurals have this language\'s forms', () {
        final known = _pluralCategories[locale]!;
        final problems = <String>[];
        for (final MapEntry(:key, :value) in messages.entries) {
          final source = english[key];
          if (source == null) continue;
          final ({Set<String> placeholders, List<_Plural> plurals}) parsed;
          try {
            parsed = _parse(value);
          } on FormatException catch (e) {
            problems.add('$key: ${e.message}');
            continue;
          }
          final template = _parse(source);
          final expected = template.placeholders;
          if (!_sameSet(parsed.placeholders, expected)) {
            problems.add(
              '$key: placeholders ${parsed.placeholders} instead of $expected',
            );
          }
          for (final plural in parsed.plurals) {
            final categories = plural.selectors
                .where((s) => !s.startsWith('='))
                .toSet();
            // gen-l10n turns `=1` into the `one` form. That is right for English and German,
            // but in Polish and Russian `one` also covers 21, 31 and so on, where a literal
            // "1" would be wrong.
            final exactOne = plural.selectors.contains('=1');
            if (exactOne && (locale == 'pl' || locale == 'ru')) {
              problems.add('$key: =1 in $locale, use one');
            }
            final englishHasOne = template.plurals.any(
              (p) =>
                  p.variable == plural.variable &&
                  (p.selectors.contains('one') || p.selectors.contains('=1')),
            );
            final missing = _neededForms(
              locale,
              englishHasOne: englishHasOne,
            ).difference(categories).difference({if (exactOne) 'one'});
            final unknown = categories.difference(known);
            if (missing.isNotEmpty) {
              problems.add('$key: plural lacks $missing');
            }
            if (unknown.isNotEmpty) {
              problems.add('$key: plural has $unknown, unused in $locale');
            }
          }
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    });
  }

  group('formatting', () {
    setUpAll(initializeDateFormatting);

    AppLocalizations l(String code) => lookupAppLocalizations(Locale(code));

    test('numbers use the language\'s separators', () {
      expect(localDigits(l('en'), '1,234.5'), '1,234.5');
      expect(localDigits(l('de'), '1,234.5'), '1.234,5');
      expect(localDigits(l('pl'), '1,234.5'), '1\u00A0234,5');
      expect(localDigits(l('ru'), '1,234.5'), '1\u00A0234,5');
      expect(localDigits(l('zh'), '1,234.5'), '1,234.5');
      expect(localDecimal(l('de'), '0.5'), '0,5');
      expect(localDecimal(l('zh'), '0.5'), '0.5');
      expect(localInt(l('de'), 2500000), '2.500.000');
      expect(localDigits(l('th'), '1,234.5'), '1,234.5');
      expect(localDecimal(l('th'), '0.5'), '0.5');
    });

    test('dates are day first in English and CLDR elsewhere', () {
      final t = DateTime(2026, 9, 21, 14, 5);
      expect(localDay(l('en'), t), '21 Sep 2026');
      expect(localDayMonth(l('en'), t), '21 Sep');
      expect(localClock(l('en'), t), '14:05');
      expect(localDay(l('zh'), t), '2026年9月21日');
      expect(localClock(l('de'), t), '14:05');
      // Thai: Gregorian year and Arabic digits, as Thai exchanges and wallets show them.
      expect(localDay(l('th'), t), '21 ก.ย. 2026');
      expect(localClock(l('th'), t), '14:05 น.');
    });
  });

  group('Thai', () {
    final thai = _messages(File('lib/l10n/app_th.arb'));
    // ICU syntax and placeholders, so only the words a reader sees are left.
    String words(String message) => message
        .replaceAll(RegExp(r'\{\w+, (plural|select),'), ' ')
        .replaceAll(RegExp(r'\b(=\d+|zero|one|two|few|many|other)\{'), ' ')
        .replaceAll(RegExp(r'\{\w+\}'), ' ');

    test('every sentence is in Thai: no English left behind', () {
      final english = _messages(File('lib/l10n/app_en.arb'));
      final left = [
        for (final MapEntry(:key, :value) in thai.entries)
          // A lower-case English word marks prose; names (Epic Cash, Mainnet, Slate ID) are capitalised.
          // One token without a space is an example address or host, not prose.
          if (english[key]!.contains(' ') &&
              RegExp(r'\b[a-z]{3,}\b').hasMatch(words(english[key]!)) &&
              !RegExp('[\u0E00-\u0E7F]').hasMatch(value))
            key,
      ];
      expect(left, isEmpty);
    });

    test('no polite particles and no full stops after Thai, as UI text', () {
      final bad = [
        for (final MapEntry(:key, :value) in thai.entries)
          if (RegExp('ครับ|ค่ะ|[\u0E00-\u0E7F][.](\\s|\$)').hasMatch(value)) key,
      ];
      expect(bad, isEmpty);
    });
  });

  group('core sentences', () {
    String say(String code, WalletErrorKind kind, String message) =>
        describeError(
          lookupAppLocalizations(Locale(code)),
          WalletError(kind: kind, message: message),
        );

    test('English shows the core\'s own sentence', () {
      expect(
        say(
          'en',
          WalletErrorKind.invalidArgument,
          'This history file is damaged',
        ),
        'This history file is damaged.',
      );
    });

    test('other languages translate the known history-file sentences', () {
      final de = lookupAppLocalizations(const Locale('de'));
      expect(
        say(
          'de',
          WalletErrorKind.invalidArgument,
          'This history file is damaged',
        ),
        de.errorHistoryDamaged,
      );
      expect(
        say(
          'de',
          WalletErrorKind.invalidArgument,
          'This history file is from Floonet, but this wallet is on Mainnet',
        ),
        de.errorHistoryOtherNetwork('Floonet', 'Mainnet'),
      );
    });

    test('other languages put a translated summary before unknown detail', () {
      final ru = lookupAppLocalizations(const Locale('ru'));
      expect(
        say('ru', WalletErrorKind.invalidArgument, 'the address has no host'),
        '${ru.errorInvalidInput} the address has no host',
      );
      expect(
        say(
          'ru',
          WalletErrorKind.paymentExpired,
          'The answer to this payment came too late (block 5, limit 4). The '
              'payment was cancelled: nothing was sent, and the funds are unlocked.',
        ),
        ru.errorPaymentExpired,
      );
    });
  });
}

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
