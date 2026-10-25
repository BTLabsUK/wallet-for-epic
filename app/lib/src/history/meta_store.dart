/// The app's own history archive: `<data_dir>/wfe_meta.json`, in the format
/// `app/rust/src/core/meta.rs` writes, so a file of the old core opens here and the other way.
///
/// LEPIC's database stays the live ledger and is never written from here. This file holds what
/// LEPIC does not keep: notes, contacts, records imported from a history file, and what the old
/// core recorded (annotations, block caches), kept as it was. Balance never reads any of it.
///
/// Every change is written atomically: a temp file in the same directory, flushed, then renamed
/// over the old one. A file that does not parse is moved aside, never overwritten, and a file of
/// a newer version is read but never rewritten.
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import '../log.dart';
import '../recipient.dart';
import '../wallet_service.dart';

const String metaFileName = 'wfe_meta.json';

/// The version this app writes. A file with a higher one is read-only.
const int metaVersion = 1;

/// The archive's errors are the old core's: `io`, with a sentence for the log.
WalletError _io(String message) =>
    WalletError(kind: WalletErrorKind.io, message: message);

/// Thrown by the JSON readers for a value of the wrong shape. Inside [MetaStore] it means a
/// damaged file; inside an import, a damaged history file.
class MetaFormatException implements Exception {
  const MetaFormatException(this.message);

  final String message;

  @override
  String toString() => 'MetaFormatException: $message';
}

Never _bad(String what) => throw MetaFormatException(what);

Map<String, dynamic> asObject(Object? v, String what) =>
    v is Map<String, dynamic> ? v : _bad('$what is not an object');

String _str(Object? v, String what) => v is String ? v : _bad(what);

String? _optStr(Object? v, String what) => v == null ? null : _str(v, what);

bool _bool(Object? v, String what) => v is bool ? v : _bad(what);

/// A JSON number as serde reads a `u64`: a whole number from 0 to 2^64-1. Dart's JSON reader
/// gives a rounded double for one above 2^63-1, so a whole double up to 2^64 counts too, at
/// most 2^64-1. Only a hostile file holds such a value: all the Epic there is fits in 2^53.
BigInt _u64(Object? v, String what) {
  final max = (BigInt.one << 64) - BigInt.one;
  if (v is int) {
    if (v < 0) _bad(what);
    return BigInt.from(v);
  }
  if (v is double && v.isFinite && v >= 0 && v == v.truncateToDouble()) {
    final n = BigInt.from(v);
    if (n <= max + BigInt.one) return n > max ? max : n;
  }
  _bad(what);
}

BigInt? _optU64(Object? v, String what) => v == null ? null : _u64(v, what);

int _i64(Object? v, String what) => v is int ? v : _bad(what);

int? _optI64(Object? v, String what) => v == null ? null : _i64(v, what);

int _u32(Object? v, String what) {
  final n = _u64(v, what);
  if (n.bitLength > 32) _bad(what);
  return n.toInt();
}

/// A `u64` for [encodeJson]: an [int] when it fits, else the [BigInt] itself.
Object _u64Json(BigInt v) => v.isValidInt ? v.toInt() : v;

/// Compact JSON as serde writes it, with a [BigInt] as its digits: `jsonEncode` refuses one,
/// and a `u64` above 2^63-1 has no [int].
String encodeJson(Object? value) {
  final out = StringBuffer();
  void write(Object? v) {
    switch (v) {
      case null || bool() || num() || String():
        out.write(jsonEncode(v));
      case BigInt():
        out.write(v);
      case List():
        out.write('[');
        for (var i = 0; i < v.length; i++) {
          if (i > 0) out.write(',');
          write(v[i]);
        }
        out.write(']');
      case Map():
        out.write('{');
        var first = true;
        for (final e in v.entries) {
          if (!first) out.write(',');
          first = false;
          out.write(jsonEncode(e.key as String));
          out.write(':');
          write(e.value);
        }
        out.write('}');
      default:
        throw JsonUnsupportedObjectError(v);
    }
  }

  write(value);
  return out.toString();
}

void _put(Map<String, Object?> out, String key, Object? value) {
  if (value != null) out[key] = value;
}

