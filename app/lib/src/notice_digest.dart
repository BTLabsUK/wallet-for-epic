// SPDX-License-Identifier: Apache-2.0
/// One result per collect or drain, on phone and desktop. While a run lasts the notices of
/// routine news are held here; when it ends they fold by slate id into nothing, one notice or
/// one digest line. Outside a run a notice shows at once, as ever. No Flutter here: the screens
/// hand in what to show, and [NoticeBatch.digests] tells them to word a digest.
library;

import 'dart:async';

/// What a held notice says happened, as a digest counts it. [stage] is how far along its slate
/// that puts it: a slate moves one way, so the higher stage is the slate's state, with no
/// timestamp to compare.
enum HeldKind {
  invoice(0),
  withdrawal(0),
  paid(1),
  expired(2),
  withdrawn(2),
  declined(2),
  cancelled(2);

  const HeldKind(this.stage);

  final int stage;
}

/// One notice waiting for its run to end.
class HeldNotice {
  const HeldNotice(this.kind, {this.slateId, this.named = false, this.show});

  final HeldKind kind;

  /// The slate it is about; null folds with nothing.
  final String? slateId;

  /// It names who it came from: of two notices for one slate, the one to keep.
  final bool named;

  /// Raises today's notice; null for news that ends a slate without one (a declined invoice,
  /// a cancelled payment that home words itself). A digest counts only what would have shown.
  final void Function()? show;

  /// Whether this one is what its slate shows, over [other]. The later wins a full tie.
  bool beats(HeldNotice other) {
    if (kind.stage != other.kind.stage) return kind.stage > other.kind.stage;
    if ((show != null) != (other.show != null)) return show != null;
    return named || !other.named;
  }
}

/// [held] with one notice per slate: the slate's furthest state, so an invoice withdrawn in the
/// same batch leaves no prompt, and two notices for one invoice leave the named one. What ends
/// a slate without a notice goes too.
List<HeldNotice> foldNotices(List<HeldNotice> held) {
  final slates = <String, HeldNotice>{};
  final others = <HeldNotice>[];
  for (final notice in held) {
    final id = notice.slateId;
    if (id == null) {
      others.add(notice);
      continue;
    }
    final best = slates[id];
    if (best == null || notice.beats(best)) slates[id] = notice;
  }
  return [...slates.values, ...others].where((n) => n.show != null).toList();
}

/// Where a digest opens: the place that lists what it counts.
enum DigestPlace { invoices, sentInvoices, activity }

/// Two or more notices as one line.
class NoticeDigest {
  NoticeDigest(this.counts);

  /// Notices per kind, in [HeldKind] order.
  factory NoticeDigest.of(List<HeldNotice> folded) => NoticeDigest({
    for (final kind in HeldKind.values)
      if (folded.any((n) => n.kind == kind)) kind: folded.where((n) => n.kind == kind).length,
  });

  final Map<HeldKind, int> counts;

  int get total => counts.values.fold(0, (a, b) => a + b);

  DigestPlace get place => counts.keys.every((k) => k == HeldKind.withdrawal)
      ? DigestPlace.activity
      : counts.keys.every((k) => k == HeldKind.paid)
      ? DigestPlace.sentInvoices
      : DigestPlace.invoices;
}

/// The notices of one wallet session's runs. Overlapping runs (a drain inside a collect) and a
/// run that starts within [grace] of the last one's end are one batch, so a coalesced rerun joins
/// the run it follows. A run that fails still gives its result; [dispose] (lock, logout,
/// wallet close) drops what it holds.
class NoticeBatch {
  NoticeBatch({required this.grace, this.settle});

  /// How long after the last run the batch stays open: events reach Dart on their own, and can
  /// land after the run's future ended.
  final Duration grace;

  /// Waits for the events already in hand, after [grace].
  final Future<void> Function()? settle;

  final StreamController<NoticeDigest> _digests = StreamController<NoticeDigest>.broadcast();
  final List<HeldNotice> _held = [];
  Timer? _timer;
  int _runs = 0;
  int _settling = 0;
  bool _closed = false;

  /// The digests of this session; a single result shows by its own [HeldNotice.show].
  Stream<NoticeDigest> get digests => _digests.stream;

  bool get _open => _runs > 0 || _timer != null || _settling > 0;

  /// Keeps the batch open around [body].
  Future<T> during<T>(Future<T> Function() body) async {
    begin();
    try {
      return await body();
    } finally {
      end();
    }
  }

  void begin() {
    _runs++;
    _timer?.cancel();
    _timer = null;
  }

  void end() {
    if (_runs > 0) _runs--;
    if (_runs == 0 && !_closed) _timer = Timer(grace, () => unawaited(_flush()));
  }

  /// Holds [notice]; false when no run is open. Nothing is shown once the session closed.
  bool _hold(HeldNotice notice) {
    if (_closed) return true;
    if (!_open) return false;
    _held.add(notice);
    return true;
  }

  Future<void> _flush() async {
    _timer = null;
    _settling++;
    try {
      await settle?.call();
    } on Object {
      // The tail never fails; a result is owed either way.
    }
    // What the tail added reaches its listeners on the next turn.
    await Future<void>.delayed(Duration.zero);
    _settling--;
    if (_closed || _open) return;
    final folded = foldNotices(_held);
    _held.clear();
    if (folded.length == 1) {
      folded.single.show!();
    } else if (folded.isNotEmpty) {
      _digests.add(NoticeDigest.of(folded));
    }
  }

  void dispose() {
    _closed = true;
    _timer?.cancel();
    _timer = null;
    _held.clear();
    _digests.close();
  }
}

/// Raises [notice] through [batch]: held while a run is open, shown at once otherwise and with no
/// session to hold it.
void raiseNotice(NoticeBatch? batch, HeldNotice notice) {
  if (batch == null || !batch._hold(notice)) notice.show?.call();
}
