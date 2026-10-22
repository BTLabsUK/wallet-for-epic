// W4 §0 task 2: per-method on/off and Start with the wallet. LepicDeskWallet over
// FakeWalletSession (one session for every open, so the counts run on); the password is a
// throwaway test value; no tor runs.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const _bundle = TorBundle(binary: '/app/bin/tor-bundle/tor', libDir: '/app/bin/tor-bundle');

void main() {
  late Directory support;
  late core.FakeWalletService service;
  late MemorySecretStore secrets;
  late LepicDeskWallet wallet;
  core.FakeWalletSession session() => service.session;

  LepicDeskWallet make() => LepicDeskWallet(
    service: service,
    walletDir: (chain) async {
      final dir = Directory('${support.path}/wallets/${chain.name}');
      await dir.create(recursive: true);
      return dir.path;
    },
    secrets: secrets,
    filesDir: () async => support,
    nodePoll: const Duration(hours: 1),
    torBundle: () async => _bundle,
    torFeature: true,
  );

  Future<void> httpStarted() async {
    session().httpListenerEvents.add(const core.HttpListenerEvent(kind: core.HttpListenerEventKind.started, port: 3415));
    await pumpEventQueue();
  }

  Future<void> relock() async {
    await wallet.lock();
    expect(await wallet.unlock(_password), isTrue);
    await wallet.startAutostart();
    await pumpEventQueue();
  }

  setUp(() async {
    support = await Directory.systemTemp.createTemp('desk-autostart-test-');
    service = core.FakeWalletService(password: _password);
    secrets = MemorySecretStore();
    wallet = make();
  });

  tearDown(() async {
    await wallet.dispose();
    await support.delete(recursive: true);
  });

  group('one switch per method', () {
    setUp(() async {
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await wallet.unlock(_password), isTrue);
    });

    test('Epicbox off leaves HTTP running', () async {
      await wallet.saveSettings((await wallet.settings()).copyWith(directHttp: true));
      await wallet.setHttpListening(true);
      await httpStarted();
      await wallet.setEpicboxListening(true);
      expect(session().listenerStarts, 1);
      expect((await wallet.status()).epicboxHealth, ServiceHealth.checking);

      await wallet.setEpicboxListening(false);
      expect(session().listenerStops, 1);
      expect(session().httpListenerStops, 0, reason: 'HTTP untouched');
      final st = await wallet.status();
      expect(st.epicboxHealth, ServiceHealth.off);
      expect(st.httpListener, ServiceHealth.ok);
    });

    test('HTTP off leaves Epicbox running', () async {
      await wallet.setEpicboxListening(true);
      await wallet.setHttpListening(true);
      await httpStarted();
      await wallet.setHttpListening(false);
      expect(session().httpListenerStops, 1);
      expect(session().listenerStops, 0, reason: 'Epicbox untouched');
      final st = await wallet.status();
      expect(st.httpListener, ServiceHealth.off);
      expect(st.epicboxHealth, ServiceHealth.checking);
      // On again is Epicbox alone too.
      await wallet.setEpicboxListening(true);
      expect(session().listenerStarts, 1, reason: 'already running: nothing starts twice');
      expect(session().httpListenerStarts, hasLength(1));
    });

    test('Tor off leaves both running', () async {
      await wallet.setEpicboxListening(true);
      await wallet.setHttpListening(true);
      await httpStarted();
      await wallet.setTor(true);
      expect(session().torStarts, hasLength(1));
      await wallet.setTor(false);
      expect(session().torStops, 1);
      expect(session().listenerStops, 0);
      expect(session().httpListenerStops, 0);
    });
  });

  group('Start with the wallet', () {
    setUp(() async {
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await wallet.unlock(_password), isTrue);
    });

    test('defaults: Epicbox on, HTTP off, Tor off', () async {
      final s = await wallet.settings();
      expect((s.epicboxAutostart, s.httpAutostart, s.torAutostart), (true, false, false));
      await wallet.startAutostart();
      expect(session().listenerStarts, 1);
      expect(session().httpListenerStarts, isEmpty);
      expect(session().torStarts, isEmpty);
    });

    test('unlock starts exactly the methods whose autostart is on', () async {
      await wallet.saveSettings((await wallet.settings()).copyWith(epicboxAutostart: false, httpAutostart: true, torAutostart: true));
      await relock();
      expect(session().listenerStarts, 0, reason: 'Epicbox autostart off');
      expect(session().httpListenerStarts, hasLength(1));
      expect(session().torStarts, hasLength(1));
      expect((await wallet.settings()).tor, isTrue, reason: 'Tor is on now');

      await wallet.saveSettings((await wallet.settings()).copyWith(epicboxAutostart: true, httpAutostart: false, torAutostart: false));
      await relock();
      expect(session().listenerStarts, 1);
      expect(session().httpListenerStarts, hasLength(1), reason: 'HTTP autostart off now');
      expect(session().torStarts, hasLength(1), reason: 'Tor autostart off now');
      expect((await wallet.settings()).tor, isFalse, reason: 'Tor on earlier does not start it at unlock');
    });

    test('the choice is the wallet\'s own and survives a relock', () async {
      await wallet.saveSettings((await wallet.settings()).copyWith(epicboxAutostart: false, torAutostart: true));
      await wallet.createWallet(name: 'Savings', password: _password);
      await wallet.lock();
      final all = await wallet.wallets();
      await wallet.selectWallet(all.firstWhere((w) => w.name == 'Savings').id);
      expect(await wallet.unlock(_password), isTrue);
      var s = await wallet.settings();
      expect((s.epicboxAutostart, s.torAutostart), (true, false), reason: 'Savings has the defaults');

      await wallet.lock();
      await wallet.selectWallet(all.firstWhere((w) => w.name == 'Main').id);
      expect(await wallet.unlock(_password), isTrue);
      s = await wallet.settings();
      expect((s.epicboxAutostart, s.torAutostart), (false, true));
    });
  });

  group('migration from 0.1.0', () {
    test('Start Epicbox with the wallet (off) and Tor on carry over once', () async {
      await secrets.write(DeskStore.prefsKey, jsonEncode({'epicboxOnStart': false}));
      await secrets.write(DeskStore.torKey, jsonEncode({'on': true}));
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await wallet.unlock(_password), isTrue);
      final s = await wallet.settings();
      expect((s.epicboxAutostart, s.torAutostart), (false, true));
      expect(jsonDecode((await secrets.read(DeskStore.autostartKey))!), {'epicbox': false, 'tor': true});

      // Saved: a later change of the old choice does not come back.
      await secrets.write(DeskStore.prefsKey, jsonEncode({'epicboxOnStart': true}));
      await wallet.lock();
      expect(await wallet.unlock(_password), isTrue);
      expect((await wallet.settings()).epicboxAutostart, isFalse);
    });

    test('nothing saved: Epicbox on, Tor off', () async {
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await wallet.unlock(_password), isTrue);
      final s = await wallet.settings();
      expect((s.epicboxAutostart, s.torAutostart), (true, false));
    });
  });
}
