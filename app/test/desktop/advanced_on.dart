// Tests of a part that Advanced hides by default (Outputs, Send options...) switch it on first,
// the way a user does in Settings › Advanced; Link is Settings › Transactions' switch.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Turns every Advanced switch on (the network stays Standard) and Link in Transactions.
Future<void> advancedOn(ProviderContainer c, {Set<AdvancedFeature>? only}) async {
  final s = c.read(deskProvider).settings;
  // The experimental switches stay as they are (on in the tests that turned them on).
  final prefs = only == null ? AdvancedPrefs.all : AdvancedPrefs(features: {...only, ...s.advanced.features.intersection(experimentalFeatures)});
  await c.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: prefs, payments: s.payments.copyWith(linkHttp: true, linkTor: true)));
}
