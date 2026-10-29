// SPDX-License-Identifier: Apache-2.0
// A network that ends the TLS handshake with the Epicbox relay (relay_block.dart) reads as
// blocked on the desktop: the wallet counts the listener's refused handshakes (direct only),
// the status shows one steady state with the relay to offer, Receive says it with one button
// that switches at once, and an ordinary failure, a connection or Tor clear or never set it.
// LepicDeskWallet over FakeWalletSession for the state; MockDeskWallet for the screen. The
// password is a throwaway test value.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/receive_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/net/tor_net.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const _refused = 'could not connect to the relay: received fatal alert: CloseNotify';

core.ListenerEvent _disconnected(String reason) => core.ListenerEvent(kind: core.ListenerEventKind.disconnected, message: 'dropped', reason: reason);

void main() {
  group('The wallet', () {
    late Directory support;
    late core.FakeWalletService service;
    late LepicDeskWallet wallet;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('desk-epicbox-blocked-test-');
      service = core.FakeWalletService(password: _password);
      wallet = LepicDeskWallet(
        service: service,
        walletDir: (chain) async {
          final dir = Directory(WalletRegistry.firstWalletDir(support.path, chain));
          await dir.create(recursive: true);
          return dir.path;
        },
        secrets: MemorySecretStore(),
        filesDir: () async => support,
        nodePoll: const Duration(hours: 1),
        torBundle: () async => const TorBundle(binary: '/app/bin/tor-bundle/tor', libDir: '/app/bin/tor-bundle'),
        torFeature: true,
      );
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await wallet.unlock(_password), isTrue);
      await wallet.setEpicboxListening(true);
      await pumpEventQueue();
    });

    tearDown(() async {
      await wallet.dispose();
      TorNet.useDirect();
      await support.delete(recursive: true);
    });

    Future<void> emit(core.ListenerEvent e) async {
      service.session.listenerEvents.add(e);
      await pumpEventQueue();
    }

    test('two refused handshakes in a row: blocked, with another relay to offer', () async {
      await emit(_disconnected(_refused));
      expect((await wallet.status()).epicboxBlocked, isFalse, reason: 'one is not enough');
      await emit(_disconnected(_refused));
      final s = await wallet.status();
      expect(s.epicboxBlocked, isTrue);
      expect(s.epicboxHealth, ServiceHealth.down);
      expect(s.epicbox.domain, defaultEpicboxHost);
      expect(s.epicboxInstead, isNotNull);
      expect(s.epicboxInstead!.host, isNot(defaultEpicboxHost));
    });

    test('an ordinary failure never reads as blocked', () async {
      for (var i = 0; i < 4; i++) {
        await emit(_disconnected('could not connect to the relay: Connection refused (os error 111)'));
      }
      final s = await wallet.status();
      expect(s.epicboxBlocked, isFalse);
      expect(s.epicboxHealth, ServiceHealth.down);
      expect(s.epicboxInstead, isNull);
    });

    test('a refused handshake between other failures does not add up', () async {
      await emit(_disconnected(_refused));
      await emit(_disconnected('could not connect to the relay: timed out'));
      await emit(_disconnected(_refused));
      expect((await wallet.status()).epicboxBlocked, isFalse);
    });

    test('a connection clears it; the next two start the count again', () async {
      await emit(_disconnected(_refused));
      await emit(_disconnected(_refused));
      expect((await wallet.status()).epicboxBlocked, isTrue);
      await emit(const core.ListenerEvent(kind: core.ListenerEventKind.connected, message: 'listening'));
      var s = await wallet.status();
      expect(s.epicboxBlocked, isFalse);
      expect(s.epicboxHealth, ServiceHealth.ok);
      await emit(_disconnected(_refused));
      expect((await wallet.status()).epicboxBlocked, isFalse);
    });

    test('stays blocked, steady, while the listener keeps failing', () async {
      await emit(_disconnected(_refused));
      await emit(_disconnected(_refused));
      await emit(_disconnected('could not connect to the relay: timed out'));
      final s = await wallet.status();
      expect(s.epicboxBlocked, isTrue);
      expect(s.epicboxHealth, ServiceHealth.down);
    });

    test('over Tor it is never blocked: the network does not see the relay', () async {
      await wallet.setTor(true);
      await pumpEventQueue();
      expect((await wallet.status()).epicboxViaTor, isTrue);
      await emit(_disconnected(_refused));
      await emit(_disconnected(_refused));
      expect((await wallet.status()).epicboxBlocked, isFalse);
    });

    test('a stop clears it', () async {
      await emit(_disconnected(_refused));
      await emit(_disconnected(_refused));
      await wallet.setEpicboxListening(false);
      await pumpEventQueue();
      final s = await wallet.status();
      expect(s.epicboxBlocked, isFalse);
      expect(s.epicboxHealth, ServiceHealth.off);
    });
  });

  group('Receive', () {
    late _Wallet wallet;
    late ProviderContainer container;

    setUp(() {
      wallet = _Wallet();
      container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
    });

    tearDown(() => container.dispose());

    Future<void> show(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: ReceiveScreen())),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('blocked: the word and sentence, one button, the address caption; a tap switches at once', (tester) async {
      wallet.epicboxBlocked = true;
      wallet.epicboxInstead = const EpicboxRelay(host: 'epicbox.stackwallet.com');
      await show(tester);
      expect(find.textContaining('Blocked', findRichText: true), findsOneWidget);
      expect(
        find.textContaining('This network blocks epicbox.epiccash.com. Choose another Epicbox server', findRichText: true),
        findsOneWidget,
      );
      expect(find.widgetWithText(EButton, 'Switch to epicbox.stackwallet.com'), findsOneWidget);
      expect(find.text('Your Epicbox address will change. Share the new one.'), findsOneWidget);
      expect(find.text('Not answering', findRichText: true), findsNothing);
      expect(find.textContaining('Retry', findRichText: true), findsNothing);
      await tester.tap(find.widgetWithText(EButton, 'Switch to epicbox.stackwallet.com'));
      await tester.pumpAndSettle();
      expect(wallet.used, ['epicbox.stackwallet.com']);
      expect(find.textContaining('Blocked', findRichText: true), findsNothing);
    });

    testWidgets('blocked with no other relay left: the sentence, no button', (tester) async {
      wallet.epicboxBlocked = true;
      await show(tester);
      expect(find.textContaining('Blocked', findRichText: true), findsOneWidget);
      expect(find.byType(EButton).evaluate().where((e) => (e.widget as EButton).label.startsWith('Switch to')), isEmpty);
    });

    testWidgets('not blocked: the ordinary down notice stays as it was', (tester) async {
      await show(tester);
      expect(find.textContaining('Blocked', findRichText: true), findsNothing);
    });
  });
}

/// The mock wallet, recording the relay switches.
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<String> used = [];

  @override
  Future<void> useEpicbox(String domain) {
    used.add(domain);
    return super.useEpicbox(domain);
  }
}
