// SPDX-License-Identifier: Apache-2.0
/// The transaction list: LEPIC's rows merged with the app's archive (`meta_store.dart`).
///
/// A port of `app/rust/src/core/history.rs`, where the live rows were epic-wallet's log. Here
/// they arrive as [TxEntry] from `lepicTxEntry`, so status, cancel and repost flags are
/// LEPIC's, and so are the output commitments each row created. Everything is pure, so the
/// rules are tested on synthetic rows.
///
/// - A live row absorbs an archive record matching by slate id, then kernel, then a created
///   commitment. Live status and amounts win, except on rows a scan rebuilt ([TxSource.restored]),
///   which only know one output: those take the record's kind, amounts and time.
/// - Keys are stable across restores: `s:<slate>`, else `k:<kernel>`, else `c:<commit>`, else
///   `l:<id>`. The two sides of a self-send share a slate id and get a suffix.
/// - A note belongs to a row by its key, or by an alias no other row carries. So does what the
///   user entered in [Meta.manual]: a label on any row; on a row a scan restored, who paid and
///   how, shown only where the row itself has nothing.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../wallet_service.dart';
import 'meta_store.dart';

String kindName(TxKind k) => switch (k) {
  TxKind.coinbase => 'Coinbase',
  TxKind.received => 'Received',
  TxKind.sent => 'Sent',
  TxKind.receivedCancelled => 'ReceivedCancelled',
  TxKind.sentCancelled => 'SentCancelled',
};

TxKind kindFrom(String s) => switch (s) {
  'Coinbase' => TxKind.coinbase,
  'Sent' => TxKind.sent,
  'ReceivedCancelled' => TxKind.receivedCancelled,
  'SentCancelled' => TxKind.sentCancelled,
  _ => TxKind.received,
};

String statusName(TxStatus s) => switch (s) {
  TxStatus.awaitingRecipient => 'AwaitingRecipient',
  TxStatus.awaitingConfirmation => 'AwaitingConfirmation',
  TxStatus.confirmed => 'Confirmed',
  TxStatus.cancelled => 'Cancelled',
};

TxStatus statusFrom(String s, {required bool confirmed}) => switch (s) {
  'AwaitingRecipient' => TxStatus.awaitingRecipient,
  'AwaitingConfirmation' => TxStatus.awaitingConfirmation,
  'Cancelled' => TxStatus.cancelled,
  'Confirmed' => TxStatus.confirmed,
  _ when confirmed => TxStatus.confirmed,
  _ => TxStatus.awaitingConfirmation,
};

String cancelReasonName(CancelReason c) => switch (c) {
  CancelReason.user => 'user',
  CancelReason.release => 'release',
  CancelReason.expiry => 'expiry',
  CancelReason.lateAnswer => 'late_answer',
  CancelReason.failed => 'failed',
};

CancelReason? cancelReasonFrom(String? s) => switch (s) {
  'user' => CancelReason.user,
  'release' => CancelReason.release,
  'expiry' => CancelReason.expiry,
  'late_answer' => CancelReason.lateAnswer,
  'failed' => CancelReason.failed,
  _ => null,
};

/// A record's flow: `invoice`, else a payment.
TxFlow flowFrom(String? s) => s == 'invoice' ? TxFlow.invoice : TxFlow.payment;

/// A record's slate messages, as the app shows them; a role it does not know is left out.
List<SlateMessage> slateMessagesOf(Record r) => [
  for (final x in r.slateMessages)
    if (SlateRole.values.asNameMap()[x.role] case final role?) SlateMessage(role: role, text: x.text),
];

String? _someStr(String? s) {
  final t = s?.trim();
  return t == null || t.isEmpty ? null : t;
}

bool _isIncoming(TxKind k) =>
    k == TxKind.received ||
    k == TxKind.receivedCancelled ||
    k == TxKind.coinbase;

