// SPDX-License-Identifier: Apache-2.0
/// The foreground check of the contacts' mailboxes (RFC 8.4), as light on the relays as it can
/// be while a message that is expected still comes fast.
///
/// Two checks run on one timer:
///  - the check of the contacts with something in flight ([ContactCheck.inFlight]): only their
///    mailboxes, every `contacts.in_flight_check_s` (45 s);
///  - the check of every contact, with the name services' payloads and listing drains. It
///    waits `contacts.idle_check_s` (45, 90, 180, 300 s): one step longer after each check that
///    brought no message, the last one repeating, and back to the first on a message, a resume,
///    an unlock, a pairing event, a payment to the payments address or a boost.
///
/// While a boost of [Poller.relays] runs (LEPIC ADR 0058: a send, an invoice, a pay, a code in
/// person) every tick is the full check, at the boost's interval.
library;

import 'dart:async';
import 'dart:math' show max, min;

import 'boosts.dart';
import 'models.dart';
import 'pairing_api.dart';

/// Reads the mailboxes of [only] (every contact when null) and returns how many messages it took.
typedef ContactCollect = Future<int> Function(PairingCollectTrigger trigger, {List<String>? only});

/// What a full check reads besides the contacts: the name services' payloads and listing drains.
typedef ContactSync = Future<void> Function(PairingCollectTrigger trigger);

/// The contacts something is in flight with: the ids [PairingApi.collect] takes as `only`.
///
/// For now it is what the app already knows: a pairing in progress ([pairings]: a code or
/// request nobody answered, an answer waiting for its confirm, a pairing whose peer was not
/// heard yet), a send that waits for the recipient ([sendPairings]) and a request this wallet
/// issued that is not paid ([requestPairings]), each given as the pairing's id. Once the
/// binding carries `ContactView.awaiting`, this reads that instead.
List<String> contactsInFlight({
  required Iterable<PairingRecord> pairings,
  Iterable<String?> sendPairings = const [],
  Iterable<String?> requestPairings = const [],
}) {
  // A pairing that is gone or ended has no mailbox to read.
  final live = {
    for (final r in pairings)
      if (r.state != PairingState.ended) r.id,
  };
  final ids = <String>{
    for (final r in pairings)
      if (r.state.isPending || r.state == PairingState.waiting) r.id,
    for (final id in sendPairings)
      if (id != null) id,
    for (final id in requestPairings)
      if (id != null) id,
  };
  return [
    for (final id in ids)
      if (live.contains(id)) id,
  ]..sort();
}

/// [PairingApi.collect] that returns how many contact messages it took, by the count [api] keeps.
Future<int> collectCounting(PairingApi api, PairingCollectTrigger trigger, {List<String>? only}) async {
  final before = api.messagesCollected;
  await api.collect(trigger: trigger, only: only);
  return api.messagesCollected - before;
}

/// The timer behind the contacts' foreground check. Plain Dart: the phone's and the desktop's
/// shells give it their calls.
class ContactCheck {
  ContactCheck({
    required Boosts boosts,
    required this.collect,
    required this.sync,
    required this.inFlight,
    required this.idleChecks,
    required this.inFlightEvery,
    this.paused,
    DateTime Function()? now,
  }) : _boosts = boosts,
       _now = now ?? DateTime.now {
    assert(idleChecks.isNotEmpty);
    _nextFull = _now().add(idleChecks.first);
    _driver = PollDriver(boosts, Poller.relays, base: idleChecks.first, tick: _tick);
  }

  final ContactCollect collect;
  final ContactSync sync;

  /// The ids of the contacts with something in flight now.
  final List<String> Function() inFlight;

  /// The waits between full checks, one step later after each that finds nothing.
  final List<Duration> idleChecks;
  final Duration inFlightEvery;

  /// True while the wallet is locked or its node is down: the timer reads nothing then, and
  /// the check of every contact runs as soon as [wake] says it is over. A pull to refresh or an
  /// open does not go through it.
  final bool Function()? paused;

  final Boosts _boosts;
  final DateTime Function() _now;
  late final PollDriver _driver;
  StreamSubscription<void>? _changes;

  /// The index in [idleChecks] of the wait now running, and when it ends.
  int _step = 0;
  late DateTime _nextFull;
  bool _boosted = false;

  /// The checks made, for a test: of every contact, and of only some.
  int fullChecks = 0;
  int inFlightChecks = 0;

  bool get running => _driver.running;

  /// When the check of every contact is due if nothing changes.
  DateTime get nextFull => _nextFull;

  void start() {
    if (running) return;
    _changes = _boosts.changed.listen((_) {
      final boosted = _isBoosted;
      // A boost starting is a message expected: the first wait again.
      if (boosted && !_boosted) reset();
      _boosted = boosted;
    });
    _boosted = _isBoosted;
    _retime();
    _driver.start();
  }

  void stop() {
    _changes?.cancel();
    _changes = null;
    _driver.stop();
  }

  bool get _isBoosted => _boosts.interval(Poller.relays, inFlightEvery) < inFlightEvery;

  /// A message came, a pairing moved, or a payment reached the payments address: the check of
  /// every contact is one first wait away.
  void reset() {
    _step = 0;
    _nextFull = _now().add(idleChecks.first);
    _retime(shorten: true);
  }

  /// The contacts in flight changed: the check of them runs within [inFlightEvery].
  void inFlightChanged() => _retime(shorten: true);

  /// What [paused] reads may have changed: when it is over, the check runs now.
  void wake() => _retime(shorten: true);

  /// The check of every contact now, for an open or a resume ([trigger] says which); the wait
  /// starts again at the first step.
  Future<void> checkAll(PairingCollectTrigger trigger) async {
    try {
      await collect(trigger);
      await sync(trigger);
    } finally {
      fullChecks++;
      reset();
    }
  }

  Future<bool> _tick() async {
    if (paused?.call() ?? false) {
      // Nothing is read; look again in [inFlightEvery], or at once on [wake].
      _driver.base = inFlightEvery;
      return true;
    }
    final boosted = _isBoosted;
    if (boosted || !_now().isBefore(_nextFull)) {
      var messages = 0;
      var ok = false;
      try {
        messages = await collect(PairingCollectTrigger.foreground);
        await sync(PairingCollectTrigger.foreground);
        ok = true;
      } finally {
        fullChecks++;
        // Nothing came: the wait moves one step on. A message or a boost keeps the first.
        _step = messages > 0 || boosted ? 0 : min(_step + 1, idleChecks.length - 1);
        _nextFull = _now().add(idleChecks[_step]);
        _retime();
      }
      return ok;
    }
    final ids = inFlight();
    var ok = true;
    var messages = 0;
    try {
      if (ids.isNotEmpty) messages = await collect(PairingCollectTrigger.foreground, only: ids);
    } on Object {
      ok = false;
    } finally {
      if (ids.isNotEmpty) inFlightChecks++;
      if (messages > 0) {
        _step = 0;
        _nextFull = _now().add(idleChecks.first);
      }
      _retime();
    }
    return ok;
  }

  /// Sets the wait to the next due check: the time to the next check of every contact, or
  /// [inFlightEvery] when a contact has something in flight and that is nearer. [shorten] sets
  /// the timer again only when that is shorter than the base now.
  void _retime({bool shorten = false}) {
    var next = _nextFull.difference(_now()).inMilliseconds;
    if (inFlight().isNotEmpty) next = min(next, inFlightEvery.inMilliseconds);
    final wait = Duration(milliseconds: max(next, 1000));
    if (shorten && wait >= _driver.base) return;
    _driver.base = wait;
  }
}
