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
final WireCodec<TxStatus> txStatusWire = enumWire('TxStatus', TxStatus.values);
final WireCodec<PeerCapability> peerCapabilityWire = enumWire(
  'PeerCapability',
  PeerCapability.values,
);
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
  (v) => {'id': v.id, 'name': v.name, 'address': v.address, 'note': v.note},
  (r) => Contact(
    id: r.of('id', stringWire),
    name: r.of('name', stringWire),
    address: r.of('address', stringWire),
    note: r.of('note', optString),
  ),
);

final WireCodec<FeeEstimate> feeEstimateWire = _object<FeeEstimate>(
  'FeeEstimate',
  (v) => {
    'amount': bigIntWire.encode(v.amount),
    'fee': bigIntWire.encode(v.fee),
  },
  (r) => FeeEstimate(
    amount: r.of('amount', bigIntWire),
    fee: r.of('fee', bigIntWire),
  ),
);

final WireCodec<ImportReport> importReportWire = _object<ImportReport>(
  'ImportReport',
  (v) => {
    'merged': v.merged,
    'added': v.added,
    'skipped': v.skipped,
    'contactsAdded': v.contactsAdded,
  },
  (r) => ImportReport(
    merged: r.of('merged', intWire),
    added: r.of('added', intWire),
    skipped: r.of('skipped', intWire),
    contactsAdded: r.of('contactsAdded', intWire),
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
  },
  (r) => ListenerEvent(
    kind: r.of('kind', listenerEventKindWire),
    slateId: r.of('slateId', optString),
    txId: r.of('txId', optInt),
    message: r.of('message', stringWire),
    amount: r.of('amount', optBigInt),
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

final WireCodec<TrustedService> trustedServiceWire = _object<TrustedService>(
  'TrustedService',
  (v) => {'address': v.address, 'label': v.label},
  (r) => TrustedService(
    address: r.of('address', stringWire),
    label: r.of('label', optString),
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
  },
  (r) => PendingInvoice(
    slateId: r.of('slateId', stringWire),
    senderAddress: r.of('senderAddress', stringWire),
    amount: r.of('amount', bigIntWire),
    message: r.of('message', optString),
    receivedAt: r.of('receivedAt', timeWire),
    expiresAt: r.of('expiresAt', timeWire),
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
  },
  (r) => PaidInvoice(
    slateId: r.of('slateId', stringWire),
    senderAddress: r.of('senderAddress', stringWire),
    amount: r.of('amount', bigIntWire),
    message: r.of('message', optString),
    status: r.of('status', invoiceStatusWire),
    txId: r.of('txId', optInt),
    kernelExcess: r.of('kernelExcess', optString),
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
  },
  (r) => IssuerEvent(
    kind: r.of('kind', issuerEventKindWire),
    slateId: r.of('slateId', stringWire),
    payerAddress: r.of('payerAddress', optString),
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

/// An open session as the server names it: its handle and [WalletSession.supportsInvoices].
typedef SessionRef = ({String handle, bool invoices});

final WireCodec<SessionRef> sessionRefWire = _object<SessionRef>(
  'SessionRef',
  (v) => {'s': v.handle, 'invoices': v.invoices},
  (r) => (handle: r.of('s', stringWire), invoices: r.of('invoices', boolWire)),
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
