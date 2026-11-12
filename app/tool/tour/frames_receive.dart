// SPDX-License-Identifier: Apache-2.0
// Designer-frame visits: Receive (Receive-*, Gap-1-Request, InPerson-*, Gap-3-InPerson-Done, File-1-Made,
// Gap-4-File-Open, Gap-5-File-Reply). See tool/tour/FRAMES.md.
part of '../screenshot_tour_test.dart';

/// The frames' own address: `esVeVU…3es6TA@epicbox.epiccash.com`.
final String _fMe = 'esVeVUhWwJT4HcFNwCw8wxqauG3SoQ3aKABLyaXWq6HUZ83es6TA@$mockBox';

/// Receive's own screen (the arriving sheet closed), on the frames' address.
/// Frames drawn for a classic wallet (the address, not the epic1 link); the rest of the tour's frames are epic1.
final Set<String> _frameClassic = {
  'fr-Receive-1',
  'fr-Receive-2-Ask',
  'fr-Receive-3-Arriving',
  'fr-Receive-4-Other',
  'fr-Gap-1-Request',
  'fr-InPerson-1-Show',
  'fr-InPerson-2-Scan',
  'fr-InPerson-3-Accept',
  'fr-InPerson-4-Answer',
  'fr-Gap-3-InPerson-Done',
  'fr-File-1-Made',
  'fr-Gap-4-File-Open',
  'fr-Gap-5-File-Reply',
};

/// The payment of InPerson-3 and -4 and of Gap-5: 12.5 EPIC, "For the concert tickets".
const String _fInJson = '{"id":"frame-in"}';

void _fInSlate(_Tour t) {
  t.service.slateInfos[_fInJson] = SlateInfo(
    slateId: 'frame-in',
    amount: _epic(12.5),
    fee: BigInt.zero,
    stage: SlateStage.send,
    messages: const [SlateMessage(role: SlateRole.sender, text: 'For the concert tickets')],
  );
  t.session.responseSlate = const Slate(slateId: 'frame-in', json: '{"id":"frame-in","step":"response"}');
}

/// Pay in person: Send, the amount, the code made.
Future<void> _fPayMake(_Tour t) async {
  await _directWaysOn(t);
  await t.tapText(t.l.homeSendButton);
  await t.tapText(t.l.sendNoAddress);
  await t.tapText(t.l.phoneSendInPerson);
  await t.enter(t.l.sendAmountLabel('EPIC'), localDecimal(t.l, '12.5'));
  await t.tap(find.text(t.l.sendMakeQr));
  await t.enterPin();
}

/// Pay in person: the code made and shown.
Future<void> _fPayShow(_Tour t) async {
  await _fPayMake(t);
  await t.tap(find.byKey(qrShowButtonKey));
  // The frame shows the code 2 s into its 40 s countdown ("Hides in 38 s").
  await t.elapse(1300);
  await t.elapse(700);
}

Future<void> _frameReceive(_Tour t) async {
  await t.openReceive();
}

