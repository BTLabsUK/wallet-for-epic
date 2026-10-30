// SPDX-License-Identifier: Apache-2.0
/// Home's status icons, in Wallet's fiat row: the node and Epicbox always, Tor while its
/// switch is on, Direct receive while the onion listener is up. Each is one [StatusIcon]: a
/// glyph with a state dot, the service and its state word for a screen reader, the detail in
/// a tooltip on a long press, and a tap that opens the service's screen. Every status read goes
/// through [watchWalletStatus] and [phoneTorProvider]; nothing here debounces or decides a route.
library;

import 'package:flutter/material.dart';
import 'status_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../network_gate.dart';
import '../node_failover_phone.dart';
import '../phone_tor.dart';
import '../providers.dart';
import '../tor_phone.dart';
import '../tor_routes.dart';
import 'network_status.dart' show nodeBehind, nodeTorWay;
import 'net_block.dart' show watchNetBlock;
import 'receive_screen.dart' show ReceiveTab, receiveTabProvider;
import 'server_picker.dart';
import '../payment_prefs.dart' show PaymentPrefs;
import '../phone_http.dart' show PhoneHttpPhase, phoneHttpProvider;
import '../settings.dart' show appSettingsProvider;
import 'settings_screen.dart' show openPrivacySettings;
import 'settings_sections.dart' show SettingsSection, openSettingsSection;
import 'status.dart';
import 'theme/tokens.dart';
import 'tor_ui.dart';

/// The key of the Tor status icon, for tests.
const Key torIconKey = ValueKey('status-tor');

/// The key of the Direct receive status icon, for tests.
const Key directIconKey = ValueKey('status-direct');

/// The keys of the compact row's icons in Send's and Receive's app bar, for tests.
const Key barNodeIconKey = ValueKey('bar-status-node');
const Key barEpicboxIconKey = ValueKey('bar-status-epicbox');
const Key barTorIconKey = ValueKey('bar-status-tor');

/// The Link icon in Send's and Receive's app bar, for tests.
const Key barLinkIconKey = ValueKey('bar-link-icon');
const Key barNetModeKey = ValueKey('bar-status-net-mode');

/// Whether the Tor icon shows: while the switch is on (Starting…, On, Not connected).
bool torIconShown(PhoneTorState s) => phoneTorState(s) != TorState.off;

/// Whether the Direct receive icon shows: the switch is on, the wallet's onion is known and
/// tor is connected, so the listener is published ([PhoneTorPhase.ready]) or being published.
bool directIconShown(PhoneTorState s) =>
    torShown(s) && torIconShown(s) && s.canSend;

/// Tor's dot: green on, blue starting, red not connected.
StatusDot torDot(TorState state) => switch (state) {
  TorState.on => StatusDot.ok,
  TorState.starting => StatusDot.busy,
  TorState.failed => StatusDot.bad,
  TorState.off => StatusDot.off,
};

/// Direct receive's dot and word: reachable (green) once the onion is published, publishing
/// (blue) meanwhile, not reachable (red) when it could not be.
({StatusDot dot, String word}) directFace(AppLocalizations l, PhoneTorState s) {
  if (s.phase == PhoneTorPhase.ready) {
    return (dot: StatusDot.ok, word: l.netStatusReachable);
  }
  if (s.failure != null) {
    return (dot: StatusDot.bad, word: l.netStatusNotReachable);
  }
  return (dot: StatusDot.busy, word: l.netStatusPublishing);
}

