// SPDX-License-Identifier: Apache-2.0
/// What the wallet's checks of its messages did, for the status places on phone and desktop.
/// Two kinds of check fill it: the drain of the payments address and the collect of the paired
/// contacts' mailboxes. The session owns one [MessageChecks]; the screens read it.
library;

import 'dart:async';

import 'notice_digest.dart';

/// The counts of one check, from the drain's report and the collect's. Every field is a plain
/// count.
class CheckOutcome {
  const CheckOutcome({
    this.received = 0,
    this.finalized = 0,
    this.bounced = 0,
    this.held = 0,
    this.rejected = 0,
    this.dropped = 0,
    this.messages = 0,
    this.failed = 0,
    this.unreadable = 0,
    this.buffered = 0,
    this.capped = 0,
  });

  /// Payments to this wallet signed and answered.
  final int received;

  /// Answers finalized and posted.
  final int finalized;

  /// Invoices this wallet issued that came back unpaid.
  final int bounced;

  /// Messages left on the relay for a later check.
  final int held;

  /// Messages refused for good.
  final int rejected;

  /// Messages acknowledged and forgotten (an unknown kind, oversize or malformed).
  final int dropped;

  /// Messages read from the contacts' mailboxes.
  final int messages;

  /// Pairings that ended without pairing in the collect.
  final int failed;

  /// Messages the wallet keeps because it could not take them: all it holds now, not this
  /// check's alone.
  final int unreadable;

  /// Notices kept until their slate arrives.
  final int buffered;

  /// Mailboxes that still had messages when the check ended.
  final int capped;

  /// What a check turned away: refused for good, or dropped.
  int get refused => rejected + dropped;

  /// Whether the status has a line to say about this check: only a count that needs the user's
  /// notice.
  bool get hasNews => held > 0 || refused > 0 || unreadable > 0;

  CheckOutcome operator +(CheckOutcome o) => CheckOutcome(
    received: received + o.received,
    finalized: finalized + o.finalized,
    bounced: bounced + o.bounced,
    held: held + o.held,
    rejected: rejected + o.rejected,
    dropped: dropped + o.dropped,
    messages: messages + o.messages,
    failed: failed + o.failed,
    unreadable: unreadable + o.unreadable,
    buffered: buffered + o.buffered,
    capped: capped + o.capped,
  );

  @override
  int get hashCode => Object.hash(received, finalized, bounced, held, rejected, dropped, messages, failed, unreadable, buffered, capped);

  @override
  bool operator ==(Object other) =>
      other is CheckOutcome &&
      received == other.received &&
      finalized == other.finalized &&
      bounced == other.bounced &&
      held == other.held &&
      rejected == other.rejected &&
      dropped == other.dropped &&
      messages == other.messages &&
      failed == other.failed &&
      unreadable == other.unreadable &&
      buffered == other.buffered &&
      capped == other.capped;
}

/// Which check a run was.
enum CheckSource { drain, collect }

/// A check of [source] that keeps failing, as the status shows it: since when no check of it
/// ended well, and the last error.
class CheckFailure {
  const CheckFailure({required this.source, required this.since, required this.error});

  final CheckSource source;

  /// The first failure after the last check that ended well.
  final DateTime since;

  /// What the last run threw.
  final Object error;

  @override
  int get hashCode => Object.hash(source, since, error);

  @override
  bool operator ==(Object other) => other is CheckFailure && source == other.source && since == other.since && error == other.error;
}

/// The state the status shows: a check running for longer than the show delay, when the last
/// one ended well, the failures worth the user's notice, and what the checks found.
class MessageCheck {
  const MessageCheck({this.checking = false, this.checkedAt, this.failures = const [], this.outcome = const CheckOutcome()});

  final bool checking;

  /// When a check last ended well; null before the first.
  final DateTime? checkedAt;

  /// The checks that failed where the user asked for them, or that kept failing for
  /// [MessageChecks.failingShowAfter]; in [CheckSource] order. A background check that failed
  /// once is only logged: the next one runs by itself.
  final List<CheckFailure> failures;

  /// The last drain's counts and the last collect's, added.
  final CheckOutcome outcome;

  /// Some check failed in a way the user should hear about.
  bool get failed => failures.isNotEmpty;

  @override
  int get hashCode => Object.hash(checking, checkedAt, Object.hashAll(failures), outcome);

  @override
  bool operator ==(Object other) =>
      other is MessageCheck &&
      checking == other.checking &&
      checkedAt == other.checkedAt &&
      _sameList(failures, other.failures) &&
      outcome == other.outcome;
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A source's failures since its last good check.
class _Failing {
  _Failing(this.since, this.error, this.asked);

  final DateTime since;
  Object error;

  /// A run the user asked for (a Retry) failed: it shows at once.
  bool asked;
}

/// Keeps the [MessageCheck] of one wallet session and tells its listeners when it changes.
class MessageChecks {
  MessageChecks({
    required this.showAfter,
    required Duration digestGrace,
    this.failingShowAfter = const Duration(minutes: 10),
    Future<void> Function()? settle,
    DateTime Function()? clock,
  }) : notices = NoticeBatch(grace: digestGrace, settle: settle),
       _now = clock ?? DateTime.now;

