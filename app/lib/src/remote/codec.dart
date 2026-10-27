/// JSON codecs for every `models.dart` type that crosses [WalletService] and [WalletSession].
///
/// Wire forms: `BigInt` as a decimal string, bytes as base64, times as UTC milliseconds since
/// the epoch (decoded to local time, as the UI shows them), enums by name, classes and records
/// as objects keyed by their Dart field names. A value that does not decode throws a
/// [WalletError] of kind [WalletErrorKind.other], never a type error.
library;

import 'dart:convert';
import 'dart:typed_data';

import '../models.dart';

/// Encodes a [T] to a JSON value and decodes it back.
final class WireCodec<T> {
  const WireCodec(this.type, this.encode, this._decode);

  /// For error messages.
  final String type;
  final Object? Function(T value) encode;
  final T Function(Object? json) _decode;

  /// Throws [WalletError] when [json] is not a [T].
  T decode(Object? json) {
    try {
      return _decode(json);
    } on WalletError {
      rethrow;
    } on FormatException catch (e) {
      throw wireError(type, e.message);
    }
  }
}

/// The error for a value that does not decode.
WalletError wireError(String type, String detail) => WalletError(
  kind: WalletErrorKind.other,
  message: 'cannot decode $type: $detail',
);

/// Fields of a JSON object, each read through a codec.
final class WireReader {
  WireReader(Object? json, this.type)
    : _map = json is Map<String, Object?>
          ? json
          : throw wireError(type, 'not an object');

  final String type;
  final Map<String, Object?> _map;

  /// The field [key] through [codec]. A missing key reads as null.
  T of<T>(String key, WireCodec<T> codec) {
    try {
      return codec.decode(_map[key]);
    } on WalletError catch (e) {
      throw WalletError(kind: e.kind, message: '$type.$key: ${e.message}');
    }
  }
}

WireCodec<T> _scalar<T>(String type, Object? Function(T) encode) =>
    WireCodec<T>(type, encode, (json) {
      if (json is T) return json;
      throw wireError(type, 'got ${json.runtimeType}');
    });

WireCodec<T> _object<T>(
  String type,
  Map<String, Object?> Function(T value) encode,
  T Function(WireReader r) decode,
) => WireCodec<T>(type, encode, (json) => decode(WireReader(json, type)));

final WireCodec<String> stringWire = _scalar<String>('String', (v) => v);
final WireCodec<int> intWire = _scalar<int>('int', (v) => v);
final WireCodec<bool> boolWire = _scalar<bool>('bool', (v) => v);

/// No value: encodes as null and accepts anything.
final WireCodec<void> voidWire = WireCodec<void>('void', (_) => null, (_) {});

final RegExp _decimal = RegExp(r'^-?\d{1,80}$');

final WireCodec<BigInt> bigIntWire = WireCodec<BigInt>(
  'BigInt',
  (v) => v.toString(),
  (json) => json is String && _decimal.hasMatch(json)
      ? BigInt.parse(json)
      : throw wireError('BigInt', 'not a decimal string'),
);

final WireCodec<Uint8List> bytesWire = WireCodec<Uint8List>(
  'bytes',
  base64Encode,
  (json) => json is String
      ? base64Decode(json)
      : throw wireError('bytes', 'not base64 text'),
);

/// The range [DateTime] accepts, in milliseconds either side of the epoch.
const int _maxMillis = 8640000000000000;

final WireCodec<DateTime> timeWire = WireCodec<DateTime>(
  'DateTime',
  (v) => v.toUtc().millisecondsSinceEpoch,
  (json) => json is int && json.abs() <= _maxMillis
      ? DateTime.fromMillisecondsSinceEpoch(json)
      : throw wireError('DateTime', 'not milliseconds since the epoch'),
);

WireCodec<T> enumWire<T extends Enum>(String type, List<T> values) {
  final byName = values.asNameMap();
  return WireCodec<T>(
    type,
    (v) => v.name,
    (json) => byName[json] ?? (throw wireError(type, 'unknown value $json')),
  );
}

WireCodec<T?> nullable<T>(WireCodec<T> codec) => WireCodec<T?>(
  '${codec.type}?',
  (v) => v == null ? null : codec.encode(v),
  (json) => json == null ? null : codec.decode(json),
);

WireCodec<List<T>> listOf<T>(WireCodec<T> codec) => WireCodec<List<T>>(
  'List<${codec.type}>',
  (v) => [for (final e in v) codec.encode(e)],
  (json) => json is List<Object?>
      ? [for (final e in json) codec.decode(e)]
      : throw wireError('List<${codec.type}>', 'not a list'),
);

WireCodec<Map<String, T>> mapOf<T>(WireCodec<T> codec) =>
    WireCodec<Map<String, T>>(
      'Map<String, ${codec.type}>',
      (v) => {for (final e in v.entries) e.key: codec.encode(e.value)},
      (json) => json is Map<String, Object?>
          ? {for (final e in json.entries) e.key: codec.decode(e.value)}
          : throw wireError('Map<String, ${codec.type}>', 'not a map'),
    );

