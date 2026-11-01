// SPDX-License-Identifier: Apache-2.0
// A send LEPIC has finalized but is still posting reads "Posting…", never "Not on the network":
// LEPIC stores the finalize, and tells the app, before it asks the node, so a list read in
// between finds the row finalized. Only a post that really failed (the app's own post ended,
// or the row is still finalized `postingFor` later) reads not posted. Against a stand-in
// `EpicWallet`; no native library is loaded.
import 'dart:async';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/watch_mode.dart' show postingFor, postingNow;
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

/// LEPIC's store of one send in memory; any call not written here fails the test.
class _PostingWallet implements lepic.EpicWallet {
  final Map<int, lepic.TransactionDetails> stored = {};
  final eventSink = StreamController<lepic.WalletEvent>.broadcast();

  /// What the next repost does: null posts it, an error kind refuses it.
  lepic.WalletErrorKind? repostError;
  final List<int> reposts = [];

  @override
  bool get isDisposed => false;

  @override
  void lock() {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('reached LEPIC: ${invocation.memberName}');

  @override
  Stream<lepic.WalletEvent> events() => eventSink.stream;

  @override
  Future<List<lepic.TransactionDetails>> transactions() async => [...stored.values];

  @override
  Future<String?> contactOfTransaction({required int txId}) async => null;

  @override
  Future<void> repostTransaction({required int txId}) async {
    reposts.add(txId);
    final kind = repostError;
    if (kind != null) throw lepic.WalletError(kind: kind, code: 0, message: kind.name);
    status(txId, lepic.TxStatus.posted);
  }

  void status(int txId, lepic.TxStatus status) => stored[txId] = lepic.TransactionDetails(
    txId: txId,
    direction: lepic.TxDirection.outgoing,
    status: status,
    slateId: 'send-$txId',
    counterparty: 'bob@epicbox.example',
    transport: 'epicbox',
    amountCredited: BigInt.zero,
    amountDebited: BigInt.from(150000000),
    fee: BigInt.from(800000),
    kernelExcess: status == lepic.TxStatus.sent ? null : '08abc$txId',
    createdAtMs: 1790000000000,
    releasable: false,
    undelivered: false,
    flow: lepic.TxFlow.payment,
    messages: const [],
    origin: lepic.TxOrigin.wallet,
    outputCommits: const [],
    spentCommits: const [],
    unverified: false,
  );
}

void main() {
  late _PostingWallet wallet;
  late LepicWalletSession session;
  var now = DateTime(2026, 11, 1, 12);

  Future<TxEntry> row(int txId) async =>
      (await session.transactions(refresh: false)).singleWhere((t) => t.id == txId);

  setUp(() {
    now = DateTime(2026, 11, 1, 12);
    LepicWalletSession.postingClock = () => now;
    wallet = _PostingWallet();
    session = LepicWalletSession(wallet);
  });

  tearDown(() => LepicWalletSession.postingClock = DateTime.now);

  test('finalized while its post runs: posting, and posted once the node takes it', () async {
    wallet.status(7, lepic.TxStatus.sent);
    expect((await row(7)).posting, isFalse);
    // The listener finalized the reply; LEPIC is asking the node.
    wallet.status(7, lepic.TxStatus.finalized);
    final during = await row(7);
    expect(during.posting, isTrue);
    expect(during.repostable, isFalse, reason: 'no "Not on the network" while the post may still succeed');
    expect(postingNow(during, now, null), isTrue, reason: 'the list is read again until it settles');
    now = now.add(const Duration(seconds: 1));
    wallet.status(7, lepic.TxStatus.posted);
    final after = await row(7);
    expect(after.posting, isFalse);
    expect(after.repostable, isFalse);
  });

  test('a first post that fails and a retry that succeeds never read not posted', () async {
    wallet.status(8, lepic.TxStatus.sent);
    await row(8);
    // LEPIC's own post failed: the row stays finalized for the app's repost.
    wallet.status(8, lepic.TxStatus.finalized);
    expect((await row(8)).repostable, isFalse);
    now = now.add(const Duration(seconds: 1));
    await session.repostTransaction(key: 'l:8');
    final after = await row(8);
    expect(wallet.reposts, [8]);
    expect(after.repostable, isFalse);
    expect(after.posting, isFalse);
  });

  test('still finalized after postingFor: not posted', () async {
    wallet.status(9, lepic.TxStatus.sent);
    await row(9);
    wallet.status(9, lepic.TxStatus.finalized);
    expect((await row(9)).posting, isTrue);
    now = now.add(postingFor);
    final late = await row(9);
    expect(late.posting, isFalse);
    expect(late.repostable, isTrue);
  });

  test("the app's own post refused: not posted at once", () async {
    wallet.status(10, lepic.TxStatus.sent);
    await row(10);
    wallet.status(10, lepic.TxStatus.finalized);
    expect((await row(10)).posting, isTrue);
    wallet.repostError = lepic.WalletErrorKind.notPosted;
    await expectLater(session.repostTransaction(key: 'l:10'), throwsA(anything));
    final refused = await row(10);
    expect(refused.posting, isFalse);
    expect(refused.repostable, isTrue);
  });

  test('already finalized when the wallet opens: not posted at once', () async {
    wallet.status(11, lepic.TxStatus.finalized);
    final first = await row(11);
    expect(first.posting, isFalse);
    expect(first.repostable, isTrue);
  });
}
