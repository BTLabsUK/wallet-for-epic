/// Display and security preferences. Not secret, but kept in the same [SecretStore] as the
/// network choice so the app needs no preferences dependency.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

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
  });

  final ThemeMode themeMode;

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

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? fiatCurrency,
    bool? showFiat,
    bool? hideBalances,
    int? Function()? autoLockMinutes,
    bool? pushNotifications,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    fiatCurrency: fiatCurrency ?? this.fiatCurrency,
    showFiat: showFiat ?? this.showFiat,
    hideBalances: hideBalances ?? this.hideBalances,
    autoLockMinutes: autoLockMinutes != null
        ? autoLockMinutes()
        : this.autoLockMinutes,
    pushNotifications: pushNotifications ?? this.pushNotifications,
  );
}

/// Plain words for an auto-lock choice.
String autoLockLabel(int? minutes) => switch (minutes) {
  null => 'Never',
  0 => 'Immediately',
  1 => 'After 1 minute',
  _ => 'After $minutes minutes',
};

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

  Future<void> setAutoLockMinutes(int? minutes) async => _put(
    _autoLockKey,
    minutes?.toString() ?? _never,
    (await _current()).copyWith(autoLockMinutes: () => minutes),
  );

  Future<void> setPushNotifications(bool on) async =>
      _put(_pushKey, '$on', (await _current()).copyWith(pushNotifications: on));
}
