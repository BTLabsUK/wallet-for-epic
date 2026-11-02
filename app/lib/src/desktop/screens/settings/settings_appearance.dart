// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
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
            // At least the wide control; wider when a language's words need it, the three
            // segments equal and every word whole (LNX-11). Under the title when that is
            // wider than the row leaves.
            wrap: true,
            control: ConstrainedBox(
              constraints: BoxConstraints(minWidth: Ctl.rowWide),
              child: IntrinsicWidth(
              child: ESegmented<ThemeChoice>(
              stretch: true,
              segments: [
                ESegment(ThemeChoice.system, l.deskSetAppearSystem, icon: EIcons.themeSystem),
                ESegment(ThemeChoice.dark, l.deskSetAppearDark, icon: EIcons.moon),
                ESegment(ThemeChoice.light, l.deskSetAppearLight, icon: EIcons.sun),
              ],
              value: s.theme,
              onChanged: (v) => n.saveSettings(s.copyWith(theme: v)),
            ),
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
        ],
      ),
    );
  }
}
