// SPDX-License-Identifier: Apache-2.0
// Designer-frame visits: Receive (Receive-*). Add `('fr-<Frame>', _Start.home, visit)` entries to
// the list and, when a frame needs its own data, a seed to `_receiveSeeds`. See tool/tour/FRAMES.md.
part of '../screenshot_tour_test.dart';

final List<(String, _Start, _Visit)> _framesReceive = [];

/// Per-frame data on top of the base wallet (frame_data.dart), by visit name.
final Map<String, void Function(FakeWalletSession s)> _receiveSeeds = {};
