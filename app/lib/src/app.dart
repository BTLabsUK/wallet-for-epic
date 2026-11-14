// SPDX-License-Identifier: Apache-2.0
import 'scan/incoming_link.dart' show incomingLinkProvider;
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'connection_state.dart';
import 'l10n.dart';
import 'node_failover_phone.dart';
import 'price.dart' show priceProvider;
import 'relay_switch_providers.dart' show relayDrainWatchProvider, relaySwitchProvider;
import 'providers.dart';
import 'restore_scan.dart';
import 'secret_store.dart' show PlatformBiometricStore;
import 'settings.dart';
import 'ui/settings_file_notices.dart';
import 'ui/common.dart';
import 'ui/kit/kit_tokens.dart' show Kit;
import 'ui/more_below.dart';
import 'ui/launch_screen.dart';
import 'ui/phone_frame.dart';
import 'ui/theme/advanced.dart';
import 'ui/theme/tokens.dart';
import 'updater.dart';

/// The web preview build (tool/build_preview.sh): shows the Demo label.
const bool _demoLabel = bool.fromEnvironment('WFE_WEB_FAKE');

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

  /// Runs while the app is away with a wallet open: Android keeps the process, and with it the
  /// session and its listener, so the wallet closes when the auto-lock time passes there. iOS
  /// suspends it, and the check on resume locks instead.
  Timer? _awayTimer;

  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onStateChange: _onLifecycle,
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
    // Alive for the app's life: it drains the payments address whenever a wallet opens.
    ref.listenManual(paymentsDrainProvider, (_, _) {});
    // Alive for the app's life: a link another app opened is taken from the start, so an invite
    // waits in the invite inbox until a wallet is open (invite_links.dart), and a payment link's
    // wait for the unlock counts from its arrival (linkMaxAge).
    ref.listenManual(incomingLinkProvider, (_, _) {});
    // Alive for the app's life: a node that read offline is asked again when the network
    // returns and on resume.
    ref.listenManual(nodeRecheckProvider, (_, _) {});
    // Alive for the app's life: a node that stops answering is left for the best working one
    // of the list for this session; the status card names the node in use.
    ref.listenManual(nodeFailoverWatchProvider, (_, _) {});
    // A wallet rebuilt from its phrase finishes its scan from block 0 by itself, after every
    // unlock (restore_scan.dart); Home shows where it stands.
    ref.listenManual(restoreScanProvider, (_, _) {});
    // Alive for the app's life: an Epicbox relay down for a while is offered a
    // one-tap move (never made by itself), and an address left behind is read for 30 days.
    ref.listenManual(relaySwitchProvider, (_, _) {});
    ref.listenManual(relayDrainWatchProvider, (_, _) {});
  }

  @override
  void dispose() {
    _awayTimer?.cancel();
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
        // A download Android's network cut stops meanwhile carries on at the return, and so
        // does a scan.
        ref.read(updateProvider.notifier).paused();
        ref.read(scanProvider.notifier).pause();
        ref.read(nodeFailoverWatchProvider.notifier).paused();
        ref.read(relaySwitchProvider.notifier).paused();
        if (ref.exists(priceProvider)) ref.read(priceProvider.notifier).paused();
        if (_leftAt == null &&
            ref.read(sessionProvider) != null &&
            ref.read(autoLockHoldProvider) == 0) {
          _leftAt = ref.read(clockProvider)();
          _armAwayTimer();
        }
      case AppLifecycleState.resumed:
        _awayTimer?.cancel();
        _awayTimer = null;
        // An update that waited for the install permission carries on, lock or no lock.
        unawaited(ref.read(updateProvider.notifier).resumed());
        // First: the scan's first request must not go out on a connection the system cut.
        ref.read(nodeFailoverWatchProvider.notifier).resumed();
        _resumeScan();
        ref.read(relaySwitchProvider.notifier).resumed();
        if (ref.exists(priceProvider)) ref.read(priceProvider.notifier).resumed();
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

  /// A scan the background paused goes on, with a note: Settings shows a Recheck only as a
  /// thin bar, so the progress line alone would not say it.
  void _resumeScan() {
    final paused = ref.read(scanProvider).paused;
    ref.read(scanProvider.notifier).resume();
    final context = _navigator.currentContext;
    if (!paused || context == null) return;
    ref
        .read(noticeProvider.notifier)
        .show(context.l10n.scanResumedNotice, level: NoticeLevel.info);
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

  /// The setting as it is now; a change while away counts from the next time away.
  void _armAwayTimer() {
    _awayTimer?.cancel();
    _awayTimer = null;
    final settings = ref.read(appSettingsProvider).value ?? const AppSettings();
    final minutes = settings.autoLockMinutes;
    if (minutes == null) return;
    _awayTimer = Timer(Duration(minutes: minutes), _lockAway);
  }

  /// The auto-lock time passed in the background. A scan is not cut: it locks once it ends,
  /// as after a return ([_onScanEnded], and the check on resume).
  void _lockAway() {
    _awayTimer = null;
    if (_leftAt == null || ref.read(autoLockHoldProvider) > 0) return;
    if (ref.read(scanProvider).running) return;
    _lock(away: true);
  }

  void _onScanEnded() {
    if (_lockAfterScan || (_leftAt != null && _timedOut())) _lock();
  }

  void _lock({bool away = false}) {
    _lockAfterScan = false;
    _leftAt = null;
    _awayTimer?.cancel();
    _awayTimer = null;
    final context = _navigator.currentContext;
    if (context == null || ref.read(sessionProvider) == null) return;
    logInfo('session', away ? 'auto-lock in background' : 'auto-lock');
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
        _awayTimer?.cancel();
        _awayTimer = null;
      }
    });
    final settings = ref.watch(appSettingsProvider).value;
    final themeMode = settings?.themeMode ?? ThemeMode.system;
    return MaterialApp(
      scrollBehavior: const MoreBelowScrollBehavior(),
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
        final framed = PhoneFrame(
          child: _BottomGap(
          child: SettingsFileNotices(
            child: AdvancedOptions(
              prefs: ref.watch(advancedPrefsProvider),
              child: child!,
            ),
          ),
          ),
        );
        // The web preview is a demo and says so on every screen (WFE_WEB_FAKE is never set in
        // a real build, so this branch is removed from it).
        if (!_demoLabel) return framed;
        return Stack(
          children: [
            framed,
            Positioned(
              top: 4,
              right: 6,
              child: SafeArea(
                child: IgnorePointer(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Semantics(
                      label: 'Demo',
                      child: ExcludeSemantics(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xCC000000),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            child: Text(
                              'Demo',
                              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      themeMode: themeMode,
      theme: buildWalletTheme(protocolLight, Brightness.light),
      darkTheme: buildWalletTheme(protocolDark, Brightness.dark),
      home: const LaunchScreen(),
    );
  }
}

/// Keeps [Kit.gutter] between the screen's bottom edge and whatever a page stands on it (a
/// button, a sheet's last row, the tab bar) where the system gives no bottom inset (a phone
/// with no gesture bar, the web preview, a desktop window): the frames' `.foot` never sits on
/// the edge. A real inset larger than that is kept as it is; the keyboard's inset is not touched.
class _BottomGap extends StatelessWidget {
  const _BottomGap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.viewPadding.bottom >= Kit.gutter) return child;
    return MediaQuery(
      data: media.copyWith(
        padding: media.viewInsets.bottom > 0 ? media.padding : media.padding.copyWith(bottom: math.max(media.padding.bottom, Kit.gutter)),
        viewPadding: media.viewPadding.copyWith(bottom: Kit.gutter),
      ),
      child: child,
    );
  }
}
