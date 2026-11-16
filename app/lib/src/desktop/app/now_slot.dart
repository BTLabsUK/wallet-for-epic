// SPDX-License-Identifier: Apache-2.0
/// What is going on now, for the status bar (status_bar.dart): progress and events (Offline
/// mode, a scan, an update out or to restart, a payment on its way, new requests, the local node
/// syncing, an update downloading), the most important first; each one opens its screen. Health
/// (a node that does not answer, Epicbox, Tor) is the status lights' part.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../node/local_node_state.dart' show LocalNodePhase;
import '../data/desk_node.dart' show deskLocalNodeProvider, deskNodeNotSyncingProvider, deskRestartLocalNode, deskNodeInfoProvider, deskOwnerSecretProvider, deskOwnStatusProvider, NodeHead, nodeClassOf;
import '../data/desk_update.dart' show DeskUpdatePhase, deskUpdateProvider;
import '../data/desk_update_apply.dart' show deskUpdateApplierProvider;
import '../data/node_view.dart' show localNodeView, digits, syncPercent;
import 'desk_failover.dart' show deskFailoverProvider;
import '../../l10n.dart' show localInt;
import '../../tor_build.dart' show inAppUpdates;
import '../desk_l10n.dart';
import '../screens/settings/prefs.dart';
import '../widgets/kit.dart';
import 'desk_app.dart' show deskNavigatorKey;
import 'update_notice.dart' show deskUpdateAct, deskUpdateWords;

/// One thing that goes on.
@immutable
class NowItem {
  const NowItem({required this.id, required this.icon, required this.tone, required this.title, this.detail, this.hint, this.act = false, this.stacked = false, this.progress, this.onTap});

  /// Stable per kind, so a line that only changes its numbers never animates.
  final String id;
  final IconData icon;
  final ETone tone;
  final String title;

  /// After the title, never cut ("62 %", "2 of 3", "Restart").
  final String? detail;

  /// More words for the tooltip and screen readers only.
  final String? hint;

  /// The detail is the click's action word: in the accent.
  final bool act;

  /// The detail goes under the title, each with the line's whole width (an update: its words
  /// and version must read whole).
  final bool stacked;

  /// 0–1 for a bar under the line; -1 for a bar that moves without a known end.
  final double? progress;
  final VoidCallback? onTap;

  String get words => [detail == null ? title : metaLine([title, detail]), ?hint].join('\n');
}

