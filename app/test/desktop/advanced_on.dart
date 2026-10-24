// Tests of a part that Advanced hides by default (Direct receiving, Outputs, Send options...)
// switch it on first, the way a user does in Settings › Advanced.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Turns every Advanced switch on (the network stays Standard).
Future<void> advancedOn(ProviderContainer c, {Set<AdvancedFeature>? only}) async {
  final s = c.read(deskProvider).settings;
  final prefs = only == null ? AdvancedPrefs.all : AdvancedPrefs(features: only);
  await c.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: prefs));
}
