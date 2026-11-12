// SPDX-License-Identifier: Apache-2.0
// Designer-frame visits: Start, PIN, restore, In person, file. Add `('fr-<Frame>', _Start.<from>,
// visit)` entries to the list (a frame before the wallet opens uses `_Start.firstRun` or
// `_Start.unlock`) and, when a frame needs its own data, a seed to `_startSeeds`. See
// tool/tour/FRAMES.md.
part of '../screenshot_tour_test.dart';

final List<(String, _Start, _Visit)> _framesStart = [];

/// Per-frame data on top of the base wallet (frame_data.dart), by visit name.
final Map<String, void Function(FakeWalletSession s)> _startSeeds = {};
