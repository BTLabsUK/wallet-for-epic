// SPDX-License-Identifier: Apache-2.0
/// Settings › About › Licences › All licence texts: the package list and each full text.
library;

import 'package:flutter/foundation.dart' show LicenseEntry;
import 'package:flutter/material.dart';

import '../l10n.dart';
import '../licence_texts.dart';
import 'theme/tokens.dart';
import 'kit/kit_group.dart';
import 'kit/kit_row.dart';
import 'kit/kit_tokens.dart';
import 'settings_phone.dart' show SettingsPhonePage;

/// Every full licence text the app carries, in the app's own look (UP-025): the usual section
/// page, one row per package in sentence case ("Tor", not "tor") with how many licences it
/// has, and each text as one preformatted mono block on the dark surface. Flutter's stock page centred the
/// paragraphs in Roboto with "====" rules.
class LicenceTextsScreen extends StatefulWidget {
  const LicenceTextsScreen({super.key});

  @override
  State<LicenceTextsScreen> createState() => _LicenceTextsScreenState();
}

class _LicenceTextsScreenState extends State<LicenceTextsScreen> {
  late final Future<Map<String, List<LicenseEntry>>> _packages = collectLicences();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SettingsPhonePage(
      title: l.licencesFull,
      backLabel: l.phoneKitBack,
      children: [
        FutureBuilder(
          future: _packages,
          builder: (context, snapshot) {
            final packages = snapshot.data;
            if (packages == null) return const Padding(padding: EdgeInsets.all(Kit.gutter), child: Center(child: CircularProgressIndicator()));
            return KitGroup(
              dividerInset: Kit.dividerInsetPlain,
              children: [
                for (final name in packages.keys)
                  KitRow(
                    size: KitRowSize.settings,
                    title: licencePackageName(name),
                    subtitle: l.licencesPackageCount(packages[name]!.length),
                    chevron: true,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => _LicenceTextScreen(name: licencePackageName(name), entries: packages[name]!),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// A package's name in sentence case: "tor" → "Tor"; a name with a capital already stays.
String licencePackageName(String name) =>
    name.isEmpty || name != name.toLowerCase() ? name : name[0].toUpperCase() + name.substring(1);

class _LicenceTextScreen extends StatelessWidget {
  const _LicenceTextScreen({required this.name, required this.entries});

  final String name;
  final List<LicenseEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    // The text as it is written: the mono face keeps its own line breaks and indents.
    final mono = theme.textTheme.bodyMedium?.copyWith(fontFamily: t.monoFamily, fontSize: 12, height: 1.4);
    return SettingsPhonePage(
      title: name,
      backLabel: context.l10n.phoneKitBack,
      children: [
        for (final (n, entry) in entries.indexed) ...[
          if (n > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Kit.gutter, vertical: 16),
              child: Divider(color: t.line, height: 1),
            ),
          // One preformatted block per licence, left-aligned, as the text is written.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
            child: SelectableText(licenceText(entry), style: mono),
          ),
        ],
      ],
    );
  }
}
