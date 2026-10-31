// SPDX-License-Identifier: Apache-2.0
/// What moves in the web preview's fake wallet, so the levels' live payment timeline and the
/// relay-down flow can be seen without a server: a send walks signed → posted → confirming →
/// completed, a payment from Bob arrives a while after Home opens and confirms the same way,
/// and the fake Epicbox can go quiet and come back on a new address. Nothing here talks to a
/// network; the pace is that of a presentation, not of the chain.
library;

import 'dart:async';

import '../wallet_service.dart';

/// Signing by the recipient, then the post, then a block every [previewBlockEvery].
const Duration previewSignedAfter = Duration(seconds: 3);
const Duration previewPostedAfter = Duration(seconds: 3);
const Duration previewBlockEvery = Duration(seconds: 5);

/// How long after Home opens the payment from Bob arrives.
const Duration previewArrivalAfter = Duration(seconds: 20);

/// The amount that arrives.
final BigInt previewArrival = BigInt.from(1250000000);

/// The fake session with a clock of its own: sends and arrivals move through their steps by
/// timers, the fake node's tip grows with every block, and [dropRelay] / [moveRelay] play the
/// Epicbox relay going down and the wallet moving to another.
class PreviewSession extends FakeWalletSession {
  PreviewSession({super.summary, super.transactions, required this.sender, required this.sendersName});

  /// Who the arriving payment is from (an address), and the name it has in the contacts.
  final String sender;
  final String sendersName;

  /// The fake node, to move its tip along with the wallet's.
  FakeWalletService? tipService;

  final List<Timer> _timers = [];
  Timer? _blocks;
  bool _relayUp = true;
  bool _arrivalPlanned = false;

  /// The payments counting blocks: slate id → how many blocks it has seen.
  final Set<String> _climbing = {};

  void _later(Duration after, void Function() run) {
    late final Timer t;
    t = Timer(after, () {
      _timers.remove(t);
      run();
    });
    _timers.add(t);
  }

