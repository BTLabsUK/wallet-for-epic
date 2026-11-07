// SPDX-License-Identifier: Apache-2.0
/// The level-1 explore sheets a status icon opens ([ShellStatusIcons]): Network and Epicbox,
/// each a header with the server's tile, the name and its state as a badge, the server under
/// them (from the wallet's own state, never literals), a few plain facts as a strip
/// (`status_parts.dart`), and Switch server ([ShallowServerSwitch]): the other servers of the
/// list, one tap moves. The Epicbox sheet also carries flow D: the relay offer with Switch /
/// Keep waiting, and after a move the new address. Levels 2 and 3 keep today's connections
/// sheet and server lists.
library;

import '../phone_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../../levels/relay_switch_providers.dart';
import '../../node_failover_phone.dart';
import '../../server_list.dart' show ServerKind;
import '../../message_checks.dart';
import '../../providers.dart';
import '../common.dart';
import '../message_check_lines.dart';
import '../status.dart';
import '../status_icons.dart';
import '../theme/tokens.dart';
import 'relay_down.dart';
import 'shallow_switch.dart';
import 'shell_status.dart';
import 'status_parts.dart';

/// The keys of the sheets and their parts, for tests.
const Key networkSheetKey = ValueKey('shell-network-sheet');
const Key epicboxSheetKey = ValueKey('shell-epicbox-sheet');
const Key sheetSwitchKey = ValueKey('shell-sheet-switch');
const Key sheetKeepWaitingKey = ValueKey('shell-sheet-keep-waiting');
const Key sheetShowAddressKey = ValueKey('shell-sheet-show-address');

Future<void> _sheet(BuildContext context, Widget body) => showPhoneSheet<void>(
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

/// The sheet's frame: the header, the notes under it, the facts strip, the cards and the
/// actions, then OK.
class _SheetBody extends StatelessWidget {
  const _SheetBody({
    super.key,
    required this.header,
    this.notes = const [],
    this.facts = const [],
    this.cards = const [],
    this.actions = const [],
  });

  final Widget header;
  final List<String> notes;
  final List<SheetFact> facts;
  final List<Widget> cards;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final n in notes) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(n, style: theme.textTheme.bodyMedium?.copyWith(color: t.dim))),
          ],
          if (facts.isNotEmpty) ...[const SizedBox(height: 14), StatusFactStrip(facts)],
          for (final c in cards) ...[const SizedBox(height: 12), c],
          const SizedBox(height: 16),
          ...actions,
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

/// The Network sheet: the node's tile, state and address, the latest block, whether this
/// wallet is up to date and the one failover moved from; Switch server.
class NetworkSheet extends ConsumerWidget {
  const NetworkSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
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
    final url = config?.nodeUrl;
    final host = url == null ? null : serverHost(url);
    final server = url == null ? null : serverFaceOf(ref, ServerKind.node, url);
    return _SheetBody(
      key: networkSheetKey,
      header: StatusSheetHeader(
        tile: host == null || host.isEmpty
            ? StatusServiceTile(icon: EpicGlyphs.node, enabled: face.dot != StatusDot.off)
            : StatusServerTile(host: host, operator: server?.operator, icon: server?.icon, dimmed: face.dot == StatusDot.off),
        name: l.settingsAboutNetwork,
        word: face.word,
        dot: face.dot,
        second: host,
        secondMono: true,
      ),
      facts: [
        if (tip != null && tip > BigInt.zero) (label: l.lvShellLatestBlock, value: groupDigits(l, tip), mono: false),
        (label: l.lvShellThisWallet, value: wallet, mono: false),
        if (failover != null) (label: l.lvShellLastChange, value: l.nodeFailoverInsteadOf(serverHost(failover.chosen)), mono: false),
      ],
      actions: const [ShallowServerSwitch(kind: ServerKind.node), SizedBox(height: 8)],
    );
  }
}

/// The Epicbox sheet: the server's tile, state and address, whether payments can reach this
/// wallet; Switch server. With a relay offer it says payments wait and offers the move; after
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
    final state = watchWalletStatus(ref).epicbox;
    final face = shellEpicboxFace(context, ref);
    final config = ref.watch(walletConfigProvider);
    final offer = ref.watch(relaySwitchProvider);
    final moved = ref.watch(relaySwitchResultProvider);
    final relay = config == null ? null : relayLabel(config);
    final server = relay == null ? null : serverFaceOf(ref, ServerKind.relay, relay);
    final down = state == EpicboxState.offline || state == EpicboxState.blocked;
    final stateText = switch (state) {
      null => l.netStatusOff,
      EpicboxState.online => l.lvShellBoxListening,
      EpicboxState.connecting => l.lvShellStateConnecting,
      EpicboxState.offline || EpicboxState.blocked => l.lvShellBoxNotReachable,
    };
    return _SheetBody(
      key: epicboxSheetKey,
      header: StatusSheetHeader(
        tile: relay == null
            ? StatusServiceTile(icon: EpicGlyphs.epicbox, enabled: face.dot != StatusDot.off)
            : StatusServerTile(host: config!.epicboxDomain, operator: server?.operator, icon: server?.icon, dimmed: face.dot == StatusDot.off),
        name: l.netStatusEpicbox,
        word: face.word,
        dot: face.dot,
        second: relay,
        secondMono: true,
      ),
      notes: [
        // The state in a sentence under the header; what it means for payments when down.
        if (stateText != face.word) stateText,
        if (down && !(moved != null && offer == null)) l.lvShellBoxDownBody,
        ...messageCheckLines(l, ref.watch(messageCheckProvider).value ?? const MessageCheck()),
      ],
      cards: [
        if (moved != null && offer == null)
          StatusSheetCard(tone: BadgeTone.ok, icon: EpicGlyphs.epicbox, title: l.lvShellNowOn(moved.name), body: l.lvShellSwitchedBody)
        else if (offer != null)
          StatusSheetCard(
            tone: BadgeTone.warn,
            icon: EpicGlyphs.epicbox,
            title: l.lvShellOfferReady(offer.name),
            body: l.lvShellOfferBody(offer.name),
          ),
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
        if (!_moving) ...[const ShallowServerSwitch(kind: ServerKind.relay), const SizedBox(height: 8)],
      ],
    );
  }
}