final WireCodec<String?> optString = nullable(stringWire);
final WireCodec<int?> optInt = nullable(intWire);
final WireCodec<BigInt?> optBigInt = nullable(bigIntWire);

final WireCodec<Chain> chainWire = enumWire('Chain', Chain.values);
final WireCodec<CancelReason> cancelReasonWire = enumWire(
  'CancelReason',
  CancelReason.values,
);
final WireCodec<ListenerEventKind> listenerEventKindWire = enumWire(
  'ListenerEventKind',
  ListenerEventKind.values,
);
final WireCodec<SlateRole> slateRoleWire = enumWire(
  'SlateRole',
  SlateRole.values,
);
final WireCodec<SlateStage> slateStageWire = enumWire(
  'SlateStage',
  SlateStage.values,
);
final WireCodec<TxKind> txKindWire = enumWire('TxKind', TxKind.values);
final WireCodec<TxFlow> txFlowWire = enumWire('TxFlow', TxFlow.values);
final WireCodec<TxSource> txSourceWire = enumWire('TxSource', TxSource.values);
final WireCodec<ManualField> manualFieldWire = enumWire(
  'ManualField',
  ManualField.values,
);
final WireCodec<TxStatus> txStatusWire = enumWire('TxStatus', TxStatus.values);
final WireCodec<InvoiceStatus> invoiceStatusWire = enumWire(
  'InvoiceStatus',
  InvoiceStatus.values,
);
final WireCodec<InvoiceEventKind> invoiceEventKindWire = enumWire(
  'InvoiceEventKind',
  InvoiceEventKind.values,
);
final WireCodec<IssuedInvoiceState> issuedInvoiceStateWire = enumWire(
  'IssuedInvoiceState',
  IssuedInvoiceState.values,
);
final WireCodec<IssuerEventKind> issuerEventKindWire = enumWire(
  'IssuerEventKind',
  IssuerEventKind.values,
);

/// A kind this side does not know reads as [WalletErrorKind.other], with the message kept.
final WireCodec<WalletError> walletErrorWire = _object<WalletError>(
  'WalletError',
  (v) => {'kind': v.kind.name, 'message': v.message},
  (r) => WalletError(
    kind:
        WalletErrorKind.values.asNameMap()[r.of('kind', optString)] ??
        WalletErrorKind.other,
    message: r.of('message', optString) ?? '',
  ),
);

final WireCodec<WalletConfig> walletConfigWire = _object<WalletConfig>(
  'WalletConfig',
  (v) => {
    'dataDir': v.dataDir,
    'chain': chainWire.encode(v.chain),
    'nodeUrl': v.nodeUrl,
    'nodeApiSecret': v.nodeApiSecret,
    'epicboxDomain': v.epicboxDomain,
    'epicboxPort': v.epicboxPort,
    'walletId': v.walletId,
  },
  (r) => WalletConfig(
    dataDir: r.of('dataDir', stringWire),
    chain: r.of('chain', chainWire),
    nodeUrl: r.of('nodeUrl', stringWire),
    nodeApiSecret: r.of('nodeApiSecret', optString),
    epicboxDomain: r.of('epicboxDomain', stringWire),
    epicboxPort: r.of('epicboxPort', intWire),
    walletId: r.of('walletId', optString),
  ),
);

final WireCodec<Contact> contactWire = _object<Contact>(
  'Contact',
  (v) => {
    'id': v.id,
    'name': v.name,
    'epicbox': v.epicbox,
    'http': v.http,
    'tor': v.tor,
    'note': v.note,
  },
  (r) => Contact(
    id: r.of('id', stringWire),
    name: r.of('name', stringWire),
    epicbox: r.of('epicbox', optString),
    http: r.of('http', optString),
    tor: r.of('tor', optString),
    note: r.of('note', optString),
  ),
);

final WireCodec<FeeEstimate> feeEstimateWire = _object<FeeEstimate>(
  'FeeEstimate',
  (v) => {
    'amount': bigIntWire.encode(v.amount),
    'fee': bigIntWire.encode(v.fee),
    'inputCount': v.inputCount,
    'change': bigIntWire.encode(v.change),
    'locked': bigIntWire.encode(v.locked),
    'changeOutputs': v.changeOutputs,
  },
  // A server from before the lock fields sends amount and fee only.
  (r) => FeeEstimate(
    amount: r.of('amount', bigIntWire),
    fee: r.of('fee', bigIntWire),
    inputCount: r.of('inputCount', optInt) ?? 0,
    change: r.of('change', optBigInt),
    locked: r.of('locked', optBigInt),
    changeOutputs: r.of('changeOutputs', optInt) ?? 0,
  ),
);

final WireCodec<SelectionStrategy> selectionStrategyWire = enumWire(
  'SelectionStrategy',
  SelectionStrategy.values,
);