/// One row while it is merged: [TxEntry]'s fields, changeable, plus what an export needs.
class MergedTx {
  MergedTx._from(TxEntry e)
    : key = e.key,
      id = e.id,
      slateId = e.slateId,
      kind = e.kind,
      status = e.status,
      source = e.source,
      createdAtUnix = e.createdAtUnix,
      timeUnix = e.timeUnix,
      confirmed = e.confirmed,
      blockHeight = e.blockHeight,
      blockTimeUnix = e.blockTimeUnix,
      amountCredited = e.amountCredited,
      amountDebited = e.amountDebited,
      fee = e.fee,
      numInputs = e.numInputs,
      numOutputs = e.numOutputs,
      kernelExcess = e.kernelExcess,
      outputCommits = [...e.outputCommits],
      counterparty = e.counterparty,
      transport = e.transport,
      note = e.note,
      label = e.label,
      manualFields = {...e.manualFields},
      manualEditedAtUnix = e.manualEditedAtUnix,
      messages = e.messages,
      ttlCutoffHeight = e.ttlCutoffHeight,
      cancellable = e.cancellable,
      repostable = e.repostable,
      undelivered = e.undelivered,
      posting = e.posting,
      statusDetail = e.statusDetail,
      releasable = e.releasable,
      finalizedAtUnix = e.finalizedAtUnix,
      cancelReason = e.cancelReason,
      flow = e.flow,
      senderReportedPostedAtUnix = e.senderReportedPostedAtUnix,
      senderReportedCancelledAtUnix = e.senderReportedCancelledAtUnix,
      receiverDeclinedAtUnix = e.receiverDeclinedAtUnix,
      pairingId = e.pairingId,
      origin = e.origin,
      spentCommits = e.spentCommits,
      unverified = e.unverified,
      epic1Via = e.epic1Via,
      sentPlain = e.sentPlain;

  String key;
  int? id;
  String? slateId;
  TxKind kind;
  TxStatus status;
  TxSource source;
  int createdAtUnix;
  int timeUnix;
  bool confirmed;
  BigInt? blockHeight;
  int? blockTimeUnix;
  BigInt amountCredited;
  BigInt amountDebited;
  BigInt? fee;
  int numInputs;
  int numOutputs;
  String? kernelExcess;
  List<String> outputCommits;
  String? counterparty;
  String? transport;
  String? note;
  String? label;
  Set<ManualField> manualFields;
  int? manualEditedAtUnix;

  /// The live row's slate messages, shown in details. Not exported: a backup's `messages` is
  /// [recordMessages].
  List<SlateMessage> messages;
  BigInt? ttlCutoffHeight;
  bool cancellable;
  bool repostable;
  bool undelivered;
  bool posting;
  String? statusDetail;
  bool releasable;
  int? finalizedAtUnix;
  CancelReason? cancelReason;

  /// From the live row, else the record's (a record of a version 1 file is a payment).
  TxFlow flow;

  /// From the live row: LEPIC's, never stored or exported.
  int? senderReportedPostedAtUnix;
  int? senderReportedCancelledAtUnix;
  int? receiverDeclinedAtUnix;

  /// From the live row, never stored or exported: whose spend it is, and the inputs LEPIC saw
  /// spent.
  TxOrigin origin;
  List<String> spentCommits;
  bool unverified;

  /// From the live row, else [Meta.epic1Payments]: never exported.
  Epic1Via? epic1Via;

  /// From the live row, else [Meta.plainResends]: never exported.
  bool sentPlain;

  /// LEPIC's link to a pairing, from the live row, else the record's: exported, so a restored
  /// wallet still knows which paired contact a payment was with.
  String? pairingId;

  /// Every key the transaction was ever known by, for notes.
  List<String> aliases = const [];
  BigInt? kernelLookupMinHeight;

  /// A record's `messages` as the old core wrote them, kept for the next export.
  Object? recordMessages;
  Object? paymentProof;

  TxEntry get tx => TxEntry(
    key: key,
    id: id,
    slateId: slateId,
    kind: kind,
    status: status,
    source: source,
    createdAtUnix: createdAtUnix,
    timeUnix: timeUnix,
    confirmed: confirmed,
    blockHeight: blockHeight,
    blockTimeUnix: blockTimeUnix,
    amountCredited: amountCredited,
    amountDebited: amountDebited,
    fee: fee,
    numInputs: numInputs,
    numOutputs: numOutputs,
    kernelExcess: kernelExcess,
    outputCommits: List.unmodifiable(outputCommits),
    counterparty: counterparty,
    transport: transport,
    note: note,
    label: label,
    manualFields: Set.unmodifiable(manualFields),
    manualEditedAtUnix: manualEditedAtUnix,
    messages: messages,
    ttlCutoffHeight: ttlCutoffHeight,
    cancellable: cancellable,
    repostable: repostable,
    undelivered: undelivered,
    posting: posting,
    statusDetail: statusDetail,
    releasable: releasable,
    finalizedAtUnix: finalizedAtUnix,
    cancelReason: cancelReason,
    flow: flow,
    senderReportedPostedAtUnix: senderReportedPostedAtUnix,
    senderReportedCancelledAtUnix: senderReportedCancelledAtUnix,
    receiverDeclinedAtUnix: receiverDeclinedAtUnix,
    pairingId: pairingId,
    origin: origin,
    spentCommits: spentCommits,
    unverified: unverified,
    epic1Via: epic1Via,
    sentPlain: sentPlain,
  );
}

