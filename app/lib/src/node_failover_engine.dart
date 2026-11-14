// SPDX-License-Identifier: Apache-2.0
/// Node failover, the engine both apps run: it decides when to ask the user's nodes, asks them
/// all at once, and moves the wallet to the best one that answers, for this session only. The
/// phone (`node_failover_phone.dart`) and the desktop feed it what their status sees and give it
/// three things: a way to ask one node its tip, a way to switch to one, and the plan of a round
/// (the node in use, the chosen one, the others in order, and what the holds allow).
///
/// Pure Dart: no Riverpod, no Flutter, no dart:io. Timers and randomness are injected, so tests
/// run it on a fake clock.
library;

import 'dart:async';
import 'dart:math';

import 'node_failover.dart' show failoverAhead, isLocalNodeUrl;
import 'server_list.dart' show ServerKind, sameServer;

/// What a round may ask (see [failoverScope]).
enum FailoverScope {
  /// Nothing: Kill switch, or the node waits for Tor. The engine waits for a kick.
  none,

  /// Only the node in use: the wallet recovers by itself but never moves (failover off, Node
  /// only, a node on this computer, a payment in progress).
  inUseOnly,

  /// The chosen node, the node in use and the candidates.
  all,
}

/// What the status shows of the engine.
enum FailoverSearch {
  /// Nothing to search: the node answers, or a move or a stay was just made.
  idle,

  /// A round runs after the node in use stopped answering: the node reads connecting.
  searching,

  /// The last round found no node that answers: the node reads offline. Rounds go on.
  noneAnswer,
}

/// A node's answer to a tip ask.
class FailoverAnswer {
  const FailoverAnswer({required this.height, this.ready});

  /// The node's chain height.
  final int height;

  /// Whether the node says it is ready for transactions; null when it does not say.
  final bool? ready;
}

/// The facts a round needs, read when it starts.
class FailoverPlan {
  const FailoverPlan({
    required this.inUse,
    required this.chosen,
    required this.candidates,
    required this.scope,
    this.overTor = false,
    this.height,
  });

  /// The node the wallet talks to now.
  final String inUse;

  /// The node the user chose (saved).
  final String chosen;

  /// The other nodes to ask, best first (`failoverCandidates`).
  final List<String> candidates;

  /// What the holds allow.
  final FailoverScope scope;

  /// The Tor switch is on: nodes not on this computer get the Tor probe budget.
  final bool overTor;

  /// The height of the node in use, for a round after it fell behind.
  final int? height;
}

/// The engine's waits (`node.failover_*` in the app config).
class FailoverTimings {
  const FailoverTimings({
    required this.probe,
    required this.torProbe,
    required this.prefer,
    required this.retryMin,
    required this.retryMax,
    required this.behindAfter,
  });

  /// One tip ask, direct (`failover_probe_s`).
  final Duration probe;

  /// One tip ask over Tor (`failover_tor_probe_s`).
  final Duration torProbe;

  /// After the first good answer, how long a better-ranked one may still come (`failover_prefer_ms`).
  final Duration prefer;

  /// The first wait after a round found nothing (`failover_retry_min_s`); it doubles up to [retryMax].
  final Duration retryMin;

  /// The longest wait between rounds (`failover_retry_max_s`).
  final Duration retryMax;

  /// How long a node may be behind before it is left (`failover_after_s`).
  final Duration behindAfter;
}

/// The jittered backoff before round [failed] + 1 when [failed] rounds in a row found nothing:
/// [FailoverTimings.retryMin] doubling to [FailoverTimings.retryMax], each +-20 %, never outside
/// the two.
Duration failoverRetryWait(int failed, FailoverTimings t, Random random) {
  final minMs = t.retryMin.inMilliseconds;
  final maxMs = max(minMs, t.retryMax.inMilliseconds);
  final base = min(maxMs.toDouble(), minMs * pow(2, max(0, failed - 1)).toDouble());
  final jittered = base * (0.8 + 0.4 * random.nextDouble());
  return Duration(milliseconds: jittered.round().clamp(minMs, maxMs));
}

/// The failover engine. One per open wallet; [dispose] it when the wallet closes.
class FailoverEngine {
  FailoverEngine({
    required this.probe,
    required this.switchTo,
    required this.plan,
    required this.timings,
    this.stay,
    this.onState,
    this.log,
    this.freshConnections,
    Timer Function(Duration wait, void Function() run)? timer,
    Random? random,
  }) : _timer = timer ?? Timer.new,
       _random = random ?? Random();

