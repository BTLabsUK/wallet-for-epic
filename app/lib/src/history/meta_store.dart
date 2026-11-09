// SPDX-License-Identifier: Apache-2.0
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

import '../name_service/pins.dart' show LinkPaymentRec, ListingPin;
import '../contact_label.dart';
import '../log.dart';
import '../recipient.dart';
import '../sealed_file.dart';
import '../wallet_service.dart';
import 'domain_check_book.dart';
import 'relay_move_book.dart';

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
    this.label,
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
      label: ContactLabel.fromStored(m['label']).stored,
    );
  }

  String id;
  String name;
  String? epicbox;
  String? http;
  String? tor;
  String? note;

  /// `exchange`, `vendor` or `service`; null for the default (a wallet).
  String? label;

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
    _put(out, 'label', label);
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

/// A slate message as a history file keeps it: who signed it (`sender` or `receiver`) and
/// its text.
class SlateMessageRec {
  SlateMessageRec({required this.role, required this.text});

  factory SlateMessageRec.fromJson(Object? json) {
    final m = asObject(json, 'slate message');
    return SlateMessageRec(
      role: _str(m['role'], 'slate message role'),
      text: _str(m['text'], 'slate message text'),
    );
  }

  final String role;
  final String text;

  Map<String, Object?> toJson() => {'role': role, 'text': text};
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
    this.flow,
    this.pairingId,
    List<SlateMessageRec>? slateMessages,
  }) : userFields = userFields ?? [],
       slateMessages = slateMessages ?? [],
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
      flow: _optStr(m['flow'], 'flow'),
      pairingId: _optStr(m['pairing_id'], 'pairing_id'),
      slateMessages: m['slate_messages'] == null
          ? null
          : m['slate_messages'] is List
          ? [for (final x in m['slate_messages'] as List) SlateMessageRec.fromJson(x)]
          : _bad('slate_messages'),
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

  /// What carried the slate (`epicbox`, `http`, `tor`, `file`). Kept in the archive when the
  /// wallet recorded it; one the user typed ([userFields] `method`) goes to [Meta.manual].
  String? transport;

  /// Which of `label`, `counterparty`, `method` ([transport]) and `note` the user entered, in
  /// a history file only.
  List<String> userFields;

  /// When the user last changed those (unix seconds), in a history file only.
  int? userEditedAtUnix;

  /// `invoice` for a payment an invoice started (either way); null for a payment. Since
  /// version 2 of the history file.
  String? flow;

  /// The pairing the payment went to or came from, as LEPIC linked it. Since version 2.
  String? pairingId;

  /// The parties' messages signed into the slate, as the app showed them. The old core's
  /// [messages] stay as they were written. Since version 2.
  List<SlateMessageRec> slateMessages;

  /// This record without what the user entered, as the archive keeps it: that goes to
  /// [Meta.manual]. A method the wallet recorded stays.
  Record withoutUserFields() => copy()
    ..label = null
    ..transport = userFields.contains('method') ? null : transport
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
    _put(out, 'flow', flow);
    _put(out, 'pairing_id', pairingId);
    if (slateMessages.isNotEmpty) {
      out['slate_messages'] = [for (final x in slateMessages) x.toJson()];
    }
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
    flow ??= other.flow;
    pairingId ??= other.pairingId;
    if (slateMessages.isEmpty) slateMessages = [...other.slateMessages];
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

/// [Meta.lastActivity]: when this wallet last synced, and the chain height it reached.
class LastActivity {
  const LastActivity({required this.atUnix, required this.height});

  factory LastActivity.fromJson(Object? json) {
    final m = asObject(json, 'last_activity');
    return LastActivity(atUnix: _i64(m['at_unix'], 'last_activity at_unix'), height: _u64(m['height'], 'last_activity height'));
  }

  /// UTC seconds.
  final int atUnix;
  final BigInt height;

