// SPDX-License-Identifier: Apache-2.0
// The tray's rules (lib/src/desktop/app/tray/tray_menu.dart): when the window's close hides the
// window instead of quitting, and what the tray's menu, hover text and icon mark say.
import 'package:epic_wallet/src/desktop/app/tray/tray_menu.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/node/local_node_state.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

LocalNodeState _node(LocalNodePhase phase, {int? height, bool stopping = false}) =>
    LocalNodeState(phase: phase, dataFolder: '/data', chainDataPath: '/data/chain_data', at: DateTime(2026, 11, 9), height: height, stopping: stopping);

ServiceStatus _status(ServiceHealth epicbox, {bool blocked = false}) => ServiceStatus(
  node: const NodeServer(url: 'http://127.0.0.1:3413', label: 'Built-in'),
  nodeHealth: ServiceHealth.ok,
  nodeHeight: 3104220,
  epicbox: const EpicboxServer(domain: 'epicbox.epiccash.com'),
  epicboxHealth: epicbox,
  epicboxBlocked: blocked,
  httpListener: ServiceHealth.off,
  tor: ServiceHealth.off,
);

TrayFacts _facts({LocalNodeState? node, bool background = true, bool unlocked = true, bool epicboxMethod = true, ServiceStatus? status}) => TrayFacts(
  node: node,
  background: background,
  unlocked: unlocked,
  settings: DeskSettings(payments: PaymentPrefs(epicbox: epicboxMethod)),
  status: unlocked ? status : null,
);

TrayItem _item(List<TrayItem> menu, String id) => menu.singleWhere((i) => i.id == id);