/// A LEPIC row with what the old core recorded about the same slate, if anything.
MergedTx _fromLive(TxEntry e, Meta meta) {
  final m = MergedTx._from(e);
  if (e.slateId != null) m.epic1Via ??= Epic1Via.fromStored(meta.epic1Payments[e.slateId]);
  if (e.slateId != null && meta.plainResends.contains(e.slateId)) m.sentPlain = true;
  final ann = e.slateId == null ? null : meta.annotations[e.slateId];
  if (ann != null) {
    m.counterparty = _someStr(m.counterparty) ?? _someStr(ann.counterparty);
    if (ann.finalized) {
      m.kernelExcess ??= ann.kernelExcess;
      m.finalizedAtUnix ??= ann.finalizedAtUnix;
    }
    if (m.status == TxStatus.cancelled) {
      m.cancelReason = cancelReasonFrom(ann.cancelledBy) ?? m.cancelReason;
    }
  }
  return m;
}

MergedTx _fromRecord(Record r) {
  final status = statusFrom(r.status, confirmed: r.confirmed);
  final m = MergedTx._from(
    TxEntry(
      key: '',
      slateId: _someStr(r.slateId),
      kind: kindFrom(r.kind),
      status: status,
      source: TxSource.imported,
      createdAtUnix: r.createdAtUnix,
      timeUnix: 0,
      confirmed: r.confirmed,
      blockHeight: r.blockHeight,
      blockTimeUnix: r.blockTimeUnix,
      amountCredited: r.amountCredited,
      amountDebited: r.amountDebited,
      fee: r.fee,
      numInputs: r.numInputs,
      numOutputs: r.numOutputs,
      kernelExcess: _someStr(r.kernelExcess),
      outputCommits: r.outputCommits,
      counterparty: _someStr(r.counterparty),
      ttlCutoffHeight: r.ttlCutoffHeight,
      cancellable: false,
      repostable: false,
      statusDetail: _someStr(r.statusDetail),
      releasable: false,
      cancelReason: status == TxStatus.cancelled
          ? cancelReasonFrom(r.cancelReason)
          : null,
      flow: flowFrom(r.flow),
      pairingId: _someStr(r.pairingId),
      messages: slateMessagesOf(r),
      transport: _someStr(r.transport),
    ),
  );
  m.kernelLookupMinHeight = r.kernelLookupMinHeight;
  m.recordMessages = r.messages;
  m.paymentProof = r.paymentProof;
  return m;
}

/// Fills [m] (a live row) from the record [r] it matched.
void _absorb(MergedTx m, Record r) {
  if (m.source == TxSource.restored) {
    // The scan saw one output; the record knows the whole transaction.
    m.source = TxSource.imported;
    m.kind = kindFrom(r.kind);
    m.amountCredited = r.amountCredited;
    m.amountDebited = r.amountDebited;
    m.numInputs = r.numInputs;
    m.numOutputs = r.numOutputs;
    m.createdAtUnix = r.createdAtUnix;
    m.fee = r.fee ?? m.fee;
    m.flow = flowFrom(r.flow);
  } else {
    m.fee ??= r.fee;
  }
  m.slateId ??= _someStr(r.slateId);
  m.kernelExcess ??= _someStr(r.kernelExcess);
  m.counterparty ??= _someStr(r.counterparty);
  m.blockHeight ??= r.blockHeight;
  m.blockTimeUnix ??= r.blockTimeUnix;
  for (final c in r.outputCommits) {
    if (!m.outputCommits.contains(c)) m.outputCommits.add(c);
  }
  m.kernelLookupMinHeight ??= r.kernelLookupMinHeight;
  m.recordMessages ??= r.messages;
  m.paymentProof ??= r.paymentProof;
  m.pairingId ??= _someStr(r.pairingId);
  m.transport ??= _someStr(r.transport);
  if (m.messages.isEmpty) m.messages = slateMessagesOf(r);
}