  Map<String, Object?> toJson() => {'at_unix': atUnix, 'height': _u64Json(height)};
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
    Map<String, PaidInvoiceRec>? paidInvoices,
    Map<String, IssuedInvoiceRec>? issuedInvoices,
    Map<String, ManualRec>? manual,
    this.lastActivity,
    Iterable<String>? favourites,
    Iterable<String>? seededContacts,
    Map<String, String>? seededAddresses,
    Map<String, ListingPin>? nameServicePins,
    Map<String, int>? paidRequests,
    Map<String, LinkPaymentRec>? linkPayments,
    Map<String, String>? epic1Payments,
    RelayMoveBook? relayMoves,
    DomainCheckBook? domainChecks,
  }) : relayMoves = relayMoves ?? RelayMoveBook(),
       domainChecks = domainChecks ?? DomainCheckBook(),
       manual = SplayTreeMap.of(manual ?? const {}),
       favourites = SplayTreeSet.of(favourites ?? const []),
       seededContacts = SplayTreeSet.of(seededContacts ?? const []),
       seededAddresses = SplayTreeMap.of(seededAddresses ?? const {}),
       nameServicePins = SplayTreeMap.of(nameServicePins ?? const {}),
       paidRequests = SplayTreeMap.of(paidRequests ?? const {}),
       linkPayments = SplayTreeMap.of(linkPayments ?? const {}),
       epic1Payments = SplayTreeMap.of(epic1Payments ?? const {}),
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
      paidInvoices: map('paid_invoices')
          .map((k, v) => MapEntry(k, PaidInvoiceRec.fromJson(v))),
      issuedInvoices: map('issued_invoices')
          .map((k, v) => MapEntry(k, IssuedInvoiceRec.fromJson(v))),
      manual: map('manual').map((k, v) => MapEntry(k, ManualRec.fromJson(v))),
      lastActivity: m['last_activity'] == null ? null : LastActivity.fromJson(m['last_activity']),
      favourites: [for (final v in list('favourites')) _str(v, 'favourite')],
      seededContacts: [for (final v in list('seeded_contacts')) _str(v, 'seeded contact')],
      seededAddresses: map('seeded_addresses').map((k, v) => MapEntry(k, _str(v, 'seeded address'))),
      nameServicePins: map('name_service_pins').map((k, v) {
        final pin = asObject(v, 'name service pin');
        return MapEntry(
          k,
          ListingPin(
            listingKey: _str(pin['listing_key'], 'name service pin'),
            firstPaid: _i64(pin['first_paid'], 'name service pin'),
            lastPaid: _i64(pin['last_paid'], 'name service pin'),
          ),
        );
      }),
      paidRequests: map('paid_requests').map((k, v) => MapEntry(k, _i64(v, 'paid request'))),
      linkPayments: map('link_payments').map((k, v) {
        final r = asObject(v, 'link payment');
        return MapEntry(
          k,
          LinkPaymentRec(
            reqid: _str(r['reqid'], 'link payment'),
            serviceKey: _str(r['dkey'], 'link payment'),
            label: _optStr(r['label'], 'link payment'),
            amount: BigInt.parse(_str(r['amount'], 'link payment')),
            address: _str(r['address'], 'link payment'),
            paidAt: _i64(r['paid_at'], 'link payment'),
            told: {
              for (final s in (r['told'] as List? ?? const [])) _i64(s, 'link payment'),
            },
          ),
        );
      }),
      epic1Payments: map('epic1_payments').map((k, v) => MapEntry(k, _str(v, 'epic1 payment'))),
      relayMoves: _relayMoves(m['relay_moves']),
      domainChecks: _domainChecks(m['domain_checks']),
    );
  }

  static RelayMoveBook _relayMoves(Object? json) {
    try {
      return RelayMoveBook.fromJson(json);
    } on FormatException catch (e) {
      _bad(e.message);
    }
  }

  static DomainCheckBook _domainChecks(Object? json) {
    try {
      return DomainCheckBook.fromJson(json);
    } on FormatException catch (e) {
      _bad(e.message);
    }
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
  /// transaction key. Written only when not empty, as [paidInvoices].
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

  /// Invoices the user approved, by slate id. Written only when not empty, so a file
  /// without invoices stays as the old core wrote it. Not part of a history file: they describe this install's replies.
  final SplayTreeMap<String, PaidInvoiceRec> paidInvoices;

  /// Invoices this wallet issued, by slate id. Written only when not empty, and not part of
  /// a history file, as [paidInvoices].
  final SplayTreeMap<String, IssuedInvoiceRec> issuedInvoices;

  /// When this wallet last synced or refreshed, and its height then. Written only when set, and
  /// not part of a history file.
  LastActivity? lastActivity;

  /// Ids of the contacts this wallet starred. The address book is shared by every wallet on
  /// the device; the star is this wallet's, as on the desktop. Written only when not empty, and
  /// not part of a history file.
  final SplayTreeSet<String> favourites;

  /// Ids of the seed contacts (`seed_contacts.dart`) this wallet has been given once, whether
  /// or not they are still in the book: a deleted one is never added again. Written only when
  /// not empty, and not part of a history file.
  final SplayTreeSet<String> seededContacts;

  /// The address this wallet last wrote for each seed contact (by seed id): a book entry still
  /// at it is untouched, so it follows a new address from the signed btlabs.json. Written only
  /// when not empty, and not part of a history file.
  final SplayTreeMap<String, String> seededAddresses;

  /// The listing key paid for each name service listing (`<serviceKey>:<handle>`, hex), from payment
  /// links. Written only when not empty, and not part of a history file.
  final SplayTreeMap<String, ListingPin> nameServicePins;

  /// Request ids (hex) of payment links paid, with the unix second, kept 30 days. Written only
  /// when not empty, and not part of a history file.
  final SplayTreeMap<String, int> paidRequests;

  /// Payments made from payment links, by slate id: what the receipt line and the
  /// silent-payee rows need. Kept 30 days. Written only when not empty, and not part of a
  /// history file.
  final SplayTreeMap<String, LinkPaymentRec> linkPayments;

  /// epic1 exchanges by slate id: how each went (`Epic1Via.stored`: a link or an in-person
  /// code), which LEPIC lists as file sends. Written only when not empty, and not part of a
  /// history file.
  final SplayTreeMap<String, String> epic1Payments;

  /// Contacts' relay moves this wallet made, showed or refused (`relay_moves.dart`), under one
  /// versioned key. Written only when not empty, and not part of a history file.
  final RelayMoveBook relayMoves;

  /// The last domain check of each paired contact (`domain_check.dart`), under one versioned
  /// key. Written only when not empty, and not part of a history file.
  final DomainCheckBook domainChecks;

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
    _put(out, 'last_activity', lastActivity?.toJson());
    if (favourites.isNotEmpty) out['favourites'] = [...favourites];
    if (seededContacts.isNotEmpty) out['seeded_contacts'] = [...seededContacts];
    if (seededAddresses.isNotEmpty) out['seeded_addresses'] = {...seededAddresses};
    if (nameServicePins.isNotEmpty) {
      out['name_service_pins'] = {for (final e in nameServicePins.entries) e.key: e.value.toJson()};
    }
    if (paidRequests.isNotEmpty) out['paid_requests'] = {...paidRequests};
    if (linkPayments.isNotEmpty) {
      out['link_payments'] = {for (final e in linkPayments.entries) e.key: e.value.toJson()};
    }
    if (epic1Payments.isNotEmpty) out['epic1_payments'] = {...epic1Payments};
    if (!relayMoves.isEmpty) out['relay_moves'] = relayMoves.toJson();
    if (!domainChecks.isEmpty) out['domain_checks'] = domainChecks.toJson();
    return out;
  }

  /// A deep copy, for [MetaStore.update] to change.
  Meta copy() => Meta.fromJson(jsonDecode(encodeJson(toJson())));
}

