import 'package:epic_wallet/src/app_log.dart';
import 'package:epic_wallet/src/redact.dart';
import 'package:flutter_test/flutter_test.dart';

// The same cases as `rust/src/core/redact.rs`, so the two passes stay in step.
const _phrase =
    'abandon ability able about above absent absorb abstract absurd abuse '
    'access accident';
const _address =
    'esWn9r2zQj5eKkVh3sT4YpX7cBdF8gHmNaLuRvS6tE1iPo2wZxC9@epicbox.epiccash.com';

void main() {
  group('redact', () {
    test('scrubs a recovery phrase', () {
      expect(redact('restoring from $_phrase'), 'restoring from [words]');
      const numbered =
          '1. abandon 2. ability 3. able 4. about 5. above 6. absent '
          '7. absorb 8. abstract 9. absurd';
      expect(redact(numbered), isNot(contains('abandon')));
      expect(redact(_phrase.toUpperCase()), isNot(contains('ABANDON')));
    });

    test('keeps ordinary sentences', () {
      const text =
          'the payment to alice could not reach the node, please try again later';
      expect(redact(text), text);
      const seven = 'abandon ability able about above absent absorb';
      expect(redact(seven), seven);
    });

    test('scrubs a PIN in every shape', () {
      expect(redact('PIN 123456 rejected'), 'PIN [redacted] rejected');
      expect(redact('pin=654321'), 'pin=[redacted]');
      expect(redact('{"pin": "112233"}'), '{"pin": "[redacted]"}');
      expect(redact('Wrong PIN, 3 tries left'), 'Wrong PIN, 3 tries left');
      expect(redact('pinned 123456'), 'pinned 123456');
    });

    test('drops the values of secret keys', () {
      expect(redact('password=hunter2 ok'), 'password=[redacted] ok');
      expect(redact('keychain_mask: 00ff'), 'keychain_mask: [redacted]');
      expect(
        redact('Authorization: Bearer abc.def'),
        'Authorization: [redacted] [redacted]',
      );
      expect(redact('fcm_token=cX1:APA91b'), 'fcm_token=[redacted]');
      expect(redact('password was wrong'), 'password was wrong');
    });

    test('keeps only the start and relay of an epicbox address', () {
      expect(
        redact('sent to $_address.'),
        'sent to esWn9r…@epicbox.epiccash.com.',
      );
    });

    test('shortens ids and drops hex and tokens', () {
      expect(
        redact('slate 0f3b2a1c-9d8e-4f7a-b6c5-d4e3f2a1b0c9 posted'),
        'slate 0f3b2a1c… posted',
      );
      const kernel =
          '08a4c7e1f2b3d4c5e6f708192a3b4c5d6e7f8091a2b3c4d5e6f708192a3b4c5d6e';
      expect(redact('kernel $kernel'), 'kernel [hex]');
      expect(redact('GET /v1/kernel/$kernel'), 'GET /v1/kernel/[hex]');
      final fcm = 'cX1abc:APA91b${'Q' * 140}';
      expect(redact('token $fcm'), 'token [redacted]');
      const url =
          'https://github.com/blacktyger/wallet-for-epic/releases/latest/download/update.json';
      expect(redact(url), url);
    });

    test('drops a slate whole', () {
      expect(
        redact(
          'invalid slate {"id":"x","participant_data":[{"part_sig":"ab"}]}',
        ),
        'invalid slate [slate]',
      );
    });

    test('is stable when applied twice', () {
      final once = redact(
        '$_phrase pin 123456 to $_address 0f3b2a1c-9d8e-4f7a-b6c5-d4e3f2a1b0c9',
      );
      expect(redact(once), once);
    });

    test('passes non-ASCII text through', () {
      expect(
        redact('Zahlung für Café ✓ PIN 123456'),
        'Zahlung für Café ✓ PIN [redacted]',
      );
    });
  });

  group('AppLog', () {
    tearDown(() => AppLog.use(MemoryLogSink()));

    test(
      'redacts before the sink and hands lines over to a new sink',
      () async {
        final early = MemoryLogSink();
        AppLog.use(early);
        logInfo('unlock', 'PIN 123456 entered');
        logError('send', StateError('to $_address'), StackTrace.current);
        final later = MemoryLogSink();
        AppLog.use(later);
        expect(early.entries, isEmpty);
        final text = await later.tail(1 << 20);
        expect(text, contains('INFO dart.unlock: PIN [redacted] entered'));
        expect(text, contains('ERROR dart.send: Bad state: to esWn9r…@'));
        expect(text, isNot(contains('123456')));
      },
    );

    test(
      'the memory tail keeps the newest whole lines within the limit',
      () async {
        final sink = MemoryLogSink(capacity: 3);
        AppLog.use(sink);
        for (var i = 0; i < 5; i++) {
          logInfo('t', 'line $i');
        }
        expect(sink.entries, hasLength(3));
        final tail = await sink.tail(60);
        expect(tail, contains('line 4'));
        expect(tail, isNot(contains('line 2')));
        expect(tail.length, lessThanOrEqualTo(60));
      },
    );
  });
}