/// Link's dot and words for the status icons: off while neither Link method is
/// on; with Link · Tor on, the onion's state ([directFace]); else the HTTP listener's.
({StatusDot dot, String word, String detail}) linkFace(AppLocalizations l, WalletTokens t, PhoneTorState s, PaymentPrefs p, PhoneHttpPhase http, {required bool linkOn}) {
  if (!linkOn) return (dot: StatusDot.off, word: l.netStatusOff, detail: l.netStatusTurnOnHint);
  if (directIconShown(s) || (p.linkTor && torIconShown(s))) {
    final d = directFace(l, s);
    return (dot: d.dot, word: d.word, detail: torStatusOf(l, t, s).text);
  }
  if (p.linkTor && !p.linkHttp) return (dot: StatusDot.bad, word: l.torWordNotConnected, detail: l.torNeeds);
  return switch (http) {
    PhoneHttpPhase.listening => (dot: StatusDot.ok, word: l.netStatusOn, detail: l.netStatusOn),
    PhoneHttpPhase.starting => (dot: StatusDot.busy, word: l.statusNodeConnecting, detail: l.statusNodeConnecting),
    PhoneHttpPhase.off => (dot: StatusDot.off, word: l.netStatusOff, detail: l.netStatusOff),
    _ => (dot: StatusDot.bad, word: l.netStatusNotConnected, detail: l.netStatusNotConnected),
  };
}

/// A service's dot and words once its route under the Tor switch is known: waiting for Tor
/// turns the dot blue (red when Tor is not connected), and "Over Tor" or "Waiting for Tor"
/// joins the label and the tooltip. On the clearnet nothing changes.
({StatusDot dot, String label, String detail}) underTor(
  BuildContext context, {
  required StatusDot dot,
  required String label,
  required String detail,
  required TorWay way,
}) {
  final words = torWayWords(context.l10n, context.tokens, way);
  if (words == null) return (dot: dot, label: label, detail: detail);
  final torDot = switch (way) {
    TorWay.wait => StatusDot.busy,
    TorWay.blocked => StatusDot.bad,
    _ => dot,
  };
  return (
    dot: torDot,
    label: '$label, ${words.word}',
    detail: [detail, words.word, ?words.detail].join('\n'),
  );
}

/// The key of the Offline / Waiting for Tor word that replaces the Node and Epicbox icons, for
/// tests.
const Key netModeStatusKey = ValueKey('status-net-mode');

/// What the network mode says in place of the node and Epicbox icons: "Offline" (neutral) or
/// "Waiting for Tor" (the in-progress blue). The words, not a pulse; a tap opens Advanced.
class NetModeStatus extends StatelessWidget {
  const NetModeStatus(this.block, {super.key});

