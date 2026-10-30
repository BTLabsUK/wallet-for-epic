// SPDX-License-Identifier: Apache-2.0
// Live: Cancel makes a delivered invoice payment impossible to complete, on floonet with the real
// LEPIC core, and its edge cases end right. B issues payment requests as files, A pays them, and
// B holds A's signed answer (I2) without finishing it. One funding, the cases in sequence:
//
//   a1  A cancels: its coins are spent back. Once that confirms, B posts the I2: refused
//       (peerInputsSpent), B's row ends final, B has nothing.
//   e   While a spend back is unconfirmed, the coins coming back read as awaiting confirmation,
//       not locked (checked in a1 and c).
//   c   As a1, but A is closed and reopened right after the cancel: the cancel stays final, no
//       duplicate rows, B's later post refused.
//   a2  The payment wins the race: B posts the I2 inside A's cancel, before the spend back.
//       While B's payment is only in the pool the spend back is refused (spendBackPending), once
//       it is mined first it is alreadyPaid. Either way A ends paid, the spend back ended, nothing
//       retried.
//   b   The spend back fails, A closes, B posts and it confirms; A reopens: paid, no spend back.
//   k   A payment that spent three coins, cancelled: three coins come back (WFE_FUND_EPIC=7).
//   w   Stop waiting (the free cancel, no spend back): B still posts it, and A shows it paid.
//   s   A plain send nobody answered: cancelled, nothing spent back, no fee.
//
// A is funded by the QA funder (/opt/epic/qa-funder) by slate file: the funder's CLI writes the
// send, A answers it, the funder finalizes and posts it, so no relay is needed. Confirmations
// need a floonet miner. Throwaway wallets; prints no phrase, password or address.
//
//   WFE_DEMO_LEPIC_LIB=<path to liblepic_ffi.so> WFE_FLOO_FUND=<path to fund.sh> \
//   WFE_LIVE_NODE=https://floo-node.btlabs.uk flutter test test/cancel_final_live_test.dart
//
// WFE_CASES=w,s runs only those cases (after the funding). Without the first two it is
// skipped. A case that fails is logged and the next one still runs
// once A's coins settle; the test fails at the end if any did.
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/cancel_final.dart';
import 'package:epic_wallet/src/demo_server/gated_service.dart';
import 'package:epic_wallet/src/demo_server/limits.dart';
import 'package:epic_wallet/src/errors.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';


final String? _lib = Platform.environment['WFE_DEMO_LEPIC_LIB'];
final String? _fund = Platform.environment['WFE_FLOO_FUND'];

/// WFE_CASES=w,s runs only the cases whose names start with one of these (all when unset).
final List<String>? _cases = Platform.environment['WFE_CASES']?.split(',');

/// The funding, in EPIC (WFE_FUND_EPIC, 3 when unset). Case k needs about 7: three coins of
/// over 1 EPIC each after its payment is cancelled.
final String _fundEpic = Platform.environment['WFE_FUND_EPIC'] ?? '3';
final String _funderDir = Platform.environment['QA_FUNDER_DIR'] ?? '${Platform.environment['HOME']}/.epic/qa-funder';

const _password = 'cancel-final-live-1';
final _nano = BigInt.from(100000000);
final _half = _nano ~/ BigInt.two;
final _one = BigInt.one;

/// A fee far above any floonet fee of a one- or two-input transaction.
final _maxFee = BigInt.from(1000000);

void log(String s) {
  // ignore: avoid_print
  print('${DateTime.now().toIso8601String().substring(11, 19)} $s');
}

String epic(BigInt n) => (n.toDouble() / 1e8).toStringAsFixed(8);

String line(WalletSummary s) =>
    'total ${epic(s.total)} spendable ${epic(s.spendable)} awaitingConfirmation ${epic(s.awaitingConfirmation)} '
    'awaitingFinalization ${epic(s.awaitingFinalization)} locked ${epic(s.locked)} height ${s.lastConfirmedHeight}';

/// The outgoing half of a row pair.
bool _out(TxEntry t) => t.kind == TxKind.sent || t.kind == TxKind.sentCancelled;

