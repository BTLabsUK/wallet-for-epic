// SPDX-License-Identifier: Apache-2.0
/// Home's status icons, in Wallet's fiat row: the node and Epicbox always, Tor while its
/// switch is on, Direct receive while the onion listener is up. Each is one [StatusIcon]: a
/// glyph with a state dot, the service and its state word for a screen reader, the detail in
/// a tooltip on a long press, and a tap that opens the service's screen. Every status read goes
/// through [watchWalletStatus] and [phoneTorProvider]; nothing here debounces or decides a route.
library;

import 'settings_rows.dart' show NavChevron;
import '../state_language.dart' show ShownState, torShownState;
import 'phone_sheet.dart';
import 'package:flutter/material.dart';
import 'status_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../advanced.dart';
import '../node_failover_phone.dart';
import '../phone_tor.dart';
import '../providers.dart';
import '../tor_phone.dart';
import '../tor_routes.dart';
import '../levels/level_providers.dart';
import 'levels/shell_status.dart' show shellEpicboxFace, shellNetworkFace, shellStatusesShown;
import 'levels/status_sheets.dart' show showEpicboxSheet, showNetworkSheet;
import 'network_status.dart' show nodeBehind, nodeTorWay;
import 'network_mode_phone.dart';
import 'network_mode_text.dart';
import 'receive_screen.dart' show ReceiveTab, receiveTabProvider;
import 'server_picker.dart';
import '../payment_prefs.dart' show PaymentPrefs;
import '../settings.dart' show appSettingsProvider, networkModeProvider;
import 'settings_screen.dart' show openPrivacySettings;
import 'settings_sections.dart' show SettingsSection, openSettingsSection;
import 'levels/status_parts.dart' show StatusServiceTile;
import 'status.dart';
import 'theme/tokens.dart';
import 'tor_ui.dart';
import '../text_join.dart';

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

/// Whether the Tor icon shows: while the switch is on (Starting…, On, Not connected).
bool torIconShown(PhoneTorState s) => phoneTorState(s) != TorState.off;

/// Whether the Direct receive icon shows: the switch is on, the wallet's onion is known and
/// tor is connected, so the listener is published ([PhoneTorPhase.ready]) or being published.
bool directIconShown(PhoneTorState s) =>
    torShown(s) && torIconShown(s) && s.canSend;

/// Tor's dot, from its one state ([torShownState]): green connected, blue starting, red not
/// connected, slashed off.
StatusDot torDot(TorState state) => StatusDot.of(torShownState(state));

/// Direct receive's dot and word: reachable (green) once the onion is published, publishing
/// (blue) meanwhile, not reachable (red) when it could not be.
({StatusDot dot, String word}) directFace(AppLocalizations l, PhoneTorState s) {
  final shown = s.phase == PhoneTorPhase.ready
      ? ShownState.reachable
      : s.failure != null
      ? ShownState.notReachable
      : ShownState.publishing;
  return (dot: StatusDot.of(shown), word: shown.word(l));
}

/// Link's dot and words for the status icons: off while Link · Tor is off; else the
/// onion's state ([directFace]). The phone receives nothing over Link · HTTP.
({StatusDot dot, String word, String detail}) linkFace(AppLocalizations l, WalletTokens t, PhoneTorState s, PaymentPrefs p, {required bool linkOn}) {
  if (!linkOn) return (dot: StatusDot.off, word: l.netStatusOff, detail: l.netStatusTurnOnHint);
  if (directIconShown(s) || (p.linkTor && torIconShown(s))) {
    final d = directFace(l, s);
    return (dot: d.dot, word: d.word, detail: torStatusOf(l, t, s).text);
  }
  return (dot: StatusDot.bad, word: l.torWordNotConnected, detail: l.torNeeds);
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

/// The key of the mode mark in Wallet's status strip, for tests.
const Key netModeStatusKey = networkModeMarkKey;

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
  String brief,
  String actionHint,
  bool pulse,
  VoidCallback onTap,
});

