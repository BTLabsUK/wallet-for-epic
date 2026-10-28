// SPDX-License-Identifier: Apache-2.0
/// The server's limits: new demos per client, and Argon2id work at once.
library;

import 'dart:async';
import 'dart:collection';

/// At most [limit] events per client in any [window]. Held in memory only: client addresses
/// never reach disk or the log.
class ClientRateLimit {
  ClientRateLimit({
    required this.limit,
    this.window = const Duration(hours: 1),
  });

  final int limit;
  final Duration window;
  final Map<String, Queue<DateTime>> _events = {};

  /// Records an event for [client] and returns null, or returns how long until one is allowed.
  Duration? take(String client, DateTime now) {
    final events = _events.putIfAbsent(client, Queue.new);
    _drop(events, now);
    if (events.length >= limit) {
      final wait = events.first.add(window).difference(now);
      return wait < const Duration(seconds: 1)
          ? const Duration(seconds: 1)
          : wait;
    }
    events.add(now);
    return null;
  }

  /// Forgets clients with no event inside the window.
  void prune(DateTime now) {
    _events.removeWhere((_, events) {
      _drop(events, now);
      return events.isEmpty;
    });
  }

  void _drop(Queue<DateTime> events, DateTime now) {
    final cutoff = now.subtract(window);
    while (events.isNotEmpty && !events.first.isAfter(cutoff)) {
      events.removeFirst();
    }
  }

  int get clients => _events.length;
}

/// Runs at most [slots] tasks at once; the rest wait in order.
class WorkGate {
  WorkGate(this.slots) : assert(slots > 0);

  final int slots;
  int _running = 0;
  final Queue<Completer<void>> _waiting = Queue();

  int get running => _running;
  int get waiting => _waiting.length;

  Future<T> run<T>(Future<T> Function() task) async {
    if (_running >= slots) {
      final turn = Completer<void>();
      _waiting.add(turn);
      await turn.future;
    } else {
      _running++;
    }
    try {
      return await task();
    } finally {
      if (_waiting.isNotEmpty) {
        // The slot passes straight to the next task, so [_running] stays.
        _waiting.removeFirst().complete();
      } else {
        _running--;
      }
    }
  }
}