final WireCodec<SendOptions> sendOptionsWire = _object<SendOptions>(
  'SendOptions',
  (v) => {
    'strategy': selectionStrategyWire.encode(v.strategy),
    'changeOutputs': v.changeOutputs,
  },
  (r) => SendOptions(
    strategy: r.of('strategy', selectionStrategyWire),
    changeOutputs: r.of('changeOutputs', intWire),
  ),
);

final WireCodec<SendOptions?> optSendOptions = nullable(sendOptionsWire);

final WireCodec<WalletOutputStatus> walletOutputStatusWire = enumWire(
  'WalletOutputStatus',
  WalletOutputStatus.values,
);

final WireCodec<OutputCategory> outputCategoryWire = enumWire(
  'OutputCategory',
  OutputCategory.values,
);

final WireCodec<WalletOutput> walletOutputWire = _object<WalletOutput>(
  'WalletOutput',
  (v) => {
    'commitment': v.commitment,
    'value': bigIntWire.encode(v.value),
    'status': walletOutputStatusWire.encode(v.status),
    'category': nullable(outputCategoryWire).encode(v.category),
    'isCoinbase': v.isCoinbase,
    'height': bigIntWire.encode(v.height),
    'lockHeight': bigIntWire.encode(v.lockHeight),
    'mmrIndex': optBigInt.encode(v.mmrIndex),
    'confirmations': bigIntWire.encode(v.confirmations),
    'txId': v.txId,
  },
  (r) => WalletOutput(
    commitment: r.of('commitment', stringWire),
    value: r.of('value', bigIntWire),
    status: r.of('status', walletOutputStatusWire),
    category: r.of('category', nullable(outputCategoryWire)),
    isCoinbase: r.of('isCoinbase', boolWire),
    height: r.of('height', bigIntWire),
    lockHeight: r.of('lockHeight', bigIntWire),
    mmrIndex: r.of('mmrIndex', optBigInt),
    confirmations: r.of('confirmations', bigIntWire),
    txId: r.of('txId', optInt),
  ),
);

final WireCodec<SelfSentTx> selfSentTxWire = _object<SelfSentTx>(
  'SelfSentTx',
  (v) => {
    'txId': v.txId,
    'receivedTxId': v.receivedTxId,
    'amount': bigIntWire.encode(v.amount),
    'fee': bigIntWire.encode(v.fee),
    'inputCount': v.inputCount,
    'outputCount': v.outputCount,
  },
  (r) => SelfSentTx(
    txId: r.of('txId', intWire),
    receivedTxId: r.of('receivedTxId', intWire),
    amount: r.of('amount', bigIntWire),
    fee: r.of('fee', bigIntWire),
    inputCount: r.of('inputCount', intWire),
    outputCount: r.of('outputCount', intWire),
  ),
);

final WireCodec<ImportConflict> importConflictWire = _object<ImportConflict>(
  'ImportConflict',
  (v) => {
    'key': v.key,
    'field': manualFieldWire.encode(v.field),
    'mine': v.mine,
    'theirs': v.theirs,
    'timeUnix': v.timeUnix,
    'amount': bigIntWire.encode(v.amount),
  },
  (r) => ImportConflict(
    key: r.of('key', stringWire),
    field: r.of('field', manualFieldWire),
    mine: r.of('mine', optString),
    theirs: r.of('theirs', stringWire),
    timeUnix: r.of('timeUnix', intWire),
    amount: r.of('amount', bigIntWire),
  ),
);

final WireCodec<ImportReport> importReportWire = _object<ImportReport>(
  'ImportReport',
  (v) => {
    'merged': v.merged,
    'added': v.added,
    'skipped': v.skipped,
    'contactsAdded': v.contactsAdded,
    'conflicts': listOf(importConflictWire).encode(v.conflicts),
    'applied': v.applied,
    'replaced': v.replaced,
    'pairingsAdded': v.pairingsAdded,
    'pairingsOtherDevice': v.pairingsOtherDevice,
    'notesAdded': v.notesAdded,
    'labelsAdded': v.labelsAdded,
    'detailsAdded': v.detailsAdded,
    'invoicesAdded': v.invoicesAdded,
    'starsAdded': v.starsAdded,
    'walletName': v.walletName,
    'settings': v.settings == null ? null : jsonEncode(v.settings),
  },
  (r) => ImportReport(
    merged: r.of('merged', intWire),
    added: r.of('added', intWire),
    skipped: r.of('skipped', intWire),
    contactsAdded: r.of('contactsAdded', intWire),
    conflicts:
        r.of('conflicts', nullable(listOf(importConflictWire))) ?? const [],
    applied: r.of('applied', nullable(boolWire)) ?? true,
    replaced: r.of('replaced', optInt) ?? 0,
    pairingsAdded: r.of('pairingsAdded', optInt) ?? 0,
    pairingsOtherDevice: r.of('pairingsOtherDevice', optInt) ?? 0,
    notesAdded: r.of('notesAdded', optInt) ?? 0,
    labelsAdded: r.of('labelsAdded', optInt) ?? 0,
    detailsAdded: r.of('detailsAdded', optInt) ?? 0,
    invoicesAdded: r.of('invoicesAdded', optInt) ?? 0,
    starsAdded: r.of('starsAdded', optInt) ?? 0,
    walletName: r.of('walletName', optString),
    settings: switch (r.of('settings', optString)) {
      final String text => switch (jsonDecode(text)) {
        final Map<String, Object?> m => m,
        _ => null,
      },
      null => null,
    },
  ),
);

