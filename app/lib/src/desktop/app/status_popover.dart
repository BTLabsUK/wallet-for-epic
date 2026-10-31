// SPDX-License-Identifier: Apache-2.0
/// What a title-bar status icon opens (wallet levels, D5/D10): a popover under that icon with
/// "Name · State", two or three plain rows, a For support group, Copy details and, at Deeper
/// and Deep end, a button to the service's settings. Shallow names the node "Network" and keeps
/// the hosts in the For support group; Deep end adds the height and the version. The Epicbox
/// popover carries the server offer ([DeskRelayOfferPanel]) when there is one.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart' show localInt;
import '../../levels/level_features.dart' show StatusIcon;
import '../../levels/wallet_level.dart';
import '../../ui/common.dart' as common show shortAddress;
import '../data/desk_levels.dart';
import '../data/desk_node.dart';
import '../desk_l10n.dart';
import '../screens/settings/prefs.dart';
import '../widgets/kit.dart';
import 'desk_app.dart' show deskNavigatorKey;
import 'desk_failover.dart';
import 'rail.dart' show RailItem;
import 'relay_offer.dart';

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

typedef _Fact = ({String label, String value, bool mono});

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
    final facts = <_Fact>[];
    final support = <_Fact>[];
    String? sub;
    var body = const <Widget>[];
    switch (i.jump) {
      case SettingsJump.node:
        final url = status?.node.url;
        final info = url == null || url.isEmpty ? null : ref.watch(deskNodeInfoProvider(url)).value;
        final failover = ref.watch(deskFailoverProvider);
        final failoverOn = ref.watch(deskProvider.select((s) => s.settings.advanced.nodeFailover));
        final height = status == null || status.nodeHeight <= 0 ? null : status.nodeHeight;
        final version = info?.version;
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
          if (url != null && url.isNotEmpty) support.add((label: l.netStatusNode, value: _hostPort(url), mono: true));
          if (version != null && version.isNotEmpty) support.add((label: l.lvShellNodeVersion, value: version, mono: false));
          support.add((label: l.deskLvShellFailover, value: l.deskLvShellFailoverAuto, mono: false));
        } else {
          if (i.second != '–' && i.second != i.word) sub = i.second;
          if (deep && height != null) facts.add((label: l.deskLvShellHeight, value: localInt(l, height), mono: false));
          if (deep && version != null && version.isNotEmpty) facts.add((label: l.deskLvShellVersion, value: version, mono: false));
          facts.add((label: l.deskLvShellFailover, value: failoverOn ? l.deskLvShellOn : l.netStatusOff, mono: false));
          support.addAll([for (final line in i.lines) (label: '', value: line, mono: true)]);
        }
      case SettingsJump.epicbox:
        final address = ref.watch(deskProvider.select((s) => s.epicboxAddress));
        final server = status?.epicbox;
        if (address != null && address.isNotEmpty) facts.add((label: l.lvShellAddress, value: common.shortAddress(address, relay: false), mono: true));
        if (shallow) {
          if (i.state == EState.risk || i.state == EState.warn) body = [Text(l.lvShellBoxDownBody, style: ts.small.copyWith(color: c.dim))];
          if (server != null && server.domain.isNotEmpty) support.add((label: l.lvShellServer, value: '${server.domain}:${server.port}', mono: true));
        } else {
          if (server != null && server.domain.isNotEmpty) facts.add((label: l.lvShellServer, value: server.domain, mono: true));
          support.addAll([for (final line in i.lines) (label: '', value: line, mono: true)]);
        }
      default:
        if (i.second != '–' && i.second != i.word) sub = i.second;
        support.addAll([for (final line in i.lines) (label: '', value: line, mono: true)]);
        if (i.note != null) body = [Text(i.note!, style: ts.small.copyWith(color: c.dim))];
    }

    String details() => [
      l.lvShellStatusTip(name, word),
      ?sub,
      for (final f in [...facts, ...support]) f.label.isEmpty ? f.value : '${f.label}: ${f.value}',
    ].join('\n');

    Widget row(_Fact f, {bool small = false}) {
      final style = small ? ts.caption.copyWith(color: c.dim) : ts.small;
      final value = f.mono ? ts.mono(size: small ? Fs.xs : Fs.sm, color: small ? c.dim : c.text) : style.copyWith(color: small ? c.dim : c.text);
      return Padding(
        padding: EdgeInsets.symmetric(vertical: small ? 2.u : 3.u),
        child: f.label.isEmpty
            ? Text(f.value, style: value)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 112.u, child: Text(f.label, style: style.copyWith(color: c.dim))),
                  SizedBox(width: Sp.x2),
                  Expanded(child: Text(f.value, style: value)),
                ],
              ),
      );
    }

    final stateColor = switch (i.state) {
      EState.ok => c.ok,
      EState.active => c.info,
      EState.warn => c.warn,
      EState.risk => c.risk,
      EState.off => c.dim,
    };
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 280.u, maxWidth: 340.u),
      child: Padding(
        padding: EdgeInsets.all(Sp.x3),
        child: Column(
          key: ValueKey('status-pop-${i.jump.name}'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Row(
                key: ValueKey('status-row-${i.jump.name}'),
                children: [
                  Icon(i.icon, size: 18.u, color: c.dim),
                  SizedBox(width: Sp.x2),
                  Text(name, style: ts.strong),
                  Text(' · ', style: ts.strong.copyWith(color: c.faint)), // l10n-ok: separator
                  Flexible(child: Text(word, style: ts.strong.copyWith(color: stateColor))),
                ],
              ),
            ),
            if (sub != null) ...[SizedBox(height: Sp.x1), Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts.mono(size: Fs.xs, color: c.dim))],
            if (body.isNotEmpty) ...[SizedBox(height: Sp.x2), ...body],
            if (facts.isNotEmpty) ...[SizedBox(height: Sp.x2), for (final f in facts) row(f)],
            if (i.jump == SettingsJump.epicbox) DeskRelayOfferPanel(close: close),
            if (support.isNotEmpty) ...[
              SizedBox(height: Sp.x3),
              Text(l.lvShellForSupport, style: ts.caption.copyWith(color: c.faint, fontWeight: FontWeight.w600)),
              SizedBox(height: Sp.x1),
              for (final f in support) row(f, small: true),
            ],
            SizedBox(height: Sp.x3),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: Sp.x2,
              runSpacing: Sp.x2,
              children: [
                EButton(
                  key: ValueKey('status-copy-${i.jump.name}'),
                  label: l.lvShellCopyDetails,
                  icon: EIcons.copy,
                  kind: EBtnKind.ghost,
                  size: EBtnSize.sm,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: details()));
                    final shown = deskNavigatorKey.currentContext;
                    if (shown != null && shown.mounted) showEToast(shown, shown.l10n.lvShellDetailsCopied, tone: ETone.ok);
                  },
                ),
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
                  EButton(key: ValueKey('status-close-${i.jump.name}'), label: l.commonClose, size: EBtnSize.sm, onPressed: close),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// `host:port` of a node URL.
String _hostPort(String url) {
  final u = Uri.tryParse(url.contains('://') ? url : 'http://$url');
  if (u == null || u.host.isEmpty) return url;
  return u.hasPort ? '${u.host}:${u.port}' : u.host;
}
