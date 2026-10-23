/// The web demo's checklist on the Wallet tab (design review F-03, mockup C): get test coins,
/// then send some to someone. The steps tick from the wallet's own history, so a reload, or a
/// visitor coming back to a demo that already paid, finds them ticked. Nothing here shows
/// unless [demoModeProvider] is on.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo.dart';
import '../l10n.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'demo_screens.dart' show TestCoinsButton;
import 'theme/protocol.dart';
import 'theme/tokens.dart';

/// The key of the checklist card, for tests.
const Key demoGuideKey = ValueKey('demo-guide');

/// Whether the visitor hid the checklist. In memory for the open wallet: a reload shows it
/// again, with its steps ticked.
final demoGuideHiddenProvider = NotifierProvider<DemoGuideHidden, bool>(
  DemoGuideHidden.new,
);

class DemoGuideHidden extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(sessionProvider);
    return false;
  }

  void hide() => state = true;
}

/// Which steps the wallet has done: [coins] once anything came in (spendable, confirming or
/// still waiting for its sender), [sent] once it has an outgoing payment that was not
/// cancelled, answered or not.
({bool coins, bool sent}) demoGuideSteps(
  WalletSummary? summary,
  Iterable<TxEntry> transactions,
) {
  final received = transactions.any(
    (t) => t.kind == TxKind.received && t.status != TxStatus.cancelled,
  );
  final balance =
      summary != null &&
      (summary.total > BigInt.zero ||
          summary.awaitingFinalization > BigInt.zero);
  return (
    coins: received || balance,
    sent: transactions.any((t) => t.kind == TxKind.sent),
  );
}

/// Whether the checklist shows: in the demo, with the wallet's history loaded, until hidden.
bool demoGuideShown(WidgetRef ref) =>
    ref.watch(demoModeProvider) &&
    !ref.watch(demoGuideHiddenProvider) &&
    ref.watch(homeProvider.select((h) => h.value != null));

/// The checklist card: a heading with Hide, then the two steps as a list. The current step
/// carries its button; while the faucet works, one line says so. With both done, a closing
/// line under the ticked steps.
class DemoGuide extends ConsumerWidget {
  const DemoGuide({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!demoGuideShown(ref)) return const SizedBox.shrink();
    final data = ref.watch(homeProvider).requireValue;
    final (:coins, :sent) = demoGuideSteps(data.summary, data.transactions);
    final asking = ref.watch(testCoinsProvider);
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final hint = theme.textTheme.bodyMedium?.copyWith(color: t.dim);
    return EdgeCard(
      key: demoGuideKey,
      edge: t.accent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l.demoGuideTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () =>
                      ref.read(demoGuideHiddenProvider.notifier).hide(),
                  child: Text(
                    l.demoGuideHide,
                    semanticsLabel: l.demoGuideHideLabel,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Semantics(
                role: SemanticsRole.list,
                container: true,
                explicitChildNodes: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Step(
                      number: 1,
                      text: l.demoTestCoins,
                      done: coins,
                      current: !coins,
                      children: [
                        if (asking)
                          Semantics(
                            liveRegion: true,
                            child: Text(l.demoGuideAsking, style: hint),
                          ),
                        const Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TestCoinsButton(primary: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Step(
                      number: 2,
                      text: l.demoGuideSend,
                      done: sent,
                      current: coins && !sent,
                      children: [
                        Text(l.demoGuideSendHint, style: hint),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            icon: const Icon(Icons.north_east),
                            label: Text(l.demoGuideOpenSend),
                            onPressed: () => ref
                                .read(shellTabProvider.notifier)
                                .go(ShellTab.send),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (coins && sent) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(l.demoGuideDone, style: hint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One step: its marker (number, or a tick once [done]) and words, which screen readers hear
/// with the state and again when it changes; under them [children] while it is [current].
class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.text,
    required this.done,
    required this.current,
    required this.children,
  });

  final int number;
  final String text;
  final bool done;
  final bool current;
  final List<Widget> children;

  static const double _marker = 24, _gap = 12;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final Widget marker = done
        ? Icon(Icons.check_circle, size: _marker, color: t.ok)
        : DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: current ? t.info : t.lineStrong,
                width: 1.5,
              ),
            ),
            child: SizedBox.square(
              dimension: _marker,
              child: Center(
                child: Text(
                  localDigits(l, '$number'),
                  textScaler: TextScaler.noScaling,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: current ? t.info : t.dim,
                  ),
                ),
              ),
            ),
          );
    return Semantics(
      role: SemanticsRole.listItem,
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            liveRegion: true,
            label: done ? l.demoGuideStepDone(text) : l.demoGuideStepToDo(text),
            excludeSemantics: true,
            child: Row(
              children: [
                marker,
                const SizedBox(width: _gap),
                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: done ? t.dim : t.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (current && children.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: _marker + _gap,
                top: 6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: children,
              ),
            ),
        ],
      ),
    );
  }
}
