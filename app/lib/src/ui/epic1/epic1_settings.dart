// SPDX-License-Identifier: Apache-2.0
/// Settings › Transactions in epic1 (spec P1): the Experimental switch, the epic1 section
/// (Epicbox server, Printed links) and the Printed links page.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../advanced.dart' show NetworkModeRestricted;
import '../../epic1.dart';
import '../../errors.dart';
import '../../l10n.dart';
import '../../network.dart' show EpicboxRelay;
import '../../providers.dart';
import '../../settings.dart' show networkModeProvider;
import '../app_dialog.dart';
import '../address_view.dart' show HostText;
import '../common.dart';
import '../network_mode_text.dart' show statusOffByModeWord;
import '../server_picker.dart' show showEpicboxPicker;
import '../settings_rows.dart';
import '../status.dart';
import '../status_icons.dart';
import '../theme/tokens.dart';
import '../theme/epic1_mark.dart';
import 'epic1_common.dart';

/// Keys for tests and the screenshot tour.
const Key epic1SwitchKey = ValueKey('epic1-switch');
const Key epic1TurnOnKey = ValueKey('epic1-turn-on');
const Key epic1AppliesKey = ValueKey('epic1-applies-next');
const Key epic1LockNowKey = ValueKey('epic1-lock-now');
const Key epic1EpicboxKey = ValueKey('epic1-epicbox');
const Key epic1PrintedKey = ValueKey('epic1-printed');

/// How many printed links a wallet holds.
const int epic1PrintedMax = 32;

/// The Experimental section: the "epic1 payments" switch and, while what is stored differs
/// from what this unlock uses, "Applies at next unlock" with Lock now. Nothing on a core
/// without epic1.
List<Widget> epic1ExperimentalRows(AppLocalizations l) => [
  SettingsHeader(l.deskE1PhExperimental),
  const Epic1SwitchRow(),
];

/// The epic1 section and Receiving, which replace the methods in epic1 mode.
List<Widget> epic1ModeRows(AppLocalizations l, {required Widget confirmations}) => [
  SettingsHeader(l.deskE1PhSection),
  const Epic1EpicboxRow(),
  const Epic1PrintedRow(),
  SettingsHeader(l.deskE1PhReceiving),
  confirmations,
];

class Epic1SwitchRow extends ConsumerStatefulWidget {
  const Epic1SwitchRow({super.key});

  @override
  ConsumerState<Epic1SwitchRow> createState() => _Epic1SwitchRowState();
}

class _Epic1SwitchRowState extends ConsumerState<Epic1SwitchRow> {
  /// What was stored on this page; the wallet's stored value is not watched.
  bool? _stored;
  bool _busy = false;

  Future<void> _set(Epic1Wallet epic1, bool on) async {
    final l = context.l10n;
    if (_busy) return;
    if (on &&
        !await askEpic1(
          context,
          title: l.deskE1PhConfirmTitle,
          body: l.deskE1PhConfirmBody,
          yes: l.deskE1PhTurnOn,
          icon: Icons.science_outlined,
          yesKey: epic1TurnOnKey,
        )) {
      return;
    }
    setState(() => _busy = true);
    try {
      await epic1.setStoredOn(on);
      if (mounted) setState(() => _stored = on);
    } catch (e) {
      if (mounted) ref.read(noticeProvider.notifier).show(describeError(l, e), level: NoticeLevel.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final epic1 = ref.watch(epic1Provider);
    if (epic1 == null) return const SizedBox.shrink();
    final stored = _stored ?? epic1.storedOn;
    final pending = stored != epic1.inUse;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HintSwitchTile(
          key: epic1SwitchKey,
          icon: Icons.science_outlined,
          leading: const Epic1Glyph(size: 24),
          title: l.deskE1PhSwitch,
          hint: l.deskE1PhSwitchHint,
          value: stored,
          onChanged: _busy ? null : (on) => _set(epic1, on),
        ),
        if (pending)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(l.deskE1PhAppliesNext, key: epic1AppliesKey, style: TextStyle(color: t.dim)),
                TextButton(
                  key: epic1LockNowKey,
                  onPressed: () => lockWallet(context, ref),
                  child: Text(l.deskE1PhLockNow),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The wallet's Epicbox server with its state, as Network shows it; opens the picker.
class Epic1EpicboxRow extends ConsumerWidget {
  const Epic1EpicboxRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final config = ref.watch(walletConfigProvider);
    final mode = ref.watch(networkModeProvider);
    final face = mode.restricted
        ? (level: SignalLevel.none, color: t.dim, word: statusOffByModeWord(l, mode))
        : epicboxNetFace(context, watchWalletStatus(ref).epicbox);
    final host = config == null ? null : EpicboxRelay(host: config.epicboxDomain, port: config.epicboxPort).label;
    return ListTile(
      key: epic1EpicboxKey,
      leading: const Icon(EpicGlyphs.epicbox),
      title: Text(l.serverEpicboxTitle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (host != null) Align(alignment: AlignmentDirectional.centerStart, child: HostText(host, style: TextStyle(color: t.dim))),
          Row(
            children: [
              SignalBars(level: face.level, color: face.color),
              const SizedBox(width: 6),
              Flexible(child: Text(face.word, style: TextStyle(color: face.color))),
            ],
          ),
        ],
      ),
      trailing: const NavChevron(),
      onTap: () => showEpicboxPicker(context),
    );
  }
}

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
    return ListTile(
      key: epic1PrintedKey,
      leading: const Icon(Icons.print_outlined),
      title: Text(l.deskE1PhPrinted),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count != null) Text(l.deskE1PhPrintedCount(count, epic1PrintedMax), style: TextStyle(color: context.tokens.dim)),
          const NavChevron(),
        ],
      ),
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
    return Scaffold(
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
    );
  }
}
