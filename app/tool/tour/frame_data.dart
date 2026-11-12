// SPDX-License-Identifier: Apache-2.0
// The designer frames' sample wallet (tool/tour/FRAMES.md): the names, amounts, notes and dates the
// frames draw, and the clock they were drawn on. One base wallet, then a seed per frame.
part of '../screenshot_tour_test.dart';

/// The frames' size, density and safe areas (390x844, shots 780x1688).
const Size _frameSize = Size(390, 844);
const double _framePixelRatio = 2;
const double _frameInsetTop = 54;
const double _frameInsetBottom = 34;

/// Thursday 12 November 2026, 14:52: "Today 14:48", "Yesterday", "Monday" (9 Nov) and "2 Nov" all
/// come out as drawn.
final DateTime frameNow = DateTime(2026, 11, 12, 14, 52);

/// The frames' rate: 1,284.7321 EPIC is $1,327.13, 25.0 is $25.82, 42.5 is $43.90.
class _FramePrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => 1.0329999;
}

int _unix(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

/// A time [day] days before [frameNow], at [hour]:[minute].
int _at(int day, int hour, int minute) =>
    _unix(DateTime(frameNow.year, frameNow.month, frameNow.day - day, hour, minute));

final String _fAnna = _address('anna-kowalska');
final String _fTom = _address('tom');
final String _fCoffee = _address('coffee-corner');
final String _fBob = _address('bob-frame');
final String _fMira = _address('mira-novak');
final String _fNorthwind = _address('northwind-exchange');

/// `esnw2M…6yCmnK`: the address row of Home, Activity and the payment pages.
final String _fUnknown = 'esnw2M${'k' * 40}6yCmnK@$mockBox';

/// Every area's seeds, joined in one place.
final Map<String, void Function(FakeWalletSession s)> _frameSeeds = {
  ..._homeSeeds,
  ..._sendSeeds,
  ..._receiveSeeds,
  ..._activitySeeds,
  ..._settingsSeeds,
  ..._startSeeds,
  ..._noticesSeeds,
};

/// Every area's visits, joined in one place; the tour runs them dark only.
List<(String, _Start, _Visit)> get frameVisits => [
  ..._framesHome,
  ..._framesSend,
  ..._framesReceive,
  ..._framesActivity,
  ..._framesSettings,
  ..._framesStart,
  ..._framesNotices,
];

/// A confirmed payment of the frames. [out]: sent (the fee is added to the debit).
TxEntry _fTx(
  int id, {
  required bool out,
  required num amount,
  required int at,
  String? who,
  String? note,
  bool sealed = false,
  TxStatus status = TxStatus.confirmed,
  int depth = 6000,
  bool pending = false,
  BigInt? height,
}) {
  final fee = out ? _epic(0.008) : BigInt.zero;
  // Awaiting confirmation: [depth] blocks under the tip (1: two confirmations), or (pending) not on chain yet.
  final onChain = !pending && status != TxStatus.cancelled && status != TxStatus.awaitingRecipient;
  return fakeTx(
    id: id,
    slateId: 'f0000000-0000-4000-8000-${id.toString().padLeft(12, '0')}',
    kind: out ? TxKind.sent : TxKind.received,
    status: status,
    createdAtUnix: at,
    timeUnix: at,
    blockHeight: height ?? (onChain ? _tip - BigInt.from(depth) : null),
    blockTimeUnix: status == TxStatus.confirmed ? at : null,
    amountDebited: out ? _epic(amount) + fee : BigInt.zero,
    amountCredited: out ? BigInt.zero : _epic(amount),
    fee: out ? fee : null,
    numInputs: out ? 1 : 0,
    counterparty: who,
    note: note,
    epic1Via: sealed ? Epic1Via.link : null,
  );
}

/// The base wallet every frame starts from: Home's balance, rows and contacts. A frame's seed in
/// [_frameSeeds] then changes what it draws differently.
FakeWalletSession frameSession(String visit) {
  final session = FakeWalletSession(
    summary: WalletSummary(
      lastConfirmedHeight: _tip,
      minimumConfirmations: BigInt.from(defaultMinimumConfirmations),
      total: parseEpic('1284.7321'),
      spendable: parseEpic('1284.7321'),
      awaitingConfirmation: BigInt.zero,
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: BigInt.zero,
      validatedWithNode: true,
    ),
    transactions: [
      _fTx(1, out: false, amount: 25.0, at: _at(0, 14, 48), who: _fAnna),
      _fTx(2, out: true, amount: 9.294, at: _at(0, 9, 12), who: _fCoffee, note: 'Coffee beans'),
      _fTx(3, out: true, amount: 12.5, at: _at(1, 18, 12), who: _fTom, sealed: true),
      _fTx(4, out: true, amount: 42.5, at: _at(3, 10, 5), who: _fNorthwind, note: 'Invoice paid'),
      _fTx(5, out: true, amount: 80.0, at: _at(10, 12, 30), who: _fUnknown),
    ],
  );
  session.address = _address('me');
  session.contactsValue.addAll([
    Contact(id: 'f-nw', name: 'Northwind Exchange', address: _fNorthwind),
    Contact(id: 'f-anna', name: 'Anna Kowalska', address: _fAnna),
    Contact(id: 'f-tom', name: 'Tom', address: _fTom),
    Contact(id: 'f-coffee', name: 'Coffee Corner', address: _fCoffee),
    Contact(id: 'f-bob', name: 'Bob', address: _fBob),
    Contact(id: 'f-mira', name: 'Mira Novak', address: _fMira),
  ]);
  _frameSeeds[visit]?.call(session);
  return session;
}