/// One line for a connections row out of a tooltip's [detail]: its first line, with [host]
/// after a middle dot when that line does not name it. A sentence's end mark goes before the
/// dot ("Up to date · node.example.org"). The rest of the detail (block, version, the
/// server's port) stays in the tooltip and the service's own screen.
String statusBrief(String detail, {String? host}) {
  var first = detail.split('\n').first.trim();
  if (host == null || host.isEmpty || first.contains(host)) return first;
  if (first.endsWith('.') || first.endsWith('。')) first = first.substring(0, first.length - 1);
  return metaLine([first, host]);
}

/// The statuses in their order, Node, Epicbox, Tor, Link. A service the network mode turns off
/// (Epicbox and Link in Node only; all of them in Kill switch) stays in its place as Off
/// ({mode}), faint with a slash, and a tap opens the Network section. Tor only waiting for Tor
/// shows through the services' own busy dots. [bar] picks the header row's keys over Wallet's.
({NetworkMode mode, List<StatusEntry> entries}) statusEntries(
  BuildContext context,
  WidgetRef ref, {
  required bool bar,
}) {
  final l = context.l10n;
  final t = context.tokens;
  // The quiet shell carries its own two icons in the app bar ([ShellStatusIcons]).
  if (shellStatusesShown(ref.watch(levelFeaturesProvider))) {
    return (mode: ref.watch(networkModeProvider), entries: const <StatusEntry>[]);
  }
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
  // On by the Link · Tor switch, or while the onion is published anyway (a running Link · Tor).
  final linkOn = payments.linkTor || directIconShown(tor);
  final link = linkFace(l, t, tor, payments, linkOn: linkOn);
  final mode = ref.watch(networkModeProvider);
  final torOn = torIconShown(tor);
  final killSwitch = mode == NetworkMode.killSwitch;
  final nodeOnly = mode == NetworkMode.nodeOnly;
  // A service the mode turns off: faint, slashed, "Off (Node only)", opens the Network section.
  StatusEntry off(Key key, IconData icon, String service) => (
    key: key,
    icon: icon,
    enabled: false,
    dot: StatusDot.off,
    label: '$service, ${statusOffByModeWord(l, mode)}',
    detail: l.statusOffByModeDetailNet,
    brief: l.statusOffByModeDetailNet,
    actionHint: l.netStatusOpenHint,
    pulse: false,
    onTap: () => openNetworkSection(context),
  );
  return (
    mode: mode,
    entries: [
      if (killSwitch) ...[
        off(bar ? barNodeIconKey : nodeStatusKey, node.icon, l.netStatusNode),
        off(bar ? barEpicboxIconKey : epicboxStatusKey, epicbox.icon, l.netStatusEpicbox),
      ] else ...[
        (
          key: bar ? barNodeIconKey : nodeStatusKey,
          icon: node.icon,
          enabled: true,
          dot: nodeTor.dot,
          label: nodeTor.label,
          detail: nodeTor.detail,
          brief: statusBrief(nodeTor.detail, host: nodeUrl == null ? null : serverHost(nodeUrl)),
          actionHint: l.netStatusOpenHint,
          // Only a sync in progress pulses: a connecting or waiting service sits still.
          pulse: status.node.state == NodeState.syncing,
          onTap: () => showNodePicker(context),
        ),
        if (nodeOnly)
          off(bar ? barEpicboxIconKey : epicboxStatusKey, epicbox.icon, l.netStatusEpicbox)
        else
        (
          key: bar ? barEpicboxIconKey : epicboxStatusKey,
          icon: epicbox.icon,
          enabled: status.epicbox != null,
          dot: epicboxTor.dot,
          label: epicboxTor.label,
          detail: status.epicbox == null ? l.netStatusTurnOnHint : epicboxTor.detail,
          brief: statusBrief(status.epicbox == null ? l.netStatusTurnOnHint : epicboxTor.detail, host: config?.epicboxDomain),
          actionHint: status.epicbox == null ? l.netStatusTurnOnHint : l.netStatusOpenHint,
          pulse: false,
          onTap: status.epicbox == null
              ? () => openSettingsSection(context, SettingsSection.transactions)
              : () => showEpicboxPicker(context),
        ),
      ],
      // Tor and Link are always there: off, faint without a dot, a tap opens the switch; on,
      // the dot says how the connection goes.
      if (killSwitch && torShown(tor))
        off(bar ? barTorIconKey : torIconKey, torIcon, l.netStatusTor)
      else if (torShown(tor))
        (
          key: bar ? barTorIconKey : torIconKey,
          icon: torIcon,
          enabled: torOn,
          dot: torDot(torState),
          label: torOn ? '${l.netStatusTor}, ${torWord(l, torState)}' : '${l.netStatusTor}, ${l.netStatusOff}',
          detail: !torOn ? l.netStatusTurnOnHintNet : torState == TorState.on ? torWord(l, torState) : torFace.text,
          brief: statusBrief(!torOn ? l.netStatusTurnOnHintNet : torState == TorState.on ? torWord(l, torState) : torFace.text),
          actionHint: l.netStatusTorOpenHint,
          pulse: torState == TorState.starting,
          onTap: () => openPrivacySettings(context),
        ),
      // No Tor in this build: Link has nothing to receive on the phone (Link · HTTP only sends),
      // so it shows nothing rather than an icon that reads as off.
      if (tor.phase != PhoneTorPhase.unavailable)
      if (killSwitch || nodeOnly)
        off(bar ? barLinkIconKey : directIconKey, EpicGlyphs.link, l.receiveTabDirect)
      else
        (
          key: bar ? barLinkIconKey : directIconKey,
          icon: EpicGlyphs.link,
          enabled: linkOn,
          dot: link.dot,
          label: '${l.receiveTabDirect}, ${link.word}',
          detail: linkOn ? link.detail : l.netStatusTurnOnHint,
          brief: statusBrief(linkOn ? link.detail : l.netStatusTurnOnHint),
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

/// The status icons side by side: Node, Epicbox, Tor, Link, in that order ([statusEntries]),
/// after the network mode's mark when the mode is not Normal. Under Wallet's figure and, with [bar], in Send's
/// and Receive's balance header: the same icons, dots, labels and details. A tap (or a long
/// press) on any icon opens the connections sheet ([showConnectionsSheet]), the one status entry
/// point at every View; its rows open the services.
class StatusIcons extends ConsumerWidget {
  const StatusIcons({super.key, this.bar = false});

  /// Whether this is the balance header's row, with its own keys for tests.
  final bool bar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final (:mode, :entries) = statusEntries(context, ref, bar: bar);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The mark belongs to Home's strip; the compact header keeps its room for the figure.
        if (mode != NetworkMode.standard && !bar) NetworkModeMark(key: netModeStatusKey),
        for (final e in entries)
          StatusIcon(
            key: e.key,
            icon: e.icon,
            enabled: e.enabled,
            dot: e.dot,
            label: e.label,
            detail: e.detail,
            actionHint: l.lvShellOpensDetails,
            pulse: e.pulse,
            onTap: () => showConnectionsSheet(context),
            onLongPress: () => showConnectionsSheet(context),
          ),
      ],
    );
  }
}

/// The key of the connections sheet, for tests.
const Key connectionsSheetKey = ValueKey('connections-sheet');

/// Opens the connections sheet, the status entry point at every View: one row per status
/// ([statusEntries]; at Shallow its Network and Epicbox) with its glyph, the service and its
/// state word, one line under them, and a tap that closes the sheet and opens the service
/// (its server list or settings; at Shallow its own sheet with Switch server). The network
/// mode, when one holds the network back, is the first row.
Future<void> showConnectionsSheet(BuildContext context) => showPhoneSheet<void>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => const ConnectionsSheet(),
);

