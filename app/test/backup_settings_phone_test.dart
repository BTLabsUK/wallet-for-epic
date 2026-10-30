// SPDX-License-Identifier: Apache-2.0
// The phone's settings in a history backup (ui/backup_settings_phone.dart): collected on one
// phone, planned and applied on a fresh one over the app's own notifiers and store (the server
// lists and switches written into its settings.toml), the questions a changed phone gets, and
// nothing of app-config.toml in the file.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/backup_settings.dart';
import 'package:epic_wallet/src/models.dart' show SelectionStrategy, WalletConfig;
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/pairing_providers.dart' show pairingSeenAsProvider;
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/phone_tor.dart' show PhoneTor;
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart' show statusSite;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/settings_file/network_mode_file.dart' show networkModeIn;
import 'package:epic_wallet/src/settings_file/settings_backend_io.dart';
import 'package:epic_wallet/src/settings_file/settings_controller.dart';
import 'package:epic_wallet/src/settings_file/settings_layout.dart' show configKeys;
import 'package:epic_wallet/src/settings_file/settings_providers.dart';
import 'package:epic_wallet/src/ui/backup_settings_phone.dart';
import 'package:epic_wallet/src/wallet_service.dart' show Chain;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_settings.dart';

const _config = WalletConfig(dataDir: '/w', chain: Chain.mainnet, nodeUrl: 'https://node.lab.invalid', epicboxDomain: 'box.epic.invalid', epicboxPort: 443);

ProviderContainer _phone(MemorySecretStore store, {SettingsFileController? file}) {
  final c = ProviderContainer(overrides: [
    secretStoreProvider.overrideWithValue(store),
    phonePaymentsProvider.overrideWithValue(true),
    if (file != null) settingsFileProvider.overrideWithValue(file),
  ]);
  c.read(walletConfigProvider.notifier).select(_config);
  return c;
}

/// Every text of [config]'s values, in maps and lists too.
Set<String> _texts(Object? v) => switch (v) {
  final String s => {s},
  final List<Object?> l => {for (final e in l) ..._texts(e)},
  final Map<Object?, Object?> m => {for (final e in m.values) ..._texts(e)},
  _ => const {},
};

