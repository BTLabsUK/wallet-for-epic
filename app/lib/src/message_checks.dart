// SPDX-License-Identifier: Apache-2.0
/// What the wallet's checks of its messages did, for the status places on phone and desktop.
/// Two kinds of check fill it: the drain of the payments address and the collect of the paired
/// contacts' mailboxes. The session owns one [MessageChecks]; the screens read it.
library;

import 'dart:async';

/// The counts of one check, from the drain's report and the collect's. Every field is a plain
/// count; [buffered], [quarantined] and [capped] are room for what the core will report later.
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
    this.quarantined = 0,
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

  /// Messages that could not be opened (a count the core does not report yet).
  final int unreadable;

  /// Not reported yet.
  final int buffered;

  /// Not reported yet.
  final int quarantined;

  /// Not reported yet.
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
    quarantined: quarantined + o.quarantined,
    capped: capped + o.capped,
  );

  @override
  int get hashCode => Object.hash(received, finalized, bounced, held, rejected, dropped, messages, failed, unreadable, buffered, quarantined, capped);

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
      quarantined == other.quarantined &&
      capped == other.capped;
}

/// Which check a run was.
enum CheckSource { drain, collect }

/// The state the status shows: a check running for longer than the show delay, when the last
/// one ended well, whether the last one failed, and what the checks found.
class MessageCheck {
  const MessageCheck({this.checking = false, this.checkedAt, this.failed = false, this.outcome = const CheckOutcome()});

  final bool checking;

  /// When a check last ended well; null before the first.
  final DateTime? checkedAt;

  /// The last check of some kind failed.
  final bool failed;

  /// The last drain's counts and the last collect's, added.
  final CheckOutcome outcome;

  @override
  int get hashCode => Object.hash(checking, checkedAt, failed, outcome);

  @override
  bool operator ==(Object other) =>
      other is MessageCheck && checking == other.checking && checkedAt == other.checkedAt && failed == other.failed && outcome == other.outcome;
}

/// Keeps the [MessageCheck] of one wallet session and tells its listeners when it changes.
class MessageChecks {
  MessageChecks({required this.showAfter, DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  /// A check shows as running only after it has run this long.
  final Duration showAfter;
  final DateTime Function() _now;
  final StreamController<MessageCheck> _changes = StreamController<MessageCheck>.broadcast();
  final Map<CheckSource, CheckOutcome> _outcomes = {};
  final Set<CheckSource> _failed = {};
  Timer? _timer;
  int _active = 0;
  bool _showing = false;
  DateTime? _checkedAt;
  MessageCheck _value = const MessageCheck();

  MessageCheck get value => _value;
  Stream<MessageCheck> get stream => _changes.stream;

  /// Runs [body] as one check of [source]. [outcomeOf] reads its result. A failure marks the
  /// check failed and is thrown again. A [quiet] run (a timer's tick) never shows "checking".
  Future<T> run<T>(CheckSource source, Future<T> Function() body, {required CheckOutcome Function(T result) outcomeOf, bool quiet = false}) async {
    if (!quiet) _begin();
    try {
      final result = await body();
      _outcomes[source] = outcomeOf(result);
      _failed.remove(source);
      _checkedAt = _now();
      return result;
    } on Object {
      _failed.add(source);
      rethrow;
    } finally {
      if (!quiet) _end();
      _publish();
    }
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
    final next = MessageCheck(
      checking: _showing,
      checkedAt: _checkedAt,
      failed: _failed.isNotEmpty,
      outcome: _outcomes.values.fold(const CheckOutcome(), (a, b) => a + b),
    );
    if (next == _value) return;
    _value = next;
    if (!_changes.isClosed) _changes.add(next);
  }

  void dispose() {
    _timer?.cancel();
    _changes.close();
  }
}
