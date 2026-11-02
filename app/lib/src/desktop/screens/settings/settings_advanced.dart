// SPDX-License-Identifier: Apache-2.0
/// Settings › Advanced: the view (Shallow, Deeper, Deep end), the switches that show more of
/// the wallet, each explained behind its ⓘ, and the experiments (Invoices). What a switch turns
/// on appears where it belongs (the sidebar, Send, a transaction's details). The network mode
/// is on Network & privacy (`settings_privacy.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../advanced.dart';
import '../../../ui/network_mode_text.dart';
import '../../app/tour.dart' show TourTarget;
import '../../../levels/wallet_level.dart';
import '../../../log.dart';
import '../../../ui/levels/level_picker.dart' show levelStopName;
import '../../data/desk_levels.dart' show deskLevelControlProvider, deskLevelProvider;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../../widgets/more_options.dart' show moreOptionsRevealProvider;
import 'prefs.dart' show SettingsJump;
import 'setting_ids.dart';
import 'settings_frame.dart';

export '../../../advanced.dart';
export '../../../ui/network_mode_text.dart' show networkModeName;

/// The desktop's Advanced choices, from the settings.
AdvancedPrefs advancedOf(WidgetRef ref) =>
    ref.watch(deskProvider.select((s) => s.settings.advanced));

/// Whether [feature] is on. [keep] holds it on anyway: a feature mid-use (a running node, a
/// listener that is on, a split in progress) never disappears under the user.
bool advancedHas(WidgetRef ref, AdvancedFeature feature, {bool keep = false}) =>
    keep || advancedOf(ref).has(feature);

/// Opens Settings › Advanced (a line elsewhere that names it links here).
void openAdvanced(WidgetRef ref) => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsAdvanced);

/// A feature's name as the Advanced page shows it.
String advancedFeatureName(AppLocalizations l, AdvancedFeature f) => switch (f) {
  AdvancedFeature.outputs => l.deskSetAdvOutputs,
  AdvancedFeature.technicalDetails => l.deskSetAdvTechnical,
  AdvancedFeature.sendOptions => l.deskSetAdvSendOptions,
  // Direct moved to Settings › Transactions: nothing on the Advanced page switches it.
  AdvancedFeature.serverDetails => l.deskSetAdvServerDetails,
  AdvancedFeature.recheckFromHeight => l.deskSetAdvRecheck,
  AdvancedFeature.builtInNode => l.deskSetAdvBuiltInNode,
  AdvancedFeature.logs => l.deskSetAdvLogs,
  // Phone only; never on the desktop's list.
  AdvancedFeature.transactionFiles => l.advTransactionFiles,
  AdvancedFeature.pairing => l.expPairing,
  AdvancedFeature.invoices => l.expInvoices,
  AdvancedFeature.linkedDevices => l.expLinkedDevices,
};


class SettingsAdvancedScreen extends ConsumerWidget {
  const SettingsAdvancedScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsFrame(
      route: DeskRoute.settingsAdvanced,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The tour lights the top of the page: the view and the switches.
          TourTarget(
            id: 'advanced-top',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [_ViewGroup(), _ShowsGroup()],
            ),
          ),
          // An "experimental" dialog's Open Advanced lands here (LNX3-1).
          const JumpSection(section: SettingsJump.experimental, child: _ExperimentalGroup()),
        ],
      ),
    );
  }
}

/// A view's one line: what it shows, in facts.
String viewLine(AppLocalizations l, WalletLevel level) => switch (level) {
  WalletLevel.justSendReceive => l.deskSetAdvViewLineOne,
  WalletLevel.casual => l.deskSetAdvViewLineTwo,
  WalletLevel.everything => l.deskSetAdvViewLineThree,
};

/// The key of a view's card, for tests.
Key advViewKey(WalletLevel level) => ValueKey('adv-view-${level.number}');

/// Advanced › View: the three views as cards, side by side while they fit; a pick applies at
/// once (the level's preset with it, as Welcome's dial), and the line under them says what a
/// view changes.
class _ViewGroup extends ConsumerStatefulWidget {
  const _ViewGroup();

  @override
  ConsumerState<_ViewGroup> createState() => _ViewGroupState();
}

class _ViewGroupState extends ConsumerState<_ViewGroup> {
  bool _busy = false;

