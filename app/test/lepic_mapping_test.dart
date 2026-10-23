// The LEPIC adapter's pure parts: error mapping, history keys and rows. No native library is
// loaded.
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

/// Fails any native call, so a test proves the adapter refused before reaching LEPIC.
class _NoNativeWallet implements lepic.EpicWallet {
  @override
  bool get isDisposed => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('reached LEPIC: ${invocation.memberName}');
}

/// Records the message of each send and answers with one stored transaction.
class _SendingWallet extends _NoNativeWallet {
  final List<String?> messages = [];
  final List<lepic.SendOptions?> options = [];

  /// What [estimateMax] answers; a test raises it to stand for a balance that grew.
  BigInt maxAmount = BigInt.from(90);

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
    flow: lepic.TxFlow.payment,
    messages: [
      for (final m in messages)
        if (m != null)
          lepic.SlateMessage(role: lepic.SlateRole.sender, text: m),
    ],
    origin: lepic.TxOrigin.wallet,
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
  group('error mapping', () {
    lepic.WalletError error(lepic.WalletErrorKind kind) =>
        lepic.WalletError(kind: kind, code: 0, message: 'm');

    test('kinds both cores have keep their name and the message', () {
      final shared = {for (final k in WalletErrorKind.values) k.name: k};
      for (final kind in lepic.WalletErrorKind.values) {
        final mapped = mapLepicError(error(kind));
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
      for (final kind in [
        lepic.WalletErrorKind.restoreScanRequired,
        lepic.WalletErrorKind.changedDuringCancel,
        lepic.WalletErrorKind.locked,
        lepic.WalletErrorKind.notPosted,
        lepic.WalletErrorKind.cancelled,
        lepic.WalletErrorKind.unsupported,
        lepic.WalletErrorKind.panic,
      ]) {
        expect(mapLepicError(error(kind)).kind, WalletErrorKind.other);
      }
    });
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
    for (final s in [
      lepic.SlateStage.i1,
      lepic.SlateStage.i2,
      lepic.SlateStage.i3,
    ]) {
      expect(stage(s), SlateStage.invoice, reason: s.name);
    }
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
        changeOutputs: 1,
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
      expect(wallet.options.last, const lepic.SendOptions(strategy: lepic.SelectionStrategy.all, changeOutputs: 1));
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
          changeOutputs: 4,
        ),
        const lepic.SendOptions(
          strategy: lepic.SelectionStrategy.all,
          changeOutputs: 1,
        ),
        const lepic.SendOptions(
          strategy: lepic.SelectionStrategy.smallest,
          changeOutputs: 1,
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

  test('peer capabilities map one to one', () {
    for (final c in lepic.PeerCapability.values) {
      expect(lepicPeerCapability(c).name, c.name);
    }
  });

  test('contacts and enrichment answer without reaching LEPIC', () async {
    final session = LepicWalletSession(_NoNativeWallet());
    expect(await session.contacts(), isEmpty);
    expect(await session.enrichHistory(), 0);
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
      messages: messages,
      flow: flow,
      origin: origin,
      imported: imported,
      found: found,
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
        ),
      );
      expect(row.kind, TxKind.received);
      expect(row.source, TxSource.restored);
      expect(row.messages, isEmpty);
      expect(row.foundDuring, isNull);
      expect(row.datedByBlock, isTrue);
    });

    test('F17: which scan found an output, and whether its time is the block\'s', () {
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
}
