// SPDX-License-Identifier: Apache-2.0
// The LEPIC adapter's pure parts: error mapping, history keys and rows. No native library is
// loaded.
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/trust/policy.dart';
import 'package:lepic/lepic.dart' as lepic;

/// Fails any native call, so a test proves the adapter refused before reaching LEPIC.
class _NoNativeWallet implements lepic.EpicWallet {
  @override
  bool get isDisposed => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('reached LEPIC: ${invocation.memberName}');
}

/// Answers `storeAtRest` with [state] and counts `retirePlainStore`, which throws [failure] when set.
class _RetiringWallet extends _NoNativeWallet {
  _RetiringWallet(this.state, {this.failure});
  final lepic.StoreAtRestState state;
  final Object? failure;
  final List<int> retired = [];

  @override
  Future<lepic.StoreAtRest> storeAtRest() async => lepic.StoreAtRest(state: state, reason: '', rollbackSetAside: false);

  @override
  Future<lepic.RetiredPlainStore> retirePlainStore({required int olderThanDays}) async {
    retired.add(olderThanDays);
    if (failure != null) throw failure!;
    return const lepic.RetiredPlainStore(deleted: [], kept: []);
  }
}

/// Records the message of each send and answers with one stored transaction.
class _SendingWallet extends _NoNativeWallet {
  final List<String?> messages = [];
  final List<lepic.SendOptions?> options = [];

  /// What [estimateMax] answers; a test raises it to stand for a balance that grew.
  BigInt maxAmount = BigInt.from(90);

  /// No send here went through a pairing.
  @override
  Future<String?> contactOfTransaction({required int txId}) async => null;

  lepic.TransactionDetails get _stored => lepic.TransactionDetails(
    txId: 5,
    direction: lepic.TxDirection.outgoing,
    status: lepic.TxStatus.sent,
    slateId: 'sent-1',
    amountCredited: BigInt.zero,
    amountDebited: BigInt.from(11),
    fee: BigInt.one,
    createdAtMs: 1790000000000,
    releasable: false,
    undelivered: false,
    flow: lepic.TxFlow.payment,
    messages: [
      for (final m in messages)
        if (m != null)
          lepic.SlateMessage(role: lepic.SlateRole.sender, text: m),
    ],
    origin: lepic.TxOrigin.wallet,
    outputCommits: const [],
    spentCommits: const [],
    unverified: false,
  );

  @override
  Future<lepic.Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    lepic.SendOptions? options,
  }) async {
    messages.add(message);
    this.options.add(options);
    return const lepic.Slate(txId: 5, slateId: 'sent-1', json: '{}');
  }

  @override
  Future<lepic.SentTx> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
    lepic.SendOptions? options,
  }) async {
    messages.add(message);
    return lepic.SentTx(
      txId: 5,
      slateId: 'sent-1',
      amount: amount,
      fee: BigInt.one,
    );
  }

  @override
  Future<lepic.FeeEstimate> estimateMax({
    required BigInt minimumConfirmations,
    lepic.SendOptions? options,
  }) async {
    this.options.add(options);
    return lepic.FeeEstimate(
      amount: maxAmount,
      fee: BigInt.from(10),
      locked: BigInt.from(100),
      changeOutputs: 0,
      change: BigInt.zero,
      inputCount: 1,
    );
  }

  @override
  Future<lepic.FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
    lepic.SendOptions? options,
  }) async {
    this.options.add(options);
    return lepic.FeeEstimate(
      amount: amount,
      fee: BigInt.from(3),
      locked: BigInt.from(100),
      changeOutputs: 4,
      change: BigInt.from(100) - amount - BigInt.from(3),
      inputCount: 2,
    );
  }

  @override
  Future<List<lepic.WalletOutput>> outputs() async => [
    lepic.WalletOutput(
      commitment: '08ab',
      value: BigInt.from(7),
      status: lepic.OutputStatus.locked,
      category: lepic.OutputCategory.locked,
      isCoinbase: false,
      height: BigInt.from(12),
      lockHeight: BigInt.zero,
      confirmations: BigInt.from(4),
      txId: 9,
    ),
    lepic.WalletOutput(
      commitment: '09cd',
      value: BigInt.from(8),
      status: lepic.OutputStatus.unconfirmed,
      isCoinbase: true,
      height: BigInt.from(13),
      lockHeight: BigInt.from(1453),
      mmrIndex: BigInt.from(77),
      confirmations: BigInt.zero,
    ),
  ];

  @override
  Future<List<lepic.TransactionDetails>> transactions() async => [_stored];

  @override
  Future<lepic.TransactionDetails> transaction({required int txId}) async =>
      _stored;
}