/// A contact as the file keeps it. [address] is the first of its addresses (Epicbox, Tor,
/// HTTP), as the old core wrote it; a contact with several also writes [epicbox], [http] and
/// [tor]. A record with none of them reads [address] by its shape.
class ContactRec {
  /// [address] goes into the field of its kind, as for [Contact].
  ContactRec({
    required this.id,
    required this.name,
    String? address,
    String? epicbox,
    String? http,
    String? tor,
    this.note,
    this.invoiceAddress,
  }) : epicbox = epicbox ?? _kindOf(address, RecipientKind.epicbox),
       http = http ?? _kindOf(address, RecipientKind.http),
       tor = tor ?? _kindOf(address, RecipientKind.tor);

  static String? _kindOf(String? address, RecipientKind kind) =>
      address == null || address.trim().isEmpty || parseRecipient(address).kind != kind ? null : address;

  factory ContactRec.fromJson(Object? json) {
    final m = asObject(json, 'contact');
    final address = _optStr(m['address'], 'contact address') ?? '';
    final epicbox = _optStr(m['epicbox'], 'contact epicbox address');
    final http = _optStr(m['http'], 'contact http address');
    final tor = _optStr(m['tor'], 'contact tor address');
    final byKind = epicbox != null || http != null || tor != null;
    final kind = address.trim().isEmpty ? null : parseRecipient(address).kind;
    return ContactRec(
      id: _str(m['id'], 'contact id'),
      name: _str(m['name'], 'contact name'),
      epicbox: byKind ? epicbox : (kind == RecipientKind.epicbox ? address : null),
      http: byKind ? http : (kind == RecipientKind.http ? address : null),
      tor: byKind ? tor : (kind == RecipientKind.tor ? address : null),
      note: _optStr(m['note'], 'contact note'),
      invoiceAddress: _optStr(m['invoice_address'], 'contact invoice address'),
    );
  }

  String id;
  String name;
  String? epicbox;
  String? http;
  String? tor;
  String? note;

  /// Written only when set, so a file without it stays as the old core wrote it.
  String? invoiceAddress;

  String get address => epicbox ?? tor ?? http ?? '';

  Map<String, Object?> toJson() {
    final out = <String, Object?>{'id': id, 'name': name, 'address': address};
    // One address stays as the old core wrote it; with several, each in its kind's field.
    if ([epicbox, http, tor].nonNulls.length > 1) {
      _put(out, 'epicbox', epicbox);
      _put(out, 'http', http);
      _put(out, 'tor', tor);
    }
    _put(out, 'note', note);
    _put(out, 'invoice_address', invoiceAddress);
    return out;
  }
}

/// What the app knows of an invoice the user approved, keyed by slate id in
/// [Meta.paidInvoices]. LEPIC keeps the payment (`flow` invoice, outgoing) with its payee,
/// amount and message; whether the reply reached the service and the service's receipt are
/// the app's, since LEPIC tells them only as events. Fields of 1.5 records LEPIC now gives
/// are read past.
class PaidInvoiceRec {
  PaidInvoiceRec({required this.status, this.kernelExcess});

  factory PaidInvoiceRec.fromJson(Object? json) {
    final m = asObject(json, 'paid invoice');
    final status = _str(m['status'], 'paid invoice status');
    return PaidInvoiceRec(
      status:
          InvoiceStatus.values.where((s) => s.name == status).firstOrNull ??
          _bad('paid invoice status'),
      kernelExcess: _optStr(m['kernel_excess'], 'paid invoice kernel excess'),
    );
  }

  InvoiceStatus status;

  /// From the service's `posted` receipt.
  String? kernelExcess;

  Map<String, Object?> toJson() {
    final out = <String, Object?>{'status': status.name};
    _put(out, 'kernel_excess', kernelExcess);
    return out;
  }
}

/// What the app knows of an invoice this wallet issued, keyed by slate id in
/// [Meta.issuedInvoices]. LEPIC keeps the request (`flow` invoice, incoming) with its payer,
/// amount, message and time, but says only `cancelled` for a declined, withdrawn or bounced
/// one; the state here tells them apart and makes each notice go out once. Fields of
/// earlier records LEPIC now gives are read past.
class IssuedInvoiceRec {
  IssuedInvoiceRec({required this.state});

  factory IssuedInvoiceRec.fromJson(Object? json) {
    final m = asObject(json, 'issued invoice');
    final state = _str(m['state'], 'issued invoice state');
    return IssuedInvoiceRec(
      state:
          IssuedInvoiceState.values.where((s) => s.name == state).firstOrNull ??
          _bad('issued invoice state'),
    );
  }

  IssuedInvoiceState state;

