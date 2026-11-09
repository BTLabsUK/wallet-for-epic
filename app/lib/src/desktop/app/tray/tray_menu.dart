// SPDX-License-Identifier: Apache-2.0
/// The tray's rules, pure: when closing the window hides it instead of quitting, what the menu
/// says and which mark the icon carries. desk_tray.dart applies them; the hosts
/// (tray_linux.dart, tray_windows.dart) draw them.
///
/// What runs in the background: the built-in node, in use, started (starting, syncing or
/// synced), with Settings › Node › Sync in background on, on a desktop with a tray. Nothing
/// else keeps the app: Epicbox, Link and Tor belong to the open wallet and stop when it locks.
library;

import 'package:flutter/foundation.dart';

import '../../../node/local_node_state.dart';
import '../../data/method_names.dart' show methodLabel;
import '../../data/models.dart';
import '../../desk_l10n.dart';
import '../../screens/settings/settings_node.dart' show localNodeRowText;
import '../../widgets/status.dart' show EState, methodStateLine;
import '../../../text_join.dart';
import '../../../l10n.dart' show localInt;

/// One mark beside a menu line and on the icon's corner: the app's status marks (green solid
/// ready, blue ring in progress, red "!" problem); off has none.
enum TrayMark { none, ready, busy, problem }

enum TrayItemKind { item, separator, header, status }

/// The menu items' ids, sent back by the host when one is chosen.
abstract final class TrayIds {
  static const background = 'background';
  static const epicbox = 'epicbox';
  static const open = 'open';
  static const lock = 'lock';
  static const quit = 'quit';
}

@immutable
class TrayItem {
  const TrayItem(this.label, {this.id = '', this.kind = TrayItemKind.item, this.enabled = true, this.checked, this.mark = TrayMark.none});

  const TrayItem.separator() : this('', kind: TrayItemKind.separator, enabled: false);

  final TrayItemKind kind;
  final String id;
  final String label;
  final bool enabled;

  /// Null: a plain item; true or false: a check item and its state.
  final bool? checked;
  final TrayMark mark;

  @override
  bool operator ==(Object other) =>
      other is TrayItem && other.kind == kind && other.id == id && other.label == label && other.enabled == enabled && other.checked == checked && other.mark == mark;

  @override
  int get hashCode => Object.hash(kind, id, label, enabled, checked, mark);

  @override
  String toString() => '$kind $id "$label"${checked == null ? '' : ' checked=$checked'}${enabled ? '' : ' disabled'} $mark';
}

/// What the menu and the icon are made of, read from the app's state.
@immutable
class TrayFacts {
  const TrayFacts({
    required this.node,
    required this.background,
    required this.unlocked,
    required this.settings,
    this.status,
  });

  /// The built-in node; null before its first state.
  final LocalNodeState? node;

  /// Settings › Node › Sync in background.
  final bool background;

  /// A wallet is open (not the unlock screen nor Welcome).
  final bool unlocked;
  final DeskSettings settings;

  /// The open wallet's services; null while locked or loading.
  final ServiceStatus? status;

  /// The Epicbox method is on in Settings › Transactions.
  bool get epicboxMethod => settings.payments.epicbox;

  /// The wallet's Epicbox listener runs (Settings › Transactions › Epicbox › Receiving).
  bool get epicboxListening => unlocked && status != null && status!.epicboxHealth != ServiceHealth.off;
}

/// The node keeps a process running: started, not stopped nor failed.
bool nodeRuns(LocalNodeState? s) =>
    s != null && !s.stopping && (s.phase == LocalNodePhase.starting || s.phase == LocalNodePhase.syncing || s.phase == LocalNodePhase.synced);

/// Closing the window hides it to the tray: the built-in node is in use and runs, Sync in
/// background is on, and the desktop has a tray to come back by. Otherwise the window's close
/// quits as before.
bool hidesOnClose({required bool builtin, required bool background, required LocalNodeState? node, required bool trayAvailable}) =>
    builtin && background && trayAvailable && nodeRuns(node);

