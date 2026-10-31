// SPDX-License-Identifier: Apache-2.0
/// The level-1 explore sheets a status icon opens ([ShellStatusIcons]): Network and Epicbox,
/// each its state, a few plain facts, a "For support" group with the hosts and the address (from
/// the wallet's own state, never literals) and Copy details. The Epicbox sheet also carries
/// flow D: the relay offer with Switch / Keep waiting, and after a move the new address.
/// Levels 2 and 3 keep today's connections sheet and server lists.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../../levels/relay_switch_providers.dart';
import '../../node_failover_phone.dart';
import '../../providers.dart';
import '../../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../common.dart';
import '../status.dart';
import '../theme/tokens.dart';
import '../tip.dart';
import 'relay_down.dart';
import 'shell_status.dart';

/// The keys of the sheets and their parts, for tests.
const Key networkSheetKey = ValueKey('shell-network-sheet');
const Key epicboxSheetKey = ValueKey('shell-epicbox-sheet');
const Key sheetCopyDetailsKey = ValueKey('shell-sheet-copy');
const Key sheetSwitchKey = ValueKey('shell-sheet-switch');
const Key sheetKeepWaitingKey = ValueKey('shell-sheet-keep-waiting');
const Key sheetShowAddressKey = ValueKey('shell-sheet-show-address');

Future<void> _sheet(BuildContext context, Widget body) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) => body,
);

/// Opens the Network sheet.
Future<void> showNetworkSheet(BuildContext context) => _sheet(context, const NetworkSheet());

/// Opens the Epicbox sheet.
Future<void> showEpicboxSheet(BuildContext context) => _sheet(context, const EpicboxSheet());

/// One fact: a label and its value. A [full] value (a host, an address) is shown shortened
/// and whole in its tooltip and in Copy details.
typedef _Fact = ({String label, String value, String? full});

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    super.key,
    required this.title,
    required this.state,
    required this.stateColor,
    required this.facts,
    required this.support,
    this.top = const [],
    this.actions = const [],
  });

  final String title;
  final String state;
  final Color stateColor;
  final List<Widget> top;
  final List<_Fact> facts;
  final List<_Fact> support;
  final List<Widget> actions;

  String _details() => [
    title,
    state,
    for (final f in [...facts, ...support]) '${f.label}: ${f.full ?? f.value}',
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    Widget row(_Fact f) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(f.label, style: theme.textTheme.bodyMedium?.copyWith(color: t.dim))),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Tip.value(
                f.full,
                child: Text(f.value, textAlign: TextAlign.end, style: theme.textTheme.bodyMedium),
              ),
            ),
          ),
        ],
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(title, style: theme.textTheme.titleLarge)),
          const SizedBox(height: 4),
          Text(state, style: theme.textTheme.bodyMedium?.copyWith(color: stateColor)),
          const SizedBox(height: 12),
          ...top,
          for (final f in facts) row(f),
          if (support.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l.lvShellForSupport, style: theme.textTheme.labelLarge?.copyWith(color: t.dim)),
            const SizedBox(height: 4),
            for (final f in support) row(f),
          ],
          const SizedBox(height: 16),
          ...actions,
          OutlinedButton.icon(
            key: sheetCopyDetailsKey,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l.lvShellCopyDetails),
            onPressed: () => copyText(context, _details(), l.lvShellDetailsCopied),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.commonOk),
          ),
        ],
      ),
    );
  }
}

Color _stateColor(WalletTokens t, StatusDot dot) => switch (dot) {
  StatusDot.ok => t.ok,
  StatusDot.off => t.dim,
  _ => dot.color(t),
};

