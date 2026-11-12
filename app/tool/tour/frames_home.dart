// SPDX-License-Identifier: Apache-2.0
// Designer-frame visits: Home, Home-busy, Contacts, Contact-Tom (the tab bar is in all of them).
part of '../screenshot_tour_test.dart';

final List<(String, _Start, _Visit)> _framesHome = [
  ('fr-Home', _Start.home, (t) => t.shot('fr-Home')),
];

/// Per-frame data on top of the base wallet (frame_data.dart), by visit name.
final Map<String, void Function(FakeWalletSession s)> _homeSeeds = {};