  /// Asks one node its tip. A throw counts as no answer; the engine bounds the wait.
  final Future<FailoverAnswer> Function(String url) probe;

  /// Moves the wallet to a node for this session; false when that did not happen.
  final Future<bool> Function(String url, {required bool behind}) switchTo;

  /// The facts of a round, read when it starts; null when no wallet is open.
  final FutureOr<FailoverPlan?> Function() plan;

  /// The waits, read when they are needed (the config may change).
  final FailoverTimings Function() timings;

  /// The node in use answered a round: read tip and balance again.
  final void Function()? stay;

  /// The search state changed.
  final void Function(FailoverSearch state)? onState;

  /// One log line (hosts only).
  final void Function(String line)? log;

  /// Asks the wallet to stop reusing kept-open node connections.
  final void Function()? freshConnections;

  final Timer Function(Duration wait, void Function() run) _timer;
  final Random _random;

  FailoverSearch _state = FailoverSearch.idle;

  /// Bumped by everything that makes a running round's result void.
  int _gen = 0;
  bool _running = false;
  bool _paused = false;
  bool _disposed = false;

  /// The node in use failed and has not answered since.
  bool _failing = false;

  /// The node in use is behind (and answering).
  bool _behind = false;

  /// It has been behind for the whole wait: rounds may look for a node ahead.
  bool _behindRipe = false;

  /// Rounds since the node last answered (none found, a stay, or a move the status has not
  /// confirmed yet), for the backoff.
  int _failed = 0;

  /// Refreshes in a row that ended unvalidated while the tip answered.
  int _badRefreshes = 0;

  /// The next round leaves the node in use out (its refreshes kept failing).
  bool _skipInUse = false;

  Timer? _retry;
  Timer? _behindTimer;

  /// What the status shows.
  FailoverSearch get state => _state;

  /// A round is running.
  bool get running => _running;

  /// A failure, a stay or a move since the node in use last answered.
  bool get awaitsAnswer => _failing || _failed > 0;

  /// A check of the node in use failed or timed out. The first round after a failure starts at
  /// once; while the failure lasts, rounds follow the backoff.
  void nodeFailed() {
    if (_disposed) return;
    if (_failing) {
      if (!_running && _retry == null) _scheduleRetry();
      return;
    }
    _failing = true;
    // A search begins: its first round must not ask on a connection the system cut.
    _fresh();
    _cancelBehind();
    if (_failed > 0) {
      // A move or a stay since the last answer did not bring the node back: the backoff goes
      // on, so a wallet whose refresh fails on every node never loops between them.
      if (!_running && _retry == null) _scheduleRetry();
      return;
    }
    _roundNow('node not answering');
  }

  /// A refresh of the node in use ended, [validated] or not. Two unvalidated ones in a row and
  /// the next round treats the node in use as down.
  void refreshEnded({required bool validated}) {
    if (_disposed) return;
    if (validated) {
      _badRefreshes = 0;
      return;
    }
    _badRefreshes++;
    if (_badRefreshes >= 2) {
      _badRefreshes = 0;
      _skipInUse = true;
    }
    if (!_failing) {
      nodeFailed();
    } else if (_skipInUse && !_running) {
      if (_failed == 0) {
        _retry?.cancel();
        _retry = null;
        _roundNow('refresh failed');
      } else if (_retry == null) {
        _scheduleRetry();
      }
    }
  }

  /// The node in use answers but is behind. After [FailoverTimings.behindAfter] a round looks for
  /// a node ahead of it.
  void nodeBehind() {
    if (_disposed) return;
    if (_failing) {
      // It answers again: the failure is over, the behind wait starts.
      nodeAnswered();
    }
    if (_behind) return;
    _behind = true;
    _behindRipe = false;
    _failed = 0;
    _startBehindWait();
  }

  void _startBehindWait() {
    _behindTimer?.cancel();
    _behindTimer = _paused ? null : _timer(timings().behindAfter, () {
      _behindTimer = null;
      _behindRipe = true;
      _roundNow('node behind');
    });
  }

