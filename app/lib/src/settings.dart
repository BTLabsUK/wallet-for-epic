/// Display and security preferences. Not secret, but kept in the same [SecretStore] as the
/// network choice so the app needs no preferences dependency.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'advanced.dart';
import 'app_log.dart';
import 'l10n.dart' show appLanguages;
import 'providers.dart';
import 'relay_directory.dart' show statusSite;
import 'models.dart' show SelectionStrategy;
import 'secret_store.dart';
import 'wallet_service.dart' show Chain, TxEntry, TxSource, TxStatus;

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

/// Auto-lock choices offered in settings, in minutes. Null means never.
const List<int?> autoLockChoices = [0, 1, 5, 15, null];

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
    this.autoLockMinutes = 5,
    this.pushNotifications = false,
    this.historyExportedAt = const {},
    this.historyReminderDismissedAt = const {},
    this.historyReminderFirstSeenAt = const {},
    this.historyExportSnapshots = const {},
    this.language,
    this.helpLanguage,
    this.advancedOptions = false,
    this.advanced = AdvancedPrefs.none,
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
    return AppSettings(
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
        final m => int.tryParse(m) ?? defaults.autoLockMinutes,
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
  Future<void> setAdvanced(AdvancedPrefs prefs) async => _put(
    _advancedPrefsKey,
    prefs.encode(),
    (await _current()).copyWith(advanced: prefs),
  );

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