  Future<void> _pick(WalletLevel level) async {
    if (_busy || level == ref.read(deskLevelProvider)) return;
    setState(() => _busy = true);
    try {
      await ref.read(deskLevelControlProvider).setLevel(level);
      // A new view: every "more options" folds again.
      ref.read(moreOptionsRevealProvider.notifier).clear();
    } on Object catch (e) {
      logWarn('levels', 'level not saved: ${e.runtimeType}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final level = ref.watch(deskLevelProvider);
    return ESetGroup(
      key: const ValueKey('adv-depth'),
      title: l.lvPickDepth,
      rows: [
        Padding(
          padding: EdgeInsets.all(Sp.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SetAnchor(id: SetId.view, child: Semantics(
                container: true,
                label: l.lvPickDepth,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final cards = [
                      for (final lv in WalletLevel.values)
                        _ViewCard(
                          key: advViewKey(lv),
                          name: levelStopName(l, lv),
                          line: viewLine(l, lv),
                          selected: lv == level,
                          onTap: _busy ? null : () => _pick(lv),
                        ),
                    ];
                    if (box.maxWidth < 560.u) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [for (final (i, c) in cards.indexed) ...[if (i > 0) SizedBox(height: Sp.x2), c]],
                      );
                    }
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [for (final (i, c) in cards.indexed) ...[if (i > 0) SizedBox(width: Sp.x2), Expanded(child: c)]],
                      ),
                    );
                  },
                ),
              ),
              ),
              SizedBox(height: Sp.x3),
              Text(l.deskSetAdvViewNote, key: const ValueKey('adv-view-note'), style: context.ts.small),
            ],
          ),
        ),
      ],
    );
  }
}

/// One view: a radio mark, the name and its line; the picked one raised with an accent edge.
class _ViewCard extends StatefulWidget {
  const _ViewCard({super.key, required this.name, required this.line, required this.selected, required this.onTap});

  final String name;
  final String line;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_ViewCard> createState() => _ViewCardState();
}

class _ViewCardState extends State<_ViewCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final sel = widget.selected;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: sel,
      button: true,
      label: widget.name,
      hint: widget.line,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: widget.onTap != null,
        mouseCursor: widget.onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap?.call())},
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: widget.onTap,
            child: FocusRing(
              focused: Focus.of(context).hasFocus,
              child: AnimatedContainer(
                duration: Dur.fast,
                padding: EdgeInsets.all(Sp.x3),
                decoration: BoxDecoration(
                  color: sel ? c.s3 : (_hover ? c.hover : c.s2),
                  borderRadius: BorderRadius.circular(Rad.sm),
                  border: Border.all(color: sel ? c.accent : c.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The radio mark of ERadioRow: a ring, the accent dot when picked.
                    Container(
                      width: 16.u,
                      height: 16.u,
                      margin: EdgeInsets.only(top: 2.u),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: sel ? c.accent : c.lineStrong, width: 1.5)),
                      child: sel ? Container(width: 8.u, height: 8.u, decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent)) : null,
                    ),
                    SizedBox(width: Sp.x2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.name, style: ts.strong),
                          const SizedBox(height: 2),
                          Text(widget.line, style: ts.small),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Advanced › Shows more: one row per feature, title, ⓘ, a switch; Deeper and up. At Shallow
/// the rows wait behind the group's ⇕ (shown with the Deeper view); Local node is Deep end's.
class _ShowsGroup extends ConsumerWidget {
  const _ShowsGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(deskProvider.select((s) => s.settings));
    final level = ref.watch(deskLevelProvider).number;
    final adv = s.advanced;
    final n = ref.read(deskProvider.notifier);
    void set(AdvancedFeature f, bool on) =>
        n.saveSettings(s.copyWith(advanced: adv.withFeature(f, on)));
    ESetRow row(AdvancedFeature f, String id, String hint, {int minLevel = 2}) => ESetRow(
      key: ValueKey('adv-${f.name}'),
      anchor: id,
      advancedBy: level >= minLevel ? null : advancedByView(l, minLevel),
      title: advancedFeatureName(l, f),
      hint: hint,
      hintTitle: advancedFeatureName(l, f),
      control: ESwitch(
        value: adv.has(f),
        semanticLabel: advancedFeatureName(l, f),
        onChanged: (v) => set(f, v),
      ),
    );
    final all = [
      (row(AdvancedFeature.outputs, SetId.advOutputs, l.deskSetAdvOutputsHint), 2),
      (row(AdvancedFeature.technicalDetails, SetId.advTech, l.deskSetAdvTechnicalHint), 2),
      (row(AdvancedFeature.sendOptions, SetId.advSendopts, l.deskSetAdvSendOptionsHint), 2),
      (row(AdvancedFeature.serverDetails, SetId.advServers, l.deskSetAdvServerDetailsHint), 2),
      (row(AdvancedFeature.recheckFromHeight, SetId.advHeight, l.deskSetAdvRecheckHint), 2),
      (row(AdvancedFeature.builtInNode, SetId.advLocal, l.deskSetAdvBuiltInNodeHint, minLevel: 3), 3),
      (row(AdvancedFeature.logs, SetId.advLogs, l.deskSetAdvLogsHint), 2),
    ];
    final on = adv.shownFeatures.length;
    final trailing = level < 2
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (on > 0) Text(l.deskSetAdvOn(on), style: context.ts.small),
              if (on > 0) SizedBox(width: Sp.x3),
              EButton.ghost(
                key: const ValueKey('adv-reset'),
                label: l.deskSetAdvReset,
                icon: EIcons.eyeOff,
                size: EBtnSize.inline,
                onPressed: on == 0 ? null : () => n.saveSettings(s.copyWith(advanced: adv.withoutShown())),
              ),
            ],
          );
    return ESetGroup(
      key: const ValueKey('adv-shows'),
      title: l.deskSetAdvShows,
      trailing: trailing,
      rows: [for (final (r, min) in all) if (level >= min) r],
      hidden: [for (final (r, min) in all) if (level < min) r],
      revealKey: 'adv-shows',
    );
  }
}

