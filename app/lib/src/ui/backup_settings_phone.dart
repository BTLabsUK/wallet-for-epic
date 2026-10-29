// SPDX-License-Identifier: Apache-2.0
/// The phone's side of the settings a history backup carries (`backup_settings.dart`): what it
/// writes into the file, what it has now and what a fresh install has, in the map's form, and
/// applying a plan through the app's own setters, so the running app follows at once (the
/// network mode reaches the gate and Tor, Epicbox off stops the listener, a new first server
/// moves the open wallet as the server pickers do).
///
/// The phone has one wallet: the file's Node and Epicbox lists and `[online]` switches are
/// written to `settings.toml` as they are, as on a fresh install.
library;

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable, ProviderOrFamily;

import '../backup_settings.dart';
import '../log.dart';
import '../models.dart' show SelectionStrategy;
import '../network.dart';
import '../pairing_providers.dart' show PairingSeenAs, pairingSeenAsProvider;
import '../payment_prefs.dart';
import '../phone_tor.dart';
import '../providers.dart';
import '../server_list.dart' show ServerKind;
import '../server_list_file.dart' show withFirst;
import '../server_switch.dart' show switchServersLive;
import '../settings.dart';
import '../settings_file/host_settings.dart' show HostSettings, shippedHostSettings;
import '../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../wallet_service.dart' show WalletError;

export '../backup_settings.dart' show BackupSettingsPlan, BackupSettingItem, BackupItem;

/// The phone's settings for [exportHistory]'s `settings`: everything the file carries.
Future<Map<String, Object?>> collectPhoneBackupSettings(WidgetRef ref) => PhoneBackupSettings.of(ref).collect();

/// What importing [file] (the backup's settings, [ImportReport.settings]) would change here:
/// [BackupSettingsPlan.conflicts] are the settings the user changed that the file has
/// otherwise, the question "Use the settings from this backup?".
Future<BackupSettingsPlan> planPhoneBackupSettings(WidgetRef ref, Map<String, Object?>? file) =>
    PhoneBackupSettings.of(ref).plan(file);

/// Applies [plan]: what it takes silently, and its conflicts when [takeConflicts]. Returns how
/// many settings changed.
Future<int> applyPhoneBackupSettings(WidgetRef ref, BackupSettingsPlan plan, {required bool takeConflicts}) =>
    PhoneBackupSettings.of(ref).apply(plan, takeConflicts: takeConflicts);

/// Moves the wallet onto [nodeUrl] and [relay] (each saved first in its list).
typedef PhoneServerSwitch = Future<void> Function(String nodeUrl, EpicboxRelay relay);

/// The three steps over a provider reader: a widget's ref, or a container in tests.
class PhoneBackupSettings {
  PhoneBackupSettings({required this.read, required this.invalidate, this.switchServers});

  /// Over a widget's [ref]: a server change moves the open wallet live ([switchServersLive]).
  factory PhoneBackupSettings.of(WidgetRef ref) => PhoneBackupSettings(
    read: ref.read,
    invalidate: ref.invalidate,
    switchServers: (node, relay) => switchServersLive(ref, nodeUrl: node, relay: relay),
  );

  /// Over [container]; without [switchServers] a server change is only saved.
  factory PhoneBackupSettings.container(ProviderContainer container, {PhoneServerSwitch? switchServers}) =>
      PhoneBackupSettings(read: container.read, invalidate: container.invalidate, switchServers: switchServers);

  final T Function<T>(ProviderListenable<T> provider) read;
  final void Function(ProviderOrFamily provider) invalidate;
  final PhoneServerSwitch? switchServers;

  /// What the phone has now, in the map's form.
  Future<Map<String, Object?>> collect() async {
    final settings = await read(appSettingsProvider.future);
    final config = read(walletConfigProvider);
    final tor = config != null && await read(secretStoreProvider).read(PhoneTor.receivingKey(config)) == 'true';
    return phoneBackupMap(
      settings,
      hosts: read(hostSettingsProvider),
      tor: tor,
      // The saved name, as typing keeps it (the provider may still be loading).
      seenAs: (await read(secretStoreProvider).read(PairingSeenAs.key) ?? '').trim(),
    );
  }

  /// A fresh install's values, in the map's form.
  Map<String, Object?> defaults() => phoneBackupMap(
    AppSettings(payments: read(phonePaymentsProvider) ? PaymentPrefs.phoneDefaults : PaymentPrefs.defaults),
    hosts: shippedHostSettings,
    tor: false,
    seenAs: '',
  );

  Future<BackupSettingsPlan> plan(Map<String, Object?>? file) async {
    if (file == null) return BackupSettingsPlan.empty;
    return planBackupSettings(here: BackupPlatform.mobile, mine: await collect(), defaults: defaults(), file: file);
  }

