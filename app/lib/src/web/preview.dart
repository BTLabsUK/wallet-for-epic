/// The wallet a `WFE_WEB_FAKE=true` web build shows: [FakeWalletService] with a slice of the
/// screenshot tour's data (`tool/screenshot_tour_test.dart`), so the web app can be previewed
/// with no server. Nothing here talks to the network. No release script sets the define.
library;

import '../wallet_service.dart';

/// `--dart-define=WFE_WEB_FAKE=true`: the web app runs on [previewWalletService].
const bool webFakeBackend = bool.fromEnvironment('WFE_WEB_FAKE');

/// A fresh fake wallet service. The visitor starts at first run; the PIN they choose opens the
/// preview wallet.
FakeWalletService previewWalletService() =>
    FakeWalletService(session: _previewSession());

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

/// A valid-looking epicbox address: 52 base58 characters, then the relay. The tour's helper.
String _address(String seed) {
  const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  final buffer = StringBuffer('es');
  var n = seed.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0x7fffffff);
  while (buffer.length < 52) {
    n = (n * 1103515245 + 12345) & 0x7fffffff;
    buffer.write(alphabet[n % alphabet.length]);
  }
  return '$buffer@flooepicbox.btlabs.uk';
}

FakeWalletSession _previewSession() {
  final tip = BigInt.from(2500000);
  final alice = _address('alice');
  final bob = _address('bob');
  final now = DateTime.now();
  int ago(Duration d) => now.subtract(d).millisecondsSinceEpoch ~/ 1000;
  final session = FakeWalletSession(
    summary: WalletSummary(
      lastConfirmedHeight: tip,
      minimumConfirmations: BigInt.one,
      total: _epic(172.5),
      spendable: _epic(160),
      awaitingConfirmation: _epic(12.5),
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: BigInt.zero,
      validatedWithNode: true,
    ),
    transactions: [
      fakeTx(
        id: 4,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000004',
        kind: TxKind.received,
        status: TxStatus.awaitingConfirmation,
        createdAtUnix: ago(const Duration(minutes: 3)),
        amountCredited: _epic(12.5),
        counterparty: bob,
      ),
      fakeTx(
        id: 3,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000003',
        kind: TxKind.sent,
        status: TxStatus.confirmed,
        createdAtUnix: ago(const Duration(hours: 2)),
        amountDebited: _epic(40),
        amountCredited: _epic(29.992),
        fee: _epic(0.008),
        numInputs: 1,
        counterparty: alice,
        note: 'Coffee',
        blockHeight: tip - BigInt.from(120),
      ),
      fakeTx(
        id: 2,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000002',
        kind: TxKind.received,
        status: TxStatus.confirmed,
        createdAtUnix: ago(const Duration(days: 1)),
        amountCredited: _epic(170),
        counterparty: alice,
        blockHeight: tip - BigInt.from(1400),
      ),
    ],
  );
  session.address = _address('me');
  session.contactsValue.addAll([
    Contact(id: 'c1', name: 'Alice', address: alice),
    Contact(id: 'c2', name: 'Bob', address: bob),
  ]);
  return session;
}
