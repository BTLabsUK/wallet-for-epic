/// Settings › Advanced: the switches that show more of the wallet, each explained in a hover
/// card, and the one network mode. Nothing here is a value the simple path needs; what a switch
/// turns on appears where it belongs (the sidebar, Send, a transaction's details).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../advanced.dart';
import '../../app/tour.dart' show TourTarget;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../transfer/send_advanced.dart' show ERadioRow;
import 'connection_servers_row.dart';
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
};

/// A network mode's name.
String networkModeName(AppLocalizations l, NetworkMode m) => switch (m) {
  NetworkMode.standard => l.deskSetAdvModeStandard,
  NetworkMode.torOnly => l.deskSetAdvModeTorOnly,
  NetworkMode.offline => l.deskSetAdvModeOffline,
};

/// A state the tour opens Settings › Advanced in.
enum AdvancedDemo { connectionServersOpen }

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
        // An "experimental" dialog's Open Advanced lands here (LNX3-1).
        JumpSection(section: SettingsJump.experimental, child: _ExperimentalGroup(openConnectionServers: arg == AdvancedDemo.connectionServersOpen)),
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

/// Pairing and Invoices, off by default: each with an Experimental tag, the rule between them
/// in one line under them.
class _ExperimentalGroup extends ConsumerWidget {
  const _ExperimentalGroup({this.openConnectionServers = false});

  final bool openConnectionServers;

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
        // Where words meet: hidden while Pairing is off and on a network without meeting servers.
        ConnectionServersRow(openInitially: openConnectionServers),
        row(AdvancedFeature.invoices, adv.invoicesOn, l.expInvoicesHint),
        ESetRow(key: const ValueKey('adv-exp-rule'), text: l.expNeedsPairing),
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
      NetworkMode.offline => DeskFeatures.tor ? l.deskSetAdvOfflineNote : l.deskNoTorAdvOfflineNote,
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
              mode(NetworkMode.offline, l.deskSetAdvModeOfflineText),
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
