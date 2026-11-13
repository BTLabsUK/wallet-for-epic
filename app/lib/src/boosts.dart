// SPDX-License-Identifier: Apache-2.0
/// Checking more often for a while (LEPIC ADR 0058). Each open wallet has one set of boosts per
/// [Poller]; a boost starts no loop. The app's loops are [PollDriver]s: each asks
/// [Boosts.interval] before it waits and sets its timer again when a boost starts or ends.
library;

import 'dart:async';
import 'dart:math' show min;

/// A loop a boost speeds up.
enum Poller {
  /// The contact collect: contact, pairing and epic1 link mailboxes on the relays.
  relays,

  /// The check of the node for a new block, and the refresh it starts.
  node,
}

/// The shortest interval a boost runs at; a shorter one is raised to it.
const Duration boostMinInterval = Duration(seconds: 5);

/// The longest window one boost runs; a longer one is cut to it.
const Duration boostMaxWindow = Duration(minutes: 10);

/// The boosts of one open wallet.
abstract interface class Boosts {
  /// Runs [poller] at most every [interval] for [duration] and returns the boost's id for
  /// [end]. Several boosts of one poller run at the shortest interval until the last ends.
  int boost(Poller poller, Duration duration, Duration interval);

  /// Ends the boost [id] before its window does: a screen that started one ends it on close.
  void end(int id);

  /// How long [poller] waits now: [base], or less while a boost of it runs.
  Duration interval(Poller poller, Duration base);

  /// Fires when a boost starts or is ended.
  Stream<void> get changed;
}

/// [Boosts] kept in Dart with LEPIC's rules, for the fakes. A boost ends on a timer, so a
/// test's fake time ends it too.
class MemoryBoosts implements Boosts {
  final _running = <int, ({Poller poller, Duration every, Timer ends})>{};
  final _changed = StreamController<void>.broadcast(sync: true);
  int _lastId = 0;

  @override
  int boost(Poller poller, Duration duration, Duration interval) {
    final id = ++_lastId;
    final window = duration > boostMaxWindow ? boostMaxWindow : duration;
    final every = interval < boostMinInterval ? boostMinInterval : interval;
    _running[id] = (poller: poller, every: every, ends: Timer(window, () => end(id)));
    _changed.add(null);
    return id;
  }

  @override
  void end(int id) {
    final ended = _running.remove(id);
    if (ended == null) return;
    ended.ends.cancel();
    _changed.add(null);
  }

  @override
  Duration interval(Poller poller, Duration base) => _running.values
      .where((b) => b.poller == poller)
      .fold(base, (shortest, b) => b.every < shortest ? b.every : shortest);

  @override
  Stream<void> get changed => _changed.stream;
}

/// Runs [tick] every [base], or at the interval of a running boost of [poller]: one timer, set
/// again after each tick and when a boost starts or ends. A tick that returns false failed:
/// the wait doubles for each failure in a row, never past [base].
class PollDriver {
  PollDriver(this.boosts, this.poller, {required this._base, required this.tick});

  final Boosts boosts;
  final Poller poller;
  final Future<bool> Function() tick;

  Duration _base;
  Timer? _timer;
  Duration _armed = Duration.zero;
  StreamSubscription<void>? _changes;
  bool _ticking = false;
  int _failures = 0;

  /// Ticks that failed in a row.
  int get failures => _failures;

  bool get running => _changes != null;

  /// The interval without a boost. Setting it counts the wait from now.
  Duration get base => _base;
  set base(Duration every) {
    _base = every;
    _arm();
  }

  /// The wait before the next tick now.
  Duration get wait {
    final boosted = boosts.interval(poller, _base) * (1 << min(_failures, 4));
    return boosted < _base ? boosted : _base;
  }

  /// Starts the loop; the first tick comes after one [wait].
  void start() {
    if (running) return;
    _changes = boosts.changed.listen((_) {
      // A shorter wait sets the timer again; a longer one starts with the next tick.
      if (wait < _armed) _arm();
    });
    _arm();
  }

  void stop() {
    _changes?.cancel();
    _changes = null;
    _timer?.cancel();
    _timer = null;
  }

  void _arm() {
    _timer?.cancel();
    _timer = null;
    if (!running || _ticking) return;
    _armed = wait;
    _timer = Timer(_armed, _fire);
  }

  Future<void> _fire() async {
    _timer = null;
    _ticking = true;
    var ok = false;
    try {
      ok = await tick();
    } on Object {
      // A tick that throws failed.
    }
    _ticking = false;
    _failures = ok ? 0 : _failures + 1;
    _arm();
  }
}