String row(TxEntry? t) => t == null
    ? 'none'
    : '#${t.id} ${t.kind.name}/${t.flow.name}/${t.status.name} confirmed ${t.confirmed} origin ${t.origin.name} '
        'fee ${t.fee == null ? '-' : epic(t.fee!)} credited ${epic(t.amountCredited)} debited ${epic(t.amountDebited)}'
        '${t.cancelReason == null ? '' : ' reason ${t.cancelReason!.name}'}';

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

/// A's session with hooks into Cancel: [afterCancel] runs once, after LEPIC's cancel and before
/// CancelFinal's spend back, and [failSpendBack] is thrown once by the next spend back.
class _Race extends GatedWalletSession {
  _Race(WalletSession inner) : super(inner, WorkGate(1));

  Future<void> Function()? afterCancel;
  WalletError? failSpendBack;
  int spendBacks = 0;

  /// The output count each spend back asked for.
  final List<int> spendBackOutputs = [];

  @override
  Future<void> cancelTransaction({required int txId}) async {
    await super.cancelTransaction(txId: txId);
    final then = afterCancel;
    afterCancel = null;
    await then?.call();
  }

  @override
  Future<SelfSentTx> spendOutputsToSelf({required List<String> commitments, required BigInt minimumConfirmations, int outputs = 1}) async {
    spendBacks++;
    spendBackOutputs.add(outputs);
    final e = failSpendBack;
    failSpendBack = null;
    if (e != null) throw e;
    return super.spendOutputsToSelf(commitments: commitments, minimumConfirmations: minimumConfirmations, outputs: outputs);
  }
}