final WireCodec<ListenerEvent> listenerEventWire = _object<ListenerEvent>(
  'ListenerEvent',
  (v) => {
    'kind': listenerEventKindWire.encode(v.kind),
    'slateId': v.slateId,
    'txId': v.txId,
    'message': v.message,
    'amount': optBigInt.encode(v.amount),
    'reason': v.reason,
    'retryInMs': v.retryInMs,
  },
  (r) => ListenerEvent(
    kind: r.of('kind', listenerEventKindWire),
    slateId: r.of('slateId', optString),
    txId: r.of('txId', optInt),
    message: r.of('message', stringWire),
    amount: r.of('amount', optBigInt),
    reason: r.of('reason', optString),
    retryInMs: r.of('retryInMs', optInt),
  ),
);

final WireCodec<NodeTip> nodeTipWire = _object<NodeTip>(
  'NodeTip',
  (v) => {
    'height': bigIntWire.encode(v.height),
    'nodeVersion': v.nodeVersion,
    'readyForTxs': nullable(boolWire).encode(v.readyForTxs),
  },
  (r) => NodeTip(
    height: r.of('height', bigIntWire),
    nodeVersion: r.of('nodeVersion', stringWire),
    readyForTxs: r.of('readyForTxs', nullable(boolWire)),
  ),
);

final WireCodec<WalletSummary> walletSummaryWire = _object<WalletSummary>(
  'WalletSummary',
  (v) => {
    'lastConfirmedHeight': bigIntWire.encode(v.lastConfirmedHeight),
    'minimumConfirmations': bigIntWire.encode(v.minimumConfirmations),
    'total': bigIntWire.encode(v.total),
    'spendable': bigIntWire.encode(v.spendable),
    'awaitingConfirmation': bigIntWire.encode(v.awaitingConfirmation),
    'awaitingFinalization': bigIntWire.encode(v.awaitingFinalization),
    'immature': bigIntWire.encode(v.immature),
    'locked': bigIntWire.encode(v.locked),
    'validatedWithNode': v.validatedWithNode,
  },
  (r) => WalletSummary(
    lastConfirmedHeight: r.of('lastConfirmedHeight', bigIntWire),
    minimumConfirmations: r.of('minimumConfirmations', bigIntWire),
    total: r.of('total', bigIntWire),
    spendable: r.of('spendable', bigIntWire),
    awaitingConfirmation: r.of('awaitingConfirmation', bigIntWire),
    awaitingFinalization: r.of('awaitingFinalization', bigIntWire),
    immature: r.of('immature', bigIntWire),
    locked: r.of('locked', bigIntWire),
    validatedWithNode: r.of('validatedWithNode', boolWire),
  ),
);

final WireCodec<RefreshProgress> refreshProgressWire = _object<RefreshProgress>(
  'RefreshProgress',
  (v) => {
    'percent': v.percent,
    'message': v.message,
    'summary': nullable(walletSummaryWire).encode(v.summary),
  },
  (r) => RefreshProgress(
    percent: r.of('percent', intWire),
    message: r.of('message', stringWire),
    summary: r.of('summary', nullable(walletSummaryWire)),
  ),
);

final WireCodec<ScanProgress> scanProgressWire = _object<ScanProgress>(
  'ScanProgress',
  (v) => {'percent': v.percent, 'message': v.message, 'finished': v.finished},
  (r) => ScanProgress(
    percent: r.of('percent', optInt),
    message: r.of('message', stringWire),
    finished: r.of('finished', boolWire),
  ),
);

final WireCodec<Slate> slateWire = _object<Slate>(
  'Slate',
  (v) => {'slateId': v.slateId, 'json': v.json},
  (r) => Slate(
    slateId: r.of('slateId', stringWire),
    json: r.of('json', stringWire),
  ),
);

final WireCodec<ReceivedSlate> receivedSlateWire = _object<ReceivedSlate>(
  'ReceivedSlate',
  (v) => {'slateId': v.slateId, 'json': v.json, 'repeated': v.repeated},
  (r) => ReceivedSlate(
    slateId: r.of('slateId', stringWire),
    json: r.of('json', stringWire),
    repeated: r.of('repeated', boolWire),
  ),
);

final WireCodec<SlateMessage> slateMessageWire = _object<SlateMessage>(
  'SlateMessage',
  (v) => {'role': slateRoleWire.encode(v.role), 'text': v.text},
  (r) => SlateMessage(
    role: r.of('role', slateRoleWire),
    text: r.of('text', stringWire),
  ),
);

