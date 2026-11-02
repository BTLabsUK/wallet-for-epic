// SPDX-License-Identifier: Apache-2.0
/// Settings › About › Licences: a few sentences, not a catalogue, folded in About until tapped.
/// The wallet, Flutter, LEPIC with its key crates, Tor and the fonts, one line each with its
/// licence, the bundled tor's source note (its GPL asks for it), and the way to every full text.
library;

import 'package:flutter/foundation.dart' show LicenseEntry;
import 'package:flutter/material.dart';

import '../l10n.dart';
import '../licence_texts.dart';
import '../tor_build.dart';
import '../tor_licence.dart';
import 'common.dart';
import 'theme/fonts.dart' show flagsLicenceNote, sasPicturesLicenceNote;
import 'theme/tokens.dart';
import 'settings_rows.dart' show NavChevron;

/// The key of the button that opens the full texts, for tests.
const Key licencesFullKey = ValueKey('licences-full');

/// Settings › About › Licences, folded (item 5): a heading and one line until tapped; open,
/// one line per component with its licence, the bundled tor's source note (its GPL asks for
/// it, so it stays one tap away) and the way to every full text. [rowKey] is the heading's.
class LicencesFold extends StatefulWidget {
  const LicencesFold({super.key, this.rowKey});

  /// The key of the heading row, for tests.
  final Key? rowKey;

  @override
  State<LicencesFold> createState() => _LicencesFoldState();
}

class _LicencesFoldState extends State<LicencesFold> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: _open,
          child: ListTile(
            key: widget.rowKey,
            leading: const Icon(Icons.article_outlined),
            title: Text(l.settingsLicences),
            subtitle: Text(l.licencesLead, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: ExcludeSemantics(
              child: Icon(_open ? Icons.unfold_less : Icons.unfold_more, color: t.dim),
            ),
            onTap: () => setState(() => _open = !_open),
          ),
        ),
        if (_open)
          Padding(
            // Under the title, past the leading icon (the settings rows' 56 dp line).
            padding: const EdgeInsets.fromLTRB(72, 4, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                if (torBuilt) TorSourceNote(style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                // The source code's address is About's Source code row, right under the fold.
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    key: licencesFullKey,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                    icon: const Icon(Icons.article_outlined),
                    label: Text(l.licencesFull),
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(builder: (_) => const LicenceTextsScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

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
                  l.licencesPackageCount(entries.length),
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
    // The text as it is written: the mono face keeps its own line breaks and indents.
    final mono = theme.textTheme.bodyMedium?.copyWith(fontFamily: t.monoFamily, fontSize: 12, height: 1.4);
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
            // One preformatted block per licence, left-aligned, as the text is written.
            SelectableText(licenceText(entry), style: mono),
          ],
        ],
      ),
    );
  }
}
