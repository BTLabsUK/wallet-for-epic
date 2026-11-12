// SPDX-License-Identifier: Apache-2.0
// Designer-frame visits: Send (Send-*). Add `('fr-<Frame>', _Start.home, visit)` entries to the
// list and, when a frame needs its own data, a seed to `_sendSeeds`. See tool/tour/FRAMES.md.
part of '../screenshot_tour_test.dart';

/// Home's Send button, then Tom picked and 12.5 typed: the amount step of Send-2 and what follows.
Future<void> _sendToTom(_Tour t, {String amount = '12.5', bool note = true}) async {
  await t.tapText(t.l.homeSendButton);
  await t.enterRecipient(_fTom);
  await t.tap(find.widgetWithText(FilledButton, t.l.commonContinue));
  await t.enter(t.l.sendAmountLabel('EPIC'), localDecimal(t.l, amount));
  if (note) {
    await t.tapText(t.l.sendAddNote);
    await t.enter(t.l.sendNoteLabel, 'Tickets');
    // Leaving the field turns the note into its chip, as the frames draw it.
    FocusManager.instance.primaryFocus?.unfocus();
    await t.tester.pump();
  }
}

final List<(String, _Start, _Visit)> _framesSend = [
  ('fr-Send-1-Who', _Start.home, (t) async {
    await t.tapText(t.l.homeSendButton);
    await t.shot('fr-Send-1-Who');
  }),
  ('fr-Send-2-Amount', _Start.home, (t) async {
    await _sendToTom(t);
    await t.shot('fr-Send-2-Amount');
  }),
  ('fr-Send-2b-Max', _Start.home, (t) async {
    await _sendToTom(t);
    await t.tapText(t.l.sendMax);
    await t.shot('fr-Send-2b-Max');
  }),
  ('fr-Send-2c-Over', _Start.home, (t) async {
    await _sendToTom(t, amount: '1300');
    await t.shot('fr-Send-2c-Over');
  }),
  ('fr-Send-3-Review', _Start.home, (t) async {
    await _sendToTom(t);
    await t.tap(find.byKey(sendReviewButtonKey));
    await t.shot('fr-Send-3-Review');
  }),
  ('fr-Send-4-Sent', _Start.home, (t) async {
    await _sendToTom(t);
    await t.tap(find.byKey(sendReviewButtonKey));
    // The wallet's own record of the payment: sent today 18:12 over Epicbox to Tom.
    t.session.transactionsValue.add(
      fakeTx(
        id: 100,
        slateId: 'send-0',
        kind: TxKind.sent,
        status: TxStatus.awaitingRecipient,
        createdAtUnix: _at(0, 18, 12),
        amountDebited: _epic(12.5) + t.session.fee,
        fee: t.session.fee,
        numInputs: 1,
        numOutputs: 0,
        counterparty: _fTom,
        transport: 'epicbox',
        pairingId: 'p-tom',
        cancellable: true,
      ),
    );
    await t.send(epicText(t.l, _epic(12.5)));
    ProviderScope.containerOf(t.tester.element(find.byType(Navigator).first)).invalidate(homeProvider);
    await t.frames();
    await t.shot('fr-Send-4-Sent');
  }),
  ('fr-Send-5-Address', _Start.home, (t) async {
    await t.tapText(t.l.homeSendButton);
    await t.enterRecipient(_fKnownNot);
    await t.shot('fr-Send-5-Address');
  }),
  ('fr-Send-6-NoAddress', _Start.home, (t) async {
    await t.tapText(t.l.homeSendButton);
    await t.tapText(t.l.sendNoAddress);
    await t.shot('fr-Send-6-NoAddress');
  }),
  ('fr-Start-5-Approve', _Start.home, (t) async {
    await _sendToTom(t);
    await t.tap(find.byKey(sendReviewButtonKey));
    await t.tapText(t.l.sendReviewSendButton(epicText(t.l, _epic(12.5))));
    await t.typeOnPad('123');
    await t.shot('fr-Start-5-Approve');
  }),
  ('fr-Gap-2-Help', _Start.home, (t) async {
    await t.tapText(t.l.homeSendButton);
    await t.tap(find.byTooltip(t.l.sendHelp));
    await t.shot('fr-Gap-2-Help');
  }),
];

/// The Send frames draw the classic Send; the other frames' wallet is in epic1 mode.
final Set<String> _framesSendClassic = {for (final v in _framesSend) v.$1};

/// Per-frame data on top of the base wallet (frame_data.dart), by visit name.
final Map<String, void Function(FakeWalletSession s)> _sendSeeds = {
  // Who lists Tom, Coffee Corner and the unsaved address as the people last paid.
  'fr-Send-1-Who': (s) => s.transactionsValue
    ..clear()
    ..addAll([
      _fTx(1, out: false, amount: 25.0, at: _at(0, 14, 48), who: _fAnna),
      _fTx(3, out: true, amount: 12.5, at: _at(1, 18, 12), who: _fTom, sealed: true),
      _fTx(2, out: true, amount: 9.294, at: _at(2, 9, 12), who: _fCoffee, note: 'Coffee beans'),
      _fTx(5, out: true, amount: 80.0, at: _at(10, 12, 30), who: _fUnknown),
    ]),
  // Tom is a paired contact in the frames that end in a payment: the review says Sealed.
  for (final v in const ['fr-Send-3-Review', 'fr-Send-4-Sent', 'fr-Start-5-Approve']) v: _pairTom,
};

void _pairTom(FakeWalletSession s) => s.pairing.seedPaired(id: 'p-tom', name: 'Tom', contactId: 'f-tom', paymentsAddress: _fTom);

/// `esKJda…RpFxfc@epicbox.epiccash.com`: the address Send-5 shows, new to the wallet.
final String _fKnownNot = 'esKJdaBi1W1eHJFeV6HAPCM63Us2983Gqa5gFSXNsE3ascRpFxfc@$mockBox';
