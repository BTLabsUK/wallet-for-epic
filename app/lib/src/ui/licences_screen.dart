// SPDX-License-Identifier: Apache-2.0
/// Settings › About › Licences: a few sentences, not a catalogue. The wallet, Flutter, LEPIC
/// with its key crates, Tor and the fonts, one line each with its licence, the bundled tor's
/// source note (its GPL asks for it), and the way to every full text.
library;

import 'package:flutter/foundation.dart' show LicenseEntry, LicenseParagraph, LicenseRegistry;
import 'package:flutter/material.dart';

import '../l10n.dart';
import '../tor_build.dart';
import '../tor_licence.dart';
import 'common.dart';
import 'settings_screen.dart' show projectRepoUrl;
import 'theme/fonts.dart' show flagsLicenceNote, sasPicturesLicenceNote;
import 'theme/tokens.dart';
import 'settings_rows.dart' show NavChevron;

/// The key of the button that opens the full texts, for tests.
const Key licencesFullKey = ValueKey('licences-full');

class LicencesScreen extends StatelessWidget {
  const LicencesScreen({super.key, this.version});

  /// The app version Flutter's licence page shows under the app's name.
  final String? version;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium;
    final dim = body?.copyWith(color: t.dim);
    return SlotScaffold(
      appBar: AppBar(title: Text(l.settingsLicences)),
      body: ScreenBody(
        children: [
          Text(l.licencesLead, style: dim),
          const SizedBox(height: 16),
          for (final line in [
            l.licencesApp,
            l.licencesFlutter,
            l.licencesLepic,
            if (torBuilt) l.licencesTor,
            l.licencesFonts,
            flagsLicenceNote,
            sasPicturesLicenceNote,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(line, style: body),
            ),
          const SizedBox(height: 6),
          // The legal minimum for the bundled tor: which build, which licence, where its
          // source is. English, as the licence texts themselves.
          // No tor in the build without Tor ([torBuilt]): nothing to name.
          if (torBuilt)
            TorSourceNote(
              style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
            ),
          if (projectRepoUrl != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              projectRepoUrl!,
              style: TextStyle(fontFamily: t.monoFamily, fontSize: 12, color: t.dim),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: licencesFullKey,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.article_outlined),
            label: Text(l.licencesFull),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const LicenceTextsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every full licence text the app carries, in the app's own look (UP-025): the usual section
/// page, one row per package in sentence case ("Tor", not "tor") with how many licences it
/// has, and each text in the body face on the dark surface. Flutter's stock page centred the
/// paragraphs in Roboto with "====" rules.
class LicenceTextsScreen extends StatefulWidget {
  const LicenceTextsScreen({super.key});

  @override
  State<LicenceTextsScreen> createState() => _LicenceTextsScreenState();
}

class _LicenceTextsScreenState extends State<LicenceTextsScreen> {
  late final Future<Map<String, List<LicenseEntry>>> _packages = _collect();

  static Future<Map<String, List<LicenseEntry>>> _collect() async {
    final byPackage = <String, List<LicenseEntry>>{};
    await for (final entry in LicenseRegistry.licenses) {
      for (final package in entry.packages) {
        byPackage.putIfAbsent(package, () => []).add(entry);
      }
    }
    final names = byPackage.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return {for (final n in names) n: byPackage[n]!};
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    return SlotScaffold(
      appBar: AppBar(title: Text(l.licencesFull)),
      body: FutureBuilder(
        future: _packages,
        builder: (context, snapshot) {
          final packages = snapshot.data;
          if (packages == null) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: packages.length,
            itemBuilder: (context, i) {
              final name = packages.keys.elementAt(i);
              final entries = packages[name]!;
              return ListTile(
                title: Text(licencePackageName(name)),
                subtitle: Text(
                  MaterialLocalizations.of(context).licensesPackageDetailText(entries.length),
                  style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
                ),
                trailing: const NavChevron(),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => _LicenceTextScreen(name: licencePackageName(name), entries: entries),
                  ),
                ),
              );
            },
          );
        },
      ),
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
    final body = theme.textTheme.bodyMedium;
    // The text as it is written: the mono face keeps its own line breaks and indents.
    final mono = body?.copyWith(fontFamily: t.monoFamily, fontSize: 12, height: 1.4);
    return SlotScaffold(
      appBar: AppBar(title: Text(name)),
      body: ScreenBody(
        children: [
          for (final (n, entry) in entries.indexed) ...[
            if (n > 0) ...[
              const SizedBox(height: 16),
              Divider(color: t.line, height: 1),
              const SizedBox(height: 16),
            ],
            for (final paragraph in entry.paragraphs)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  bottom: 10,
                  start: paragraph.indent == LicenseParagraph.centeredIndent ? 0 : 16.0 * paragraph.indent,
                ),
                child: SelectableText(
                  paragraph.text,
                  textAlign: paragraph.indent == LicenseParagraph.centeredIndent ? TextAlign.center : TextAlign.start,
                  style: paragraph.indent > 0 ? mono : body,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
