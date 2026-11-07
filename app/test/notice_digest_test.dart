// SPDX-License-Identifier: Apache-2.0
// One result per collect or drain: the fold of what a run held, and the batch around the run.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/message_checks.dart';
import 'package:epic_wallet/src/notice_digest.dart';
import 'package:epic_wallet/src/notice_digest_text.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

void _shown() {}

HeldNotice _held(HeldKind kind, String? slate, {bool named = false, bool silent = false}) =>
    HeldNotice(kind, slateId: slate, named: named, show: silent ? null : _shown);

/// A batch that records what it raised.
class _Run {
  _Run({Duration grace = const Duration(milliseconds: 10), Future<void> Function()? settle})
    : checks = MessageChecks(showAfter: const Duration(seconds: 5), digestGrace: grace, settle: settle) {
    addTearDown(checks.dispose);
    checks.notices.digests.listen(digests.add);
  }

  final MessageChecks checks;
  final digests = <NoticeDigest>[];
  final shown = <String>[];

  NoticeBatch get batch => checks.notices;

  void raise(HeldKind kind, String slate, {bool silent = false}) => raiseNotice(
    batch,
    HeldNotice(kind, slateId: slate, show: silent ? null : () => shown.add(slate)),
  );

  /// Past the grace.
  Future<void> settled() => Future<void>.delayed(const Duration(milliseconds: 80));
}

