/// The web demo's own screens and controls (`app/README.md` "Web demo"): the gate before the
/// app's usual start, the welcome and ended screens, the countdown beside the network name,
/// Get test coins, Get the app and End demo. Nothing here shows unless [demoModeProvider] is on.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo.dart';
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../settings.dart' show clockProvider;
import 'centered_body.dart';
import 'common.dart';
import 'launch_screen.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';

/// The demo's first route, in place of [LaunchScreen]: welcome without a demo, the ended
/// screen after one ran out, and the usual start (PIN unlock or first run) during one.
class DemoGate extends ConsumerWidget {
  const DemoGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return switch (ref.watch(demoStatusProvider)) {
      AsyncData(value: DemoActive()) => const LaunchScreen(),
      AsyncData(value: DemoEnded()) => const DemoEndedScreen(),
      AsyncData(value: DemoNone()) => const DemoWelcomeScreen(),
      AsyncError(:final error) => SlotScaffold(
        centered: true,
        glow: heroGlow,
        body: CenteredBody(
          children: [
            BrandHero(title: l.appTitle),
            const SizedBox(height: 32),
            ErrorText(describeError(l, error)),
            BusyButton(
              label: l.launchTryAgain,
              onPressed: () => ref.invalidate(demoStatusProvider),
            ),
          ],
        ),
      ),
      _ => SlotScaffold(
        centered: true,
        glow: heroGlow,
        body: CenteredBody(
          children: [
            BrandHero(title: l.appTitle),
            const SizedBox(height: 32),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    };
  }
}

/// Shows the ended screen over everything once a running demo ends, from whatever screen is
/// up. The app root calls it in demo mode, with its navigator.
void listenForDemoEnd(WidgetRef ref, GlobalKey<NavigatorState> navigator) {
  ref.listen(demoStatusProvider, (previous, next) {
    if (previous?.value is! DemoActive || next.value is! DemoEnded) return;
    ref.read(noticeProvider.notifier).clear();
    ref.read(sessionProvider.notifier).lock();
    navigator.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const DemoGate()),
      (_) => false,
    );
  });
}

/// Before the first run of a demo: what it is, then Start the demo and Get the app.
class DemoWelcomeScreen extends ConsumerWidget {
  const DemoWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return _DemoStartScaffold(
      startLabel: l.demoStart,
      children: [
        BrandHero(title: l.demoWelcomeTitle),
        const SizedBox(height: 12),
        Text(
          l.demoWelcomeLine,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _Fact(icon: Icons.science_outlined, text: l.demoWelcomeNoValue),
        _Fact(icon: Icons.language, text: l.demoWelcomeNothingToInstall),
        _Fact(icon: Icons.timer_outlined, text: l.demoWelcomeDeleted),
      ],
    );
  }
}

/// After a demo ran out: it ended, then Start again and Get the app.
class DemoEndedScreen extends ConsumerWidget {
  const DemoEndedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return _DemoStartScaffold(
      startLabel: l.demoStartAgain,
      children: [
        BrandHero(title: l.demoEndedTitle),
        const SizedBox(height: 12),
        Text(
          l.demoEndedBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

/// The lit hero layout of the welcome and ended screens, with the button that starts a demo
/// and Get the app at the bottom.
class _DemoStartScaffold extends ConsumerStatefulWidget {
  const _DemoStartScaffold({required this.startLabel, required this.children});

  final String startLabel;
  final List<Widget> children;

  @override
  ConsumerState<_DemoStartScaffold> createState() => _DemoStartScaffoldState();
}

class _DemoStartScaffoldState extends ConsumerState<_DemoStartScaffold> {
  bool _busy = false;
  String? _error;

  /// Starts a demo; [DemoGate] then shows the usual first run.
  Future<void> _start() async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(demoStatusProvider.notifier).start();
    } catch (error) {
      if (mounted) setState(() => _error = describeError(l, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlotScaffold(
      glow: heroGlow,
      body: ScreenBody(
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BusyButton(
              label: widget.startLabel,
              busy: _busy,
              onPressed: _start,
            ),
            const GetAppButton(),
          ],
        ),
        children: [
          const SizedBox(height: 24),
          ...widget.children,
          if (_error case final error?) ...[
            const SizedBox(height: 16),
            ErrorText(error),
          ],
        ],
      ),
    );
  }
}

/// One of the welcome screen's short facts.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: context.tokens.accentText),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

/// Opens the configured download page; nothing without one ([DemoApi.downloadUrl]).
class GetAppButton extends ConsumerWidget {
  const GetAppButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(demoApiProvider);
    final url = api.downloadUrl;
    if (url == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextButton.icon(
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        icon: const Icon(Icons.install_mobile),
        label: Text(context.l10n.demoGetApp),
        onPressed: () => api.openLink(url),
      ),
    );
  }
}

/// Settings' About row that opens the download page; nothing without one.
class GetAppTile extends ConsumerWidget {
  const GetAppTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(demoApiProvider);
    final url = api.downloadUrl;
    if (url == null) return const SizedBox.shrink();
    return ListTile(
      leading: const Icon(Icons.install_mobile),
      title: Text(context.l10n.demoGetApp),
      onTap: () => api.openLink(url),
    );
  }
}

/// The key of the countdown beside the network name, for tests.
const Key demoCountdownKey = ValueKey('demo-countdown');

/// "Demo, ends in 5 h" beside the network name, the exact time in its tooltip. Warns once at
/// [demoWarningAt] left, and asks the server again when the time is up.
class DemoCountdown extends ConsumerStatefulWidget {
  const DemoCountdown({super.key});