final List<(String, _Start, _Visit)> _framesReceive = [
  ('fr-Receive-1', _Start.home, (t) async {
    await _frameReceive(t);
    await t.shot('fr-Receive-1');
  }),
  ('fr-Receive-2-Ask', _Start.home, (t) async {
    await _frameReceive(t);
    await t.tapText(t.l.phoneRecvAsk);
    for (final c in '25'.split('')) {
      await t.tap(find.descendant(of: find.byType(KitKeypad), matching: find.text(c)));
    }
    await t.tapText(t.l.phonePayAddNote);
    await t.enter(t.l.requestMessageLabel, 'Dinner');
    await t.tapText(t.l.commonDone);
    await t.shot('fr-Receive-2-Ask');
  }),
  ('fr-Receive-3-Arriving', _Start.home, (t) async {
    await t.tapText(t.l.homeReceiveButton);
    await t.frames();
    await t.shot('fr-Receive-3-Arriving');
  }),
  ('fr-Receive-5-epic1', _Start.home, (t) async {
    await _frameReceive(t);
    await t.shot('fr-Receive-5-epic1');
  }),
  ('fr-Gap-1-Request', _Start.home, (t) async {
    await _frameReceive(t);
    await t.tapText(t.l.phoneRecvAsk);
    for (final c in '25'.split('')) {
      await t.tap(find.descendant(of: find.byType(KitKeypad), matching: find.text(c)));
    }
    await t.tapText(t.l.phonePayAddNote);
    await t.enter(t.l.requestMessageLabel, 'Dinner');
    await t.tapText(t.l.commonDone);
    // With a camera the page opens on the in-person code; the file variant is the request page.
    await t.tapText(t.l.phoneRecvFromAnyone);
    await t.tapText(t.l.phoneRecvAnyoneFile);
    await t.tap(find.textContaining('Ask for 25'));
    await t.images();
    await t.shot('fr-Gap-1-Request');
  }),
  ('fr-InPerson-1-Show', _Start.home, (t) async {
    await _fPayShow(t);
    await t.shot('fr-InPerson-1-Show');
  }),
  ('fr-InPerson-2-Scan', _Start.home, (t) async {
    await _fPayShow(t);
    await t.tap(find.byKey(qrNextButtonKey));
    await t.frames();
    await t.shot('fr-InPerson-2-Scan');
  }),
  ('fr-InPerson-3-Accept', _Start.home, (t) async {
    _fInSlate(t);
    await t.push(const SlateFileScreen(file: SlateFile(name: scannedSlateName, json: _fInJson), pasted: true, scanned: true));
    await t.shot('fr-InPerson-3-Accept');
  }),
  ('fr-InPerson-4-Answer', _Start.home, (t) async {
    _fInSlate(t);
    await t.push(const SlateFileScreen(file: SlateFile(name: scannedSlateName, json: _fInJson), pasted: true, scanned: true));
    await t.tapText(t.l.phoneAcceptAccept);
    await t.tap(find.byKey(showReplyQrKey));
    await t.tap(find.byKey(qrShowButtonKey));
    await t.elapse(1300);
    await t.elapse(700);
    await t.shot('fr-InPerson-4-Answer');
  }),
  ('fr-Gap-3-InPerson-Done', _Start.home, (t) async {
    await _fPayMake(t);
    await t.frames();
    await t.shot('fr-Gap-3-InPerson-Done');
  }),
  ('fr-File-1-Made', _Start.home, (t) async {
    frameClockAt = DateTime(2026, 11, 12, 18, 12);
    await _directWaysOn(t);
    await t.tapText(t.l.homeSendButton);
    await t.tapText(t.l.sendNoAddress);
    await t.tapText(t.l.phoneSendWithFile);
    await t.enter(t.l.sendAmountLabel('EPIC'), localDecimal(t.l, '12.5'));
    await t.tap(find.text(t.l.sendMakeFile));
    await t.enterPin();
    await t.shot('fr-File-1-Made');
  }),
  ('fr-Gap-4-File-Open', _Start.home, (t) async {
    await _directWaysOn(t);
    await _frameReceive(t);
    await t.receiveWay(t.l.phoneSettingsWithFile);
    await t.shot('fr-Gap-4-File-Open');
  }),
  ('fr-Gap-5-File-Reply', _Start.home, (t) async {
    frameClockAt = DateTime(2026, 11, 12, 18, 20);
    _fInSlate(t);
    await t.push(const SlateFileScreen(file: SlateFile(name: 'from-tom.tx', json: _fInJson)));
    await t.tapText(t.l.phoneAcceptAccept);
    await t.shot('fr-Gap-5-File-Reply');
  }),
  ('fr-Receive-4-Other', _Start.home, (t) async {
    await _directWaysOn(t);
    await _frameReceive(t);
    await t.tapText(t.l.phoneRecvOther);
    await t.shot('fr-Receive-4-Other');
  }),
];

/// Per-frame data on top of the base wallet (frame_data.dart), by visit name.
final Map<String, void Function(FakeWalletSession s)> _receiveSeeds = {
  for (final name in _frameClassic) name: (s) => s.address = _fMe,
  // The payment is already posted when the code page opens: it shows the finished page.
  'fr-Gap-3-InPerson-Done': (s) {
    s.address = _fMe;
    s.transactionsValue.add(
      fakeTx(
        id: 11,
        slateId: 'slate-1',
        kind: TxKind.sent,
        status: TxStatus.awaitingConfirmation,
        createdAtUnix: _at(0, 14, 50),
        timeUnix: _at(0, 14, 50),
        amountDebited: _epic(12.508),
        fee: _epic(0.008),
        numInputs: 1,
        blockHeight: _tip,
      ),
    );
  },
  'fr-Receive-3-Arriving': (s) {
    s.address = _fMe;
    s.transactionsValue.add(
      fakeTx(
        id: 10,
        slateId: 'f0000000-0000-4000-8000-000000000010',
        kind: TxKind.received,
        status: TxStatus.awaitingConfirmation,
        createdAtUnix: _at(0, 17, 30),
        timeUnix: _at(0, 17, 30),
        amountCredited: _epic(12.5),
        numOutputs: 1,
        counterparty: _fBob,
        blockHeight: _tip - BigInt.one,
      ),
    );
  },
};
