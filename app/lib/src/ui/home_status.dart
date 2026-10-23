/// Home's status icons, in Wallet's fiat row: the node and Epicbox always, Tor while its
/// switch is on, Direct receive while the onion listener is up. Each is one [StatusIcon]: a
/// glyph with a state dot, the service and its state word for a screen reader, the detail in
/// a tooltip on a long press, and a tap that opens the service's screen. Every status read goes
/// through [watchWalletStatus] and [phoneTorProvider]; nothing here debounces or decides a route.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../phone_tor.dart';
import '../providers.dart';
import '../tor_phone.dart';
import '../tor_routes.dart';
import 'network_status.dart' show nodeBehind, nodeTorWay;
import 'receive_screen.dart' show ReceiveTab, receiveTabProvider;
import 'server_picker.dart';
import 'settings_screen.dart' show openPrivacySettings;
import 'status.dart';
import 'theme/tokens.dart';
import 'tor_ui.dart';

/// The key of the Tor status icon, for tests.
const Key torIconKey = ValueKey('status-tor');

/// The key of the Direct receive status icon, for tests.
const Key directIconKey = ValueKey('status-direct');

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

/// The status icons side by side: Node, Epicbox, Tor, Direct, in that order.
class StatusIcons extends ConsumerWidget {
  const StatusIcons({super.key});

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
    final nodeTor = underTor(
      context,
      dot: node.dot,
      label: '${l.netStatusNode}, ${node.word}',
      detail: node.detail,
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
    final direct = directFace(l, tor);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusIcon(
          key: nodeStatusKey,
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
          key: epicboxStatusKey,
          icon: epicbox.icon,
          dot: epicboxTor.dot,
          label: epicboxTor.label,
          detail: epicboxTor.detail,
          actionHint: l.netStatusOpenHint,
          onTap: () => showEpicboxPicker(context),
        ),
        if (torIconShown(tor))
          StatusIcon(
            key: torIconKey,
            icon: torIcon,
            dot: torDot(torState),
            label: '${l.netStatusTor}, ${torWord(l, torState)}',
            detail: torState == TorState.on ? l.netStatusOn : torFace.text,
            actionHint: l.netStatusTorOpenHint,
            pulse: torState == TorState.starting,
            onTap: () => openPrivacySettings(context),
          ),
        if (directIconShown(tor))
          StatusIcon(
            key: directIconKey,
            icon: Icons.link,
            dot: direct.dot,
            label: '${l.receiveTabDirect}, ${direct.word}',
            detail: torFace.text,
            actionHint: l.netStatusDirectOpenHint,
            pulse: direct.dot == StatusDot.busy,
            onTap: () {
              ref.read(receiveTabProvider.notifier).choose(ReceiveTab.direct);
              ref.read(shellTabProvider.notifier).go(ShellTab.receive);
            },
          ),
      ],
    );
  }
}