  Map<String, Object?> toJson() => {'state': state.name};
}

/// Facts the old core recorded about one of its transactions, keyed by slate id. Kept as read;
/// this app only reads `counterparty`, `kernel_excess`, `finalized_at_unix` and `cancelled_by`.
class Annotation {
  Annotation({
    this.counterparty,
    this.finalized = false,
    this.kernelExcess,
    this.finalizedAtUnix,
    this.finalizedHeight,
    this.postError,
    this.postRefused = false,
    this.cancelledBy,
    this.kernelAbsentAt,
  });

  factory Annotation.fromJson(Object? json) {
    final m = asObject(json, 'annotation');
    return Annotation(
      counterparty: _optStr(m['counterparty'], 'counterparty'),
      finalized: m['finalized'] == null
          ? false
          : _bool(m['finalized'], 'finalized'),
      kernelExcess: _optStr(m['kernel_excess'], 'kernel_excess'),
      finalizedAtUnix: _optI64(m['finalized_at_unix'], 'finalized_at_unix'),
      finalizedHeight: _optU64(m['finalized_height'], 'finalized_height'),
      postError: _optStr(m['post_error'], 'post_error'),
      postRefused: m['post_refused'] == null
          ? false
          : _bool(m['post_refused'], 'post_refused'),
      cancelledBy: _optStr(m['cancelled_by'], 'cancelled_by'),
      kernelAbsentAt: _optU64(m['kernel_absent_at'], 'kernel_absent_at'),
    );
  }

  final String? counterparty;
  final bool finalized;
  final String? kernelExcess;
  final int? finalizedAtUnix;
  final BigInt? finalizedHeight;
  final String? postError;
  final bool postRefused;
  final String? cancelledBy;
  final BigInt? kernelAbsentAt;

  Map<String, Object?> toJson() {
    final out = <String, Object?>{};
    _put(out, 'counterparty', counterparty);
    if (finalized) out['finalized'] = true;
    _put(out, 'kernel_excess', kernelExcess);
    _put(out, 'finalized_at_unix', finalizedAtUnix);
    _put(
      out,
      'finalized_height',
      finalizedHeight == null ? null : _u64Json(finalizedHeight!),
    );
    _put(out, 'post_error', postError);
    if (postRefused) out['post_refused'] = true;
    _put(out, 'cancelled_by', cancelledBy);
    _put(
      out,
      'kernel_absent_at',
      kernelAbsentAt == null ? null : _u64Json(kernelAbsentAt!),
    );
    return out;
  }
}

/// What the user entered for one transaction beyond its note, keyed by [TxEntry.key] in
/// [Meta.manual]: a label on any transaction, and on one a scan restored who paid and how.
/// Notes stay in [Meta.notes]. Never passed to LEPIC, never used for payment proofs.
class ManualRec {
  ManualRec({
    this.label,
    this.counterparty,
    this.transport,
    this.editedAtUnix,
    Map<String, String>? declined,
  }) : declined = SplayTreeMap.of(declined ?? const {});

  factory ManualRec.fromJson(Object? json) {
    final m = asObject(json, 'manual record');
    return ManualRec(
      label: _optStr(m['label'], 'manual label'),
      counterparty: _optStr(m['counterparty'], 'manual counterparty'),
      transport: _optStr(m['transport'], 'manual transport'),
      editedAtUnix: _optI64(m['edited_at_unix'], 'manual edited_at_unix'),
      declined: m['declined'] == null
          ? null
          : asObject(m['declined'], 'manual declined')
                .map((k, v) => MapEntry(k, _str(v, 'manual declined'))),
    );
  }

  String? label;
  String? counterparty;

  /// LEPIC's transport name: `epicbox`, `http`, `tor` or `file`.
  String? transport;

  /// When the user last changed a field here (unix seconds).
  int? editedAtUnix;

  /// By field name ([ManualField.name]): SHA-256 (hex) of a history file's value the user
  /// chose not to take, so importing that file again does not ask again.
  final SplayTreeMap<String, String> declined;

  bool get isEmpty =>
      label == null &&
      counterparty == null &&
      transport == null &&
      declined.isEmpty;

  Map<String, Object?> toJson() {
    final out = <String, Object?>{};
    _put(out, 'label', label);
    _put(out, 'counterparty', counterparty);
    _put(out, 'transport', transport);
    _put(out, 'edited_at_unix', editedAtUnix);
    if (declined.isNotEmpty) out['declined'] = {...declined};
    return out;
  }
}