/// Live rows by slate id, kernel and created commitment, so matching a record is a lookup
/// instead of a walk over every row. Kept current as rows absorb records.
class _RowIndex {
  final Map<String, List<int>> slate = {};
  final Map<String, List<int>> kernel = {};
  final Map<String, List<int>> commit = {};

  static void _putIn(Map<String, List<int>> map, String k, int i) {
    final v = map.putIfAbsent(k, () => []);
    if (!v.contains(i)) v.add(i);
  }

  void add(int i, MergedTx m) {
    if (m.slateId case final s?) _putIn(slate, s, i);
    if (m.kernelExcess case final k?) _putIn(kernel, k, i);
    for (final c in m.outputCommits) {
      _putIn(commit, c, i);
    }
  }

  /// Rows matching [r]: by slate id, then kernel, then created commitment, each group in row
  /// order.
  List<int> matches(Record r, List<bool> hidden) {
    final out = <int>[];
    void group(Iterable<int> hits) {
      for (final i in [...hits]..sort()) {
        if (!hidden[i] && !out.contains(i)) out.add(i);
      }
    }

    group(r.slateId == null ? const [] : slate[r.slateId] ?? const []);
    group(
      r.kernelExcess == null ? const [] : kernel[r.kernelExcess] ?? const [],
    );
    group([for (final c in r.outputCommits) ...?commit[c]]);
    return out;
  }
}

/// [s] as Rust's `{:?}` writes a string, so the hash below matches the old core's.
String _rustDebug(String s) {
  final out = StringBuffer('"');
  for (final rune in s.runes) {
    switch (rune) {
      case 0x09:
        out.write(r'\t');
      case 0x0a:
        out.write(r'\n');
      case 0x0d:
        out.write(r'\r');
      case 0x22:
        out.write(r'\"');
      case 0x5c:
        out.write(r'\\');
      case 0x00:
        out.write(r'\0');
      case < 0x20 || 0x7f:
        out.write('\\u{${rune.toRadixString(16)}}');
      default:
        out.writeCharCode(rune);
    }
  }
  out.write('"');
  return out.toString();
}

String _debugOpt(String? s) => s == null ? 'None' : 'Some(${_rustDebug(s)})';

/// Short stable hash of what identifies an imported row, as the old core computes it.
String identityHash(MergedTx m) {
  final text =
      '${_debugOpt(m.slateId)}|${_debugOpt(m.kernelExcess)}|'
      '[${m.outputCommits.map(_rustDebug).join(', ')}]|'
      '${m.createdAtUnix}|${m.amountCredited}|${m.amountDebited}';
  final digest = sha256.convert(utf8.encode(text)).bytes;
  return [for (final b in digest.take(4)) b.toRadixString(16).padLeft(2, '0')]
      .join();
}

String _baseKey(MergedTx m) {
  if (m.slateId case final s?) return 's:$s';
  if (m.kernelExcess case final k?) return 'k:$k';
  if (m.outputCommits.isNotEmpty) return 'c:${m.outputCommits.first}';
  if (m.id case final i?) return 'l:$i';
  return 'x:unknown';
}

List<String> _aliasesOf(MergedTx m) {
  final seen = <String>{};
  return [
    m.key,
    if (m.slateId != null) 's:${m.slateId}',
    if (m.kernelExcess != null) 'k:${m.kernelExcess}',
    for (final c in m.outputCommits) 'c:$c',
    if (m.id != null) 'l:${m.id}',
  ].where(seen.add).toList();
}

/// Aliases that more than one row carries.
Set<String> sharedAliases(List<MergedTx> rows) {
  final seen = <String>{};
  final shared = <String>{};
  for (final a in rows.expand((m) => m.aliases)) {
    if (!seen.add(a)) shared.add(a);
  }
  return shared;
}

