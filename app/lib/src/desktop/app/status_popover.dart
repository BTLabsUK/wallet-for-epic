// SPDX-License-Identifier: Apache-2.0
/// What a title-bar status icon opens (wallet levels, D5/D10): a popover under that icon. Its
/// header is the service's tile (the server's operator icon or initials as the server lists
/// show it; the glyph on a gold-ticked tile for Tor and Link), the name with the state as a
/// badge and the server under it; then the facts as a strip of aligned cells, a note where
/// one is due, and a footer band with the actions (`status_parts.dart`). At Deeper and Deep
/// end the footer opens the service's settings. Shallow names the node "Network" and, having no
/// server settings, offers Switch server ([DeskServerSwitch]) for the node and Epicbox with
/// Close beside it; Deep end adds the height and the version. The Epicbox popover carries the
/// server offer ([DeskRelayOfferPanel]) when there is one.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart' show localInt;
import '../../network.dart' show EpicboxRelay;
import '../../levels/level_features.dart' show StatusIcon;
import '../../levels/wallet_level.dart';
import '../../ui/common.dart' as common show shortAddress;
import '../../message_checks.dart' show MessageCheck;
import '../data/desk_levels.dart';
import '../data/desk_node.dart';
import '../desk_l10n.dart';
import '../screens/settings/prefs.dart';
import '../widgets/kit.dart';
import 'desk_app.dart' show deskNavigatorKey;
import 'desk_failover.dart';
import 'kept_messages_dialog.dart';
import 'message_check_panel.dart';
import 'rail.dart' show RailItem;
import 'relay_offer.dart';
import 'server_switch.dart';
import 'status_parts.dart';

/// The level's icon for a status row (Node is the level's Network).
StatusIcon deskStatusIconOf(RailItem i) => switch (i.jump) {
  SettingsJump.node => StatusIcon.network,
  SettingsJump.epicbox => StatusIcon.epicbox,
  SettingsJump.http => StatusIcon.http,
  _ => StatusIcon.tor,
};

/// The items the level shows, in the bar's order. A server that does not answer while another
/// is ready to take over is amber, not red (the offer is the way out, as on the phone).
List<RailItem> deskStatusShown(WidgetRef ref, List<RailItem> items) {
  final icons = ref.watch(deskLevelFeaturesProvider).statusIcons;
  final offer = ref.watch(deskRelayOfferProvider) != null;
  return [
    for (final i in items)
      if (icons.contains(deskStatusIconOf(i)))
        offer && i.jump == SettingsJump.epicbox && i.state == EState.risk
            ? RailItem(icon: i.icon, name: i.name, word: i.word, state: EState.warn, second: i.second, marker: i.marker, lines: i.lines, note: i.note, open: i.open, jump: i.jump, byMode: i.byMode)
            : i,
  ];
}

/// [items] during the connection grace ([grace], `connection_grace.dart`): a server that does
/// not answer yet (the node, Epicbox, Tor) reads Connecting, in progress, with its host and
/// none of its warning lines: the connection is only coming back. Off, off by the mode, and
/// Link · HTTP (a listener on this computer) stay as they are.
List<RailItem> graceRailItems(AppLocalizations l, List<RailItem> items, {required bool grace}) => !grace
    ? items
    : [
        for (final i in items)
          if (i.byMode || i.jump == SettingsJump.http || !(i.state == EState.risk || i.state == EState.warn))
            i
          else
            RailItem(
              icon: i.icon,
              name: i.name,
              word: ShownState.connecting.word(l),
              state: EState.active,
              second: i.second,
              lines: const [],
              note: i.note,
              open: i.open,
              jump: i.jump,
            ),
      ];

/// The name a status shows at the level: Shallow's node is "Network".
String deskStatusName(AppLocalizations l, WalletLevel level, RailItem i) =>
    level == WalletLevel.justSendReceive && i.jump == SettingsJump.node ? l.settingsAboutNetwork : i.name;