/// Adds to [into] what [plain] holds and [into] lacks: a plain `wfe_meta.json` an older build
/// changed after the sealed file was made. Only adds; where both hold an entry, [into] wins.
/// Returns whether anything was added.
bool mergePlainMeta(Meta into, Meta plain) {
  final before = encodeJson(into.toJson());
  void maps<V>(Map<String, V> to, Map<String, V> from) {
    for (final e in from.entries) {
      to.putIfAbsent(e.key, () => e.value);
    }
  }

  maps(into.notes, plain.notes);
  maps(into.manual, plain.manual);
  maps(into.annotations, plain.annotations);
  maps(into.blockTimes, plain.blockTimes);
  maps(into.kernelHeights, plain.kernelHeights);
  maps(into.blockTimeMisses, plain.blockTimeMisses);
  maps(into.paidInvoices, plain.paidInvoices);
  maps(into.issuedInvoices, plain.issuedInvoices);
  maps(into.seededAddresses, plain.seededAddresses);
  maps(into.nameServicePins, plain.nameServicePins);
  maps(into.paidRequests, plain.paidRequests);
  maps(into.linkPayments, plain.linkPayments);
  maps(into.epic1Payments, plain.epic1Payments);
  into.relayMoves.addAll(plain.relayMoves);
  into.domainChecks.addAll(plain.domainChecks);
  into.lastActivity ??= plain.lastActivity;
  into.favourites.addAll(plain.favourites);
  into.seededContacts.addAll(plain.seededContacts);
  for (final c in plain.contacts) {
    if (!into.contacts.any((e) => e.id == c.id)) into.contacts.add(c);
  }
  for (final r in plain.records) {
    if (!into.records.any((e) => e.sameTx(r))) into.records.add(r);
  }
  return encodeJson(into.toJson()) != before;
}