bool _pending(String status) =>
    status == 'AwaitingRecipient' || status == 'AwaitingConfirmation';

/// One transaction as it travels in a history file, and as it is kept once imported. Amounts
/// are in the smallest unit. Nothing in here is secret. Field names are the old core's.
class Record {
  Record({
    this.slateId,
    this.kernelExcess,
    this.kernelLookupMinHeight,
    required this.kind,
    required this.status,
    this.confirmed = false,
    this.createdAtUnix = 0,
    this.blockHeight,
    this.blockTimeUnix,
    BigInt? amountCredited,
    BigInt? amountDebited,
    this.fee,
    this.numInputs = 0,
    this.numOutputs = 0,
    List<String>? outputCommits,
    this.counterparty,
    this.note,
    this.ttlCutoffHeight,
    this.messages,
    this.paymentProof,
    this.statusDetail,
    this.cancelReason,
    this.exportedAtUnix,
    this.label,
    this.transport,
    List<String>? userFields,
    this.userEditedAtUnix,
  }) : userFields = userFields ?? [],
       amountCredited = amountCredited ?? BigInt.zero,
       amountDebited = amountDebited ?? BigInt.zero,
       outputCommits = outputCommits ?? [];

  /// Reads a record as serde does: `kind`, `status`, `confirmed`, `created_at_unix` and both
  /// amounts are required, everything else may be missing or null.
  factory Record.fromJson(Object? json) {
    final m = asObject(json, 'record');
    final commits = m['output_commits'];
    return Record(
      slateId: _optStr(m['slate_id'], 'slate_id'),
      kernelExcess: _optStr(m['kernel_excess'], 'kernel_excess'),
      kernelLookupMinHeight: _optU64(
        m['kernel_lookup_min_height'],
        'kernel_lookup_min_height',
      ),
      kind: _str(m['kind'], 'kind'),
      status: _str(m['status'], 'status'),
      confirmed: _bool(m['confirmed'], 'confirmed'),
      createdAtUnix: _i64(m['created_at_unix'], 'created_at_unix'),
      blockHeight: _optU64(m['block_height'], 'block_height'),
      blockTimeUnix: _optI64(m['block_time_unix'], 'block_time_unix'),
      amountCredited: _u64(m['amount_credited'], 'amount_credited'),
      amountDebited: _u64(m['amount_debited'], 'amount_debited'),
      fee: _optU64(m['fee'], 'fee'),
      numInputs: m['num_inputs'] == null
          ? 0
          : _u32(m['num_inputs'], 'num_inputs'),
      numOutputs: m['num_outputs'] == null
          ? 0
          : _u32(m['num_outputs'], 'num_outputs'),
      outputCommits: commits == null
          ? []
          : commits is List
          ? [for (final c in commits) _str(c, 'output commit')]
          : _bad('output_commits'),
      counterparty: _optStr(m['counterparty'], 'counterparty'),
      note: _optStr(m['note'], 'note'),
      ttlCutoffHeight: _optU64(m['ttl_cutoff_height'], 'ttl_cutoff_height'),
      messages: m['messages'],
      paymentProof: m['payment_proof'],
      statusDetail: _optStr(m['status_detail'], 'status_detail'),
      cancelReason: _optStr(m['cancel_reason'], 'cancel_reason'),
      exportedAtUnix: _optI64(m['exported_at_unix'], 'exported_at_unix'),
      label: _optStr(m['label'], 'label'),
      transport: _optStr(m['transport'], 'transport'),
      userFields: m['user_fields'] == null
          ? null
          : m['user_fields'] is List
          ? [for (final f in m['user_fields'] as List) _str(f, 'user field')]
          : _bad('user_fields'),
      userEditedAtUnix: _optI64(
        m['user_edited_at_unix'],
        'user_edited_at_unix',
      ),
    );
  }

  String? slateId;
  String? kernelExcess;
  BigInt? kernelLookupMinHeight;

  /// `TxKind` name of the old core: Coinbase, Received, Sent, ReceivedCancelled, SentCancelled.
  String kind;

  /// `TxStatus` name of the old core at export time.
  String status;
  bool confirmed;
  int createdAtUnix;
  BigInt? blockHeight;
  int? blockTimeUnix;
  BigInt amountCredited;
  BigInt amountDebited;
  BigInt? fee;
  int numInputs;
  int numOutputs;
  List<String> outputCommits;
  String? counterparty;
  String? note;
  BigInt? ttlCutoffHeight;

