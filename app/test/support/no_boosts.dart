// SPDX-License-Identifier: Apache-2.0
import 'package:lepic/lepic.dart' as lepic;

/// LEPIC's boost calls for a fake `lepic.EpicWallet` whose other calls throw: no boost runs,
/// so each loop keeps its base interval.
mixin NoBoosts {
  BigInt boost({required lepic.Poller poller, required int durationSecs, required int intervalSecs}) =>
      BigInt.one;

  bool endBoost({required BigInt id}) => false;

  int pollInterval({required lepic.Poller poller, required int baseSecs}) => baseSecs;
}