/// The sealed archive beside the plain one.
const String metaSealedFileName = 'wfe_meta.sealed';

/// The archive of one wallet, loaded once per session.
///
/// Opened with an [AppDataSealer] (every LEPIC session), it lives in `wfe_meta.sealed` and
/// `wfe_meta.json` is only read: on the first open the plain file is sealed copy-then-switch
/// (`wfe_meta.sealed.tmp`, read back and opened, renamed), and left where it is for a rollback
/// to an older build. The sealed file records the plain file's size and hash; a plain file
/// changed since (an older build wrote it) is merged in at the next open, adding only.
class MetaStore {
  MetaStore._(this.path, this._meta, {this._sealer, this._walletId, this._plain, this.readOnly = false});

  /// An archive kept in memory only, for a session no file belongs to (tests).
  MetaStore.memory() : path = null, _meta = Meta(), _sealer = null, _walletId = null, readOnly = false;

  /// The file written: `wfe_meta.sealed` when sealed, else `wfe_meta.json`; null for
  /// [MetaStore.memory].
  final String? path;
  Meta _meta;
  bool _closed = false;
  Future<void> _tail = Future.value();
  final AppDataSealer? _sealer;
  final String? _walletId;
  PlainRecord? _plain;

  /// A sealed file this app may not rewrite (another wallet's, another kind, a later version):
  /// read as far as it goes, never written.
  final bool readOnly;

  bool get sealed => _sealer != null;

  /// Stores open on a wallet's archive (by its plain file's path), so a delete can stop their
  /// late writes.
  static final Map<String, Set<MetaStore>> _open = {};

  static String _fileOf(String dataDir, [String name = metaFileName]) =>
      File('$dataDir${Platform.pathSeparator}$name').absolute.path;

  /// Loads the archive of [dataDir]. With [sealer] (and the wallet's [walletId]) the sealed
  /// archive, migrated from `wfe_meta.json` the first time; without, `wfe_meta.json` itself.
  static Future<MetaStore> open(String dataDir, {AppDataSealer? sealer, String? walletId}) async {
    final MetaStore store;
    if (sealer == null) {
      final path = _fileOf(dataDir);
      store = MetaStore._(path, await _readPlain(path, moveAside: true) ?? Meta());
    } else {
      if (walletId == null || !sealedWalletIdPattern.hasMatch(walletId)) {
        throw _io('a sealed archive needs the wallet id');
      }
      store = await _openSealed(dataDir, sealer, walletId);
    }
    (_open[_fileOf(dataDir)] ??= {}).add(store);
    return store;
  }