void main() {
  group('peer compat mapping', () {
    test('keeps the stored facts as dates and bits, and leaves what LEPIC derives to the policy', () {
      final c = lepicPeerCompat(
        const lepic.PeerCompat(
          lastMarkedAtMs: 1767225600000,
          lastUnmarkedAtMs: 1767312000000,
          claimed: 3,
          works: 1,
          featuresAtMs: 1767225600000,
          lepic: false,
          notices: false,
          fresh: false,
        ),
      )!;
      expect(c.lastMarkedAt, DateTime.utc(2026, 1, 1));
      expect(c.lastUnmarkedAt, DateTime.utc(2026, 1, 2));
      expect(c.featuresAt, DateTime.utc(2026, 1, 1));
      expect(c.claimed, 3);
      expect(c.works, 1);
      expect(c.claims(featureMarker), isTrue);
      expect(c.claims(featurePairRequests), isTrue);
      expect(c.worked(featurePairRequests), isFalse);
      expect(answeredByOtherApp(c), isTrue);
    });

    test('a key nothing is known about is no row at all', () {
      expect(lepicPeerCompat(const lepic.PeerCompat(claimed: 0, works: 0, lepic: false, notices: false, fresh: false)), isNull);
    });
  });

  group('core wave binding', () {
    test('a call that left a transaction behind keeps its id', () {
      final mapped = mapLepicError(lepic.WalletError(kind: lepic.WalletErrorKind.notPosted, code: 1, message: 'm', txId: 42));
      expect(mapped.kind, WalletErrorKind.other);
      expect(mapped.txId, 42);
      expect(mapLepicError(lepic.WalletError(kind: lepic.WalletErrorKind.other, code: 1, message: 'm')).txId, isNull);
    });
  });

  group('26.10.25 binding', () {
    test('the pairing v3 kinds say which, and an attach refusal is about the contact', () {
      lepic.WalletError e(lepic.WalletErrorKind k, int code) => lepic.WalletError(kind: k, code: code, message: 'm');
      expect(pairingFailureOf(mapLepicError(e(lepic.WalletErrorKind.otherAddress, 81))), PairingFailure.otherWallet);
      expect(lepicPairingFailure(lepic.WalletErrorKind.otherAddress, '', true), PairingFailure.otherAddress);
      expect(pairingFailureOf(mapLepicError(e(lepic.WalletErrorKind.addressProofMissing, 82))), PairingFailure.addressProofMissing);
      expect(pairingFailureOf(mapLepicError(e(lepic.WalletErrorKind.peerNotProven, 83))), PairingFailure.peerNotProven);
      expect(pairingFailureOf(mapLepicError(e(lepic.WalletErrorKind.pairingInProgress, 84))), PairingFailure.inProgress);
      expect(pairingFailureOf(mapLepicError(e(lepic.WalletErrorKind.pairingCrossed, 85))), PairingFailure.crossed);
      expect(pairingFailureOf(mapLepicError(e(lepic.WalletErrorKind.pairingKindDiffers, 91))), PairingFailure.kindDiffers);
      expect(mapLepicError(e(lepic.WalletErrorKind.relayMoveNotRequested, 92)).kind, WalletErrorKind.invalidArgument);
      expect(pairingFailureOf(mapLepicError(e(lepic.WalletErrorKind.inviteDismissed, 86))), PairingFailure.inviteDismissed);
      expect(pairingFailureOf(mapLepicError(e(lepic.WalletErrorKind.pairingEnded, 87))), PairingFailure.ended);
      expect(pairingFailureOf(mapLepicError(e(lepic.WalletErrorKind.pairingWaiting, 88))), PairingFailure.waiting);
      expect(mapLepicError(e(lepic.WalletErrorKind.foreignProofAddress, 89)).kind, WalletErrorKind.invalidArgument);
      expect(mapLepicError(e(lepic.WalletErrorKind.wrongKey, 90)).kind, WalletErrorKind.wrongKey);
    });

    test('the derived pairing status and the end reasons', () {
      expect([for (final s in lepic.PairingStatus.values) lepicPairingStatus(s)], [
        PairingState.waiting,
        PairingState.paired,
        PairingState.verified,
        PairingState.keysChanged,
        PairingState.ended,
      ]);
      expect([for (final r in lepic.PairingEndReason.values) lepicPairingEndReason(r)], PairingEndReason.values);
    });

    test("the store copy's progress: pages while copying, full while checking, then finished", () {
      expect(lepicStoreMigrationProgress(const lepic.StoreMigrationProgress(stage: lepic.StoreMigrationStage.copying, done: 3, total: 10)),
          const StoreMigrationProgress(done: 3, total: 10));
      expect(lepicStoreMigrationProgress(const lepic.StoreMigrationProgress(stage: lepic.StoreMigrationStage.checking, done: 9, total: 10)),
          const StoreMigrationProgress(done: 10, total: 10));
      expect(lepicStoreMigrationProgress(const lepic.StoreMigrationProgress(stage: lepic.StoreMigrationStage.finished, done: 10, total: 10)),
          const StoreMigrationProgress(done: 10, total: 10, finished: true));
    });

    test('how the records were found at the unlock', () {
      expect(lepicStoreOpen(const lepic.StoreAtRest(state: lepic.StoreAtRestState.encrypted, reason: '', rollbackSetAside: false)), StoreOpenOutcome.encrypted);
      expect(lepicStoreOpen(const lepic.StoreAtRest(state: lepic.StoreAtRestState.migratedNow, reason: '', rollbackSetAside: true)), StoreOpenOutcome.migratedNow);
      expect(lepicStoreOpen(const lepic.StoreAtRest(state: lepic.StoreAtRestState.fellBackToPlain, reason: 'disk full', rollbackSetAside: false)), StoreOpenOutcome.plainFallback);
    });

    test('the build claims the directory bit only', () async {
      expect(appHostFeatures, featureDirectory);
    });
  });

  group('error mapping', () {
    lepic.WalletError error(lepic.WalletErrorKind kind) =>
        lepic.WalletError(kind: kind, code: 0, message: 'm');

    test('a pairing text for the other network or a newer wallet says so, not "not a pairing link"', () {
      lepic.WalletError refused(String why) =>
          lepic.WalletError(kind: lepic.WalletErrorKind.invalidPairingText, code: 58, message: 'pairing text was refused: $why');
      expect(pairingFailureOf(mapLepicError(refused('made for the other network'))), PairingFailure.wrongNetwork);
      expect(pairingFailureOf(mapLepicError(refused('made by a newer wallet: version 3'))), PairingFailure.newerVersion);
      expect(pairingFailureOf(mapLepicError(refused('the text was damaged on the way'))), PairingFailure.invalid);
    });

    test('kinds both cores have keep their name and the message', () {
      final shared = {for (final k in WalletErrorKind.values) k.name: k};
      for (final kind in lepic.WalletErrorKind.values) {
        final mapped = mapLepicError(error(kind));
        // A pairing failure carries which one it is, for the screens (pairingFailureOf).
        if (lepicPairingFailure(kind) case final failure?) {
          expect(mapped.kind, WalletErrorKind.pairingFailed, reason: kind.name);
          expect(pairingFailureOf(mapped), failure, reason: kind.name);
          continue;
        }
        // The split errors carry the app's own sentence (tested below).
        if (kind != lepic.WalletErrorKind.changeTooSmall &&
            kind != lepic.WalletErrorKind.tooHeavy &&
            kind != lepic.WalletErrorKind.nothingToConsolidate) {
          expect(mapped.message, 'm');
        }
        if (shared.containsKey(kind.name)) {
          expect(mapped.kind, shared[kind.name], reason: kind.name);
        }
      }
    });

    test('LEPIC-only kinds land on the nearest app kind', () {
      expect(
        mapLepicError(error(lepic.WalletErrorKind.foreignWallet)).kind,
        WalletErrorKind.invalidArgument,
      );
      expect(
        mapLepicError(error(lepic.WalletErrorKind.secretStore)).kind,
        WalletErrorKind.io,
      );
      for (final kind in [
        lepic.WalletErrorKind.onChain,
        lepic.WalletErrorKind.inPool,
        lepic.WalletErrorKind.notReleasable,
        lepic.WalletErrorKind.foreignAppData,
        lepic.WalletErrorKind.damagedAppData,
      ]) {
        expect(
          mapLepicError(error(kind)).kind,
          WalletErrorKind.invalidArgument,
          reason: kind.name,
        );
      }
      expect(
        mapLepicError(error(lepic.WalletErrorKind.invoiceNotFound)).kind,
        WalletErrorKind.invoiceNotFound,
      );
      expect(
        mapLepicError(error(lepic.WalletErrorKind.amountMismatch)).kind,
        WalletErrorKind.amountMismatch,
      );
      // Wave 19: what came as invalidSlate has its own kinds.
      expect(
        mapLepicError(error(lepic.WalletErrorKind.invoiceAlreadyPaid)).kind,
        WalletErrorKind.invoiceAlreadyPaid,
      );
      expect(
        mapLepicError(error(lepic.WalletErrorKind.invoiceLockedAboveTip)).kind,
        WalletErrorKind.invoiceLockedAboveTip,
      );
      expect(
        mapLepicError(error(lepic.WalletErrorKind.invoiceChanged)).kind,
        WalletErrorKind.invoiceChanged,
      );
      expect(
        mapLepicError(error(lepic.WalletErrorKind.notDelivered)).kind,
        WalletErrorKind.transportFailed,
      );
      expect(
        mapLepicError(error(lepic.WalletErrorKind.restoreScanRequired)).kind,
        WalletErrorKind.restoreScanRequired,
      );
      expect(
        mapLepicError(error(lepic.WalletErrorKind.unsupported)).kind,
        WalletErrorKind.unsupported,
      );
      expect(
        mapLepicError(error(lepic.WalletErrorKind.cancelled)).kind,
        WalletErrorKind.cancelled,
      );
      for (final kind in [
        lepic.WalletErrorKind.changedDuringCancel,
        lepic.WalletErrorKind.locked,
        lepic.WalletErrorKind.notPosted,
        lepic.WalletErrorKind.panic,
      ]) {
        expect(mapLepicError(error(kind)).kind, WalletErrorKind.other);
      }
    });
  });

  test('an undelivered epicbox, http or tor send is offered again, but not while it is being sent', () {
    lepic.TransactionDetails send({
      String transport = 'epicbox',
      bool undelivered = true,
      lepic.TxStatus status = lepic.TxStatus.sent,
    }) => lepic.TransactionDetails(
      txId: 7,
      direction: lepic.TxDirection.outgoing,
      status: status,
      slateId: 'undelivered-1',
      transport: transport,
      amountCredited: BigInt.zero,
      amountDebited: BigInt.from(11),
      fee: BigInt.one,
      createdAtMs: 1790000000000,
      releasable: false,
      undelivered: undelivered,
      flow: lepic.TxFlow.payment,
      messages: const [],
      origin: lepic.TxOrigin.wallet,
      outputCommits: const [],
      spentCommits: const [],
      unverified: false,
    );
    expect(lepicTxEntry(send()).undelivered, isTrue);
    // The first attempt of a send still running is undelivered for LEPIC too.
    expect(lepicTxEntry(send(), sending: true).undelivered, isFalse);
    expect(lepicTxEntry(send(undelivered: false)).undelivered, isFalse);
    // A Link send that failed is not delivered either (linux-13, windows-07).
    expect(lepicTxEntry(send(transport: 'http')).undelivered, isTrue);
    expect(lepicTxEntry(send(transport: 'tor')).undelivered, isTrue);
    expect(lepicTxEntry(send(transport: 'http'), sending: true).undelivered, isFalse);
    // A file send has no delivery to redo.
    expect(lepicTxEntry(send(transport: 'file')).undelivered, isFalse);
    expect(lepicTxEntry(send(status: lepic.TxStatus.cancelled)).undelivered, isFalse);
  });

  test('history keys carry the LEPIC transaction id', () {
    expect(lepicTxId('l:42'), 42);
    for (final key in ['s:slate-1', 'l:', 'l:x', '42']) {
      expect(
        () => lepicTxId(key),
        throwsA(
          isA<WalletError>().having(
            (e) => e.kind,
            'kind',
            WalletErrorKind.invalidArgument,
          ),
        ),
      );
    }
  });

  test('slate steps read as the old core tells them', () {
    SlateStage stage(lepic.SlateStage s) => lepicSlateInfo(
      lepic.SlateInfo(
        slateId: 'id',
        version: 3,
        stage: s,
        amount: BigInt.from(5),
        fee: BigInt.two,
        messages: const [],
      ),
    ).stage;
    expect(stage(lepic.SlateStage.s1), SlateStage.send);
    expect(stage(lepic.SlateStage.s2), SlateStage.response);
    expect(stage(lepic.SlateStage.s3), SlateStage.response);
    expect(stage(lepic.SlateStage.i1), SlateStage.request);
    expect(stage(lepic.SlateStage.i2), SlateStage.requestAnswer);
    expect(stage(lepic.SlateStage.i3), SlateStage.requestAnswer);
    final info = lepicSlateInfo(
      lepic.SlateInfo(
        slateId: 'abc',
        version: 2,
        stage: lepic.SlateStage.s1,
        amount: BigInt.from(7),
        fee: BigInt.one,
        messages: const [],
      ),
    );
    expect(
      info,
      SlateInfo(
        slateId: 'abc',
        amount: BigInt.from(7),
        fee: BigInt.one,
        stage: SlateStage.send,
      ),
    );
  });

  test('a slate\'s messages keep their role and text', () {
    final info = lepicSlateInfo(
      lepic.SlateInfo(
        slateId: 'abc',
        version: 3,
        stage: lepic.SlateStage.s2,
        amount: BigInt.from(7),
        fee: BigInt.one,
        messages: const [
          lepic.SlateMessage(role: lepic.SlateRole.sender, text: 'for lunch'),
          lepic.SlateMessage(role: lepic.SlateRole.receiver, text: 'thanks'),
        ],
      ),
    );
    expect(info.messages, const [
      SlateMessage(role: SlateRole.sender, text: 'for lunch'),
      SlateMessage(role: SlateRole.receiver, text: 'thanks'),
    ]);
    expect(messageBy(info.messages, SlateRole.receiver), 'thanks');
  });

  group('send options', () {
    test('strategy All always reaches LEPIC with one change output', () {
      final all = lepicSendOptions(
        const SendOptions(strategy: SelectionStrategy.all, changeOutputs: 4),
      );
      expect(all.strategy, lepic.SelectionStrategy.all);
      expect(all.changeOutputs, 1);
      final smallest = lepicSendOptions(const SendOptions(changeOutputs: 4));
      expect(smallest.strategy, lepic.SelectionStrategy.smallest);
      expect(smallest.changeOutputs, 4);
    });

    test('send all uses every coin and one change output, others none', () async {
      final wallet = _SendingWallet();
      final session = LepicWalletSession(wallet);
      final max = await session.estimateMax(minimumConfirmations: BigInt.from(3));
      await session.createSendSlate(
        amount: max.amount,
        minimumConfirmations: BigInt.from(3),
      );
      await session.createSendSlate(
        amount: BigInt.from(5),
        minimumConfirmations: BigInt.from(3),
      );
      const all = lepic.SendOptions(
        strategy: lepic.SelectionStrategy.all,
        changeOutputs: 1, excludeOutputs: [],
      );
      // estimateMax, its re-check before the send, the send; the small send has none.
      expect(wallet.options, [all, all, all, null]);
    });

    test('a max remembered from before the balance grew does not make a typed amount a send-all', () async {
      final wallet = _SendingWallet();
      final session = LepicWalletSession(wallet);
      final max = await session.estimateMax(minimumConfirmations: BigInt.from(3));
      wallet.maxAmount = BigInt.from(150);
      await session.createSendSlate(
        amount: max.amount,
        minimumConfirmations: BigInt.from(3),
      );
      expect(wallet.options.last, isNull);
    });

    test('after another amount was estimated, the old max is still not a send-all once the balance grew', () async {
      final wallet = _SendingWallet();
      final session = LepicWalletSession(wallet);
      final max = await session.estimateMax(minimumConfirmations: BigInt.from(3));
      await session.estimateFee(amount: BigInt.from(5), minimumConfirmations: BigInt.from(3));
      wallet.maxAmount = BigInt.from(150);
      await session.createSendSlate(amount: max.amount, minimumConfirmations: BigInt.from(3));
      expect(wallet.options.last, isNull);
      // A caller that knows it is a send-all says so, and is not second-guessed.
      await session.createSendSlate(
        amount: max.amount,
        minimumConfirmations: BigInt.from(3),
        options: const SendOptions(strategy: SelectionStrategy.all),
      );
      expect(wallet.options.last, const lepic.SendOptions(strategy: lepic.SelectionStrategy.all, changeOutputs: 1, excludeOutputs: []));
    });

    test('given options reach LEPIC, and the whole estimate comes back', () async {
      final wallet = _SendingWallet();
      final session = LepicWalletSession(wallet);
      final e = await session.estimateFee(
        amount: BigInt.from(10),
        minimumConfirmations: BigInt.from(3),
        options: const SendOptions(changeOutputs: 4),
      );
      // Given options win over the send-all default.
      final max = await session.estimateMax(minimumConfirmations: BigInt.from(3));
      await session.createSendSlate(
        amount: max.amount,
        minimumConfirmations: BigInt.from(3),
        options: const SendOptions(),
      );
      expect(wallet.options, [
        const lepic.SendOptions(
          strategy: lepic.SelectionStrategy.smallest,
          changeOutputs: 4, excludeOutputs: [],
        ),
        const lepic.SendOptions(
          strategy: lepic.SelectionStrategy.all,
          changeOutputs: 1, excludeOutputs: [],
        ),
        const lepic.SendOptions(
          strategy: lepic.SelectionStrategy.smallest,
          changeOutputs: 1, excludeOutputs: [],
        ),
      ]);
      expect(
        e,
        FeeEstimate(
          amount: BigInt.from(10),
          fee: BigInt.from(3),
          inputCount: 2,
          change: BigInt.from(87),
          locked: BigInt.from(100),
          changeOutputs: 4,
        ),
      );
    });

    test('outputs map field by field', () async {
      final list = await LepicWalletSession(_SendingWallet()).outputs();
      expect(list, [
        WalletOutput(
          commitment: '08ab',
          value: BigInt.from(7),
          status: WalletOutputStatus.locked,
          category: OutputCategory.locked,
          isCoinbase: false,
          height: BigInt.from(12),
          lockHeight: BigInt.zero,
          confirmations: BigInt.from(4),
          txId: 9,
        ),
        WalletOutput(
          commitment: '09cd',
          value: BigInt.from(8),
          status: WalletOutputStatus.unconfirmed,
          isCoinbase: true,
          height: BigInt.from(13),
          lockHeight: BigInt.from(1453),
          mmrIndex: BigInt.from(77),
          confirmations: BigInt.zero,
        ),
      ]);
    });

    test('a split LEPIC cannot build reads as one short error', () {
      for (final kind in [
        lepic.WalletErrorKind.changeTooSmall,
        lepic.WalletErrorKind.tooHeavy,
      ]) {
        final e = mapLepicError(lepic.WalletError(kind: kind, code: 45, message: 'x'));
        expect(e.message, sendUnbuildable);
      }
    });

    test('nothing to consolidate (code 47) reads as its own sentence', () {
      final e = mapLepicError(lepic.WalletError(kind: lepic.WalletErrorKind.nothingToConsolidate, code: 47, message: 'x'));
      expect(e.kind, WalletErrorKind.invalidArgument);
      expect(e.message, nothingToConsolidate);
    });

    test('a self-send event is neither an invoice nor an issuer event', () {
      final e = lepic.WalletEvent(kind: lepic.WalletEventKind.selfSend, txId: 7, slateId: 's');
      expect(lepicInvoiceEvent(e), isNull);
      expect(lepicIssuerEvent(e), isNull);
    });
  });

  group('send messages reach LEPIC', () {
    test('trimmed, and none when blank or missing', () async {
      final wallet = _SendingWallet();
      final session = LepicWalletSession(wallet);
      await session.createSendSlate(
        amount: BigInt.from(10),
        minimumConfirmations: BigInt.from(3),
        message: '  for lunch ',
      );
      await session.createSendSlate(
        amount: BigInt.from(10),
        minimumConfirmations: BigInt.from(3),
        message: '   ',
      );
      await session.createSendSlate(
        amount: BigInt.from(10),
        minimumConfirmations: BigInt.from(3),
      );
      expect(wallet.messages, ['for lunch', null, null]);
    });

    test('an epicbox send returns its row with the message', () async {
      final wallet = _SendingWallet();
      final session = LepicWalletSession(wallet);
      final row = await session.sendEpicbox(
        amount: BigInt.from(10),
        minimumConfirmations: BigInt.from(3),
        address: 'key@relay',
        message: 'rent',
      );
      expect(wallet.messages, ['rent']);
      expect(row.messages, const [
        SlateMessage(role: SlateRole.sender, text: 'rent'),
      ]);
    });
  });

  test('a repeated receive keeps its flag and the first answer', () {
    lepic.ReceivedSlate received({required bool repeated}) =>
        lepic.ReceivedSlate(
          txId: 4,
          slateId: 'abc',
          json: '{"r":1}',
          repeated: repeated,
        );
    expect(
      lepicReceivedSlate(received(repeated: true)),
      const ReceivedSlate(slateId: 'abc', json: '{"r":1}', repeated: true),
    );
    expect(
      lepicReceivedSlate(received(repeated: false)),
      const ReceivedSlate(slateId: 'abc', json: '{"r":1}'),
    );
  });

  test('listener kinds map one to one, a repeat apart from a receive', () {
    for (final kind in lepic.ListenerEventKind.values) {
      if (kind == lepic.ListenerEventKind.invoiceBounced) continue;
      final event = lepicListenerEvent(
        lepic.ListenerEvent(kind: kind, txId: 7, message: 'm'),
      )!;
      expect(event.kind.name, kind.name);
      expect(event.txId, 7);
      expect(event.message, 'm');
      expect(
        lepicListenerBounce(lepic.ListenerEvent(kind: kind, message: '')),
        isNull,
      );
    }
    expect(
      lepicListenerEvent(
        const lepic.ListenerEvent(
          kind: lepic.ListenerEventKind.repeated,
          txId: 3,
          message: 'answered again',
        ),
      ),
      const ListenerEvent(
        kind: ListenerEventKind.repeated,
        txId: 3,
        message: 'answered again',
      ),
    );
  });

  test('a disconnect carries its reason and retry wait', () {
    expect(
      lepicListenerEvent(
        lepic.ListenerEvent(
          kind: lepic.ListenerEventKind.disconnected,
          message: '',
          reason: 'relay closed the connection',
          retryInMs: BigInt.from(1500),
        ),
      ),
      const ListenerEvent(
        kind: ListenerEventKind.disconnected,
        message: '',
        reason: 'relay closed the connection',
        retryInMs: 1500,
      ),
    );
  });

  test('a listener bounce is an issuer event, not a listener one', () {
    const bounce = lepic.ListenerEvent(
      kind: lepic.ListenerEventKind.invoiceBounced,
      txId: 4,
      slateId: 'inv-4',
      message: 'sent back',
    );
    expect(lepicListenerEvent(bounce), isNull);
    expect(lepicListenerBounce(bounce), 'inv-4');
  });

  test('contacts and enrichment answer without reaching LEPIC', () async {
    final session = LepicWalletSession(_NoNativeWallet());
    expect(await session.contacts(), isEmpty);
    expect(await session.enrichHistory(), 0);
  });

  group('plain copies after the move to encryption', () {
    Future<_RetiringWallet> unlock(lepic.StoreAtRestState state, {Object? failure}) async {
      final wallet = _RetiringWallet(state, failure: failure);
      await LepicWalletSession(wallet).readStoreOpen();
      return wallet;
    }

    test('are retired once per unlock when the records are encrypted or just migrated', () async {
      expect((await unlock(lepic.StoreAtRestState.encrypted)).retired, [30]);
      expect((await unlock(lepic.StoreAtRestState.migratedNow)).retired, [30]);
    });

    test('are left alone on a plain fallback', () async {
      expect((await unlock(lepic.StoreAtRestState.fellBackToPlain)).retired, isEmpty);
    });

    test('a failed retirement does not break the open', () async {
      final session = LepicWalletSession(_RetiringWallet(lepic.StoreAtRestState.encrypted, failure: StateError('x')));
      await session.readStoreOpen();
      expect(session.storeOpen, StoreOpenOutcome.encrypted);
    });
  });

  group('history rows', () {
    lepic.TransactionDetails details({
      lepic.TxDirection direction = lepic.TxDirection.outgoing,
      required lepic.TxStatus status,
      String? slateId = 'slate-1',
      int? confirmedAtMs,
      BigInt? confirmedHeight,
      bool releasable = false,
      List<lepic.SlateMessage> messages = const [],
      lepic.TxFlow flow = lepic.TxFlow.payment,
      lepic.TxOrigin origin = lepic.TxOrigin.wallet,
      lepic.ImportedTx? imported,
      lepic.ScanFound? found,
      List<String> outputCommits = const [],
    }) => lepic.TransactionDetails(
      txId: 7,
      direction: direction,
      status: status,
      slateId: slateId,
      amountCredited: BigInt.from(3),
      amountDebited: BigInt.from(10),
      fee: BigInt.from(1),
      createdAtMs: 1790000000500,
      confirmedAtMs: confirmedAtMs,
      confirmedHeight: confirmedHeight,
      kernelExcess: 'ab',
      counterparty: 'key@relay',
      ttlCutoffHeight: BigInt.from(99),
      releasable: releasable,
      undelivered: false,
      messages: messages,
      flow: flow,
      origin: origin,
      imported: imported,
      found: found,
      outputCommits: outputCommits,
      spentCommits: const [],
      unverified: false,
    );

    test('a send waiting for its answer can be cancelled', () {
      final row = lepicTxEntry(details(status: lepic.TxStatus.sent));
      expect(row.key, 'l:7');
      expect(lepicTxId(row.key), 7);
      expect(row.kind, TxKind.sent);
      expect(row.status, TxStatus.awaitingRecipient);
      expect(row.cancellable, isTrue);
      expect(row.repostable, isFalse);
      expect(row.timeUnix, 1790000000);
      expect(row.counterparty, 'key@relay');
      expect(row.ttlCutoffHeight, BigInt.from(99));
    });

    test('a finalized send the node refused can be posted again', () {
      final row = lepicTxEntry(details(status: lepic.TxStatus.finalized));
      expect(row.status, TxStatus.awaitingConfirmation);
      expect(row.repostable, isTrue);
      expect(row.cancellable, isFalse);
      expect(row.releasable, isFalse);
    });

    test('a send LEPIC lets go of is releasable', () {
      final row = lepicTxEntry(
        details(status: lepic.TxStatus.posted, releasable: true),
      );
      expect(row.releasable, isTrue);
    });

    test('a confirmed send carries its block and the confirmation time', () {
      final row = lepicTxEntry(
        details(
          status: lepic.TxStatus.confirmed,
          confirmedAtMs: 1790000600000,
          confirmedHeight: BigInt.from(42),
        ),
      );
      expect(row.status, TxStatus.confirmed);
      expect(row.confirmed, isTrue);
      expect(row.blockHeight, BigInt.from(42));
      expect(row.timeUnix, 1790000600);
      expect(row.kernelExcess, 'ab');
    });

    test('an expired receive is a cancelled one, by expiry', () {
      final row = lepicTxEntry(
        details(
          direction: lepic.TxDirection.incoming,
          status: lepic.TxStatus.expired,
        ),
      );
      expect(row.kind, TxKind.receivedCancelled);
      expect(row.status, TxStatus.cancelled);
      expect(row.cancelReason, CancelReason.expiry);
    });

    test('an output a scan restored has no slate', () {
      final row = lepicTxEntry(
        details(
          direction: lepic.TxDirection.incoming,
          status: lepic.TxStatus.confirmed,
          slateId: null,
          origin: lepic.TxOrigin.foundByScan,
          outputCommits: const ['08cafe'],
        ),
      );
      // The commitment is what the row is known by after a restore changes its id.
      expect(row.outputCommits, ['08cafe']);
      expect(row.kind, TxKind.received);
      expect(row.source, TxSource.restored);
      expect(row.messages, isEmpty);
      expect(row.foundDuring, isNull);
      expect(row.datedByBlock, isTrue);
    });

    test('which scan found an output, and whether its time is the block\'s', () {
      TxEntry found(lepic.FoundDuring during, bool byBlock) => lepicTxEntry(
        details(
          direction: lepic.TxDirection.incoming,
          status: lepic.TxStatus.confirmed,
          slateId: null,
          origin: lepic.TxOrigin.foundByScan,
          found: lepic.ScanFound(during: during, datedByBlock: byBlock),
        ),
      );
      final restored = found(lepic.FoundDuring.restore, true);
      expect((restored.foundDuring, restored.datedByBlock), (TxFoundDuring.restore, true));
      final rescan = found(lepic.FoundDuring.rescan, false);
      expect((rescan.foundDuring, rescan.datedByBlock), (TxFoundDuring.rescan, false));
    });

    lepic.ImportedTx imported(lepic.ImportedTxKind kind, lepic.ChainCheck check) =>
        lepic.ImportedTx(sourceId: 31, kind: kind, inputCount: 2, outputCount: 1, check: check);

    test('an imported send keeps its counts and says where it came from', () {
      final row = lepicTxEntry(
        details(
          status: lepic.TxStatus.confirmed,
          origin: lepic.TxOrigin.imported,
          imported: imported(lepic.ImportedTxKind.sent, lepic.ChainCheck.onChain),
        ),
      );
      expect(row.source, TxSource.wallet);
      expect(row.kind, TxKind.sent);
      expect((row.numInputs, row.numOutputs), (2, 1));
      expect(row.statusDetail, contains('transaction 31'));
    });

    test('an imported receipt the old wallet restored shows as found by a scan', () {
      final row = lepicTxEntry(
        details(
          direction: lepic.TxDirection.incoming,
          status: lepic.TxStatus.confirmed,
          slateId: null,
          origin: lepic.TxOrigin.imported,
          imported: imported(lepic.ImportedTxKind.received, lepic.ChainCheck.onChain),
        ),
      );
      expect(row.source, TxSource.restored);
    });

    test('imported coinbase is a mining reward, and chain checks are explained', () {
      final coinbase = lepicTxEntry(
        details(
          direction: lepic.TxDirection.incoming,
          status: lepic.TxStatus.confirmed,
          slateId: null,
          origin: lepic.TxOrigin.imported,
          imported: imported(lepic.ImportedTxKind.coinbase, lepic.ChainCheck.unspentNotOnChain),
        ),
      );
      expect(coinbase.kind, TxKind.coinbase);
      expect(coinbase.statusDetail, contains('not in the balance'));
      final cancelled = lepicTxEntry(
        details(
          status: lepic.TxStatus.confirmed,
          origin: lepic.TxOrigin.imported,
          imported: imported(lepic.ImportedTxKind.sentCancelled, lepic.ChainCheck.cancelledButOnChain),
        ),
      );
      expect(cancelled.statusDetail, contains('had cancelled'));
      final open = lepicTxEntry(
        details(
          status: lepic.TxStatus.sent,
          origin: lepic.TxOrigin.imported,
          imported: imported(lepic.ImportedTxKind.sent, lepic.ChainCheck.unchecked),
        ),
      );
      expect(open.statusDetail, contains('Finish or cancel it in the older wallet'));
    });

    test('an output a scan restored is told by its origin', () {
      final row = lepicTxEntry(
        details(
          direction: lepic.TxDirection.incoming,
          status: lepic.TxStatus.confirmed,
          slateId: null,
          origin: lepic.TxOrigin.foundByScan,
        ),
      );
      expect(row.source, TxSource.restored);
      expect(row.statusDetail, isNull);
    });

    test('flow tells a request and a paid invoice from payments', () {
      TxEntry row(lepic.TxDirection direction, lepic.TxFlow flow) =>
          lepicTxEntry(
            details(
              direction: direction,
              status: lepic.TxStatus.received,
              flow: flow,
            ),
          );
      final request = row(lepic.TxDirection.incoming, lepic.TxFlow.invoice);
      expect(request.flow, TxFlow.invoice);
      expect(request.isRequest, isTrue);
      expect(request.awaitingPayer, isTrue);
      final paid = row(lepic.TxDirection.outgoing, lepic.TxFlow.invoice);
      expect(paid.flow, TxFlow.invoice);
      expect(paid.isRequest, isFalse);
      final received = row(lepic.TxDirection.incoming, lepic.TxFlow.payment);
      expect(received.flow, TxFlow.payment);
      expect(received.isRequest, isFalse);
      final sent = row(lepic.TxDirection.outgoing, lepic.TxFlow.payment);
      expect(sent.flow, TxFlow.payment);
      // LEPIC finalized the request's payment: it is paid, not waiting.
      final finalized = lepicTxEntry(
        details(
          direction: lepic.TxDirection.incoming,
          status: lepic.TxStatus.posted,
          flow: lepic.TxFlow.invoice,
        ),
      );
      expect(finalized.isRequest, isTrue);
      expect(finalized.awaitingPayer, isFalse);
    });

    test('a request and a paid invoice read from their transactions', () {
      final request = issuedInvoiceOf(
        lepicTxEntry(
          details(
            direction: lepic.TxDirection.incoming,
            status: lepic.TxStatus.received,
            flow: lepic.TxFlow.invoice,
            messages: const [
              lepic.SlateMessage(role: lepic.SlateRole.receiver, text: 'rent'),
            ],
          ),
        ),
      )!;
      expect(request.slateId, 'slate-1');
      expect(request.txId, 7);
      expect(request.payerAddress, 'key@relay');
      expect(request.amount, BigInt.from(3));
      expect(request.message, 'rent');
      expect(request.state, IssuedInvoiceState.waiting);
      expect(
        request.issuedAt,
        DateTime.fromMillisecondsSinceEpoch(1790000000000),
      );
      expect(request.expiresAt, request.issuedAt.add(invoiceExpiry));
      // What the app recorded wins over LEPIC's plain cancelled.
      final cancelled = lepicTxEntry(
        details(
          direction: lepic.TxDirection.incoming,
          status: lepic.TxStatus.cancelled,
          flow: lepic.TxFlow.invoice,
        ),
      );
      expect(issuedInvoiceOf(cancelled)!.state, IssuedInvoiceState.expired);
      expect(
        issuedInvoiceOf(cancelled, recorded: IssuedInvoiceState.bounced)!.state,
        IssuedInvoiceState.bounced,
      );
      // A received payment is no request; a paid invoice is the payer's side.
      final payment = lepicTxEntry(
        details(
          direction: lepic.TxDirection.incoming,
          status: lepic.TxStatus.received,
        ),
      );
      expect(issuedInvoiceOf(payment), isNull);
      final paidTx = lepicTxEntry(
        details(status: lepic.TxStatus.posted, flow: lepic.TxFlow.invoice),
      );
      expect(issuedInvoiceOf(paidTx), isNull);
      final paid = paidInvoiceOf(paidTx, kernelExcess: 'k')!;
      expect(paid.senderAddress, 'key@relay');
      expect(paid.amount, BigInt.from(6), reason: '10 in, 3 change, 1 fee');
      expect(paid.status, InvoiceStatus.replied);
      expect(paid.txId, 7);
      expect(paid.kernelExcess, 'k');
      expect(
        paidInvoiceOf(lepicTxEntry(details(status: lepic.TxStatus.posted))),
        isNull,
      );
    });

    test('a receive carries the sender\'s verified message', () {
      final row = lepicTxEntry(
        details(
          direction: lepic.TxDirection.incoming,
          status: lepic.TxStatus.received,
          messages: const [
            lepic.SlateMessage(role: lepic.SlateRole.sender, text: 'hi'),
          ],
        ),
      );
      expect(row.messages, const [
        SlateMessage(role: SlateRole.sender, text: 'hi'),
      ]);
    });
  });

  test("a contact's invoice keeps the issuer's message LEPIC verified", () {
    final view = lepic.ContactInvoiceView(
      slateId: 's1',
      contactId: 'c1',
      amount: BigInt.from(5),
      message: 'for order 1',
      receivedAtMs: 0,
      sameAmount: const [],
    );
    expect(lepicContactInvoice(view).message, 'for order 1');
    expect(lepicContactInvoice(lepic.ContactInvoiceView(slateId: 's2', contactId: 'c1', amount: BigInt.one, receivedAtMs: 0, sameAmount: const [])).message, isNull);
  });
}
