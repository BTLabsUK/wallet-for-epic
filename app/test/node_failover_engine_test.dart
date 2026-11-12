// SPDX-License-Identifier: Apache-2.0
// The node failover engine on a fake clock: rounds ask every node at once, the best-ranked good
// answer wins, nothing answering means rounds with a growing wait until one node is back.

import 'dart:async';
import 'dart:math';

import 'package:epic_wallet/src/node_failover_engine.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

const _a = 'https://a.example:3413';
const _b = 'https://b.example:3413';
const _c = 'https://c.example:3413';
const _d = 'https://d.example:3413';

const _t = FailoverTimings(
  probe: Duration(seconds: 8),
  torProbe: Duration(seconds: 30),
  prefer: Duration(milliseconds: 1500),
  retryMin: Duration(seconds: 2),
  retryMax: Duration(seconds: 60),
  behindAfter: Duration(seconds: 30),
);

/// How a fake node answers: after [after], with [height], or an error, or never.
class _Node {
  _Node.answers(this.height, {this.after = const Duration(milliseconds: 100), this.ready}) : hangs = false, fails = false;
  _Node.fails() : height = 0, after = const Duration(milliseconds: 100), ready = null, hangs = false, fails = true;
  _Node.hangs() : height = 0, ready = null, after = Duration.zero, hangs = true, fails = false;

  final int height;
  final bool? ready;
  final Duration after;
  final bool hangs;
  final bool fails;
}

class _Harness {
  _Harness({String inUse = _a, String chosen = _a, List<String> candidates = const [_b, _c, _d], this.scope = FailoverScope.all, this.clock})
    : inUse = inUse,
      chosen = chosen,
      candidates = candidates {
    engine = FailoverEngine(
      probe: (url) {
        asked.add(url);
        final n = nodes[url] ?? _Node.fails();
        if (n.hangs) return Completer<FailoverAnswer>().future;
        return Future.delayed(n.after, () {
          if (n.fails) throw StateError('down');
          return FailoverAnswer(height: n.height, ready: n.ready);
        });
      },
      switchTo: (url, {required behind}) async {
        switched.add(url);
        inUse = url;
        return true;
      },
      plan: () => FailoverPlan(inUse: inUse, chosen: chosen, candidates: candidates, scope: scope, height: height),
      timings: () => _t,
      stay: () => stays++,
      onState: states.add,
      log: (line) {
        lines.add(line);
        if (line.contains('round (') && clock != null) roundsAt.add(clock!());
      },
      random: Random(7),
    );
  }

  late final FailoverEngine engine;
  String inUse;
  String chosen;
  List<String> candidates;
  FailoverScope scope;
  int? height;
  final nodes = <String, _Node>{};
  final asked = <String>[];
  final switched = <String>[];
  final states = <FailoverSearch>[];
  final lines = <String>[];
  final roundsAt = <Duration>[];
  final Duration Function()? clock;
  int stays = 0;
}

