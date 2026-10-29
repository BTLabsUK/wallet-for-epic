// SPDX-License-Identifier: Apache-2.0
/// The desktop's side of the settings a history backup carries (`backup_settings.dart`).
///
/// The wallet ([DeskWalletApi.backupSettings]) reads what the open wallet has now and what a
/// fresh install has, in the map's form ([deskBackupMap]); the export seals the first into the
/// file. After an import, [planDeskBackupSettings] says what the file would change and
/// [applyDeskBackupSettings] applies it: the app-wide settings through [DeskController] (one
/// save, so the theme, the language, auto-lock, the network mode and the payment methods
/// follow at once), the Outputs choices through [deskOutputPrefsProvider], the Node and Epicbox
/// lists and `[online]` switches into `settings.toml` through [hostSettingsProvider] (a new
/// first server through [DeskController.useEpicbox] / [DeskController.useNode] first, so the
/// wallet reopens on it), and the wallet's deleted seed contacts through
/// [DeskWalletApi.restoreBackupItems].
///
/// The app-wide settings are shared by every wallet on this computer: the Backup screen asks
/// before it takes any the user changed ([BackupSettingsPlan.conflicts]). The lists are too, and
/// the first Epicbox entry is every wallet's address: with another wallet on this network a
/// file whose lists differ asks once, keep this computer's servers or use the backup's
/// ([BackupSettingsPlan.servers]). With none, the file's lists and switches are taken.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable, ProviderOrFamily;

import '../../backup_settings.dart';
import '../../log.dart';
import '../../payment_prefs.dart';
import '../../server_list_file.dart' show withFirst;
import '../../settings_file/host_settings.dart' show HostSettings;
import '../../settings_file/settings_providers.dart' show hostSettingsProvider;
import 'api.dart';
import 'features.dart';
import 'models.dart';
import 'server_lists.dart';
import 'state.dart';

export '../../backup_settings.dart' show BackupSettingsPlan, BackupSettingItem, BackupItem;

/// What [DeskWalletApi.backupSettings] answers: the network's chain name, and the open
/// wallet's settings now and a fresh install's, as backup maps.
class DeskBackupSettings {
  const DeskBackupSettings({required this.chain, required this.mine, required this.defaults});

  final String chain;
  final Map<String, Object?> mine;
  final Map<String, Object?> defaults;
}

/// The desktop's settings as the backup map ([BackupKey]); [hosts] gives `settings.toml`'s
/// lists and switches. HTTP (reach, port), the built-in node's settings and the interface scale
/// are never in it.
Map<String, Object?> deskBackupMap(
  DeskSettings s, {
  required HostSettings hosts,
  required OutputPrefs outputs,
  required Duration invoiceExpiry,
  required Iterable<String> seedsDeleted,
}) => {
  BackupKey.v: backupSettingsVersion,
  BackupKey.from: BackupPlatform.desktop.name,
  BackupKey.theme: s.theme.name,
  BackupKey.language: s.language,
  BackupKey.helpLanguage: s.helpLanguage,
  BackupKey.hideBalances: s.hideAmounts,
  BackupKey.autoLock: s.autoLockOn ? s.autoLockMinutes : BackupKey.never,
  BackupKey.advanced: s.advanced.toJson(),
  BackupKey.payments: s.payments.toJson(),
  BackupKey.sendStrategy: outputs.strategy.name,
  BackupKey.splitChange: outputs.smartOutputs,
  BackupKey.tor: s.torAutostart,
  BackupKey.seenAs: s.pairingSeenAs,
  ...backupHostSettings(hosts),
  BackupKey.desktop: {
    BackupKey.invoiceExpiry: invoiceExpiry.inSeconds,
    BackupKey.seedsDeleted: [...seedsDeleted]..sort(),
    BackupKey.epicboxAutostart: s.epicboxAutostart,
  },
};

/// What importing [result]'s settings and wallet name would change here
/// ([HistoryImport.settings], [HistoryImport.walletName]).
Future<BackupSettingsPlan> planDeskBackupSettings(WidgetRef ref, HistoryImport result) =>
    DeskBackupSettingsGlue.of(ref).plan(result);