void main() {
  tearDown(() {
    NetGate.set(NetworkMode.standard);
    NetGate.setPayments(PaymentPrefs.defaults);
    NetGate.setExperimental(AdvancedPrefs.none);
    statusSite.on = true;
  });

  test('collected on one phone, a fresh phone takes it all without a question, lists into its settings.toml', () async {
    final old = _phone(MemorySecretStore());
    addTearDown(old.dispose);
    final n = old.read(appSettingsProvider.notifier);
    await old.read(appSettingsProvider.future);
    await n.setThemeMode(ThemeMode.dark);
    await n.setLanguage('pl');
    await n.setHideBalances(true);
    await n.setAutoLockMinutes(null);
    await n.setFiatCurrency('eur');
    await n.setSendStrategy(SelectionStrategy.all);
    await n.setSplitChange(false);
    await n.setUseStatusSite(false);
    await old.read(hostSettingsProvider.notifier).set('online.price', false);
    await n.setAdvanced(AdvancedPrefs(features: {AdvancedFeature.outputs, AdvancedFeature.pairing}, networkMode: NetworkMode.torOnly));
    await n.setPayments(PaymentPrefs.phoneDefaults.copyWith(linkTor: true, defaultMethod: MethodKind.directQr));
    await old.read(pairingSeenAsProvider.future);
    await old.read(pairingSeenAsProvider.notifier).set('Alice');
    final nodes = ['https://node.net.invalid:3413', 'https://my.node.invalid:3413', 'http://10.0.1.24:3413', 'https://node.lab.invalid'];
    final boxes = ['box.stack.invalid:8443', 'box.epic.invalid'];
    await old.read(hostSettingsProvider.notifier).setAll({'node.servers': nodes, 'epicbox.servers': boxes});
    await old.read(secretStoreProvider).write(PhoneTor.receivingKey(_config), 'true');

    final glue = PhoneBackupSettings.container(old);
    final settings = jsonDecode(jsonEncode(await glue.collect())) as Map<String, Object?>;
    expect(settings[BackupKey.v], 2);
    expect(settings[BackupKey.from], 'mobile');
    expect(settings[BackupKey.servers], {BackupKey.node: nodes, BackupKey.epicbox: boxes});
    expect(settings[BackupKey.online], {BackupKey.statusSite: false, BackupKey.updateCheck: true, BackupKey.price: false});
    expect(settings.keys, isNot(contains('push')));
    expect((settings[BackupKey.advanced] as Map)['networkMode'], 'torOnly', reason: 'the mode travels with the other switches');

    // The fresh phone: its own settings.toml, written from the default copy on first start.
    final dir = await Directory.systemTemp.createTemp('backup-phone-');
    addTearDown(() => dir.delete(recursive: true));
    final file = await SettingsFileController.open(backend: FileSettingsBackend(dir), shippedText: testSettingsText(), config: testConfig());
    addTearDown(file.close);
    final store = MemorySecretStore();
    final fresh = _phone(store, file: file);
    addTearDown(fresh.dispose);
    final moves = <(String, String)>[];
    final apply = PhoneBackupSettings.container(fresh, switchServers: (node, relay) async {
      moves.add((node, relay.label));
      await fresh.read(networkChoiceProvider.notifier).save(mainnetPreset, node, relay: relay);
    });
    final plan = await apply.plan(settings);
    expect(plan.conflicts, isEmpty);
    expect(plan.servers, isEmpty, reason: 'one wallet on a phone: nothing to ask');
    expect(plan.refused, isEmpty, reason: 'the first node is public');
    final changed = await apply.apply(plan, takeConflicts: false);
    expect(changed, plan.take.length);

    final s = await fresh.read(appSettingsProvider.future);
    expect(s.themeMode, ThemeMode.dark);
    expect(s.language, 'pl');
    expect(s.hideBalances, isTrue);
    expect(s.autoLockMinutes, isNull);
    expect(s.fiatCurrency, 'eur');
    expect(s.sendStrategy, SelectionStrategy.all);
    expect(s.splitChange, isFalse);
    expect(s.useStatusSite, isFalse);
    expect(statusSite.on, isFalse);
    expect(s.advanced.networkMode, NetworkMode.torOnly);
    expect(NetGate.torOnly, isTrue, reason: 'the mode reaches the gate at once');
    expect(networkModeIn(file.settings), NetworkMode.torOnly, reason: 'restored into settings.toml');
    expect(File('${dir.path}/settings.toml').readAsStringSync(), contains('mode = "tor_only"'));
    // Linked devices is this phone's own choice, on by default; a file never sets it.
    expect(s.advanced.features, {AdvancedFeature.outputs, AdvancedFeature.pairing, AdvancedFeature.linkedDevices});
    expect(s.payments, PaymentPrefs.phoneDefaults.copyWith(linkTor: true, defaultMethod: MethodKind.directQr));
    expect(await fresh.read(pairingSeenAsProvider.future), 'Alice');
    expect(moves, [('https://node.net.invalid:3413', 'box.stack.invalid:8443')], reason: 'the new first servers move the wallet live');
    expect(await store.read(PhoneTor.receivingKey(_config)), 'true');

    // settings.toml on disk has the lists in the file's order and the switches.
    final written = HostSettings.fromText(await File('${dir.path}/settings.toml').readAsString(), config: testConfig());
    expect(written.nodeUrls, nodes);
    expect(written.epicboxLabels, boxes);
    expect((written.statusEnabled, written.updatesCheck, written.priceEnabled), (false, true, false));

    // The same file again changes nothing (the lists compare in order).
    expect((await apply.plan(settings)).isEmpty, isTrue);
  });

  test('a phone the user changed is asked about its settings; its servers are the file\'s; a LAN node is never first', () async {
    final store = MemorySecretStore();
    final c = _phone(store);
    addTearDown(c.dispose);
    final n = c.read(appSettingsProvider.notifier);
    await c.read(appSettingsProvider.future);
    await n.setThemeMode(ThemeMode.light);
    await n.setAdvanced(AdvancedPrefs.none.withMode(NetworkMode.torOnly));
    await c.read(hostSettingsProvider.notifier).set('node.servers', ['https://node.stack.invalid:3413']);
    final glue = PhoneBackupSettings.container(c);
    final file = {
      ...glue.defaults(),
      BackupKey.theme: 'dark',
      BackupKey.advanced: AdvancedPrefs.none.toJson(),
      BackupKey.hideBalances: true,
      BackupKey.servers: {
        BackupKey.node: ['http://10.0.1.50:3413', 'https://node.net.invalid:3413'],
        BackupKey.epicbox: ['box.epic.invalid'],
      },
    };
    final plan = await glue.plan(file);
    expect({for (final i in plan.conflicts) i.key}, {BackupItem.theme, BackupItem.networkMode});
    expect({for (final i in plan.refused) i.key}, {BackupItem.nodeServers});
    expect(plan.servers, isEmpty);
    // Hide balances, the Node list and the Epicbox list (the test default copy has four).
    expect(await glue.apply(plan, takeConflicts: false), 3);
    final s = await c.read(appSettingsProvider.future);
    expect((s.themeMode, s.advanced.networkMode, s.hideBalances), (ThemeMode.light, NetworkMode.torOnly, true));
    expect(c.read(hostSettingsProvider).nodeUrls, ['https://node.net.invalid:3413', 'http://10.0.1.50:3413'], reason: 'a LAN node is never made the node in use');
    expect(c.read(hostSettingsProvider).epicboxLabels, ['box.epic.invalid']);

    expect(await glue.apply(await glue.plan(file), takeConflicts: true), 2);
    final taken = await c.read(appSettingsProvider.future);
    expect((taken.themeMode, taken.advanced.networkMode), (ThemeMode.dark, NetworkMode.standard));
  });

  test('app-config.toml is never in the file', () async {
    final c = _phone(MemorySecretStore());
    addTearDown(c.dispose);
    final settings = await PhoneBackupSettings.container(c).collect();
    expect(settings.keys.toSet(), {
      BackupKey.v, BackupKey.from, BackupKey.theme, BackupKey.language, BackupKey.helpLanguage, BackupKey.hideBalances,
      BackupKey.autoLock, BackupKey.advanced, BackupKey.payments, BackupKey.sendStrategy, BackupKey.splitChange,
      BackupKey.fiat, BackupKey.showFiat, BackupKey.tor, BackupKey.seenAs, BackupKey.servers, BackupKey.online,
    });
    final h = c.read(hostSettingsProvider);
    final mine = {...h.nodeUrls, ...h.epicboxLabels};
    final json = jsonEncode(settings);
    for (final k in configKeys) {
      for (final t in _texts(h.config.value(k.path))) {
        if (t.length < 4 || mine.any((m) => m.contains(t))) continue;
        expect(json, isNot(contains(t)), reason: k.path);
      }
    }
  });

  test('a file without settings, or a newer one, plans nothing', () async {
    final c = _phone(MemorySecretStore());
    addTearDown(c.dispose);
    final glue = PhoneBackupSettings.container(c);
    expect((await glue.plan(null)).isEmpty, isTrue);
    final newer = {...glue.defaults(), BackupKey.v: backupSettingsVersion + 1, BackupKey.theme: 'dark'};
    expect((await glue.plan(newer)).isEmpty, isTrue);
    expect(await glue.apply(BackupSettingsPlan.empty, takeConflicts: true), 0);
  });
}