  /// epic-wallet's `ParticipantMessages` and `StoredProofInfo`, as the old core wrote them.
  Object? messages;
  Object? paymentProof;
  String? statusDetail;

  /// `CancelReason` name, for a cancelled record.
  String? cancelReason;

  /// `exported_at_unix` of the file this record's status came from. Set on import.
  int? exportedAtUnix;

  /// The user's label, in a history file only: an import moves it to [Meta.manual].
  String? label;

  /// What carried the slate (`epicbox`, `http`, `tor`, `file`), in a history file only.
  String? transport;

  /// Which of `label`, `counterparty`, `method` ([transport]) and `note` the user entered, in
  /// a history file only.
  List<String> userFields;

  /// When the user last changed those (unix seconds), in a history file only.
  int? userEditedAtUnix;

  /// This record without what only a history file carries, as the archive keeps it.
  Record withoutUserFields() => copy()
    ..label = null
    ..transport = null
    ..userFields = []
    ..userEditedAtUnix = null;

  Map<String, Object?> toJson() {
    final out = <String, Object?>{};
    _put(out, 'slate_id', slateId);
    _put(out, 'kernel_excess', kernelExcess);
    if (kernelLookupMinHeight != null) {
      out['kernel_lookup_min_height'] = _u64Json(kernelLookupMinHeight!);
    }
    out['kind'] = kind;
    out['status'] = status;
    out['confirmed'] = confirmed;
    out['created_at_unix'] = createdAtUnix;
    if (blockHeight != null) out['block_height'] = _u64Json(blockHeight!);
    _put(out, 'block_time_unix', blockTimeUnix);
    out['amount_credited'] = _u64Json(amountCredited);
    out['amount_debited'] = _u64Json(amountDebited);
    if (fee != null) out['fee'] = _u64Json(fee!);
    out['num_inputs'] = numInputs;
    out['num_outputs'] = numOutputs;
    out['output_commits'] = [...outputCommits];
    _put(out, 'counterparty', counterparty);
    _put(out, 'note', note);
    if (ttlCutoffHeight != null) {
      out['ttl_cutoff_height'] = _u64Json(ttlCutoffHeight!);
    }
    _put(out, 'messages', messages);
    _put(out, 'payment_proof', paymentProof);
    _put(out, 'status_detail', statusDetail);
    _put(out, 'cancel_reason', cancelReason);
    _put(out, 'exported_at_unix', exportedAtUnix);
    _put(out, 'label', label);
    _put(out, 'transport', transport);
    if (userFields.isNotEmpty) out['user_fields'] = [...userFields];
    _put(out, 'user_edited_at_unix', userEditedAtUnix);
    return out;
  }

  Record copy() => Record.fromJson(jsonDecode(encodeJson(toJson())));

  String get _canonical => encodeJson(toJson());

  /// Merges a record of the same transaction from another import into this one. Fields this
  /// one lacks are filled in (commitments are added); the status, kind and amounts are taken
  /// when the other file is newer, except that a settled status never goes back to pending.
  /// Returns true when anything the user can see changed.
  bool mergeFrom(Record other) {
    final before = _canonical;
    slateId ??= other.slateId;
    kernelExcess ??= other.kernelExcess;
    kernelLookupMinHeight ??= other.kernelLookupMinHeight;
    blockHeight ??= other.blockHeight;
    blockTimeUnix ??= other.blockTimeUnix;
    fee ??= other.fee;
    final newer = (other.exportedAtUnix ?? 0) > (exportedAtUnix ?? 0);
    // A newer file's note and counterparty are the user's latest edits.
    if (newer && other.note != null) note = other.note;
    if (newer && other.counterparty != null) counterparty = other.counterparty;
    counterparty ??= other.counterparty;
    note ??= other.note;
    ttlCutoffHeight ??= other.ttlCutoffHeight;
    messages ??= other.messages;
    paymentProof ??= other.paymentProof;
    for (final c in other.outputCommits) {
      if (!outputCommits.contains(c)) outputCommits.add(c);
    }
    if (newer && !(_pending(other.status) && !_pending(status))) {
      status = other.status;
      confirmed = other.confirmed;
      kind = other.kind;
      statusDetail = other.statusDetail;
      cancelReason = other.cancelReason;
      amountCredited = other.amountCredited;
      amountDebited = other.amountDebited;
      numInputs = other.numInputs;
      numOutputs = other.numOutputs;
    }
    // Measured before `exported_at_unix` moves: that alone is not a change the user sees.
    final changed = _canonical != before;
    if (newer) exportedAtUnix = other.exportedAtUnix;
    return changed;
  }

