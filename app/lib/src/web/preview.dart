/// The wallet a `WFE_WEB_FAKE=true` web build shows: [FakeWalletService] with the desktop
/// Overview's numbers and payments, outputs, contacts, two invoices to pay and two requests
/// sent, so every phone screen can be previewed in a browser with no server. Nothing here talks
/// to the network. No release script sets the define.
library;

import '../wallet_service.dart';

/// `--dart-define=WFE_WEB_FAKE=true`: the web app runs on [previewWalletService].
const bool webFakeBackend = bool.fromEnvironment('WFE_WEB_FAKE');

/// A fresh fake wallet service. The visitor starts at first run; the PIN they choose opens the
/// preview wallet.
FakeWalletService previewWalletService() =>
    FakeWalletService(session: _previewSession())
      // Ahead of the live directory's height for a long while, so the status card reads
      // Synced rather than Behind.
      ..nodeTipValue = NodeTip(height: _tip, nodeVersion: '4.1.1');

final BigInt _tip = BigInt.from(3900000);

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

/// A valid-looking epicbox address: 52 base58 characters, then the relay. The tour's helper.
String _address(String seed, {String relay = 'epicbox.epiccash.com'}) {
  const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  final buffer = StringBuffer('es');
  var n = seed.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0x7fffffff);
  while (buffer.length < 52) {
    n = (n * 1103515245 + 12345) & 0x7fffffff;
    buffer.write(alphabet[n % alphabet.length]);
  }
  return '$buffer@$relay';
}

/// A 66-character commitment from a seed.
String _commit(String seed) {
  const hex = '0123456789abcdef';
  final buffer = StringBuffer('09');
  var n = seed.codeUnits.fold<int>(11, (a, c) => (a * 31 + c) & 0x7fffffff);
  while (buffer.length < 66) {
    n = (n * 1103515245 + 12345) & 0x7fffffff;
    buffer.write(hex[n % 16]);
  }
  return buffer.toString();
}

