// SPDX-License-Identifier: Apache-2.0
// What reaches the log file on disk: a recovery phrase, a PIN or a secret in any shape a line
// could carry it (a JSON object, a URL, a typo'd word, pretty-printed data) must come out
// scrubbed. The phrase alone spends every coin.

import 'dart:io';

import 'package:epic_wallet/src/app_log.dart';
import 'package:epic_wallet/src/redact.dart';
import 'package:flutter_test/flutter_test.dart';

const _words = [
  'abandon', 'ability', 'able', 'about', 'above', 'absent', //
  'absorb', 'abstract', 'absurd', 'abuse', 'access', 'accident',
];

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
