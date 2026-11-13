// SPDX-License-Identifier: Apache-2.0
// The contacts' foreground check (contact_check.dart): an idle wallet backs off from 45 s to
// 300 s between checks of every contact, a contact with something in flight is read every 45 s,
// and a boost ticks as fast as it asks. Fake time and fake collect/sync calls; no relay.
import 'package:epic_wallet/src/boosts.dart';
import 'package:epic_wallet/src/contact_check.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

const _idle = [Duration(seconds: 45), Duration(seconds: 90), Duration(seconds: 180), Duration(seconds: 300)];
const _inFlightEvery = Duration(seconds: 45);
const _hour = Duration(hours: 1);
const _s = Duration(seconds: 1);

/// Five paired contacts, one name-service listing on one relay. Every call is recorded with the
/// time it was made.
class _Rig {
  _Rig(this.time, {this.inFlight = const []}) {
    boosts = MemoryBoosts();
    check = ContactCheck(
      boosts: boosts,
      collect: _collect,
      sync: _sync,
      inFlight: () => inFlight,
      idleChecks: _idle,
      inFlightEvery: _inFlightEvery,
      now: () => start.add(time.elapsed),
    );
  }

  static const contacts = ['c1', 'c2', 'c3', 'c4', 'c5'];
  final FakeAsync time;
  final start = DateTime.utc(2026, 11, 13, 9);
  late final MemoryBoosts boosts;
  late final ContactCheck check;
  List<String> inFlight;

  /// Messages the next collect returns (once).
  int messages = 0;

  final calls = <({Duration at, PairingCollectTrigger trigger, List<String>? only})>[];
  int listingDrains = 0;

  /// Mailboxes read: a full collect reads all five, an `only` collect the ids given.
  int get mailboxReads => calls.fold(0, (n, c) => n + (c.only?.length ?? contacts.length));
  int get fullCollects => calls.where((c) => c.only == null).length;
  int get inFlightCollects => calls.where((c) => c.only != null).length;

  Future<int> _collect(PairingCollectTrigger trigger, {List<String>? only}) async {
    calls.add((at: time.elapsed, trigger: trigger, only: only));
    final m = messages;
    messages = 0;
    return m;
  }

  Future<void> _sync(PairingCollectTrigger trigger) async => listingDrains++;

  /// The longest wait for a message that lands in [contact]'s mailbox at any second of
  /// [window]: the time to the first collect that reads that mailbox.
  Duration longestWait(String contact, Duration window, {Duration from = Duration.zero}) {
    var worst = Duration.zero;
    for (var t = from; t < window; t += _s) {
      final next = calls.where((c) => c.at >= t && (c.only == null || c.only!.contains(contact)));
      if (next.isEmpty) continue;
      final wait = next.first.at - t;
      if (wait > worst) worst = wait;
    }
    return worst;
  }
}

