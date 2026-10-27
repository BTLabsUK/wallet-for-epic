/// The desktop's side of the settings a history backup carries (`backup_settings.dart`).
///
/// The wallet ([DeskWalletApi.backupSettings]) reads what the open wallet has now and what a
/// fresh install has, in the map's form ([deskBackupMap]); the export seals the first into the
/// file. After an import, [planDeskBackupSettings] says what the file would change and
/// [applyDeskBackupSettings] applies it: the app-wide settings through [DeskController] (one
/// save, so the theme, the language, auto-lock, the network mode and the payment methods
/// follow at once), the Outputs choices through [deskOutputPrefsProvider], the servers through
/// [DeskController.useEpicbox] / [DeskController.useNode] (the wallet reopens on them), and the
/// wallet's own items (the lists, its own Epicbox server, deleted seed contacts) through
/// [DeskWalletApi.restoreBackupItems].
///
/// The app-wide settings are shared by every wallet on this computer: the Backup screen asks
/// before it takes any the user changed ([BackupSettingsPlan.conflicts]).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable, ProviderOrFamily;

import '../../backup_settings.dart';
import '../../log.dart';
import '../../payment_prefs.dart';
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

/// The desktop's settings as the backup map ([BackupKey]); only [chain]'s servers and lists.
/// HTTP (reach, port), the built-in node and the interface scale are never in it.
Map<String, Object?> deskBackupMap(
  DeskSettings s, {
  required String chain,
  required OutputPrefs outputs,
  String? node,
  String? relay,
  required ServerList nodeList,
  required ServerList relayList,
  required List<NodeServer> ownNodes,
  required Duration invoiceExpiry,
  required Iterable<String> seedsDeleted,
  String? ownRelay,
}) => {
  BackupKey.v: backupSettingsVersion,
  BackupKey.from: BackupPlatform.desktop.name,
  BackupKey.theme: s.theme.name,
  BackupKey.language: s.language,
  BackupKey.helpLanguage: s.helpLanguage,
  BackupKey.hideBalances: s.hideAmounts,
  BackupKey.statusSite: s.useStatusSite,
  BackupKey.autoLock: s.autoLockOn ? s.autoLockMinutes : BackupKey.never,
  BackupKey.advanced: s.advanced.toJson(),
  BackupKey.payments: s.payments.toJson(),
  BackupKey.sendStrategy: outputs.strategy.name,
  BackupKey.splitChange: outputs.smartOutputs,
  BackupKey.node: {chain: ?node},
  BackupKey.relay: {chain: ?relay},
  BackupKey.nodeList: {chain: serverListJson(nodeList)},
  BackupKey.relayList: {chain: serverListJson(relayList)},
  BackupKey.tor: s.torAutostart,
  BackupKey.seenAs: s.pairingSeenAs,
  BackupKey.desktop: {
    BackupKey.deskNodes: [
      for (final n in ownNodes) {'url': n.url, 'label': n.label},
    ],
    BackupKey.invoiceExpiry: invoiceExpiry.inSeconds,
    BackupKey.seedsDeleted: [...seedsDeleted]..sort(),
    BackupKey.ownRelay: ownRelay,
    BackupKey.epicboxAutostart: s.epicboxAutostart,
  },
};

/// What importing [result]'s settings and wallet name would change here
/// ([HistoryImport.settings], [HistoryImport.walletName]).
Future<BackupSettingsPlan> planDeskBackupSettings(WidgetRef ref, HistoryImport result) =>
    DeskBackupSettingsGlue.of(ref).plan(result);

/// Applies [plan]: what it takes silently, and its conflicts when [takeConflicts]. Returns how
/// many settings changed.
Future<int> applyDeskBackupSettings(WidgetRef ref, BackupSettingsPlan plan, {required bool takeConflicts}) =>
    DeskBackupSettingsGlue.of(ref).apply(plan, takeConflicts: takeConflicts);

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

  Future<BackupSettingsPlan> plan(HistoryImport result) async {
    if (result.settings == null && result.walletName == null) return BackupSettingsPlan.empty;
    final b = await _api.backupSettings();
    final account = await _account();
    return planBackupSettings(
      here: BackupPlatform.desktop,
      chain: b.chain,
      mine: b.mine,
      defaults: b.defaults,
      file: result.settings,
      fileWalletName: result.walletName,
      myWalletName: account?.id == null ? null : account!.name,
    );
  }

  Future<int> apply(BackupSettingsPlan plan, {required bool takeConflicts}) async {
    final v = plan.values(takeConflicts: takeConflicts);
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

    final nodes = v[BackupItem.deskNodes];
    if (nodes is List) {
      final known = await _api.nodes();
      for (final n in nodes.whereType<Map>()) {
        final url = n['url'];
        if (url is! String || known.any((k) => k.own && sameServer(ServerKind.node, k.url, url))) continue;
        final label = n['label'] is String && (n['label'] as String).isNotEmpty ? n['label'] as String : (Uri.tryParse(url)?.host ?? url);
        await desk.addNode(NodeServer(url: url, label: label, own: true, health: ServiceHealth.checking));
      }
      changed++;
    }

    // The wallet's own items: the lists (merged again with what they hold now), its own
    // Epicbox server, the seed contacts deleted.
    final nodeList = serverListFromJson(ServerKind.node, v[BackupItem.nodeList]);
    final relayList = serverListFromJson(ServerKind.relay, v[BackupItem.relayList]);
    final seeds = v[BackupItem.seedsDeleted];
    final ownRelay = v.containsKey(BackupItem.ownRelay);
    if (nodeList != null || relayList != null || seeds is List || ownRelay) {
      await _api.restoreBackupItems(
        nodeList: nodeList,
        relayList: relayList,
        seedsDeleted: seeds is List ? seeds.whereType<String>().toList() : null,
        ownRelay: ownRelay ? (relay: v[BackupItem.ownRelay] as String?) : null,
      );
      if (nodeList != null) invalidate(deskServerListProvider(ServerKind.node));
      if (relayList != null) invalidate(deskServerListProvider(ServerKind.relay));
      changed += [nodeList, relayList].nonNulls.length + (seeds is List ? 1 : 0) + (ownRelay ? 1 : 0);
    }

    // The servers: the wallet reopens on each (a wallet with its own Epicbox server keeps the
    // relay to itself).
    final relay = (v[BackupItem.relay] ?? v[BackupItem.ownRelay]) as String?;
    if (relay != null) {
      try {
        await desk.useEpicbox(relay);
        if (v.containsKey(BackupItem.relay)) changed++;
      } on Object catch (e) {
        logWarn('backup', 'epicbox server from the backup not used: ${e.runtimeType}');
      }
    }
    final node = v[BackupItem.node];
    if (node is String) {
      try {
        await desk.useNode(node);
        changed++;
      } on Object catch (e) {
        logWarn('backup', 'node from the backup not used: ${e.runtimeType}');
      }
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
