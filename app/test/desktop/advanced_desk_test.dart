// SPDX-License-Identifier: Apache-2.0
// Advanced on the desktop: the More link on a transaction, the locked and the disabled Tor
// switch, the sidebar and Overview in Offline and Tor only, Send and Receive held by the network
// mode (File goes on), a pasted onion with Link off, Restore's start height for everyone, and
// the tour's Advanced step.
import 'dart:convert';

import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/tour.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/net_mode_view.dart' show deskOfflinePeersProvider;
import 'package:epic_wallet/src/desktop/screens/invoices/invoices_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/restore_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/overview_screen.dart';
import 'package:epic_wallet/src/desktop/data/files.dart' show DeskFiles, PickedSlate, deskFilesProvider;
import 'package:epic_wallet/src/desktop/data/history_files.dart' show MockDeskHistoryFiles, deskHistoryFilesProvider;
import 'package:epic_wallet/src/desktop/screens/settings/settings_advanced.dart' show advModeConfirmKey;
import 'package:epic_wallet/src/desktop/screens/transfer/finalize_screen.dart' show FinalizeArgs;
import 'package:epic_wallet/src/desktop/screens/transfer/send_advanced.dart' show ERadioRow;
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/wallet_service.dart' show FakeWalletSession;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _onion = 'http://pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd.onion';

/// The file dialog picking one finished payment.
class _PickFinished implements DeskFiles {
  @override
  Future<String?> pickSlate({required String title}) async => null;

  @override
  Future<List<PickedSlate>> pickSlates({required String title}) async =>
      [(name: 'payment.finished.tx', path: 'payment.finished.tx', bytes: utf8.encode(FakeWalletSession.fakeFinishedText(3)))];
}

late MockDeskWallet _wallet;
late ProviderContainer _container;

Future<void> _open(
  WidgetTester tester,
  DeskRoute route, {
  Object? arg,
  AdvancedPrefs advanced = AdvancedPrefs.none,
  bool tor = false,
  String? node,
  int? peers,
  DeskFiles? files,
}) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _wallet = MockDeskWallet(delay: Duration.zero);
  _container = ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(_wallet),
      deskOfflinePeersProvider.overrideWith((ref) async => peers),
      if (files != null) deskFilesProvider.overrideWithValue(files),
    ],
    retry: (_, _) => null,
  );
  addTearDown(_container.dispose);
  await tester.runAsync(() async {
    if (tor) await _wallet.setTor(true);
    if (node != null) {
      await _wallet.addNode(NodeServer(url: node, label: 'LAN node', health: ServiceHealth.ok, own: true));
      await _wallet.useNode(node);
    }
    final n = _container.read(deskProvider.notifier);
    await n.refresh();
    await n.saveSettings(_container.read(deskProvider).settings.copyWith(advanced: advanced, tor: tor, tourSeen: true));
  });
  _container.read(deskNavProvider.notifier).reset(route, arg);
  await tester.pumpWidget(UncontrolledProviderScope(container: _container, child: const DeskApp()));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

AdvancedPrefs get _advanced => _container.read(deskProvider).settings.advanced;

const _offline = AdvancedPrefs(networkMode: NetworkMode.nodeOnly);
const _kill = AdvancedPrefs(networkMode: NetworkMode.killSwitch);
const _torOnly = AdvancedPrefs(networkMode: NetworkMode.torOnly);

