import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'connection_state.dart';
import 'demo.dart';
import 'demo_web_connection.dart';
import 'l10n.dart';
import 'node_failover_phone.dart';
import 'providers.dart';
import 'push_controller.dart';
import 'secret_store.dart' show PlatformBiometricStore;
import 'settings.dart';
import 'ui/common.dart';
import 'ui/demo_screens.dart';
import 'ui/launch_screen.dart';
import 'ui/phone_frame.dart';
import 'ui/status.dart' show serverHost;
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
    // Alive for the app's life: a node that read offline is asked again when the network
    // returns and on resume.
    ref.listenManual(nodeRecheckProvider, (_, _) {});
    // Alive for the app's life: a node that stops answering is left for the next working one
    // of the list for this session, and the notice says so wherever the user is.
    ref.listenManual(nodeFailoverWatchProvider, (_, _) {});
    ref.listenManual(nodeFailoverProvider, (before, now) {
      final context = _navigator.currentContext;
      if (now == null || now == before || context == null) return;
      ref
          .read(noticeProvider.notifier)
          .show(
            context.l10n.nodeFailoverSwitched(serverHost(now.inUse)),
            level: NoticeLevel.info,
          );
    });
    // Push notifications follow every unlock and the Tor switch (push_controller.dart); what
    // they tell the user is said here, where the language is known.
    ref.listenManual(pushControllerProvider, (_, _) {});
    ref.listenManual(pushNoteProvider, (_, event) {
      final context = _navigator.currentContext;
      if (event == null || context == null) return;
      final l = context.l10n;
      ref
          .read(noticeProvider.notifier)
          .show(
            switch (event.note) {
              PushNote.on => l.pushNoticeOn,
              PushNote.off => l.pushNoticeOff,
              PushNote.offEpicbox => l.pushNoticeOffEpicbox,
              PushNote.available => l.pushNoticeAvailable,
            },
            level: NoticeLevel.info,
          );
    });
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
        // A download Android's network cut stops meanwhile carries on at the return.
        ref.read(updateProvider.notifier).paused();
        if (_leftAt == null &&
            ref.read(sessionProvider) != null &&
            ref.read(autoLockHoldProvider) == 0) {
          _leftAt = ref.read(clockProvider)();
        }
      case AppLifecycleState.resumed:
        // An update that waited for the install permission carries on, lock or no lock.
        unawaited(ref.read(updateProvider.notifier).resumed());
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
          _wakeListener();
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

  /// An Epicbox listener that dropped while the app was away reconnects now, not after
  /// LEPIC's backoff (`ListenerNotifier.wake`), and a node that read offline is asked again
  /// now, not at the next minute's refresh.
  void _wakeListener() {
    unawaited(ref.read(nodeRecheckProvider.notifier).recheck('resume'));
    if (!ref.exists(listenerProvider)) return;
    unawaited(ref.read(listenerProvider.notifier).wake('resume'));
  }

  /// Opening the app again without an unlock looks for an update, as start and unlock do
  /// (home). Coming back from a picker or the scanner (the auto-lock hold) is not an opening.
  void _checkForUpdate() {
    if (ref.read(sessionProvider) == null || ref.read(demoModeProvider)) return;
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
    lockWallet(context, ref, reason: LockReason.timeout);
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
    final demo = ref.watch(demoModeProvider);
    if (demo) listenForDemoEnd(ref, _navigator);
    if (demo) listenForDemoConnection(ref, _navigator);
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
        return PhoneFrame(
          child: AdvancedOptions(
            prefs: settings?.advanced ?? AdvancedPrefs.none,
            child: child!,
          ),
        );
      },
      themeMode: themeMode,
      theme: buildWalletTheme(protocolLight, Brightness.light),
      darkTheme: buildWalletTheme(protocolDark, Brightness.dark),
      // The web demo starts at its welcome screen, or its ended screen, before the usual start.
      home: demo ? const DemoGate() : const LaunchScreen(),
    );
  }
}
