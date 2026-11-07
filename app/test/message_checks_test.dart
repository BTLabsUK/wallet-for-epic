import 'package:epic_wallet/src/message_checks.dart';
import 'package:epic_wallet/src/ui/message_check_lines.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/l10n/app_localizations_en.dart';

void main() {
  test('outcomes add up and only held, refused and unreadable are news', () {
    const a = CheckOutcome(received: 1, held: 2, rejected: 1);
    const b = CheckOutcome(messages: 3, dropped: 1, failed: 1);
    final sum = a + b;
    expect((sum.held, sum.refused, sum.messages, sum.failed, sum.received), (2, 2, 3, 1, 1));
    expect(sum.hasNews, isTrue);
    expect(const CheckOutcome(received: 4, messages: 2).hasNews, isFalse);
  });

  test('a quick check never shows, a slow one does, a tick stays quiet', () async {
    final checks = MessageChecks(showAfter: const Duration(milliseconds: 40), digestGrace: Duration.zero);
    final seen = <bool>[];
    checks.stream.listen((c) => seen.add(c.checking));
    await checks.run(CheckSource.drain, () async => 1, outcomeOf: (_) => const CheckOutcome());
    expect(seen.contains(true), isFalse);
    expect(checks.value.checkedAt, isNotNull);
    await checks.run(CheckSource.collect, () => Future<int>.delayed(const Duration(milliseconds: 120), () => 1), outcomeOf: (_) => const CheckOutcome(messages: 1));
    expect(seen.contains(true), isTrue);
    expect(checks.value.checking, isFalse);
    seen.clear();
    await checks.run(CheckSource.collect, () => Future<int>.delayed(const Duration(milliseconds: 120), () => 1), quiet: true, outcomeOf: (_) => const CheckOutcome());
    expect(seen.contains(true), isFalse);
    checks.dispose();
  });

  test('a failure is kept and shown until a check ends well', () async {
    final checks = MessageChecks(showAfter: const Duration(seconds: 5), digestGrace: Duration.zero);
    await expectLater(checks.run<int>(CheckSource.collect, () async => throw StateError('x'), outcomeOf: (_) => const CheckOutcome()), throwsStateError);
    expect(checks.value.failed, isTrue);
    await checks.run(CheckSource.collect, () async => 1, outcomeOf: (_) => const CheckOutcome());
    expect(checks.value.failed, isFalse);
    checks.dispose();
  });

  test('lines say only what is not zero', () {
    final l = AppLocalizationsEn();
    expect(messageCheckLines(l, const MessageCheck(checking: true)), ['Checking messages']);
    final lines = messageCheckLines(l, MessageCheck(checkedAt: DateTime(2026, 1, 1, 14, 5), outcome: const CheckOutcome(held: 2, rejected: 1, unreadable: 1)));
    expect(lines, ['Checked at 14:05', 'Messages held: 2', 'Messages refused: 1', '1 message could not be read']);
    expect(messageCheckLines(l, const MessageCheck(failed: true)), ['The last message check failed']);
    expect(messageCheckLines(l, const MessageCheck(outcome: CheckOutcome(messages: 3, failed: 1, capped: 1))), [
      'Messages read: 3',
      'Pairings failed: 1',
      'More messages wait for the next check',
    ]);
  });
}