/// Applies [plan]: what it takes silently, its conflicts when [takeConflicts] and its servers
/// when [takeServers]. Returns how many settings changed.
Future<int> applyDeskBackupSettings(WidgetRef ref, BackupSettingsPlan plan, {required bool takeConflicts, bool takeServers = false}) =>
    DeskBackupSettingsGlue.of(ref).apply(plan, takeConflicts: takeConflicts, takeServers: takeServers);

/// The two steps over a provider reader: a widget's ref, or a container in tests.
class DeskBackupSettingsGlue {
  DeskBackupSettingsGlue({required this.read, required this.invalidate});

  factory DeskBackupSettingsGlue.of(WidgetRef ref) => DeskBackupSettingsGlue(read: ref.read, invalidate: ref.invalidate);

  factory DeskBackupSettingsGlue.container(ProviderContainer c) => DeskBackupSettingsGlue(read: c.read, invalidate: c.invalidate);

  final T Function<T>(ProviderListenable<T> provider) read;
  final void Function(ProviderOrFamily provider) invalidate;

  DeskWalletApi get _api => read(deskApiProvider);

  Future<WalletAccount?> _account() async {
    final held = read(deskProvider).account;
    if (held != null) return held;
    try {
      return await _api.account();
    } on Object {
      return null; // Locked.
    }
  }

  /// Whether another wallet on this network shares `settings.toml`'s lists with the open one.
  Future<bool> _otherWallets(String chain, String? openId) async {
    try {
      return (await _api.wallets()).any((w) => w.network == chain && w.id != openId);
    } on Object {
      return true; // Not known: ask rather than move every wallet.
    }
  }

  Future<BackupSettingsPlan> plan(HistoryImport result) async {
    if (result.settings == null && result.walletName == null) return BackupSettingsPlan.empty;
    final b = await _api.backupSettings();
    final account = await _account();
    return planBackupSettings(
      here: BackupPlatform.desktop,
      // The lists and switches as the app holds them now (a hand edit included).
      mine: {...b.mine, ...backupHostSettings(read(hostSettingsProvider))},
      defaults: b.defaults,
      file: result.settings,
      sharedServers: await _otherWallets(b.chain, account?.id),
      fileWalletName: result.walletName,
      myWalletName: account?.id == null ? null : account!.name,
    );
  }

