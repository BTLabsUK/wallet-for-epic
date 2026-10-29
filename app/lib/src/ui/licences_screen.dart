// SPDX-License-Identifier: Apache-2.0
/// Settings › About › Licences: a few sentences, not a catalogue. The wallet, Flutter, LEPIC
/// with its key crates, Tor and the fonts, one line each with its licence, the bundled tor's
/// source note (its GPL asks for it), and the way to every full text.
library;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../tor_build.dart';
import '../tor_licence.dart';
import 'common.dart';
import 'settings_screen.dart' show openFlutterLicences, projectRepoUrl;
import 'theme/fonts.dart' show flagsLicenceNote;
import 'theme/tokens.dart';

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
            onPressed: () => openFlutterLicences(context, version),
          ),
        ],
      ),
    );
  }
}
