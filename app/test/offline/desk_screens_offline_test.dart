// SPDX-License-Identifier: Apache-2.0
// Every desktop screen while an outside service is down — the node, the Epicbox relay, Tor,
// or all of them (no network) — over the mock wallet: no exception, no spinner still turning
// after the wait, a body that is not blank, at most a few notices. Then the service comes
// back and the app shows it by itself (the 5 s status poll), with no offline line left.
import 'dart:async';

import 'package:epic_wallet/src/advanced.dart' show AdvancedFeature;
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/desk_levels.dart' show deskLevelProvider;
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart' show hostSettings;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../desktop/advanced_on.dart';

enum _Down { node, epicbox, tor, everything }

/// The mock wallet with [down] out until [down] is set to null.
class _DownWallet extends MockDeskWallet {
  _DownWallet(this.down) : super(delay: const Duration(milliseconds: 50));

  _Down? down;

  bool get _node => down == _Down.node || down == _Down.everything;
  bool get _box => down == _Down.epicbox || down == _Down.everything;
  bool get _tor => down == _Down.tor || down == _Down.everything;

  @override
  Future<ServiceStatus> status() async {
    final s = await super.status();
    if (down == null) return s;
    return ServiceStatus(
      node: s.node,
      nodeHealth: _node ? ServiceHealth.down : s.nodeHealth,
      nodeHeight: _node ? 0 : s.nodeHeight,
      epicbox: s.epicbox,
      epicboxHealth: _box ? ServiceHealth.down : s.epicboxHealth,
      httpListener: s.httpListener,
      tor: _tor ? ServiceHealth.down : s.tor,
      torProblem: _tor ? 'tor could not connect' : null,
      torCanSend: !_tor && s.torCanSend,
      lastUpdate: _node ? DateTime.now().subtract(const Duration(hours: 2)) : s.lastUpdate,
    );
  }

  @override
  Future<List<NodeServer>> nodes() async => [
    for (final n in await super.nodes())
      _node ? NodeServer(url: n.url, label: n.label, operator: n.operator, health: ServiceHealth.down, own: n.own) : n,
  ];

  @override
  Future<List<EpicboxServer>> epicboxes() async => [
    for (final e in await super.epicboxes())
      _box ? EpicboxServer(domain: e.domain, port: e.port, operator: e.operator, health: ServiceHealth.down) : e,
  ];

  @override
  Future<void> syncNow() async {
    if (_node) throw DeskError.l10n((l) => l.deskErrNodeNoAnswer);
    return super.syncNow();
  }
}

const _routes = [
  DeskRoute.overview,
  DeskRoute.activity,
  DeskRoute.send,
  DeskRoute.receive,
  DeskRoute.importTx,
  DeskRoute.finalize,
  DeskRoute.invoices,
  DeskRoute.invoiceIssue,
  DeskRoute.outputs,
  DeskRoute.contacts,
  DeskRoute.settingsNode,
  DeskRoute.settingsReceiving,
  DeskRoute.settingsPrivacy,
  DeskRoute.settingsInvoices,
  DeskRoute.settingsAppearance,
  DeskRoute.settingsAccount,
  DeskRoute.settingsWallets,
  DeskRoute.settingsPhrase,
  DeskRoute.settingsSecurity,
  DeskRoute.settingsRescan,
  DeskRoute.settingsAdvanced,
  DeskRoute.settingsAbout,
  DeskRoute.settingsHelp,
];

final _offlineWords = RegExp(r'offline|unreachable|not reachable|no answer|did not answer|can.t reach|could not connect', caseSensitive: false);

/// Lines that say "offline" of the recipient or of a mode, never of a service that is down.
final _notAboutUs = RegExp(r'can be offline|when offline|while it is offline|stays offline|Offline is on', caseSensitive: false);

List<String> _texts(Finder within) => [
  for (final e in find.descendant(of: within, matching: find.byType(RichText)).evaluate())
    if ((e.widget as RichText).text.toPlainText().trim() case final t when t.isNotEmpty) t,
];

int _spinners() => find.byWidgetPredicate((w) => w is ProgressIndicator && w.value == null).evaluate().length;

