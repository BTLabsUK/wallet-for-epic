// SPDX-License-Identifier: Apache-2.0
/// Settings › Advanced: the switches that show more of the wallet, each explained in a hover
/// card (the network mode is on Network & privacy, `settings_privacy.dart`). Nothing here is a value the simple path needs; what a switch
/// turns on appears where it belongs (the sidebar, Send, a transaction's details).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../advanced.dart';
import '../../../ui/network_mode_text.dart';
import '../../../models.dart' show defaultMinimumConfirmations, maxMinimumConfirmations, minMinimumConfirmations;
import '../../app/tour.dart' show TourTarget;
import '../../../levels/level_features.dart' show AdvancedPageKind;
import '../../../ui/levels/level_picker.dart' show levelLine, levelStopName;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/desk_levels.dart' show deskLevelFeaturesProvider, deskLevelProvider;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../wallet/outputs_dialogs.dart' show EStepper;
import 'prefs.dart' show SettingsJump;
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
    final l = context.l10n;
    // Shallow: the Depth row alone; the switches belong to Deeper and up.
    final changeOnly = ref.watch(deskLevelFeaturesProvider.select((f) => f.advancedPage)) == AdvancedPageKind.changeLevelOnly;
    return SettingsFrame(
      route: DeskRoute.settingsAdvanced,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DepthGroup(),
          if (changeOnly)
            Text(l.deskLvStartAdvNote, key: const ValueKey('adv-depth-note'), style: context.ts.small)
          else ...[
            // The tour lights the top of the page: the intro and the switches.
            TourTarget(
              id: 'advanced-top',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.deskSetAdvIntro, style: context.ts.bodyDim),
                  SizedBox(height: Sp.x5),
                  const _ShowsGroup(),
                ],
              ),
            ),
            const JumpSection(section: SettingsJump.confirmations, child: _BalanceGroup()),
            // An "experimental" dialog's Open Advanced lands here (LNX3-1).
            const JumpSection(section: SettingsJump.experimental, child: _ExperimentalGroup()),
          ],
        ],
      ),
    );
  }
}

/// The depth in force with its line and Change level (Settings › Advanced › Depth).
class _DepthGroup extends ConsumerWidget {
  const _DepthGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final level = ref.watch(deskLevelProvider);
    return ESetGroup(
      key: const ValueKey('adv-depth'),
      title: l.lvPickDepth,
      rows: [
        ESetRow(
          title: levelStopName(l, level),
          text: levelLine(l, level),
          control: ERowControl(
            child: EButton(
              key: const ValueKey('adv-depth-change'),
              label: l.levelChangeTitle,
              size: EBtnSize.sm,
              onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsLevel),
            ),
          ),
        ),
      ],
    );
  }
}

/// One row per feature: title, a hover card, a switch.
class _ShowsGroup extends ConsumerWidget {
  const _ShowsGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(deskProvider.select((s) => s.settings));
    final adv = s.advanced;
    final n = ref.read(deskProvider.notifier);
    void set(AdvancedFeature f, bool on) =>
        n.saveSettings(s.copyWith(advanced: adv.withFeature(f, on)));
    ESetRow row(AdvancedFeature f, String hint, {bool shown = true}) => ESetRow(
      key: ValueKey('adv-${f.name}'),
      title: advancedFeatureName(l, f),
      hint: hint,
      hintTitle: advancedFeatureName(l, f),
      control: ESwitch(
        value: adv.has(f),
        semanticLabel: advancedFeatureName(l, f),
        onChanged: shown ? (v) => set(f, v) : null,
      ),
    );
    final on = adv.shownFeatures.length;
    final trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (on > 0) Text(l.deskSetAdvOn(on), style: context.ts.small),
          if (on > 0) SizedBox(width: Sp.x3),
          EButton.ghost(
            key: const ValueKey('adv-reset'),
            label: l.deskSetAdvReset,
            icon: EIcons.eyeOff,
            size: EBtnSize.inline,
            onPressed: on == 0
                ? null
                : () => n.saveSettings(s.copyWith(advanced: adv.withoutShown())),
          ),
        ],
      );
    final group = ESetGroup(
      rows: [
        row(AdvancedFeature.outputs, l.deskSetAdvOutputsHint),
        row(AdvancedFeature.technicalDetails, l.deskSetAdvTechnicalHint),
        row(AdvancedFeature.sendOptions, l.deskSetAdvSendOptionsHint),
        row(AdvancedFeature.serverDetails, l.deskSetAdvServerDetailsHint),
        row(AdvancedFeature.recheckFromHeight, l.deskSetAdvRecheckHint),
        row(AdvancedFeature.builtInNode, l.deskSetAdvBuiltInNodeHint),
        row(AdvancedFeature.logs, l.deskSetAdvLogsHint),
      ],
    );
    // The trailing count and Reset sit beside the title while the header has room, else under it.
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= Lay.sm) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [ESectionHead(l.deskSetAdvShows, top: 0, trailing: trailing), group]);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ESectionHead(l.deskSetAdvShows, top: 0),
            Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(bottom: Sp.x3), child: trailing)),
            group,
          ],
        );
      },
    );
  }
}