/// Merges [live] rows and the archive into the list the UI shows, newest first.
List<MergedTx> mergeHistory(List<TxEntry> live, Meta meta) {
  final rows = [for (final e in live) _fromLive(e, meta)];
  final hidden = List.filled(rows.length, false);
  final recordNotes = <int, String>{};
  final imported = <(MergedTx, String?)>[];
  final index = _RowIndex();
  for (var i = 0; i < rows.length; i++) {
    index.add(i, rows[i]);
  }

  for (final r in meta.records) {
    final found = index.matches(r, hidden);
    if (found.isEmpty) {
      imported.add((_fromRecord(r), _someStr(r.note)));
      continue;
    }
    // Prefer a row of the record's own kind (both sides of a self-send share a slate id),
    // and among those a row the wallet made itself over one a scan rebuilt.
    final kind = kindFrom(r.kind);
    bool sameKind(int i) =>
        rows[i].kind == kind ||
        (rows[i].source == TxSource.restored && _isIncoming(kind));
    bool made(int i) => rows[i].source != TxSource.restored;
    int? first(bool Function(int) test) {
      for (final i in found) {
        if (test(i)) return i;
      }
      return null;
    }

    final primary =
        first((i) => sameKind(i) && made(i)) ??
        first(sameKind) ??
        first(made) ??
        found.first;
    _absorb(rows[primary], r);
    final note = _someStr(r.note);
    if (note != null) recordNotes.putIfAbsent(primary, () => note);
    // Other outputs of the same transaction that a scan rebuilt as separate "Received" rows.
    for (final i in found) {
      if (i != primary && rows[i].source == TxSource.restored) {
        for (final c in rows[i].outputCommits) {
          if (!rows[primary].outputCommits.contains(c)) {
            rows[primary].outputCommits.add(c);
          }
        }
        hidden[i] = true;
      }
    }
    // The primary row may now carry the record's slate id, kernel and commitments.
    index.add(primary, rows[primary]);
  }

  final out = <(MergedTx, String?)>[
    for (var i = 0; i < rows.length; i++)
      if (!hidden[i]) (rows[i], recordNotes[i]),
    ...imported,
  ];

  final used = <String>{};
  final result = <MergedTx>[];
  final recordNoteOf = <String?>[];
  for (final (m, recordNote) in out) {
    var key = _baseKey(m);
    if (!used.add(key)) {
      // Both sides of a self-send share a slate id. The suffix depends only on the row
      // itself, so a note saved under it stays with that row when others are added.
      key = m.id != null ? '$key#l${m.id}' : '$key#${identityHash(m)}';
      used.add(key);
    }
    m.key = key;
    if (m.blockTimeUnix == null && m.blockHeight != null) {
      m.blockTimeUnix = meta.blockTime(m.blockHeight!);
    }
    // LEPIC's own rows keep the time LEPIC gave them; a row the archive describes is shown at
    // its creation, a row a scan rebuilt at its block.
    m.timeUnix = switch (m.source) {
      TxSource.restored => m.blockTimeUnix ?? m.timeUnix,
      TxSource.imported => m.createdAtUnix,
      TxSource.wallet => m.timeUnix,
    };
    m.aliases = _aliasesOf(m);
    recordNoteOf.add(recordNote);
    result.add(m);
  }
  final shared = sharedAliases(result);
  for (var i = 0; i < result.length; i++) {
    final m = result[i];
    String? byAlias() {
      for (final a in m.aliases) {
        if (shared.contains(a)) continue;
        final n = meta.notes[a];
        if (n != null) return n;
      }
      return null;
    }

    m.note = meta.notes[m.key] ?? byAlias() ?? recordNoteOf[i];
    _applyManual(m, manualOf(meta, m, shared));
  }
  result.sort((a, b) {
    final byTime = b.timeUnix.compareTo(a.timeUnix);
    if (byTime != 0) return byTime;
    // Rust's `Option` order: None before every id, so newest-first puts it last.
    return (b.id ?? -1).compareTo(a.id ?? -1);
  });
  return result;
}

/// The manual record of [m]: under its key, else under an alias no other row carries.
ManualRec? manualOf(Meta meta, MergedTx m, Set<String> shared) {
  final own = meta.manual[m.key];
  if (own != null) return own;
  for (final a in m.aliases) {
    if (shared.contains(a)) continue;
    final r = meta.manual[a];
    if (r != null) return r;
  }
  return null;
}

