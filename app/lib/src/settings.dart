/// Display and security preferences. Not secret, but kept in the same [SecretStore] as the
/// network choice so the app needs no preferences dependency.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'advanced.dart';
import 'payment_prefs.dart';
import 'app_log.dart';
import 'l10n.dart' show appLanguages;
import 'network_gate.dart';
import 'providers.dart';
import 'relay_directory.dart' show statusSite;
import 'models.dart' show SelectionStrategy;
import 'secret_store.dart';
import 'wallet_backend.dart' show hostIsPhone;
import 'wallet_service.dart' show Chain, TxEntry, TxSource, TxStatus;

/// `--dart-define=WFE_WEB_FAKE=true`, the clickable web preview of the phone app: the payment
/// methods are the phone's, QR is offered although the browser has no camera, and the scan
/// screen shows a simulated camera that reads the fake wallet's payment and reply. Never set
/// in a real build.
const bool qrPreviewSimulation = bool.fromEnvironment('WFE_WEB_FAKE');

/// Whether the payment methods are the phone's (QR on, File off by default). Tests override it:
/// the app under test runs on a computer.
final phonePaymentsProvider = Provider<bool>(
  (ref) => hostIsPhone || qrPreviewSimulation,
);

/// What a history backup export held, beyond its time: the payments still pending then, and a
/// short hash of every note. The home reminder compares it with today's list to find payments
/// that settled, and notes that changed, since. (Added by uihome.)
class HistoryExportSnapshot {
  const HistoryExportSnapshot({
    this.pendingKeys = const {},
    this.noteHashes = const {},
  });

  /// Builds the snapshot of [transactions] at export time. Only this wallet's own rows count;
  /// a restore or an import brings the others back anyway.
  factory HistoryExportSnapshot.of(Iterable<TxEntry> transactions) {
    final own = transactions.where((t) => t.source == TxSource.wallet);
    return HistoryExportSnapshot(
      pendingKeys: {
        for (final t in own)
          if (t.status == TxStatus.awaitingRecipient ||
              t.status == TxStatus.awaitingConfirmation)
            t.key,
      },
      noteHashes: {for (final t in own) t.key: ?noteHash(t.note)},
    );
  }

  factory HistoryExportSnapshot.fromJson(Map<String, dynamic> json) =>
      HistoryExportSnapshot(
        pendingKeys: {
          for (final k in json['pending'] as List<dynamic>? ?? const [])
            k as String,
        },
        noteHashes: {
          for (final e
              in (json['notes'] as Map<String, dynamic>? ?? const {}).entries)
            e.key: e.value as String,
        },
      );

  /// Keys of the payments that were pending at export time.
  final Set<String> pendingKeys;

  /// [noteHash] of each note at export time, by payment key. Rows without a note are absent.
  final Map<String, String> noteHashes;

  Map<String, dynamic> toJson() => {
    'pending': pendingKeys.toList(),
    'notes': noteHashes,
  };

  /// A short, stable fingerprint of a note, or null for none. Stored instead of the note, so
  /// notes stay out of the preferences.
  static String? noteHash(String? note) {
    final text = note?.trim() ?? '';
    if (text.isEmpty) return null;
    return sha256.convert(utf8.encode(text)).toString().substring(0, 12);
  }
}

/// Auto-lock choices in minutes, the same on the phone and the desktop (1 to 60).
const List<int> autoLockChoices = [1, 2, 5, 10, 15, 30, 45, 60];

/// The auto-lock a new wallet starts with, in minutes, on both.
const int autoLockDefault = 15;

/// [minutes] as one of [autoLockChoices]: the nearest at or above it, 60 at most (an old
/// "immediately", 0, becomes 1).
int autoLockChoice(int minutes) =>
    autoLockChoices.firstWhere((m) => m >= minutes, orElse: () => autoLockChoices.last);

/// The wall clock. Tests override it to move time.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// How many of our own trips to another app (file picker, share sheet) are in progress. While
/// any is, leaving the app does not count towards auto-lock.
final autoLockHoldProvider = NotifierProvider<AutoLockHold, int>(
  AutoLockHold.new,
);

class AutoLockHold extends Notifier<int> {
  @override
  int build() => 0;

