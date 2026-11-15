// SPDX-License-Identifier: Apache-2.0
/// The phone's network-mode widgets: the Network section of Settings › Network & privacy (four radio rows,
/// each with the line on what the mode does), the switch confirmation, and the mode's
/// line in the connections sheet. Text and glyphs: `network_mode_text.dart`; the rules:
/// `network_gate.dart`.
library;

import '../trust_ids.dart';
import 'phone_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../advanced.dart';
import '../l10n.dart';
import '../models.dart';
import '../phone_tor.dart';
import '../providers.dart';
import '../settings.dart';
import 'network_mode_text.dart';
import 'kit/kit_group.dart';
import 'kit/kit_row.dart';
import 'kit/kit_tokens.dart';
import 'settings_sections.dart' show SettingsSection, openSettingsSection;
import 'tor_ui.dart' show torShown;
import 'theme/tokens.dart';

/// The key of a mode's row in the Network section: `adv-mode-<name>`.
Key networkModeRowKey(NetworkMode m) => ValueKey('adv-mode-${m.name}');


/// The key of the Network section's header, for scrolling to it and for tests.
const Key networkSectionKey = ValueKey('adv-network');


/// The key of the network mode's line in the connections sheet.
const Key networkModeMarkKey = ValueKey('net-mode-mark');

/// The key of that line's Change link.
const Key networkModeChangeKey = ValueKey('net-mode-change');

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
    final ok = await showPhoneSheet<bool>(
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

/// The stable test id for the modes (`TrustIds`, lib/src/trust_ids.dart).
const _modeId = {NetworkMode.standard: TrustIds.privacyModeStandard, NetworkMode.torOnly: TrustIds.privacyModeToronly};

/// The Connection mode block of Settings › Network & privacy: its label and one radio row per
/// offered mode, each with the one line on what it does. Tor only is left out of the build
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
    // A change is being applied (tor coming up or going down for it): the choices wait, the
    // chosen one turns, so a tap in a row cannot leave services half started.
    final changing = ref.watch(phoneTorProvider.select((s) => s.changing));
    Widget row(NetworkMode m) {
      final enabled = m != NetworkMode.torOnly || torAvailable;
      return KitRow.radio(
        key: networkModeRowKey(m),
        semanticsId: _modeId[m],
        title: networkModeName(l, m),
        subtitle: switch (m) {
          NetworkMode.standard => l.phoneSettingsModeNormalLine,
          NetworkMode.torOnly => l.phoneSettingsModeTorLine,
          NetworkMode.nodeOnly => l.phoneSettingsModeNodeLine,
          NetworkMode.killSwitch => l.phoneSettingsModeKillLine,
        },
        subtitleLines: 3,
        size: KitRowSize.list,
        selected: mode == m,
        busy: changing,
        onChanged: enabled && !changing ? () => chooseNetworkMode(context, ref, m) : null,
      );
    }
    final rows = KitGroup(
      dividerInset: Kit.dividerInsetPlain,
      children: [for (final m in offeredNetworkModes()) row(m)],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: networkSectionKey,
          child: KeyedSubtree(key: headerKey, child: KitGroupLabel(l.netModesGroup)),
        ),
        tourId == null ? rows : tourId!(rows),
      ],
    );
  }
}

/// Opens Settings › Network & privacy at the Network section.
Future<void> openNetworkSection(BuildContext context) =>
    openSettingsSection(context, SettingsSection.privacyNetwork, toNetwork: true);

/// The network mode's line in the connections sheet, off Normal only: the mode's glyph and
/// "Network mode: {name}" in the dim small type, and a Change link that closes the sheet and
/// opens the Network section. A mode is a choice, not a service: no tile, no state mark, no
/// row of its own. One sentence on what the mode does is the screen reader's hint.
class NetworkModeLine extends StatelessWidget {
  const NetworkModeLine({super.key = networkModeMarkKey, required this.mode, this.waitingForTor = false});

  final NetworkMode mode;

  /// Tor only while Tor is not yet on: the hint says the wallet waits for it.
  final bool waitingForTor;

  @override
  Widget build(BuildContext context) {
    if (mode == NetworkMode.standard) return const SizedBox.shrink();
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final name = networkModeName(l, mode);
    void change() {
      Navigator.of(context).pop();
      openNetworkSection(context);
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: l.netMarkRowLabel(name),
              hint: networkModeMarkLine(l, mode, waitingForTor: waitingForTor),
              excludeSemantics: true,
              child: Row(
                children: [
                  Icon(networkModeGlyph(mode), size: 16, color: t.dim),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.netMarkRowLabel(name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            key: networkModeChangeKey,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(48, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: theme.textTheme.labelMedium,
            ),
            onPressed: change,
            child: Text(l.netMarkChange),
          ),
        ],
      ),
    );
  }
}
