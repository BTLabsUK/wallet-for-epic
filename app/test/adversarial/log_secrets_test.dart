// SPDX-License-Identifier: Apache-2.0
// What reaches the log file on disk: a recovery phrase, a PIN or a secret in any shape a line
// could carry it (a JSON object, a URL, a typo'd word, pretty-printed data) must come out
// scrubbed. The phrase alone spends every coin.

import 'dart:io';

import 'package:epic_wallet/src/app_log.dart';
import 'package:epic_wallet/src/feedback.dart';
import 'package:epic_wallet/src/redact.dart';
import 'package:epic_wallet/src/support_clean.dart';
import 'package:flutter_test/flutter_test.dart';

const _words = [
  'abandon', 'ability', 'able', 'about', 'above', 'absent', //
  'absorb', 'abstract', 'absurd', 'abuse', 'access', 'accident',
];

const _address = 'esWWbPq4mFMqGXZ2nN1P9P2uGFZnTtM4axHwHrrcmVdTbixBK3oa';
const _onion = 'pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd';
const _slateId = '0f3b2a1c-9d8e-4f7a-b6c5-d4e3f2a1b0c9';
const _slate = '{"ver":"4:3","id":"$_slateId","sta":"S2","amt":"1500000000","sigs":[{"xs":"02ab","nonce":"03cd"}]}';

/// Names a log call must not interpolate: what says who was paid, how much, or a secret.
/// Log the fact and an id (`slateId`, `tx_id`), never the value.
const _banned = {
  'address', 'addr', 'recipient', 'amount', 'amt', 'fee', 'balance', 'slate', 'slatejson',
  'json', 'mnemonic', 'phrase', 'password', 'passphrase', 'seed', 'secret', 'privatekey', 'pin',
  'token', 'words',
};

/// How many of the phrase's words are still readable in [out].
int _leaked(String out) {
  final lower = out.toLowerCase();
  return _words.where((w) => RegExp('(^|[^a-z])$w([^a-z]|\$)').hasMatch(lower)).length;
}

void _scrubbed(String line, {int atMost = 0}) {
  final out = redact(line);
  expect(_leaked(out), lessThanOrEqualTo(atMost), reason: 'logged as: $out');
}