void main() {
  group('transaction details', () {
    testWidgets('Technical details off: a More link shows the rows for this view only', (tester) async {
      await _open(tester, DeskRoute.activity, arg: 36);
      expect(find.text('Kernel'), findsNothing);
      expect(find.byKey(const ValueKey('tx-more')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('tx-more')));
      await tester.tap(find.byKey(const ValueKey('tx-more')));
      await _settle(tester);
      expect(find.text('Kernel'), findsOneWidget);
      expect(find.text('Slate ID'), findsOneWidget);
      expect(find.text('Less'), findsOneWidget);
      expect(_advanced.has(AdvancedFeature.technicalDetails), isFalse, reason: 'the switch stays off');
      await tester.ensureVisible(find.byKey(const ValueKey('tx-more')));
      await tester.tap(find.byKey(const ValueKey('tx-more')));
      await _settle(tester);
      expect(find.text('Kernel'), findsNothing);
    });

    testWidgets('Technical details on: the fold, no More link', (tester) async {
      await _open(tester, DeskRoute.activity, arg: 36, advanced: AdvancedPrefs.all);
      expect(find.byKey(const ValueKey('tx-more')), findsNothing);
      expect(find.text('Technical details'), findsWidgets);
    });
  });

  group('Settings › Network & privacy', () {
    // One Tor control (9dff7df46): Connection mode › Tor only. The Tor for all connections
    // switch and its mode line are gone; the page keeps the mode rows.
    bool selected(WidgetTester tester, NetworkMode m) => tester.widget<ERadioRow>(find.byKey(ValueKey('adv-mode-${m.name}'))).selected;

    testWidgets('Standard: Normal is chosen, no Tor switch', (tester) async {
      await _open(tester, DeskRoute.settingsPrivacy);
      expect(selected(tester, NetworkMode.standard), isTrue);
      expect(selected(tester, NetworkMode.torOnly), isFalse);
      expect(find.byKey(const ValueKey('privacy-tor-switch')), findsNothing);
      expect(find.byKey(const ValueKey('privacy-mode-line')), findsNothing);
    }, skip: !torBuilt);

    testWidgets('Tor only: its row is chosen on the same page, no other Tor control', (tester) async {
      await _open(tester, DeskRoute.settingsPrivacy, advanced: _torOnly);
      expect(selected(tester, NetworkMode.torOnly), isTrue);
      expect(selected(tester, NetworkMode.standard), isFalse);
      expect(find.byKey(const ValueKey('privacy-tor-switch')), findsNothing);
      // No way off to another page (B-03): the mode's radio is on this one.
      expect(find.byKey(const ValueKey('privacy-undercover-change')), findsNothing);
      expect(find.byKey(const ValueKey('adv-mode-standard')), findsOneWidget);
    }, skip: !torBuilt);

    testWidgets('Kill switch: its row is chosen, no Tor switch', (tester) async {
      await _open(tester, DeskRoute.settingsPrivacy, advanced: _kill);
      expect(selected(tester, NetworkMode.killSwitch), isTrue);
      expect(find.byKey(const ValueKey('privacy-tor-switch')), findsNothing);
    }, skip: !torBuilt);
  });

  group('sidebar and Overview', () {
    testWidgets('Kill switch: the rows read Off (Kill switch), Overview marks the balance Last known', (tester) async {
      await _open(tester, DeskRoute.overview, advanced: _kill);
      await tester.tap(find.byKey(const ValueKey('bar-status-node')));
      await _settle(tester);
      expect(find.descendant(of: find.byKey(const ValueKey('status-row-node')), matching: find.text('Off (Kill switch)')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('bar-status-epicbox')));
      await _settle(tester);
      expect(find.descendant(of: find.byKey(const ValueKey('status-row-epicbox')), matching: find.text('Off (Kill switch)')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(find.text('Last known'), findsWidgets);
      expect(find.byKey(const ValueKey('overview-offline')), findsOneWidget);
      expect(find.text('Available to spend'), findsOneWidget, reason: 'the last known balance stays');
    });

    testWidgets('Tor only without Tor: Node and Epicbox read Waiting for Tor', (tester) async {
      await _open(tester, DeskRoute.overview, advanced: _torOnly);
      // The status rows are in the title bar's status list.
      // Waiting for Tor is in progress: its dots pulse, so the menu gets a fixed time to open.
      await tester.tap(find.byKey(const ValueKey('bar-status-epicbox')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('status-row-epicbox')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('status-row-epicbox')), matching: find.text('Waiting for Tor')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('bar-status-node')));
      await _settle(tester);
      expect(find.descendant(of: find.byKey(const ValueKey('status-row-node')), matching: find.text('Waiting for Tor')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(find.byKey(const ValueKey('overview-offline')), findsNothing);
    }, skip: !torBuilt);

    testWidgets('Standard: no Offline mark', (tester) async {
      await _open(tester, DeskRoute.overview);
      expect(find.byKey(const ValueKey('overview-offline')), findsNothing);
    });
  });

  group('Send', () {
    // The address in To decides the method (08897d39a); the mode holds an address with its
    // reason under To, and Pay with a file goes on.
    const epicbox = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';

    testWidgets('Node only: an address is held with the reason; Pay with a file runs and says the node is used', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: epicbox, amount: '1'), advanced: _offline);
      expect(find.byKey(const ValueKey('send-hold-nodeOnly')), findsOneWidget);
      expect(find.text('Node only is on. Only the node connects.'), findsWidgets);
      expect(find.byKey(const ValueKey('send-without-connection')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('send-pay-file')));
      await tester.tap(find.byKey(const ValueKey('send-pay-file')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('send-hold-nodeOnly')), findsNothing);
      expect(find.byKey(const ValueKey('file-offline-node')), findsOneWidget);
      // The note sits in the file form.
      expect(find.text('Uses the node to read the chain and post. For the most privacy, use a local node.'), findsWidgets);
    });

    testWidgets('Offline with a public node: Direct · File is not held by the node sync, and says it uses the node (LNX-7)', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(method: TxMethod.file, amount: '1', nodeSync: -1), advanced: _offline);
      // nodeSync -1: the node does not answer, as when Offline stops polling it.
      expect(find.text('Node not synced'), findsNothing);
      expect(find.byKey(const ValueKey('file-offline-node')), findsOneWidget);
      expect(find.text('Uses the node to read the chain and post. For the most privacy, use a local node.'), findsWidgets);
    });

    testWidgets('Overview: what a sender reports posted leaves Waiting for sender for its own line (LNX-13)', (tester) async {
      await _open(tester, DeskRoute.overview);
      expect(find.text('Sender reports posted'), findsNothing);
      expect(find.textContaining('12.5'), findsWidgets, reason: 'the mock awaits 12.5 EPIC finalization');
      _wallet.addSenderPostedDemo();
      await tester.runAsync(() => _container.read(deskProvider.notifier).refresh());
      await _settle(tester);
      // Its own line (and the row): 7.25 reported, 5.25 still awaiting; Total unchanged.
      expect(find.text('Sender reports posted'), findsWidgets);
      expect(find.textContaining('5.25'), findsWidgets);
      expect(find.textContaining('7.25'), findsWidgets);
    });

    testWidgets('Kill switch with a public node: a Link address gets the Kill switch reason, not the node sync (LNX-15)', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: 'http://203.0.113.5:3415', amount: '1', nodeSync: -1), advanced: _kill);
      expect(find.text('Waiting for the node to sync.'), findsNothing);
      expect(find.byKey(const ValueKey('send-hold-killSwitch')), findsOneWidget);
      expect(find.text('Kill switch is on. Nothing connects.'), findsWidgets);
    });

    testWidgets('Node only: an onion in To gives the Node only reason, never Needs Tor with Turn on Tor (LNX-12)', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: _onion, amount: '1'), advanced: _offline);
      expect(find.byKey(const ValueKey('send-needs-tor')), findsNothing);
      expect(find.text('Turn on Tor'), findsNothing);
      expect(find.byKey(const ValueKey('send-hold-nodeOnly')), findsOneWidget);
    });

    testWidgets('Node only with a LAN node: a Link send to a LAN address is held too, Pay with a file runs', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: 'http://10.0.1.30:3415', amount: '1'), advanced: _offline, node: 'http://10.100.10.20:3413', peers: 0);
      expect(find.byKey(const ValueKey('send-hold-nodeOnly')), findsOneWidget);
      expect(find.byKey(const ValueKey('send-pay-file')), findsOneWidget);
    });

    testWidgets('Tor only without Tor: the Tor reason, and File Transfer still works', (tester) async {
      await _open(tester, DeskRoute.send, advanced: _torOnly);
      expect(find.byKey(const ValueKey('send-net-blocked')), findsOneWidget);
      expect(find.text('Waiting for Tor. Nothing connects until it is ready.'), findsWidgets);
      // A file needs no connection of its own: it goes on while Tor connects.
      expect(find.text('File Transfer still works.'), findsOneWidget);
    }, skip: !torBuilt);

    testWidgets('Standard: nothing is held', (tester) async {
      await _open(tester, DeskRoute.send);
      expect(find.byKey(const ValueKey('send-net-blocked')), findsNothing);
      expect(find.byKey(const ValueKey('send-hold-fix')), findsNothing);
    });

    testWidgets('Link receiving off: a pasted onion is named as off for this send, with the reason', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(), tor: true);
      await tester.enterText(find.byType(EditableText).first, _onion);
      await _settle(tester);
      expect(find.byKey(const ValueKey('send-method-off')), findsOneWidget);
      expect(_container.read(deskProvider).settings.payments.offersFamily(MethodFamily.link), isFalse, reason: 'nothing was switched on');
    }, skip: !torBuilt);
  });

  group('Receive', () {
    testWidgets('Node only: the address stays, a line says Epicbox is off, the Files panel runs and says the node is used', (tester) async {
      await _open(tester, DeskRoute.receive, advanced: _offline);
      expect(find.byKey(const ValueKey('rx-net-blocked')), findsOneWidget);
      expect(find.text('Epicbox is off in Node only.'), findsWidgets);
      expect(find.text('Epicbox address'), findsWidgets);
      expect(find.textContaining('Turned off by the network mode'), findsWidgets);
      expect(find.byKey(tourKey('receive-files')), findsOneWidget);
      expect(find.byKey(const ValueKey('rx-files-offline-node')), findsOneWidget);
      expect(find.text('Uses the node to read the chain and post. For the most privacy, use a local node.'), findsOneWidget);
      for (final button in tester.widgetList<EButton>(find.descendant(of: find.byKey(tourKey('receive-files')), matching: find.byType(EButton)))) {
        expect(button.onPressed, isNotNull, reason: button.label);
      }
    });

    testWidgets('Offline with a LAN node: the Files panel runs without the node line', (tester) async {
      await _open(tester, DeskRoute.receive, advanced: _offline, node: 'http://10.100.10.20:3413');
      expect(find.byKey(const ValueKey('rx-files-offline-node')), findsNothing);
    });

    testWidgets('Tor only without Tor: the Files panel works', (tester) async {
      await _open(tester, DeskRoute.receive, advanced: _torOnly);
      expect(find.byKey(const ValueKey('rx-net-blocked')), findsOneWidget);
      expect(find.byKey(const ValueKey('rx-files-offline-node')), findsNothing);
    }, skip: !torBuilt);

    testWidgets('Standard: no notice', (tester) async {
      await _open(tester, DeskRoute.receive);
      expect(find.byKey(const ValueKey('rx-net-blocked')), findsNothing);
    });
  });

  group('network modes', () {
    List<String> rowKeys() => [
      for (final m in NetworkMode.values)
        if (find.byKey(ValueKey('adv-mode-${m.name}')).evaluate().isNotEmpty) m.name,
    ];

    testWidgets('Network & privacy › Network: a row per mode, just its name and its ⓘ; choosing one saves it', (tester) async {
      await _open(tester, DeskRoute.settingsPrivacy);
      expect(rowKeys(), torBuilt ? ['standard', 'torOnly', 'nodeOnly', 'killSwitch'] : ['standard', 'nodeOnly', 'killSwitch']);
      // No explanation in the list: no line under a mode.
      expect(find.textContaining('Only the node in use.'), findsNothing);
      // The Kill switch row's ⓘ opens the picture of the modes at Kill switch.
      await tester.ensureVisible(find.byKey(const ValueKey('adv-mode-killSwitch')));
      await _settle(tester);
      await tester.tap(find.descendant(of: find.byKey(const ValueKey('adv-mode-killSwitch')), matching: find.byType(EInfoHint)));
      await _settle(tester);
      expect(find.byKey(const ValueKey('net-modes-dialog')), findsOneWidget);
      expect(find.textContaining('Nothing connects, not even the node.'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('adv-mode-nodeOnly')));
      await tester.tap(find.byKey(const ValueKey('adv-mode-nodeOnly')));
      await _settle(tester);
      expect(_advanced.networkMode, NetworkMode.nodeOnly);
      expect(find.textContaining('Epicbox, Link, price and update checks stop now'), findsNothing);
    });

    testWidgets('a send waiting over Epicbox: Kill switch asks first; Cancel keeps the mode', (tester) async {
      await _open(tester, DeskRoute.settingsPrivacy);
      final waiting = _container.read(deskProvider).txs!.where((t) => !t.incoming && t.state == TxState.waitingRecipient && t.method != TxMethod.file).length;
      if (waiting == 0) {
        // The mock holds none: nothing to ask about.
        await tester.ensureVisible(find.byKey(const ValueKey('adv-mode-killSwitch')));
        await tester.tap(find.byKey(const ValueKey('adv-mode-killSwitch')));
        await _settle(tester);
        expect(find.byKey(advModeConfirmKey), findsNothing);
        expect(_advanced.networkMode, NetworkMode.killSwitch);
        return;
      }
      await tester.ensureVisible(find.byKey(const ValueKey('adv-mode-killSwitch')));
      await tester.tap(find.byKey(const ValueKey('adv-mode-killSwitch')));
      await _settle(tester);
      expect(find.byKey(advModeConfirmKey), findsOneWidget);
      expect(find.text('Switch to Kill switch?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(_advanced.networkMode, NetworkMode.standard);
    });

    testWidgets('Normal: no mark in the title bar', (tester) async {
      await _open(tester, DeskRoute.overview);
      expect(find.byKey(const ValueKey('bar-net-mode')), findsNothing);
    });

    testWidgets('the title bar mark shows off Normal; its popover says what the mode does and Change opens Network & privacy', (tester) async {
      await _open(tester, DeskRoute.overview, advanced: _offline);
      expect(find.byKey(const ValueKey('bar-net-mode')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('bar-net-mode')), matching: find.text('Node only')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bar-net-mode')));
      await _settle(tester);
      expect(find.text('Only the node in use. Epicbox, Link, updates and price are off.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bar-mode-change')));
      await _settle(tester);
      expect(_container.read(deskNavProvider).route, DeskRoute.settingsPrivacy);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Node only: Epicbox and Link read Off (Node only) in the status list, the node does not', (tester) async {
      await _open(tester, DeskRoute.overview, advanced: _offline);
      await tester.tap(find.byKey(const ValueKey('bar-status-epicbox')));
      await _settle(tester);
      expect(find.descendant(of: find.byKey(const ValueKey('status-row-epicbox')), matching: find.text('Off (Node only)')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('bar-status-node')));
      await _settle(tester);
      expect(find.descendant(of: find.byKey(const ValueKey('status-row-node')), matching: find.text('Off (Node only)')), findsNothing);
    });

    testWidgets('Kill switch: the Overview marks the balance Last known and shows no fiat value', (tester) async {
      await _open(tester, DeskRoute.overview, advanced: _kill);
      expect(find.text('Last known'), findsWidgets);
      expect(find.textContaining('≈'), findsNothing);
    });

    testWidgets('Kill switch: Activity says the list is the last seen', (tester) async {
      await _open(tester, DeskRoute.activity, advanced: _kill);
      expect(find.byKey(const ValueKey('activity-last-known')), findsOneWidget);
    });

    testWidgets('Receive › Transaction files: Open posts a finished payment', (tester) async {
      await _open(tester, DeskRoute.receive, files: _PickFinished());
      await tester.ensureVisible(find.byKey(const ValueKey('rx-files-open')));
      await tester.tap(find.byKey(const ValueKey('rx-files-open')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await _settle(tester);
      expect(find.byKey(const ValueKey('rx-files-results')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('rx-files-results')), matching: find.textContaining('Payment posted', findRichText: true)), findsOneWidget);
    });

    testWidgets('Finalize under Kill switch ends on Finished, not posted with Save file and Copy', (tester) async {
      await _open(tester, DeskRoute.send);
      final tx = _container.read(deskProvider).txs!.firstWhere((t) => !t.incoming);
      _container.read(deskNavProvider.notifier).go(DeskRoute.finalize, FinalizeArgs(finishedTx: tx));
      await _settle(tester);
      expect(find.text('Finished, not posted'), findsOneWidget);
      expect(find.byKey(const ValueKey('finished-save')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('finished-save')));
      await _settle(tester);
      final files = _container.read(deskHistoryFilesProvider) as MockDeskHistoryFiles;
      expect(files.saved.single, endsWith('.finished.tx'));
    });
  });

  group('Recheck balance, updates and reports', () {
    testWidgets('Offline: Recheck balance is disabled with the reason', (tester) async {
      await _open(tester, DeskRoute.settingsRescan, advanced: _kill);
      expect(find.byKey(const ValueKey('rescan-net-blocked')), findsOneWidget);
      final start = tester.widget<EButton>(find.widgetWithText(EButton, 'Recheck'));
      expect(start.onPressed, isNull);
    });

    testWidgets('Standard: Recheck balance starts', (tester) async {
      await _open(tester, DeskRoute.settingsRescan);
      expect(find.byKey(const ValueKey('rescan-net-blocked')), findsNothing);
      expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Recheck')).onPressed, isNotNull);
      expect(find.text('Delete unconfirmed'), findsNothing, reason: 'behind Recheck from a height');
    });
  });

  group('Restore', () {
    testWidgets('the start height is offered with Advanced off, and reaches the wallet', (tester) async {
      await _open(tester, DeskRoute.restore, arg: RestoreStep.account);
      expect(_advanced.has(AdvancedFeature.recheckFromHeight), isFalse);
      expect(find.byKey(const ValueKey('restore-from-link')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('restore-from-link')));
      await _settle(tester);
      // The phone's choice (GP-031): Date first on mainnet, Block height beside it.
      expect(find.byKey(const ValueKey('start-date-pick')), findsOneWidget);
      await tester.tap(find.text('Block height'));
      await _settle(tester);
      await tester.enterText(find.byKey(const ValueKey('restore-from-height')), 'x12');
      await _settle(tester);
      expect(find.text('Use digits only, or leave it empty.'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('restore-from-height')), '2800000');
      await _settle(tester);
      expect(find.text('Use digits only, or leave it empty.'), findsNothing);
    });
  });

  group('the tour', () {
    test('Advanced comes just before Help', () {
      for (final invoices in [false, true]) {
        final titles = tourStepsFor(invoices: invoices).map((s) => s.title).toList();
        expect(titles[titles.length - 2], 'Advanced');
        expect(titles.last, 'Help');
      }
      final step = tourStepsFor(invoices: false).firstWhere((s) => s.title == 'Advanced');
      expect(step.route, DeskRoute.settingsAdvanced);
      expect(step.targets, ['advanced-top']);
      expect(step.subId, 'subnav-settingsAdvanced');
    });

    test('no step names a hidden part', () {
      final hidden = RegExp('Link|Outputs|Technical|Logs|local node|kernel', caseSensitive: false);
      for (final s in tourStepsFor(invoices: true)) {
        if (s.title == 'Advanced') continue;
        expect(hidden.hasMatch(s.text), isFalse, reason: '${s.title}: ${s.text}');
      }
    });

    testWidgets('with Advanced off every step’s targets exist on its page; the Advanced step switches nothing on', (tester) async {
      // Invoices (Experimental) on, for the tour's Invoices step.
      await _open(tester, DeskRoute.overview, advanced: AdvancedPrefs.none.withExperimental(AdvancedFeature.invoices, true));
      final nav = _container.read(deskNavProvider.notifier);
      final before = _advanced;
      for (final step in tourStepsFor(invoices: true)) {
        nav.go(step.route);
        await _settle(tester);
        for (final id in [...step.targets, step.navId, ?step.subId]) {
          expect(find.byKey(tourKey(id)), findsOneWidget, reason: '${step.title}: $id');
        }
      }
      expect(_advanced, before);
    });
  });

  group('experimental', () {
    testWidgets('off by default: no Invoices in the sidebar, an invoice place reads as Overview', (tester) async {
      await _open(tester, DeskRoute.invoices);
      expect(_advanced.invoicesOn, isFalse);
      expect(find.byType(InvoicesScreen), findsNothing);
      expect(find.byType(OverviewScreen), findsOneWidget);
      expect(find.text('Invoices'), findsNothing);
    });

    testWidgets('on: Invoices in the sidebar and its page', (tester) async {
      await _open(tester, DeskRoute.invoices, advanced: AdvancedPrefs.none.withExperimental(AdvancedFeature.invoices, true));
      expect(find.byType(InvoicesScreen), findsOneWidget);
    });

    testWidgets('Invoices has its switch; Pairing has none (always on)', (tester) async {
      await _open(tester, DeskRoute.settingsAdvanced);
      expect(find.byKey(const ValueKey('adv-exp-rule')), findsNothing);
      expect(find.byKey(const ValueKey('adv-pairing')), findsNothing);
      final row = find.byKey(const ValueKey('adv-invoices'));
      await tester.ensureVisible(row);
      await tester.tap(find.descendant(of: row, matching: find.byType(ESwitch)));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _settle(tester);
      expect(_advanced.invoicesOn, isTrue);
      expect(_advanced.pairingOn, isTrue);
    });
  });
}