  final NetBlock block;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final offline = block.byMode;
    final word = offline ? l.advModeOffline : l.torWayWaiting;
    final detail = offline ? l.homeOfflineDetail : l.homeWaitingTorDetail;
    final color = offline ? t.dim : t.info;
    void open() => openSettingsSection(context, SettingsSection.advanced);
    return Semantics(
      container: true,
      button: true,
      label: word,
      hint: [detail, l.netStatusOpenHint].join('\n'),
      liveRegion: true,
      excludeSemantics: true,
      onTap: open,
      child: Tooltip(
        message: detail,
        triggerMode: TooltipTriggerMode.longPress,
        showDuration: const Duration(seconds: 6),
        child: InkWell(
          onTap: open,
          borderRadius: BorderRadius.circular(t.radiusSmall),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: statusTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: statusInset),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    offline ? Icons.cloud_off_outlined : torIcon,
                    size: statusGlyph,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    word,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                    ),
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

/// One status for the icon rows ([StatusIcons]) and the connections sheet
/// ([ConnectionsSheet]): the service's glyph, whether it is on, its dot, the service and its
/// state word for a screen reader ([label]), the detail a long press or the sheet shows, the
/// hint of what a tap does, and the tap itself (the service's screen or switch).
typedef StatusEntry = ({
  Key key,
  IconData icon,
  bool enabled,
  StatusDot dot,
  String label,
  String detail,
  String actionHint,
  bool pulse,
  VoidCallback onTap,
});

/// The statuses in their order, Node, Epicbox, Tor, Link, and the network mode that holds
/// the network back ([block]: Offline, or Tor only without Tor), which stands in for the Node
/// and Epicbox icons while it lasts. [bar] picks the header row's keys over Wallet's.
({NetBlock block, List<StatusEntry> entries}) statusEntries(
  BuildContext context,
  WidgetRef ref, {
  required bool bar,
}) {
  final l = context.l10n;
  final t = context.tokens;
  final status = watchWalletStatus(ref);
  final config = ref.watch(walletConfigProvider);
  final choice = ref.watch(networkChoiceProvider).value;
  final tor = ref.watch(phoneTorProvider);
  final torState = phoneTorState(tor);
  final nodeUrl = config?.nodeUrl ?? choice?.nodeUrl;
  final node = nodeIconFace(
    context,
    status.node,
    config,
    behind: nodeBehind(ref, status.node, choice?.preset),
  );
  final failover = ref.watch(nodeFailoverProvider);
  final nodeTor = underTor(
    context,
    dot: node.dot,
    label: '${l.netStatusNode}, ${node.word}',
    detail: failover == null
        ? node.detail
        : '${node.detail}\n${l.nodeFailoverInsteadOf(serverHost(failover.chosen))}',
    way: nodeTorWay(nodeUrl, torState),
  );
  final epicbox = epicboxIconFace(context, status.epicbox, config);
  final epicboxTor = underTor(
    context,
    dot: epicbox.dot,
    label: '${l.netStatusEpicbox}, ${epicbox.word}',
    detail: epicbox.detail,
    way: torWay(TorRoute.epicbox, torState),
  );
  final torFace = torStatusOf(l, t, tor);
  final payments = ref.watch(appSettingsProvider).value?.payments ?? const PaymentPrefs();
  // On by either Link switch, or while the onion is published anyway (a running Link · Tor).
  final linkOn = payments.linkHttp || payments.linkTor || directIconShown(tor);
  final link = linkFace(l, t, tor, payments, ref.watch(phoneHttpProvider).listener, linkOn: linkOn);
  final block = watchNetBlock(context, ref);
  final torOn = torIconShown(tor);
  return (
    block: block,
    entries: [
      if (block == NetBlock.none) ...[
        (
          key: bar ? barNodeIconKey : nodeStatusKey,
          icon: node.icon,
          enabled: true,
          dot: nodeTor.dot,
          label: nodeTor.label,
          detail: nodeTor.detail,
          actionHint: l.netStatusOpenHint,
          // Only a sync in progress pulses: a connecting or waiting service sits still.
          pulse: status.node.state == NodeState.syncing,
          onTap: () => showNodePicker(context),
        ),
        (
          key: bar ? barEpicboxIconKey : epicboxStatusKey,
          icon: epicbox.icon,
          enabled: status.epicbox != null,
          dot: epicboxTor.dot,
          label: epicboxTor.label,
          detail: status.epicbox == null ? l.netStatusTurnOnHint : epicboxTor.detail,
          actionHint: status.epicbox == null ? l.netStatusTurnOnHint : l.netStatusOpenHint,
          pulse: false,
          onTap: status.epicbox == null
              ? () => openSettingsSection(context, SettingsSection.transactions)
              : () => showEpicboxPicker(context),
        ),
      ],
      // Tor and Link are always there: off, faint without a dot, a tap opens the switch; on,
      // the dot says how the connection goes.
      if (!block.byMode && torShown(tor))
        (
          key: bar ? barTorIconKey : torIconKey,
          icon: torIcon,
          enabled: torOn,
          dot: torDot(torState),
          label: torOn ? '${l.netStatusTor}, ${torWord(l, torState)}' : '${l.netStatusTor}, ${l.netStatusOff}',
          detail: !torOn ? l.netStatusTurnOnHintPrivacy : torState == TorState.on ? l.netStatusOn : torFace.text,
          actionHint: l.netStatusTorOpenHint,
          pulse: torState == TorState.starting,
          onTap: () => openPrivacySettings(context),
        ),
      if (block == NetBlock.none)
        (
          key: bar ? barLinkIconKey : directIconKey,
          icon: EpicGlyphs.link,
          enabled: linkOn,
          dot: link.dot,
          label: '${l.receiveTabDirect}, ${link.word}',
          detail: linkOn ? link.detail : l.netStatusTurnOnHint,
          actionHint: linkOn ? l.netStatusDirectOpenHint : l.netStatusTurnOnHint,
          pulse: link.dot == StatusDot.busy,
          onTap: linkOn
              ? () {
                  ref.read(receiveTabProvider.notifier).choose(ReceiveTab.direct);
                  ref.read(shellTabProvider.notifier).go(ShellTab.receive);
                }
              : () => openSettingsSection(context, SettingsSection.transactions),
        ),
    ],
  );
}

/// The status icons side by side: Node, Epicbox, Tor, Link, in that order ([statusEntries]).
/// While the network mode holds the network back (Offline, or Tor only without Tor) one word
/// stands in for the Node and Epicbox icons. Under Wallet's figure and, with [bar], in Send's
/// and Receive's balance header: the same icons, dots, labels, details and taps. A long press
/// on any icon opens the connections sheet ([showConnectionsSheet]).
class StatusIcons extends ConsumerWidget {
  const StatusIcons({super.key, this.bar = false});

  /// Whether this is the balance header's row, with its own keys for tests.
  final bool bar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:block, :entries) = statusEntries(context, ref, bar: bar);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (block != NetBlock.none)
          NetModeStatus(block, key: bar ? barNetModeKey : netModeStatusKey),
        for (final e in entries)
          StatusIcon(
            key: e.key,
            icon: e.icon,
            enabled: e.enabled,
            dot: e.dot,
            label: e.label,
            detail: e.detail,
            actionHint: e.actionHint,
            pulse: e.pulse,
            onTap: e.onTap,
            onLongPress: () => showConnectionsSheet(context),
          ),
      ],
    );
  }
}