/// Pairing and Invoices, off by default, and Linked devices, on unless turned off: each with an
/// Experimental tag, the rule between the first two in one line under them.
class _ExperimentalGroup extends ConsumerWidget {
  const _ExperimentalGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(deskProvider.select((s) => s.settings));
    final adv = s.advanced;
    final n = ref.read(deskProvider.notifier);
    ESetRow row(AdvancedFeature f, bool value, String hint) => ESetRow(
      key: ValueKey('adv-${f.name}'),
      title: advancedFeatureName(l, f),
      badge: EBadge(l.advExperimental),
      hint: hint,
      hintTitle: advancedFeatureName(l, f),
      control: ESwitch(
        value: value,
        semanticLabel: advancedFeatureName(l, f),
        onChanged: (v) => n.saveSettings(s.copyWith(advanced: adv.withExperimental(f, v))),
      ),
    );
    return ESetGroup(
      key: const ValueKey('adv-experimental'),
      title: l.advExperimental,
      rows: [
        row(AdvancedFeature.invoices, adv.invoicesOn, l.expInvoicesHint),
        // On unless turned off; independent of Pairing (its pairings are private).
        row(AdvancedFeature.linkedDevices, adv.linkedDevicesOn, l.expLinkedDevicesHint),
      ],
    );
  }
}

/// The wallet's minimum confirmations (the core keeps it per wallet): a stepper that applies
/// each step at once, a Default tag at the default and Reset elsewhere, and a quiet line under
/// it below the default. A refused count goes back and says why in a toast.
class _BalanceGroup extends ConsumerWidget {
  const _BalanceGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    final count = ref.watch(deskMinConfirmationsSettingProvider).value ?? deskMinConfirmations(ref);
    Future<void> set(int n) async {
      if (n == count) return;
      try {
        await ref.read(deskMinConfirmationsSettingProvider.notifier).set(n);
      } on Object catch (e) {
        if (context.mounted) showEToast(context, l.deskSetAdvConfirmationsNotSaved, text: deskErrorText(e, l), tone: ETone.risk);
      }
    }

    return ESetGroup(
      key: const ValueKey('adv-balance'),
      title: l.deskSetAdvBalance,
      rows: [
        ESetRow(
          key: const ValueKey('adv-minConfirmations'),
          title: l.deskSetAdvConfirmations,
          hint: l.deskSetAdvConfirmationsHint(defaultMinimumConfirmations, minMinimumConfirmations, maxMinimumConfirmations),
          hintTitle: l.deskSetAdvConfirmations,
          wrap: true,
          control: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (count == defaultMinimumConfirmations)
                EBadge(l.deskSetAdvConfirmationsDefault)
              else
                EButton.ghost(
                  key: const ValueKey('adv-minConfirmations-reset'),
                  label: l.deskSetAdvConfirmationsReset(defaultMinimumConfirmations),
                  size: EBtnSize.inline,
                  onPressed: () => set(defaultMinimumConfirmations),
                ),
              SizedBox(width: Sp.x3),
              EStepper(
                value: count,
                min: minMinimumConfirmations,
                max: maxMinimumConfirmations,
                label: l.deskSetAdvConfirmations,
                fewerLabel: l.deskSetAdvConfirmationsFewer,
                moreLabel: l.deskSetAdvConfirmationsMore,
                valueText: l.deskSetAdvConfirmationsCount,
                onChanged: set,
              ),
            ],
          ),
          below: count < defaultMinimumConfirmations
              ? Text(l.deskSetAdvConfirmationsLowNote, key: const ValueKey('adv-minConfirmations-note'), style: context.ts.small.copyWith(color: c.dim))
              : null,
        ),
      ],
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