/// What goes on now, the most important first (the status bar shows two).
List<NowItem> nowItems(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  final s = ref.watch(deskProvider);
  final nav = ref.read(deskNavProvider.notifier);
  final here = ref.watch(deskNavProvider.select((a) => a.route));
  final items = <NowItem>[];
  final status = s.status;
  void go(DeskRoute r, [Object? arg]) {
    deskNavigatorKey.currentState?.popUntil((r) => r.isFirst);
    nav.go(r, arg);
  }

  // A line whose screen is open now says what goes on, and takes no click.
  VoidCallback? to(DeskRoute r, [Object? arg]) => r == here ? null : () => go(r, arg);

  // 1. The network mode is the title bar's mark, not a line here; only Tor only waiting for
  //    Tor is an event (the Tor row below says it).
  // 2. A scan: the one a restore owes, or a Recheck balance.
  final scan = status?.restoreScan;
  if (scan != null) {
    items.add(switch (scan.state) {
      RestoreScanState.running => NowItem(
        id: 'scan',
        icon: EIcons.scan,
        tone: ETone.info,
        title: l.deskSlotScanning,
        detail: scan.percent == null ? null : percentText(l, scan.percent!),
        progress: scan.percent == null ? -1 : scan.percent! / 100,
        hint: DeskRoute.settingsRescan == here ? null : l.deskSlotOpenRecheck, onTap: to(DeskRoute.settingsRescan),
      ),
      // Only waiting: neutral. A mode the user chose holds it: the way to change it is the action.
      RestoreScanState.waiting => scan.offline
          ? NowItem(id: 'scan', icon: EIcons.scan, tone: ETone.info, title: l.deskSlotScanWaits, detail: l.netChangeLink, act: true, onTap: () => ref.read(settingsPrefsProvider.notifier).jumpTo(SettingsJump.network))
          : NowItem(id: 'scan', icon: EIcons.scan, tone: ETone.info, title: l.deskSlotScanWaits, hint: DeskRoute.settingsRescan == here ? null : l.deskSlotOpenRecheck, onTap: to(DeskRoute.settingsRescan)),
      RestoreScanState.failed => NowItem(
        id: 'scan',
        icon: EIcons.scan,
        tone: ETone.warn,
        title: l.deskSlotScanStopped,
        detail: l.deskSlotTryAgain,
        act: true,
        hint: DeskRoute.settingsRescan == here ? null : l.deskSlotOpenRecheck, onTap: to(DeskRoute.settingsRescan),
      ),
    });
  } else if (status?.scanning ?? false) {
    items.add(NowItem(id: 'scan', icon: EIcons.scan, tone: ETone.info, title: l.deskSlotScanning, progress: -1, hint: DeskRoute.settingsRescan == here ? null : l.deskSlotOpenRecheck, onTap: to(DeskRoute.settingsRescan)));
  }
  // 3. An update: out (download it, or the page), to restart, to try again; 8. one downloading.
  final u = ref.watch(deskUpdateProvider);
  NowItem? downloading;
  if (inAppUpdates && u.offered) {
    final w = deskUpdateWords(l, u, byHand: ref.read(deskUpdateApplierProvider)?.byHand ?? false);
    if (u.phase == DeskUpdatePhase.downloading) {
      downloading = NowItem(id: 'update', icon: EIcons.download, tone: ETone.info, title: w.title, progress: u.progress ?? -1);
    } else {
      items.add(
        NowItem(
          id: 'update',
          icon: w.warn ? EIcons.alert : (u.phase == DeskUpdatePhase.available ? EIcons.download : EIcons.restart),
          tone: w.warn ? ETone.warn : ETone.gold,
          title: w.title,
          detail: w.second,
          act: w.act,
          stacked: true,
          hint: w.tip,
          onTap: () => unawaited(deskUpdateAct(context, ref)),
        ),
      );
    }
  }
  // 4. A send under way.
  if (ref.watch(deskSendingProvider) > 0) {
    items.add(NowItem(id: 'sending', icon: EIcons.send, tone: ETone.info, title: l.deskSlotSending, progress: -1, hint: DeskRoute.send == here ? null : l.deskSlotOpenSend, onTap: to(DeskRoute.send)));
  }
  // 5. Payments posted and confirming (never a mining reward, which matures for a day).
  final moving = [
    for (final t in s.txs ?? const <Tx>[])
      if (!t.coinbase && (t.state == TxState.posted || t.state == TxState.confirming)) t,
  ]..sort((a, b) => b.created.compareTo(a.created));
  if (moving.isNotEmpty) {
    final t = moving.first;
    final sent = moving.where((m) => m.direction == TxDirection.sent).length;
    final needed = t.confirmationsNeeded <= 0 ? 1 : t.confirmationsNeeded;
    final done = t.state == TxState.posted ? 0 : t.confirmations.clamp(0, needed);
    // The node refused the payment: the slot says so instead of "on its way".
    final refused = moving.length == 1 && t.state == TxState.posted && t.notPosted;
    final count = l.deskSlotOf(localInt(l, done), localInt(l, needed));
    items.add(
      NowItem(
        id: 'payment',
        icon: t.direction == TxDirection.sent ? EIcons.send : EIcons.receive,
        tone: refused ? ETone.warn : ETone.info,
        title: refused
            ? l.deskSlotNotPosted
            : moving.length > 1
            ? (sent == moving.length ? l.deskSlotPaymentsOut : l.deskSlotPaymentsMoving)
            : t.direction == TxDirection.sent
            ? l.deskSlotPaymentOut
            : l.deskSlotPaymentIn,
        detail: refused ? l.deskTxBroadcastAgain : (t.state == TxState.posted ? l.deskSlotWaitingBlock : count),
        // Subject on line one, state on line two: nothing cut (UD-009).
        stacked: true,
        progress: done / needed,
        hint: DeskRoute.activity == here ? null : l.deskSlotOpenActivity, onTap: to(DeskRoute.activity, t.id),
      ),
    );
  }
  // 6. Invoices to pay are the Invoices tab's count (title_bar.dart), not said twice here.
  // 7. The local node starting or syncing: with a public node standing in, "Using public node ·
  // your node is catching up 29%"; with no progress for a long while, "Your node is not
  // syncing" and a click restarts it.
  if (ref.watch(settingsPrefsProvider.select((p) => p.builtin))) {
    final node = ref.watch(deskLocalNodeProvider).value;
    if (node != null && (node.phase == LocalNodePhase.starting || node.phase == LocalNodePhase.syncing)) {
      final stuck = node.phase == LocalNodePhase.syncing && ref.watch(deskNodeNotSyncingProvider);
      final v = localNodeView(l, node, fallbackUrl: status?.node.url, notSyncing: stuck);
      final standIn = v.standIn;
      items.add(
        stuck
            ? NowItem(
                id: 'node',
                icon: EIcons.node,
                tone: ETone.warn,
                title: l.deskNodeNotSyncing,
                stacked: true,
                hint: l.deskNodeRestart,
                onTap: () => unawaited(deskRestartLocalNode(ref)),
              )
            : NowItem(
                id: 'node',
                icon: EIcons.node,
                tone: ETone.info,
                title: standIn != null ? l.deskNodeUsingPublic : (node.phase == LocalNodePhase.starting ? l.deskSlotNodeStarting : l.deskSlotNodeSyncing),
                detail: standIn != null ? standIn.detail(l) : (node.phase == LocalNodePhase.starting ? null : metaLine([?v.marker, ?v.eta])),
                stacked: true,
                // The share its percent says, else a bar without a known end.
                progress: node.phase == LocalNodePhase.syncing ? node.progress?.overall ?? -1 : -1,
                hint: DeskRoute.settingsNode == here ? null : l.deskRailOpenNode, onTap: to(DeskRoute.settingsNode),
              ),
      );
    }
  }
  // 8. The user's own node syncing: its progress here, its health in the Node light.
  if (!ref.watch(settingsPrefsProvider.select((p) => p.builtin))) {
    final prefs = ref.watch(settingsPrefsProvider);
    final chosen = ref.watch(deskFailoverProvider)?.chosen ?? (prefs.typedNode ?? status?.node)?.url;
    if (chosen != null && nodeClassOf(chosen, mine: prefs.mineNodes.contains(chosen)).own) {
      final info = ref.watch(deskNodeInfoProvider(chosen)).value;
      if (info?.head == NodeHead.syncing) {
        final has = ref.watch(deskOwnerSecretProvider(chosen)).value ?? false;
        final owner = has ? ref.watch(deskOwnStatusProvider((url: chosen, tip: info!.networkHeight))).value : null;
        final behind = info!.blocksBehind;
        items.add(
          NowItem(
            id: 'own-node',
            icon: EIcons.node,
            tone: ETone.info,
            title: l.deskOwnSlotSyncing,
            detail: owner?.progress?.overall != null ? syncPercent(l, owner!.progress!.overall!) : (behind != null && behind > 0 ? l.deskNodeMarkerBehind(digits(l, behind)) : null),
            stacked: true,
            progress: owner?.progress?.overall ?? -1,
            hint: DeskRoute.settingsNode == here ? null : l.deskRailOpenNode, onTap: to(DeskRoute.settingsNode),
          ),
        );
      }
    }
  }
  if (downloading != null) items.add(downloading);
  // 9. A notice from the wallet core (a database being rebuilt).
  final notice = status?.notice;
  if (notice != null && notice.isNotEmpty) {
    items.add(NowItem(id: 'notice', icon: EIcons.info, tone: ETone.info, title: notice));
  }
  return items;
}