/// The key of the connections sheet, for tests.
const Key connectionsSheetKey = ValueKey('connections-sheet');

/// Opens the connections sheet: one row per status ([statusEntries]) with its glyph, the
/// service and its state word, the detail under them, and a tap that closes the sheet and
/// opens the service as its icon does. The network mode, when one holds the network back, is
/// the first row.
Future<void> showConnectionsSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => const ConnectionsSheet(),
);

/// The connections sheet's body.
class ConnectionsSheet extends ConsumerWidget {
  const ConnectionsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final (:block, :entries) = statusEntries(context, ref, bar: false);
    final ring = theme.scaffoldBackgroundColor;
    Widget row({
      required Widget glyph,
      required String label,
      required String detail,
      required StatusDot dot,
      required VoidCallback onTap,
    }) {
      final problem = dot == StatusDot.bad;
      return Semantics(
        button: true,
        label: label,
        hint: detail,
        excludeSemantics: true,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            onTap();
          },
          borderRadius: BorderRadius.circular(t.radiusSmall),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: problem
                ? BoxDecoration(
                    color: t.riskSoft,
                    borderRadius: BorderRadius.circular(t.radiusSmall),
                  )
                : null,
            child: Row(
              children: [
                SizedBox(width: 28, child: Center(child: glyph)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: theme.textTheme.bodyLarge),
                      Text(
                        detail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: problem ? t.risk : t.dim,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: t.faint),
              ],
            ),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      key: connectionsSheetKey,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Semantics(
              header: true,
              child: Text(l.connectionsSheetTitle, style: theme.textTheme.titleMedium),
            ),
          ),
          if (block != NetBlock.none)
            row(
              glyph: Icon(
                block.byMode ? Icons.cloud_off_outlined : torIcon,
                size: statusGlyph,
                color: block.byMode ? t.dim : t.info,
              ),
              label: block.byMode ? l.advModeOffline : l.torWayWaiting,
              detail: block.byMode ? l.homeOfflineDetail : l.homeWaitingTorDetail,
              dot: StatusDot.off,
              onTap: () => openSettingsSection(context, SettingsSection.advanced),
            ),
          for (final e in entries)
            row(
              glyph: StatusGlyph(icon: e.icon, enabled: e.enabled, dot: e.dot, ring: ring),
              label: e.label,
              detail: e.detail,
              dot: e.enabled ? e.dot : StatusDot.off,
              onTap: e.onTap,
            ),
        ],
      ),
    );
  }
}
