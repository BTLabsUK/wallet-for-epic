// SPDX-License-Identifier: Apache-2.0
// Two devices of one wallet over the fake pairing engine's shared private net, for the linked
// devices tests.

import 'package:epic_wallet/src/devices/device_service.dart';
import 'package:epic_wallet/src/devices/device_store.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart';

/// A 66-character commitment for [i].
String cm(int i) => '08${i.toRadixString(16).padLeft(64, '0')}';

WalletOutput coin(int i, int epic, {WalletOutputStatus status = WalletOutputStatus.unspent, int? txId}) => WalletOutput(
  commitment: cm(i),
  value: BigInt.from(epic) * BigInt.from(100000000),
  status: status,
  category: status == WalletOutputStatus.unspent ? OutputCategory.spendable : null,
  isCoinbase: false,
  height: BigInt.from(100),
  lockHeight: BigInt.from(100),
  confirmations: BigInt.from(10),
  txId: txId,
);

class Clock {
  DateTime now = DateTime.utc(2026, 10, 27, 12);
  DateTime call() => now;
}

class Side {
  Side(this.name, {required this.clock, required FakePrivateNet net, String key = 'esSameWalletKey'}) {
    session.address = '$key@epicbox.epiccash.com';
    session.pairing.privateNet = net;
    session.pairing.clock = clock.call;
    session.outputsValue = [coin(1, 5), coin(2, 3), coin(3, 2)];
    session.summaryValue = WalletSummary(
      lastConfirmedHeight: BigInt.from(1000),
      minimumConfirmations: BigInt.from(10),
      total: BigInt.from(1000000000),
      spendable: BigInt.from(1000000000),
      awaitingConfirmation: BigInt.zero,
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: BigInt.zero,
      validatedWithNode: true,
    );
    service = DeviceService(
      host: SessionDeviceHost(session),
      store: DeviceStore(store, chain: Chain.floonet),
      defaultName: name,
      clock: clock.call,
    );
  }

  final String name;
  final Clock clock;
  final FakeWalletSession session = FakeWalletSession();
  final MemorySecretStore store = MemorySecretStore();
  late final DeviceService service;

  FakePairing get pairing => session.pairing;

  Future<void> sync() => service.sync(DeviceSyncTrigger.tick);
}

/// Reads both channels a few times, as the 5 s runs would.
Future<void> settle(Side a, Side b, {int rounds = 3}) async {
  for (var i = 0; i < rounds; i++) {
    await a.sync();
    await b.sync();
  }
}

/// [a] shows a code on [servers], [b] scans it; both reach the pictures.
Future<void> showAndScan(Side a, Side b, {List<String> servers = const ['epicbox.epiccash.com']}) async {
  await a.service.load();
  await b.service.load();
  await a.service.startShowing(servers);
  await b.service.startScanned(a.service.link!.code!);
  await settle(a, b);
}

/// A full link: both check the pictures.
Future<void> linkBoth(Side a, Side b, {List<String> servers = const ['epicbox.epiccash.com']}) async {
  await showAndScan(a, b, servers: servers);
  await a.service.answerCheck(true);
  await settle(a, b);
  await b.service.answerCheck(true);
  await settle(a, b);
}