final WireCodec<SlateInfo> slateInfoWire = _object<SlateInfo>(
  'SlateInfo',
  (v) => {
    'slateId': v.slateId,
    'amount': bigIntWire.encode(v.amount),
    'fee': bigIntWire.encode(v.fee),
    'stage': slateStageWire.encode(v.stage),
    'messages': listOf(slateMessageWire).encode(v.messages),
  },
  (r) => SlateInfo(
    slateId: r.of('slateId', stringWire),
    amount: r.of('amount', bigIntWire),
    fee: r.of('fee', bigIntWire),
    stage: r.of('stage', slateStageWire),
    messages: r.of('messages', listOf(slateMessageWire)),
  ),
);

final WireCodec<TxEntry> txEntryWire = _object<TxEntry>(
  'TxEntry',
  (v) => {
    'key': v.key,
    'id': v.id,
    'slateId': v.slateId,
    'kind': txKindWire.encode(v.kind),
    'status': txStatusWire.encode(v.status),
    'source': txSourceWire.encode(v.source),
    'createdAtUnix': v.createdAtUnix,
    'timeUnix': v.timeUnix,
    'confirmed': v.confirmed,
    'blockHeight': optBigInt.encode(v.blockHeight),
    'blockTimeUnix': v.blockTimeUnix,
    'amountCredited': bigIntWire.encode(v.amountCredited),
    'amountDebited': bigIntWire.encode(v.amountDebited),
    'fee': optBigInt.encode(v.fee),
    'numInputs': v.numInputs,
    'numOutputs': v.numOutputs,
    'kernelExcess': v.kernelExcess,
    'outputCommits': listOf(stringWire).encode(v.outputCommits),
    'counterparty': v.counterparty,
    'note': v.note,
    'label': v.label,
    'manualFields': listOf(manualFieldWire).encode([...v.manualFields]),
    'manualEditedAtUnix': v.manualEditedAtUnix,
    'messages': listOf(slateMessageWire).encode(v.messages),
    'ttlCutoffHeight': optBigInt.encode(v.ttlCutoffHeight),
    'cancellable': v.cancellable,
    'repostable': v.repostable,
    'statusDetail': v.statusDetail,
    'releasable': v.releasable,
    'finalizedAtUnix': v.finalizedAtUnix,
    'cancelReason': nullable(cancelReasonWire).encode(v.cancelReason),
    'flow': txFlowWire.encode(v.flow),
  },
  (r) => TxEntry(
    key: r.of('key', stringWire),
    id: r.of('id', optInt),
    slateId: r.of('slateId', optString),
    kind: r.of('kind', txKindWire),
    status: r.of('status', txStatusWire),
    source: r.of('source', txSourceWire),
    createdAtUnix: r.of('createdAtUnix', intWire),
    timeUnix: r.of('timeUnix', intWire),
    confirmed: r.of('confirmed', boolWire),
    blockHeight: r.of('blockHeight', optBigInt),
    blockTimeUnix: r.of('blockTimeUnix', optInt),
    amountCredited: r.of('amountCredited', bigIntWire),
    amountDebited: r.of('amountDebited', bigIntWire),
    fee: r.of('fee', optBigInt),
    numInputs: r.of('numInputs', intWire),
    numOutputs: r.of('numOutputs', intWire),
    kernelExcess: r.of('kernelExcess', optString),
    outputCommits: r.of('outputCommits', listOf(stringWire)),
    counterparty: r.of('counterparty', optString),
    note: r.of('note', optString),
    label: r.of('label', optString),
    manualFields: {
      ...?r.of('manualFields', nullable(listOf(manualFieldWire))),
    },
    manualEditedAtUnix: r.of('manualEditedAtUnix', optInt),
    messages: r.of('messages', listOf(slateMessageWire)),
    ttlCutoffHeight: r.of('ttlCutoffHeight', optBigInt),
    cancellable: r.of('cancellable', boolWire),
    repostable: r.of('repostable', boolWire),
    statusDetail: r.of('statusDetail', optString),
    releasable: r.of('releasable', boolWire),
    finalizedAtUnix: r.of('finalizedAtUnix', optInt),
    cancelReason: r.of('cancelReason', nullable(cancelReasonWire)),
    flow: r.of('flow', txFlowWire),
  ),
);

final WireCodec<PendingInvoice> pendingInvoiceWire = _object<PendingInvoice>(
  'PendingInvoice',
  (v) => {
    'slateId': v.slateId,
    'senderAddress': v.senderAddress,
    'amount': bigIntWire.encode(v.amount),
    'message': v.message,
    'receivedAt': timeWire.encode(v.receivedAt),
    'expiresAt': timeWire.encode(v.expiresAt),
    'pairingId': v.pairingId,
    'reference': v.reference,
  },
  (r) => PendingInvoice(
    slateId: r.of('slateId', stringWire),
    senderAddress: r.of('senderAddress', stringWire),
    amount: r.of('amount', bigIntWire),
    message: r.of('message', optString),
    receivedAt: r.of('receivedAt', timeWire),
    expiresAt: r.of('expiresAt', timeWire),
    pairingId: r.of('pairingId', optString),
    reference: r.of('reference', optString),
  ),
);