/// The connections sheet's body: a header, then one row per service, its glyph with the state
/// mark on a tile, the service and its state word, one line under them, a chevron; a hairline
/// between rows. A row that reports a problem is tinted.
class ConnectionsSheet extends ConsumerWidget {
  const ConnectionsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final (:mode, :entries) = statusEntries(context, ref, bar: false);
    final shallow = shellStatusesShown(ref.watch(levelFeaturesProvider));
    final ring = t.surface;
    Widget row({
      required IconData icon,
      required Widget glyph,
      required bool enabled,
      required String label,
      required String detail,
      required StatusDot dot,
      required VoidCallback onTap,
    }) {
      final problem = dot == StatusDot.bad;
      void open() {
        Navigator.of(context).pop();
        onTap();
      }

      // The row's own tap for a screen reader: excludeSemantics drops the InkWell's.
      return Semantics(
        button: true,
        label: label,
        hint: detail,
        excludeSemantics: true,
        onTap: open,
        child: InkWell(
          onTap: open,
          borderRadius: BorderRadius.circular(t.radiusSmall),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: problem
                ? BoxDecoration(
                    color: t.riskSoft,
                    borderRadius: BorderRadius.circular(t.radiusSmall),
                  )
                : null,
            child: Row(
              children: [
                StatusServiceTile(icon: icon, enabled: enabled, size: 40, child: glyph),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: problem ? t.risk : t.dim,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const NavChevron(),
              ],
            ),
          ),
        ),
      );
    }
    final rows = <Widget>[
      if (mode != NetworkMode.standard)
        row(
          icon: networkModeGlyph(mode),
          glyph: Icon(networkModeGlyph(mode), size: statusGlyph, color: t.dim),
          enabled: false,
          label: l.netMarkRowLabel(networkModeName(l, mode)),
          detail: networkModeMarkLine(l, mode, waitingForTor: mode == NetworkMode.torOnly && ref.watch(phoneTorProvider.select(phoneTorState)) != TorState.on),
          dot: StatusDot.off,
          onTap: () => openNetworkSection(context),
        ),
      // Shallow: its two statuses, each opening its own sheet (status_sheets.dart).
      if (shallow) ...[
        () {
          final face = shellNetworkFace(context, ref);
          final url = ref.watch(walletConfigProvider)?.nodeUrl;
          return row(
            icon: EpicGlyphs.node,
            glyph: StatusGlyph(icon: EpicGlyphs.node, enabled: face.dot != StatusDot.off, dot: face.dot, ring: ring),
            enabled: face.dot != StatusDot.off,
            label: l.lvShellStatusTip(l.settingsAboutNetwork, face.word),
            detail: url == null || url.isEmpty ? face.word : serverHost(url),
            dot: face.dot,
            onTap: () => showNetworkSheet(context),
          );
        }(),
        () {
          final face = shellEpicboxFace(context, ref);
          final config = ref.watch(walletConfigProvider);
          return row(
            icon: EpicGlyphs.epicbox,
            glyph: StatusGlyph(icon: EpicGlyphs.epicbox, enabled: face.dot != StatusDot.off, dot: face.dot, ring: ring),
            enabled: face.dot != StatusDot.off,
            label: l.lvShellStatusTip(l.netStatusEpicbox, face.word),
            detail: config == null ? face.word : relayLabel(config),
            dot: face.dot,
            onTap: () => showEpicboxSheet(context),
          );
        }(),
      ] else
        for (final e in entries)
          row(
            icon: e.icon,
            glyph: StatusGlyph(icon: e.icon, enabled: e.enabled, dot: e.dot, ring: ring),
            enabled: e.enabled,
            label: e.label,
            detail: e.brief,
            dot: e.enabled ? e.dot : StatusDot.off,
            onTap: e.onTap,
          ),
    ];
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
          for (final (n, r) in rows.indexed) ...[
            if (n > 0) Divider(height: 1, thickness: 1, indent: 12, endIndent: 12, color: t.line),
            r,
          ],
        ],
      ),
    );
  }
}
