/// Display and security preferences. Not secret, but kept in the same [SecretStore] as the
/// network choice so the app needs no preferences dependency.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'l10n.dart' show appLanguages;
import 'providers.dart';
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
    this.historyExportSnapshots = const {},
    this.language,
    this.advancedOptions = false,
  });

  final ThemeMode themeMode;

  /// Show the technical controls: node, relay, block heights, transport, files and logs.
  /// Off by default, so the simple path never mentions them.
  final bool advancedOptions;

  /// The app's language as a code from `appLanguages` (`de`), or null to follow the system.
  final String? language;

  /// [language] as a [Locale] for `MaterialApp.locale`; null follows the system.
  Locale? get locale => language == null ? null : Locale(language!);

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

  /// What the last history backup export held, per network. Absent for exports made before
  /// snapshots were kept.
  final Map<String, HistoryExportSnapshot> historyExportSnapshots;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? fiatCurrency,
    bool? showFiat,
    bool? hideBalances,
    int? Function()? autoLockMinutes,
    bool? pushNotifications,
    Map<String, int>? historyExportedAt,
    Map<String, int>? historyReminderDismissedAt,
    Map<String, HistoryExportSnapshot>? historyExportSnapshots,
    String? Function()? language,
    bool? advancedOptions,
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
    historyExportSnapshots:
        historyExportSnapshots ?? this.historyExportSnapshots,
    language: language != null ? language() : this.language,
    advancedOptions: advancedOptions ?? this.advancedOptions,
  );
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
      AppSettingsNotifier.new,
    );

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  static const String _themeKey = 'app.theme';
  static const String _currencyKey = 'app.fiat';
  static const String _showFiatKey = 'app.show_fiat';
  static const String _hideKey = 'app.hide_balances';
  static const String _autoLockKey = 'app.auto_lock';
  static const String _pushKey = 'app.push';
  static const String _languageKey = 'app.language';
  static const String _advancedKey = 'app.advanced';
  static String _exportedKey(Chain chain) =>
      'app.history_exported.${chain.name}';
  static String _dismissedKey(Chain chain) =>
      'app.history_reminder_dismissed.${chain.name}';
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
    final advanced = await store.read(_advancedKey);
    Future<Map<String, int>> perChain(String Function(Chain) key) async => {
      for (final chain in Chain.values)
        chain.name: ?int.tryParse(await store.read(key(chain)) ?? ''),
    };
    final exported = await perChain(_exportedKey);
    final dismissed = await perChain(_dismissedKey);
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
      historyExportSnapshots: snapshots,
      // A code no translation has any more (a language removed) falls back to the system.
      language: appLanguages.any((a) => a.code == language) ? language : null,
      advancedOptions: advanced == null
          ? defaults.advancedOptions
          : advanced == 'true',
    );
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

  Future<void> setAdvancedOptions(bool on) async => _put(
    _advancedKey,
    '$on',
    (await _current()).copyWith(advancedOptions: on),
  );

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
    await store.delete(_snapshotKey(chain));
    state = AsyncData(
      current.copyWith(
        historyExportedAt: {...current.historyExportedAt}..remove(chain.name),
        historyReminderDismissedAt: {...current.historyReminderDismissedAt}
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
}
