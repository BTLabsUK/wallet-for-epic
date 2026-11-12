// SPDX-License-Identifier: Apache-2.0
// Designer-frame visits: Receive (Receive-*, Gap-1-Request, InPerson-*, Gap-3-InPerson-Done, File-1-Made,
// Gap-4-File-Open, Gap-5-File-Reply). See tool/tour/FRAMES.md.
part of '../screenshot_tour_test.dart';

/// The frames' own address: `esVeVU…3es6TA@epicbox.epiccash.com`.
final String _fMe = 'esVeVUhWwJT4HcFNwCw8wxqauG3SoQ3aKABLyaXWq6HUZ83es6TA@$mockBox';

/// Receive's own screen (the arriving sheet closed), on the frames' address.
/// Frames drawn for a classic wallet (the address, not the epic1 link); the rest of the tour's frames are epic1.
final Set<String> _frameClassic = {'fr-Receive-1', 'fr-Receive-2-Ask', 'fr-Receive-4-Other'};

Future<void> _frameReceive(_Tour t) async {
  await t.openReceive();
}

final List<(String, _Start, _Visit)> _framesReceive = [
  ('fr-Receive-1', _Start.home, (t) async {
    await _frameReceive(t);
    await t.shot('fr-Receive-1');
  }),
  ('fr-Receive-2-Ask', _Start.home, (t) async {
    await _frameReceive(t);
    await t.tapText(t.l.phoneRecvAsk);
    for (final c in '25'.split('')) {
      await t.tap(find.descendant(of: find.byType(KitKeypad), matching: find.text(c)));
    }
    await t.shot('fr-Receive-2-Ask');
  }),
  ('fr-Receive-4-Other', _Start.home, (t) async {
    await _directWaysOn(t);
    await _frameReceive(t);
    await t.tapText(t.l.phoneRecvOther);
    await t.shot('fr-Receive-4-Other');
  }),
];

/// Per-frame data on top of the base wallet (frame_data.dart), by visit name.
final Map<String, void Function(FakeWalletSession s)> _receiveSeeds = {
  for (final name in ['fr-Receive-1', 'fr-Receive-2-Ask', 'fr-Receive-4-Other'])
    name: (s) => s.address = _fMe,
};
