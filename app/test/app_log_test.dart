// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:epic_wallet/src/app_log.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart' show logLepicEntry;
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

const _phrase =
    'abandon ability able about above absent absorb abstract absurd abuse '
    'access accident';
const _address =
    'esWn9r2zQj5eKkVh3sT4YpX7cBdF8gHmNaLuRvS6tE1iPo2wZxC9@epicbox.epiccash.com';
const _slate =
    '{"version_info":{"version":3},"id":"0436430c-2b02-624c-2032-570501212b00",'
    '"participant_data":[{"public_blind_excess":"03aa","part_sig":null}]}';

void main() {
  late Directory dir;
  final mirrored = <String>[];

  FileLogSink open({int maxBytes = maxLogFileBytes}) => FileLogSink.open(
    dir,
    maxBytes: maxBytes,
    mirror: (level, target, body) => mirrored.add('$target: $body'),
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('wfe_log_test');
    mirrored.clear();
  });
  tearDown(() {
    AppLog.use(MemoryLogSink());
    AppLog.ring = null;
    AppLog.ringDir = null;
    AppLog.detailedUntil = null;
    dir.deleteSync(recursive: true);
  });

  test('the file rotates to wfe.log.1 and stays bounded', () async {
    final sink = open(maxBytes: 1000);
    for (var i = 0; i < 100; i++) {
      sink.write(
        LogLevel.info,
        't',
        'line ${i.toString().padLeft(3, '0')} ${'x' * 20}',
      );
    }
    final current = sink.file.lengthSync();
    final previous = sink.previous.lengthSync();
    expect(current, lessThanOrEqualTo(1000));
    expect(previous, lessThanOrEqualTo(1000));
    expect(dir.listSync().map((e) => e.uri.pathSegments.last).toSet(), {
      'wfe.log',
      'wfe.log.1',
    });

    final tail = await sink.tail(1500);
    expect(tail.length, lessThanOrEqualTo(1500));
    expect(tail, endsWith('dart.t: line 099 ${'x' * 20}\n'));
    expect(tail, matches(RegExp(r'^\d{4}-\d\d-\d\dT')), reason: 'whole line');
    expect(tail, isNot(contains('line 000')));
    // It reaches into the rotated file when the current one is short.
    expect(tail.length, greaterThan(current));
    sink.close();
  });

  test('the tail keeps whole lines, and a reopened file carries on', () async {
    open()
      ..write(LogLevel.info, 'a', 'first')
      ..close();
    final sink = open()..write(LogLevel.warn, 'b', 'second');
    final all = await sink.tail(1 << 20);
    expect(
      all,
      matches(
        RegExp(r'^\S+Z INFO  dart\.a: first\n\S+Z WARN  dart\.b: second\n$'),
      ),
    );
    final last = await sink.tail(
      '2026-10-01T00:00:00.000Z WARN  dart.b: second\n'.length,
    );
    expect(last, endsWith('WARN  dart.b: second\n'));
    expect(last, isNot(contains('first')));
    expect(await sink.tail(10), isEmpty, reason: 'no partial line');
    sink.close();
  });

  test('a LEPIC entry writes each field once and keeps the harmless numbers (windows-08)', () async {
    final sink = open();
    AppLog.use(sink);
    logLepicEntry(
      const lepic.LogEntry(
        level: lepic.LogLevel.info,
        target: 'lepic_epicbox::client_inbox',
        message: 'epicbox disconnected, retrying',
        spans: ['epicbox_listen', 'epicbox_listen'],
        fields: [
          lepic.LogField(name: 'wallet', value: 'default'),
          lepic.LogField(name: 'transport', value: 'epicbox'),
          lepic.LogField(name: 'transport', value: 'epicbox'),
          lepic.LogField(name: 'relay', value: 'epicbox.epiccash.com'),
          lepic.LogField(name: 'attempt', value: '0'),
          lepic.LogField(name: 'retry_in_ms', value: '2000'),
          lepic.LogField(name: 'relay', value: 'epicbox.epiccash.com'),
          lepic.LogField(name: 'amount', value: '2500000000'),
        ],
      ),
    );
    logLepicEntry(
      const lepic.LogEntry(
        level: lepic.LogLevel.info,
        target: 'lepic_foreign::server',
        message: 'foreign api listening',
        spans: [],
        fields: [
          lepic.LogField(name: 'port', value: '3415'),
          lepic.LogField(name: 'exposure', value: 'local'),
        ],
      ),
    );
    final written = sink.file.readAsStringSync();
    expect(
      written,
      contains(
        'epicbox disconnected, retrying in epicbox_listen wallet=default transport=epicbox '
        'relay=epicbox.epiccash.com attempt=0 retry_in_ms=2000 amount=[redacted]\n',
      ),
    );
    expect(written, contains('foreign api listening port=3415 exposure=local\n'));
    expect(written, isNot(contains('2500000000')));
    sink.close();
  });

  test('a LEPIC entry is redacted at the sink: slate, phrase and PIN', () async {
    final sink = open();
    AppLog.use(sink);
    logLepicEntry(
      const lepic.LogEntry(
        level: lepic.LogLevel.info,
        target: 'lepic_wallet::receive',
        message: 'slate received $_slate',
        spans: ['receive'],
        fields: [lepic.LogField(name: 'slate_id', value: 'abcd1234')],
      ),
    );
    logLepicEntry(
      const lepic.LogEntry(
        level: lepic.LogLevel.error,
        target: 'lepic_wallet::restore',
        message: 'restore failed',
        spans: [],
        fields: [
          lepic.LogField(name: 'amount', value: '2500000000'),
          lepic.LogField(name: 'height', value: '1041'),
          // Last: the phrase rule also takes a wordlist word after the run.
          lepic.LogField(name: 'error', value: 'bad words $_phrase'),
        ],
      ),
    );
    logLepicEntry(
      const lepic.LogEntry(
        level: lepic.LogLevel.warn,
        target: 'lepic_ffi::vault',
        message: 'unlock with pin 123456 refused, sending to $_address',
        spans: [],
        fields: [],
      ),
    );
    logLepicEntry(
      const lepic.LogEntry(
        level: lepic.LogLevel.warn,
        target: 'lepic_epicbox::frame',
        message: 'relay frame rejected',
        spans: [],
        fields: [
          lepic.LogField(
            name: 'error',
            value:
                'invalid type: string "say \\"hi\\" 7300431", '
                'expected u64; out of range `300431`',
          ),
        ],
      ),
    );
    logLepicEntry(
      const lepic.LogEntry(
        level: lepic.LogLevel.debug,
        target: 'lepic_wallet::send',
        message: 'debug detail',
        spans: [],
        fields: [],
      ),
    );
    // Every minute: kept only with Detailed logging.
    logLepicEntry(
      const lepic.LogEntry(
        level: lepic.LogLevel.info,
        target: 'lepic_wallet::refresh',
        message: 'refresh completed',
        spans: ['refresh'],
        fields: [lepic.LogField(name: 'height', value: '3766845')],
      ),
    );

    final written = sink.file.readAsStringSync();
    expect(
      written,
      contains('INFO  lepic_wallet::receive: slate received [slate 0436430c…]'),
    );
    expect(
      written,
      contains(
        'ERROR lepic_wallet::restore: restore failed amount=[redacted] '
        'height=1041 error=bad words [words]\n',
      ),
    );
    expect(
      written,
      contains('WARN  lepic_ffi::vault: unlock with pin [redacted] refused'),
    );
    expect(written, contains('esWn9r…ZxC9@epicbox.epiccash.com'));
    expect(
      written,
      contains(
        'WARN  lepic_epicbox::frame: relay frame rejected error=invalid type: '
        'string "[redacted]", expected u64; out of range `[redacted]`\n',
      ),
    );
    expect(written, isNot(contains('debug detail')));
    expect(written, isNot(contains('refresh completed')));
    for (final text in [written, await sink.tail(1 << 20), ...mirrored]) {
      for (final secret in [
        'participant_data',
        'abandon',
        '123456',
        '2500000000',
        'esWn9r2zQj5',
        '7300431',
        '300431',
        'say',
      ]) {
        expect(text, isNot(contains(secret)), reason: secret);
      }
    }
    expect(mirrored, hasLength(4));
    sink.close();
  });

  test(
    'early lines reach the file, and dependencies log at warn only',
    () async {
      final early = MemoryLogSink();
      AppLog.use(early);
      logInfo('app', 'start');
      final sink = open();
      AppLog.use(sink);
      AppLog.record(LogLevel.info, 'hyper::client', 'chatter');
      AppLog.record(LogLevel.warn, 'hyper::client', 'dependency warning');
      logError('push', StateError('multi\nline'));
      final written = sink.file.readAsStringSync();
      expect(written, contains('INFO  dart.app: start\n'));
      expect(written, isNot(contains('chatter')));
      expect(written, contains('WARN  hyper::client: dependency warning\n'));
      expect(
        written,
        contains('ERROR dart.push: Bad state: multi\n    line\n'),
      );
      sink.close();
    },
  );

  test(
    'the sink itself redacts what reaches it, and so does the tail',
    () async {
      final sink = open();
      sink.record(LogLevel.info, 'lepic_wallet::x', 'pin 123456 $_slate');
      sink.write(LogLevel.warn, 'restore', 'words $_phrase');
      final written = sink.file.readAsStringSync();
      expect(
        written,
        contains('INFO  lepic_wallet::x: pin [redacted] [slate 0436430c…]\n'),
      );
      expect(written, contains('WARN  dart.restore: words [words]\n'));
      // A line an older build, or anything else, wrote without redaction.
      File(sink.file.path).writeAsStringSync(
        '2026-10-01T00:00:00.000Z INFO  dart.old: pin 654321 $_address\n',
        mode: FileMode.append,
      );
      final tail = await sink.tail(1 << 20);
      // The tail feeds the report, whose cleanForReport keeps or drops addresses (Include full
      // details); secrets are gone already.
      expect(tail, contains('dart.old: pin [redacted] $_address'));
      for (final text in [written, tail, ...mirrored]) {
        for (final secret in [
          '123456',
          '654321',
          'participant_data',
          'abandon',
          if (!identical(text, tail)) 'esWn9r2zQj5',
        ]) {
          expect(text, isNot(contains(secret)), reason: secret);
        }
      }
      expect(mirrored, hasLength(2));
      sink.close();
    },
  );

  test('a failed rotation keeps the log going and says so', () {
    // A directory where wfe.log.1 belongs cannot be deleted as a file or renamed over.
    Directory('${dir.path}/wfe.log.1/blocker').createSync(recursive: true);
    final sink = open(maxBytes: 300);
    for (var i = 0; i < 20; i++) {
      sink.write(LogLevel.info, 't', 'line $i ${'x' * 40}');
    }
    final written = sink.file.readAsStringSync();
    expect(written, contains('WARN  dart.log: rotation failed'));
    expect(written, contains('line 19 '));
    expect(written, contains('line 0 '), reason: 'nothing was lost');
    sink.close();
  });

  test('the app\'s lines go to the ring too, redacted as without Detailed logging', () {
    final sink = open();
    AppLog.use(sink);
    final ring = <String>[];
    AppLog.ring = (level, tag, message) => ring.add('${level.name} $tag: $message');
    AppLog.detailedUntil = DateTime.now().add(const Duration(hours: 1));
    logInfo('send', 'to $_address, pin 123456');
    AppLog.detailedUntil = null;
    logDebug('send', 'not without Detailed logging');
    AppLog.record(LogLevel.warn, 'lepic_wallet::send', 'LEPIC writes its own');
    expect(ring, ['info send: to esWn9r…ZxC9@epicbox.epiccash.com, pin [redacted]']);
    expect(sink.file.readAsStringSync(), contains('dart.send: to $_address'), reason: 'Detailed keeps it in the file');
    sink.close();
  });

  test('the app\'s lines coming back from LEPIC are not written twice', () {
    final sink = open();
    AppLog.use(sink);
    for (final target in ['dart', 'dart.send']) {
      logLepicEntry(
        lepic.LogEntry(level: lepic.LogLevel.info, target: target, message: 'from the ring', spans: const [], fields: const []),
      );
    }
    expect(sink.file.readAsStringSync(), isNot(contains('from the ring')));
    sink.close();
  });

  test('a report reads the ring oldest first, whole lines only; clearing empties it', () async {
    expect(await readLogRing(), isNull, reason: 'no ring named');
    final ring = Directory('${dir.path}/ring')..createSync();
    AppLog.ringDir = ring.path;
    expect(await readLogRing(), isNull, reason: 'no line yet');
    final other = File('${ring.path}/notes.txt')..writeAsStringSync('kept');
    File('${ring.path}/lepic.2.log').writeAsStringSync('a\n');
    File('${ring.path}/lepic.0.log').writeAsStringSync('c\nhalf');
    expect(await readLogRing(), [(name: 'lepic.2.log', text: 'a\n'), (name: 'lepic.0.log', text: 'c\n')]);

    File('${ring.path}/lepic.1.log').writeAsStringSync('${'b' * logRingBytes}\n');
    final capped = await readLogRing();
    expect([for (final f in capped!) f.name], ['lepic.0.log'], reason: 'the newest ${logRingBytes ~/ 1024} KB');

    clearLogRing();
    expect(File('${ring.path}/lepic.0.log').readAsStringSync(), isEmpty);
    expect(File('${ring.path}/lepic.1.log').existsSync(), isFalse);
    expect(File('${ring.path}/lepic.2.log').existsSync(), isFalse);
    expect(other.readAsStringSync(), 'kept');
    expect(await readLogRing(), isNull);
  });

  test('quoted text in an error is redacted, escapes and all', () {
    expect(redactQuoted('no quotes'), 'no quotes');
    expect(
      redactQuoted('bad "abc" and `12`'),
      'bad "[redacted]" and `[redacted]`',
    );
    expect(redactQuoted(r'say "a \" b" end'), 'say "[redacted]" end');
    expect(redactQuoted('open "rest of it'), 'open "[redacted]');
    expect(redactQuoted(r'tick `a\` b'), r'tick `[redacted]` b');
  });

  test('long messages are cut on a character', () {
    final line = formatLogLine(
      DateTime.utc(2026),
      LogLevel.info,
      'dart.t',
      'é' * maxLogMessageBytes,
    );
    expect(line, endsWith('…\n'));
    expect(line, isNot(contains('\uFFFD')));
    expect(line.length, lessThan(maxLogMessageBytes));
  });

  test('timestamps are UTC to the millisecond', () {
    expect(
      logTimestamp(DateTime.fromMillisecondsSinceEpoch(1790000000123)),
      '2026-09-21T14:13:20.123Z',
    );
    expect(
      logTimestamp(DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)),
      '1970-01-01T00:00:00.000Z',
    );
  });
}