  /// A check shows as running only after it has run this long.
  final Duration showAfter;

  /// A check that failed in the background shows as failed once no check of its source has
  /// ended well for this long: by then payments or messages may be waiting.
  final Duration failingShowAfter;

  /// Runs every check again as one the user asked for: set by the session, called by Retry.
  Future<void> Function()? retrier;

  /// The notices held while a check runs, quiet ones too: one result per run.
  final NoticeBatch notices;
  final DateTime Function() _now;
  final StreamController<MessageCheck> _changes = StreamController<MessageCheck>.broadcast();
  final Map<CheckSource, CheckOutcome> _outcomes = {};
  final Map<CheckSource, _Failing> _failing = {};
  Timer? _timer;
  Timer? _failingTimer;
  int _asking = 0;
  int _active = 0;
  bool _showing = false;
  DateTime? _checkedAt;
  MessageCheck _value = const MessageCheck();

  MessageCheck get value => _value;
  Stream<MessageCheck> get stream => _changes.stream;

  /// Runs [body] as one check of [source]. [outcomeOf] reads its result. A failure is thrown
  /// again; it shows at once only when the user asked for the run ([asked], or inside
  /// [retry]), else only after [failingShowAfter] without a good check of [source]. A [quiet]
  /// run (a timer's tick) never shows "checking".
  Future<T> run<T>(
    CheckSource source,
    Future<T> Function() body, {
    required CheckOutcome Function(T result) outcomeOf,
    bool quiet = false,
    bool asked = false,
  }) async {
    final byUser = asked || _asking > 0;
    notices.begin();
    if (!quiet) _begin();
    try {
      final result = await body();
      _outcomes[source] = outcomeOf(result);
      _failing.remove(source);
      _checkedAt = _now();
      return result;
    } on Object catch (error) {
      final f = _failing[source];
      if (f == null) {
        _failing[source] = _Failing(_now(), error, byUser);
      } else {
        f.error = error;
        f.asked = f.asked || byUser;
      }
      rethrow;
    } finally {
      if (!quiet) _end();
      notices.end();
      _publish();
    }
  }

  /// Runs every check again through [retrier], each as one the user asked for: a failure
  /// shows at once. Throws nothing: the failures are in [value].
  Future<void> retry() async {
    final again = retrier;
    if (again == null) return;
    _asking++;
    try {
      await again();
    } on Object {
      // Kept in the failures.
    } finally {
      _asking--;
    }
  }

  /// Drops what the last check of [source] found and whether it failed: the check no longer
  /// runs (its method was turned off).
  void forget(CheckSource source) {
    final had = _outcomes.remove(source) != null;
    if (_failing.remove(source) != null || had) _publish();
  }

  /// Sets how many messages the wallet keeps unread, after the user tried them again or
  /// removed one, without a new check.
  void setUnreadable(int count) {
    final o = _outcomes[CheckSource.collect] ?? const CheckOutcome();
    if (o.unreadable == count) return;
    _outcomes[CheckSource.collect] = CheckOutcome(
      received: o.received,
      finalized: o.finalized,
      bounced: o.bounced,
      held: o.held,
      rejected: o.rejected,
      dropped: o.dropped,
      messages: o.messages,
      failed: o.failed,
      unreadable: count,
      buffered: o.buffered,
      capped: o.capped,
    );
    _publish();
  }

  void _begin() {
    _active++;
    if (_active == 1) {
      _timer = Timer(showAfter, () {
        _showing = true;
        _publish();
      });
    }
  }

  void _end() {
    if (_active > 0) _active--;
    if (_active == 0) {
      _timer?.cancel();
      _timer = null;
      _showing = false;
    }
  }

  void _publish() {
    final now = _now();
    _failingTimer?.cancel();
    _failingTimer = null;
    DateTime? nextShow;
    final shown = <CheckFailure>[];
    for (final source in CheckSource.values) {
      final f = _failing[source];
      if (f == null) continue;
      final showAt = f.since.add(failingShowAfter);
      if (f.asked || !now.isBefore(showAt)) {
        shown.add(CheckFailure(source: source, since: f.since, error: f.error));
      } else if (nextShow == null || showAt.isBefore(nextShow)) {
        nextShow = showAt;
      }
    }
    // A failure not shown yet shows when its time is up, with no other check needed.
    if (nextShow != null && !_changes.isClosed) _failingTimer = Timer(nextShow.difference(now), _publish);
    final next = MessageCheck(
      checking: _showing,
      checkedAt: _checkedAt,
      failures: shown,
      outcome: _outcomes.values.fold(const CheckOutcome(), (a, b) => a + b),
    );
    if (next == _value) return;
    _value = next;
    if (!_changes.isClosed) _changes.add(next);
  }

  void dispose() {
    _timer?.cancel();
    _failingTimer?.cancel();
    notices.dispose();
    _changes.close();
  }
}