final WireCodec<PaidInvoice> paidInvoiceWire = _object<PaidInvoice>(
  'PaidInvoice',
  (v) => {
    'slateId': v.slateId,
    'senderAddress': v.senderAddress,
    'amount': bigIntWire.encode(v.amount),
    'message': v.message,
    'status': invoiceStatusWire.encode(v.status),
    'txId': v.txId,
    'kernelExcess': v.kernelExcess,
    'pairingId': v.pairingId,
    'reference': v.reference,
  },
  (r) => PaidInvoice(
    slateId: r.of('slateId', stringWire),
    senderAddress: r.of('senderAddress', stringWire),
    amount: r.of('amount', bigIntWire),
    message: r.of('message', optString),
    status: r.of('status', invoiceStatusWire),
    txId: r.of('txId', optInt),
    kernelExcess: r.of('kernelExcess', optString),
    pairingId: r.of('pairingId', optString),
    reference: r.of('reference', optString),
  ),
);

final WireCodec<PaidRequestFile> paidRequestFileWire = _object<PaidRequestFile>(
  'PaidRequestFile',
  (v) => {
    'txId': v.txId,
    'slateId': v.slateId,
    'amount': bigIntWire.encode(v.amount),
    'fee': bigIntWire.encode(v.fee),
    'json': v.json,
  },
  (r) => PaidRequestFile(
    txId: r.of('txId', intWire),
    slateId: r.of('slateId', stringWire),
    amount: r.of('amount', bigIntWire),
    fee: r.of('fee', bigIntWire),
    json: r.of('json', stringWire),
  ),
);

final WireCodec<InvoiceEvent> invoiceEventWire = _object<InvoiceEvent>(
  'InvoiceEvent',
  (v) => {
    'kind': invoiceEventKindWire.encode(v.kind),
    'slateId': v.slateId,
    'kernelExcess': v.kernelExcess,
  },
  (r) => InvoiceEvent(
    kind: r.of('kind', invoiceEventKindWire),
    slateId: r.of('slateId', stringWire),
    kernelExcess: r.of('kernelExcess', optString),
  ),
);

final WireCodec<InvoiceDrainReport> invoiceDrainReportWire =
    _object<InvoiceDrainReport>(
      'InvoiceDrainReport',
      (v) => {
        'parked': v.parked,
        'finalized': v.finalized,
        'dropped': v.dropped,
        'notices': v.notices,
      },
      (r) => InvoiceDrainReport(
        parked: r.of('parked', intWire),
        finalized: r.of('finalized', intWire),
        dropped: r.of('dropped', intWire),
        notices: r.of('notices', intWire),
      ),
    );

final WireCodec<IssuedInvoice> issuedInvoiceWire = _object<IssuedInvoice>(
  'IssuedInvoice',
  (v) => {
    'slateId': v.slateId,
    'txId': v.txId,
    'payerAddress': v.payerAddress,
    'pairingId': v.pairingId,
    'amount': bigIntWire.encode(v.amount),
    'message': v.message,
    'issuedAt': timeWire.encode(v.issuedAt),
    'expiresAt': timeWire.encode(v.expiresAt),
    'state': issuedInvoiceStateWire.encode(v.state),
  },
  (r) => IssuedInvoice(
    slateId: r.of('slateId', stringWire),
    txId: r.of('txId', intWire),
    payerAddress: r.of('payerAddress', stringWire),
    pairingId: r.of('pairingId', optString),
    amount: r.of('amount', bigIntWire),
    message: r.of('message', optString),
    issuedAt: r.of('issuedAt', timeWire),
    expiresAt: r.of('expiresAt', timeWire),
    state: r.of('state', issuedInvoiceStateWire),
  ),
);

final WireCodec<IssuerEvent> issuerEventWire = _object<IssuerEvent>(
  'IssuerEvent',
  (v) => {
    'kind': issuerEventKindWire.encode(v.kind),
    'slateId': v.slateId,
    'payerAddress': v.payerAddress,
    'pairingId': v.pairingId,
  },
  (r) => IssuerEvent(
    kind: r.of('kind', issuerEventKindWire),
    slateId: r.of('slateId', stringWire),
    payerAddress: r.of('payerAddress', optString),
    pairingId: r.of('pairingId', optString),
  ),
);

final WireCodec<PaymentsDrainReport> paymentsDrainReportWire =
    _object<PaymentsDrainReport>(
      'PaymentsDrainReport',
      (v) => {
        'received': v.received,
        'finalized': v.finalized,
        'bounced': v.bounced,
      },
      (r) => PaymentsDrainReport(
        received: r.of('received', intWire),
        finalized: r.of('finalized', intWire),
        bounced: r.of('bounced', intWire),
      ),
    );

/// An open session as the server names it: its handle, [WalletSession.supportsInvoices],
/// whether its core pairs ([PairingApi.supported]) and [WalletSession.supportsRequestFiles].
typedef SessionRef = ({String handle, bool invoices, bool pairing, bool requestFiles});

