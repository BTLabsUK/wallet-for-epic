/// The transaction list: LEPIC's rows merged with the app's archive (`meta_store.dart`).
///
/// A port of `app/rust/src/core/history.rs`, where the live rows were epic-wallet's log. Here
/// they arrive as [TxEntry] from `lepicTxEntry`, so status, cancel and repost flags are
/// LEPIC's, and LEPIC rows carry no output commitments. Everything is pure, so the rules are
/// tested on synthetic rows.
///
/// - A live row absorbs an archive record matching by slate id, then kernel, then a created
///   commitment. Live status and amounts win, except on rows a scan rebuilt ([TxSource.restored]),
///   which only know one output: those take the record's kind, amounts and time.
/// - Keys are stable across restores: `s:<slate>`, else `k:<kernel>`, else `c:<commit>`, else
///   `l:<id>`. The two sides of a self-send share a slate id and get a suffix.
/// - A note belongs to a row by its key, or by an alias no other row carries.
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
      note = e.note,
      messages = e.messages,
      ttlCutoffHeight = e.ttlCutoffHeight,
      cancellable = e.cancellable,
      repostable = e.repostable,
      statusDetail = e.statusDetail,
      releasable = e.releasable,
      finalizedAtUnix = e.finalizedAtUnix,
      cancelReason = e.cancelReason;

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
  String? note;

  /// The live row's slate messages, shown in details. Not exported: a backup's `messages` is
  /// [recordMessages].
  List<SlateMessage> messages;
  BigInt? ttlCutoffHeight;
  bool cancellable;
  bool repostable;
  String? statusDetail;
  bool releasable;
  int? finalizedAtUnix;
  CancelReason? cancelReason;

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
    note: note,
    messages: messages,
    ttlCutoffHeight: ttlCutoffHeight,
    cancellable: cancellable,
    repostable: repostable,
    statusDetail: statusDetail,
    releasable: releasable,
    finalizedAtUnix: finalizedAtUnix,
    cancelReason: cancelReason,
  );
}

/// A LEPIC row with what the old core recorded about the same slate, if anything.
MergedTx _fromLive(TxEntry e, Meta meta) {
  final m = MergedTx._from(e);
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
  }
  result.sort((a, b) {
    final byTime = b.timeUnix.compareTo(a.timeUnix);
    if (byTime != 0) return byTime;
    // Rust's `Option` order: None before every id, so newest-first puts it last.
    return (b.id ?? -1).compareTo(a.id ?? -1);
  });
  return result;
}

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
  // The file's own `exported_at_unix` stands for every record in it.
);
