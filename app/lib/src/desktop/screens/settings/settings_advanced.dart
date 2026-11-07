// SPDX-License-Identifier: Apache-2.0
/// Settings › Advanced: the view (Shallow, Deeper, Deep end), the switches that show more of
/// the wallet, each explained behind its ⓘ, and the experiments (Invoices). What a switch turns
/// on appears where it belongs (the sidebar, Send, a transaction's details). The network mode
/// is on Network & privacy (`settings_privacy.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../advanced.dart';
import '../../../trust_ids.dart';
import '../../../ui/network_mode_text.dart';
import '../../app/tour.dart' show TourTarget;
import '../../../levels/wallet_level.dart';
import '../../../log.dart';
import '../../data/desk_levels.dart' show deskLevelControlProvider, deskLevelProvider;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../../widgets/more_options.dart' show moreOptionsRevealProvider;
import '../onboarding/depth_dial.dart' show DeskDepthPicker, showDepthHelp;
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

/// Advanced › View: the depth dial with the Overview picture (Welcome's old first step, now
/// here only); a pick applies at once (the level's preset with it), and the line under the dial
/// says what the view shows, in facts.
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
        SetAnchor(
          id: SetId.view,
          child: DeskDepthPicker(
            framed: false,
            level: level,
            onLevel: _pick,
            caption: l.deskLvStartPreviewCaption,
            foot: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(viewLine(l, level), key: const ValueKey('adv-view-note'), style: context.ts.small),
                SizedBox(height: Sp.x2),
                ELink(label: l.lvPickHelpTitle, onPressed: () => showDepthHelp(context)),
              ],
            ),
          ),
        ),
      ],
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
    ESetRow row(AdvancedFeature f, String hint, {required String anchor, int minLevel = 2}) => ESetRow(
      key: ValueKey('adv-${f.name}'),
      anchor: anchor,
      advancedBy: level >= minLevel ? null : advancedByView(l, minLevel),
      title: advancedFeatureName(l, f),
      hint: hint,
      hintTitle: advancedFeatureName(l, f),
      control: ESwitch(
        semanticsId: switch (f) {
          AdvancedFeature.technicalDetails => TrustIds.advancedTechnical,
          AdvancedFeature.pairing => TrustIds.pairAdvPairing,
          _ => null,
        },
        value: adv.has(f),
        semanticLabel: advancedFeatureName(l, f),
        onChanged: (v) => set(f, v),
      ),
    );
    final all = [
      (row(AdvancedFeature.outputs, l.deskSetAdvOutputsHint, anchor: SetId.advOutputs), 2),
      (row(AdvancedFeature.technicalDetails, l.deskSetAdvTechnicalHint, anchor: SetId.advTech), 2),
      (row(AdvancedFeature.sendOptions, l.deskSetAdvSendOptionsHint, anchor: SetId.advSendopts), 2),
      (row(AdvancedFeature.serverDetails, l.deskSetAdvServerDetailsHint, anchor: SetId.advServers), 2),
      (row(AdvancedFeature.recheckFromHeight, l.deskSetAdvRecheckHint, anchor: SetId.advHeight), 2),
      (row(AdvancedFeature.builtInNode, l.deskSetAdvBuiltInNodeHint, anchor: SetId.advLocal, minLevel: 3), 3),
      (row(AdvancedFeature.logs, l.deskSetAdvLogsHint, anchor: SetId.advLogs), 2),
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
        semanticsId: TrustIds.pairAdvInvoices,
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
