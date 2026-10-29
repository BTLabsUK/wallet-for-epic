// SPDX-License-Identifier: Apache-2.0
// Live: a sender's cancel reaches the receiver over Epicbox, on floonet with the real LEPIC core.
// The sender's listener is off while the receiver answers, as on a phone in the background; the
// sender cancels, then listens again and finds the late answer: it tells the receiver, and the
// receiver (the desktop adapter) reads Cancelled by the sender and releases the payment by
// itself. The sender is funded by the QA funder (/opt/epic/qa-funder), which needs a floonet
// miner for its confirmations. Throwaway wallets; prints no phrase, password or address.
//
//   WFE_DEMO_LEPIC_LIB=<path to liblepic_ffi.so> WFE_FLOO_FUND=<path to fund.sh> \
//   [WFE_LIVE_RELAY=epicbox.stackwallet.com] flutter test test/desktop/sender_cancel_live_test.dart
//
// Without them it is skipped.
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:flutter_test/flutter_test.dart';

final String? _lib = Platform.environment['WFE_DEMO_LEPIC_LIB'];
final String? _fund = Platform.environment['WFE_FLOO_FUND'];
final String _relay = Platform.environment['WFE_LIVE_RELAY'] ?? 'epicbox.stackwallet.com';

const _password = 'sender-cancel-live-1';
final _nano = BigInt.from(100000000);

void log(String s) {
  // ignore: avoid_print
  print('${DateTime.now().toIso8601String().substring(11, 19)} $s');
}

Future<T> until<T>(String what, Duration limit, Future<T?> Function() probe) async {
  final end = DateTime.now().add(limit);
  while (DateTime.now().isBefore(end)) {
    final v = await probe();
    if (v != null) return v;
    await Future<void>.delayed(const Duration(seconds: 5));
  }
  throw TimeoutException('waited ${limit.inMinutes} min for $what');
}

void main() {
  late Directory tmp;

  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
  });
  setUp(() async => tmp = await Directory.systemTemp.createTemp('desk-sender-cancel-live-'));
  tearDown(() => tmp.delete(recursive: true));

  test('the sender cancels with the answer unread; the receiver reads Cancelled by the sender and releases it', () async {
    // The sender: a plain session on the funder's relay, listening for its funds.
    final secrets = MemorySecretStore({'app.node.floonet': floonetPreset.nodeUrl});
    final service = LepicWalletService(secrets: MemorySecretStore());
    final aDir = Directory('${tmp.path}/a')..createSync();
    final a = await service.create(config: floonetPreset.config(dataDir: aDir.path, nodeUrl: floonetPreset.nodeUrl), password: _password);
    addTearDown(a.dispose);
    var listening = a.startListener().listen((e) => log('A listener ${e.kind.name}'), onError: (Object e) => log('A listener error ${e.runtimeType}'));
    final fund = await Process.run(_fund!, [await a.epicboxAddress(), '3']);
    log('funded: exit ${fund.exitCode}');
    expect(fund.exitCode, 0, reason: '${fund.stderr}');
    await until('the sender\'s funds to confirm', const Duration(minutes: 20), () async {
      final s = await a.summary(refresh: true, minimumConfirmations: BigInt.one);
      log('A spendable ${s.spendable}');
      return s.spendable >= _nano * BigInt.two ? s : null;
    });

    // The receiver: the desktop adapter, listening on another relay.
    final b = LepicDeskWallet(
      preset: floonetPreset,
      service: LepicWalletService(secrets: secrets, oneWalletPerChain: true),
      walletDir: (chain) async {
        final d = Directory(WalletRegistry.firstWalletDir('${tmp.path}/b', chain));
        await d.create(recursive: true);
        return d.path;
      },
      secrets: secrets,
      filesDir: () async => Directory('${tmp.path}/b')..createSync(recursive: true),
      rememberDir: () async => Directory('${tmp.path}/b/remember'),
      listProcesses: () async => const [],
    );
    addTearDown(b.dispose);
    await b.createWallet(name: 'Desktop', password: _password);
    expect(await b.unlock(_password), isTrue);
    await b.useEpicbox(_relay);
    await b.setEpicboxListening(true);
    final to = await b.epicboxAddress();
    log('B listens on $_relay');

    // The sender's listener is off while the receiver answers.
    await a.stopListener().timeout(const Duration(seconds: 30));
    log('A listener stopped');
    unawaited(listening.cancel());
    final sent = await a
        .sendEpicbox(amount: _nano, minimumConfirmations: BigInt.one, address: to, message: 'sender cancel live')
        .timeout(const Duration(minutes: 2));
    log('A sent ${sent.slateId}');
    final waiting = await until('the receiver to answer', const Duration(minutes: 5), () async {
      final row = (await b.transactions()).where((t) => t.slateId == sent.slateId).firstOrNull;
      return row != null && row.state == TxState.waitingRecipient ? row : null;
    });
    log('B answered: ${waiting.state.name}');
    await Future<void>.delayed(const Duration(seconds: 10));

    await a.cancelTransaction(txId: sent.id!);
    log('A cancelled');
    listening = a.startListener().listen((e) => log('A listener ${e.kind.name}'), onError: (Object e) => log('A listener error ${e.runtimeType}'));
    // The listener stops first: cancelling its stream while it runs does not return.
    addTearDown(() async {
      await a.stopListener().timeout(const Duration(seconds: 30));
      unawaited(listening.cancel());
    });

    final released = await until('the receiver to release it', const Duration(minutes: 5), () async {
      final row = (await b.transactions()).where((t) => t.slateId == sent.slateId).firstOrNull;
      log('B row: ${row?.state.name} senderCancelled ${row?.senderCancelled}');
      return row != null && row.senderCancelled && row.state == TxState.cancelled ? row : null;
    });
    expect(released.senderCancelled, isTrue);

    // The late answer was never finalized: the sender's payment stays cancelled.
    final mine = (await a.transactions(refresh: true)).where((t) => t.slateId == sent.slateId).single;
    log('A row: ${mine.kind.name}/${mine.status.name}');
    expect(mine.kind, TxKind.sentCancelled);
  }, skip: _lib == null || _fund == null ? 'needs WFE_DEMO_LEPIC_LIB and WFE_FLOO_FUND' : false, timeout: const Timeout(Duration(minutes: 40)));
}