  /// [takeServers]: the answer to [BackupSettingsPlan.asksServers], use the backup's.
  Future<int> apply(BackupSettingsPlan plan, {required bool takeConflicts, bool takeServers = false}) async {
    final v = plan.values(takeConflicts: takeConflicts, takeServers: takeServers);
    if (v.isEmpty) return 0;
    final desk = read(deskProvider.notifier);
    var changed = 0;

    // The app-wide settings in one save: the network mode reaches the gate and Tor before the
    // servers below are asked.
    final was = read(deskProvider).settings;
    var s = was;
    void set(String key, DeskSettings Function(Object? value) change) {
      if (!v.containsKey(key)) return;
      s = change(v[key]);
      changed++;
    }

    set(BackupItem.theme, (x) => s.copyWith(theme: ThemeChoice.values.byName(x! as String)));
    set(BackupItem.language, (x) => s.copyWith(language: () => x as String?));
    set(BackupItem.helpLanguage, (x) => s.copyWith(helpLanguage: () => x as String?));
    set(BackupItem.hideBalances, (x) => s.copyWith(hideAmounts: x! as bool));
    set(BackupItem.statusSite, (x) => s.copyWith(useStatusSite: x! as bool));
    set(BackupItem.autoLock, (x) {
      final minutes = autoLockFromBackup(x);
      return minutes == null ? s.copyWith(autoLockOn: false) : s.copyWith(autoLockOn: true, autoLockMinutes: minutes);
    });
    set(BackupItem.payments, (x) => s.copyWith(payments: PaymentPrefs.fromJson(x)));
    set(BackupItem.seenAs, (x) => s.copyWith(pairingSeenAs: x! as String));
    set(BackupItem.epicboxAutostart, (x) => s.copyWith(epicboxAutostart: x! as bool));
    final advanced = [BackupItem.features, BackupItem.networkMode, BackupItem.nodeFailover].where(v.containsKey).length;
    if (advanced > 0) {
      s = s.copyWith(advanced: advancedFromBackup(s.advanced, v));
      changed += advanced;
    }
    if (!identical(s, was)) await desk.saveSettings(s);
    for (final key in [BackupItem.updateCheck, BackupItem.price]) {
      if (!v.containsKey(key)) continue;
      await read(hostSettingsProvider.notifier).set(key, v[key]! as bool);
      changed++;
    }

    // The open wallet's Outputs choices.
    if (v.containsKey(BackupItem.sendStrategy) || v.containsKey(BackupItem.splitChange)) {
      final now = await read(deskOutputPrefsProvider.future);
      final strategy = v[BackupItem.sendStrategy];
      final split = v[BackupItem.splitChange];
      await read(deskOutputPrefsProvider.notifier).save(
        OutputPrefs(
          strategy: strategy is String ? SelectionStrategy.values.byName(strategy) : now.strategy,
          smartOutputs: split is bool ? split : now.smartOutputs,
        ),
      );
      changed += [BackupItem.sendStrategy, BackupItem.splitChange].where(v.containsKey).length;
    }

    final name = v[BackupItem.walletName];
    final account = await _account();
    if (name is String && account?.id != null) {
      try {
        await desk.renameWallet(account!.id!, name);
        changed++;
      } on Object catch (e) {
        // A name the list does not take (taken by another wallet): the current one stays.
        logWarn('backup', 'wallet name from the backup not used: ${e.runtimeType}');
      }
    }

    final expiry = v[BackupItem.invoiceExpiry];
    if (expiry is int) {
      await _api.setInvoiceExpiry(Duration(seconds: expiry));
      changed++;
    }

    // The seed contacts deleted.
    final seeds = v[BackupItem.seedsDeleted];
    if (seeds is List) {
      await _api.restoreBackupItems(seedsDeleted: seeds.whereType<String>().toList());
      changed++;
    }

    // The lists, as the file has them. A new first server first: the wallet reopens on it
    // (every wallet's address follows the Epicbox one); when refused, the one in use stays first.
    final nodes = (v[BackupItem.nodeServers] as List?)?.cast<String>();
    final boxes = (v[BackupItem.epicboxServers] as List?)?.cast<String>();
    if (nodes != null || boxes != null) {
      final h = read(hostSettingsProvider);
      var keepNode = '';
      var keepBox = '';
      final box = boxes?.first;
      if (box != null && box != h.epicboxUse) {
        try {
          await desk.useEpicbox(box);
        } on Object catch (e) {
          keepBox = h.epicboxUse;
          logWarn('backup', 'epicbox server from the backup not used: ${e.runtimeType}');
        }
      }
      final node = nodes?.first;
      if (node != null && node != h.nodeUse) {
        try {
          await desk.useNode(node);
        } on Object catch (e) {
          keepNode = h.nodeUse;
          logWarn('backup', 'node from the backup not used: ${e.runtimeType}');
        }
      }
      await read(hostSettingsProvider.notifier).setAll({
        if (nodes != null) BackupItem.nodeServers: keepNode.isEmpty ? nodes : withFirst(ServerKind.node, nodes, keepNode),
        if (boxes != null) BackupItem.epicboxServers: keepBox.isEmpty ? boxes : withFirst(ServerKind.relay, boxes, keepBox),
      });
      invalidate(deskServerListProvider(ServerKind.node));
      invalidate(deskServerListProvider(ServerKind.relay));
      changed += [nodes, boxes].nonNulls.length;
    }

    // Tor last, on the servers and in the mode just set.
    final tor = v[BackupItem.tor];
    if (tor is bool && DeskFeatures.tor) {
      try {
        await desk.setTor(tor);
        changed++;
      } on Object catch (e) {
        logWarn('backup', 'tor from the backup not set: ${e.runtimeType}');
      }
    }
    logInfo('backup', 'settings from the backup: $changed changed');
    return changed;
  }
}
