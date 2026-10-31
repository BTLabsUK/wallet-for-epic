// SPDX-License-Identifier: Apache-2.0
// Advanced on the desktop: the More link on a transaction, the locked and the disabled Tor
// switch, the sidebar and Overview in Offline and Tor only, Send and Receive held by the network
// mode (File goes on), a pasted onion with Link off, Restore's start height for everyone, and
// the tour's Advanced step.
import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/tour.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/net_mode_view.dart' show deskOfflinePeersProvider;
import 'package:epic_wallet/src/desktop/screens/invoices/invoices_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/restore_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/overview_screen.dart';
import 'package:epic_wallet/src/desktop/data/history_files.dart' show MockDeskHistoryFiles, deskHistoryFilesProvider;
import 'package:epic_wallet/src/desktop/screens/settings/settings_advanced.dart' show advModeConfirmKey;
import 'package:epic_wallet/src/desktop/screens/transfer/finalize_screen.dart' show FinalizeArgs;
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/wallet_service.dart' show FakeWalletSession;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _onion = 'http://pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd.onion';

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
}) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _wallet = MockDeskWallet(delay: Duration.zero);
  _container = ProviderContainer(
    overrides: [deskApiProvider.overrideWithValue(_wallet), deskOfflinePeersProvider.overrideWith((ref) async => peers)],
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

  group('Settings › Privacy', () {
    ESwitch torSwitch(WidgetTester tester) => tester.widget<ESwitch>(find.byKey(const ValueKey('privacy-tor-switch')));

    testWidgets('Standard: the switch is the user’s', (tester) async {
      await _open(tester, DeskRoute.settingsPrivacy);
      expect(torSwitch(tester).onChanged, isNotNull);
      expect(find.byKey(const ValueKey('privacy-mode-line')), findsNothing);
    }, skip: !torBuilt);

    testWidgets('Tor only: on and locked, with a link to Advanced', (tester) async {
      await _open(tester, DeskRoute.settingsPrivacy, advanced: _torOnly);
      expect(torSwitch(tester).value, isTrue);
      expect(torSwitch(tester).onChanged, isNull);
      expect(find.text('Tor only is on in Advanced.'), findsOneWidget);
      await tester.tap(find.text('Open Advanced'));
      await _settle(tester);
      expect(_container.read(deskNavProvider).route, DeskRoute.settingsAdvanced);
    }, skip: !torBuilt);

    testWidgets('Kill switch: disabled, with the reason', (tester) async {
      await _open(tester, DeskRoute.settingsPrivacy, advanced: _kill);
      expect(torSwitch(tester).onChanged, isNull);
      expect(torSwitch(tester).value, isFalse);
      expect(find.text('Off in Kill switch: nothing connects.'), findsOneWidget);
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
    ESegment<TxMethod?> segment(WidgetTester tester, String label) =>
        tester.widget<ESegmented<TxMethod?>>(find.byType(ESegmented<TxMethod?>)).segments.firstWhere((s) => s.label == label);

    testWidgets('Node only: Epicbox is disabled with the reason; File runs and its tooltip says the node is used', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com', amount: '1'), advanced: _offline);
      // D-06 (772eae3ad): Epicbox reads Off with the mode's reason and Send moves to File.
      expect(find.byKey(const ValueKey('send-net-blocked')), findsNothing);
      expect(segment(tester, 'Epicbox').enabled, isFalse);
      expect(segment(tester, 'Epicbox').tooltip, 'Off in Node only.');
      expect(_selected(tester), TxMethod.file);
      expect(segment(tester, 'Direct · File').enabled, isTrue);
      // The note sits under the selector now, not in the segment's tooltip.
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

    testWidgets('Offline with a public node: Link\'s summary gives the Offline reason the banner gives, not the node sync (LNX-15)', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: 'http://203.0.113.5:3415', amount: '1', nodeSync: -1), advanced: _kill);
      expect(find.text('Waiting for the node to sync.'), findsNothing);
      // D-06: Link reads Off with the Kill switch reason, never the node sync, and Send moves to File.
      expect(find.byKey(const ValueKey('send-net-blocked')), findsNothing);
      expect(segment(tester, 'Link').enabled, isFalse);
      expect(segment(tester, 'Link').tooltip, 'Off in Kill switch: nothing connects.');
      expect(_selected(tester), TxMethod.file);
    });

    testWidgets('Offline: an onion in To gives the Offline reason, never Needs Tor with Turn on Tor (LNX-12)', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: 'http://pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd.onion', amount: '1'), advanced: _offline);
      expect(find.byKey(const ValueKey('send-needs-tor')), findsNothing);
      expect(find.text('Turn on Tor'), findsNothing);
      // D-06: Link reads Off with the mode's reason; Send moves to File.
      expect(segment(tester, 'Link').tooltip, 'Off in Node only.');
      expect(_selected(tester), TxMethod.file);
    });

    testWidgets('Node only with a LAN node: a Link send to a LAN address is held too (Link is off), File runs', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: 'http://10.0.1.30:3415', amount: '1'), advanced: _offline, node: 'http://10.100.10.20:3413', peers: 0);
      expect(segment(tester, 'Epicbox').enabled, isFalse);
      expect(segment(tester, 'Link').enabled, isFalse);
      expect(segment(tester, 'Direct · File').enabled, isTrue);
      // D-06: Link reads Off with the mode's reason; Send moves to File.
      expect(segment(tester, 'Link').tooltip, 'Off in Node only.');
      expect(_selected(tester), TxMethod.file);
    });

    testWidgets('Tor only without Tor: the same, with the Tor reason', (tester) async {
      await _open(tester, DeskRoute.send, advanced: _torOnly);
      expect(find.byKey(const ValueKey('send-net-blocked')), findsOneWidget);
      expect(find.text('Waiting for Tor. Tor only is on in Advanced.'), findsWidgets);
      // Tor still starting keeps the chosen method (7acea2920): Epicbox waits for Tor.
      expect(segment(tester, 'Epicbox').enabled, isTrue);
      // A file needs no connection of its own: it goes on while Tor connects.
      expect(segment(tester, 'Direct · File').enabled, isTrue);
      await tester.tap(find.text('Direct · File'));
      await _settle(tester);
      expect(find.byKey(const ValueKey('send-net-blocked')), findsNothing);
    }, skip: !torBuilt);

    testWidgets('Standard: nothing is held', (tester) async {
      await _open(tester, DeskRoute.send);
      expect(find.byKey(const ValueKey('send-net-blocked')), findsNothing);
      expect(segment(tester, 'Epicbox').enabled, isTrue);
    });

    testWidgets('Link receiving off: Link is listed, and a pasted onion picks it for this send', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(), tor: true);
      List<String> labels() => tester.widget<ESegmented<TxMethod?>>(find.byType(ESegmented<TxMethod?>)).segments.map((s) => s.label).toList();
      expect(labels(), ['Epicbox', 'Link', 'Direct · File']);
      await tester.enterText(find.byType(EditableText).first, _onion);
      await _settle(tester);
      expect(labels(), ['Epicbox', 'Link', 'Direct · File']);
      expect(tester.widget<ESegmented<TxMethod?>>(find.byType(ESegmented<TxMethod?>)).value, TxMethod.http);
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

    testWidgets('Advanced › Network: a row per mode, just its name and its info popover; choosing one saves it', (tester) async {
      await _open(tester, DeskRoute.settingsAdvanced);
      expect(rowKeys(), torBuilt ? ['standard', 'torOnly', 'nodeOnly', 'killSwitch'] : ['standard', 'nodeOnly', 'killSwitch']);
      // No explanation in the list: no line under a mode, no section ⓘ of its own.
      expect(find.textContaining('Only the node in use.'), findsNothing);
      // The Kill switch row's ⓘ opens a popover with its text.
      await tester.ensureVisible(find.byKey(const ValueKey('adv-mode-killSwitch')));
      await _settle(tester);
      await tester.tap(find.descendant(of: find.byKey(const ValueKey('adv-mode-killSwitch')), matching: find.byType(EInfoHint)));
      await _settle(tester);
      expect(find.textContaining('The wallet works offline'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('adv-mode-nodeOnly')));
      await tester.tap(find.byKey(const ValueKey('adv-mode-nodeOnly')));
      await _settle(tester);
      expect(_advanced.networkMode, NetworkMode.nodeOnly);
      expect(find.textContaining('Epicbox, Link, price and update checks stop now'), findsNothing);
    });

    testWidgets('a send waiting over Epicbox: Kill switch asks first; Cancel keeps the mode', (tester) async {
      await _open(tester, DeskRoute.settingsAdvanced);
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

    testWidgets('the title bar mark shows off Normal; its popover says what the mode does and Change opens Advanced', (tester) async {
      await _open(tester, DeskRoute.overview, advanced: _offline);
      expect(find.byKey(const ValueKey('bar-net-mode')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('bar-net-mode')), matching: find.text('Node only')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bar-net-mode')));
      await _settle(tester);
      expect(find.text('Only the node in use. Epicbox, Link, updates and price are off.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bar-mode-change')));
      await _settle(tester);
      expect(_container.read(deskNavProvider).route, DeskRoute.settingsAdvanced);
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

    testWidgets('Receive › Transaction files: Post a finished payment reads the text, shows the summary, posts', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') return <String, Object?>{'text': FakeWalletSession.fakeFinishedText(3)};
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await _open(tester, DeskRoute.receive);
      await tester.ensureVisible(find.byKey(const ValueKey('rx-post-finished-open')));
      await tester.tap(find.byKey(const ValueKey('rx-post-finished-open')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('post-finished-dialog')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('post-finished-paste')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('post-finished-summary')), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('post-finished-post')));
      await _settle(tester);
      expect(find.text('Posted'), findsWidgets);
    });

    testWidgets('Receive › Transaction files: the entry is off in Kill switch, with its note', (tester) async {
      await _open(tester, DeskRoute.receive, advanced: _kill);
      expect(find.text('Off in Kill switch: nothing connects here.'), findsOneWidget);
      expect(tester.widget<EButton>(find.byKey(const ValueKey('rx-post-finished-open'))).onPressed, isNull);
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
      expect(_advanced.pairingOn, isFalse);
      expect(find.byType(InvoicesScreen), findsNothing);
      expect(find.byType(OverviewScreen), findsOneWidget);
      expect(find.text('Invoices'), findsNothing);
    });

    testWidgets('on: Invoices in the sidebar and its page', (tester) async {
      await _open(tester, DeskRoute.invoices, advanced: AdvancedPrefs.none.withExperimental(AdvancedFeature.invoices, true));
      expect(find.byType(InvoicesScreen), findsOneWidget);
    });

    testWidgets('Invoices on turns Pairing on; Pairing off turns Invoices off', (tester) async {
      await _open(tester, DeskRoute.settingsAdvanced);
      expect(find.byKey(const ValueKey('adv-exp-rule')), findsOneWidget);
      Future<void> flip(String key) async {
        final row = find.byKey(ValueKey(key));
        await tester.ensureVisible(row);
        await tester.tap(find.descendant(of: row, matching: find.byType(ESwitch)));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await _settle(tester);
      }

      await flip('adv-invoices');
      expect(_advanced.invoicesOn, isTrue);
      expect(_advanced.pairingOn, isTrue);
      await flip('adv-pairing');
      expect(_advanced.pairingOn, isFalse);
      expect(_advanced.invoicesOn, isFalse);
    });
  });
}

/// The method Send's selector holds now.
TxMethod? _selected(WidgetTester tester) => tester.widget<ESegmented<TxMethod?>>(find.byType(ESegmented<TxMethod?>).first).value;
