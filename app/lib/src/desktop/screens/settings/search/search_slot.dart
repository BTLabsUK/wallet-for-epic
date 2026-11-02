// SPDX-License-Identifier: Apache-2.0
/// Settings search: the field in the Settings column, the query, the keys (/ and Ctrl+K focus
/// it, Esc clears it, then leaves Settings) and the results that replace the page while the
/// query is not empty.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/kit.dart';

/// What the search field holds; not empty means Settings shows [SettingsSearchResults].
final settingsQueryProvider = NotifierProvider<SettingsQuery, String>(SettingsQuery.new);

class SettingsQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String q) => state = q;

  void clear() => state = '';
}

/// Bumped to focus and select the search field (Ctrl+K, /).
final settingsSearchFocusProvider = NotifierProvider<SettingsSearchFocus, int>(SettingsSearchFocus.new);

class SettingsSearchFocus extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

/// Ctrl+K from anywhere: Settings opens (Wallet when it is not open) with the search focused.
void openSettingsSearch(WidgetRef ref) {
  final nav = ref.read(deskNavProvider);
  if (nav.route.section != DeskSection.settings) ref.read(deskNavProvider.notifier).go(DeskRoute.settingsAccount);
  ref.read(settingsSearchFocusProvider.notifier).request();
}

/// The sections with results while searching (navigation entries outside it are dimmed and
/// read "No results"); null while not searching.
final settingsSearchRoutesProvider = Provider<Set<DeskRoute>?>((ref) => null);

/// The search field, under the Settings title in the Settings column.
class SettingsSearchSlot extends ConsumerStatefulWidget {
  const SettingsSearchSlot({super.key});

  @override
  ConsumerState<SettingsSearchSlot> createState() => _SettingsSearchSlotState();
}

class _SettingsSearchSlotState extends ConsumerState<SettingsSearchSlot> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// The results, in place of the page while the query is not empty.
class SettingsSearchResults extends ConsumerWidget {
  const SettingsSearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}

/// Around the whole Settings takeover (column and page): / and Ctrl+K focus and select the
/// search; Esc clears it, and with nothing to clear calls [onLeave] (back to the wallet).
class SettingsSearchKeys extends ConsumerWidget {
  const SettingsSearchKeys({super.key, required this.onLeave, required this.child});

  final VoidCallback onLeave;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => child;
}