  /// The node in use answered and is not behind: any search ends, the backoff starts over.
  void nodeAnswered() {
    if (_disposed) return;
    final was = _failing || _behind || _running || _retry != null;
    _failing = false;
    _cancelBehind();
    _failed = 0;
    _skipInUse = false;
    _retry?.cancel();
    _retry = null;
    if (_running) _gen++;
    _running = false;
    if (was) _set(FailoverSearch.idle);
  }

  /// Resume, a network change, Tor connected or switched, failover turned on, wallet opened: a
  /// waiting round runs now and the backoff starts over.
  void kick(String why) {
    if (_disposed) return;
    // The network may have changed, whether or not a search runs.
    _fresh();
    _failed = 0;
    if (!_failing && !(_behind && _behindRipe)) return;
    log?.call('node failover: kick ($why)');
    if (_running || _paused) return;
    _retry?.cancel();
    _retry = null;
    _roundNow(why);
  }

  /// The user picked a node: a running round is dropped, nothing waits, the backoff starts over.
  void userPicked() {
    if (_disposed) return;
    _gen++;
    _running = false;
    _failing = false;
    _cancelBehind();
    _failed = 0;
    _badRefreshes = 0;
    _skipInUse = false;
    _retry?.cancel();
    _retry = null;
    _set(FailoverSearch.idle);
  }

  /// The app went to the background: nothing is asked until [resume].
  void pause() {
    if (_disposed) return;
    _paused = true;
    _gen++;
    _running = false;
    _retry?.cancel();
    _retry = null;
    _behindTimer?.cancel();
    _behindTimer = null;
  }

  /// The app is back: a round runs at once if the node was failing or behind.
  void resume() {
    if (_disposed) return;
    _fresh();
    if (!_paused) return;
    _paused = false;
    _failed = 0;
    if (_failing || (_behind && _behindRipe)) {
      _roundNow('resume');
    } else if (_behind) {
      _startBehindWait();
    }
  }

  /// The wallet closed: everything stops.
  void dispose() {
    _disposed = true;
    _gen++;
    _retry?.cancel();
    _behindTimer?.cancel();
  }

  void _fresh() {
    try {
      freshConnections?.call();
    } catch (_) {}
  }

  void _cancelBehind() {
    _behind = false;
    _behindRipe = false;
    _behindTimer?.cancel();
    _behindTimer = null;
  }

  void _set(FailoverSearch s) {
    if (_state == s) return;
    _state = s;
    onState?.call(s);
  }

  void _scheduleRetry() {
    if (_disposed || _paused) return;
    _retry?.cancel();
    final t = timings();
    var wait = failoverRetryWait(max(1, _failed), t, _random);
    // Behind is not down: a node ahead is looked for no more often than the behind wait.
    if (!_failing && wait < t.behindAfter) wait = t.behindAfter;
    _lastWait = wait;
    _retry = _timer(wait, () {
      _retry = null;
      _roundNow('retry');
    });
  }

  Duration _lastWait = Duration.zero;

  void _roundNow(String why) {
    if (_disposed || _paused || _running) return;
    unawaited(_round(why));
  }