/// Advanced › Experiments: Invoices, off by default, Deep end's. Linked devices shows at every
/// view and has no switch (item 10).
class _ExperimentalGroup extends ConsumerWidget {
  const _ExperimentalGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(deskProvider.select((s) => s.settings));
    final deep = ref.watch(deskLevelProvider) == WalletLevel.everything;
    final adv = s.advanced;
    final n = ref.read(deskProvider.notifier);
    final invoices = ESetRow(
      key: ValueKey('adv-${AdvancedFeature.invoices.name}'),
      anchor: SetId.xInvoices,
      advancedBy: deep ? null : advancedByView(l, 3),
      title: advancedFeatureName(l, AdvancedFeature.invoices),
      badge: EBadge(l.deskSetFrameExperiment),
      hint: l.expInvoicesHint,
      hintTitle: advancedFeatureName(l, AdvancedFeature.invoices),
      control: ESwitch(
        value: adv.invoicesOn,
        semanticLabel: advancedFeatureName(l, AdvancedFeature.invoices),
        onChanged: (v) => n.saveSettings(s.copyWith(advanced: adv.withExperimental(AdvancedFeature.invoices, v))),
      ),
    );
    return ESetGroup(
      key: const ValueKey('adv-experimental'),
      title: l.deskSetAdvExperiments,
      rows: [if (deep) invoices],
      hidden: [if (!deep) invoices],
      revealKey: 'adv-experiments',
    );
  }
}

/// The key of the switch confirmation dialog.
const Key advModeConfirmKey = ValueKey('adv-mode-confirm');

/// "Switch to {mode}?": only when a send waits for its recipient over Epicbox or Link and the
/// target is Node only or Kill switch. True to switch; nothing is cancelled either way.
Future<bool?> confirmNetworkModeSwitch(BuildContext context, {required NetworkMode mode, required int waiting}) {
  final l = context.l10n;
  final name = networkModeName(l, mode);
  return showEDialog<bool>(
    context,
    builder: (context) => EDialog(
      key: advModeConfirmKey,
      title: l.advModeConfirmTitle(name),
      description: l.advModeConfirmBody(waiting, name),
      icon: networkModeGlyph(mode),
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.pop(context, false)),
        EButton.primary(
          key: const ValueKey('adv-mode-confirm-switch'),
          label: l.advModeConfirmSwitch,
          autofocus: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
}
