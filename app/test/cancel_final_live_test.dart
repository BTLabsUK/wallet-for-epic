// SPDX-License-Identifier: Apache-2.0
// Live: Cancel makes a delivered invoice payment impossible to complete, on floonet with the real
// LEPIC core. B issues a payment request as a file, A pays it, and B holds A's signed answer (I2)
// without finishing it. A cancels: CancelFinal spends the coins the payment locked back to A.
// Once that confirms, B finalizes and posts the answer it holds, and the node refuses it: its
// inputs are spent. A second case cancels a plain send nobody answered: nothing is spent back.
//
// A is funded by the QA funder (/opt/epic/qa-funder) by slate file: the funder's CLI writes the
// send, A answers it, the funder finalizes and posts it, so no relay is needed. Confirmations
// need a floonet miner. Throwaway wallets; prints no phrase, password or address.
//
//   WFE_DEMO_LEPIC_LIB=<path to liblepic_ffi.so> WFE_FLOO_FUND=<path to fund.sh> \
//   flutter test test/cancel_final_live_test.dart
//
// Without them it is skipped.
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/cancel_final.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';


final String? _lib = Platform.environment['WFE_DEMO_LEPIC_LIB'];
final String? _fund = Platform.environment['WFE_FLOO_FUND'];
final String _funderDir = Platform.environment['QA_FUNDER_DIR'] ?? '${Platform.environment['HOME']}/.epic/qa-funder';

const _password = 'cancel-final-live-1';
final _nano = BigInt.from(100000000);

/// A fee far above any floonet fee of a one- or two-input transaction.
final _maxFee = BigInt.from(1000000);

void log(String s) {
  // ignore: avoid_print
  print('${DateTime.now().toIso8601String().substring(11, 19)} $s');
}

String epic(BigInt n) => (n.toDouble() / 1e8).toStringAsFixed(8);

String line(WalletSummary s) =>
    'total ${epic(s.total)} spendable ${epic(s.spendable)} awaitingConfirmation ${epic(s.awaitingConfirmation)} '
    'locked ${epic(s.locked)} height ${s.lastConfirmedHeight}';

Future<T> until<T>(String what, Duration limit, Future<T?> Function() probe, {Duration every = const Duration(seconds: 10)}) async {
  final end = DateTime.now().add(limit);
  while (DateTime.now().isBefore(end)) {
    final v = await probe();
    if (v != null) return v;
    await Future<void>.delayed(every);
  }
  throw TimeoutException('waited ${limit.inMinutes} min for $what');
}

/// The QA funder's CLI wallet, run in its own directory (it reads epic-wallet.toml from there),
/// the password passed only in the environment.
Future<ProcessResult> funder(List<String> args) async {
  final bin = '${File(_fund!).parent.path}/bin/epic-wallet';
  final pass = File('$_funderDir/.password').readAsStringSync().trim();
  return Process.run(
    bin,
    ['--floonet', '-t', _funderDir, ...args],
    workingDirectory: _funderDir,
    environment: {'EPIC_WALLET_PASS': pass},
  );
}

String tail(ProcessResult r) {
  final all = '${r.stdout}\n${r.stderr}'.trim().split('\n');
  return all.skip(all.length > 6 ? all.length - 6 : 0).join(' | ');
}

