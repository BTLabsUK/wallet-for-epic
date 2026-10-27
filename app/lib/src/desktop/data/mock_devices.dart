/// The other device of the prototype's linked devices: a phone that holds the mock wallet,
/// played over the fake pairing engine the mock wallet and the phone share. The screenshot tour
/// and the desktop tests link it to the computer, make it pay, and read the computer's side.
library;

import '../../devices/device_service.dart';
import '../../devices/device_store.dart';
import '../../secret_store_api.dart';
import '../../wallet_service.dart';
import 'mock_wallet.dart';

class MockPhone {
  MockPhone._(this.service, this.session);

  /// The phone's own device service (its own book, its own fake wallet).
  final DeviceService service;
  final FakeWalletSession session;

  /// A phone holding the same wallet as [wallet]: the same coins, the same payments key, on the
  /// network the mock's pairing engine uses.
  static Future<MockPhone> create(MockDeskWallet wallet, {String name = 'Phone'}) async {
    final session = FakeWalletSession();
    session.address = '$mockEpicboxKey@epicbox.epiccash.com';
    session.pairing.privateNet = wallet.pairing.privateNet;
    session.pairing.clock = wallet.pairing.clock;
    session.outputsValue = [
      for (final o in await wallet.walletOutputs())
        if (o.status == WalletOutputStatus.unspent) o,
    ];
    final service = DeviceService(
      host: SessionDeviceHost(session),
      store: DeviceStore(MemorySecretStore(), chain: Chain.mainnet),
      defaultName: name,
      clock: wallet.pairing.clock,
    );
    await service.load();
    return MockPhone._(service, session);
  }

  /// Both devices read the channel [rounds] times, as their 5 s runs would.
  Future<void> rounds(DeviceService desk, {int rounds = 3}) async {
    for (var i = 0; i < rounds; i++) {
      await desk.sync(DeviceSyncTrigger.tick);
      await service.sync(DeviceSyncTrigger.tick);
    }
  }

  /// The phone scans the code [desk] shows; both reach the four pictures.
  Future<void> scan(DeviceService desk) async {
    await service.startScanned(desk.link!.code!);
    await rounds(desk);
  }

  /// A whole link: [desk] shows a code on [servers], the phone scans it, both check the pictures.
  Future<void> link(DeviceService desk, {List<String> servers = const ['epicbox.epiccash.com']}) async {
    await desk.startShowing(servers);
    await scan(desk);
    await desk.answerCheck(true);
    await rounds(desk);
    await service.answerCheck(true);
    await rounds(desk);
  }

  /// The phone starts paying [epic] EPIC to [to] with the coin [commitment]: its coin is locked
  /// by the payment, and the computer hears of it.
  Future<void> pay(
    DeviceService desk, {
    required String commitment,
    String slateId = '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d',
    int txId = 41,
    String to = 'esQ7mPz3xKd9aVw2nT5uYhL8cRb4gF6jXe@epicbox.epiccash.com',
    String? message,
    int fee = 800000,
  }) async {
    final coin = session.outputsValue.firstWhere((o) => o.commitment == commitment);
    session.outputsValue = [
      for (final o in session.outputsValue)
        if (o.commitment == commitment)
          WalletOutput(
            commitment: o.commitment,
            value: o.value,
            status: WalletOutputStatus.locked,
            category: null,
            isCoinbase: false,
            height: o.height,
            lockHeight: o.lockHeight,
            confirmations: o.confirmations,
            txId: txId,
          )
        else
          o,
    ];
    session.transactionsValue = [
      ...session.transactionsValue,
      fakeTx(
        id: txId,
        slateId: slateId,
        kind: TxKind.sent,
        status: TxStatus.awaitingRecipient,
        createdAtUnix: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        amountDebited: coin.value,
        amountCredited: BigInt.zero,
        fee: BigInt.from(fee),
        counterparty: to,
        transport: 'epicbox',
        messages: [if (message != null) SlateMessage(role: SlateRole.sender, text: message)],
      ),
    ];
    await service.announceNow();
    await rounds(desk);
  }
}