  /// Same transaction as [other]: shared slate id, kernel, or created output.
  bool sameTx(Record other) {
    bool eq(String? a, String? b) => a != null && b != null && a == b;
    return eq(slateId, other.slateId) ||
        eq(kernelExcess, other.kernelExcess) ||
        outputCommits.any(other.outputCommits.contains);
  }
}

class Meta {
  Meta({
    this.version = metaVersion,
    Map<String, String>? notes,
    List<ContactRec>? contacts,
    Map<String, Annotation>? annotations,
    List<Record>? records,
    Map<String, int>? blockTimes,
    Map<String, BigInt>? kernelHeights,
    Map<String, BigInt>? blockTimeMisses,
    this.cacheNode,
    Map<String, String>? serviceLabels,
    this.invoiceIndex,
    Map<String, PaidInvoiceRec>? paidInvoices,
    Map<String, IssuedInvoiceRec>? issuedInvoices,
    Map<String, ManualRec>? manual,
  }) : manual = SplayTreeMap.of(manual ?? const {}),
       serviceLabels = SplayTreeMap.of(serviceLabels ?? const {}),
       paidInvoices = SplayTreeMap.of(paidInvoices ?? const {}),
       issuedInvoices = SplayTreeMap.of(issuedInvoices ?? const {}),
       notes = SplayTreeMap.of(notes ?? const {}),
       contacts = contacts ?? [],
       annotations = SplayTreeMap.of(annotations ?? const {}),
       records = records ?? [],
       blockTimes = _byHeight(blockTimes ?? const {}),
       kernelHeights = SplayTreeMap.of(kernelHeights ?? const {}),
       blockTimeMisses = _byHeight(blockTimeMisses ?? const {});

  /// Reads a file as serde reads `Meta`: every field may be missing.
  factory Meta.fromJson(Object? json) {
    final m = asObject(json, 'archive');
    Map<String, Object?> map(String key) =>
        m[key] == null ? const {} : asObject(m[key], key);
    List<Object?> list(String key) => m[key] == null
        ? const []
        : m[key] is List
        ? m[key] as List
        : _bad(key);
    String heightKey(String k, String what) {
      // serde reads a `u64` map key from its digits.
      if (BigInt.tryParse(k) == null || k.startsWith('-')) _bad(what);
      return k;
    }

    return Meta(
      version: m['version'] == null
          ? metaVersion
          : _u32(m['version'], 'version'),
      notes: map('notes').map((k, v) => MapEntry(k, _str(v, 'note'))),
      contacts: [for (final c in list('contacts')) ContactRec.fromJson(c)],
      annotations: map('annotations')
          .map((k, v) => MapEntry(k, Annotation.fromJson(v))),
      records: [for (final r in list('records')) Record.fromJson(r)],
      blockTimes: map('block_times').map(
        (k, v) => MapEntry(heightKey(k, 'block_times'), _i64(v, 'block time')),
      ),
      kernelHeights: map('kernel_heights')
          .map((k, v) => MapEntry(k, _u64(v, 'kernel height'))),
      blockTimeMisses: map('block_time_misses').map(
        (k, v) => MapEntry(
          heightKey(k, 'block_time_misses'),
          _u64(v, 'block time miss'),
        ),
      ),
      cacheNode: _optStr(m['cache_node'], 'cache_node'),
      serviceLabels: map('service_labels')
          .map((k, v) => MapEntry(k, _str(v, 'service label'))),
      invoiceIndex: m['invoice_index'] == null
          ? null
          : _u32(m['invoice_index'], 'invoice_index'),
      paidInvoices: map('paid_invoices')
          .map((k, v) => MapEntry(k, PaidInvoiceRec.fromJson(v))),
      issuedInvoices: map('issued_invoices')
          .map((k, v) => MapEntry(k, IssuedInvoiceRec.fromJson(v))),
      manual: map('manual').map((k, v) => MapEntry(k, ManualRec.fromJson(v))),
    );
  }