  /// Runs [action], which may open another app, without the trip counting towards auto-lock.
  Future<T> during<T>(Future<T> Function() action) async {
    state++;
    try {
      return await action();
    } finally {
      if (ref.mounted) state--;
    }
  }
}

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.fiatCurrency = 'usd',
    this.showFiat = true,
    this.hideBalances = false,
    this.autoLockMinutes = autoLockDefault,
    this.pushNotifications = false,
    this.historyExportedAt = const {},
    this.historyReminderDismissedAt = const {},
    this.historyReminderFirstSeenAt = const {},
    this.historyExportSnapshots = const {},
    this.language,
    this.helpLanguage,
    this.advancedOptions = false,
    this.advanced = AdvancedPrefs.none,
    this.payments = PaymentPrefs.defaults,
    this.useStatusSite = true,
    this.sendStrategy = SelectionStrategy.smallest,
    this.splitChange = true,
    this.hiddenTips = const {},
    this.phoneTourSeen = false,
  });

  final ThemeMode themeMode;

  /// Server health and node lists from status.btlabs.uk (`statusSite`). Off, only the servers
  /// themselves are asked.
  final bool useStatusSite;

  /// Show the technical controls: node, relay, block heights, transport, files and logs.
  /// Off by default, so the simple path never mentions them.
  final bool advancedOptions;

  /// The Advanced page: which expert features show and the network mode (`advanced.dart`).
  final AdvancedPrefs advanced;

  /// Settings › Transactions: the methods Send and Receive offer and Send's first one.
  final PaymentPrefs payments;

  /// Which outputs a send spends unless Send overrides it (Outputs).
  final SelectionStrategy sendStrategy;

  /// Split the change of a send into several outputs when few would be left (Outputs).
  final bool splitChange;

  /// The app's language as a code from `appLanguages` (`de`), or null to follow the system.
  final String? language;

  /// [language] as a [Locale] for `MaterialApp.locale`; null follows the system.
  Locale? get locale => language == null ? null : Locale(language!);

  /// The language of the help topics as a code from `appLanguages`, or null to follow the app's
  /// language. Chosen with the switch at the top of Help; the rest of the app is not changed.
  final String? helpLanguage;

  /// Lower-case CoinGecko currency code, for example `usd`.
  final String fiatCurrency;

  /// Fetch and show prices.
  final bool showFiat;

  /// Show amounts as dots.
  final bool hideBalances;

  /// Lock this long after the app goes to the background; 0 locks at once, null never.
  final int? autoLockMinutes;

  /// Firebase payment notifications. Off until the user turns them on, because starting them
  /// contacts Google and asks for notification permission.
  final bool pushNotifications;

  /// When a history backup was last exported, per network: [Chain.name] to Unix seconds.
  /// (Added by uihome for the history backup reminder.)
  final Map<String, int> historyExportedAt;

  /// When the history backup reminder was last dismissed, per network, in Unix seconds.
  final Map<String, int> historyReminderDismissedAt;

  /// When the history backup reminder first had something to remind of, per network, in Unix
  /// seconds. The pause of a wallet never exported nor dismissed counts from here.
  final Map<String, int> historyReminderFirstSeenAt;

  /// What the last history backup export held, per network. Absent for exports made before
  /// snapshots were kept.
  final Map<String, HistoryExportSnapshot> historyExportSnapshots;

  /// The ids of the inline guides the user closed with their X (`DismissibleTip`), for good
  /// until Show tips again clears them.
  final Set<String> hiddenTips;

  /// The first-unlock tour was shown (or skipped) once; it does not open by itself again.
  final bool phoneTourSeen;

  /// Whether any guide is hidden, so Show tips again can be off when there is nothing to show.
  bool get tipsHidden => hiddenTips.isNotEmpty;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? fiatCurrency,
    bool? showFiat,
    bool? hideBalances,
    int? Function()? autoLockMinutes,
    bool? pushNotifications,
    Map<String, int>? historyExportedAt,
    Map<String, int>? historyReminderDismissedAt,
    Map<String, int>? historyReminderFirstSeenAt,
    Map<String, HistoryExportSnapshot>? historyExportSnapshots,
    String? Function()? language,
    String? Function()? helpLanguage,
    bool? advancedOptions,
    AdvancedPrefs? advanced,
    PaymentPrefs? payments,
    bool? useStatusSite,
    SelectionStrategy? sendStrategy,
    bool? splitChange,
    Set<String>? hiddenTips,
    bool? phoneTourSeen,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    fiatCurrency: fiatCurrency ?? this.fiatCurrency,
    showFiat: showFiat ?? this.showFiat,
    hideBalances: hideBalances ?? this.hideBalances,
    autoLockMinutes: autoLockMinutes != null
        ? autoLockMinutes()
        : this.autoLockMinutes,
    pushNotifications: pushNotifications ?? this.pushNotifications,
    historyExportedAt: historyExportedAt ?? this.historyExportedAt,
    historyReminderDismissedAt:
        historyReminderDismissedAt ?? this.historyReminderDismissedAt,
    historyReminderFirstSeenAt:
        historyReminderFirstSeenAt ?? this.historyReminderFirstSeenAt,
    historyExportSnapshots:
        historyExportSnapshots ?? this.historyExportSnapshots,
    language: language != null ? language() : this.language,
    helpLanguage: helpLanguage != null ? helpLanguage() : this.helpLanguage,
    advancedOptions: advancedOptions ?? this.advancedOptions,
    advanced: advanced ?? this.advanced,
    payments: payments ?? this.payments,
    useStatusSite: useStatusSite ?? this.useStatusSite,
    sendStrategy: sendStrategy ?? this.sendStrategy,
    splitChange: splitChange ?? this.splitChange,
    hiddenTips: hiddenTips ?? this.hiddenTips,
    phoneTourSeen: phoneTourSeen ?? this.phoneTourSeen,
  );
}

