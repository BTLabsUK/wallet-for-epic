// SPDX-License-Identifier: Apache-2.0
/// The web demo's own screens and controls (`app/README.md` "Web demo"): the gate before the
/// app's usual start, the welcome and ended screens, the Demo stripe with the countdown,
/// Get test coins and End demo. Nothing here shows unless [demoModeProvider] is on. The demo
/// is the app itself, so nothing here points to another app, a store or a download.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo.dart';
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../settings.dart' show clockProvider;
import 'app_dialog.dart';
import 'centered_body.dart';
import 'common.dart';
import 'launch_screen.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';
import 'tip.dart';

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
            const BrandHero(),
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
            const BrandHero(),
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

/// Before the first run of a demo: what it is in one line, then Start the demo.
class DemoWelcomeScreen extends ConsumerWidget {
  const DemoWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return _DemoStartScaffold(
      startLabel: l.demoStart,
      children: [
        BrandHero(title: l.demoWelcomeTitle, wordmark: null),
        const SizedBox(height: 12),
        Text(
          l.demoWelcomeLine,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

/// After a demo ran out: it ended, then Start again.
class DemoEndedScreen extends ConsumerWidget {
  const DemoEndedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return _DemoStartScaffold(
      startLabel: l.demoStartAgain,
      children: [
        BrandHero(title: l.demoEndedTitle, wordmark: null),
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
/// at the bottom.
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
        bottom: BusyButton(
          label: widget.startLabel,
          busy: _busy,
          onPressed: _start,
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

/// The key of the Demo stripe with the countdown, for tests.
const Key demoCountdownKey = ValueKey('demo-countdown');

/// The stripe's words, for tests.
const Key demoStripeTextKey = ValueKey('demo-stripe-text');

/// The demo's mark on every screen (B-05): a thin full-width stripe under the app bar,
/// "Demo · Test coins · 5 h left", in the in-progress blue, never the brand's gold, so no
/// screenshot of the demo passes for a real wallet. `SlotScaffold` puts it on every screen; it
/// draws nothing outside a running demo. Its tooltip says the coins have no value and when the
/// demo ends. Warns once at [demoWarningAt] left, and asks the server again when the time is
/// up. (It replaces the small Test coins pill that sat beside Wallet's title.)
class DemoStripe extends ConsumerStatefulWidget {
  const DemoStripe({super.key});

  @override
  ConsumerState<DemoStripe> createState() => _DemoStripeState();
}

class _DemoStripeState extends ConsumerState<DemoStripe> {
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
    final t = context.tokens;
    final time = left.hours > 0
        ? l.demoLeftHours(left.hours)
        : l.demoLeftMinutes(left.minutes);
    return Tip.value(
      '${l.demoTestCoinsPillTip}\n'
      '${l.demoEndsAt(formatDateTime(l, status.expiresAt.toLocal()))}',
      key: demoCountdownKey,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: t.infoSoft,
          border: Border(bottom: BorderSide(color: t.info.withValues(alpha: 0.4))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_outlined, size: 16, color: t.info),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                metaLine([l.demoStripeLabel, l.demoTestCoinsPill, time]),
                key: demoStripeTextKey,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: t.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The key of Get test coins, for tests.
const Key testCoinsKey = ValueKey('demo-test-coins');

/// Get test coins: asks the faucet for coins to the epicbox address, and says how it went in
/// a notice. Disabled while any claim runs. [primary] makes it the screen's main button, as
/// in the demo's checklist.
class TestCoinsButton extends ConsumerWidget {
  const TestCoinsButton({super.key, this.primary = false});

  final bool primary;

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
    final style = FilledButton.styleFrom(minimumSize: const Size(48, 48));
    final icon = running
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.water_drop_outlined);
    final label = Text(context.l10n.demoTestCoins);
    final onPressed = running ? null : () => _claim(context, ref);
    return primary
        ? FilledButton.icon(
            key: testCoinsKey,
            style: style,
            icon: icon,
            label: label,
            onPressed: onPressed,
          )
        : FilledButton.tonalIcon(
            key: testCoinsKey,
            style: style,
            icon: icon,
            label: label,
            onPressed: onPressed,
          );
  }
}

/// End demo, in Settings: confirm, end the demo on the server, then the welcome screen.
Future<void> endDemo(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final confirmed = await confirmAppDialog(
    context,
    title: l.demoEndTitle,
    icon: Icons.logout,
    description: l.demoEndBody,
    cancelLabel: l.commonCancel,
    confirmLabel: l.demoEnd,
    risk: true,
  );
  if (!confirmed || !context.mounted) return;
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
