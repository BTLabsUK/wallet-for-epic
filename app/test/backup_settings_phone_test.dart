// The phone's settings in a history backup (ui/backup_settings_phone.dart): collected on one
// phone, planned and applied on a fresh one over the app's own notifiers and store, and the
// questions a changed phone gets.
import 'dart:convert';

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
import 'package:epic_wallet/src/server_list_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/backup_settings_phone.dart';
import 'package:epic_wallet/src/wallet_service.dart' show Chain;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _config = WalletConfig(dataDir: '/w', chain: Chain.mainnet, nodeUrl: 'https://node.epiccash.com:3413', epicboxDomain: 'epicbox.epiccash.com', epicboxPort: 443);

ProviderContainer _phone(MemorySecretStore store) {
  final c = ProviderContainer(overrides: [
    secretStoreProvider.overrideWithValue(store),
    phonePaymentsProvider.overrideWithValue(true),
  ]);
  c.read(walletConfigProvider.notifier).select(_config);
  return c;
}

void main() {
  tearDown(() {
    NetGate.set(NetworkMode.standard);
    NetGate.setPayments(PaymentPrefs.defaults);
    NetGate.setExperimental(AdvancedPrefs.none);
    statusSite.on = true;
  });

  test('collected on one phone, a fresh phone takes it all without a question', () async {
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
    await n.setAdvanced(AdvancedPrefs(features: {AdvancedFeature.outputs, AdvancedFeature.pairing}, networkMode: NetworkMode.torOnly));
    await n.setPayments(PaymentPrefs.phoneDefaults.copyWith(linkTor: true, defaultMethod: MethodKind.directQr));
    await old.read(pairingSeenAsProvider.future);
    await old.read(pairingSeenAsProvider.notifier).set('Alice');
    await old.read(networkChoiceProvider.notifier).save(mainnetPreset, 'https://node.btlabs.uk', relay: const EpicboxRelay(host: 'epicbox.stackwallet.com'));
    await old.read(serverListProvider((ServerKind.node, Chain.mainnet)).notifier).add('https://my.node.example:3413');
    await old.read(serverListProvider((ServerKind.node, Chain.mainnet)).notifier).add('http://10.0.1.24:3413');
    await old.read(secretStoreProvider).write(PhoneTor.receivingKey(_config), 'true');

    final glue = PhoneBackupSettings.container(old);
    final settings = jsonDecode(jsonEncode(await glue.collect())) as Map<String, Object?>;
    expect(settings[BackupKey.from], 'mobile');
    expect(settings.keys, isNot(contains('push')));

    final store = MemorySecretStore();
    final fresh = _phone(store);
    addTearDown(fresh.dispose);
    final moves = <(String, String)>[];
    final apply = PhoneBackupSettings.container(fresh, switchServers: (node, relay) async {
      moves.add((node, relay.label));
      await fresh.read(networkChoiceProvider.notifier).save(mainnetPreset, node, relay: relay);
    });
    final plan = await apply.plan(settings);
    expect(plan.conflicts, isEmpty);
    expect(plan.refused, isEmpty, reason: 'the node in use is public');
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
    // Linked devices is this phone's own choice, on by default; a file never sets it.
    expect(s.advanced.features, {AdvancedFeature.outputs, AdvancedFeature.pairing, AdvancedFeature.linkedDevices});
    expect(s.payments, PaymentPrefs.phoneDefaults.copyWith(linkTor: true, defaultMethod: MethodKind.directQr));
    expect(await fresh.read(pairingSeenAsProvider.future), 'Alice');
    expect(moves, [('https://node.btlabs.uk', 'epicbox.stackwallet.com')]);
    final choice = await fresh.read(networkChoiceProvider.future);
    expect((choice.nodeUrl, choice.relay.label), ('https://node.btlabs.uk', 'epicbox.stackwallet.com'));
    final nodes = await fresh.read(serverListProvider((ServerKind.node, Chain.mainnet)).future);
    expect(nodes.entries, containsAll(['https://my.node.example:3413', 'http://10.0.1.24:3413']));
    expect(await store.read(PhoneTor.receivingKey(_config)), 'true');

    // The same file again changes nothing.
    expect((await apply.plan(settings)).isEmpty, isTrue);
  });

  test('a phone the user changed is asked; Keep mine takes only the rest', () async {
    final store = MemorySecretStore();
    final c = _phone(store);
    addTearDown(c.dispose);
    final n = c.read(appSettingsProvider.notifier);
    await c.read(appSettingsProvider.future);
    await n.setThemeMode(ThemeMode.light);
    await n.setAdvanced(AdvancedPrefs.none.withMode(NetworkMode.torOnly));
    final glue = PhoneBackupSettings.container(c);
    final file = {
      ...glue.defaults(Chain.mainnet),
      BackupKey.theme: 'dark',
      BackupKey.advanced: AdvancedPrefs.none.toJson(),
      BackupKey.hideBalances: true,
      BackupKey.node: {'mainnet': 'http://10.0.1.50:3413'},
    };
    final plan = await glue.plan(file);
    expect({for (final i in plan.conflicts) i.key}, {BackupItem.theme, BackupItem.networkMode});
    expect({for (final i in plan.refused) i.key}, {BackupItem.node});
    expect(await glue.apply(plan, takeConflicts: false), 1);
    final s = await c.read(appSettingsProvider.future);
    expect((s.themeMode, s.advanced.networkMode, s.hideBalances), (ThemeMode.light, NetworkMode.torOnly, true));
    expect((await c.read(networkChoiceProvider.future)).nodeUrl, mainnetPreset.nodeUrl, reason: 'a LAN node is never made the node in use');

    expect(await glue.apply(await glue.plan(file), takeConflicts: true), 2);
    final taken = await c.read(appSettingsProvider.future);
    expect((taken.themeMode, taken.advanced.networkMode), (ThemeMode.dark, NetworkMode.standard));
  });

  test('a file without settings, or a newer one, plans nothing', () async {
    final c = _phone(MemorySecretStore());
    addTearDown(c.dispose);
    final glue = PhoneBackupSettings.container(c);
    expect((await glue.plan(null)).isEmpty, isTrue);
    final newer = {...glue.defaults(Chain.mainnet), BackupKey.v: backupSettingsVersion + 1, BackupKey.theme: 'dark'};
    expect((await glue.plan(newer)).isEmpty, isTrue);
    expect(await glue.apply(BackupSettingsPlan.empty, takeConflicts: true), 0);
  });
}
