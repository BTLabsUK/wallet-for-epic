// Pairing and Invoices are experimental switches (Settings › Advanced), off by default: the
// tests of those parts turn them on first.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The phone's stored Advanced value with Pairing and Invoices on (`app.advanced_prefs`).
const phoneExperimentalOn = 'invoices,pairing|standard';

/// The phone's store key for it.
const phoneAdvancedPrefsKey = 'app.advanced_prefs';

/// Turns Pairing and Invoices on in the desktop's settings.
Future<void> deskExperimentalOn(ProviderContainer c) {
  final s = c.read(deskProvider).settings;
  return c
      .read(deskProvider.notifier)
      .saveSettings(s.copyWith(advanced: s.advanced.withExperimental(AdvancedFeature.invoices, true)));
}
