import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme.dart';
import '../widgets/kit.dart';
import 'screens.dart';
import 'shell.dart';

/// The desktop interface's root. Expects a `ProviderScope` above it. Dark by default; the
/// theme follows Settings › Appearance.
class DeskApp extends ConsumerWidget {
  const DeskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(deskProvider.select((s) => s.settings.theme));
    return MaterialApp(
      title: 'Epic Cash Wallet',
      debugShowCheckedModeBanner: false,
      themeMode: switch (theme) {
        ThemeChoice.system => ThemeMode.system,
        ThemeChoice.dark => ThemeMode.dark,
        ThemeChoice.light => ThemeMode.light,
      },
      theme: buildDeskTheme(Brightness.light),
      darkTheme: buildDeskTheme(Brightness.dark),
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
  @override
  void initState() {
    super.initState();
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
