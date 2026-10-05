import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'l10n.dart';
import 'providers.dart';
import 'push.dart';
import 'secret_store.dart' show PlatformBiometricStore;
import 'settings.dart';
import 'ui/common.dart';
import 'ui/launch_screen.dart';
import 'ui/theme/advanced.dart';
import 'ui/theme/tokens.dart';
import 'updater.dart';

/// Root widget. Expects a `ProviderScope` above it.
class WalletApp extends ConsumerStatefulWidget {
  const WalletApp({super.key});

  @override
  ConsumerState<WalletApp> createState() => _WalletAppState();
}

class _WalletAppState extends ConsumerState<WalletApp> {
  final _navigator = GlobalKey<NavigatorState>();

  /// When the app last went to the background with a wallet open, until it locks or resumes.
  DateTime? _leftAt;

  /// The timeout passed while a scan was running; lock once it ends.
  bool _lockAfterScan = false;

  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onStateChange: _onLifecycle,
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
    // Alive for the app's life: it drains the payments address whenever a wallet opens.
    ref.listenManual(paymentsDrainProvider, (_, _) {});
    // Payment notifications start only once the user turned them on. Firebase cannot be shut
    // down in-process, so turning them off takes effect at the next start.
    ref.listenManual(
      appSettingsProvider.select((s) => s.value?.pushNotifications ?? false),
      (_, on) async {
        if (!on) return;
        final permitted = await ref.read(pushProvider.notifier).start();
        // Denied in system settings: the switch goes back off and settings says why.
        if (!permitted && mounted) {
          await ref
              .read(appSettingsProvider.notifier)
              .setPushNotifications(false);
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.resumed) {
      logInfo('app', state.name);
    }
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        if (_leftAt == null &&
            ref.read(sessionProvider) != null &&
            ref.read(autoLockHoldProvider) == 0) {
          _leftAt = ref.read(clockProvider)();
        }
      case AppLifecycleState.resumed:
        if (ref.read(autoLockHoldProvider) > 0) {
          _leftAt = null;
          _drainPayments();
          return;
        }
        if (_timedOut()) {
          if (ref.read(scanProvider).running) {
            _lockAfterScan = true;
          } else {
            // The unlock that follows checks for an update.
            _lock();
          }
        } else {
          _drainPayments();
          // Only after the app was away: a system dialog (inactive) is not an opening.
          if (_leftAt != null) _checkForUpdate();
        }
        _leftAt = null;
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        // Inactive covers system dialogs such as the biometric prompt; it is not leaving.
        break;
    }
  }

  /// Payments that reached the payments address while the app was away are finalized on
  /// return, beside the listener. The provider also drains when a wallet opens.
  void _drainPayments() {
    if (ref.read(sessionProvider) == null) return;
    unawaited(ref.read(paymentsDrainProvider.notifier).drain());
  }

  /// Opening the app again without an unlock looks for an update, as start and unlock do
  /// (home). Coming back from a picker or the scanner (the auto-lock hold) is not an opening.
  void _checkForUpdate() {
    if (ref.read(sessionProvider) == null) return;
    unawaited(ref.read(updateProvider.notifier).checkOnOpening());
  }

  /// Whether the time away reached the auto-lock setting.
  bool _timedOut() {
    final leftAt = _leftAt;
    final settings = ref.read(appSettingsProvider).value ?? const AppSettings();
    final minutes = settings.autoLockMinutes;
    if (leftAt == null || minutes == null) return false;
    final away = ref.read(clockProvider)().difference(leftAt);
    return away >= Duration(minutes: minutes);
  }

  void _onScanEnded() {
    if (_lockAfterScan || (_leftAt != null && _timedOut())) _lock();
  }

  void _lock() {
    _lockAfterScan = false;
    _leftAt = null;
    final context = _navigator.currentContext;
    if (context == null || ref.read(sessionProvider) == null) return;
    logInfo('session', 'auto-lock');
    lockWallet(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scanProvider.select((s) => s.running), (was, running) {
      if (was == true && !running) _onScanEnded();
    });
    ref.listen(sessionProvider, (_, session) {
      if (session == null) {
        _leftAt = null;
        _lockAfterScan = false;
      }
    });
    final settings = ref.watch(appSettingsProvider).value;
    final themeMode = settings?.themeMode ?? ThemeMode.system;
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      navigatorKey: _navigator,
      debugShowCheckedModeBanner: false,
      // Null follows the system's languages; Flutter picks the first one we translate, else
      // English (the first supported locale).
      locale: settings?.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        // The system biometric prompt is not a widget, so it gets the current words here.
        final biometrics = ref.read(biometricStoreProvider);
        if (biometrics is PlatformBiometricStore) {
          final l = context.l10n;
          biometrics.prompt = (
            title: l.biometricPromptTitle,
            subtitle: l.biometricPromptSubtitle,
            usePin: l.biometricPromptUsePin,
          );
        }
        return AdvancedOptions(
          enabled: settings?.advancedOptions ?? false,
          child: child!,
        );
      },
      themeMode: themeMode,
      theme: buildWalletTheme(protocolLight, Brightness.light),
      darkTheme: buildWalletTheme(protocolDark, Brightness.dark),
      home: const LaunchScreen(),
    );
  }
}
