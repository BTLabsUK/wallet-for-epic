// SPDX-License-Identifier: Apache-2.0
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/trust/policy.dart';
import 'package:epic_wallet/src/trust/profile_watch.dart';

PairingRecord _rec(String id, int profile, {PairingState state = PairingState.paired}) =>
    PairingRecord(id: id, state: state, way: PairingWay.link, inviter: false, createdAt: DateTime(2026), peerProfile: profile);

void main() {
  late DateTime now;
  late PeerProfileWatch watch;
  setUp(() {
    now = DateTime(2026, 11, 6, 10);
    watch = PeerProfileWatch(() => now);
  });

  test('the first sight of a pairing only seeds: startup says nothing', () {
    expect(watch.update([_rec('a', profileNoPayments)]), isEmpty);
    expect(watch.update([_rec('a', profileNoPayments)]), isEmpty);
  });

  test('bit 0 on and off are said, bit 1 is silent', () {
    watch.update([_rec('a', 0)]);
    final on = watch.update([_rec('a', profileNoPayments)]);
    expect(on.map((c) => c.takesPayments), [false]);
    final off = watch.update([_rec('a', 0)]);
    expect(off.map((c) => c.takesPayments), [true]);
    expect(watch.update([_rec('a', profileAutomated)]), isEmpty);
    expect(watch.update([_rec('a', 0)]), isEmpty);
  });

  test('once a day per contact and direction', () {
    watch.update([_rec('a', 0), _rec('b', 0)]);
    expect(watch.update([_rec('a', 1), _rec('b', 1)]), hasLength(2));
    watch.update([_rec('a', 0)]);
    now = now.add(const Duration(hours: 3));
    expect(watch.update([_rec('a', 1)]), isEmpty, reason: 'on was said 3 hours ago');
    now = now.add(const Duration(hours: 22));
    watch.update([_rec('a', 0)]);
    expect(watch.update([_rec('a', 1)]), hasLength(1));
  });

  test('an unpaired or ended pairing is not watched', () {
    watch.update([_rec('a', 0, state: PairingState.waiting)]);
    expect(watch.update([_rec('a', 1, state: PairingState.waiting)]), isEmpty);
    expect(watch.update([_rec('a', 1)]), isEmpty, reason: 'first paired sight seeds');
  });
}