  /// Heights as map keys, in numeric order as the old core's `BTreeMap<u64, _>` writes them.
  static SplayTreeMap<String, V> _byHeight<V>(Map<String, V> from) =>
      SplayTreeMap<String, V>.of(
        from,
        (a, b) => BigInt.parse(a).compareTo(BigInt.parse(b)),
      );

  final int version;

  /// Notes by transaction key (`TxEntry.key`).
  final SplayTreeMap<String, String> notes;

  /// What the user entered beyond notes (labels; sender and method of restored rows), by
  /// transaction key. Written only when not empty, as [serviceLabels].
  final SplayTreeMap<String, ManualRec> manual;
  final List<ContactRec> contacts;

  /// The old core's annotations by slate id.
  final SplayTreeMap<String, Annotation> annotations;
  final List<Record> records;

  /// The old core's block caches, kept so a file written back stays whole.
  final SplayTreeMap<String, int> blockTimes;
  final SplayTreeMap<String, BigInt> kernelHeights;
  final SplayTreeMap<String, BigInt> blockTimeMisses;
  final String? cacheNode;

  /// The user's labels of trusted invoice services, by the full epicbox address. The wallet
  /// keeps the addresses; only these names are the app's. Written only when not empty, so a
  /// file without invoices stays as the old core wrote it.
  final SplayTreeMap<String, String> serviceLabels;

  /// The address index of the current invoice address (1 or higher), which the seed does not
  /// hold. Null until the first rotation: the wallet starts at 1.
  int? invoiceIndex;

  /// Invoices the user approved, by slate id. Written only when not empty, as
  /// [serviceLabels]. Not part of a history file: they describe this install's replies.
  final SplayTreeMap<String, PaidInvoiceRec> paidInvoices;

  /// Invoices this wallet issued, by slate id. Written only when not empty, and not part of
  /// a history file, as [paidInvoices].
  final SplayTreeMap<String, IssuedInvoiceRec> issuedInvoices;

  /// The block time at [height], when cached and known.
  int? blockTime(BigInt height) {
    final t = blockTimes['$height'];
    return t != null && t > 0 ? t : null;
  }

  Map<String, Object?> toJson() {
    final out = <String, Object?>{
      'version': version,
      'notes': {...notes},
      'contacts': [for (final c in contacts) c.toJson()],
      'annotations': {
        for (final e in annotations.entries) e.key: e.value.toJson(),
      },
      'records': [for (final r in records) r.toJson()],
      'block_times': {...blockTimes},
      'kernel_heights': {
        for (final e in kernelHeights.entries) e.key: _u64Json(e.value),
      },
    };
    if (blockTimeMisses.isNotEmpty) {
      out['block_time_misses'] = {
        for (final e in blockTimeMisses.entries) e.key: _u64Json(e.value),
      };
    }
    _put(out, 'cache_node', cacheNode);
    if (serviceLabels.isNotEmpty) out['service_labels'] = {...serviceLabels};
    _put(out, 'invoice_index', invoiceIndex);
    if (paidInvoices.isNotEmpty) {
      out['paid_invoices'] = {
        for (final e in paidInvoices.entries) e.key: e.value.toJson(),
      };
    }
    if (issuedInvoices.isNotEmpty) {
      out['issued_invoices'] = {
        for (final e in issuedInvoices.entries) e.key: e.value.toJson(),
      };
    }
    if (manual.isNotEmpty) {
      out['manual'] = {for (final e in manual.entries) e.key: e.value.toJson()};
    }
    return out;
  }

  /// A deep copy, for [MetaStore.update] to change.
  Meta copy() => Meta.fromJson(jsonDecode(encodeJson(toJson())));
}

/// The archive of one wallet, loaded once per session.
class MetaStore {
  MetaStore._(this.path, this._meta);

  /// An archive kept in memory only, for a session no file belongs to (tests).
  MetaStore.memory() : path = null, _meta = Meta();

  /// The file, or null for [MetaStore.memory].
  final String? path;
  Meta _meta;
  bool _closed = false;
  Future<void> _tail = Future.value();

  /// Stores open on a file, so a delete can stop their late writes.
  static final Map<String, Set<MetaStore>> _open = {};

  static String _fileOf(String dataDir) =>
      File('$dataDir${Platform.pathSeparator}$metaFileName').absolute.path;