/// The state word at the level: Shallow's plain words, today's elsewhere.
String deskStatusWord(AppLocalizations l, WalletLevel level, RailItem i) {
  if (level != WalletLevel.justSendReceive || i.byMode) return i.word;
  final node = i.jump == SettingsJump.node;
  return switch (i.state) {
    EState.ok => l.commonOk,
    EState.active => node ? l.lvShellStateCatchingUp : l.lvShellStateConnecting,
    EState.warn => node ? l.lvShellStateBehind : l.netStatusNotReachable,
    EState.risk => l.netStatusNotReachable,
    EState.off => l.netStatusOff,
  };
}

/// "Name · State", the icon's tooltip and its button's label.
String deskStatusTip(AppLocalizations l, WalletLevel level, RailItem i) => l.lvShellStatusTip(deskStatusName(l, level, i), deskStatusWord(l, level, i));

/// The popover's width: wide enough for a relay's label beside its tile, never a reading column.
double get deskStatusPopoverWidth => 320.u;

/// The popover's content for [item]; [close] closes it (before a jump into Settings).
class DeskStatusPopover extends ConsumerWidget {
  const DeskStatusPopover({super.key, required this.item, required this.close});

  final RailItem item;
  final VoidCallback close;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final i = item;
    final level = ref.watch(deskLevelProvider);
    final shallow = level == WalletLevel.justSendReceive;
    final deep = level == WalletLevel.everything;
    final status = ref.watch(deskProvider.select((s) => s.status));
    final name = deskStatusName(l, level, i);
    final word = deskStatusWord(l, level, i);
    final facts = <DeskFact>[];
    final notes = <String>[];
    Widget tile;
    String? second;
    var secondMono = false;
    Widget? panel;
    switch (i.jump) {
      case SettingsJump.node:
        final node = status?.node;
        final url = node?.url;
        final info = url == null || url.isEmpty ? null : ref.watch(deskNodeInfoProvider(url)).value;
        final failover = ref.watch(deskFailoverProvider);
        final failoverOn = ref.watch(deskProvider.select((s) => s.settings.advanced.nodeFailover));
        final height = status == null || status.nodeHeight <= 0 ? null : status.nodeHeight;
        final version = info?.version;
        final host = url == null || url.isEmpty ? null : nodeHost(url);
        tile = host == null
            ? DeskServiceTile(icon: i.icon, state: i.state)
            : DeskServerTile(host: host, operator: node?.listedAs ?? node?.operator, icon: node?.icon, dimmed: i.state == EState.off);
        second = host;
        secondMono = true;
        if (shallow) {
          final tip = info?.networkHeight ?? height;
          if (tip != null) facts.add((label: l.lvShellLatestBlock, value: localInt(l, tip), mono: false));
          facts.add((
            label: l.lvShellThisWallet,
            value: switch (i.state) {
              EState.ok => l.lvShellUpToDate,
              EState.active || EState.warn => l.lvShellStateCatchingUp,
              _ => l.lvShellNotChecked,
            },
            mono: false,
          ));
          if (failover != null) facts.add((label: l.lvShellLastChange, value: l.deskNodeFailoverInsteadOf(nodeHost(failover.chosen)), mono: false));
        } else {
          // A mode's own line, unless it only repeats the state word (then the host stays).
          if (i.byMode && i.second != i.word) {
            second = i.second;
            secondMono = false;
          }
          if (deep && height != null) facts.add((label: l.deskLvShellHeight, value: localInt(l, height), mono: false));
          if (deep && version != null && version.isNotEmpty) facts.add((label: l.deskLvShellVersion, value: version, mono: false));
          facts.add((label: l.deskLvShellFailover, value: failoverOn ? l.deskLvShellOn : l.netStatusOff, mono: false));
        }
      case SettingsJump.epicbox:
        final address = ref.watch(deskProvider.select((s) => s.epicboxAddress));
        final server = status?.epicbox;
        final relay = server == null || server.domain.isEmpty ? null : EpicboxRelay(host: server.domain, port: server.port).label;
        tile = relay == null
            ? DeskServiceTile(icon: i.icon, state: i.state)
            : DeskServerTile(host: server!.domain, operator: server.listedAs ?? server.operator, icon: server.icon, dimmed: i.state == EState.off);
        final modeLine = i.byMode && i.second != i.word;
        second = modeLine ? i.second : relay;
        secondMono = !modeLine;
        if (address != null && address.isNotEmpty) facts.add((label: l.lvShellAddress, value: common.shortAddress(address, relay: false), mono: true));
        if (shallow && (i.state == EState.risk || i.state == EState.warn)) notes.add(l.lvShellBoxDownBody);
        panel = DeskMessageCheckPanel(
          ref.watch(deskMessageCheckProvider).value ?? const MessageCheck(),
          onOpenKept: () {
            close();
            final nav = deskNavigatorKey.currentContext;
            if (nav != null) unawaited(showDeskKeptMessages(nav));
          },
        );
      default:
        tile = DeskServiceTile(icon: i.icon, state: i.state);
        if (i.second != '–' && i.second != i.word) second = [i.second, ?i.marker].join(' ');
        if (i.note != null) notes.add(i.note!);
    }
    if (i.byMode) notes.addAll(i.lines);