/// The Network sheet: the node's state, the latest block, whether this wallet is up to date;
/// for support the node in use and the one failover moved from.
class NetworkSheet extends ConsumerWidget {
  const NetworkSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final status = watchWalletStatus(ref);
    final face = shellNetworkFace(context, ref);
    final config = ref.watch(walletConfigProvider);
    final failover = ref.watch(nodeFailoverProvider);
    final node = status.node;
    final tip = node.tip?.height;
    final wallet = switch (node.state) {
      NodeState.online when face.dot == StatusDot.ok => l.lvShellUpToDate,
      NodeState.syncing when node.percent != null => l.statusNodeSyncingPercent(node.percent!),
      NodeState.syncing || NodeState.online => l.lvShellStateCatchingUp,
      NodeState.connecting || NodeState.offline => l.lvShellNotChecked,
    };
    final host = config == null ? null : serverHost(config.nodeUrl);
    return _SheetBody(
      key: networkSheetKey,
      title: l.settingsAboutNetwork,
      state: face.word,
      stateColor: _stateColor(t, face.dot),
      facts: [
        if (tip != null && tip > BigInt.zero) (label: l.lvShellLatestBlock, value: groupDigits(l, tip), full: null),
        (label: l.lvShellThisWallet, value: wallet, full: null),
      ],
      support: [
        if (host != null && host.isNotEmpty) (label: l.netStatusNode, value: host, full: null),
        if (failover != null) (label: l.lvShellLastChange, value: l.nodeFailoverInsteadOf(serverHost(failover.chosen)), full: null),
        if (node.tip?.nodeVersion case final v? when v.isNotEmpty) (label: l.lvShellNodeVersion, value: v, full: null),
      ],
    );
  }
}

/// The Epicbox sheet: whether payments can reach this wallet, the server's name; for support
/// the address and the host. With a relay offer it says payments wait and offers the move; after
/// a move it names the new server and opens the new address.
class EpicboxSheet extends ConsumerStatefulWidget {
  const EpicboxSheet({super.key});

  @override
  ConsumerState<EpicboxSheet> createState() => _EpicboxSheetState();
}

class _EpicboxSheetState extends ConsumerState<EpicboxSheet> {
  bool _moving = false;

  Future<void> _switch() async {
    setState(() => _moving = true);
    await acceptRelaySwitch(context, ref);
    if (mounted) setState(() => _moving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final state = watchWalletStatus(ref).epicbox;
    final face = shellEpicboxFace(context, ref);
    final config = ref.watch(walletConfigProvider);
    final offer = ref.watch(relaySwitchProvider);
    final moved = ref.watch(relaySwitchResultProvider);
    final address = state == null ? null : ref.watch(addressProvider).value;
    final relay = config == null ? null : relayLabel(config);
    final name = relay == null
        ? null
        : ref
              .watch(hostSettingsProvider)
              .epicboxServers
              .where((s) => s.label.toLowerCase() == relay.toLowerCase())
              .firstOrNull
              ?.operator;
    final down = state == EpicboxState.offline || state == EpicboxState.blocked;
    final stateText = switch (state) {
      null => l.netStatusOff,
      EpicboxState.online => l.lvShellBoxListening,
      EpicboxState.connecting => l.lvShellStateConnecting,
      EpicboxState.offline || EpicboxState.blocked => l.lvShellBoxNotReachable,
    };
    Widget card(String title, String body) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(t.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(body, style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
        ],
      ),
    );
    return _SheetBody(
      key: epicboxSheetKey,
      title: l.netStatusEpicbox,
      state: stateText,
      stateColor: _stateColor(t, face.dot),
      top: [
        if (moved != null && offer == null)
          card(l.lvShellNowOn(moved.name), l.lvShellSwitchedBody)
        else if (down) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(l.lvShellBoxDownBody, style: theme.textTheme.bodyMedium),
          ),
          if (offer != null) card(l.lvShellOfferReady(offer.name), l.lvShellOfferBody(offer.name)),
        ],
      ],
      facts: [
        if (name != null) (label: l.lvShellServer, value: name, full: null),
      ],
      support: [
        if (address != null) (label: l.lvShellAddress, value: shortAddress(address), full: address),
        if (relay != null) (label: l.lvShellHost, value: relay, full: null),
        if (moved != null) (label: l.lvShellOldServer, value: moved.from.label, full: null),
      ],
      actions: [
        if (offer != null) ...[
          BusyButton(
            key: sheetSwitchKey,
            label: l.lvShellSwitchTo(offer.name),
            busy: _moving,
            onPressed: _switch,
          ),
          const SizedBox(height: 8),
          TextButton(
            key: sheetKeepWaitingKey,
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _moving
                ? null
                : () {
                    keepWaitingForRelay(ref);
                    Navigator.of(context).pop();
                  },
            child: Text(l.lvShellKeepWaiting),
          ),
          const SizedBox(height: 8),
        ] else if (moved != null) ...[
          FilledButton(
            key: sheetShowAddressKey,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () {
              Navigator.of(context).pop();
              showNewAddress(ref);
            },
            child: Text(l.lvShellShowNewAddress),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