/// SHA-256 (hex) of a value the user chose to keep their own over, as [ManualRec.declined]
/// stores it.
String declinedHash(String value) =>
    sha256.convert(utf8.encode(value)).toString();

/// Whether the typed [field] shows on a row whose own (recorded) value is [recorded]: when the
/// row has none, or when the user chose their own over exactly this recorded value ("Details
/// differ", Mine).
bool _manualWins(ManualRec? rec, ManualField field, String? recorded) {
  final own = _someStr(recorded);
  return own == null || rec?.declined[field.name] == declinedHash(own);
}

/// Puts what the user entered on [m]. A label fits any row. Who paid and how fill only what
/// the row does not know, so a recorded value shows over a typed one until the user chose
/// theirs for it. A note on a row a scan restored is the user's too.
void _applyManual(MergedTx m, ManualRec? rec) {
  final fields = <ManualField>{};
  final label = _someStr(rec?.label);
  if (label != null) {
    m.label = label;
    fields.add(ManualField.label);
  }
  final counterparty = _someStr(rec?.counterparty);
  if (counterparty != null &&
      _manualWins(rec, ManualField.counterparty, m.counterparty)) {
    m.counterparty = counterparty;
    fields.add(ManualField.counterparty);
  }
  final transport = _someStr(rec?.transport);
  if (transport != null &&
      _manualWins(rec, ManualField.transport, m.transport)) {
    m.transport = transport;
    fields.add(ManualField.transport);
  }
  if (m.source == TxSource.restored && _someStr(m.note) != null) {
    fields.add(ManualField.note);
  }
  m.manualFields = fields;
  m.manualEditedAtUnix = fields.isEmpty ? null : rec?.editedAtUnix;
}

/// The names a history file's `user_fields` and the CSV give [ManualField]s.
String userFieldName(ManualField f) => switch (f) {
  ManualField.label => 'label',
  ManualField.counterparty => 'counterparty',
  ManualField.transport => 'method',
  ManualField.note => 'note',
};

/// [userFieldName] the other way; null for a name this version does not know.
ManualField? userFieldFrom(String name) => switch (name) {
  'label' => ManualField.label,
  'counterparty' => ManualField.counterparty,
  'method' => ManualField.transport,
  'note' => ManualField.note,
  _ => null,
};

/// True when the record describes the transaction shown as [tx].
bool recordMatches(Record r, MergedTx tx) {
  bool eq(String? a, String? b) => a != null && b != null && a == b;
  return eq(tx.slateId, r.slateId) ||
      eq(tx.kernelExcess, r.kernelExcess) ||
      tx.outputCommits.any(r.outputCommits.contains);
}

/// The archive record an export writes for [m].
Record toRecord(MergedTx m) => Record(
  slateId: m.slateId,
  kernelExcess: m.kernelExcess,
  kernelLookupMinHeight: m.kernelLookupMinHeight,
  kind: kindName(m.kind),
  status: statusName(m.status),
  confirmed: m.confirmed,
  createdAtUnix: m.createdAtUnix,
  blockHeight: m.blockHeight,
  blockTimeUnix: m.blockTimeUnix,
  amountCredited: m.amountCredited,
  amountDebited: m.amountDebited,
  fee: m.fee,
  numInputs: m.numInputs,
  numOutputs: m.numOutputs,
  outputCommits: [...m.outputCommits],
  counterparty: m.counterparty,
  note: m.note,
  ttlCutoffHeight: m.ttlCutoffHeight,
  messages: m.recordMessages,
  paymentProof: m.paymentProof,
  statusDetail: m.statusDetail,
  cancelReason: m.cancelReason == null
      ? null
      : cancelReasonName(m.cancelReason!),
  label: m.label,
  transport: m.transport,
  userFields: [
    for (final f in ManualField.values)
      if (m.manualFields.contains(f)) userFieldName(f),
  ],
  userEditedAtUnix: m.manualEditedAtUnix,
  // The file's own `exported_at_unix` stands for every record in it.
  flow: m.flow == TxFlow.invoice ? 'invoice' : null,
  pairingId: m.pairingId,
  slateMessages: [
    for (final x in m.messages) SlateMessageRec(role: x.role.name, text: x.text),
  ],
);
