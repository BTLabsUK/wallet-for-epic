// SPDX-License-Identifier: Apache-2.0
/// Whether the first-run tour is still due, settled once at launch, before this run writes
/// anything. Platform-neutral: the phone (`main.dart`) passes `app.phone_tour_seen`, the desktop
/// (`main_desktop.dart`) the `tourSeen` of its settings.
///
/// The seen flag is written only when the tour opens, so a missing flag alone does not mean a
/// fresh install: an install from before the tour, or one where it never got to open (Level 1,
/// the user left Home first, a dialog over it), would get it on a later launch, an update's
/// included. Here an install that already holds any of the [markers] keys, or whose [hasData]
/// says so, ran before: its flag is saved as seen and the tour never opens by itself (Help still
/// offers it). A fresh install keeps it due for its first run only: by the next launch its own
/// keys are markers.
library;

import 'levels/wallet_level.dart' show existingInstallMarkers, levelKey;
import 'log.dart';
import 'secret_store_api.dart';
import 'settings.dart' show AppSettingsNotifier;

/// The phone's markers: the keys an earlier run leaves ([existingInstallMarkers], and the level
/// every launch settles).
const List<String> phoneTourMarkers = [...existingInstallMarkers, levelKey];

/// Saves the tour as seen when this install ran before. Returns whether the tour is still due.
/// A store that can't be read leaves everything as it is.
Future<bool> settleFirstRunTour({
  required Future<String?> Function(String key) read,
  required Future<bool> Function() seen,
  required Future<void> Function() markSeen,
  required List<String> markers,
  Future<bool> Function()? hasData,
}) async {
  try {
    if (await seen()) return false;
    var existing = false;
    for (final k in markers) {
      if (await read(k) != null) {
        existing = true;
        break;
      }
    }
    if (!existing && hasData != null) existing = await hasData();
    if (!existing) return true;
    await markSeen();
    logInfo('tour', 'existing install: tour saved as seen');
    return false;
  } on Object catch (e) {
    logWarn('tour', 'first-run tour not settled: ${e.runtimeType}');
    return false;
  }
}

/// The phone's launch step: [AppSettingsNotifier.phoneTourSeenKey] saved as `true` when this
/// install ran before.
Future<bool> settlePhoneFirstRunTour(SecretStore store) => settleFirstRunTour(
  read: store.read,
  seen: () async => await store.read(AppSettingsNotifier.phoneTourSeenKey) == 'true',
  markSeen: () => store.write(AppSettingsNotifier.phoneTourSeenKey, 'true'),
  markers: phoneTourMarkers,
);