final WireCodec<SessionRef> sessionRefWire = _object<SessionRef>(
  'SessionRef',
  (v) => {'s': v.handle, 'invoices': v.invoices, 'pairing': v.pairing, 'requestFiles': v.requestFiles},
  (r) => (
    handle: r.of('s', stringWire),
    invoices: r.of('invoices', boolWire),
    pairing: r.of('pairing', nullable(boolWire)) ?? false,
    requestFiles: r.of('requestFiles', nullable(boolWire)) ?? false,
  ),
);

/// [WalletService.createWithPin]'s record, with the session as a [SessionRef].
typedef PinWalletRef = ({SessionRef session, String sealedPassword});

final WireCodec<PinWalletRef> pinWalletRefWire = _object<PinWalletRef>(
  'PinWallet',
  (v) => {
    'session': sessionRefWire.encode(v.session),
    'sealedPassword': v.sealedPassword,
  },
  (r) => (
    session: r.of('session', sessionRefWire),
    sealedPassword: r.of('sealedPassword', stringWire),
  ),
);

// Pairing (RFC 0002).

final WireCodec<PairingState> pairingStateWire = enumWire('PairingState', PairingState.values);
final WireCodec<PairingParty> pairingPartyWire = enumWire('PairingParty', PairingParty.values);
final WireCodec<SealMode> sealModeWire = enumWire('SealMode', SealMode.values);
final WireCodec<PairingWay> pairingWayWire = enumWire('PairingWay', PairingWay.values);
final WireCodec<PairingCheck> pairingCheckWire = enumWire('PairingCheck', PairingCheck.values);
final WireCodec<KeysChoice> keysChoiceWire = enumWire('KeysChoice', KeysChoice.values);
final WireCodec<PairingFailure> pairingFailureWire = enumWire('PairingFailure', PairingFailure.values);
final WireCodec<PairingEventKind> pairingEventKindWire = enumWire('PairingEventKind', PairingEventKind.values);
final WireCodec<DateTime?> optTime = nullable(timeWire);

final WireCodec<SasWord> sasWordWire = _object<SasWord>(
  'SasWord',
  (v) => {'emoji': v.emoji, 'name': v.name},
  (r) => SasWord(r.of('emoji', stringWire), r.of('name', stringWire)),
);

final WireCodec<PairingRecord> pairingRecordWire = _object<PairingRecord>(
  'PairingRecord',
  (v) => {
    'id': v.id,
    'state': pairingStateWire.encode(v.state),
    'way': pairingWayWire.encode(v.way),
    'inviter': v.inviter,
    'createdAt': timeWire.encode(v.createdAt),
    'name': v.name,
    'label': v.label,
    'kind': pairingPartyWire.encode(v.kind),
    'caps': v.caps.bits,
    'sas': listOf(sasWordWire).encode(v.sas),
    'verifiedAt': optTime.encode(v.verifiedAt),
    'checkSkipped': v.checkSkipped,
    'allowInvoices': v.allowInvoices,
    'asksInvoices': v.asksInvoices,
    'seal': sealModeWire.encode(v.seal),
    'homeRelay': v.homeRelay,
    'contactId': v.contactId,
    'paymentsAddress': v.paymentsAddress,
    'lastSealedIn': optTime.encode(v.lastSealedIn),
    'expiresAt': optTime.encode(v.expiresAt),
    'inviteLink': v.inviteLink,
    'inviteWords': listOf(sasWordWire).encode(v.inviteWords),
    'relayDown': v.relayDown,
    'otherDevice': v.otherDevice,
    'removedByPeer': v.removedByPeer,
  },
  (r) => PairingRecord(
    id: r.of('id', stringWire),
    state: r.of('state', pairingStateWire),
    way: r.of('way', pairingWayWire),
    inviter: r.of('inviter', boolWire),
    createdAt: r.of('createdAt', timeWire),
    name: r.of('name', optString),
    label: r.of('label', optString),
    kind: r.of('kind', pairingPartyWire),
    caps: PairingCaps.fromBits(r.of('caps', intWire)),
    sas: r.of('sas', listOf(sasWordWire)),
    verifiedAt: r.of('verifiedAt', optTime),
    checkSkipped: r.of('checkSkipped', boolWire),
    allowInvoices: r.of('allowInvoices', boolWire),
    asksInvoices: r.of('asksInvoices', boolWire),
    seal: r.of('seal', sealModeWire),
    homeRelay: r.of('homeRelay', stringWire),
    contactId: r.of('contactId', optString),
    paymentsAddress: r.of('paymentsAddress', optString),
    lastSealedIn: r.of('lastSealedIn', optTime),
    expiresAt: r.of('expiresAt', optTime),
    inviteLink: r.of('inviteLink', optString),
    inviteWords: r.of('inviteWords', listOf(sasWordWire)),
    relayDown: r.of('relayDown', boolWire),
    otherDevice: r.of('otherDevice', boolWire),
    removedByPeer: r.of('removedByPeer', boolWire),
  ),
);

