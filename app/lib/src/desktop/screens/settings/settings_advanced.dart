// SPDX-License-Identifier: Apache-2.0
/// Settings › Advanced: the switches that show more of the wallet, each explained in a hover
/// card, and the one network mode. Nothing here is a value the simple path needs; what a switch
/// turns on appears where it belongs (the sidebar, Send, a transaction's details).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../advanced.dart';
import '../../../models.dart' show defaultMinimumConfirmations, maxMinimumConfirmations, minMinimumConfirmations;
import '../../app/tour.dart' show TourTarget;
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../transfer/send_advanced.dart' show ERadioRow;
import '../wallet/outputs_dialogs.dart' show EStepper;
import 'prefs.dart' show SettingsJump;
import 'settings_frame.dart';

export '../../../advanced.dart';

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

/// A network mode's name.
String networkModeName(AppLocalizations l, NetworkMode m) => switch (m) {
  NetworkMode.standard => l.deskSetAdvModeStandard,
  NetworkMode.torOnly => l.deskSetAdvModeTorOnly,
  NetworkMode.nodeOnly || NetworkMode.killSwitch => l.deskSetAdvModeOffline,
};

class SettingsAdvancedScreen extends ConsumerWidget {
  const SettingsAdvancedScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingsFrame(
    route: DeskRoute.settingsAdvanced,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The tour lights the top of the page: the intro and the switches.
        TourTarget(
          id: 'advanced-top',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.deskSetAdvIntro, style: context.ts.bodyDim),
              SizedBox(height: Sp.x5),
              const _ShowsGroup(),
            ],
          ),
        ),
        SizedBox(height: Sp.x6),
        const _NetworkGroup(),
        SizedBox(height: Sp.x6),
        const JumpSection(section: SettingsJump.confirmations, child: _BalanceGroup()),
        SizedBox(height: Sp.x6),
        // An "experimental" dialog's Open Advanced lands here (LNX3-1).
        const JumpSection(section: SettingsJump.experimental, child: _ExperimentalGroup()),
      ],
    ),
  );
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
    return ESetGroup(
      title: l.deskSetAdvShows,
      trailing: Row(
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
      ),
      rows: [
        if (DeskFeatures.coins) row(AdvancedFeature.outputs, l.deskSetAdvOutputsHint),
        row(AdvancedFeature.technicalDetails, l.deskSetAdvTechnicalHint),
        row(AdvancedFeature.sendOptions, l.deskSetAdvSendOptionsHint),
        row(AdvancedFeature.serverDetails, l.deskSetAdvServerDetailsHint),
        row(AdvancedFeature.recheckFromHeight, l.deskSetAdvRecheckHint),
        if (DeskFeatures.builtInNode) row(AdvancedFeature.builtInNode, l.deskSetAdvBuiltInNodeHint),
        row(AdvancedFeature.logs, l.deskSetAdvLogsHint),
      ],
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
        row(AdvancedFeature.pairing, adv.pairingOn, l.expPairingHint),
        row(AdvancedFeature.invoices, adv.invoicesOn, l.expInvoicesHint),
        ESetRow(key: const ValueKey('adv-exp-rule'), text: l.expNeedsPairing),
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

/// The three network modes as radio rows, the note a mode brings with it under them.
class _NetworkGroup extends ConsumerWidget {
  const _NetworkGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    final st = ref.watch(deskProvider);
    final s = st.settings;
    final adv = s.advanced;
    final torIncluded = (st.status?.torIncluded ?? true) && DeskFeatures.tor;
    void choose(NetworkMode m) =>
        ref.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: adv.withMode(m)));
    Widget mode(NetworkMode m, String text, {bool tor = false}) => ERadioRow(
      key: ValueKey('adv-mode-${m.name}'),
      selected: adv.networkMode == m,
      title: networkModeName(l, m),
      text: text,
      tag: tor && !torIncluded ? l.deskSetAdvNotInBuild : null,
      onSelected: tor && !torIncluded ? null : () => choose(m),
    );
    final note = switch (adv.networkMode) {
      NetworkMode.torOnly => l.deskSetAdvTorOnlyNote,
      NetworkMode.nodeOnly || NetworkMode.killSwitch => DeskFeatures.tor ? l.deskSetAdvOfflineNote : l.deskNoTorAdvOfflineNote,
      _ => null,
    };
    return ESetGroup(
      title: l.deskSetAdvNetwork,
      trailing: EInfoHint(DeskFeatures.tor ? l.deskSetAdvNetworkHint : l.deskNoTorAdvNetworkHint, title: l.deskSetAdvNetwork, icon: EIcons.antenna),
      rows: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              mode(NetworkMode.standard, DeskFeatures.tor ? l.deskSetAdvModeStandardText : l.advModeStandardLineNoTor),
              if (DeskFeatures.tor) mode(NetworkMode.torOnly, l.deskSetAdvModeTorOnlyText, tor: true),
              mode(NetworkMode.nodeOnly, l.deskSetAdvModeOfflineText),
              if (note != null) ...[
                SizedBox(height: Sp.x3),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Sp.x2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(EIcons.alert, size: Ctl.iconSm, color: c.warn),
                      SizedBox(width: Sp.x2),
                      Expanded(child: Text(note, style: context.ts.small.copyWith(color: c.warn))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // On by default: the one switch here that keeps the simple app working.
        ESetRow(
          key: const ValueKey('adv-nodeFailover'),
          title: l.deskSetAdvNodeFailover,
          hint: l.deskSetAdvNodeFailoverHint,
          hintTitle: l.deskSetAdvNodeFailover,
          control: ESwitch(
            value: adv.nodeFailover,
            semanticLabel: l.deskSetAdvNodeFailover,
            onChanged: (v) => ref.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: adv.withNodeFailover(v))),
          ),
        ),
      ],
    );
  }
}
