// SPDX-License-Identifier: Apache-2.0
/// The phone's network-mode widgets: the Network section of Settings › Advanced (four radio rows,
/// each with its ⓘ, the dim line for the chosen mode), the switch confirmation, and the mode
/// mark at the start of Home's status strip. Text and glyphs: `network_mode_text.dart`; the
/// rules: `network_gate.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../advanced.dart';
import '../l10n.dart';
import '../models.dart';
import '../phone_tor.dart';
import '../providers.dart';
import '../settings.dart';
import 'info_hint.dart';
import 'network_mode_text.dart';
import 'settings_sections.dart' show SettingsHeader, SettingsSection, openSettingsSection;
import 'tor_ui.dart' show torShown;
import 'theme/tokens.dart';

/// The key of a mode's row in the Network section: `adv-mode-<name>`.
Key networkModeRowKey(NetworkMode m) => ValueKey('adv-mode-${m.name}');

/// The key of a mode's ⓘ in the Network section.
Key networkModeHintKey(NetworkMode m) => ValueKey('adv-mode-hint-${m.name}');

/// The key of the Network section's header, for scrolling to it and for tests.
const Key networkSectionKey = ValueKey('adv-network');


/// The key of the mode mark on Home.
const Key networkModeMarkKey = ValueKey('net-mode-mark');

/// The key of the switch confirmation sheet.
const Key networkModeConfirmKey = ValueKey('net-mode-confirm');

/// Sends that wait for their recipient over Epicbox or Link: Node only and Kill switch stop
/// the listeners they wait on, so they pause until the mode is left.
int pendingNetworkSends(Iterable<TxEntry>? txs) =>
    txs
        ?.where(
          (x) =>
              x.kind == TxKind.sent &&
              x.status == TxStatus.awaitingRecipient &&
              (x.transport == 'epicbox' || x.transport == 'http' || x.transport == 'tor'),
        )
        .length ??
    0;

/// Switches to [target]. Takes effect at once; the one confirmation is when a send waits for
/// its recipient over Epicbox or Link and [target] stops their listeners. Returns whether the
/// mode was switched.
Future<bool> chooseNetworkMode(BuildContext context, WidgetRef ref, NetworkMode target) async {
  final current = ref.read(networkModeProvider);
  if (target == current) return false;
  final waiting = switchPausesSends(target) && !switchPausesSends(current)
      ? pendingNetworkSends(ref.read(homeProvider).value?.transactions)
      : 0;
  if (waiting > 0) {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => NetworkModeConfirmSheet(mode: target, waiting: waiting),
    );
    if (ok != true) return false;
  }
  await ref.read(appSettingsProvider.notifier).setNetworkMode(target);
  return true;
}

/// "Switch to {mode}?": how many payments pause, that nothing is cancelled, Cancel / Switch.
class NetworkModeConfirmSheet extends StatelessWidget {
  const NetworkModeConfirmSheet({super.key, required this.mode, required this.waiting});

  final NetworkMode mode;
  final int waiting;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final name = networkModeName(l, mode);
    return Padding(
      key: networkModeConfirmKey,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(networkModeGlyph(mode), size: 22, color: t.dim),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(header: true, child: Text(l.advModeConfirmTitle(name), style: theme.textTheme.titleMedium)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(l.advModeConfirmBody(waiting, name), style: theme.textTheme.bodyMedium?.copyWith(color: t.dim, height: 1.5)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
              const SizedBox(width: 8),
              FilledButton(key: const ValueKey('net-mode-confirm-switch'), onPressed: () => Navigator.pop(context, true), child: Text(l.advModeConfirmSwitch)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The Network section of Settings › Advanced: its header and one radio row per offered mode,
/// just the name and its ⓘ (the explanation lives in the sheet, none in the list; the owner: "no
/// explanations in main view"), as tall as the other rows. Tor only is left out of the build
/// without Tor and disabled while Tor is unavailable on the phone.
class NetworkModeSection extends ConsumerWidget {
  const NetworkModeSection({super.key, this.headerKey, this.tourId});

  final Key? headerKey;
  final Widget Function(Widget child)? tourId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final mode = ref.watch(networkModeProvider);
    final torAvailable = ref.watch(phoneTorProvider.select(torShown));
    Widget row(NetworkMode m) {
      final enabled = m != NetworkMode.torOnly || torAvailable;
      final name = networkModeName(l, m);
      return ListTile(
        key: networkModeRowKey(m),
        enabled: enabled,
        leading: Radio<NetworkMode>(value: m, enabled: enabled),
        title: TitleWithHint(
          name,
          hintKey: networkModeHintKey(m),
          hint: networkModeHint(l, m),
          icon: networkModeGlyph(m),
          labelled: enabled,
        ),
        onTap: enabled ? () => chooseNetworkMode(context, ref, m) : null,
      );
    }
    final rows = RadioGroup<NetworkMode>(
      groupValue: mode,
      onChanged: (v) {
        if (v != null) chooseNetworkMode(context, ref, v);
      },
      child: Column(children: [for (final m in offeredNetworkModes()) row(m)]),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(key: networkSectionKey, child: SettingsHeader(l.advNetworkHeader, key: headerKey)),
        tourId == null ? rows : tourId!(rows),
      ],
    );
  }
}

/// Opens Settings › Advanced scrolled to the Network section.
Future<void> openNetworkSection(BuildContext context) =>
    openSettingsSection(context, SettingsSection.advanced, toNetwork: true);

/// The mode mark: a small neutral pill (the mode's glyph and name, no state dot: a mode is a
/// choice, not a service) at the start of Home's status strip, shown only off Normal. A tap
/// opens the Network section. 24 dp high inside a 44 dp target.
class NetworkModeMark extends ConsumerWidget {
  const NetworkModeMark({super.key = networkModeMarkKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(networkModeProvider);
    if (mode == NetworkMode.standard) return const SizedBox.shrink();
    final l = context.l10n;
    final t = context.tokens;
    final name = networkModeName(l, mode);
    void open() => openNetworkSection(context);
    return Semantics(
      container: true,
      button: true,
      label: l.netMarkSemantics(name),
      excludeSemantics: true,
      onTap: open,
      child: InkResponse(
        onTap: open,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Center(
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: t.surfaceHi,
                border: Border.all(color: t.lineStrong),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(networkModeGlyph(mode), size: 14, color: t.dim),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: t.dim),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