void main() {
  group('closing the window', () {
    final syncing = _node(LocalNodePhase.syncing);

    test('hides to the tray only with the built-in node running, Sync in background on and a tray', () {
      expect(hidesOnClose(builtin: true, background: true, node: syncing, trayAvailable: true), isTrue);
      expect(hidesOnClose(builtin: false, background: true, node: syncing, trayAvailable: true), isFalse);
      expect(hidesOnClose(builtin: true, background: false, node: syncing, trayAvailable: true), isFalse);
      // No tray (GNOME without AppIndicator): the close quits, never a window with no way back.
      expect(hidesOnClose(builtin: true, background: true, node: syncing, trayAvailable: false), isFalse);
    });

    test('counts starting, syncing and synced as running; stopped, failed, stopping and unknown not', () {
      for (final p in [LocalNodePhase.starting, LocalNodePhase.syncing, LocalNodePhase.synced]) {
        expect(nodeRuns(_node(p)), isTrue, reason: '$p');
        expect(hidesOnClose(builtin: true, background: true, node: _node(p), trayAvailable: true), isTrue, reason: '$p');
      }
      for (final p in [LocalNodePhase.stopped, LocalNodePhase.error]) {
        expect(nodeRuns(_node(p)), isFalse, reason: '$p');
      }
      expect(nodeRuns(_node(LocalNodePhase.syncing, stopping: true)), isFalse);
      expect(nodeRuns(null), isFalse);
      expect(hidesOnClose(builtin: true, background: true, node: null, trayAvailable: true), isFalse);
    });
  });

  group('menu', () {
    test('lists header, node line and switch, Epicbox line and switch, Open, Lock and Quit', () {
      final menu = trayMenu(_l, _facts(node: _node(LocalNodePhase.synced, height: 3104220), status: _status(ServiceHealth.ok)));
      expect(menu.map((i) => i.kind).toList(), [
        TrayItemKind.header,
        TrayItemKind.separator,
        TrayItemKind.status,
        TrayItemKind.item,
        TrayItemKind.separator,
        TrayItemKind.status,
        TrayItemKind.item,
        TrayItemKind.separator,
        TrayItemKind.item,
        TrayItemKind.item,
        TrayItemKind.item,
      ]);
      expect(menu.where((i) => i.id.isNotEmpty).map((i) => i.id).toList(), [TrayIds.background, TrayIds.epicbox, TrayIds.open, TrayIds.lock, TrayIds.quit]);
      expect(menu.where((i) => i.kind != TrayItemKind.item).every((i) => !i.enabled), isTrue);
      expect(menu.every((i) => !i.label.toLowerCase().contains('floonet')), isTrue);
    });

    test('says the node state with its height and marks it', () {
      final synced = trayMenu(_l, _facts(node: _node(LocalNodePhase.synced, height: 3104220)))[2];
      expect(synced.label, contains('3,104,220'));
      expect(synced.label, startsWith('Node: '));
      expect(synced.mark, TrayMark.ready);
      expect(trayMenu(_l, _facts(node: _node(LocalNodePhase.syncing)))[2].mark, TrayMark.busy);
      expect(trayMenu(_l, _facts(node: _node(LocalNodePhase.error, height: 5)))[2].mark, TrayMark.problem);
      expect(trayMenu(_l, _facts(node: _node(LocalNodePhase.error, height: 5)))[2].label, isNot(contains('5')));
      final off = trayMenu(_l, _facts(node: _node(LocalNodePhase.stopped)))[2];
      expect(off.label, _l.deskTrayNode(_l.deskKitMethodOff));
      expect(off.mark, TrayMark.none);
    });

    test('Sync in background is a check item with the setting\'s state', () {
      expect(_item(trayMenu(_l, _facts(background: true)), TrayIds.background).checked, isTrue);
      expect(_item(trayMenu(_l, _facts(background: false)), TrayIds.background).checked, isFalse);
      expect(_item(trayMenu(_l, _facts()), TrayIds.background).label, _l.deskSetNodeBackground);
    });

    test('Epicbox receiving follows the listener and needs an open wallet with the method on', () {
      final on = _item(trayMenu(_l, _facts(status: _status(ServiceHealth.ok))), TrayIds.epicbox);
      expect(on.checked, isTrue);
      expect(on.enabled, isTrue);
      final stopped = _item(trayMenu(_l, _facts(status: _status(ServiceHealth.off))), TrayIds.epicbox);
      expect(stopped.checked, isFalse);
      expect(stopped.enabled, isTrue);
      final locked = trayMenu(_l, _facts(unlocked: false, status: _status(ServiceHealth.ok)));
      expect(_item(locked, TrayIds.epicbox).enabled, isFalse);
      expect(_item(locked, TrayIds.epicbox).checked, isFalse);
      expect(_item(locked, TrayIds.lock).enabled, isFalse);
      expect(locked[5].label, _l.deskTrayEpicbox(_l.deskShellLockedTitle));
      final methodOff = trayMenu(_l, _facts(epicboxMethod: false, status: _status(ServiceHealth.off)));
      expect(_item(methodOff, TrayIds.epicbox).enabled, isFalse);
      expect(methodOff[5].label, _l.deskTrayEpicbox(_l.deskKitMethodOff));
    });

    test('Epicbox line carries the server or the reason, and its mark', () {
      final ok = trayEpicboxState(_l, _facts(status: _status(ServiceHealth.ok)));
      expect(ok.text, contains('epicbox.epiccash.com'));
      expect(ok.mark, TrayMark.ready);
      expect(trayEpicboxState(_l, _facts(status: _status(ServiceHealth.checking))).mark, TrayMark.busy);
      expect(trayEpicboxState(_l, _facts(status: _status(ServiceHealth.down))).mark, TrayMark.problem);
      expect(trayEpicboxState(_l, _facts(status: _status(ServiceHealth.down, blocked: true))).text, contains(_l.deskEpicboxBlockedWord));
    });

    test('Open and Quit are always there and enabled', () {
      for (final f in [_facts(), _facts(unlocked: false), _facts(node: _node(LocalNodePhase.error))]) {
        final menu = trayMenu(_l, f);
        expect(_item(menu, TrayIds.open).enabled, isTrue);
        expect(_item(menu, TrayIds.quit).enabled, isTrue);
      }
    });

    test('a long line is cut to fit', () {
      final long = 'x' * 200;
      final s = ServiceStatus(
        node: const NodeServer(url: 'http://127.0.0.1:3413', label: 'Built-in'),
        nodeHealth: ServiceHealth.ok,
        nodeHeight: 1,
        epicbox: EpicboxServer(domain: '$long.example'),
        epicboxHealth: ServiceHealth.ok,
        httpListener: ServiceHealth.off,
        tor: ServiceHealth.off,
      );
      final line = trayMenu(_l, _facts(status: s))[5].label;
      expect(line.length, trayLineMax);
      expect(line, endsWith('…'));
    });
  });

  group('icon and hover text', () {
    test('marks a node problem, a failing listener, then a sync; synced and quiet has none', () {
      expect(trayIconMark(_l, _facts(node: _node(LocalNodePhase.synced), status: _status(ServiceHealth.ok))), TrayMark.none);
      expect(trayIconMark(_l, _facts(node: _node(LocalNodePhase.syncing), status: _status(ServiceHealth.ok))), TrayMark.busy);
      expect(trayIconMark(_l, _facts(node: _node(LocalNodePhase.error), status: _status(ServiceHealth.ok))), TrayMark.problem);
      expect(trayIconMark(_l, _facts(node: _node(LocalNodePhase.syncing), status: _status(ServiceHealth.down))), TrayMark.problem);
      // A listener the user turned off is no problem.
      expect(trayIconMark(_l, _facts(node: _node(LocalNodePhase.synced), status: _status(ServiceHealth.off))), TrayMark.none);
      // Locked: the listener stopped with the wallet; only the node counts.
      expect(trayIconMark(_l, _facts(node: _node(LocalNodePhase.synced), unlocked: false)), TrayMark.none);
    });

    test('hover text is the app name over the node line', () {
      final tip = trayTooltip(_l, _facts(node: _node(LocalNodePhase.synced, height: 42)));
      expect(tip.split('\n'), [_l.appTitle, trayMenu(_l, _facts(node: _node(LocalNodePhase.synced, height: 42)))[2].label]);
    });
  });
}
