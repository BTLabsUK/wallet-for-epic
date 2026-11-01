// SPDX-License-Identifier: Apache-2.0
import 'settings_file_watch.dart';
import '../../invite_links.dart' show inviteInboxProvider;
import '../../app_info.dart';
import '../../l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../desk_l10n.dart' show deskStrings;
import '../theme/theme.dart';
import '../../ui/more_below.dart';
import '../widgets/kit.dart';
import 'screens.dart';
import 'auto_lock.dart';
import 'close_guard.dart';
import 'title_bar.dart';
import 'shell.dart';
import 'tour.dart';

/// The app's navigator: dialogs and drawers live on it (lock closes them).
final deskNavigatorKey = GlobalKey<NavigatorState>();

/// The desktop interface's root. Expects a `ProviderScope` above it. Dark by default; the
/// theme follows Settings › Appearance.
class DeskApp extends ConsumerWidget {
  const DeskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(deskProvider.select((s) => s.settings.theme));
    final scale = ref.watch(deskProvider.select((s) => s.settings.scale));
    final language = ref.watch(deskProvider.select((s) => s.settings.language));
    // Before anything reads a token: the theme below and every screen size from it. The BT Labs
    // Theme's 100 % is a 17 px root (6.1.6's MODERN_BASE), the tokens are written for 16.
    deskScale = (deskScales.contains(scale) ? scale : 100) / 100 * deskBase;
    return MaterialApp(
      scrollBehavior: const MoreBelowScrollBehavior(),
      navigatorKey: deskNavigatorKey,
      navigatorObservers: [ref.watch(deskModalWatchProvider)],
      title: appName,
      debugShowCheckedModeBanner: false,
      // The app's own translations (lib/l10n). Screens moved to l10n read context.l10n; the
      // rest still speak English whatever the setting says.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: deskLocaleOf(language),
      themeMode: switch (theme) {
        ThemeChoice.system => ThemeMode.system,
        ThemeChoice.dark => ThemeMode.dark,
        ThemeChoice.light => ThemeMode.light,
      },
      theme: buildDeskTheme(Brightness.light),
      darkTheme: buildDeskTheme(Brightness.dark),
      // Interface scale: text through the text scaler, layout through the tokens. The key
      // rebuilds every page and dialog with the new sizes.
      builder: (context, child) {
        deskStrings = context.l10n;
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: DeskTextScaler(mq.textScaler, deskScale)),
          // The window's own title bar above the navigator (title_bar.dart), and the close rule.
          child: KeyedSubtree(
            key: ValueKey(deskScale),
            child: DeskSettingsFileWatch(child: DeskCloseGuard(child: DeskWindowFrame(child: child!))),
          ),
        );
      },
      home: const DeskRoot(),
    );
  }
}

/// Shows the current place: bare screens fill the window, the rest go in [DeskShell].
class DeskRoot extends ConsumerStatefulWidget {
  const DeskRoot({super.key});

  @override
  ConsumerState<DeskRoot> createState() => _DeskRootState();
}

class _DeskRootState extends ConsumerState<DeskRoot> {
  /// Per provider container, so each test's app starts fresh.
  static final _started = Expando<bool>();

  @override
  void initState() {
    super.initState();
    // A scale change rebuilds this widget; settings and the wallet load only the first time.
    final container = ProviderScope.containerOf(context, listen: false);
    if (_started[container] ?? false) return;
    _started[container] = true;
    ref.read(deskProvider.notifier).loadSettings();
    // Invite links from the command line or the runner wait from the start, not only from the
    // unlock (the shell routes them: invite_link_gate.dart).
    ref.read(inviteInboxProvider);
    // Started straight on an in-app page (WFE_DESK_START, the tour): load the mock wallet.
    if (!ref.read(deskNavProvider).route.bare) ref.read(deskProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    // The wallet closed by itself: nothing of it stays, Unlock says why.
    ref.listen(deskClosedProvider, (_, message) {
      if (message == null) return;
      deskNavigatorKey.currentState?.popUntil((r) => r.isFirst);
      ref.read(deskTourProvider.notifier).close();
      ref.read(deskNavProvider.notifier).reset(DeskRoute.unlock, message);
      Future.microtask(() => ref.read(deskClosedProvider.notifier).set(null));
    });
    final at = ref.watch(deskNavProvider);
    final child = at.route.bare
        // A Scaffold, so toasts (showEToast) show on the first-run screens too.
        ? Scaffold(backgroundColor: context.dc.bg, body: KeyedSubtree(key: ValueKey(at.route), child: deskScreen(at)))
        // The open wallet locks itself after the idle time (Settings › Account › Security).
        : DeskAutoLock(child: DeskShell(at: at));
    return DeskNavKeys(
      child: AnimatedSwitcher(
        duration: Dur.base,
        // The page fading out gives up the focus at once: still holding it, it would keep the
        // incoming page's autofocus (Unlock's password after a Lock or a wallet switch) from
        // taking it, and leave nothing focused when it goes.
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            builder: (_, child) => ExcludeFocus(excluding: !animation.status.isForwardOrCompleted, child: child!),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(at.route.bare), child: child),
      ),
    );
  }
}

/// The platform's text scale (the system's text size setting) times the interface scale, each
/// size rounded to a whole pixel.
class DeskTextScaler extends TextScaler {
  const DeskTextScaler(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize * factor).roundToDouble();

  @Deprecated('Use scale() instead.')
  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) => other is DeskTextScaler && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}

/// The locale of Settings › Appearance › Language (a code from `appLanguages`); null follows
/// the computer: the first of its languages the app has, else English (l10n.yaml puts English
/// first among the supported locales).
Locale? deskLocaleOf(String? language) => language == null ? null : Locale(language);