void main() {
  test('the node in use is dead: the best answering node is used, silently', () {
    fakeAsync((async) {
      final h = _Harness();
      h.nodes[_b] = _Node.fails();
      h.nodes[_c] = _Node.answers(100, after: const Duration(milliseconds: 400));
      h.nodes[_d] = _Node.answers(100, after: const Duration(milliseconds: 100));
      h.engine.nodeFailed();
      async.flushMicrotasks();
      expect(h.engine.state, FailoverSearch.searching);
      expect(h.asked, [_a, _b, _c, _d], reason: 'the chosen node, then the others, all at once');
      async.elapse(const Duration(seconds: 2));
      expect(h.switched, [_c], reason: 'c ranks above d and answered within the prefer window');
      expect(h.engine.state, FailoverSearch.idle);
      expect(h.lines.last, contains('moved to c.example'));
    });
  });

  test('a probe that never returns: the others win after the prefer window, the round ends at the budget', () {
    fakeAsync((async) {
      final h = _Harness();
      h.nodes[_b] = _Node.hangs();
      h.nodes[_c] = _Node.answers(100);
      h.engine.nodeFailed();
      async.elapse(const Duration(milliseconds: 1000));
      expect(h.switched, isEmpty, reason: 'b ranks above c and may still answer');
      async.elapse(const Duration(milliseconds: 700));
      expect(h.switched, [_c]);

      final g = _Harness();
      g.nodes[_b] = _Node.hangs();
      g.nodes[_c] = _Node.hangs();
      g.nodes[_d] = _Node.hangs();
      g.engine.nodeFailed();
      async.elapse(const Duration(milliseconds: 7900));
      expect(g.engine.state, FailoverSearch.searching);
      async.elapse(const Duration(milliseconds: 200));
      expect(g.engine.state, FailoverSearch.noneAnswer, reason: 'each probe counts as failed at its budget');
    });
  });

  test('the node in use answers again inside the round: it stays, tip and balance read again', () {
    fakeAsync((async) {
      final h = _Harness(inUse: _b, chosen: _a);
      h.nodes[_b] = _Node.answers(100);
      h.nodes[_c] = _Node.answers(100);
      h.engine.nodeFailed();
      async.elapse(const Duration(seconds: 1));
      expect(h.switched, isEmpty);
      expect(h.stays, 1);
      expect(h.engine.state, FailoverSearch.idle);
    });
  });

  test('the chosen node is back: the wallet goes back to it', () {
    fakeAsync((async) {
      final h = _Harness(inUse: _b, chosen: _a);
      h.nodes[_a] = _Node.answers(100, after: const Duration(milliseconds: 600));
      h.nodes[_b] = _Node.answers(100);
      h.engine.nodeFailed();
      async.elapse(const Duration(seconds: 3));
      expect(h.switched, [_a]);
    });
  });

  test('a node not ready for transactions does not count', () {
    fakeAsync((async) {
      final h = _Harness();
      h.nodes[_b] = _Node.answers(100, ready: false);
      h.nodes[_c] = _Node.answers(100, ready: true);
      h.engine.nodeFailed();
      async.elapse(const Duration(seconds: 3));
      expect(h.switched, [_c]);
    });
  });

  test('behind: after the wait a node ahead is used, a node not ahead is not', () {
    fakeAsync((async) {
      final h = _Harness()..height = 100;
      h.nodes[_b] = _Node.answers(105);
      h.nodes[_c] = _Node.answers(150);
      h.engine.nodeBehind();
      async.elapse(const Duration(seconds: 29));
      expect(h.asked, isEmpty, reason: 'a node behind is left only after the wait');
      async.elapse(const Duration(seconds: 3));
      expect(h.asked, isNot(contains(_a)), reason: 'the node in use is the one behind');
      expect(h.switched, [_c], reason: 'b is not ahead by enough');
      expect(h.states, isNot(contains(FailoverSearch.searching)), reason: 'a node behind still answers');

      final g = _Harness()..height = 100;
      g.nodes[_b] = _Node.answers(104);
      g.engine.nodeBehind();
      async.elapse(const Duration(seconds: 40));
      expect(g.switched, isEmpty);
      expect(g.engine.state, FailoverSearch.idle);
    });
  });

  test('all down: none answer, rounds at growing jittered waits up to the max, then back by itself', () {
    fakeAsync((async) {
      final h = _Harness(clock: () => async.elapsed);
      h.engine.nodeFailed();
      async.elapse(const Duration(seconds: 1));
      expect(h.engine.state, FailoverSearch.noneAnswer);
      async.elapse(const Duration(minutes: 6));
      expect(h.engine.state, FailoverSearch.noneAnswer, reason: 'a retry does not flip the status back');
      final waits = [for (var i = 1; i < h.roundsAt.length; i++) h.roundsAt[i] - h.roundsAt[i - 1] - const Duration(milliseconds: 100)];
      expect(waits.length, greaterThanOrEqualTo(8));
      expect(waits.first.inMilliseconds, inInclusiveRange(1600, 2400));
      expect(waits[3], greaterThan(waits[1]));
      for (final w in waits) {
        expect(w.inMilliseconds, inInclusiveRange(_t.retryMin.inMilliseconds, _t.retryMax.inMilliseconds));
      }
      expect(waits.last, greaterThanOrEqualTo(const Duration(seconds: 48)), reason: 'capped near the max');

      h.nodes[_d] = _Node.answers(100);
      async.elapse(const Duration(seconds: 70));
      expect(h.switched, [_d], reason: 'no user action needed');
      expect(h.engine.state, FailoverSearch.idle);
    });
  });

  test('a kick during a wait runs a round now and starts the backoff over', () {
    fakeAsync((async) {
      final h = _Harness();
      h.engine.nodeFailed();
      async.elapse(const Duration(seconds: 1));
      for (var i = 0; i < 5; i++) {
        async.elapse(const Duration(seconds: 61));
      }
      final before = h.asked.length;
      h.engine.kick('network');
      async.flushMicrotasks();
      expect(h.asked.length, before + 4);
      expect(h.lines, contains('node failover: kick (network)'));
      async.elapse(const Duration(seconds: 1));
      expect(h.lines.last, matches(RegExp(r'next in [12]s')), reason: 'backoff starts over');
    });
  });

  test('the user picks a node during a round: its result is not applied', () {
    fakeAsync((async) {
      final h = _Harness();
      h.nodes[_c] = _Node.answers(100, after: const Duration(seconds: 1));
      h.engine.nodeFailed();
      async.elapse(const Duration(milliseconds: 500));
      h.engine.userPicked();
      expect(h.engine.state, FailoverSearch.idle);
      async.elapse(const Duration(seconds: 120));
      expect(h.switched, isEmpty);
    });
  });

  test('held: only the node in use is asked, and it recovers', () {
    fakeAsync((async) {
      final h = _Harness(scope: FailoverScope.inUseOnly);
      h.nodes[_b] = _Node.answers(100);
      h.engine.nodeFailed();
      async.elapse(const Duration(seconds: 9));
      expect(h.asked.toSet(), {_a});
      expect(h.engine.state, FailoverSearch.noneAnswer);
      h.nodes[_a] = _Node.answers(100);
      async.elapse(const Duration(seconds: 20));
      expect(h.stays, greaterThanOrEqualTo(1));
      expect(h.switched, isEmpty);
      h.engine.nodeAnswered();
      expect(h.engine.state, FailoverSearch.idle);
      final before = h.asked.length;
      async.elapse(const Duration(minutes: 5));
      expect(h.asked.length, before, reason: 'nothing more once it answers');
    });
  });

  test('Kill switch or waiting for Tor: nothing is asked until a kick', () {
    fakeAsync((async) {
      final h = _Harness(scope: FailoverScope.none);
      h.nodes[_b] = _Node.answers(100);
      h.engine.nodeFailed();
      async.elapse(const Duration(minutes: 5));
      expect(h.asked, isEmpty);
      h.scope = FailoverScope.all;
      h.engine.kick('tor');
      async.elapse(const Duration(seconds: 3));
      expect(h.switched, [_b]);
    });
  });

  test('paused: no probes; resumed: a round', () {
    fakeAsync((async) {
      final h = _Harness();
      h.engine.pause();
      h.engine.nodeFailed();
      async.elapse(const Duration(minutes: 5));
      expect(h.asked, isEmpty);
      h.nodes[_b] = _Node.answers(100);
      h.engine.resume();
      async.elapse(const Duration(seconds: 3));
      expect(h.switched, [_b]);
    });
  });

  test('the node answers: the search ends and no round waits', () {
    fakeAsync((async) {
      final h = _Harness();
      h.engine.nodeFailed();
      async.elapse(const Duration(seconds: 1));
      expect(h.engine.state, FailoverSearch.noneAnswer);
      h.engine.nodeAnswered();
      expect(h.engine.state, FailoverSearch.idle);
      final before = h.asked.length;
      async.elapse(const Duration(minutes: 5));
      expect(h.asked.length, before);
    });
  });

  test('two refreshes in a row unvalidated: the next round leaves the node in use out', () {
    fakeAsync((async) {
      final h = _Harness(inUse: _b, chosen: _a);
      h.nodes[_b] = _Node.answers(100);
      h.nodes[_c] = _Node.answers(100);
      h.engine.refreshEnded(validated: false);
      async.elapse(const Duration(seconds: 1));
      expect(h.stays, 1, reason: 'the first time the tip answer is believed');
      h.engine.refreshEnded(validated: false);
      async.elapse(const Duration(seconds: 3));
      expect(h.switched, [_c]);
    });
  });

  test('the retry wait grows from the min to the max with jitter', () {
    final r = Random(3);
    for (var n = 1; n < 12; n++) {
      final w = failoverRetryWait(n, _t, r);
      expect(w, greaterThanOrEqualTo(_t.retryMin));
      expect(w, lessThanOrEqualTo(_t.retryMax));
    }
    expect(failoverRetryWait(10, _t, r), greaterThanOrEqualTo(const Duration(seconds: 48)));
    expect(failoverRetryWait(1, _t, r), lessThanOrEqualTo(const Duration(milliseconds: 2400)));
  });
}