  /// The wallet opened: the payment from Bob is on its way, and the relay connects.
  void opened() {
    if (!_arrivalPlanned) {
      _arrivalPlanned = true;
      _later(previewArrivalAfter, _arrive);
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _blocks?.cancel();
    _blocks = null;
    _arrivalPlanned = false;
    _climbing.clear();
  }

  // The relay -----------------------------------------------------------------------------

  @override
  Stream<ListenerEvent> startListener() {
    final stream = super.startListener();
    _later(const Duration(milliseconds: 600), () {
      listenerEvents.add(
        _relayUp
            ? ListenerEvent(kind: ListenerEventKind.connected, message: address)
            : _disconnected,
      );
    });
    return stream;
  }

  static const ListenerEvent _disconnected = ListenerEvent(
    kind: ListenerEventKind.disconnected,
    message: 'connection closed',
    reason: 'connection closed',
    retryInMs: 8000,
  );

  /// Whether the relay answers.
  bool get relayUp => _relayUp;

  /// The relay stops answering; the listener reports it, and again on every restart the app tries.
  void dropRelay() {
    if (!_relayUp) return;
    _relayUp = false;
    listenerEvents.add(_disconnected);
  }

  /// The wallet moved to a relay that answers, under a new address.
  void moveRelay(String newAddress) {
    address = newAddress;
    _relayUp = true;
    listenerEvents.add(ListenerEvent(kind: ListenerEventKind.connected, message: newAddress));
  }

  // A send --------------------------------------------------------------------------------

  @override
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
    SendOptions? options,
  }) async {
    final tx = await super.sendEpicbox(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      address: address,
      message: message,
      options: options,
    );
    final stored = fakeTx(
      id: tx.id,
      slateId: tx.slateId,
      kind: TxKind.sent,
      status: TxStatus.awaitingRecipient,
      createdAtUnix: _now,
      amountDebited: tx.amountDebited,
      fee: tx.fee,
      numInputs: 1,
      numOutputs: 0,
      counterparty: address,
      messages: tx.messages,
      cancellable: true,
    );
    transactionsValue.add(stored);
    _moveFunds(spendable: -tx.amountDebited, locked: tx.amountDebited);
    final slate = stored.slateId!;
    _later(previewSignedAfter, () {
      _replace(slate, status: TxStatus.awaitingConfirmation, finalized: true, cancellable: false);
      _event(ListenerEventKind.finalized, stored);
      _later(previewPostedAfter, () => _mine(slate));
    });
    return stored;
  }

  // An arrival ----------------------------------------------------------------------------

  void _arrive() {
    final slate = 'a1b2c3d4-0001-4e5f-8a9b-0000000000b0';
    final tx = fakeTx(
      id: 60,
      slateId: slate,
      kind: TxKind.received,
      status: TxStatus.awaitingConfirmation,
      createdAtUnix: _now,
      amountCredited: previewArrival,
      numOutputs: 1,
      counterparty: sender,
      messages: const [SlateMessage(role: SlateRole.sender, text: 'For the tickets')],
    );
    transactionsValue.add(tx);
    final s = summaryValue;
    summaryValue = _summary(s, total: s.total + previewArrival, awaitingConfirmation: s.awaitingConfirmation + previewArrival);
    _event(ListenerEventKind.received, tx, amount: previewArrival);
    _later(previewSignedAfter, () => _mine(slate));
  }

  // Blocks --------------------------------------------------------------------------------

  /// The payment [slate] is in the next block; from here it counts blocks until it completes.
  void _mine(String slate) {
    final height = summaryValue.lastConfirmedHeight + BigInt.one;
    _tip(height);
    _replace(slate, blockHeight: height, blockTime: true);
    _climbing.add(slate);
    _blocks ??= Timer.periodic(previewBlockEvery, (_) => _block());
  }

  void _block() {
    _tip(summaryValue.lastConfirmedHeight + BigInt.one);
    final need = summaryValue.minimumConfirmations;
    for (final slate in _climbing.toList()) {
      final tx = transactionsValue.where((t) => t.slateId == slate).firstOrNull;
      final h = tx?.blockHeight;
      if (tx == null || h == null) continue;
      if (summaryValue.lastConfirmedHeight - h + BigInt.one >= need) {
        _climbing.remove(slate);
        _replace(slate, status: TxStatus.confirmed);
        _settleFunds(tx);
      }
    }
    if (_climbing.isEmpty) {
      _blocks?.cancel();
      _blocks = null;
    }
  }

  void _tip(BigInt height) {
    summaryValue = _summary(summaryValue, lastConfirmedHeight: height);
    final service = tipService;
    if (service != null) {
      service.nodeTipValue = NodeTip(height: height, nodeVersion: service.nodeTipValue.nodeVersion);
    }
  }

  /// A completed payment: its coins stop being locked / confirming.
  void _settleFunds(TxEntry tx) {
    final s = summaryValue;
    if (tx.kind == TxKind.sent) {
      summaryValue = _summary(s, total: s.total - tx.amountDebited, locked: s.locked - tx.amountDebited);
    } else {
      summaryValue = _summary(
        s,
        spendable: s.spendable + tx.amountCredited,
        awaitingConfirmation: s.awaitingConfirmation - tx.amountCredited,
      );
    }
  }

  void _moveFunds({required BigInt spendable, required BigInt locked}) {
    final s = summaryValue;
    summaryValue = _summary(s, spendable: s.spendable + spendable, locked: s.locked + locked);
  }

  // Helpers -------------------------------------------------------------------------------

  int get _now => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  void _replace(
    String slate, {
    TxStatus? status,
    BigInt? blockHeight,
    bool blockTime = false,
    bool finalized = false,
    bool? cancellable,
  }) {
    final i = transactionsValue.indexWhere((t) => t.slateId == slate);
    if (i < 0) return;
    final t = transactionsValue[i];
    transactionsValue[i] = fakeTx(
      key: t.key,
      id: t.id,
      slateId: t.slateId,
      kind: t.kind,
      status: status ?? t.status,
      createdAtUnix: t.createdAtUnix,
      blockHeight: blockHeight ?? t.blockHeight,
      blockTimeUnix: blockTime ? _now : t.blockTimeUnix,
      amountCredited: t.amountCredited,
      amountDebited: t.amountDebited,
      fee: t.fee,
      numInputs: t.numInputs,
      numOutputs: t.kind == TxKind.sent && status == TxStatus.awaitingConfirmation ? 1 : t.numOutputs,
      counterparty: t.counterparty,
      messages: t.messages,
      cancellable: cancellable ?? t.cancellable,
      finalizedAtUnix: finalized ? _now : t.finalizedAtUnix,
    );
  }

  /// Tells the listener something happened to [tx], so Home reads the wallet again (and words
  /// it as a notice). The blocks that follow need none: Home's own tip check sees them.
  void _event(ListenerEventKind kind, TxEntry tx, {BigInt? amount}) {
    listenerEvents.add(
      ListenerEvent(
        kind: kind,
        slateId: tx.slateId,
        txId: tx.id,
        message: 'preview',
        amount: amount ?? (tx.kind == TxKind.sent ? tx.amountDebited : tx.amountCredited),
      ),
    );
  }
}

/// [s] with the given figures changed.
WalletSummary _summary(
  WalletSummary s, {
  BigInt? lastConfirmedHeight,
  BigInt? total,
  BigInt? spendable,
  BigInt? awaitingConfirmation,
  BigInt? locked,
}) => WalletSummary(
  lastConfirmedHeight: lastConfirmedHeight ?? s.lastConfirmedHeight,
  minimumConfirmations: s.minimumConfirmations,
  total: total ?? s.total,
  spendable: spendable ?? s.spendable,
  awaitingConfirmation: awaitingConfirmation ?? s.awaitingConfirmation,
  awaitingFinalization: s.awaitingFinalization,
  immature: s.immature,
  locked: locked ?? s.locked,
  validatedWithNode: s.validatedWithNode,
);
