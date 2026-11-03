// SPDX-License-Identifier: Apache-2.0
// The desktop's settings in a history backup (desktop/data/backup_settings_desk.dart): planned
// and applied over the mock through the desktop's own state (one settings save, the Outputs
// choices, settings.toml's lists and switches, Tor, the wallet's name and items); with other
// wallets here a file whose lists differ asks once, and each answer is applied; and read and
// sealed by the LEPIC adapter over the fake core session, with nothing it must never carry.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/backup_settings.dart';
import 'package:epic_wallet/src/desktop/data/backup_settings_desk.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/settings_file/settings_providers.dart' show hostSettingsProvider;
import 'package:epic_wallet/src/settings_file/host_settings.dart' show hostSettings;
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';

void main() {
  tearDown(() {
    NetGate.set(NetworkMode.standard);
    NetGate.setPayments(PaymentPrefs.defaults);
    NetGate.setExperimental(AdvancedPrefs.none);
  });

  group('over the mock', () {
    late MockDeskWallet mock;
    late ProviderContainer c;
    late DeskBackupSettingsGlue glue;

    setUp(() {
      mock = MockDeskWallet(delay: Duration.zero);
      c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(mock)]);
      glue = DeskBackupSettingsGlue.container(c);
    });

    tearDown(() => c.dispose());

    Future<Map<String, Object?>> file(Map<String, Object?> over, {Map<String, Object?> desk = const {}}) async {
      final d = (await mock.backupSettings()).defaults;
      return jsonDecode(jsonEncode({
        ...d,
        ...over,
        BackupKey.desktop: {...d[BackupKey.desktop]! as Map, ...desk},
      })) as Map<String, Object?>;
    }

    /// The mock's other mainnet wallet gone: this computer has only the open one.
    Future<void> alone() => mock.removeWallet('5a1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f', WalletRemoval.list);

    const nodes = ['https://node.net.invalid:3413', 'http://10.0.0.5:3413'];
    const boxes = ['box.stack.invalid', 'box.epic.invalid'];

    test('a desktop with no other wallet takes the file\'s settings, lists and name without a question; the app follows', () async {
      await alone();
      final settings = await file(
        {
          BackupKey.theme: 'light',
          BackupKey.language: 'de',
          BackupKey.autoLock: BackupKey.never,
          BackupKey.advanced: AdvancedPrefs(features: {AdvancedFeature.outputs}, networkMode: NetworkMode.torOnly).toJson(),
          BackupKey.payments: PaymentPrefs.defaults.copyWith(linkTor: true).toJson(),
          BackupKey.sendStrategy: 'all',
          BackupKey.splitChange: false,
          BackupKey.servers: {BackupKey.node: nodes, BackupKey.epicbox: boxes},
          BackupKey.online: {BackupKey.statusSite: false, BackupKey.updateCheck: false, BackupKey.price: true},
          BackupKey.tor: true,
          BackupKey.seenAs: 'Alice',
        },
        desk: {
          BackupKey.invoiceExpiry: 3600,
          BackupKey.seedsDeleted: ['btlabs'],
          BackupKey.epicboxAutostart: false,
        },
      );
      final plan = await glue.plan(HistoryImport(settings: settings, walletName: 'Savings'));
      expect(plan.conflicts, isEmpty);
      expect(plan.asksServers, isFalse);
      final changed = await glue.apply(plan, takeConflicts: false);
      expect(changed, plan.take.length);

      final s = c.read(deskProvider).settings;
      expect(s.theme, ThemeChoice.light);
      expect(s.language, 'de');
      expect(s.autoLockOn, isFalse);
      expect(s.advanced.networkMode, NetworkMode.torOnly);
      expect(NetGate.torOnly, isTrue, reason: 'the mode reaches the gate at once');
      expect(s.payments.linkTor, isTrue);
      expect(s.pairingSeenAs, 'Alice');
      expect(s.epicboxAutostart, isFalse);
      expect((await mock.settings()).tor, isTrue);
      expect(await mock.outputPrefs(), const OutputPrefs(strategy: SelectionStrategy.all, smartOutputs: false));
      expect(mock.proto.expiry, const Duration(hours: 1));
      expect(mock.seedsDeleted, {'btlabs'});
      expect((await mock.contacts()).any((x) => x.id == 'btlabs'), isFalse);
      final h = c.read(hostSettingsProvider);
      expect(h.nodeUrls, nodes);
      expect(h.epicboxLabels, boxes);
      expect((h.statusEnabled, h.updatesCheck, h.priceEnabled), (false, false, true));
      expect(s.useStatusSite, isFalse);
      // The wallet reopened on the new first servers.
      expect(await mock.epicboxAddress(), endsWith('@box.stack.invalid'));
      expect((await mock.wallets()).firstWhere((w) => w.id == 'legacy-mainnet').name, 'Savings');

      expect((await glue.plan(HistoryImport(settings: settings, walletName: 'Savings'))).isEmpty, isTrue, reason: 'the same file again');
    }, skip: torBuilt ? null : 'no Tor in this build');

    test('another wallet here: lists that differ ask once; keeping this computer\'s changes no server', () async {
      final settings = await file({
        BackupKey.servers: {BackupKey.node: nodes, BackupKey.epicbox: boxes},
      });
      final before = c.read(hostSettingsProvider);
      final plan = await glue.plan(HistoryImport(settings: settings));
      expect(plan.asksServers, isTrue);
      expect({for (final i in plan.servers) i.key}, {BackupItem.nodeServers, BackupItem.epicboxServers});
      expect(plan.conflicts, isEmpty);
      expect(await glue.apply(plan, takeConflicts: false), 0);
      final h = c.read(hostSettingsProvider);
      expect(h.nodeUrls, before.nodeUrls);
      expect(h.epicboxLabels, before.epicboxLabels);
      expect((await glue.plan(HistoryImport(settings: settings))).asksServers, isTrue, reason: 'still the other lists');
    });

    test('another wallet here: using the backup\'s servers writes its lists and moves the wallet', () async {
      final settings = await file({
        BackupKey.servers: {BackupKey.node: nodes, BackupKey.epicbox: boxes},
      });
      final plan = await glue.plan(HistoryImport(settings: settings));
      expect(await glue.apply(plan, takeConflicts: false, takeServers: true), 2);
      final h = c.read(hostSettingsProvider);
      expect(h.nodeUrls, nodes);
      expect(h.epicboxLabels, boxes);
      expect(await mock.epicboxAddress(), endsWith('@box.stack.invalid'));
      expect((await glue.plan(HistoryImport(settings: settings))).isEmpty, isTrue, reason: 'the same lists now: no question');
    });

    test('a desktop the user changed is asked; a local node in the file never becomes the one in use', () async {
      await alone();
      final desk = c.read(deskProvider.notifier);
      await desk.saveSettings(c.read(deskProvider).settings.copyWith(theme: ThemeChoice.system, hideAmounts: false));
      await desk.renameWallet('legacy-mainnet', 'Daily');
      final settings = await file({
        BackupKey.theme: 'light',
        BackupKey.hideBalances: true,
        BackupKey.servers: {
          BackupKey.node: ['http://192.168.1.24:3413'],
          BackupKey.epicbox: c.read(hostSettingsProvider).epicboxLabels,
        },
      });
      final nodesBefore = c.read(hostSettingsProvider).nodeUrls;
      final plan = await glue.plan(HistoryImport(settings: settings, walletName: 'Savings'));
      expect({for (final i in plan.conflicts) i.key}, {BackupItem.theme, BackupItem.walletName});
      expect({for (final i in plan.refused) i.key}, {BackupItem.nodeServers});
      expect(await glue.apply(plan, takeConflicts: false), 1);
      expect(c.read(deskProvider).settings.theme, ThemeChoice.system);
      expect(c.read(deskProvider).settings.hideAmounts, isTrue);
      expect(c.read(hostSettingsProvider).nodeUrls, nodesBefore, reason: 'a list of LAN nodes only is not taken');

      expect(await glue.apply(plan, takeConflicts: true), 3);
      expect(c.read(deskProvider).settings.theme, ThemeChoice.light);
      expect((await mock.wallets()).firstWhere((w) => w.id == 'legacy-mainnet').name, 'Savings');
    });

    test('a phone\'s file: what maps is taken, the phone-only keys are skipped', () async {
      final settings = await file({
        BackupKey.from: 'mobile',
        BackupKey.theme: 'system',
        BackupKey.fiat: 'eur',
        BackupKey.showFiat: false,
        BackupKey.payments: PaymentPrefs.phoneDefaults.copyWith(linkHttp: true).toJson(),
      });
      settings.remove(BackupKey.desktop);
      final plan = await glue.plan(HistoryImport(settings: settings));
      expect(plan.skipped, containsAll([BackupKey.fiat, BackupKey.showFiat]));
      expect(plan.values(takeConflicts: false), {BackupItem.payments: PaymentPrefs.defaults.copyWith(linkHttp: true).toJson()});
    });

    test('an import without settings plans nothing', () async {
      expect((await glue.plan(const HistoryImport())).isEmpty, isTrue);
    });
  });

  group('the LEPIC adapter', () {
    late Directory support;
    late core.FakeWalletService service;
    late LepicDeskWallet wallet;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('desk-backup-settings-test-');
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
      );
      await wallet.createWallet(name: 'Savings', password: _password);
      expect(await wallet.unlock(_password), isTrue);
    });

    tearDown(() async {
      await wallet.dispose();
      await support.delete(recursive: true);
    });

    test('the export carries the settings, settings.toml\'s lists in order and the name; never HTTP, the scale, the built-in node or app-config', () async {
      await wallet.saveSettings((await wallet.settings()).copyWith(theme: ThemeChoice.light, publicMode: true, httpPort: 4000, scale: 125));
      await wallet.addNode(const NodeServer(url: 'https://mine.example:3413', label: 'mine', own: true));
      await wallet.setInvoiceExpiry(const Duration(hours: 2));
      final text = utf8.decode(await wallet.exportHistory());
      final sealed = jsonDecode(text.substring(text.indexOf('{'))) as Map<String, Object?>;
      expect(sealed['walletName'], 'Savings');
      final settings = sealed['settings']! as Map<String, Object?>;
      expect(settings[BackupKey.v], 2);
      expect(settings[BackupKey.from], 'desktop');
      expect(settings[BackupKey.theme], 'light');
      final servers = settings[BackupKey.servers]! as Map<String, Object?>;
      expect(servers[BackupKey.node], hostSettings.nodeUrls);
      expect(servers[BackupKey.node], contains('https://mine.example:3413'));
      expect(servers[BackupKey.epicbox], hostSettings.epicboxLabels);
      expect(settings[BackupKey.online], {BackupKey.statusSite: true, BackupKey.updateCheck: true, BackupKey.price: true});
      final desk = settings[BackupKey.desktop]! as Map<String, Object?>;
      expect(desk[BackupKey.invoiceExpiry], 7200);
      final all = jsonEncode(settings);
      final config = hostSettings.config;
      for (final never in [
        'publicMode', 'httpPort', '4000', 'scale', 'builtin', 'chainData', 'push', 'tourSeen', _password,
        // app-config.toml: never in a backup.
        ?config.statusDirectory, 'operators', 'mainnet',
      ]) {
        expect(all, isNot(contains(never)), reason: never);
      }
    });

    test('the wallet\'s items: a deleted seed contact goes again', () async {
      expect((await wallet.contacts()).any((x) => x.name == 'BT Labs'), isTrue, reason: 'seeded on open');
      await wallet.restoreBackupItems(seedsDeleted: ['btlabs', 'unknown-seed']);
      final desk = (await wallet.backupSettings()).mine[BackupKey.desktop]! as Map<String, Object?>;
      expect(desk[BackupKey.seedsDeleted], ['btlabs']);
      expect((await wallet.contacts()).any((x) => x.name == 'BT Labs'), isFalse);
    });
  });
}