void main() {
  test('an idle hour: the full check backs off 45, 90, 180, 300 s and nothing is read in between', () {
    fakeAsync((time) {
      final rig = _Rig(time);
      rig.check.start();
      time.elapse(_hour);
      rig.check.stop();

      // Main ticked a full collect and a listing drain every 45 s: 3600 / 45 = 80 of each, 400
      // mailbox reads. Now:
      // ignore: avoid_print
      print('idle hour: ${rig.fullCollects} full collects, ${rig.inFlightCollects} in-flight collects, '
          '${rig.listingDrains} listing drains, ${rig.mailboxReads} mailbox reads (main: 80 / 0 / 80 / 400)');
      expect(rig.inFlightCollects, 0);
      expect(rig.check.inFlightChecks, 0);
      expect(rig.fullCollects, rig.check.fullChecks);
      expect(rig.listingDrains, rig.fullCollects);
      expect(rig.fullCollects, lessThanOrEqualTo(14));
      expect([for (final c in rig.calls.take(5)) c.at.inSeconds], [45, 135, 315, 615, 915]);
      // The steps are 45, 90, 180, then 300 s again and again.
      final gaps = [
        for (var i = 1; i < rig.calls.length; i++) (rig.calls[i].at - rig.calls[i - 1].at).inSeconds,
      ];
      expect(gaps.take(3), [90, 180, 300]);
      expect(gaps.skip(2).every((g) => g == 300), isTrue);
    });
  });

  test('delivery bounds with nothing in flight: at most 300 s, from the first wait on', () {
    fakeAsync((time) {
      final rig = _Rig(time);
      rig.check.start();
      time.elapse(_hour);
      rig.check.stop();
      for (final c in _Rig.contacts) {
        expect(rig.longestWait(c, _hour - const Duration(minutes: 6)), lessThanOrEqualTo(const Duration(seconds: 300)));
      }
    });
  });

  test('one contact in flight: it is read every 45 s on its own, the others back off', () {
    fakeAsync((time) {
      final rig = _Rig(time, inFlight: ['c3']);
      rig.check.start();
      time.elapse(_hour);
      rig.check.stop();

      // ignore: avoid_print
      print('idle hour, c3 in flight: ${rig.fullCollects} full collects, ${rig.inFlightCollects} in-flight '
          'collects, ${rig.listingDrains} listing drains, ${rig.mailboxReads} mailbox reads');
      expect(rig.inFlightCollects, greaterThan(60));
      expect([for (final c in rig.calls) if (c.only != null) c.only], everyElement(['c3']));
      expect(rig.listingDrains, rig.fullCollects);
      expect(rig.fullCollects, lessThanOrEqualTo(14));
      // The contact in flight: within 45 s. The others: within 300 s.
      expect(rig.longestWait('c3', _hour - const Duration(minutes: 1)), lessThanOrEqualTo(const Duration(seconds: 45)));
      expect(rig.longestWait('c1', _hour - const Duration(minutes: 6)), lessThanOrEqualTo(const Duration(seconds: 300)));
    });
  });

  test('a contact that goes in flight is read within 45 s, from a long wait', () {
    fakeAsync((time) {
      final rig = _Rig(time);
      rig.check.start();
      time.elapse(const Duration(minutes: 20));
      final before = rig.calls.length;
      rig.inFlight = ['c2'];
      final at = time.elapsed;
      rig.check.inFlightChanged();
      time.elapse(_inFlightEvery);
      // A full check reads c2 too.
      final read = rig.calls.skip(before).where((c) => c.only?.contains('c2') ?? true);
      expect(read, isNotEmpty);
      expect(read.first.at - at, lessThanOrEqualTo(_inFlightEvery));
      rig.check.stop();
    });
  });

  test('a boost ticks a full collect at its interval, and the wait starts again after it', () {
    fakeAsync((time) {
      final rig = _Rig(time);
      rig.check.start();
      time.elapse(const Duration(minutes: 20));
      final before = rig.calls.length;
      final at = time.elapsed;
      const every = Duration(seconds: 10);
      final id = rig.boosts.boost(Poller.relays, const Duration(minutes: 2), every);
      time.elapse(const Duration(minutes: 2));
      final during = rig.calls.skip(before).toList();
      expect(during.every((c) => c.only == null), isTrue);
      expect(rig.longestWait('c4', at + const Duration(minutes: 2) - every, from: at), lessThanOrEqualTo(every));
      expect(during.length, greaterThanOrEqualTo(10));
      rig.boosts.end(id);
      // After it: the first wait, 45 s, then the steps again.
      final last = rig.calls.last.at;
      time.elapse(const Duration(minutes: 3));
      final after = rig.calls.where((c) => c.at > last).map((c) => c.at - last).toList();
      expect(after.first, lessThanOrEqualTo(const Duration(seconds: 50)));
      rig.check.stop();
    });
  });

  test('a message, an open and a pairing event each bring the first wait back', () {
    fakeAsync((time) {
      final rig = _Rig(time);
      rig.check.start();
      // Past the backoff: the wait is 300 s.
      time.elapse(const Duration(minutes: 12));
      var last = rig.calls.last.at;
      time.elapse(const Duration(seconds: 301));
      expect((rig.calls.last.at - last).inSeconds, 300);

      // A message in a full check: the next one is 45 s later.
      rig.messages = 1;
      time.elapse(const Duration(seconds: 200));
      last = rig.calls.last.at;
      time.elapse(const Duration(seconds: 46));
      expect((rig.calls.last.at - last).inSeconds, 45);

      // The check settles back to long waits; an open runs a full check now, the next 45 s on.
      time.elapse(const Duration(minutes: 10));
      final openAt = time.elapsed;
      final before = rig.calls.length;
      rig.check.checkAll(PairingCollectTrigger.open);
      time.flushMicrotasks();
      expect(rig.calls.length, before + 1);
      expect(rig.calls.last.trigger, PairingCollectTrigger.open);
      time.elapse(const Duration(seconds: 46));
      expect((rig.calls.last.at - openAt).inSeconds, 45);

      // A pairing event or a payment: reset, the next one 45 s on.
      time.elapse(const Duration(minutes: 10));
      final eventAt = time.elapsed;
      rig.check.reset();
      time.elapse(const Duration(seconds: 46));
      expect((rig.calls.last.at - eventAt).inSeconds, 45);
      rig.check.stop();
    });
  });
}
