import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'push.dart';
import 'settings.dart';
import 'ui/common.dart';
import 'ui/launch_screen.dart';

const Color _seed = Color(0xFF5B3FD0);

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
    // Payment notifications start only once the user turned them on. Firebase cannot be shut
    // down in-process, so turning them off takes effect at the next start.
    ref.listenManual(
      appSettingsProvider.select((s) => s.value?.pushNotifications ?? false),
      (_, on) {
        if (on) ref.read(pushProvider.notifier).start();
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
          return;
        }
        if (_timedOut()) {
          if (ref.read(scanProvider).running) {
            _lockAfterScan = true;
          } else {
            _lock();
          }
        }
        _leftAt = null;
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        // Inactive covers system dialogs such as the biometric prompt; it is not leaving.
        break;
    }
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
    final themeMode =
        ref.watch(appSettingsProvider).value?.themeMode ?? ThemeMode.system;
    return MaterialApp(
      title: 'Epic Cash Wallet',
      navigatorKey: _navigator,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seed)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      ),
      home: const LaunchScreen(),
    );
  }
}
