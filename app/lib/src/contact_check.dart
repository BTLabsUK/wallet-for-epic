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
/// While push sessions are live ([ContactCheck.live]: a session of the Epicbox relay is attached
/// on every relay a contact or a pairing in flight uses), the relay says when mail comes: the
/// reads of the contacts in flight stop, and the check of every contact is a reconcile every
/// 10 minutes plus one right after a pairing event ([pairingEvent]).
/// A push collect ([pushCollect]) reads when the relay says mail was queued. With no session
/// attached, or a relay that does not offer them, the checks above run unchanged.
///
/// While a boost of [Poller.relays] runs (LEPIC ADR 0058: a send, an invoice, a pay, a code in
/// person) every tick is the full check, at the boost's interval.
library;

import 'dart:async';
import 'dart:math' show max, min;

import 'boosts.dart';
import 'models.dart';
import 'pairing_api.dart';

/// What a [ContactCollect] returns when the call joined a collect already running: it read
/// nothing itself, so the check has learned nothing about the mailboxes.
const collectJoined = -1;

/// Reads the mailboxes of [only] (every contact when null) and returns how many messages it took,
/// or [collectJoined].
typedef ContactCollect = Future<int> Function(PairingCollectTrigger trigger, {List<String>? only});

/// What a full check reads besides the contacts: the name services' payloads and listing drains.
typedef ContactSync = Future<void> Function(PairingCollectTrigger trigger);

/// The contacts something is in flight with: the ids [PairingApi.collect] takes as `only`.
///
/// A pairing in progress ([PairingRecord.state] pending or waiting: a code or request nobody
/// answered, an answer waiting for its confirm, a pairing whose peer was not heard yet), or a
/// contact LEPIC marks [PairingRecord.awaiting] (a message waiting to go out, a payment not
/// yet finished, an invoice from it waiting for an answer). A pairing that is gone or ended
/// has no mailbox to read.
List<String> contactsInFlight(Iterable<PairingRecord> pairings) => [
  for (final r in pairings)
    if (r.state != PairingState.ended && (r.state.isPending || r.state == PairingState.waiting || r.awaiting)) r.id,
]..sort();

/// [PairingApi.collect] that returns how many contact messages it took, by the count [api] keeps,
/// or [collectJoined] when a collect was already running and this call only marked its rerun.
Future<int> collectCounting(PairingApi api, PairingCollectTrigger trigger, {List<String>? only}) async {
  final joined = api.collecting;
  final before = api.messagesCollected;
  await api.collect(trigger: trigger, only: only);
  return joined ? collectJoined : api.messagesCollected - before;
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
    this.idlePaused,
    this.live,
    this.reconcileEvery = const Duration(minutes: 10),
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

  /// True while the wallet is locked: the timer reads nothing then, and the check of every
  /// contact runs as soon as [wake] says it is over. A pull to refresh or an open does not go
  /// through it.
  final bool Function()? paused;

  /// True while the node is down: the check of every contact waits (it needs the node), but the
  /// reads of the contacts in flight and a boost's ticks go on, as pairing needs no node.
  final bool Function()? idlePaused;

  /// True while push sessions are attached for every relay in use: the reads of the contacts in
  /// flight stop and the check of every contact is a reconcile, every [reconcileEvery]. Call
  /// [liveChanged] when it may have changed.
  final bool Function()? live;

  /// The wait between full checks while [live].
  final Duration reconcileEvery;

  final Boosts _boosts;
  final DateTime Function() _now;
  late final PollDriver _driver;
  StreamSubscription<void>? _changes;

  /// The index in [idleChecks] of the wait now running, and when it ends.
  int _step = 0;
  late DateTime _nextFull;
  bool _boosted = false;
  bool _wasLive = false;
  DateTime? _lastFull;

  /// The checks made, for a test: of every contact, of only some, and by push.
  int fullChecks = 0;
  int inFlightChecks = 0;
  int pushChecks = 0;

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
    _wasLive = _isLive;
    if (_wasLive) _nextFull = _now().add(reconcileEvery);
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
    _nextFull = _now().add(_isLive ? reconcileEvery : idleChecks.first);
    _retime(shorten: true);
  }

  /// A pairing moved: while [live] the check of every contact runs at once, as the in-flight
  /// reads that would follow it are off; otherwise as [reset].
  void pairingEvent() {
    if (!_isLive) return reset();
    _step = 0;
    _nextFull = _now();
    _retime(shorten: true);
  }

  bool get _isLive => live?.call() ?? false;

  /// What [live] reads may have changed. Going live puts the next check of every contact one
  /// reconcile after the last; leaving it starts the adaptive wait again at its first step.
  void liveChanged() {
    final now = _isLive;
    if (now == _wasLive) return;
    _wasLive = now;
    _step = 0;
    if (now) {
      _nextFull = (_lastFull ?? _now()).add(reconcileEvery);
    } else {
      _nextFull = _now().add(idleChecks.first);
    }
    _retime();
  }

  /// The relay said mail was queued: reads every contact's mailbox with the push trigger. A
  /// message taken starts the waits again, like a message the tick read.
  Future<void> pushCollect() async {
    if (paused?.call() ?? false) return;
    var messages = 0;
    try {
      messages = await collect(PairingCollectTrigger.push);
    } finally {
      pushChecks++;
      if (messages > 0) {
        _step = 0;
        _nextFull = _now().add(_isLive ? reconcileEvery : idleChecks.first);
        _retime();
      }
    }
  }

  /// The contacts in flight changed: the check of them runs within [inFlightEvery].
  void inFlightChanged() {
    if (!_isLive) _retime(shorten: true);
  }

  /// What [paused] or [idlePaused] read may have changed (an unlock, the node back): the wait
  /// starts again at the first step and the check of every contact is due now.
  void wake() {
    _step = 0;
    _nextFull = _now();
    _retime(shorten: true);
  }

  bool get _idlePaused => idlePaused?.call() ?? false;

  /// The check of every contact now, for an open or a resume ([trigger] says which); the wait
  /// starts again at the first step.
  Future<void> checkAll(PairingCollectTrigger trigger) async {
    try {
      await collect(trigger);
      await sync(trigger);
    } finally {
      fullChecks++;
      _lastFull = _now();
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
    if (boosted || (!_now().isBefore(_nextFull) && !_idlePaused)) {
      var messages = 0;
      var ok = false;
      try {
        messages = await collect(PairingCollectTrigger.foreground);
        await sync(PairingCollectTrigger.foreground);
        ok = true;
      } finally {
        fullChecks++;
        _lastFull = _now();
        // Nothing came: the wait moves one step on. A message or a boost keeps the first, and a
        // call that only joined a collect running read nothing: the step stays.
        _step = messages > 0 || boosted
            ? 0
            : messages == collectJoined
            ? _step
            : min(_step + 1, idleChecks.length - 1);
        _nextFull = _now().add(_isLive && !boosted ? reconcileEvery : idleChecks[_step]);
        _retime();
      }
      return ok;
    }
    // Live: the relay pushes what comes, so nothing is read for the contacts in flight.
    final ids = _isLive ? const <String>[] : inFlight();
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
    // The check of every contact due but held back: look again in [inFlightEvery].
    if (_idlePaused && !_isBoosted) next = max(next, inFlightEvery.inMilliseconds);
    if (!_isLive && inFlight().isNotEmpty) next = min(next, inFlightEvery.inMilliseconds);
    final wait = Duration(milliseconds: max(next, 1000));
    if (shorten && wait >= _driver.base) return;
    _driver.base = wait;
  }
}