  @override
  ConsumerState<DemoCountdown> createState() => _DemoCountdownState();
}

class _DemoCountdownState extends ConsumerState<DemoCountdown> {
  Timer? _tick;
  bool _rechecked = false;

  @override
  void initState() {
    super.initState();
    if (!ref.read(demoModeProvider)) return;
    _tick = Timer.periodic(const Duration(seconds: 15), (_) => _update());
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _update() {
    if (!mounted) return;
    setState(() {});
    final status = ref.read(demoStatusProvider).value;
    if (status is! DemoActive) return;
    final left = status.expiresAt.difference(ref.read(clockProvider)());
    final notifier = ref.read(demoStatusProvider.notifier);
    if (left <= Duration.zero) {
      // The server pushes the end; this only catches one that went missing.
      if (!_rechecked) {
        _rechecked = true;
        unawaited(notifier.recheck().catchError((Object _) {}));
      }
      return;
    }
    if (left <= demoWarningAt && notifier.takeWarning(status.expiresAt)) {
      ref
          .read(noticeProvider.notifier)
          .show(context.l10n.demoEndingSoon, level: NoticeLevel.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(demoStatusProvider).value;
    if (status is! DemoActive) return const SizedBox.shrink();
    final l = context.l10n;
    final left = demoTimeLeft(
      status.expiresAt.difference(ref.watch(clockProvider)()),
    );
    if (left == null) return const SizedBox.shrink();
    final text = left.hours > 0
        ? l.demoEndsInHours(left.hours)
        : l.demoEndsInMinutes(left.minutes);
    return Tooltip(
      key: demoCountdownKey,
      message: l.demoEndsAt(formatDateTime(l, status.expiresAt.toLocal())),
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Align(
          widthFactor: 1,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: context.tokens.dim),
          ),
        ),
      ),
    );
  }
}

/// The key of Get test coins, for tests.
const Key testCoinsKey = ValueKey('demo-test-coins');

/// Get test coins: asks the faucet for coins to the epicbox address, and says how it went in
/// a notice. Disabled while any claim runs.
class TestCoinsButton extends ConsumerWidget {
  const TestCoinsButton({super.key});

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final notices = ref.read(noticeProvider.notifier);
    final String address;
    try {
      address = await ref.read(addressProvider.future);
    } catch (error) {
      notices.show(describeError(l, error), level: NoticeLevel.error);
      return;
    }
    final result = await ref.read(testCoinsProvider.notifier).claim(address);
    switch (result) {
      case null:
        return;
      case TestCoinsPaid():
        notices.show(l.demoTestCoinsPaid, level: NoticeLevel.success);
      case TestCoinsCooldown(:final seconds):
        notices.show(
          l.demoTestCoinsCooldown(seconds),
          level: NoticeLevel.warning,
        );
      case TestCoinsFailed():
        notices.show(l.demoTestCoinsFailed, level: NoticeLevel.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = ref.watch(testCoinsProvider);
    return FilledButton.tonalIcon(
      key: testCoinsKey,
      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      icon: running
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.water_drop_outlined),
      label: Text(context.l10n.demoTestCoins),
      onPressed: running ? null : () => _claim(context, ref),
    );
  }
}

/// End demo, in Settings: confirm, end the demo on the server, then the welcome screen.
Future<void> endDemo(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.demoEndTitle),
      content: Text(l.demoEndBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.demoEnd),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final config = ref.read(walletConfigProvider);
  ref.read(sessionProvider.notifier).lock();
  try {
    await ref.read(demoStatusProvider.notifier).end();
    if (config != null) await ref.read(vaultProvider).forget(config.chain);
  } catch (error) {
    // The server deletes the wallet at its expiry anyway; the visitor gets a fresh start.
    if (context.mounted) {
      ref
          .read(noticeProvider.notifier)
          .show(describeError(l, error), level: NoticeLevel.error);
    }
  }
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const DemoGate()),
    (_) => false,
  );
}
