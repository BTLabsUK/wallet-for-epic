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

/// Link's dot and words for the status icons (bot #123): off while neither Link method is
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
  const NetModeStatus(this.block, {super.key, this.compact = false});

  final NetBlock block;

  /// The glyph alone, for the app bar; the word is still what a screen reader says.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final offline = block == NetBlock.offline;
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
            constraints: BoxConstraints(minHeight: statusTarget, minWidth: compact ? statusTarget : 0),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 4 : statusInset,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    offline ? Icons.cloud_off_outlined : torIcon,
                    size: compact ? statusCompactGlyph : statusGlyph,
                    color: color,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 8),
                    Text(
                      word,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The status icons side by side: Node, Epicbox, Tor, Direct, in that order. While the network
/// mode holds the network back (Offline, or Tor only without Tor) one word stands in for the
/// Node and Epicbox icons. [compact] is the small row in Send's and Receive's app bar: the same
/// icons, dots, labels, details and taps, smaller and without Direct receive (which belongs to
/// Wallet), and the mode's word shrinks to its glyph.
class StatusIcons extends ConsumerWidget {
  const StatusIcons({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (block != NetBlock.none)
          NetModeStatus(
            block,
            key: compact ? barNetModeKey : netModeStatusKey,
            compact: compact,
          )
        else ...[
          StatusIcon(
            key: compact ? barNodeIconKey : nodeStatusKey,
            compact: compact,
            icon: node.icon,
            dot: nodeTor.dot,
            label: nodeTor.label,
            detail: nodeTor.detail,
            actionHint: l.netStatusOpenHint,
            // Only a sync in progress pulses: a connecting or waiting service sits still.
            pulse: status.node.state == NodeState.syncing,
            onTap: () => showNodePicker(context),
          ),
          StatusIcon(
            key: compact ? barEpicboxIconKey : epicboxStatusKey,
            compact: compact,
            enabled: status.epicbox != null,
            icon: epicbox.icon,
            dot: epicboxTor.dot,
            label: epicboxTor.label,
            detail: status.epicbox == null ? l.netStatusTurnOnHint : epicboxTor.detail,
            actionHint: status.epicbox == null ? l.netStatusTurnOnHint : l.netStatusOpenHint,
            onTap: status.epicbox == null ? () => openSettingsSection(context, SettingsSection.transactions) : () => showEpicboxPicker(context),
          ),
        ],
        // Tor and Link are always there (bot #123): off, faint without a dot, a tap opens
        // the switch; on, the dot says how the connection goes.
        if (block != NetBlock.offline && torShown(tor))
          StatusIcon(
            key: compact ? barTorIconKey : torIconKey,
            compact: compact,
            enabled: torIconShown(tor),
            icon: torIcon,
            dot: torDot(torState),
            label: torIconShown(tor) ? '${l.netStatusTor}, ${torWord(l, torState)}' : '${l.netStatusTor}, ${l.netStatusOff}',
            detail: !torIconShown(tor) ? l.netStatusTurnOnHintPrivacy : torState == TorState.on ? l.netStatusOn : torFace.text,
            actionHint: l.netStatusTorOpenHint,
            pulse: torState == TorState.starting,
            onTap: () => openPrivacySettings(context),
          ),
        if (block == NetBlock.none)
          StatusIcon(
            key: compact ? barLinkIconKey : directIconKey,
            compact: compact,
            enabled: linkOn,
            icon: EpicGlyphs.link,
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
    if (!compact || block != NetBlock.none) return row;
    // The compact row is one tap target (its icons are too narrow to be one each): it says
    // every status, and a tap opens what has a problem first, else the node list.
    final torOn = torIconShown(tor);
    final torBad = torOn && torDot(torState) == StatusDot.bad;
    final torLabel = torOn ? '${l.netStatusTor}, ${torWord(l, torState)}' : '${l.netStatusTor}, ${l.netStatusOff}';
    void open() => nodeTor.dot == StatusDot.bad || epicboxTor.dot != StatusDot.bad && !torBad
        ? showNodePicker(context)
        : epicboxTor.dot == StatusDot.bad
        ? showEpicboxPicker(context)
        : openPrivacySettings(context);
    return Semantics(
      container: true,
      button: true,
      label: [nodeTor.label, epicboxTor.label, torLabel, '${l.receiveTabDirect}, ${link.word}'].join('\n'),
      hint: l.netStatusOpenHint,
      liveRegion: true,
      excludeSemantics: true,
      onTap: open,
      child: InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(t.radiusSmall),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: statusTarget, minHeight: statusTarget),
          child: row,
        ),
      ),
    );
  }
}