/// The saved Use status.btlabs.uk choice, read before the first screen (`main.dart`), so an
/// opted-out phone never asks the site while its settings load.
Future<bool> readUseStatusSite(SecretStore store) async =>
    await store.read(AppSettingsNotifier.statusSiteKey) != 'false';

/// The network mode the phone runs in now (network_gate.dart): Standard, Tor only or Offline.
/// Before the settings load, the mode read at launch.
final networkModeProvider = Provider<NetworkMode>(
  (ref) => netModeOf(
    ref.watch(appSettingsProvider.select((s) => s.value?.advanced.networkMode)) ?? NetGate.mode,
  ),
);

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
      AppSettingsNotifier.new,
    );

/// Whether any inline guide is hidden; Show tips again is off while this is false.
final tipsHiddenProvider = Provider<bool>(
  (ref) => ref.watch(appSettingsProvider).value?.tipsHidden ?? false,
);

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  static const String _themeKey = 'app.theme';
  static const String _currencyKey = 'app.fiat';
  static const String _showFiatKey = 'app.show_fiat';
  static const String _hideKey = 'app.hide_balances';
  static const String _autoLockKey = 'app.auto_lock';
  static const String _pushKey = 'app.push';
  static const String _languageKey = 'app.language';
  static const String _helpLanguageKey = 'app.helpLanguage';
  static const String _advancedKey = 'app.advanced';
  static const String _advancedPrefsKey = 'app.advanced_prefs';
  static const String _paymentsKey = 'app.payment_prefs';
  static const String _qrMethodKey = 'app.qr_method_seen';
  static const String _strategyKey = 'app.send_strategy';
  static const String _splitChangeKey = 'app.split_change';
  static const String statusSiteKey = 'app.status_site';
  static const String tipsHiddenKey = 'app.tips_hidden';
  static const String phoneTourSeenKey = 'app.phone_tour_seen';
  static String _exportedKey(Chain chain) =>
      'app.history_exported.${chain.name}';
  static String _dismissedKey(Chain chain) =>
      'app.history_reminder_dismissed.${chain.name}';
  static String _firstSeenKey(Chain chain) =>
      'app.history_reminder_first_seen.${chain.name}';
  static String _snapshotKey(Chain chain) =>
      'app.history_export_snapshot.${chain.name}';
  static const String _never = 'never';

  @override
  Future<AppSettings> build() async {
    final store = ref.watch(secretStoreProvider);
    const defaults = AppSettings();
    final theme = await store.read(_themeKey);
    final currency = await store.read(_currencyKey);
    final showFiat = await store.read(_showFiatKey);
    final hide = await store.read(_hideKey);
    final autoLock = await store.read(_autoLockKey);
    final push = await store.read(_pushKey);
    final language = await store.read(_languageKey);
    final helpLanguage = await store.read(_helpLanguageKey);
    final advanced = await store.read(_advancedKey);
    final advancedPrefs = await store.read(_advancedPrefsKey);
    final legacyDirect = (advancedPrefs ?? '').split('|').first.split(',').contains('directReceiving');
    final phone = ref.watch(phonePaymentsProvider);
    var payments = await store.read(_paymentsKey);
    if (phone) payments = await _migrateQrMethod(store, payments, legacyDirect);
    final strategy = await store.read(_strategyKey);
    final splitChange = await store.read(_splitChangeKey);
    final tips = await store.read(tipsHiddenKey);
    final tourSeen = await store.read(phoneTourSeenKey);
    final site = await store.read(statusSiteKey) != 'false';
    statusSite.on = site;
    Future<Map<String, int>> perChain(String Function(Chain) key) async => {
      for (final chain in Chain.values)
        chain.name: ?int.tryParse(await store.read(key(chain)) ?? ''),
    };
    final exported = await perChain(_exportedKey);
    final dismissed = await perChain(_dismissedKey);
    final firstSeen = await perChain(_firstSeenKey);
    final snapshots = <String, HistoryExportSnapshot>{};
    for (final chain in Chain.values) {
      final raw = await store.read(_snapshotKey(chain));
      if (raw == null) continue;
      try {
        snapshots[chain.name] = HistoryExportSnapshot.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (error) {
        // A damaged snapshot only makes the reminder count less; the next export rewrites it.
        logWarn(
          'settings',
          'damaged history snapshot for ${chain.name}: $error',
        );
      }
    }
    final settings = AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == theme,
        orElse: () => defaults.themeMode,
      ),
      fiatCurrency: (currency == null || currency.isEmpty)
          ? defaults.fiatCurrency
          : currency,
      showFiat: showFiat == null ? defaults.showFiat : showFiat == 'true',
      hideBalances: hide == null ? defaults.hideBalances : hide == 'true',
      autoLockMinutes: switch (autoLock) {
        null => defaults.autoLockMinutes,
        _never => null,
        final m => int.tryParse(m) == null ? defaults.autoLockMinutes : autoLockChoice(int.parse(m)),
      },
      pushNotifications: push == null
          ? defaults.pushNotifications
          : push == 'true',
      historyExportedAt: exported,
      historyReminderDismissedAt: dismissed,
      historyReminderFirstSeenAt: firstSeen,
      historyExportSnapshots: snapshots,
      // A code no translation has any more (a language removed) falls back to the system.
      language: appLanguages.any((a) => a.code == language) ? language : null,
      helpLanguage: appLanguages.any((a) => a.code == helpLanguage)
          ? helpLanguage
          : null,
      advancedOptions: advanced == null
          ? defaults.advancedOptions
          : advanced == 'true',
      // A wallet that had the old Advanced options switch on keeps what it showed.
      advanced: advancedPrefs != null
          ? AdvancedPrefs.decode(advancedPrefs)
          : advanced == 'true'
          ? const AdvancedPrefs(
              features: {
                AdvancedFeature.technicalDetails,
                AdvancedFeature.serverDetails,
                AdvancedFeature.recheckFromHeight,
              },
            )
          : defaults.advanced,
      // Direct was the Advanced page's "Direct receiving" switch before 26.10.13.
      payments: PaymentPrefs.decode(payments, legacyDirect: legacyDirect, phone: phone),
      useStatusSite: site,
      sendStrategy: SelectionStrategy.values.firstWhere(
        (v) => v.name == strategy,
        orElse: () => defaults.sendStrategy,
      ),
      splitChange: splitChange == null
          ? defaults.splitChange
          : splitChange == 'true',
      hiddenTips: _tipIds(tips),
      phoneTourSeen: tourSeen == 'true',
    );
    // The network mode reaches the runtime here (network_gate.dart); main.dart set it at launch.
    NetGate.set(settings.advanced.networkMode);
    return settings;
  }

  /// The first start of the version that made QR a phone method and File an Advanced one: a
  /// phone that already has a wallet keeps File (saved on explicitly when it was on or never
  /// chosen), a new install does not get it. Runs once; returns the stored payments value.
  static Future<String?> _migrateQrMethod(
    SecretStore store,
    String? payments,
    bool legacyDirect,
  ) async {
    if (await store.read(_qrMethodKey) != null) return payments;
    var hadWallet = false;
    for (final chain in Chain.values) {
      final sealed = await store.read('wallet.${chain.name}.pinSealed');
      final backedUp = await store.read('wallet.${chain.name}.backedUp');
      if (sealed != null || backedUp != null) hadWallet = true;
    }
    if (hadWallet) {
      // As the version before read it: nothing stored means File on.
      final before = PaymentPrefs.decode(payments, legacyDirect: legacyDirect);
      if (before.file) {
        payments = before.encode();
        await store.write(_paymentsKey, payments);
      }
    }
    await store.write(_qrMethodKey, '1');
    return payments;
  }

  /// The ids saved under [tipsHiddenKey], a JSON list; anything else counts as none hidden.
  static Set<String> _tipIds(String? raw) {
    if (raw == null) return const {};
    try {
      return {...(jsonDecode(raw) as List).whereType<String>()};
    } catch (_) {
      return const {};
    }
  }

  Future<AppSettings> _current() async => state.value ?? await future;

  Future<void> _put(String key, String value, AppSettings next) async {
    await ref.read(secretStoreProvider).write(key, value);
    state = AsyncData(next);
  }

  Future<void> setThemeMode(ThemeMode mode) async =>
      _put(_themeKey, mode.name, (await _current()).copyWith(themeMode: mode));

  Future<void> setFiatCurrency(String currency) async {
    final code = currency.trim().toLowerCase();
    await _put(
      _currencyKey,
      code,
      (await _current()).copyWith(fiatCurrency: code),
    );
  }

  Future<void> setShowFiat(bool show) async =>
      _put(_showFiatKey, '$show', (await _current()).copyWith(showFiat: show));

  Future<void> setHideBalances(bool hide) async =>
      _put(_hideKey, '$hide', (await _current()).copyWith(hideBalances: hide));

  Future<void> setSendStrategy(SelectionStrategy strategy) async => _put(
    _strategyKey,
    strategy.name,
    (await _current()).copyWith(sendStrategy: strategy),
  );

  Future<void> setSplitChange(bool on) async => _put(
    _splitChangeKey,
    '$on',
    (await _current()).copyWith(splitChange: on),
  );

  Future<void> setAdvancedOptions(bool on) async => _put(
    _advancedKey,
    '$on',
    (await _current()).copyWith(advancedOptions: on),
  );

  /// The Advanced page: one feature switch or the network mode changed.
  /// A new network mode applies at once ([NetGate], [networkModeProvider]).
  Future<void> setAdvanced(AdvancedPrefs prefs) async {
    await _put(
      _advancedPrefsKey,
      prefs.encode(),
      (await _current()).copyWith(advanced: prefs),
    );
    NetGate.set(prefs.networkMode);
  }

  /// Settings › Transactions changed.
  Future<void> setPayments(PaymentPrefs prefs) async =>
      _put(_paymentsKey, prefs.encode(), (await _current()).copyWith(payments: prefs));

  /// The saved network mode, read at launch before any request (`main.dart`).
  static Future<NetworkMode> savedNetworkMode(SecretStore store) async =>
      netModeOf(AdvancedPrefs.decode(await store.read(_advancedPrefsKey)).networkMode);

  Future<void> setFeature(AdvancedFeature f, bool on) async =>
      setAdvanced((await _current()).advanced.withFeature(f, on));

  Future<void> setNetworkMode(NetworkMode mode) async =>
      setAdvanced((await _current()).advanced.withMode(mode));

  /// The first-unlock tour was shown: written first, and the state copied after the write from
  /// what the settings are then, so a setting saved meanwhile is not undone.
  Future<void> markPhoneTourSeen() async {
    final store = ref.read(secretStoreProvider);
    await store.write(phoneTourSeenKey, 'true');
    state = AsyncData((await _current()).copyWith(phoneTourSeen: true));
  }
  /// Advanced › Node failover (`node_failover.dart`).
  Future<void> setNodeFailover(bool on) async =>
      setAdvanced((await _current()).advanced.withNodeFailover(on));

  /// Settings › Privacy › Use status.btlabs.uk; applies at once ([statusSite]).
  Future<void> setUseStatusSite(bool on) async {
    statusSite.on = on;
    await _put(
      statusSiteKey,
      '$on',
      (await _current()).copyWith(useStatusSite: on),
    );
  }

  Future<void> setAutoLockMinutes(int? minutes) async => _put(
    _autoLockKey,
    minutes?.toString() ?? _never,
    (await _current()).copyWith(autoLockMinutes: () => minutes),
  );

  /// Sets the app's language to [code] from `appLanguages`, or back to the system's for null.
  Future<void> setLanguage(String? code) async {
    assert(code == null || appLanguages.any((a) => a.code == code));
    final store = ref.read(secretStoreProvider);
    if (code == null) {
      await store.delete(_languageKey);
    } else {
      await store.write(_languageKey, code);
    }
    state = AsyncData((await _current()).copyWith(language: () => code));
  }

  /// Sets the language of the help topics to [code] from `appLanguages`, or back to following
  /// the app's language for null.
  Future<void> setHelpLanguage(String? code) async {
    assert(code == null || appLanguages.any((a) => a.code == code));
    final store = ref.read(secretStoreProvider);
    if (code == null) {
      await store.delete(_helpLanguageKey);
    } else {
      await store.write(_helpLanguageKey, code);
    }
    state = AsyncData((await _current()).copyWith(helpLanguage: () => code));
  }

  Future<void> setPushNotifications(bool on) async =>
      _put(_pushKey, '$on', (await _current()).copyWith(pushNotifications: on));

  /// Records a successful history backup export on [chain] at [when], with what it held.
  Future<void> setHistoryExported(
    Chain chain,
    DateTime when, {
    HistoryExportSnapshot snapshot = const HistoryExportSnapshot(),
  }) async {
    final current = await _current();
    final seconds = when.millisecondsSinceEpoch ~/ 1000;
    await ref
        .read(secretStoreProvider)
        .write(_snapshotKey(chain), jsonEncode(snapshot.toJson()));
    await _put(
      _exportedKey(chain),
      '$seconds',
      current.copyWith(
        historyExportedAt: {...current.historyExportedAt, chain.name: seconds},
        historyExportSnapshots: {
          ...current.historyExportSnapshots,
          chain.name: snapshot,
        },
      ),
    );
  }

  /// Drops [chain]'s history backup export and reminder records, so a new wallet on that
  /// network does not inherit the deleted wallet's dates. Called by the delete flow; any key
  /// added for the reminder belongs here too.
  Future<void> forgetHistoryBackup(Chain chain) async {
    final current = await _current();
    final store = ref.read(secretStoreProvider);
    await store.delete(_exportedKey(chain));
    await store.delete(_dismissedKey(chain));
    await store.delete(_firstSeenKey(chain));
    await store.delete(_snapshotKey(chain));
    state = AsyncData(
      current.copyWith(
        historyExportedAt: {...current.historyExportedAt}..remove(chain.name),
        historyReminderDismissedAt: {...current.historyReminderDismissedAt}
          ..remove(chain.name),
        historyReminderFirstSeenAt: {...current.historyReminderFirstSeenAt}
          ..remove(chain.name),
        historyExportSnapshots: {...current.historyExportSnapshots}
          ..remove(chain.name),
      ),
    );
  }

  /// Records that the history backup reminder on [chain] was dismissed at [when].
  Future<void> dismissHistoryReminder(Chain chain, DateTime when) async {
    final current = await _current();
    final seconds = when.millisecondsSinceEpoch ~/ 1000;
    await _put(
      _dismissedKey(chain),
      '$seconds',
      current.copyWith(
        historyReminderDismissedAt: {
          ...current.historyReminderDismissedAt,
          chain.name: seconds,
        },
      ),
    );
  }

  /// Records at [when] that the history backup reminder on [chain] first had something to
  /// remind of. Keeps the first time: later calls change nothing.
  Future<void> markHistoryReminderSeen(Chain chain, DateTime when) async {
    final current = await _current();
    if (current.historyReminderFirstSeenAt.containsKey(chain.name)) return;
    final seconds = when.millisecondsSinceEpoch ~/ 1000;
    await _put(
      _firstSeenKey(chain),
      '$seconds',
      current.copyWith(
        historyReminderFirstSeenAt: {
          ...current.historyReminderFirstSeenAt,
          chain.name: seconds,
        },
      ),
    );
  }

  /// Hides the inline guide [id] for good (its X).
  Future<void> hideTip(String id) async {
    final current = await _current();
    if (current.hiddenTips.contains(id)) return;
    final next = {...current.hiddenTips, id};
    await _put(
      tipsHiddenKey,
      jsonEncode(next.toList()..sort()),
      current.copyWith(hiddenTips: next),
    );
  }

  /// Shows every hidden guide again (Settings, Show tips again).
  Future<void> showTipsAgain() async {
    final current = await _current();
    await ref.read(secretStoreProvider).delete(tipsHiddenKey);
    state = AsyncData(current.copyWith(hiddenTips: const {}));
  }
}
