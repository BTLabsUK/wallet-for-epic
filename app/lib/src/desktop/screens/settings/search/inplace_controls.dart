// SPDX-License-Identifier: Apache-2.0
/// The controls a search result can use in place, as their page has them: the Advanced
/// switches, Theme, Interface scale, Language and Hide amounts. Every other result has Open.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../advanced.dart';
import '../../../data/settings_registry.dart';
import '../../../desk_l10n.dart';
import '../../../widgets/kit.dart';
import '../../onboarding/onboarding_parts.dart' show deskLanguageItems, deskSystemLanguage;
import 'settings_sections.dart' show setFeatureName;

/// The Advanced switch each row id stands for.
const Map<String, AdvancedFeature> _featureRows = {
  SetId.advOutputs: AdvancedFeature.outputs,
  SetId.advTech: AdvancedFeature.technicalDetails,
  SetId.advSendopts: AdvancedFeature.sendOptions,
  SetId.advServers: AdvancedFeature.serverDetails,
  SetId.advHeight: AdvancedFeature.recheckFromHeight,
  SetId.advLocal: AdvancedFeature.builtInNode,
  SetId.advLogs: AdvancedFeature.logs,
  SetId.xInvoices: AdvancedFeature.invoices,
};

/// The ids [settingsInPlaceControl] has a control for.
const Set<String> settingsInPlaceIds = {
  SetId.advOutputs, SetId.advTech, SetId.advSendopts, SetId.advServers, SetId.advHeight, SetId.advLocal, SetId.advLogs, SetId.xInvoices,
  SetId.theme, SetId.scale, SetId.language, SetId.hideAmounts,
};

/// Row [id]'s control, usable here; null when the result opens its page instead.
Widget? settingsInPlaceControl(BuildContext context, WidgetRef ref, String id) {
  if (!settingsInPlaceIds.contains(id)) return null;
  final l = context.l10n;
  final s = ref.watch(deskProvider.select((s) => s.settings));
  final n = ref.read(deskProvider.notifier);
  if (_featureRows[id] case final f?) {
    final adv = s.advanced;
    return ESwitch(
      value: adv.has(f),
      semanticLabel: setFeatureName(l, f),
      onChanged: (v) => n.saveSettings(s.copyWith(advanced: experimentalFeatures.contains(f) ? adv.withExperimental(f, v) : adv.withFeature(f, v))),
    );
  }
  return switch (id) {
    SetId.theme => ESegmented<ThemeChoice>(
      segments: [
        ESegment(ThemeChoice.system, l.deskSetAppearSystem, icon: EIcons.themeSystem),
        ESegment(ThemeChoice.dark, l.deskSetAppearDark, icon: EIcons.moon),
        ESegment(ThemeChoice.light, l.deskSetAppearLight, icon: EIcons.sun),
      ],
      value: s.theme,
      onChanged: (v) => n.saveSettings(s.copyWith(theme: v)),
    ),
    SetId.scale => ERowControl(
      child: ESelect<int>(
        size: EBtnSize.sm,
        semanticLabel: l.deskSetAppearScale,
        value: s.scale,
        items: [for (final v in deskScales) ESelectItem(v, '$v%')],
        onChanged: (v) => n.saveSettings(s.copyWith(scale: v)),
      ),
    ),
    SetId.language => ERowControl(
      child: ESelect<String>(
        size: EBtnSize.sm,
        semanticLabel: l.deskSetAppearLanguage,
        value: s.language ?? deskSystemLanguage,
        items: deskLanguageItems(l),
        onChanged: (v) => n.saveSettings(s.copyWith(language: () => v == deskSystemLanguage ? null : v)),
      ),
    ),
    SetId.hideAmounts => ESwitch(value: s.hideAmounts, semanticLabel: l.deskOvHideAmounts, onChanged: (v) => n.saveSettings(s.copyWith(hideAmounts: v))),
    _ => null,
  };
}