void main() {
  late Directory tmp;

  // Floonet's own hosts (tool/config/floonet/): its node first. The test settings name example
  // hosts only, and the shipped ones mainnet's.
  setUp(() {
    hostSettings = HostSettings.fromText(
      File('tool/config/floonet/settings.default.toml').readAsStringSync(),
      config: AppConfig.fromText(File('tool/config/floonet/app-config.toml').readAsStringSync()),
    );
  });

  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
  });
  setUp(() async => tmp = await Directory.systemTemp.createTemp('cancel-final-live-'));
  tearDown(() => tmp.delete(recursive: true));

  test('a cancelled invoice payment is spent back; the issuer can no longer post it', () async {
    final node = Platform.environment['WFE_LIVE_NODE'] ?? floonetPreset.nodeUrl;
    log('node $node');
    final service = LepicWalletService(secrets: MemorySecretStore());
    Future<WalletSession> wallet(String name) async {
      final dir = Directory('${tmp.path}/$name')..createSync();
      final s = await service.create(config: floonetPreset.config(dataDir: dir.path, nodeUrl: node), password: _password);
      addTearDown(s.dispose);
      await s.setMinimumConfirmations(1);
      return s;
    }

    final a = await wallet('a');
    final b = await wallet('b');
    final one = BigInt.one;

    // 1. Fund A by file: the funder sends, A answers, the funder finalizes and posts.
    final sendFile = '${tmp.path}/fund.slate';
    final answerFile = '${tmp.path}/fund.answer';
    await until('the funder to have coins to send', const Duration(minutes: 30), () async {
      final r = await funder(['send', '-m', 'file', '-d', sendFile, '3']);
      log('funder send: exit ${r.exitCode} ${r.exitCode == 0 ? '' : tail(r)}');
      return r.exitCode == 0 ? true : null;
    }, every: const Duration(seconds: 60));
    final answer = await a.receiveSlate(slateJson: File(sendFile).readAsStringSync());
    File(answerFile).writeAsStringSync(answer.json);
    final fin = await funder(['finalize', '-f', '-i', answerFile]);
    log('funder finalize: exit ${fin.exitCode} ${tail(fin)}');
    expect(fin.exitCode, 0, reason: 'the funder could not post the funding');
    final start = await until('A\'s funds to confirm', const Duration(minutes: 30), () async {
      final s = await a.summary(refresh: true, minimumConfirmations: one);
      log('A ${line(s)}');
      return s.spendable >= _nano * BigInt.two && s.awaitingConfirmation == BigInt.zero ? s : null;
    });
    log('step 1 A funded: ${line(start)}');

    // 2. B issues a request file for 1 EPIC; A pays it. B keeps A's answer (I2) unfinished.
    final request = await b.pairing.requestFile(amount: _nano, message: 'cancel final live');
    final paid = await a.payRequestFile(slateJson: request.json, amount: _nano);
    log('step 2 A paid the request: fee ${epic(paid.fee)}');
    final i2 = paid.json;
    final tx = (await a.transactions(refresh: true)).singleWhere((t) => t.slateId == request.slateId);
    log('A row ${tx.kind.name}/${tx.flow.name}/${tx.status.name}');
    expect(tx.kind, TxKind.sent);
    expect(tx.flow, TxFlow.invoice);
    expect(cancelSpendsBack(tx), isTrue);
    final lockedCoins = (await a.outputs()).where((o) => o.txId == tx.id && o.status == WalletOutputStatus.locked).toList();
    log('A coins locked by the payment: ${lockedCoins.length}');
    expect(lockedCoins, isNotEmpty);

    // 3. Cancel: spent back.
    final before = await a.summary(refresh: true, minimumConfirmations: one);
    log('step 3 A before cancel: ${line(before)}');
    final result = await CancelFinal().cancel(a, tx);
    log('step 3 cancel: ${result.name}');
    expect(result, CancelResult.spentBack);
    final totals = <BigInt>[];
    final rowAfter = (await a.transactions(refresh: true)).singleWhere((t) => t.slateId == request.slateId);
    log('A row after cancel ${rowAfter.kind.name}/${rowAfter.status.name}');
    expect(rowAfter.kind, TxKind.sentCancelled);
    final outs = await a.outputs();
    log('cancelFinal right after: ${cancelFinal(rowAfter, outs)}');
    expect(cancelFinal(rowAfter, outs), isTrue);
    for (final c in lockedCoins) {
      final now = outs.singleWhere((o) => o.commitment == c.commitment);
      log('locked coin now ${now.status.name}');
      expect(now.status, isNot(WalletOutputStatus.unspent));
    }

    // 4. The spend back confirms. Totals logged every poll.
    final end = await until('the spend back to confirm', const Duration(minutes: 30), () async {
      final s = await a.summary(refresh: true, minimumConfirmations: one);
      totals.add(s.total);
      final o = await a.outputs();
      log('A ${line(s)} cancelFinal ${cancelFinal(rowAfter, o)}');
      expect(cancelFinal(rowAfter, o), isTrue);
      return s.awaitingConfirmation == BigInt.zero && s.locked == BigInt.zero && s.spendable > BigInt.zero ? s : null;
    });
    final fee = start.spendable - end.spendable;
    log('step 4 spend back confirmed: ${line(end)}; spend back fee ${epic(fee)}');
    expect(fee > BigInt.zero && fee <= _maxFee, isTrue, reason: 'spend back fee ${epic(fee)}');
    expect(end.total, start.total - fee);
    for (final t in totals) {
      expect(t <= start.total, isTrue, reason: 'total ${epic(t)} above the start ${epic(start.total)}: counted twice');
      expect(t >= start.total - fee, isTrue, reason: 'total ${epic(t)} dropped more than the fee');
    }

    // 5. B finalizes and posts the I2 it holds: refused.
    Object? refusal;
    try {
      final posted = await b.finalizeAndPost(slateJson: i2);
      log('step 5 B finalizeAndPost returned ${posted.kind.name}/${posted.status.name}');
    } catch (e) {
      refusal = e;
      log('step 5 B finalizeAndPost refused: ${e is WalletError ? '${e.kind.name}: ${e.message}' : e}');
    }
    expect(refusal, isA<WalletError>(), reason: 'the node took a payment whose inputs were spent');
    // A few blocks later B still has nothing.
    final h = end.lastConfirmedHeight;
    await until('two more blocks', const Duration(minutes: 15), () async {
      final s = await b.summary(refresh: true, minimumConfirmations: one);
      log('B ${line(s)}');
      return s.lastConfirmedHeight >= h + BigInt.two ? s : null;
    });
    final bSum = await b.summary(refresh: true, minimumConfirmations: one);
    final bRow = (await b.transactions(refresh: true)).where((t) => t.slateId == request.slateId).firstOrNull;
    log('B row ${bRow?.kind.name}/${bRow?.status.name} confirmed ${bRow?.confirmed}; B ${line(bSum)}');
    expect(bSum.total, BigInt.zero);
    expect(bSum.spendable, BigInt.zero);
    expect(bRow?.confirmed ?? false, isFalse);
    expect(bRow?.status, isNot(TxStatus.confirmed));
    final aEnd = await a.summary(refresh: true, minimumConfirmations: one);
    log('A after B\'s attempt: ${line(aEnd)}');
    expect(aEnd.spendable, start.spendable - fee);

    // 6. A plain send B never answers: cancelled, nothing spent back, no fee.
    final countBefore = (await a.transactions(refresh: true)).length;
    final slate = await a.createSendSlate(amount: _nano ~/ BigInt.two, minimumConfirmations: one);
    final send = (await a.transactions(refresh: true)).singleWhere((t) => t.slateId == slate.slateId);
    log('step 6 send row ${send.kind.name}/${send.flow.name}/${send.status.name}');
    expect(cancelSpendsBack(send), isFalse);
    expect(await CancelFinal().cancel(a, send), CancelResult.cancelled);
    final after6 = await a.summary(refresh: true, minimumConfirmations: one);
    final rows6 = await a.transactions(refresh: true);
    log('step 6 after cancel: ${line(after6)}; rows ${rows6.length} (were ${countBefore + 1})');
    expect(rows6.length, countBefore + 1, reason: 'no spend back row');
    expect(after6.spendable, aEnd.spendable);
    expect(after6.total, aEnd.total);
  }, skip: _lib == null || _fund == null ? 'needs WFE_DEMO_LEPIC_LIB and WFE_FLOO_FUND' : false, timeout: const Timeout(Duration(minutes: 120)));
}