  /// Reads `wfe_meta.json`, or null when there is none. One that cannot be parsed is moved aside
  /// to `wfe_meta.json.corrupt-<ms>` with [moveAside] (the plain archive in use, so notes are
  /// never destroyed silently and the wallet still opens), else left as it is and read as empty.
  static Future<Meta?> _readPlain(String path, {required bool moveAside}) async {
    final file = File(path);
    try {
      final bytes = await file.readAsBytes();
      try {
        return Meta.fromJson(jsonDecode(utf8.decode(bytes)));
      } on Object catch (e) {
        if (e is! FormatException && e is! MetaFormatException) rethrow;
        // Never the exception's text: Dart's FormatException quotes the source, which holds
        // notes and addresses. serde's error in the old core named only the position.
        final why = switch (e) {
          FormatException(:final offset) => offset == null ? 'not JSON' : 'not JSON at byte $offset',
          MetaFormatException(:final message) => 'wrong shape: $message',
          _ => 'unreadable',
        };
        if (!moveAside) {
          logWarn('history', '$metaFileName is unreadable ($why); not merged');
          return Meta();
        }
        logWarn('history', '$metaFileName is unreadable ($why); moved aside');
        // Timestamped, so a second damaged file does not replace the first.
        final aside = '$path.corrupt-${DateTime.now().millisecondsSinceEpoch}';
        try {
          await file.rename(aside);
        } on FileSystemException catch (e) {
          throw _io('moving $path: ${e.message}');
        }
        return Meta();
      }
    } on PathNotFoundException {
      return null;
    } on FileSystemException catch (e) {
      throw _io('reading $path: ${e.message}');
    }
  }

  /// The sealed open. Each step leaves a state the next open completes:
  /// 1. a `wfe_meta.sealed.tmp` is a write a crash cut short: deleted;
  /// 2. no sealed file: the plain one (or nothing) is sealed copy-then-switch; until the rename
  ///    nothing but the tmp changed, so a crash starts over;
  /// 3. a sealed file: opened; a plain file whose size or hash differs from the record is merged
  ///    in and the record moves, in one sealed write. Merging only adds, so doing it twice
  ///    changes nothing.
  /// The plain file is never written, renamed or deleted.
  static Future<MetaStore> _openSealed(String dataDir, AppDataSealer sealer, String walletId) async {
    final path = _fileOf(dataDir, metaSealedFileName);
    final plainPath = _fileOf(dataDir);
    try {
      await SealedFile.dropTmp(path);
    } on FileSystemException catch (e) {
      throw _io('deleting ${SealedFile.tmpOf(path)}: ${e.message}');
    }
    final PlainRecord? plainRec;
    SealedPayload? found;
    try {
      plainRec = await PlainRecord.ofFile(plainPath);
      found = await SealedFile.readSealed(path, sealer, kind: sealedKindMeta, walletId: walletId);
    } on SealedOpenError catch (e) {
      if (e.problem != SealedOpenProblem.damaged) {
        // Not this wallet's archive, or a later one: never overwritten. The plain file, if any,
        // shows what it can, read-only.
        logWarn('history', '$metaSealedFileName does not open here (${e.problem.name}); read-only');
        final plain = await _readPlain(plainPath, moveAside: false);
        return MetaStore._(path, plain ?? Meta(), sealer: sealer, walletId: walletId, readOnly: true);
      }
      logWarn('history', '$metaSealedFileName is damaged; moved aside');
      try {
        await File(path).rename('$path.corrupt-${DateTime.now().millisecondsSinceEpoch}');
      } on FileSystemException catch (e) {
        throw _io('moving $path: ${e.message}');
      }
      return _openSealed(dataDir, sealer, walletId);
    } on FileSystemException catch (e) {
      throw _io('reading $path: ${e.message}');
    }
    if (found != null) {
      final Meta meta;
      try {
        meta = Meta.fromJson(jsonDecode(utf8.decode(found.body)));
      } on Object catch (e) {
        if (e is! FormatException && e is! MetaFormatException) rethrow;
        // Sealed and intact, yet not an archive: kept as it is.
        logWarn('history', '$metaSealedFileName holds no archive; read-only');
        return MetaStore._(path, Meta(), sealer: sealer, walletId: walletId, readOnly: true);
      }
      final store = MetaStore._(
        path,
        meta,
        sealer: sealer,
        walletId: walletId,
        plain: found.plain,
        readOnly: found.version > sealedHeaderVersion,
      );
      if (plainRec != null && plainRec != found.plain && !store.readOnly && meta.version <= metaVersion) {
        final plain = await _readPlain(plainPath, moveAside: false) ?? Meta();
        final next = meta.copy();
        mergePlainMeta(next, plain);
        try {
          await store._writeSealed(next, plainRec);
          logInfo('history', '$metaFileName changed since it was sealed; merged in');
        } on WalletError {
          // Tried again at the next open; nothing was lost, the plain file is still there.
          logWarn('history', '$metaFileName changed since it was sealed; not merged yet');
        }
      }
      return store;
    }
    final plain = plainRec == null ? null : await _readPlain(plainPath, moveAside: false);
    final store = MetaStore._(path, plain ?? Meta(), sealer: sealer, walletId: walletId, plain: plainRec);
    if (plain != null) {
      try {
        await store._writeSealed(store._meta, plainRec);
        logInfo('history', '$metaFileName sealed');
      } on WalletError {
        // Disk full or the like: this session runs on the copy in memory; the next change, or
        // the next open, seals again. The plain file is still there.
        logWarn('history', '$metaFileName could not be sealed yet');
      }
    }
    return store;
  }