FakeWalletSession _previewSession() {
  final tip = _tip;
  final anna = _address('anna');
  final btlabs = _address('btlabs');
  final exchange = _address('exchange');
  final coffee = _address('coffee');
  final pool = _address('pool');
  final tom = _address('tom');
  final biller = _address('northwind', relay: 'epicbox.example.com');
  final now = DateTime.now();
  int ago(Duration d) => now.subtract(d).millisecondsSinceEpoch ~/ 1000;
  final session = FakeWalletSession(
    summary: WalletSummary(
      lastConfirmedHeight: tip,
      minimumConfirmations: BigInt.from(3),
      total: _epic(1327.44515),
      spendable: _epic(1284.73215),
      awaitingConfirmation: _epic(25),
      awaitingFinalization: _epic(12.5),
      immature: _epic(2),
      locked: _epic(15.713),
      validatedWithNode: true,
    ),
    transactions: [
      fakeTx(
        id: 34,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000034',
        kind: TxKind.received,
        status: TxStatus.awaitingConfirmation,
        createdAtUnix: ago(const Duration(minutes: 4)),
        amountCredited: _epic(25),
        numOutputs: 1,
        counterparty: anna,
        messages: const [
          SlateMessage(role: SlateRole.sender, text: 'Lunch, thanks'),
        ],
        blockHeight: tip - BigInt.one,
      ),
      fakeTx(
        id: 33,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000033',
        kind: TxKind.sent,
        status: TxStatus.awaitingRecipient,
        createdAtUnix: ago(const Duration(hours: 2, minutes: 40)),
        amountDebited: _epic(12.507),
        amountCredited: BigInt.zero,
        fee: _epic(0.007),
        numInputs: 1,
        numOutputs: 0,
        counterparty: tom,
        note: 'Second half',
        cancellable: true,
      ),
      fakeTx(
        id: 32,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000032',
        kind: TxKind.sent,
        status: TxStatus.awaitingConfirmation,
        createdAtUnix: ago(const Duration(hours: 4, minutes: 40)),
        amountDebited: _epic(3.206),
        amountCredited: _epic(12.5),
        fee: _epic(0.006),
        numInputs: 1,
        numOutputs: 1,
        counterparty: coffee,
      ),
      fakeTx(
        id: 31,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000031',
        kind: TxKind.received,
        status: TxStatus.confirmed,
        createdAtUnix: ago(const Duration(days: 1, hours: 1, minutes: 40)),
        amountCredited: _epic(148.73215),
        numOutputs: 1,
        counterparty: pool,
        blockHeight: tip - BigInt.from(1200),
        blockTimeUnix: ago(const Duration(days: 1, hours: 1, minutes: 40)),
        kernelExcess: _commit('kernel-31').replaceFirst('09', '08'),
        outputCommits: [_commit('out-31')],
      ),
      fakeTx(
        id: 30,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000030',
        kind: TxKind.sent,
        status: TxStatus.confirmed,
        createdAtUnix: ago(const Duration(days: 2, hours: 5)),
        amountDebited: _epic(40.008),
        amountCredited: _epic(34.73215),
        fee: _epic(0.008),
        numInputs: 2,
        numOutputs: 1,
        counterparty: tom,
        note: 'Old laptop',
        blockHeight: tip - BigInt.from(2900),
      ),
      fakeTx(
        id: 29,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000029',
        kind: TxKind.sentCancelled,
        status: TxStatus.cancelled,
        createdAtUnix: ago(const Duration(days: 3, hours: 1)),
        amountDebited: _epic(5.006),
        fee: _epic(0.006),
        numInputs: 1,
        counterparty: exchange,
      ),
      fakeTx(
        id: 28,
        kind: TxKind.coinbase,
        status: TxStatus.confirmed,
        createdAtUnix: ago(const Duration(days: 4)),
        amountCredited: _epic(2),
        blockHeight: tip - BigInt.from(5700),
      ),
      fakeTx(
        key: 'c:restored-1',
        id: 2,
        kind: TxKind.received,
        status: TxStatus.confirmed,
        source: TxSource.restored,
        createdAtUnix: ago(const Duration(days: 6)),
        timeUnix: ago(const Duration(days: 40)),
        blockHeight: tip - BigInt.from(57600),
        blockTimeUnix: ago(const Duration(days: 40)),
        amountCredited: _epic(7.5),
        outputCommits: [_commit('out-2')],
      ),
    ],
  );
  session.address = _address('me');
  session.contactsValue.addAll([
    Contact(id: 'c1', name: 'Anna Kowalska', address: anna, note: 'Flatmate'),
    Contact(id: 'c2', name: 'BT Labs', address: btlabs),
    Contact(id: 'c3', name: 'Exchange deposit', address: exchange),
    Contact(id: 'c4', name: 'Merchant: Coffee', address: coffee),
    Contact(id: 'c5', name: 'Mining pool payouts', address: pool),
    Contact(id: 'c6', name: 'Tom', address: tom, note: 'Pays by file'),
  ]);
  // The outputs the balance is made of, as the desktop's Outputs page shows them.
  WalletOutput output(
    String seed,
    num value, {
    required int age,
    WalletOutputStatus status = WalletOutputStatus.unspent,
    OutputCategory? category = OutputCategory.spendable,
    bool coinbase = false,
    int? txId,
  }) => WalletOutput(
    commitment: _commit(seed),
    value: _epic(value),
    status: status,
    category: category,
    isCoinbase: coinbase,
    height: tip - BigInt.from(age),
    lockHeight: tip - BigInt.from(age) + (coinbase ? BigInt.from(1440) : BigInt.zero),
    mmrIndex: BigInt.from(7000000 - age),
    confirmations: status == WalletOutputStatus.unconfirmed
        ? BigInt.zero
        : BigInt.from(age + 1),
    txId: txId,
  );
  session.outputsValue.addAll([
    output('o1', 500, age: 1205, txId: 2),
    output('o2', 412.5, age: 620),
    output('o3', 212.5, age: 89, txId: 31),
    output('o4', 125, age: 42),
    output('o5', 34.73215, age: 301, txId: 30),
    output(
      'o6',
      25,
      age: 1,
      status: WalletOutputStatus.unconfirmed,
      category: OutputCategory.awaitingConfirmation,
      txId: 34,
    ),
    output(
      'o7',
      12.5,
      age: 0,
      status: WalletOutputStatus.unconfirmed,
      category: OutputCategory.awaitingFinalization,
      txId: 32,
    ),
    output(
      'o8',
      15.713,
      age: 350,
      status: WalletOutputStatus.locked,
      category: OutputCategory.locked,
      txId: 33,
    ),
    output(
      'o9',
      2,
      age: 5700,
      category: OutputCategory.immature,
      coinbase: true,
      txId: 28,
    ),
  ]);
  // Two invoices from a trusted service, and two requests this wallet sent.
  session
      .addTrustedService(address: biller, label: 'Northwind Exchange')
      .then((_) {
        session
          ..relayInvoice(
            from: biller,
            slateId: 'inv-1042',
            amount: _epic(42.5),
            message: 'Order 1042: 2 x hosting, October',
            expiresIn: const Duration(hours: 23, minutes: 12),
          )
          ..relayInvoice(
            from: biller,
            slateId: 'inv-1043',
            amount: _epic(7),
            message: 'Withdrawal fee',
            expiresIn: const Duration(minutes: 38),
          );
      })
      .then(
        (_) => session.issueInvoice(
          amount: _epic(25),
          address: anna,
          message: 'Concert tickets, Friday',
        ),
      )
      .then(
        (_) => session.issueInvoice(
          amount: _epic(12),
          address: anna,
          message: 'Pizza',
        ),
      )
      .then((request) => session.payIssued(request.slateId));
  return session;
}