void main() {
  group('phrase shapes', () {
    test('scrubs_a_phrase_in_a_url_query', () {
      _scrubbed('GET /restore?words=${_words.join('+')}&lang=en');
      _scrubbed('GET /restore?words=${_words.join('%20')}');
    });

    test('scrubs_a_phrase_separated_by_newlines_and_tabs', () {
      _scrubbed(_words.join('\n'));
      _scrubbed(_words.join('\t'));
      _scrubbed(_words.join('\r\n'));
    });

    test('scrubs_a_phrase_in_mixed_case', () {
      _scrubbed(_words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' '));
    });

    test('scrubs_a_phrase_in_a_numbered_json_object', () {
      final obj = {for (var i = 0; i < _words.length; i++) '${i + 1}': _words[i]};
      _scrubbed(obj.entries.map((e) => '"${e.key}":"${e.value}"').join(','));
    });

    test('scrubs_a_phrase_held_in_named_json_fields', () {
      // A map of words by name, as a decoded form or a debug dump writes it.
      final obj = [for (var i = 0; i < _words.length; i++) '"word${i + 1}":"${_words[i]}"'].join(',');
      _scrubbed('{$obj}');
    });

    test('scrubs_a_pretty_printed_phrase_deep_in_a_document', () {
      final indent = ' ' * 16;
      _scrubbed('{\n  "a": {\n    "b": [\n$indent"${_words.join('",\n$indent"')}"\n    ]\n  }\n}');
    });

    test('scrubs_a_phrase_with_one_word_mistyped_long', () {
      // One extra letter on an eight-letter word: "abstract" typed "abstracts".
      final typo = [..._words]..[7] = 'abstracts';
      _scrubbed(typo.join(' '), atMost: 0);
    });

    test('scrubs_a_phrase_with_one_word_mistyped_short', () {
      // A two-letter fragment of a three-letter word: "able" typed "ab".
      final typo = [..._words]..[2] = 'ab';
      _scrubbed(typo.join(' '));
    });

    test('scrubs_a_twenty_four_word_phrase_with_two_typos', () {
      final words = [..._words, ..._words.reversed];
      words[6] = 'absorv';
      words[17] = 'abandn';
      _scrubbed(words.join(' '));
    });

    test('keeps_nothing_of_a_phrase_after_a_secret_key', () {
      _scrubbed('mnemonic="${_words.join(' ')}"');
      _scrubbed('{"phrase": "${_words.join(' ')}"}');
      _scrubbed('seed: ${_words.join(',')}');
    });
  });

  group('other secrets', () {
    test('scrubs_a_pin_and_a_password_in_any_quoting', () {
      for (final line in [
        'pin=123456',
        'PIN: 123456',
        '{"pin":"123456"}',
        "password='hunter2hunter2'",
        'Password = "s3cr3t-value"',
        'Authorization: Basic dXNlcjpwYXNz',
        'api_key=abcdef0123',
      ]) {
        final out = redact(line);
        for (final secret in ['123456', 'hunter2hunter2', 's3cr3t-value', 'dXNlcjpwYXNz', 'abcdef0123']) {
          expect(out, isNot(contains(secret)), reason: '$line => $out');
        }
      }
    });

    test('scrubs_a_slate_whatever_comes_before_it', () {
      final out = redact('received: {"ver":"4:3","sta":"S1","participant_data":[{"part_sig":"aa"}]}');
      expect(out, isNot(contains('part_sig')));
    });
  });

  group('redacted by default', () {
    test('an_address_is_a_fingerprint_an_amount_a_bucket_a_slate_its_id_and_state', () {
      final out = redact('sent 12.5 EPIC to $_address@epicbox.example via $_onion.onion, fee=700000 slate $_slate');
      expect(out, contains('esWWbP…K3oa@epicbox.example'));
      expect(out, contains('pg6mmj…cryd.onion'));
      expect(out, contains('[<100 EPIC] to'));
      expect(out, contains('fee=[<0.01 EPIC]'));
      expect(out, contains('[slate 0f3b2a1c… S2]'));
      for (final leak in [_address, _onion, '12.5', '700000', '1500000000', 'sigs', '"02ab"']) {
        expect(out, isNot(contains(leak)), reason: out);
      }
      expect(redact(out), out, reason: 'a second pass, at the sink, changes nothing');
    });

    test('detailed_keeps_addresses_and_amounts_but_never_a_secret_or_a_slate', () {
      final out = redact('sent 12.5 EPIC to $_address pin=482913 ${_words.join(' ')} slate $_slate', details: true);
      expect(out, contains(_address));
      expect(out, contains('12.5 EPIC'));
      expect(out, isNot(contains('482913')));
      expect(_leaked(out), 0);
      expect(out, contains('[slate 0f3b2a1c… S2]'));
    });

    test('the_log_file_holds_full_details_only_while_detailed_is_on', () {
      final dir = Directory.systemTemp.createTempSync('wfe-log-');
      final sink = FileLogSink.open(dir, mirror: (_, _, _) {});
      final before = AppLog.sink;
      AppLog.use(sink);
      addTearDown(() {
        AppLog.detailedUntil = null;
        AppLog.use(before);
        dir.deleteSync(recursive: true);
      });
      logWarn('send', 'to $_address failed for 3 EPIC');
      expect(sink.file.readAsStringSync(), isNot(contains(_address)));
      expect(sink.file.readAsStringSync(), isNot(contains('3 EPIC')));
      AppLog.detailedUntil = DateTime.now().add(const Duration(hours: 1));
      logWarn('send', 'to $_address failed for 3 EPIC, password=hunter2hunter2');
      final text = sink.file.readAsStringSync();
      expect(text, contains(_address));
      expect(text, contains('3 EPIC'));
      expect(text, isNot(contains('hunter2hunter2')));
    });

    test('a_report_drops_full_details_unless_the_user_includes_them', () async {
      final log = 'WARN dart.send: to $_address@epicbox.example failed for 3 EPIC, slate ${_slateId.substring(0, 8)}…\n';
      const facts = FeedbackDetails(appVersion: '1', platform: 'linux', network: 'mainnet', node: 'n', relay: 'r', sync: 's');
      String report({required bool full}) =>
          buildFeedbackReport(message: 'm', details: facts, log: log, at: DateTime(2026), fullDetails: full).text;
      final redacted = report(full: false);
      expect(redacted, isNot(contains(_address)));
      expect(redacted, isNot(contains('esWWbP')));
      expect(redacted, isNot(contains('3 EPIC')));
      expect(redacted, contains('[<10 EPIC]'));
      final full = report(full: true);
      expect(full, contains(_address));
      expect(full, contains('3 EPIC'));
      expect(full, contains('log details'));
      expect(cleanForReport('pin=482913 ${_words.join(' ')}', fullDetails: true), isNot(contains('482913')));
    });

    test('no_log_call_interpolates_an_address_an_amount_a_slate_or_a_secret', () {
      final call = RegExp(r'\blog(?:Info|Warn|Error|Debug)\(([^;]*?)\);', dotAll: true);
      final interpolation = RegExp(r'\$\{([^}]*)\}|\$([A-Za-z_]\w*)');
      final identifier = RegExp(r'[A-Za-z_]\w*');
      final offenders = <String>[];
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart') || file.path.contains('${Platform.pathSeparator}l10n${Platform.pathSeparator}')) continue;
        final text = file.readAsStringSync();
        for (final m in call.allMatches(text)) {
          for (final i in interpolation.allMatches(m[1]!)) {
            final names = identifier.allMatches(i[1] ?? i[2]!).map((n) => n[0]!.toLowerCase());
            if (names.any(_banned.contains)) {
              final line = '\n'.allMatches(text.substring(0, m.start)).length + 1;
              offenders.add('${file.path}:$line ${i[0]}');
            }
          }
        }
      }
      expect(offenders, isEmpty, reason: 'log the fact and an id instead');
    });
  });

  group('log file', () {
    test('the_log_file_never_holds_a_phrase_or_pin_logged_in_any_shape', () {
      final dir = Directory.systemTemp.createTempSync('wfe-log-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final sink = FileLogSink.open(dir, mirror: (_, _, _) {});
      sink.record(LogLevel.warn, 'restore', 'failed for ["${_words.join('","')}"]');
      sink.record(LogLevel.warn, 'restore', 'words: ${_words.join(' | ')}');
      sink.record(LogLevel.info, 'unlock', 'pin=482913');
      final text = sink.file.readAsStringSync();
      expect(_leaked(text), 0, reason: text);
      expect(text, isNot(contains('482913')));
    });
  });
}