final WireCodec<PairingInvitePreview> pairingPreviewWire = _object<PairingInvitePreview>(
  'PairingInvitePreview',
  (v) => {
    'token': v.token,
    'name': v.name,
    'expiresAt': timeWire.encode(v.expiresAt),
    'kind': pairingPartyWire.encode(v.kind),
    'asksInvoices': v.asksInvoices,
    'homeRelay': v.homeRelay,
    'wordsAvailable': v.wordsAvailable,
  },
  (r) => PairingInvitePreview(
    token: r.of('token', stringWire),
    name: r.of('name', stringWire),
    expiresAt: r.of('expiresAt', timeWire),
    kind: r.of('kind', pairingPartyWire),
    asksInvoices: r.of('asksInvoices', boolWire),
    homeRelay: r.of('homeRelay', stringWire),
    wordsAvailable: r.of('wordsAvailable', boolWire),
  ),
);

final WireCodec<PairingCard> pairingCardWire = _object<PairingCard>(
  'PairingCard',
  (v) => {'id': v.id, 'link': v.link},
  (r) => PairingCard(id: r.of('id', stringWire), link: r.of('link', stringWire)),
);

final WireCodec<PairingStray> pairingStrayWire = _object<PairingStray>(
  'PairingStray',
  (v) => {'id': v.id, 'inviteId': v.inviteId, 'name': v.name},
  (r) => PairingStray(id: r.of('id', stringWire), inviteId: r.of('inviteId', stringWire), name: r.of('name', stringWire)),
);

final WireCodec<PairingEvent> pairingEventWire = _object<PairingEvent>(
  'PairingEvent',
  (v) => {
    'kind': pairingEventKindWire.encode(v.kind),
    'pairingId': v.pairingId,
    'name': v.name,
    'failure': nullable(pairingFailureWire).encode(v.failure),
    'slateId': v.slateId,
    'amount': optBigInt.encode(v.amount),
    'count': v.count,
  },
  (r) => PairingEvent(
    r.of('kind', pairingEventKindWire),
    pairingId: r.of('pairingId', optString),
    name: r.of('name', stringWire),
    failure: r.of('failure', nullable(pairingFailureWire)),
    slateId: r.of('slateId', optString),
    amount: r.of('amount', optBigInt),
    count: r.of('count', intWire),
  ),
);

final WireCodec<SlatePurpose> slatePurposeWire = enumWire('SlatePurpose', SlatePurpose.values);

final WireCodec<PairingSlate> pairingSlateWire = _object<PairingSlate>(
  'PairingSlate',
  (v) => {'pairingId': v.pairingId, 'purpose': slatePurposeWire.encode(v.purpose), 'reference': v.reference},
  (r) => PairingSlate(
    pairingId: r.of('pairingId', stringWire),
    purpose: r.of('purpose', slatePurposeWire),
    reference: r.of('reference', optString),
  ),
);

final WireCodec<OpenedSlate> openedSlateWire = _object<OpenedSlate>(
  'OpenedSlate',
  (v) => {
    'slateJson': v.slateJson,
    'pairingId': v.pairingId,
    'sealed': v.sealed,
    'stage': nullable(slateStageWire).encode(v.stage),
    'slateId': v.slateId,
    'amount': optBigInt.encode(v.amount),
    'fee': optBigInt.encode(v.fee),
    'purpose': nullable(slatePurposeWire).encode(v.purpose),
    'reference': v.reference,
    'messages': listOf(slateMessageWire).encode(v.messages),
  },
  (r) => OpenedSlate(
    slateJson: r.of('slateJson', optString),
    pairingId: r.of('pairingId', optString),
    sealed: r.of('sealed', boolWire),
    stage: r.of('stage', nullable(slateStageWire)),
    slateId: r.of('slateId', optString),
    amount: r.of('amount', optBigInt),
    fee: r.of('fee', optBigInt),
    purpose: r.of('purpose', nullable(slatePurposeWire)),
    reference: r.of('reference', optString),
    messages: r.of('messages', listOf(slateMessageWire)),
  ),
);

final WireCodec<PaidSealedRequest> paidSealedRequestWire = _object<PaidSealedRequest>(
  'PaidSealedRequest',
  (v) => {'paid': paidRequestFileWire.encode(v.paid), 'sealed': v.sealed},
  (r) => PaidSealedRequest(paid: r.of('paid', paidRequestFileWire), sealed: r.of('sealed', boolWire)),
);

final WireCodec<SealedReply> sealedReplyWire = _object<SealedReply>(
  'SealedReply',
  (v) => {'slateId': v.slateId, 'answer': v.answer, 'sealed': v.sealed, 'repeated': v.repeated},
  (r) => SealedReply(
    slateId: r.of('slateId', stringWire),
    answer: r.of('answer', stringWire),
    sealed: r.of('sealed', boolWire),
    repeated: r.of('repeated', boolWire),
  ),
);

final WireCodec<PairingCollectTrigger> pairingCollectTriggerWire = enumWire('PairingCollectTrigger', PairingCollectTrigger.values);
