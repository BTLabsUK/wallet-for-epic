// SPDX-License-Identifier: Apache-2.0
// The desktop's settings in a history backup (desktop/data/backup_settings_desk.dart): planned
// and applied over the mock through the desktop's own state (one settings save, the Outputs
// choices, the servers, Tor, the wallet's name and items), and read and sealed by the LEPIC
// adapter over the fake core session, with nothing it must never carry.
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
import 'package:epic_wallet/src/server_list.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epic_wallet/src/network.dart' show EpicboxRelay;
import 'package:epic_wallet/src/settings_file/host_settings.dart' show hostSettings;
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

    test('a fresh desktop takes the file\'s settings and name without a question; the app follows', () async {
      final settings = await file(
        {
          BackupKey.theme: 'light',
          BackupKey.language: 'de',
          BackupKey.autoLock: BackupKey.never,
          BackupKey.advanced: AdvancedPrefs(features: {AdvancedFeature.outputs}, networkMode: NetworkMode.torOnly).toJson(),
          BackupKey.payments: PaymentPrefs.defaults.copyWith(linkTor: true).toJson(),
          BackupKey.sendStrategy: 'all',
          BackupKey.splitChange: false,
          BackupKey.node: {'mainnet': 'https://node.epicnet.us:3413'},
          BackupKey.relay: {'mainnet': 'epicbox.stackwallet.com'},
          BackupKey.nodeList: {'mainnet': serverListJson(const ServerList(entries: ['https://node.epicnet.us:3413', 'http://10.0.0.5:3413']))},
          BackupKey.tor: true,
          BackupKey.seenAs: 'Alice',
        },
        desk: {
          BackupKey.deskNodes: [
            {'url': 'https://mine.example:3413', 'label': 'mine'},
          ],
          BackupKey.invoiceExpiry: 3600,
          BackupKey.seedsDeleted: ['btlabs'],
          BackupKey.epicboxAutostart: false,
        },
      );
      final plan = await glue.plan(HistoryImport(settings: settings, walletName: 'Savings'));
      expect(plan.conflicts, isEmpty);
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
      expect(mock.nodeList.entries, ['https://node.epicnet.us:3413', 'http://10.0.0.5:3413']);
      expect((await mock.nodes()).any((n) => n.url == 'https://mine.example:3413' && n.label == 'mine' && n.own), isTrue);
      expect((await mock.wallets()).firstWhere((w) => w.id == 'legacy-mainnet').name, 'Savings');
      final mine = (await mock.backupSettings()).mine;
      expect(mine[BackupKey.node], {'mainnet': 'https://node.epicnet.us:3413'});
      expect(mine[BackupKey.relay], {'mainnet': 'epicbox.stackwallet.com'});

      expect((await glue.plan(HistoryImport(settings: settings, walletName: 'Savings'))).isEmpty, isTrue, reason: 'the same file again');
    }, skip: torBuilt ? null : 'no Tor in this build');

    test('a desktop the user changed is asked; a local node in the file never becomes the one in use', () async {
      final desk = c.read(deskProvider.notifier);
      await desk.saveSettings(c.read(deskProvider).settings.copyWith(theme: ThemeChoice.system, hideAmounts: false));
      await desk.renameWallet('legacy-mainnet', 'Daily');
      final settings = await file({
        BackupKey.theme: 'light',
        BackupKey.hideBalances: true,
        BackupKey.node: {'mainnet': 'http://10.0.1.24:3413'},
      });
      final plan = await glue.plan(HistoryImport(settings: settings, walletName: 'Savings'));
      expect({for (final i in plan.conflicts) i.key}, {BackupItem.theme, BackupItem.walletName});
      expect({for (final i in plan.refused) i.key}, {BackupItem.node});
      expect(await glue.apply(plan, takeConflicts: false), 1);
      expect(c.read(deskProvider).settings.theme, ThemeChoice.system);
      expect(c.read(deskProvider).settings.hideAmounts, isTrue);
      expect((await mock.backupSettings()).mine[BackupKey.node], {'mainnet': 'https://node.btlabs.uk'});

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

    test('the export carries the settings and the name, never HTTP, the scale or the built-in node', () async {
      await wallet.saveSettings((await wallet.settings()).copyWith(theme: ThemeChoice.light, publicMode: true, httpPort: 4000, scale: 125));
      await wallet.addNode(const NodeServer(url: 'https://mine.example:3413', label: 'mine', own: true));
      await wallet.setInvoiceExpiry(const Duration(hours: 2));
      final text = utf8.decode(await wallet.exportHistory());
      final sealed = jsonDecode(text.substring(text.indexOf('{'))) as Map<String, Object?>;
      expect(sealed['walletName'], 'Savings');
      final settings = sealed['settings']! as Map<String, Object?>;
      expect(settings[BackupKey.from], 'desktop');
      expect(settings[BackupKey.theme], 'light');
      final desk = settings[BackupKey.desktop]! as Map<String, Object?>;
      // The node is in the settings file's Node list, as one the user added (no operator): its
      // label is not kept there.
      expect(desk[BackupKey.deskNodes], [
        {'url': 'https://mine.example:3413', 'label': ''},
      ]);
      expect(desk[BackupKey.invoiceExpiry], 7200);
      final all = jsonEncode(settings);
      for (final never in ['publicMode', 'httpPort', '4000', 'scale', 'builtin', 'chainData', 'push', 'tourSeen', _password]) {
        expect(all, isNot(contains(never)), reason: never);
      }
    });

    test('the wallet\'s items: lists merge, a wallet\'s own relay is not taken, a deleted seed contact goes again', () async {
      // Empty lists in the settings file, so the merge shows only the backup's.
      final before = hostSettings;
      hostSettings = before.withValues({'node.servers': const <Object>[], 'epicbox.servers': const <Object>[]});
      addTearDown(() => hostSettings = before);
      expect((await wallet.contacts()).any((x) => x.name == 'BT Labs'), isTrue, reason: 'seeded on open');
      await wallet.restoreBackupItems(
        nodeList: const ServerList(entries: ['https://node.epicnet.us:3413']),
        relayList: ServerList(entries: const ['epicbox.epicnet.us'], removed: {serverKeyOf(ServerKind.relay, 'epicbox.stackwallet.com')}),
        ownRelay: (relay: 'epicbox.epicnet.us'),
        seedsDeleted: ['btlabs', 'unknown-seed'],
      );
      final mine = (await wallet.backupSettings()).mine;
      final desk = mine[BackupKey.desktop]! as Map<String, Object?>;
      expect(desk[BackupKey.seedsDeleted], ['btlabs']);
      // Every wallet uses the settings' Epicbox server: an older backup's own one is not taken.
      expect(desk[BackupKey.ownRelay], isNull);
      expect(mine[BackupKey.relay], {'mainnet': EpicboxRelay.parse(hostSettings.epicboxUse)!.label});
      expect((mine[BackupKey.nodeList]! as Map)['mainnet'], {'entries': ['https://node.epicnet.us:3413'], 'removed': <Object?>[]});
      final relays = serverListFromJson(ServerKind.relay, (mine[BackupKey.relayList]! as Map)['mainnet'])!;
      expect(relays.removed, {serverKeyOf(ServerKind.relay, 'epicbox.stackwallet.com')});
      expect((await wallet.contacts()).any((x) => x.name == 'BT Labs'), isFalse);
    });
  });
}