void main() {
  testWidgets('empty Node and Epicbox lists: Overview, Send and Receive say none is set, no "Cannot reach"', (tester) async {
    tester.view.physicalSize = const Size(1280, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final before = hostSettings;
    hostSettings = before.withValues(const {'node.servers': <String>[], 'epicbox.servers': <String>[]});
    addTearDown(() => hostSettings = before);
    // The wallet's view of a session with no servers: neither answers.
    final api = _DownWallet(_Down.everything);
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)], retry: (_, _) => null);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    container.read(deskNavProvider.notifier).reset(DeskRoute.overview);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byKey(const ValueKey('overview-no-node')), findsOneWidget);
    expect(find.textContaining('Cannot reach the node'), findsNothing);
    container.read(deskNavProvider.notifier).go(DeskRoute.send);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byKey(const ValueKey('send-no-node')), findsOneWidget);
    expect(find.text('Node not synced'), findsNothing);
    container.read(deskNavProvider.notifier).go(DeskRoute.receive);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byKey(const ValueKey('rx-no-epicbox')), findsOneWidget);
    expect(find.byKey(const ValueKey('rx-state-epicbox')), findsNothing, reason: 'no "Not answering" line for a server that is not set');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    // Before the test ends: the node failover's wait goes with it.
    container.dispose();
    await tester.pump(const Duration(seconds: 2));
  });

  for (final down in _Down.values) {
    testWidgets('${down.name} down: every screen settles, then it comes back by itself', (tester) async {
      tester.view.physicalSize = const Size(1280, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = _DownWallet(down);
      // Deep end with Invoices on (Advanced › Experimental) and Outputs on, so every page is
      // there to visit: a lower level shows Overview in place of the pages it hides.
      final container = ProviderContainer(
        overrides: [deskApiProvider.overrideWithValue(api), deskLevelProvider.overrideWithValue(WalletLevel.everything)],
        retry: (_, _) => null,
      );
      addTearDown(container.dispose);
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      await tester.runAsync(() => advancedOn(container, only: {AdvancedFeature.outputs, AdvancedFeature.invoices}));
      // What an unlock starts: the 5 s status poll and the change stream.
      unawaited(container.read(deskProvider.notifier).startLive());
      container.read(deskNavProvider.notifier).reset(DeskRoute.overview);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));

      Future<void> wait(int seconds) async {
        for (var i = 0; i < seconds * 4; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
      }

      final problems = <String>[];
      for (final r in _routes) {
        container.read(deskNavProvider.notifier).go(r);
        // Longer than any screen's own wait on the mock, and two status polls.
        await wait(12);
        final e = tester.takeException();
        if (e != null) problems.add('${r.name}: exception ${'$e'.split('\n').first}');
        final spin = _spinners();
        if (spin > 0) problems.add('${r.name}: $spin spinner(s) still turning after 12 s');
        final page = find.byKey(ValueKey(r));
        final body = page.evaluate().isEmpty ? 0 : _texts(page.first).length;
        if (body < 2) problems.add('${r.name}: blank body ($body texts)');
        final toasts = find.byType(SnackBar).evaluate().length;
        if (toasts > 1) problems.add('${r.name}: $toasts toasts');
        final nodeDown = down == _Down.node || down == _Down.everything;
        final boxDown = down == _Down.epicbox || down == _Down.everything;
        // A node that does not answer is not one that syncs.
        if (r == DeskRoute.send && nodeDown && find.text('Node not synced').evaluate().isNotEmpty) problems.add('send: says "Node not synced" for a node that does not answer');
        if (r == DeskRoute.send && down == _Down.node && find.byKey(const ValueKey('send-node-down')).evaluate().isEmpty) problems.add('send: no "Node not answering" notice');
        // The state line says "Not answering"; with no other server to offer, no second notice.
        if ((r == DeskRoute.receive || r == DeskRoute.settingsReceiving) && boxDown && find.text('Epicbox server not answering').evaluate().isNotEmpty) {
          problems.add('${r.name}: "Epicbox server not answering" twice (state line and notice)');
        }
      }
      final st = container.read(deskProvider).status;
      if (down == _Down.node || down == _Down.everything) {
        expect(st?.nodeHealth, ServiceHealth.down, reason: 'the header says the node is down');
      }

      // Back: the next status poll shows it, nothing to press.
      api.down = null;
      await wait(7);
      expect(container.read(deskProvider).status?.nodeHealth, isNot(ServiceHealth.down));
      expect(container.read(deskProvider).status?.epicboxHealth, isNot(ServiceHealth.down));
      for (final r in [DeskRoute.overview, DeskRoute.receive, DeskRoute.send, DeskRoute.settingsNode, DeskRoute.settingsReceiving]) {
        container.read(deskNavProvider.notifier).go(r);
        await wait(4);
        final page = find.byKey(ValueKey(r));
        final stale = page.evaluate().isEmpty ? const <String>[] : _texts(page.first).where((t) => _offlineWords.hasMatch(t) && !_notAboutUs.hasMatch(t)).toList();
        if (stale.isNotEmpty) problems.add('back online, ${r.name}: still says ${stale.take(2).join(' / ')}');
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
      unawaited(container.read(deskProvider.notifier).lock());
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