  /// Loads `<dataDir>/wfe_meta.json`, or starts empty when there is none. A file that cannot be
  /// parsed is moved aside to `wfe_meta.json.corrupt-<ms>` rather than overwritten, so notes
  /// are never destroyed silently, and the wallet still opens.
  static Future<MetaStore> open(String dataDir) async {
    final path = _fileOf(dataDir);
    final file = File(path);
    Meta meta;
    try {
      final bytes = await file.readAsBytes();
      try {
        meta = Meta.fromJson(jsonDecode(utf8.decode(bytes)));
      } on Object catch (e) {
        if (e is! FormatException && e is! MetaFormatException) rethrow;
        // Timestamped, so a second damaged file does not replace the first.
        final aside = '$path.corrupt-${DateTime.now().millisecondsSinceEpoch}';
        // Never the exception's text: Dart's FormatException quotes the source, which holds
        // notes and addresses. serde's error in the old core named only the position.
        final why = switch (e) {
          FormatException(:final offset) =>
            offset == null ? 'not JSON' : 'not JSON at byte $offset',
          MetaFormatException(:final message) => 'wrong shape: $message',
          _ => 'unreadable',
        };
        logWarn('history', '$metaFileName is unreadable ($why); moved aside');
        try {
          await file.rename(aside);
        } on FileSystemException catch (e) {
          throw _io('moving $path: ${e.message}');
        }
        meta = Meta();
      }
    } on PathNotFoundException {
      meta = Meta();
    } on FileSystemException catch (e) {
      throw _io('reading $path: ${e.message}');
    }
    final store = MetaStore._(path, meta);
    (_open[path] ??= {}).add(store);
    return store;
  }

  /// Removes the archive of [dataDir], its temp file and the `.corrupt-<ms>` copies moved aside,
  /// and stops every store still open on it from writing, so no late call brings the file back
  /// and a new wallet in the same directory starts with no notes or contacts.
  static Future<void> deleteFiles(String dataDir) async {
    final path = _fileOf(dataDir);
    for (final store in _open.remove(path) ?? const <MetaStore>{}) {
      store._closed = true;
    }
    final corrupt = <String>[];
    try {
      await for (final e in Directory(File(path).parent.path).list()) {
        if (e is File &&
            e.uri.pathSegments.last.startsWith('$metaFileName.corrupt-')) {
          corrupt.add(e.path);
        }
      }
    } on PathNotFoundException {
      return;
    } on FileSystemException catch (e) {
      throw _io('listing ${File(path).parent.path}: ${e.message}');
    }
    for (final name in [path, _tmpOf(path), ...corrupt]) {
      try {
        await File(name).delete();
      } on PathNotFoundException {
        // Nothing to remove.
      } on FileSystemException catch (e) {
        throw _io('deleting $name: ${e.message}');
      }
    }
  }

  static String _tmpOf(String path) =>
      '${path.substring(0, path.length - '.json'.length)}.tmp';

  /// The current state. Never change it: [update] makes the changes.
  Meta get snapshot => _meta;

  /// Ends this session's use of the file.
  void close() {
    _closed = true;
    final p = path;
    if (p != null) _open[p]?.remove(this);
  }

  /// Applies [change] to a copy and persists it. The state changes only if the write succeeds.
  /// Nothing is written when [change] leaves the state unchanged. Updates run one at a time.
  Future<R> update<R>(R Function(Meta meta) change) {
    final result = _tail.then((_) => _apply(change));
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<R> _apply<R>(R Function(Meta meta) change) async {
    if (_closed) throw _io('the wallet is closed or was deleted');
    if (_meta.version > metaVersion) {
      // Rewriting it would drop whatever the newer version added.
      throw _io(
        '$path was written by a newer version of the app; update the app to change notes, '
        'contacts or history',
      );
    }
    final next = _meta.copy();
    final out = change(next);
    // Compact, as the old core writes it.
    final text = encodeJson(next.toJson());
    if (text != encodeJson(_meta.toJson())) {
      final p = path;
      if (p != null) await _writeAtomic(p, utf8.encode(text));
      _meta = next;
    }
    return out;
  }

  /// Writes [bytes] to [path] so a crash leaves either the old file or the new one. The
  /// directory must exist: a wallet deleted while a call was still running must not come back
  /// as a directory holding only this file. Dart cannot sync a directory; the rename is what
  /// the old core relied on too where it could not.
  static Future<void> _writeAtomic(String path, List<int> bytes) async {
    final tmp = File(_tmpOf(path));
    try {
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(path);
    } on FileSystemException catch (e) {
      throw _io('writing $path: ${e.message}');
    }
  }
}
