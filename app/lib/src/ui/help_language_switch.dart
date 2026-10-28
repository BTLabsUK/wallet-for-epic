// SPDX-License-Identifier: Apache-2.0
/// The small switch at the top of Help on the phone: the help language's flag and own name, and a
/// compact menu of the app's languages. It sets only the language of the help topics.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../help/help_i18n.dart' show systemHelpLanguage;
import '../l10n.dart';
import '../settings.dart';
import 'language_flag.dart';
import 'theme/tokens.dart';

/// The key of the switch, for tests.
const Key helpLanguageKey = ValueKey('help-language');

/// The language Help shows its topics in: the choice in the switch, else the app's own
/// language (the system's languages when the app follows them).
String phoneHelpLanguage(WidgetRef ref, BuildContext context) {
  final chosen = ref.watch(
    appSettingsProvider.select((s) => s.value?.helpLanguage),
  );
  if (chosen != null) return chosen;
  return systemHelpLanguage([Localizations.localeOf(context)]);
}

/// The language's own name from [appLanguages]; the code itself for one it does not list.
String languageName(String code) =>
    appLanguages.where((a) => a.code == code).firstOrNull?.name ?? code;

class HelpLanguageSwitch extends ConsumerWidget {
  const HelpLanguageSwitch({super.key, required this.current});

  /// The help language now, a code from [appLanguages].
  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final name = languageName(current);
    return PopupMenuButton<String>(
      key: helpLanguageKey,
      tooltip: '${l.helpLanguageLabel}: $name',
      initialValue: current,
      position: PopupMenuPosition.under,
      onSelected: (code) =>
          ref.read(appSettingsProvider.notifier).setHelpLanguage(code),
      itemBuilder: (_) => [
        for (final a in appLanguages)
          PopupMenuItem<String>(
            value: a.code,
            height: 44,
            child: Row(
              children: [
                LanguageFlag(a.code),
                const SizedBox(width: 10),
                Text(a.name),
              ],
            ),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LanguageFlag(current),
              const SizedBox(width: 8),
              Text(name, style: Theme.of(context).textTheme.bodyMedium),
              Icon(Icons.arrow_drop_down, color: t.dim),
            ],
          ),
        ),
      ),
    );
  }
}
