// SPDX-License-Identifier: Apache-2.0
// Designer-frame visits: Start, PIN, restore, In person, file. Add `('fr-<Frame>', _Start.<from>,
// visit)` entries to the list (a frame before the wallet opens uses `_Start.firstRun` or
// `_Start.unlock`) and, when a frame needs its own data, a seed to `_startSeeds`. See
// tool/tour/FRAMES.md.
part of '../screenshot_tour_test.dart';

final List<(String, _Start, _Visit)> _framesStart = [
  ('fr-Start-1-Welcome', _Start.firstRun, (t) => t.shot('fr-Start-1-Welcome')),
  (
    'fr-Start-2-Pin',
    _Start.firstRun,
    (t) async {
      await t.tapText(t.l.firstRunCreate);
      await t.typeOnPad('11');
      await t.shot('fr-Start-2-Pin');
    },
  ),
  (
    'fr-Start-3-Biometrics',
    _Start.firstRun,
    (t) async {
      await t.tapText(t.l.firstRunCreate);
      await t.enter(t.l.pinLabel, _pin);
      await t.enter(t.l.pinRepeatLabel, _pin);
      await t.shot('fr-Start-3-Biometrics');
    },
  ),
  ('fr-Start-4-Unlock', _Start.unlock, (t) => t.shot('fr-Start-4-Unlock')),
  (
    'fr-Start-6-Restore',
    _Start.firstRun,
    (t) async {
      await t.tapText(t.l.firstRunRestore);
      await t.enter(t.l.restorePhraseLabel, 'abandon account address advance aerobic balance because bicycle capital');
      await t.shot('fr-Start-6-Restore');
    },
  ),
  (
    'fr-Gap-6-Pin-Wrong',
    _Start.unlock,
    (t) async {
      await t.typeOnPad('111111');
      await t.shot('fr-Gap-6-Pin-Wrong');
    },
  ),
  (
    'fr-Gap-7-Pin-Wait',
    _Start.unlock,
    (t) async {
      for (var i = 0; i < 5; i++) {
        await t.typeOnPad('111111');
      }
      await t.elapse(1000);
      await t.shot('fr-Gap-7-Pin-Wait');
    },
  ),
  (
    'fr-Gap-8-Pin-Forgot',
    _Start.unlock,
    (t) async {
      await t.tapText(t.l.pinForgot);
      await t.tapText(t.l.pinResetConfirm);
      await t.shot('fr-Gap-8-Pin-Forgot');
    },
  ),
  (
    'fr-Gap-9-Restore-Scan',
    _Start.firstRun,
    (t) async {
      await t.tapText(t.l.firstRunRestore);
      await t.enter(t.l.restorePhraseLabel, t.service.phrase);
      await t.tapText(t.l.commonContinue);
      await t.enter(t.l.pinLabel, _pin);
      await t.enter(t.l.pinRepeatLabel, _pin);
      await t.elapse(6000);
      await t.tapText(t.l.pinBiometricsNotNow);
      await t.elapse(500);
      await t.shot('fr-Gap-9-Restore-Scan');
    },
  ),
  (
    'fr-Gap-10-Restore-Done',
    _Start.firstRun,
    (t) async {
      await t.tapText(t.l.firstRunRestore);
      await t.enter(t.l.restorePhraseLabel, t.service.phrase);
      await t.tapText(t.l.commonContinue);
      await t.enter(t.l.pinLabel, _pin);
      await t.enter(t.l.pinRepeatLabel, _pin);
      await t.elapse(6000);
      await t.tapText(t.l.pinBiometricsNotNow);
      await t.elapse(3000);
      await t.shot('fr-Gap-10-Restore-Done');
    },
  ),
];

/// Per-frame data on top of the base wallet (frame_data.dart), by visit name.
final Map<String, void Function(FakeWalletSession s)> _startSeeds = {
  // The restore's scan, held at 42%.
  'fr-Gap-9-Restore-Scan': (s) => s.scanStream = () async* {
    yield const ScanProgress(percent: 42, message: 'Scanning', finished: false);
    await Completer<void>().future;
  }(),
};