void main() {
  group('the fold', () {
    test('nothing folds to nothing', () {
      expect(foldNotices(const []), isEmpty);
    });

    test('a terminal state wins whatever the order: no prompt, not an invoice', () {
      for (final held in [
        [_held(HeldKind.invoice, 'a'), _held(HeldKind.withdrawn, 'a')],
        [_held(HeldKind.withdrawn, 'a'), _held(HeldKind.invoice, 'a')],
      ]) {
        expect(foldNotices(held).single.kind, HeldKind.withdrawn);
      }
    });

    test('a terminal state with no notice of its own leaves nothing', () {
      for (final kind in [HeldKind.declined, HeldKind.cancelled, HeldKind.withdrawn]) {
        expect(foldNotices([_held(HeldKind.invoice, 'a', named: true), _held(kind, 'a', silent: true)]), isEmpty);
      }
    });

    test('of a silent and a worded end, the worded one shows', () {
      final worded = _held(HeldKind.withdrawn, 'a');
      expect(foldNotices([_held(HeldKind.withdrawn, 'a', silent: true), worded]).single, worded);
      expect(foldNotices([worded, _held(HeldKind.withdrawn, 'a', silent: true)]).single, worded);
    });

    test('paid beats open and yields to a terminal state', () {
      expect(foldNotices([_held(HeldKind.invoice, 'a'), _held(HeldKind.paid, 'a')]).single.kind, HeldKind.paid);
      expect(foldNotices([_held(HeldKind.paid, 'a'), _held(HeldKind.expired, 'a')]).single.kind, HeldKind.expired);
    });

    test('the two notices of one contact invoice are the named one', () {
      for (final held in [
        [_held(HeldKind.invoice, 'a', named: true), _held(HeldKind.invoice, 'a')],
        [_held(HeldKind.invoice, 'a'), _held(HeldKind.invoice, 'a', named: true)],
      ]) {
        expect(foldNotices(held).single.named, isTrue);
      }
    });

    test('other slates and notices with no slate stay apart', () {
      final folded = foldNotices([_held(HeldKind.invoice, 'a'), _held(HeldKind.invoice, 'b'), _held(HeldKind.expired, null), _held(HeldKind.expired, null)]);
      expect(folded, hasLength(4));
    });

    test('mixed kinds count by kind, and open the place that lists them', () {
      final digest = NoticeDigest.of(
        foldNotices([
          _held(HeldKind.invoice, 'a'),
          _held(HeldKind.invoice, 'a', named: true),
          _held(HeldKind.invoice, 'b'),
          _held(HeldKind.withdrawal, 'c'),
          _held(HeldKind.invoice, 'd'),
          _held(HeldKind.withdrawn, 'd'),
        ]),
      );
      expect(digest.counts, {HeldKind.invoice: 2, HeldKind.withdrawal: 1, HeldKind.withdrawn: 1});
      expect(digest.total, 4);
      expect(digest.place, DigestPlace.invoices);
      expect(NoticeDigest({HeldKind.withdrawal: 2}).place, DigestPlace.activity);
      expect(NoticeDigest({HeldKind.paid: 2}).place, DigestPlace.sentInvoices);
    });
  });

  group('the words', () {
    test('one line counts the updates; the items count by kind with their plurals and places', () {
      final l = englishStrings;
      expect(noticeDigestText(l, NoticeDigest({HeldKind.invoice: 2, HeldKind.withdrawal: 1})), '3 new updates');
      expect(noticeDigestText(l, NoticeDigest({HeldKind.invoice: 1})), '1 new update');
      final items = noticeDigestItems(l, NoticeDigest({HeldKind.invoice: 2, HeldKind.withdrawal: 1}));
      expect(items.map((i) => i.text), ['2 invoices', '1 withdrawal']);
      expect(items.map((i) => i.place), [DigestPlace.invoices, DigestPlace.activity]);
      expect(
        noticeDigestItems(l, NoticeDigest({HeldKind.invoice: 1, HeldKind.paid: 2, HeldKind.expired: 1, HeldKind.withdrawn: 1})).map((i) => i.text),
        ['1 invoice', '2 invoices paid', '1 invoice expired', '1 invoice withdrawn'],
      );
      expect(noticeDigestItems(l, NoticeDigest({HeldKind.paid: 2})).single.place, DigestPlace.sentInvoices);
    });

    test('Polish and Russian decline the count', () {
      final pl = lookupAppLocalizations(const Locale('pl'));
      expect(noticeDigestText(pl, NoticeDigest({HeldKind.invoice: 5, HeldKind.withdrawal: 2})), '7 nowych aktualizacji');
      expect(noticeDigestItems(pl, NoticeDigest({HeldKind.invoice: 5, HeldKind.withdrawal: 2})).map((i) => i.text), ['5 faktur', '2 wypłaty']);
      final ru = lookupAppLocalizations(const Locale('ru'));
      expect(noticeDigestText(ru, NoticeDigest({HeldKind.invoice: 2, HeldKind.withdrawal: 1})), '3 новых обновления');
      expect(noticeDigestItems(ru, NoticeDigest({HeldKind.invoice: 2, HeldKind.withdrawal: 1})).map((i) => i.text), ['2 счёта', '1 вывод']);
    });
  });

  group('the batch', () {
    test('outside a run a notice shows at once', () {
      final run = _Run();
      run.raise(HeldKind.invoice, 'a');
      expect(run.shown, ['a']);
    });

    test('with no session a notice shows at once', () {
      var shown = false;
      raiseNotice(null, HeldNotice(HeldKind.invoice, show: () => shown = true));
      expect(shown, isTrue);
    });

    test('one notice is today\'s, after the run', () async {
      final run = _Run();
      await run.checks.run(CheckSource.collect, () async {
        run.raise(HeldKind.invoice, 'a');
        expect(run.shown, isEmpty);
      }, outcomeOf: (_) => const CheckOutcome());
      await run.settled();
      expect(run.shown, ['a']);
      expect(run.digests, isEmpty);
    });

    test('several are one digest, also from a quiet run', () async {
      final run = _Run();
      await run.checks.run(CheckSource.collect, () async {
        run.raise(HeldKind.invoice, 'a');
        run.raise(HeldKind.withdrawal, 'b');
      }, outcomeOf: (_) => const CheckOutcome(), quiet: true);
      await run.settled();
      expect(run.shown, isEmpty);
      expect(run.digests.single.total, 2);
    });

    test('what folds away gives nothing', () async {
      final run = _Run();
      run.batch.begin();
      run.raise(HeldKind.invoice, 'a');
      run.raise(HeldKind.declined, 'a', silent: true);
      run.batch.end();
      await run.settled();
      expect(run.shown, isEmpty);
      expect(run.digests, isEmpty);
    });

    test('an event that lands just after the run is in its result', () async {
      final run = _Run(grace: const Duration(milliseconds: 30));
      run.batch.begin();
      run.raise(HeldKind.invoice, 'a');
      run.batch.end();
      run.raise(HeldKind.withdrawal, 'b');
      await run.settled();
      expect(run.digests.single.total, 2);
      // The run is over: the next one is alone.
      run.raise(HeldKind.invoice, 'c');
      expect(run.shown, ['c']);
    });

    test('what the event tail still delivers after the grace is in the result', () async {
      late _Run run;
      run = _Run(settle: () async => run.raise(HeldKind.withdrawal, 'b'));
      run.batch.begin();
      run.raise(HeldKind.invoice, 'a');
      run.batch.end();
      await run.settled();
      expect(run.digests.single.total, 2);
    });

    test('a failed run still gives what it gathered', () async {
      final run = _Run();
      await expectLater(
        run.checks.run(CheckSource.collect, () async {
          run.raise(HeldKind.invoice, 'a');
          throw StateError('no server');
        }, outcomeOf: (_) => const CheckOutcome()),
        throwsStateError,
      );
      await run.settled();
      expect(run.shown, ['a']);
    });

    test('a rerun inside the grace and an overlapping run are one batch', () async {
      final run = _Run(grace: const Duration(milliseconds: 30));
      run.batch.begin();
      run.batch.begin();
      run.raise(HeldKind.invoice, 'a');
      run.batch.end();
      run.batch.end();
      run.batch.begin();
      run.raise(HeldKind.invoice, 'b');
      run.batch.end();
      await run.settled();
      expect(run.digests.single.total, 2);
    });

    test('lock, logout and close drop the batch without a word', () async {
      final run = _Run();
      run.batch.begin();
      run.raise(HeldKind.invoice, 'a');
      run.raise(HeldKind.invoice, 'b');
      run.batch.end();
      run.checks.dispose();
      await run.settled();
      run.raise(HeldKind.invoice, 'c');
      expect(run.shown, isEmpty);
      expect(run.digests, isEmpty);
    });
  });
}