  /// Removes the archive of [dataDir] (plain and sealed), their temp files and the
  /// `.corrupt-<ms>` copies moved aside, and stops every store still open on it from writing, so
  /// no late call brings a file back and a new wallet in the same directory starts with no notes
  /// or contacts.
  static Future<void> deleteFiles(String dataDir) async {
    final path = _fileOf(dataDir);
    final sealedPath = _fileOf(dataDir, metaSealedFileName);
    for (final store in _open.remove(path) ?? const <MetaStore>{}) {
      store._closed = true;
    }
    final corrupt = <String>[];
    try {
      await for (final e in Directory(File(path).parent.path).list()) {
        final name = e.uri.pathSegments.last;
        if (e is File && (name.startsWith('$metaFileName.corrupt-') || name.startsWith('$metaSealedFileName.corrupt-'))) {
          corrupt.add(e.path);
        }
      }
    } on PathNotFoundException {
      return;
    } on FileSystemException catch (e) {
      throw _io('listing ${File(path).parent.path}: ${e.message}');
    }
    for (final name in [path, _tmpOf(path), sealedPath, SealedFile.tmpOf(sealedPath), ...corrupt]) {
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
    if (p == null) return;
    _open[_fileOf(File(p).parent.path)]?.remove(this);
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
    if (readOnly) throw _io('$path does not open as this wallet\'s archive; it is kept as it is');
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
      if (p != null && sealed) {
        await _writeSealed(next, _plain);
        return out;
      }
      if (p != null) await _writeAtomic(p, utf8.encode(text));
      _meta = next;
    }
    return out;
  }

  /// Seals [meta] with the record [plain] into the sealed file; the state moves only once the
  /// sealed copy is in place.
  Future<void> _writeSealed(Meta meta, PlainRecord? plain) async {
    final payload = SealedPayload(
      kind: sealedKindMeta,
      walletId: _walletId!,
      plain: plain,
      body: utf8.encode(encodeJson(meta.toJson())),
    );
    try {
      await SealedFile.writeSealed(path!, _sealer!, payload);
    } on FileSystemException catch (e) {
      throw _io('writing $path: ${e.message}');
    } on SealedOpenError catch (e) {
      throw _io('writing $path: the sealed copy did not open (${e.problem.name})');
    }
    _meta = meta;
    _plain = plain;
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
