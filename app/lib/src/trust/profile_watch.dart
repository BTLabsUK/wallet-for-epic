// SPDX-License-Identifier: Apache-2.0
/// Tells when a paired contact starts or stops taking payments (bit 0 of its card profile,
/// docs/design/peer-profile.md 5.3). Phone and desktop both feed it the pairings.
library;

import '../models.dart';
import 'policy.dart';

/// One change to say: [record] takes payments again ([takesPayments]) or no longer does.
typedef ProfileChange = ({PairingRecord record, bool takesPayments});

class PeerProfileWatch {
  PeerProfileWatch(this._now);

  final DateTime Function() _now;

  /// The last profile seen per paired pairing; kept in memory only.
  final Map<String, int> _seen = {};

  /// When each direction (`id:on`, `id:off`) was last said.
  final Map<String, DateTime> _said = {};

  static const Duration _every = Duration(days: 1);

  /// The changes in [records] since the last call, at most one per contact and direction a day.
  /// A pairing seen for the first time (startup, a new pairing) is only remembered; bit 1
  /// (automated) changes silently.
  List<ProfileChange> update(Iterable<PairingRecord> records) {
    final changes = <ProfileChange>[];
    final live = <String>{};
    for (final r in records) {
      if (r.ended || !(r.state == PairingState.paired || r.state == PairingState.verified)) continue;
      live.add(r.id);
      final before = _seen[r.id];
      _seen[r.id] = r.peerProfile;
      if (before == null) continue;
      final was = statedNoPayments(before), is_ = statedNoPayments(r.peerProfile);
      if (was == is_) continue;
      final key = '${r.id}:${is_ ? 'off' : 'on'}';
      final at = _now();
      final last = _said[key];
      if (last != null && at.difference(last) < _every) continue;
      _said[key] = at;
      changes.add((record: r, takesPayments: !is_));
    }
    _seen.removeWhere((id, _) => !live.contains(id));
    return changes;
  }
}