    final switchable = shallow && (i.jump == SettingsJump.node || i.jump == SettingsJump.epicbox);
    final closeButton = EButton(key: ValueKey('status-close-${i.jump.name}'), label: l.commonClose, kind: EBtnKind.ghost, size: EBtnSize.sm, onPressed: close);
    return SizedBox(
      width: deskStatusPopoverWidth,
      child: Column(
        key: ValueKey('status-pop-${i.jump.name}'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(Sp.x3, Sp.x3, Sp.x3, Sp.x3),
            child: DeskStatusHeader(
              rowKey: ValueKey('status-row-${i.jump.name}'),
              tile: tile,
              name: name,
              word: word,
              state: i.state,
              second: second,
              secondMono: secondMono,
            ),
          ),
          if (facts.isNotEmpty) Padding(padding: EdgeInsets.symmetric(horizontal: Sp.x3), child: DeskFactStrip(facts, bottomLine: false)),
          if (notes.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(Sp.x3, facts.isEmpty ? 0 : Sp.x3, Sp.x3, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final n in notes) Padding(padding: EdgeInsets.only(bottom: 4.u), child: Text(n, style: ts.small.copyWith(color: c.dim)))],
              ),
            ),
          if (panel case final panel?)
            Padding(
              padding: EdgeInsets.fromLTRB(Sp.x1, facts.isEmpty && notes.isEmpty ? 0 : Sp.x2, Sp.x1, 0),
              child: Container(
                padding: EdgeInsets.only(top: Sp.x1),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                child: panel,
              ),
            ),
          if (i.jump == SettingsJump.epicbox) Padding(padding: EdgeInsets.symmetric(horizontal: Sp.x3), child: DeskRelayOfferPanel(close: close)),
          // The footer band: Switch server with Close beside it (Shallow), or the settings button.
          Padding(
            padding: EdgeInsets.fromLTRB(Sp.x3, Sp.x3, Sp.x3, Sp.x2),
            child: switchable
                ? DeskServerSwitch(key: ValueKey('status-switch-box-${i.jump.name}'), epicbox: i.jump == SettingsJump.epicbox, close: close, trailing: closeButton)
                : Container(
                    padding: EdgeInsets.only(top: Sp.x2),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: c.lineStrong))),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: Sp.x2,
                      runSpacing: Sp.x2,
                      children: [
                        if (!shallow)
                          EButton(
                            key: ValueKey('status-open-${i.jump.name}'),
                            label: i.open,
                            size: EBtnSize.sm,
                            onPressed: () {
                              close();
                              deskNavigatorKey.currentState?.popUntil((r) => r.isFirst);
                              ref.read(settingsPrefsProvider.notifier).jumpTo(i.opens);
                            },
                          )
                        else
                          closeButton,
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
