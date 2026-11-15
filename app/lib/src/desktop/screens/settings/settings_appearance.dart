// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import '../../../trust_ids.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'setting_ids.dart';
import '../onboarding/onboarding_parts.dart' show deskLanguageItems, deskSystemLanguage;
import 'settings_frame.dart';

class SettingsAppearanceScreen extends ConsumerWidget {
  const SettingsAppearanceScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(deskProvider.select((s) => s.settings));
    final n = ref.read(deskProvider.notifier);
    final l = context.l10n;
    return SettingsFrame(
      route: DeskRoute.settingsAppearance,
      child: ESetGroup(
        rows: [
          ESetRow(
            anchor: SetId.theme,
            title: l.deskSetAppearTheme,
            hint: l.deskSetAppearThemeHint,
            // A choice from a list is a dropdown in the row's slot, as Size and Language.
            control: ERowControl(
              child: ESelect<ThemeChoice>(
                key: const ValueKey('appearance-theme'),
                // The phone's Theme row id: one control, one id.
                semanticsId: TrustIds.appearanceTheme,
                size: EBtnSize.sm,
                semanticLabel: l.deskSetAppearTheme,
                value: s.theme,
                items: [
                  ESelectItem(ThemeChoice.system, l.deskSetAppearSystem, leading: Icon(EIcons.themeSystem, size: 14.u)),
                  ESelectItem(ThemeChoice.dark, l.deskSetAppearDark, leading: Icon(EIcons.moon, size: 14.u)),
                  ESelectItem(ThemeChoice.light, l.deskSetAppearLight, leading: Icon(EIcons.sun, size: 14.u)),
                ],
                onChanged: (v) => n.saveSettings(s.copyWith(theme: v)),
              ),
            ),
          ),
          ESetRow(
            anchor: SetId.scale,
            title: l.deskSetAppearScale,
            hint: l.deskSetAppearScaleHint,
            control: ERowControl(
              child: ESelect<int>(
                size: EBtnSize.sm,
                semanticLabel: l.deskSetAppearScale,
                value: s.scale,
                items: [for (final v in deskScales) ESelectItem(v, '$v%')],
                onChanged: (v) => n.saveSettings(s.copyWith(scale: v)),
              ),
            ),
          ),
          ESetRow(
            anchor: SetId.language,
            title: l.deskSetAppearLanguage,
            hint: l.deskSetAppearLanguageHint,
            control: ERowControl(
              child: ESelect<String>(
                size: EBtnSize.sm,
                semanticLabel: l.deskSetAppearLanguage,
                value: s.language ?? deskSystemLanguage,
                // The app's own translations (lib/l10n), as on Setup.
                items: deskLanguageItems(l),
                onChanged: (v) => n.saveSettings(s.copyWith(language: () => v == deskSystemLanguage ? null : v)),
              ),
            ),
          ),
          ESetRow(
            anchor: SetId.hideAmounts,
            title: l.deskOvHideAmounts,
            hint: l.deskSetAppearHideHint,
            control: ESwitch(value: s.hideAmounts, semanticLabel: l.deskOvHideAmounts, onChanged: (v) => n.saveSettings(s.copyWith(hideAmounts: v))),
          ),
          ESetRow(
            anchor: SetId.systemNotices,
            title: l.deskSetSystemNotices,
            control: ESwitch(value: s.systemNotices, semanticLabel: l.deskSetSystemNotices, onChanged: (v) => n.saveSettings(s.copyWith(systemNotices: v))),
          ),
        ],
      ),
    );
  }
}
