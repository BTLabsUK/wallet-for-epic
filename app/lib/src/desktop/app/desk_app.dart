import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme.dart';
import '../widgets/kit.dart';
import 'screens.dart';
import 'shell.dart';

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
    // Before anything reads a token: the theme below and every screen size from it. The BT Labs
    // Theme's 100 % is a 17 px root (6.1.6's MODERN_BASE), the tokens are written for 16.
    deskScale = (deskScales.contains(scale) ? scale : 100) / 100 * deskBase;
    return MaterialApp(
      navigatorKey: deskNavigatorKey,
      title: 'Epic Cash Wallet',
      debugShowCheckedModeBanner: false,
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
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: DeskTextScaler(mq.textScaler, deskScale)),
          child: KeyedSubtree(key: ValueKey(deskScale), child: child!),
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
    // Started straight on an in-app page (WFE_DESK_START, the tour): load the mock wallet.
    if (!ref.read(deskNavProvider).route.bare) ref.read(deskProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final at = ref.watch(deskNavProvider);
    final child = at.route.bare
        ? Material(color: context.dc.bg, child: KeyedSubtree(key: ValueKey(at.route), child: deskScreen(at)))
        : DeskShell(at: at);
    return AnimatedSwitcher(duration: Dur.base, child: KeyedSubtree(key: ValueKey(at.route.bare), child: child));
  }
}

/// The platform's text scale (the system's text size setting) times the interface scale, each
/// size rounded to a whole pixel.
class DeskTextScaler extends TextScaler {
  const DeskTextScaler(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale((fontSize * factor).roundToDouble());

  @Deprecated('Use scale() instead.')
  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) => other is DeskTextScaler && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}
