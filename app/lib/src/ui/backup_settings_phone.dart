/// The phone's side of the settings a history backup carries (`backup_settings.dart`): what it
/// writes into the file, what it has now and what a fresh install has, in the map's form, and
/// applying a plan through the app's own setters, so the running app follows at once (the
/// network mode reaches the gate and Tor, Epicbox off stops the listener, a relay or node
/// change moves the open wallet as the server pickers do).
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
import '../server_list_store.dart';
import '../server_switch.dart' show switchServersLive;
import '../settings.dart';
import '../wallet_service.dart' show Chain, WalletError;

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

/// Moves the wallet onto [nodeUrl] and [relay] (saved as the current network's servers).
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

  Future<Chain> _chain() async => read(walletConfigProvider)?.chain ?? (await read(networkChoiceProvider.future)).preset.chain;

  /// What the phone has now, in the map's form.
  Future<Map<String, Object?>> collect() async {
    final settings = await read(appSettingsProvider.future);
    final choice = await read(networkChoiceProvider.future);
    final chain = await _chain();
    final config = read(walletConfigProvider);
    final tor = config != null && await read(secretStoreProvider).read(PhoneTor.receivingKey(config)) == 'true';
    return phoneBackupMap(
      settings,
      chain: chain,
      node: choice.preset.chain == chain ? choice.nodeUrl : null,
      relay: choice.preset.chain == chain ? choice.relay.label : null,
      nodeList: await read(serverListProvider((ServerKind.node, chain)).future),
      relayList: await read(serverListProvider((ServerKind.relay, chain)).future),
      tor: tor,
      // The saved name, as typing keeps it (the provider may still be loading).
      seenAs: (await read(secretStoreProvider).read(PairingSeenAs.key) ?? '').trim(),
    );
  }

  /// A fresh install's values on [chain], in the map's form.
  Map<String, Object?> defaults(Chain chain) {
    final preset = networkPresets.firstWhere((p) => p.chain == chain);
    return phoneBackupMap(
      AppSettings(payments: read(phonePaymentsProvider) ? PaymentPrefs.phoneDefaults : PaymentPrefs.defaults),
      chain: chain,
      node: preset.nodeUrl,
      relay: preset.defaultRelay.label,
      nodeList: ServerList.seed(ServerKind.node, builtInValues(ServerKind.node, chain)),
      relayList: ServerList.seed(ServerKind.relay, builtInValues(ServerKind.relay, chain)),
      tor: false,
      seenAs: '',
    );
  }

  Future<BackupSettingsPlan> plan(Map<String, Object?>? file) async {
    if (file == null) return BackupSettingsPlan.empty;
    final chain = await _chain();
    return planBackupSettings(here: BackupPlatform.mobile, chain: chain.name, mine: await collect(), defaults: defaults(chain), file: file);
  }

  Future<int> apply(BackupSettingsPlan plan, {required bool takeConflicts}) async {
    final v = plan.values(takeConflicts: takeConflicts);
    if (v.isEmpty) return 0;
    final n = read(appSettingsProvider.notifier);
    final chain = await _chain();
    var changed = 0;

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

    Future<void> each(String key, Future<void> Function(Object? value) set) async {
      if (!v.containsKey(key)) return;
      await set(v[key]);
      changed++;
    }

    await each(BackupItem.theme, (x) => n.setThemeMode(ThemeMode.values.byName(x! as String)));
    await each(BackupItem.language, (x) => n.setLanguage(x as String?));
    await each(BackupItem.helpLanguage, (x) => n.setHelpLanguage(x as String?));
    await each(BackupItem.hideBalances, (x) => n.setHideBalances(x! as bool));
    await each(BackupItem.statusSite, (x) => n.setUseStatusSite(x! as bool));
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

    // The lists: merged again with what they hold now, so nothing added meanwhile is lost.
    for (final (item, kind) in [(BackupItem.nodeList, ServerKind.node), (BackupItem.relayList, ServerKind.relay)]) {
      final from = serverListFromJson(kind, v[item]);
      if (from == null) continue;
      final provider = serverListProvider((kind, chain));
      final now = await read(provider.future);
      final next = mergeServerLists(kind, now, from);
      if (next != now) {
        await read(secretStoreProvider).write(serverListKey(kind, chain), next.encode());
        invalidate(provider);
      }
      changed++;
    }

    // The servers in use: one move for both.
    if (v.containsKey(BackupItem.node) || v.containsKey(BackupItem.relay)) {
      final choice = await read(networkChoiceProvider.future);
      final node = v[BackupItem.node] as String? ?? choice.nodeUrl;
      final relay = EpicboxRelay.parse(v[BackupItem.relay] as String? ?? '') ?? choice.relay;
      try {
        final move = switchServers;
        if (move != null) {
          await move(node, relay);
        } else {
          await read(networkChoiceProvider.notifier).save(choice.preset, node, relay: relay);
          await read(serverListProvider((ServerKind.node, chain)).notifier).add(node);
          await read(serverListProvider((ServerKind.relay, chain)).notifier).add(relay.label);
        }
        changed += [BackupItem.node, BackupItem.relay].where(v.containsKey).length;
      } on WalletError catch (e) {
        // Refused: the servers stay as they were, and so does what was saved.
        logWarn('backup', 'servers from the backup not used: ${e.kind.name}');
      }
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

/// The phone's settings as the backup map ([BackupKey]). Only [chain]'s servers and lists.
Map<String, Object?> phoneBackupMap(
  AppSettings s, {
  required Chain chain,
  String? node,
  String? relay,
  required ServerList nodeList,
  required ServerList relayList,
  required bool tor,
  required String seenAs,
}) => {
  BackupKey.v: backupSettingsVersion,
  BackupKey.from: BackupPlatform.mobile.name,
  BackupKey.theme: s.themeMode.name,
  BackupKey.language: s.language,
  BackupKey.helpLanguage: s.helpLanguage,
  BackupKey.hideBalances: s.hideBalances,
  BackupKey.statusSite: s.useStatusSite,
  BackupKey.autoLock: autoLockToBackup(s.autoLockMinutes),
  BackupKey.advanced: s.advanced.toJson(),
  BackupKey.payments: s.payments.toJson(),
  BackupKey.sendStrategy: s.sendStrategy.name,
  BackupKey.splitChange: s.splitChange,
  BackupKey.fiat: s.fiatCurrency,
  BackupKey.showFiat: s.showFiat,
  BackupKey.node: {chain.name: ?node},
  BackupKey.relay: {chain.name: ?relay},
  BackupKey.nodeList: {chain.name: serverListJson(nodeList)},
  BackupKey.relayList: {chain.name: serverListJson(relayList)},
  BackupKey.tor: tor,
  BackupKey.seenAs: seenAs,
};