  Future<int> apply(BackupSettingsPlan plan, {required bool takeConflicts}) async {
    final v = plan.values(takeConflicts: takeConflicts);
    if (v.isEmpty) return 0;
    final n = read(appSettingsProvider.notifier);
    var changed = 0;

    Future<void> each(String key, Future<void> Function(Object? value) set) async {
      if (!v.containsKey(key)) return;
      await set(v[key]);
      changed++;
    }

    // settings.toml's switches first: the app settings rebuild on the status-site switch, and
    // a rebuild still reading would put back what the setters below write.
    await each(BackupItem.statusSite, (x) => n.setUseStatusSite(x! as bool));
    for (final key in [BackupItem.updateCheck, BackupItem.price]) {
      await each(key, (x) => read(hostSettingsProvider.notifier).set(key, x! as bool));
    }
    await read(appSettingsProvider.future);

    // The network mode first: a stricter one holds before any server is asked.
    final advanced = [BackupItem.features, BackupItem.networkMode, BackupItem.nodeFailover].where(v.containsKey).length;
    if (advanced > 0) {
      final current = (await read(appSettingsProvider.future)).advanced;
      await n.setAdvanced(advancedFromBackup(current, v));
      changed += advanced;
    }
    final payments = v[BackupItem.payments];
    if (payments is Map) {
      await n.setPayments(PaymentPrefs.fromJson(payments));
      changed++;
    }

    await each(BackupItem.theme, (x) => n.setThemeMode(ThemeMode.values.byName(x! as String)));
    await each(BackupItem.language, (x) => n.setLanguage(x as String?));
    await each(BackupItem.helpLanguage, (x) => n.setHelpLanguage(x as String?));
    await each(BackupItem.hideBalances, (x) => n.setHideBalances(x! as bool));
    await each(BackupItem.autoLock, (x) => n.setAutoLockMinutes(autoLockFromBackup(x)));
    await each(BackupItem.sendStrategy, (x) => n.setSendStrategy(SelectionStrategy.values.byName(x! as String)));
    await each(BackupItem.splitChange, (x) => n.setSplitChange(x! as bool));
    await each(BackupItem.fiat, (x) => n.setFiatCurrency(x! as String));
    await each(BackupItem.showFiat, (x) => n.setShowFiat(x! as bool));
    await each(BackupItem.seenAs, (x) async {
      // Loaded first: a load still running would put the old name back over the new one.
      await read(pairingSeenAsProvider.future);
      await read(pairingSeenAsProvider.notifier).set(x! as String);
    });

    // The lists, as the file has them. A new first server moves the open wallet live first;
    // when that is refused the servers in use stay first.
    final nodes = (v[BackupItem.nodeServers] as List?)?.cast<String>();
    final boxes = (v[BackupItem.epicboxServers] as List?)?.cast<String>();
    if (nodes != null || boxes != null) {
      final h = read(hostSettingsProvider);
      final node = nodes?.first;
      final box = boxes?.first;
      var moved = true;
      if ((node != null && node != h.nodeUse) || (box != null && box != h.epicboxUse)) {
        final move = switchServers;
        if (move != null) {
          final choice = await read(networkChoiceProvider.future);
          try {
            await move(node ?? choice.nodeUrl, EpicboxRelay.parse(box ?? '') ?? choice.relay);
          } on WalletError catch (e) {
            moved = false;
            logWarn('backup', 'servers from the backup not used: ${e.kind.name}');
          }
        }
      }
      await read(hostSettingsProvider.notifier).setAll(_listValues(read(hostSettingsProvider), nodes, boxes, keepInUse: !moved));
      changed += [nodes, boxes].nonNulls.length;
    }

    // Tor last: it starts on the servers and in the mode just set.
    final tor = v[BackupItem.tor];
    final config = read(walletConfigProvider);
    if (tor is bool && config != null) {
      if (read(sessionProvider) != null) {
        await read(phoneTorProvider.notifier).setReceiving(tor);
      } else {
        await read(secretStoreProvider).write(PhoneTor.receivingKey(config), '$tor');
      }
      changed++;
    }
    logInfo('backup', 'settings from the backup: $changed changed');
    return changed;
  }
}

/// The `settings.toml` values for [nodes] and [boxes] (each null: not written). With
/// [keepInUse] the servers in use in [now] stay first.
Map<String, Object> _listValues(HostSettings now, List<String>? nodes, List<String>? boxes, {required bool keepInUse}) {
  List<String> list(ServerKind kind, List<String> l, String inUse) => keepInUse && inUse.isNotEmpty ? withFirst(kind, l, inUse) : l;
  return {
    if (nodes != null) BackupItem.nodeServers: list(ServerKind.node, nodes, now.nodeUse),
    if (boxes != null) BackupItem.epicboxServers: list(ServerKind.relay, boxes, now.epicboxUse),
  };
}

/// The phone's settings as the backup map ([BackupKey]); [hosts] gives `settings.toml`'s lists
/// and switches.
Map<String, Object?> phoneBackupMap(AppSettings s, {required HostSettings hosts, required bool tor, required String seenAs}) => {
  BackupKey.v: backupSettingsVersion,
  BackupKey.from: BackupPlatform.mobile.name,
  BackupKey.theme: s.themeMode.name,
  BackupKey.language: s.language,
  BackupKey.helpLanguage: s.helpLanguage,
  BackupKey.hideBalances: s.hideBalances,
  BackupKey.autoLock: autoLockToBackup(s.autoLockMinutes),
  BackupKey.advanced: s.advanced.toJson(),
  BackupKey.payments: s.payments.toJson(),
  BackupKey.sendStrategy: s.sendStrategy.name,
  BackupKey.splitChange: s.splitChange,
  BackupKey.fiat: s.fiatCurrency,
  BackupKey.showFiat: s.showFiat,
  BackupKey.tor: tor,
  BackupKey.seenAs: seenAs,
  ...backupHostSettings(hosts),
};
