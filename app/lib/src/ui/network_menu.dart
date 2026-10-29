// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'status_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo.dart' show devNetworksProvider;
import '../l10n.dart';
import '../network.dart';
import '../providers.dart';
import '../settings_file/settings_providers.dart' show DevSettingsMissing;
import 'notices.dart';
import '../wallet_service.dart' show Chain;
import 'server_picker.dart';

/// The keys of the menu's items, for tests.
const Key networkMenuNodeKey = ValueKey('network-menu-node');
const Key networkMenuEpicboxKey = ValueKey('network-menu-epicbox');
const Key networkMenuNetworkKey = ValueKey('network-menu-network');

/// The small menu behind the app bar's network button on first run and unlock (no wallet is
/// open there): Node and Epicbox open the same picker sheets as the status icons on Home, and
/// development builds add Network. With no wallet open the sheets save the choice and start
/// the app again on it.
Future<void> showNetworkMenu(BuildContext context) async {
  final choice = await showModalBottomSheet<_Entry>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => const _NetworkMenu(),
  );
  if (choice == null || !context.mounted) return;
  switch (choice) {
    case _Entry.node:
      await showNodePicker(context);
    case _Entry.epicbox:
      await showEpicboxPicker(context);
    case _Entry.network:
      await showNetworkChooser(context);
  }
}

enum _Entry { node, epicbox, network }

class _NetworkMenu extends ConsumerWidget {
  const _NetworkMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final devNetworks = ref.watch(devNetworksProvider);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: networkMenuNodeKey,
            leading: const Icon(EpicGlyphs.node),
            title: Text(l.serverNodeTitle),
            onTap: () => Navigator.of(context).pop(_Entry.node),
          ),
          ListTile(
            key: networkMenuEpicboxKey,
            leading: const Icon(EpicGlyphs.epicbox),
            title: Text(l.serverEpicboxTitle),
            onTap: () => Navigator.of(context).pop(_Entry.epicbox),
          ),
          if (devNetworks)
            ListTile(
              key: networkMenuNetworkKey,
              leading: const Icon(Icons.hub),
              title: Text(l.setupNetworkHeading),
              onTap: () => Navigator.of(context).pop(_Entry.network),
            ),
        ],
      ),
    );
  }
}

/// The key of a network's row in the chooser, for tests: `network-<chain>`.
Key networkChoiceKey(NetworkPreset preset) =>
    ValueKey('network-${preset.chain.name}');

/// Development builds and the web demo only (devNetworksProvider): pick the network. Each
/// network has its own wallet and settings file (node and relay), so another network opens its
/// own file and the app starts again on it (an open wallet is locked by that start).
Future<void> showNetworkChooser(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _NetworkChooser(outer: context),
    );

class _NetworkChooser extends ConsumerStatefulWidget {
  const _NetworkChooser({required this.outer});

  /// The screen under the sheet, for the restart (the sheet closes first).
  final BuildContext outer;

  @override
  ConsumerState<_NetworkChooser> createState() => _NetworkChooserState();
}

class _NetworkChooserState extends ConsumerState<_NetworkChooser> {
  bool _busy = false;

  Future<void> _choose(NetworkPreset preset) async {
    final notifier = ref.read(networkChoiceProvider.notifier);
    final outer = widget.outer;
    setState(() => _busy = true);
    try {
      // The chain's own settings file: its node and Epicbox server.
      await notifier.switchChain(preset.chain);
    } on DevSettingsMissing catch (e) {
      // A dev build only: the message names the file and the script that copies it.
      ref.read(noticeProvider.notifier).show('$e', level: NoticeLevel.error);
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    if (outer.mounted) relaunchAfterSwitch(outer);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final current = ref.watch(networkChoiceProvider).value?.preset;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l.setupNetworkHeading,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(l.setupWalletPerNetwork),
            const SizedBox(height: 8),
            for (final p in networkPresets)
              // Usernet is a local test network for developers.
              if (p.chain != Chain.usernet || !kReleaseMode || p == current)
                ListTile(
                  key: networkChoiceKey(p),
                  contentPadding: EdgeInsets.zero,
                  title: Text(chainName(l, p.chain)),
                  subtitle: Text(chainDescription(l, p.chain)),
                  trailing: p == current ? const Icon(Icons.check) : null,
                  selected: p == current,
                  enabled: !_busy,
                  onTap: p == current ? null : () => _choose(p),
                ),
          ],
        ),
      ),
    );
  }
}
