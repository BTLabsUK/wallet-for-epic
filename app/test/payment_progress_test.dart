// SPDX-License-Identifier: Apache-2.0
// The payment progress model: steps for a send, a receive and a request; the network step; the
// steps going back; no steps where a status line says it all.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/kit/kit_steps.dart';
import 'package:epic_wallet/src/ui/payment_progress.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/watch_mode.dart' show BlockWait;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _l = englishStrings;
final _now = DateTime(2026, 11, 3, 12);
int _at(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;
final _tip = BigInt.from(2500000);

List<String> _labels(PaymentProgress p) => [for (final s in p.steps) s.title];
List<KitStepState> _states(PaymentProgress p) => [for (final s in p.steps) s.state];

PaymentProgress? _go(TxEntry tx, {String? who = 'Tom', BlockWait wait = BlockWait.none, bool paused = false, bool kill = false, String? reserved}) =>
    paymentProgress(_l, tx, _tip, now: _now, who: who, target: 3, wait: wait, paused: paused, killSwitch: kill, reserved: reserved);

TxEntry _sent(TxStatus status, {BigInt? height, String transport = 'epicbox', bool repostable = false, bool undelivered = false, int? finalized, int? blockTime}) =>
    fakeTx(
      slateId: 'a',
      kind: TxKind.sent,
      status: status,
      transport: transport,
      blockHeight: height,
      repostable: repostable,
      undelivered: undelivered,
      createdAtUnix: _at(_now.subtract(const Duration(hours: 2))),
      finalizedAtUnix: finalized,
      blockTimeUnix: blockTime,
    );

TxEntry _received(TxStatus status, {BigInt? height, int? reported}) => fakeTx(
  slateId: 'b',
  kind: TxKind.received,
  status: status,
  transport: 'epicbox',
  blockHeight: height,
  senderReportedPostedAtUnix: reported,
  createdAtUnix: _at(_now.subtract(const Duration(hours: 2))),
);

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  group('sending', () {
    test('waits for the other wallet, with the reason by transport', () {
      final p = _go(_sent(TxStatus.awaitingRecipient), reserved: '12.508 EPIC')!;
      // The network step only shows once the payment is there (the frame's three steps).
      expect(_labels(p), ['Sent', 'Waiting for Tom’s wallet to answer', 'Confirmed']);
      expect(_states(p), [KitStepState.done, KitStepState.now, KitStepState.later]);
      expect(p.current, 1);
      expect(p.network, isFalse);
      expect(p.reason, 'It answers when Tom next opens it. 12.508 EPIC is set aside until then.');
      expect(p.steps[1].detail, p.reason);
      expect(p.steps[0].detail, isNotNull, reason: 'a done step shows its time');
      expect(_go(_sent(TxStatus.awaitingRecipient, transport: 'file'), who: null)!.reason, 'It continues when the answer file comes back.');
    });

    test('goes back to the first step when it was not delivered', () {
      final p = _go(_sent(TxStatus.awaitingRecipient, undelivered: true))!;
      expect(p.current, 0);
      expect(p.reason, isNotEmpty);
    });

    test('goes back to the first step while Epicbox is off', () {
      final p = _go(_sent(TxStatus.awaitingRecipient), paused: true)!;
      expect(p.current, 0);
      expect(p.reason, _l.contactPausedEpicboxOff);
    });

    test('is in the network, with the animated mark, until a block holds it', () {
      final p = _go(_sent(TxStatus.awaitingConfirmation))!;
      expect(p.current, 2);
      expect(p.network, isTrue);
      expect(p.reason, 'On the network. A block will include it soon.');
      expect(_go(_sent(TxStatus.awaitingConfirmation), wait: BlockWait.noNewBlock)!.reason, startsWith('No new block yet'));
      expect(_go(_sent(TxStatus.awaitingConfirmation), wait: BlockWait.notInBlock)!.reason, startsWith('On the network, but no block'));
    });

    test('goes back to the network step, still, when it is not posted', () {
      final p = _go(_sent(TxStatus.awaitingConfirmation, repostable: true))!;
      expect(p.current, 2);
      expect(p.network, isFalse);
      expect(p.reason, 'Not posted yet. Post it again.');
      final held = _go(_sent(TxStatus.awaitingConfirmation, repostable: true), kill: true)!;
      expect(held.network, isFalse);
      expect(held.reason, startsWith('Finished but not posted'));
    });

    test('counts blocks once one holds it', () {
      final p = _go(_sent(TxStatus.confirmed, height: _tip))!;
      expect(p.current, 3);
      expect(p.reason, 'Confirming 1 of 3');
      expect(p.network, isFalse);
      expect(_states(p), [KitStepState.done, KitStepState.done, KitStepState.done, KitStepState.now]);
    });

    test('is done at the target, with the times it knows', () {
      final p = _go(_sent(TxStatus.confirmed, height: _tip - BigInt.from(5), finalized: _at(_now.subtract(const Duration(hours: 1))), blockTime: _at(_now.subtract(const Duration(minutes: 30)))))!;
      expect(p.completed, isTrue);
      expect(p.reason, isNull);
      expect(_states(p), everyElement(KitStepState.done));
      expect(p.steps[2].detail, isNotNull);
      expect(p.steps[3].detail, isNotNull);
    });
  });

  group('receiving', () {
    test('arrives, then the sender finishes', () {
      final p = _go(_received(TxStatus.awaitingConfirmation), who: 'Anna')!;
      expect(_labels(p), ['Arriving', 'Confirming 0 of 3', 'Ready to spend']);
      expect(p.current, 0);
      expect(p.reason, 'Waiting for Anna to finish the payment');
    });

    test('is in the network once the sender says it posted', () {
      final p = _go(_received(TxStatus.awaitingConfirmation, reported: _at(_now.subtract(const Duration(minutes: 5)))), who: 'Anna')!;
      expect(_labels(p), ['Arrived', 'In the network, waiting for a block', 'Confirming 0 of 3', 'Ready to spend']);
      expect(p.current, 1);
      expect(p.network, isTrue);
      expect(p.beforeNetwork, isFalse);
      expect(p.reason, 'Anna says it is on the network');
    });

    test('counts blocks and completes', () {
      final counting = _go(_received(TxStatus.confirmed, height: _tip - BigInt.one))!;
      expect(counting.steps[counting.current].title, 'Confirming 2 of 3');
      expect(counting.reason, 'It finishes by itself. You can leave this screen.');
      final done = _go(_received(TxStatus.confirmed, height: _tip - BigInt.from(9)))!;
      expect(done.completed, isTrue);
      expect(_labels(done).last, 'Ready to spend');
      expect(_states(done), everyElement(KitStepState.done));
    });
  });

  group('requests', () {
    test('wait for the payer, then for the chain', () {
      TxEntry request(TxStatus s, {BigInt? height}) =>
          fakeTx(slateId: 'c', kind: TxKind.received, flow: TxFlow.invoice, status: s, blockHeight: height, createdAtUnix: _at(_now.subtract(const Duration(hours: 1))));
      final waiting = _go(request(TxStatus.awaitingConfirmation), who: 'Tom');
      expect(waiting, isNotNull);
      expect(_labels(waiting!), ['Requested', 'Paid', 'In the network, waiting for a block', 'Confirmed']);
    });
  });

  group('no steps', () {
    test('for a cancelled payment, another wallet, a reward and a restored row', () {
      expect(_go(_sent(TxStatus.cancelled)), isNull);
      expect(_go(fakeTx(slateId: 'd', kind: TxKind.sent, status: TxStatus.confirmed, origin: TxOrigin.otherWallet)), isNull);
      expect(_go(fakeTx(slateId: 'e', kind: TxKind.coinbase, status: TxStatus.confirmed)), isNull);
      expect(_go(fakeTx(slateId: 'f', kind: TxKind.received, status: TxStatus.confirmed, source: TxSource.restored)), isNull);
    });
  });
}
