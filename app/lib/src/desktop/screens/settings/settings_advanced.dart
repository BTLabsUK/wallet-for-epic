// SPDX-License-Identifier: Apache-2.0
/// Settings › Advanced: the switches that show more of the wallet, each explained behind its
/// ⓘ. What a switch turns on appears where it belongs (a tab, Send, a transaction's details).
/// The network mode is on Network & privacy (`settings_privacy.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../advanced.dart';
import '../../../announcements/announcements_service.dart' show announcementsOffered;
import '../../../trust_ids.dart';
import '../../../ui/network_mode_text.dart';
import '../../../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../../app/tour.dart' show TourTarget;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
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
  AdvancedFeature.invoices => l.invoicesTitle,
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
          // The tour lights the top of the page: the switches.
          const TourTarget(
            id: 'advanced-top',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_ShowsGroup(), _AnnouncementsGroup()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Advanced › Shows more: one row per feature, title, ⓘ, a switch.
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
    ESetRow row(AdvancedFeature f, String hint, {required String anchor}) => ESetRow(
      key: ValueKey('adv-${f.name}'),
      anchor: anchor,
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
                onPressed: on == 0 ? null : () => n.saveSettings(s.copyWith(advanced: adv.withoutShown())),
              ),
            ],
          );
    return ESetGroup(
      key: const ValueKey('adv-shows'),
      title: l.deskSetAdvShows,
      trailing: trailing,
      rows: [
        row(AdvancedFeature.outputs, l.deskSetAdvOutputsHint, anchor: SetId.advOutputs),
        row(AdvancedFeature.technicalDetails, l.deskSetAdvTechnicalHint, anchor: SetId.advTech),
        row(AdvancedFeature.sendOptions, l.deskSetAdvSendOptionsHint, anchor: SetId.advSendopts),
        row(AdvancedFeature.serverDetails, l.deskSetAdvServerDetailsHint, anchor: SetId.advServers),
        row(AdvancedFeature.recheckFromHeight, l.deskSetAdvRecheckHint, anchor: SetId.advHeight),
        row(AdvancedFeature.builtInNode, l.deskSetAdvBuiltInNodeHint, anchor: SetId.advLocal),
        row(AdvancedFeature.logs, l.deskSetAdvLogsHint, anchor: SetId.advLogs),
      ],
    );
  }
}

/// Advanced › Announcements: one switch, with no gate, so anyone can turn the
/// messages off. Shown only when the build has a feed (`[announcements] feed`).
class _AnnouncementsGroup extends ConsumerWidget {
  const _AnnouncementsGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final host = ref.watch(hostSettingsProvider);
    if (!announcementsOffered(host)) return const SizedBox.shrink();
    final l = context.l10n;
    return ESetGroup(
      key: const ValueKey('adv-announcements'),
      title: l.deskSetGrpAnnouncements,
      rows: [
        ESetRow(
          key: const ValueKey('adv-announcements-row'),
          anchor: SetId.announcements,
          title: l.announcementsTitle,
          hint: l.announcementsHint,
          hintTitle: l.announcementsTitle,
          control: ESwitch(
            semanticsId: TrustIds.advancedAnnouncements,
            value: host.announcementsEnabled,
            semanticLabel: l.announcementsTitle,
            onChanged: (v) => ref.read(hostSettingsProvider.notifier).set('online.announcements', v),
          ),
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
