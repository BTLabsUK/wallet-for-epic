// SPDX-License-Identifier: Apache-2.0
/// The relay collect, checked more often while a screen or a wait needs an answer.
library;

import 'boosts.dart';

/// Boosts [Poller.relays] to [every] for [window] and returns the call that ends it, for the
/// screen or wait to make on close. Does nothing while [boosts] is null (no open wallet).
void Function() boostRelays(Boosts? boosts, Duration every, {Duration window = boostMaxWindow}) {
  if (boosts == null) return () {};
  final id = boosts.boost(Poller.relays, window, every);
  return () => boosts.end(id);
}