void main() {
  late Directory tmp;
  final l = lookupAppLocalizations(const Locale('en'));

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

  test('cancelled invoice payments end final in every order of events', () async {
    final node = Platform.environment['WFE_LIVE_NODE'] ?? floonetPreset.nodeUrl;
    log('node $node');
    expect(node, 'https://floo-node.btlabs.uk', reason: 'floonet runs only against our own node');
    final service = LepicWalletService(secrets: MemorySecretStore());
    final open = <WalletSession>[];
    addTearDown(() {
      for (final s in open) {
        try {
          s.dispose();
        } catch (_) {}
      }
    });
    WalletConfig config(String name) => floonetPreset.config(dataDir: '${tmp.path}/$name', nodeUrl: node);
    Future<_Race> create(String name) async {
      Directory('${tmp.path}/$name').createSync();
      final s = _Race(await service.create(config: config(name), password: _password));
      open.add(s);
      await s.setMinimumConfirmations(1);
      return s;
    }

    var a = await create('a');
    final b = await create('b');
    var cf = CancelFinal();

    /// Closes A and opens it again from its directory, with a new CancelFinal, as a restart.
    Future<void> restartA() async {
      a.dispose();
      open.remove(a);
      a = _Race(await service.open(config: config('a'), password: _password));
      open.add(a);
      cf = CancelFinal();
      log('A closed and reopened');
    }

    Future<WalletSummary> sum(WalletSession s) => s.summary(refresh: true, minimumConfirmations: _one);
    Future<TxEntry?> rowOf(WalletSession s, String slateId) async =>
        (await s.transactions(refresh: true)).where((t) => t.slateId == slateId).firstOrNull;
    final fees = <String, BigInt>{};

    /// A with every coin spendable: nothing awaiting, nothing locked.
    Future<WalletSummary> settled(String who, WalletSession s) => until('$who to settle', const Duration(minutes: 25), () async {
      final x = await sum(s);
      log('$who ${line(x)}');
      return x.awaitingConfirmation == BigInt.zero &&
              x.awaitingFinalization == BigInt.zero &&
              x.locked == BigInt.zero &&
              x.spendable > BigInt.zero
          ? x
          : null;
    });

    Future<void> blocks(WalletSession s, String who, int n) async {
      final h = (await sum(s)).lastConfirmedHeight;
      await until('$n more blocks', const Duration(minutes: 15), () async {
        final x = await sum(s);
        log('$who ${line(x)}');
        return x.lastConfirmedHeight >= h + BigInt.from(n) ? x : null;
      });
    }

    /// No row of [s] reads as another wallet's spend, and no two rows share a key or a
    /// payment's slate.
    Future<void> cleanRows(WalletSession s, String who) async {
      final rows = await s.transactions(refresh: true);
      for (final r in rows) {
        log('$who row ${r.slateId?.substring(0, 8)} ${row(r)}');
      }
      expect(rows.where((r) => r.origin == TxOrigin.otherWallet), isEmpty, reason: '$who marks a spend by another wallet');
      expect(rows.map((r) => r.key).toSet().length, rows.length, reason: '$who has duplicate rows');
      final slates = rows.where((r) => r.slateId != null).map((r) => r.slateId).toList();
      for (final id in slates.toSet()) {
        final same = rows.where((r) => r.slateId == id).toList();
        // A payment is one row; a spend back to itself two, its sent and its received half.
        final pair = same.length == 2 && same.where(_out).length == 1;
        expect(same.length == 1 || pair, isTrue, reason: '$who has ${same.length} rows for slate $id: ${same.map(row).join('; ')}');
      }
    }

    /// B issues a request for [amount], A pays it; B keeps the I2. A's row and the coins it locks.
    Future<({String slateId, String i2, BigInt fee, TxEntry tx, List<WalletOutput> coins})> pay(String tag, BigInt amount) async {
      final request = await b.pairing.requestFile(amount: amount, message: 'cancel live $tag');
      final paid = await a.payRequestFile(slateJson: request.json, amount: amount);
      final tx = (await rowOf(a, request.slateId))!;
      log('$tag A paid ${epic(amount)}, fee ${epic(paid.fee)}; A row ${row(tx)}');
      expect(tx.kind, TxKind.sent);
      expect(tx.flow, TxFlow.invoice);
      expect(cancelSpendsBack(tx), isTrue);
      final coins = (await a.outputs()).where((o) => o.txId == tx.id && o.status == WalletOutputStatus.locked).toList();
      log('$tag A coins locked by the payment: ${coins.length}, ${epic(coins.fold(BigInt.zero, (v, o) => v + o.value))}');
      expect(coins, isNotEmpty);
      log('$tag A after paying: ${line(await sum(a))}');
      return (slateId: request.slateId, i2: paid.json, fee: paid.fee, tx: tx, coins: coins);
    }

    /// Case e: right after a spend back, while it is not mined, the coins coming back are
    /// awaiting confirmation (their value less the fee), nothing is locked, and the total is
    /// down by the fee only. Returns the spend back's sent half, which carries the fee.
    Future<TxEntry> spendBackShape(String tag, WalletSummary start, List<WalletOutput> coins, Set<String> keysBefore) async {
      final s = await sum(a);
      final added = (await a.transactions(refresh: true)).where((r) => !keysBefore.contains(r.key)).toList();
      log('$tag e: A ${line(s)}; new rows ${added.map(row).join('; ')}');
      // LEPIC shows a send to itself as two rows: the sent half with the fee (and, for several
      // outputs, all but one of them as its change), the received half with the last output.
      expect(added, hasLength(2), reason: 'the spend back\'s two halves');
      final back = added.singleWhere(_out);
      final received = added.singleWhere((r) => !_out(r));
      expect(back.amountCredited + received.amountCredited, back.amountDebited - (back.fee ?? BigInt.zero));
      final fee = back.fee;
      log('$tag e: spend back fee ${fee == null ? '-' : epic(fee)}');
      expect(fee, isNotNull);
      if (back.confirmed) {
        log('$tag e: the spend back was mined already, shape not checked');
        return back;
      }
      final value = coins.fold(BigInt.zero, (v, o) => v + o.value);
      expect(s.locked, BigInt.zero, reason: 'coins of a posted spend back read as locked');
      expect(s.awaitingConfirmation, value - fee!, reason: 'coming back: their value less the fee');
      expect(s.total, start.total - fee, reason: 'total is down by the fee only');
      log('$tag e: PASS locked 0, awaitingConfirmation ${epic(s.awaitingConfirmation)} = coins ${epic(value)} - fee');
      return back;
    }

    /// Waits for A's spend back to confirm, with the total of every poll between [start] less
    /// a fee and [start]. Returns the summary and the fee.
    Future<(WalletSummary, BigInt)> spendBackConfirms(String tag, WalletSummary start, TxEntry payment) async {
      final totals = <BigInt>[];
      final end = await until('the spend back to confirm', const Duration(minutes: 30), () async {
        final s = await sum(a);
        totals.add(s.total);
        final o = await a.outputs();
        final now = (await rowOf(a, payment.slateId!))!;
        log('$tag A ${line(s)} cancelFinal ${cancelFinal(now, o)}');
        expect(cancelFinal(now, o), isTrue, reason: 'the cancel read as may-still-complete');
        return s.awaitingConfirmation == BigInt.zero && s.locked == BigInt.zero && s.spendable > BigInt.zero ? s : null;
      });
      final fee = start.total - end.total;
      log('$tag spend back confirmed: ${line(end)}; fee ${epic(fee)}');
      expect(fee > BigInt.zero && fee <= _maxFee, isTrue, reason: 'spend back fee ${epic(fee)}');
      for (final t in totals) {
        expect(t <= start.total, isTrue, reason: 'total ${epic(t)} above the start ${epic(start.total)}: counted twice');
        expect(t >= start.total - fee, isTrue, reason: 'total ${epic(t)} dropped more than the fee');
      }
      return (end, fee);
    }

    /// Case a1/c/d: B posts the I2 it holds after A's coins moved: refused as peerInputsSpent,
    /// worded as a cancelled payment whose coins moved, and B's row ends final within a few
    /// refreshes. B's balance does not change.
    Future<void> lateRefused(String tag, String slateId, String i2, WalletSummary bStart) async {
      Object? refusal;
      try {
        final posted = await b.finalizeAndPost(slateJson: i2);
        log('$tag B finalizeAndPost returned ${row(posted)}');
      } catch (e) {
        refusal = e;
        log('$tag B finalizeAndPost refused: ${e is WalletError ? '${e.kind.name}: ${e.message}' : e}');
      }
      expect(refusal, isA<WalletError>(), reason: 'the node took a payment whose inputs were spent');
      expect((refusal! as WalletError).kind, WalletErrorKind.peerInputsSpent);
      final words = describeError(l, refusal);
      log('$tag describeError: $words');
      expect(words, l.errorPaymentCancelledCoinsMoved);
      var refreshes = 0;
      final bRow = await until('B\'s row to end', const Duration(minutes: 10), () async {
        refreshes++;
        final r = await rowOf(b, slateId);
        log('$tag B refresh $refreshes: ${row(r)}; B ${line(await sum(b))}');
        final waiting = r == null || r.status == TxStatus.awaitingRecipient || r.status == TxStatus.awaitingConfirmation;
        return waiting ? null : r;
      });
      log('$tag d: B row final after $refreshes refreshes: ${row(bRow)}');
      expect(refreshes <= 3, isTrue, reason: 'B row took $refreshes refreshes to end');
      expect(bRow.confirmed, isFalse);
      expect(bRow.status, isNot(TxStatus.confirmed));
      await blocks(b, '$tag B', 2);
      final bEnd = await sum(b);
      log('$tag B after its attempt: ${line(bEnd)}');
      expect(bEnd.total, bStart.total);
      expect(bEnd.spendable, bStart.spendable);
    }

    final results = <String, String>{};
    Future<void> run(String name, Future<void> Function() body) async {
      final only = _cases;
      if (only != null && !only.any(name.startsWith)) return;
      log('=== case $name');
      try {
        await body();
        results[name] = 'PASS';
      } catch (e, st) {
        results[name] = 'FAIL: ${e.toString().split('\n').take(6).join(' ')}';
        log('$e\n$st');
      }
      log('=== case $name: ${results[name]}');
    }

    // Funding: the funder sends 3 EPIC by file, A answers, the funder finalizes and posts.
    final sendFile = '${tmp.path}/fund.slate';
    final answerFile = '${tmp.path}/fund.answer';
    await until('the funder to have coins to send', const Duration(minutes: 30), () async {
      final r = await funder(['send', '-m', 'file', '-d', sendFile, _fundEpic]);
      log('funder send: exit ${r.exitCode} ${r.exitCode == 0 ? '' : tail(r)}');
      return r.exitCode == 0 ? true : null;
    }, every: const Duration(seconds: 60));
    final answer = await a.receiveSlate(slateJson: File(sendFile).readAsStringSync());
    File(answerFile).writeAsStringSync(answer.json);
    final fin = await funder(['finalize', '-f', '-i', answerFile]);
    log('funder finalize: exit ${fin.exitCode} ${tail(fin)}');
    expect(fin.exitCode, 0, reason: 'the funder could not post the funding');
    final funded = await settled('A', a);
    log('funded: ${line(funded)}');
    expect(funded.spendable >= _nano * BigInt.two, isTrue);

    await run('a1 send back wins, late post refused (+ e)', () async {
      final start = await settled('a1 A', a);
      final bStart = await sum(b);
      final p = await pay('a1', _nano);
      final keys = (await a.transactions(refresh: true)).map((r) => r.key).toSet();
      final result = await cf.cancel(a, p.tx);
      log('a1 cancel: ${result.name}; owed ${cf.owed}');
      expect(result, CancelResult.spentBack);
      final after = (await rowOf(a, p.slateId))!;
      log('a1 A row after cancel ${row(after)}; cancelFinal ${cancelFinal(after, await a.outputs())}');
      expect(after.kind, TxKind.sentCancelled);
      expect(cancelFinal(after, await a.outputs()), isTrue);
      await spendBackShape('a1', start, p.coins, keys);
      final (end, fee) = await spendBackConfirms('a1', start, p.tx);
      fees['a1 spend back'] = fee;
      await lateRefused('a1', p.slateId, p.i2, bStart);
      final aEnd = await sum(a);
      log('a1 A after B\'s attempt: ${line(aEnd)}');
      expect(aEnd.total, start.total - fee);
      expect(aEnd.spendable, end.spendable);
      await cleanRows(a, 'a1 A');
    });

    await run('c restart before the send back confirms (+ e)', () async {
      final start = await settled('c A', a);
      final bStart = await sum(b);
      final p = await pay('c', _nano);
      final rowsBefore = await a.transactions(refresh: true);
      final result = await cf.cancel(a, p.tx);
      log('c cancel: ${result.name}');
      expect(result, CancelResult.spentBack);
      await restartA();
      await spendBackShape('c', start, p.coins, rowsBefore.map((r) => r.key).toSet());
      final (_, fee) = await spendBackConfirms('c', start, p.tx);
      fees['c spend back'] = fee;
      final cancelled = (await rowOf(a, p.slateId))!;
      final outs = await a.outputs();
      log('c A row ${row(cancelled)} cancelFinal ${cancelFinal(cancelled, outs)}');
      expect(cancelled.kind, TxKind.sentCancelled);
      expect(cancelFinal(cancelled, outs), isTrue);
      final rows = await a.transactions(refresh: true);
      expect(rows.length, rowsBefore.length + 2, reason: 'the spend back\'s two halves, nothing more');
      await cleanRows(a, 'c A');
      await lateRefused('c', p.slateId, p.i2, bStart);
      final aEnd = await sum(a);
      log('c A at the end: ${line(aEnd)}');
      expect(aEnd.total, start.total - fee);
    });

    /// Case a2: the payment wins. [mined]: B's post is mined before the spend back, else only in
    /// the pool.
    Future<void> paymentWins(String tag, {required bool mined}) async {
      final start = await settled('$tag A', a);
      final bStart = await sum(b);
      final p = await pay(tag, _half);
      final keys = (await a.transactions(refresh: true)).map((r) => r.key).toSet();
      a.afterCancel = () async {
        final posted = await b.finalizeAndPost(slateJson: p.i2);
        log('$tag B posted the I2 inside A\'s cancel: ${row(posted)}');
        if (!mined) return;
        await until('B\'s payment to be mined', const Duration(minutes: 15), () async {
          final r = await rowOf(b, p.slateId);
          log('$tag B ${row(r)}; B ${line(await sum(b))}');
          return r != null && r.confirmed ? r : null;
        });
      };
      final totals = <BigInt>[];
      final result = await cf.cancel(a, p.tx);
      log('$tag cancel: ${result.name}; owed ${cf.owed}; spend backs tried ${a.spendBacks}');
      expect(a.afterCancel, isNull, reason: 'B posted inside the cancel');
      expect(result, mined ? CancelResult.alreadyPaid : CancelResult.spendBackPending);
      final s0 = await sum(a);
      totals.add(s0.total);
      final added = (await a.transactions(refresh: true)).where((r) => !keys.contains(r.key)).toList();
      log('$tag A right after: ${line(s0)}; new rows ${added.map(row).join('; ')}');
      for (final o in (await a.outputs()).where((o) => p.coins.any((c) => c.commitment == o.commitment))) {
        log('$tag A paid coin now ${o.status.name} tx ${o.txId}');
      }
      for (var i = 0; i < 3; i++) {
        final again = await cf.retry(a);
        log('$tag retry ${i + 1}: $again; owed ${cf.owed}');
        expect(again, isFalse);
      }
      expect(cf.owed, isFalse);
      // Mined, LEPIC's refresh ends the spend back and its watch confirms the payment.
      final paid = await until('A\'s payment to read paid', const Duration(minutes: 30), () async {
        final s = await sum(a);
        totals.add(s.total);
        final r = await rowOf(a, p.slateId);
        final backs = (await a.transactions(refresh: false)).where((t) => !keys.contains(t.key)).toList();
        final again = await cf.retry(a);
        log('$tag A ${line(s)}; payment ${row(r)}; spend back ${backs.map(row).join('; ')}; retry $again owed ${cf.owed}');
        expect(again, isFalse);
        final backsEnded = backs.every((t) => !t.confirmed && t.status == TxStatus.cancelled);
        return r != null && r.confirmed && backsEnded && s.awaitingConfirmation == BigInt.zero && s.locked == BigInt.zero
            ? r
            : null;
      });
      log('$tag A payment ${row(paid)}');
      expect(paid.status, TxStatus.confirmed);
      await blocks(a, '$tag A', 2);
      for (var i = 0; i < 3; i++) {
        final again = await cf.retry(a);
        log('$tag retry after mined ${i + 1}: $again; owed ${cf.owed}');
        expect(again, isFalse);
      }
      expect(cf.owed, isFalse);
      final backs = (await a.transactions(refresh: true)).where((t) => !keys.contains(t.key)).toList();
      log('$tag spend back rows at the end: ${backs.map(row).join('; ')}');
      for (final t in backs) {
        expect(t.status, TxStatus.cancelled);
        expect(t.confirmed, isFalse);
        expect(t.origin, TxOrigin.thisWallet);
      }
      await cleanRows(a, '$tag A');
      final aEnd = await sum(a);
      fees['$tag payment'] = p.fee;
      log('$tag A at the end: ${line(aEnd)}; expected total ${epic(start.total - _half - p.fee)}');
      expect(aEnd.total, start.total - _half - p.fee);
      for (final t in totals) {
        expect(t <= start.total, isTrue, reason: 'total ${epic(t)} above the start: counted twice');
        expect(t >= start.total - _half - p.fee - _maxFee, isTrue, reason: 'total ${epic(t)} dropped more than amount and fees');
      }
      final bEnd = await until('B to receive', const Duration(minutes: 10), () async {
        final x = await sum(b);
        log('$tag B ${line(x)}');
        return x.awaitingConfirmation == BigInt.zero ? x : null;
      });
      expect(bEnd.total, bStart.total + _half, reason: 'B received the amount');
    }

    await run('a2 payment in the pool before the send back', () => paymentWins('a2pool', mined: false));
    await run('a2 payment mined before the send back', () => paymentWins('a2mined', mined: true));

    await run('b B posts while A is closed with the send back pending', () async {
      final start = await settled('b A', a);
      final bStart = await sum(b);
      final p = await pay('b', _half);
      final rowsBefore = await a.transactions(refresh: true);
      a.failSpendBack = const WalletError(kind: WalletErrorKind.nodeUnreachable, message: 'test: node unreachable once');
      final result = await cf.cancel(a, p.tx);
      log('b cancel: ${result.name}; owed ${cf.owed}');
      expect(result, CancelResult.spendBackPending);
      expect(cf.owed, isTrue);
      a.dispose();
      open.remove(a);
      log('b A closed');
      final posted = await b.finalizeAndPost(slateJson: p.i2);
      log('b B posted: ${row(posted)}');
      await until('B\'s payment to confirm', const Duration(minutes: 20), () async {
        final r = await rowOf(b, p.slateId);
        log('b B ${row(r)}; B ${line(await sum(b))}');
        return r != null && r.confirmed ? r : null;
      });
      a = _Race(await service.open(config: config('a'), password: _password));
      open.add(a);
      cf = CancelFinal();
      log('b A reopened');
      final paid = await until('A\'s payment to read paid', const Duration(minutes: 15), () async {
        final s = await sum(a);
        final r = await rowOf(a, p.slateId);
        log('b A ${line(s)}; payment ${row(r)}');
        return r != null && r.confirmed && s.awaitingConfirmation == BigInt.zero && s.locked == BigInt.zero ? r : null;
      });
      expect(paid.status, TxStatus.confirmed);
      expect(cf.owed, isFalse);
      expect(await cf.retry(a), isFalse);
      expect(a.spendBacks, 0, reason: 'no spend back after the reopen');
      final rows = await a.transactions(refresh: true);
      expect(rows.length, rowsBefore.length, reason: 'no spend back row');
      await cleanRows(a, 'b A');
      final aEnd = await sum(a);
      fees['b payment'] = p.fee;
      log('b A at the end: ${line(aEnd)}');
      expect(aEnd.total, start.total - _half - p.fee);
      final bEnd = await sum(b);
      log('b B at the end: ${line(bEnd)}');
      expect(bEnd.total, bStart.total + _half);
    });

    await run('k a payment of three coins, cancelled: three coins come back', () async {
      await settled('k A', a);
      final split = await a.splitOutputs(outputs: 3, minimumConfirmations: _one);
      fees['k split'] = split.fee;
      log('k A split into three, fee ${epic(split.fee)}');
      final start = await settled('k A', a);
      final coins = (await a.outputs()).where((o) => o.status == WalletOutputStatus.unspent).toList();
      log('k A coins ${coins.map((o) => epic(o.value)).join(', ')}');
      expect(coins, hasLength(3));
      // More than any two coins hold, so the payment spends all three.
      final values = [for (final o in coins) o.value]..sort();
      final p = await pay('k', values[0] + values[1] + _nano ~/ BigInt.from(10));
      expect(p.coins, hasLength(3), reason: 'the payment spends all three coins');
      final keysBefore = (await a.transactions(refresh: true)).map((r) => r.key).toSet();
      final result = await cf.cancel(a, p.tx);
      log('k cancel: ${result.name}; outputs asked ${a.spendBackOutputs.last}');
      expect(result, CancelResult.spentBack);
      expect(a.spendBackOutputs.last, 3);
      await spendBackShape('k', start, p.coins, keysBefore);
      final (_, fee) = await spendBackConfirms('k', start, p.tx);
      fees['k spend back'] = fee;
      expect(fee, spendBackFee(3, 3), reason: 'three in, three out: 0.010 EPIC');
      final back = (await a.outputs()).where((o) => o.status == WalletOutputStatus.unspent).toList();
      log('k A coins after: ${back.map((o) => epic(o.value)).join(', ')}');
      expect(back, hasLength(3), reason: 'as many coins back as the payment spent');
      for (final o in back) {
        expect(o.value >= _nano, isTrue, reason: 'no coin under 1 EPIC');
      }
      await cleanRows(a, 'k A');
    });

    await run('w Stop waiting, then B finishes the payment: it shows as paid', () async {
      final start = await settled('w A', a);
      final bStart = await sum(b);
      final p = await pay('w', _half);
      final rowsBefore = await a.transactions(refresh: true);
      final tried = a.spendBacks;
      final result = await cf.cancel(a, p.tx, spendBack: false);
      log('w cancel: ${result.name}; owed ${cf.owed}');
      expect(result, CancelResult.stoppedWaiting);
      expect(cf.owed, isFalse);
      final cancelled = (await rowOf(a, p.slateId))!;
      final outs = await a.outputs();
      log('w A row ${row(cancelled)} cancelFinal ${cancelFinal(cancelled, outs)}; A ${line(await sum(a))}');
      expect(cancelled.kind, TxKind.sentCancelled);
      expect(cancelFinal(cancelled, outs), isFalse, reason: 'its coins are free again, so it may still finish');
      expect(await cf.retry(a), isFalse);
      final posted = await b.finalizeAndPost(slateJson: p.i2);
      log('w B posted: ${row(posted)}');
      final paid = await until('A\'s payment to read paid', const Duration(minutes: 20), () async {
        final s = await sum(a);
        final r = await rowOf(a, p.slateId);
        log('w A ${line(s)}; payment ${row(r)}');
        return r != null && r.confirmed && s.awaitingConfirmation == BigInt.zero && s.locked == BigInt.zero ? r : null;
      });
      expect(paid.status, TxStatus.confirmed);
      expect(paid.kind, TxKind.sent);
      expect(a.spendBacks, tried, reason: 'Stop waiting spends nothing back');
      expect(await cf.retry(a), isFalse);
      final rows = await a.transactions(refresh: true);
      expect(rows.length, rowsBefore.length, reason: 'no spend back row');
      await cleanRows(a, 'w A');
      final aEnd = await sum(a);
      fees['w payment'] = p.fee;
      log('w A at the end: ${line(aEnd)}');
      expect(aEnd.total, start.total - _half - p.fee);
      await until('B\'s payment to confirm', const Duration(minutes: 10), () async {
        final r = await rowOf(b, p.slateId);
        return r != null && r.confirmed ? r : null;
      });
      final bEnd = await sum(b);
      log('w B at the end: ${line(bEnd)}');
      expect(bEnd.total, bStart.total + _half);
    });

    await run('s plain send nobody answered: no spend back, no fee', () async {
      final start = await settled('s A', a);
      final countBefore = (await a.transactions(refresh: true)).length;
      final slate = await a.createSendSlate(amount: _half, minimumConfirmations: _one);
      final send = (await rowOf(a, slate.slateId))!;
      log('s send row ${row(send)}');
      expect(cancelSpendsBack(send), isFalse);
      expect(await cf.cancel(a, send), CancelResult.cancelled);
      final after = await sum(a);
      final rows = await a.transactions(refresh: true);
      log('s after cancel: ${line(after)}; rows ${rows.length} (were ${countBefore + 1})');
      expect(rows.length, countBefore + 1, reason: 'no spend back row');
      expect(after.spendable, start.spendable);
      expect(after.total, start.total);
    });

    final height = (await sum(a)).lastConfirmedHeight;
    log('=== results at height $height');
    results.forEach((k, v) => log('  $k: $v'));
    var spent = BigInt.zero;
    fees.forEach((k, v) {
      spent += v;
      log('  fee $k ${epic(v)}');
    });
    log('  fees in all ${epic(spent)}');
    expect(results.values.where((v) => v != 'PASS'), isEmpty);
  }, skip: _lib == null || _fund == null ? 'needs WFE_DEMO_LEPIC_LIB and WFE_FLOO_FUND' : false, timeout: const Timeout(Duration(minutes: 240)));
}