  Future<void> _round(String why) async {
    final gen = ++_gen;
    _running = true;
    final behindRound = !_failing && _behind && _behindRipe;
    final skip = _skipInUse;
    _skipInUse = false;
    final first = _failed == 0;
    if (_failing && (first || _state == FailoverSearch.idle)) _set(FailoverSearch.searching);

    FailoverPlan? p;
    try {
      p = await plan();
    } catch (_) {
      p = null;
    }
    if (gen != _gen) return;
    if (p == null || p.scope == FailoverScope.none) {
      // Nothing may be asked now. A kick (Tor up, mode changed, resume) runs the next round at
      // once; without one the plan is read again after the backoff, so a hold that ended
      // unseen is not a dead end. No plan (a switch the user started runs) is not "none answer".
      _running = false;
      if (_failing && p != null) _set(FailoverSearch.noneAnswer);
      if (_failed == 0) log?.call('node failover: round ($why) held, waiting');
      _failed++;
      _scheduleRetry();
      return;
    }

    final asked = _nodesFor(p, behind: behindRound, skipInUse: skip);
    log?.call('node failover: round ($why), ${asked.length} node(s)');
    final t = timings();
    final best = await _ask(asked, p, t, gen, behind: behindRound);
    if (gen != _gen) return;

    for (final url in best) {
      if (sameServer(ServerKind.node, url, p.inUse) && !behindRound) {
        _running = false;
        // It answered the probe and the status is about to confirm it: connecting is the truth
        // until nodeAnswered ends the search (or a later round finds nothing).
        _set(_failing ? FailoverSearch.searching : FailoverSearch.idle);
        log?.call('node failover: stay on ${_host(url)}');
        stay?.call();
        // The node answered the round; the status confirms it. Until then the next round waits.
        _failed++;
        _scheduleRetry();
        return;
      }
      var moved = false;
      try {
        moved = await switchTo(url, behind: behindRound);
      } catch (_) {
        moved = false;
      }
      if (gen != _gen) return;
      if (moved) {
        _running = false;
        _failing = false;
        _cancelBehind();
        // Counted until the new node answers (nodeAnswered starts the backoff over).
        _failed++;
        _set(FailoverSearch.idle);
        log?.call('node failover: moved to ${_host(url)}');
        return;
      }
    }

    _running = false;
    _failed++;
    if (_failing) _set(FailoverSearch.noneAnswer);
    _scheduleRetry();
    log?.call('node failover: ${behindRound ? 'no node ahead' : 'no node answered'}, next in ${_lastWait.inSeconds}s');
  }

  /// The nodes a round asks, best first: the chosen node, the node in use, then the candidates.
  List<String> _nodesFor(FailoverPlan p, {required bool behind, required bool skipInUse}) {
    final out = <String>[];
    void add(String url) {
      if (url.trim().isEmpty || out.any((u) => sameServer(ServerKind.node, u, url))) return;
      out.add(url);
    }

    final inUse = p.inUse;
    final leaveInUse = behind || skipInUse;
    if (p.scope == FailoverScope.inUseOnly) {
      // Held: the wallet may only recover on its node. Behind and held: nothing to look for.
      if (!behind) add(inUse);
      return out;
    }
    if (!sameServer(ServerKind.node, p.chosen, inUse) || !leaveInUse) add(p.chosen);
    if (!leaveInUse) add(inUse);
    p.candidates.forEach(add);
    if (leaveInUse) out.removeWhere((u) => sameServer(ServerKind.node, u, inUse));
    return out;
  }

  /// Asks [nodes] at once and returns the good ones, best-ranked first. Waits until every node
  /// answered or failed, or until [FailoverTimings.prefer] after the first good answer, or until
  /// every node ranked above the best good one has finished.
  Future<List<String>> _ask(List<String> nodes, FailoverPlan p, FailoverTimings t, int gen, {required bool behind}) {
    final done = Completer<List<String>>();
    if (nodes.isEmpty) {
      done.complete(const []);
      return done.future;
    }
    final good = List<bool?>.filled(nodes.length, null);
    final timers = <Timer>[];
    Timer? prefer;

    void finish() {
      if (done.isCompleted) return;
      for (final x in timers) {
        x.cancel();
      }
      prefer?.cancel();
      done.complete([for (var i = 0; i < nodes.length; i++) if (good[i] == true) nodes[i]]);
    }

    void check() {
      if (done.isCompleted) return;
      if (gen != _gen) return finish();
      final firstGood = good.indexOf(true);
      if (firstGood >= 0 && good.sublist(0, firstGood).every((g) => g != null)) return finish();
      if (good.every((g) => g != null)) return finish();
      if (firstGood >= 0 && prefer == null) prefer = _timer(t.prefer, finish);
    }

    void settle(int i, bool ok) {
      if (good[i] != null || done.isCompleted) return;
      good[i] = ok;
      check();
    }

    for (var i = 0; i < nodes.length; i++) {
      final url = nodes[i];
      final budget = p.overTor && !isLocalNodeUrl(url) ? t.torProbe : t.probe;
      timers.add(_timer(budget, () => settle(i, false)));
      Future<FailoverAnswer>.sync(() => probe(url)).then(
        (a) => settle(i, a.ready != false && (!behind || failoverAhead(a.height, p.height ?? 0))),
        onError: (Object _) => settle(i, false),
      );
    }
    return done.future;
  }

  static String _host(String url) {
    final host = Uri.tryParse(url.trim())?.host ?? '';
    return host.isEmpty ? 'node' : host;
  }
}
