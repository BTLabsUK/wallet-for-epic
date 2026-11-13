// SPDX-License-Identifier: Apache-2.0
// Boosts (boosts.dart): a driver ticks at its base, faster while a boost of its poller runs,
// back at the base when the boost ends or runs out, and backs off after failures up to the base.
import 'package:epic_wallet/src/boosts.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

const _base = Duration(seconds: 45);
const _s = Duration(seconds: 1);

void main() {
  test('a boost speeds its poller up until it ends, and the base comes back', () {
    fakeAsync((time) {
      final boosts = MemoryBoosts();
      var ticks = 0;
      final driver = PollDriver(boosts, Poller.relays, base: _base, tick: () async {
        ticks++;
        return true;
      })..start();
      time.elapse(_base);
      expect(ticks, 1);

      // Shorter than the wait set: the timer is set again from now.
      final id = boosts.boost(Poller.relays, const Duration(minutes: 10), _s);
      expect(driver.wait, boostMinInterval);
      time.elapse(boostMinInterval * 3);
      expect(ticks, 4);

      // A boost of the other poller changes nothing here.
      boosts.boost(Poller.node, const Duration(minutes: 1), boostMinInterval);
      expect(driver.wait, boostMinInterval);

      boosts.end(id);
      expect(driver.wait, _base);
      time.elapse(boostMinInterval + _base);
      expect(ticks, 6);
      driver.stop();
      time.elapse(_base * 2);
      expect(ticks, 6);
    });
  });

  test('a boost runs out after its window, at most 10 min', () {
    fakeAsync((time) {
      final boosts = MemoryBoosts();
      boosts.boost(Poller.node, const Duration(hours: 1), const Duration(seconds: 10));
      expect(boosts.interval(Poller.node, _base), const Duration(seconds: 10));
      boosts.boost(Poller.node, const Duration(minutes: 2), boostMinInterval);
      expect(boosts.interval(Poller.node, _base), boostMinInterval);
      time.elapse(const Duration(minutes: 2));
      expect(boosts.interval(Poller.node, _base), const Duration(seconds: 10));
      time.elapse(boostMaxWindow);
      expect(boosts.interval(Poller.node, _base), _base);
    });
  });

  test('failed ticks double the wait, never past the base', () {
    fakeAsync((time) {
      final boosts = MemoryBoosts()..boost(Poller.node, boostMaxWindow, boostMinInterval);
      var ok = false;
      final driver = PollDriver(boosts, Poller.node, base: const Duration(seconds: 15), tick: () async => ok)..start();
      time.elapse(boostMinInterval);
      expect(driver.failures, 1);
      expect(driver.wait, const Duration(seconds: 10));
      time.elapse(const Duration(seconds: 10));
      expect(driver.wait, const Duration(seconds: 15));
      ok = true;
      time.elapse(const Duration(seconds: 15));
      expect(driver.failures, 0);
      expect(driver.wait, boostMinInterval);
      driver.stop();
    });
  });
}
