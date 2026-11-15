// SPDX-License-Identifier: Apache-2.0
/// Settings › Payments for epic1: the epic1 method row, the Printed links row and the Printed
/// links page.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../epic1.dart';
import '../../errors.dart';
import '../../l10n.dart';
import '../../providers.dart';
import '../../settings.dart' show AppSettings, appSettingsProvider;
import '../../trust_ids.dart';
import '../app_dialog.dart';
import '../common.dart';
import '../kit/kit_ground.dart' show KitGround;
import '../kit/kit_row.dart';
import '../theme/epic1_mark.dart' show Epic1Glyph;
import '../theme/tokens.dart';
import 'epic1_common.dart';

/// Keys for tests and the screenshot tour.
const Key epic1SwitchKey = ValueKey('epic1-switch');
const Key epic1PrintedKey = ValueKey('epic1-printed');

/// How many printed links a wallet holds.
const int epic1PrintedMax = 32;

/// The epic1 row among the payment methods: its switch writes [PaymentPrefs.epic1] and applies
/// at once. It is no route of a classic payment, so it never counts for the last method that
/// stays on. Nothing on a core without epic1.
class Epic1MethodRow extends ConsumerWidget {
  const Epic1MethodRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    if (ref.watch(epic1Provider) == null) return const SizedBox.shrink();
    final payments = (ref.watch(appSettingsProvider).value ?? const AppSettings()).payments;
    return KitRow.toggle(
      key: epic1SwitchKey,
      leading: KitIconWell.child(Epic1Glyph(size: 20, color: context.tokens.accentText)),
      title: l.deskE1SetSwitch,
      titleMarks: true,
      size: KitRowSize.list,
      subtitle: l.deskE1SetInfo,
      subtitleLines: 3,
      value: payments.epic1,
      onChanged: (on) => ref.read(appSettingsProvider.notifier).setPayments(payments.copyWith(epic1: on)),
      semanticsId: TrustIds.paymentsEpic1,
    );
  }
}

/// The rows of the epic1 method, for the methods group: the switch, then Printed links while
/// epic1 is on.
List<Widget> epic1MethodRows(WidgetRef ref) => [
  if (ref.watch(epic1Provider) != null) const Epic1MethodRow(),
  if (ref.watch(epic1OnProvider)) const Epic1PrintedRow(),
];

/// The printed links of this wallet; the links are read once per build of the page.
final epic1PrintedProvider = FutureProvider.autoDispose<List<Epic1LinkSlot>>((ref) async {
  final epic1 = ref.watch(epic1Provider);
  if (epic1 == null) return const [];
  final all = await epic1.links();
  return [for (final s in all) if (s.kind == Epic1LinkKind.printed) s]..sort((a, b) => a.n.compareTo(b.n));
});

/// "Printed links" with "n of 32"; opens [PrintedCodesScreen].
class Epic1PrintedRow extends ConsumerWidget {
  const Epic1PrintedRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final count = ref.watch(epic1PrintedProvider).value?.length;
    return KitRow(
      key: epic1PrintedKey,
      leading: KitIconWell(Icons.qr_code_2, color: context.tokens.accentText, iconSize: 20),
      title: l.deskE1PhPrinted,
      value: count == null ? null : l.deskE1PhPrintedCount(count, epic1PrintedMax),
      chevron: true,
      size: KitRowSize.list,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PrintedCodesScreen())),
    );
  }
}

/// The printed links, each with Retire.
class PrintedCodesScreen extends ConsumerWidget {
  const PrintedCodesScreen({super.key});

  Future<void> _retire(BuildContext context, WidgetRef ref, Epic1LinkSlot slot) async {
    final l = context.l10n;
    final epic1 = ref.read(epic1Provider);
    if (epic1 == null) return;
    final yes = await askEpic1(
      context,
      title: l.deskE1Retire,
      body: l.deskE1RetireAsk(slot.n),
      yes: l.deskE1Retire,
      no: l.deskE1Keep,
      tone: DialogTone.warn,
      yesKey: const ValueKey('epic1-retire-yes'),
    );
    if (!yes) return;
    final notices = ref.read(noticeProvider.notifier);
    try {
      await epic1.retireLink(slot.n);
      notices.show(l.deskE1PhRetired(slot.n), level: NoticeLevel.success);
    } catch (e) {
      notices.show(describeError(l, e), level: NoticeLevel.error);
    }
    ref.invalidate(epic1PrintedProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final codes = ref.watch(epic1PrintedProvider);
    return KitGround(child: Scaffold(
      appBar: AppBar(title: Text(l.deskE1PhPrinted)),
      body: SafeArea(
        child: switch (codes) {
          AsyncValue(:final error?) => Center(
            child: Padding(padding: const EdgeInsets.all(24), child: Text(describeError(l, error), textAlign: TextAlign.center)),
          ),
          AsyncValue(value: final list?) when list.isEmpty => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.deskE1PhPrintedEmpty, style: TextStyle(color: t.dim), textAlign: TextAlign.center),
            ),
          ),
          AsyncValue(value: final list?) => ListView(
            children: [
              for (final slot in list)
                ListTile(
                  key: ValueKey('epic1-printed-${slot.n}'),
                  leading: const Icon(Icons.qr_code_2),
                  title: Text(l.deskE1PhPrintedCode(slot.n)),
                  subtitle: Text(
                    [
                      l.deskE1PhPrintedMade(formatDateTime(l, slot.issuedAt)),
                      if (slot.usedAt != null) l.deskE1PhPrintedUsed,
                    ].join(' · '),
                    style: TextStyle(color: t.dim),
                  ),
                  trailing: TextButton(
                    key: ValueKey('epic1-retire-${slot.n}'),
                    onPressed: () => _retire(context, ref, slot),
                    child: Text(l.deskE1Retire),
                  ),
                ),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    ));
  }
}