/// The node's state, as Settings says it, with its height when known.
String trayNodeState(AppLocalizations l, LocalNodeState? s) {
  if (s == null || s.phase == LocalNodePhase.stopped) return l.deskKitMethodOff;
  final word = localNodeRowText(l, s);
  final h = s.height;
  return h == null || h == 0 || s.phase == LocalNodePhase.error ? word : metaLine([word, l.deskTrayHeight(localInt(l, h))]);
}

TrayMark trayNodeMark(LocalNodeState? s) => switch (s?.phase) {
  null || LocalNodePhase.stopped => TrayMark.none,
  LocalNodePhase.starting || LocalNodePhase.syncing => TrayMark.busy,
  LocalNodePhase.synced => TrayMark.ready,
  LocalNodePhase.error => TrayMark.problem,
};

TrayMark _markOf(EState s) => switch (s) {
  EState.ok => TrayMark.ready,
  EState.active => TrayMark.busy,
  EState.warn || EState.risk => TrayMark.problem,
  EState.off => TrayMark.none,
};

/// Epicbox's line: the receiving state as Settings › Transactions words it, with the server or
/// the short reason; Wallet locked while no wallet is open (the listener belongs to it).
({String text, TrayMark mark}) trayEpicboxState(AppLocalizations l, TrayFacts f) {
  if (!f.unlocked) return (text: l.deskShellLockedTitle, mark: TrayMark.none);
  if (!f.epicboxMethod) return (text: l.deskKitMethodOff, mark: TrayMark.none);
  final status = f.status;
  if (status == null) return (text: l.deskKitMethodOff, mark: TrayMark.none);
  final line = methodStateLine(l, TxMethod.epicbox, status, f.settings);
  return (text: line.text, mark: _markOf(line.state));
}

/// The icon's corner: a problem with the node or a listener that is on but failing first, a
/// sync under way next; synced and quiet carries no mark.
TrayMark trayIconMark(AppLocalizations l, TrayFacts f) {
  final node = trayNodeMark(f.node);
  if (node == TrayMark.problem) return TrayMark.problem;
  if (f.epicboxListening && trayEpicboxState(l, f).mark == TrayMark.problem) return TrayMark.problem;
  if (node == TrayMark.busy) return TrayMark.busy;
  return TrayMark.none;
}

/// A menu line can hold about this much before the panels cut it.
const int trayLineMax = 64;

String _cut(String s) => s.length <= trayLineMax ? s : '${s.substring(0, trayLineMax - 1)}…';

/// The menu, top to bottom: the app's name, the node's state and its Sync in background
/// switch, Epicbox's state and the wallet's receiving switch, then Open wallet, Lock wallet and
/// Quit.
List<TrayItem> trayMenu(AppLocalizations l, TrayFacts f) {
  final epicbox = trayEpicboxState(l, f);
  return [
    TrayItem(l.appTitle, kind: TrayItemKind.header, enabled: false),
    const TrayItem.separator(),
    TrayItem(_cut(l.deskTrayNode(trayNodeState(l, f.node))), kind: TrayItemKind.status, enabled: false, mark: trayNodeMark(f.node)),
    TrayItem(l.deskSetNodeBackground, id: TrayIds.background, checked: f.background),
    const TrayItem.separator(),
    TrayItem(_cut(l.deskTrayEpicbox(epicbox.text)), kind: TrayItemKind.status, enabled: false, mark: epicbox.mark),
    // The same switch as Settings › Transactions › Epicbox › Receiving: only with a wallet open
    // and the Epicbox method on.
    TrayItem(
      l.deskSetRecvMethodReceiving(methodLabel(l, TxMethod.epicbox)),
      id: TrayIds.epicbox,
      checked: f.epicboxListening,
      enabled: f.unlocked && f.epicboxMethod && f.status != null,
    ),
    const TrayItem.separator(),
    TrayItem(l.deskTrayOpen, id: TrayIds.open),
    TrayItem(l.deskBarLock, id: TrayIds.lock, enabled: f.unlocked),
    TrayItem(l.deskBarQuit, id: TrayIds.quit),
  ];
}

/// The icon's hover text: the app's name and the node's line.
String trayTooltip(AppLocalizations l, TrayFacts f) => '${l.appTitle}\n${l.deskTrayNode(trayNodeState(l, f.node))}';
