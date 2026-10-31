// SPDX-License-Identifier: Apache-2.0
/// The donation note at the end of the phone's Help: a heading, one line, and a button that
/// copies BT Labs' donation address (the same one the contacts book starts with).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../seed_contacts.dart';

/// The key of the Copy address button, for tests.
const Key helpDonateCopyKey = ValueKey('help-donate-copy');

/// Support development: heading, line and a Copy address button.
class DonateNote extends StatefulWidget {
  const DonateNote({super.key});

  @override
  State<DonateNote> createState() => _DonateNoteState();
}

class _DonateNoteState extends State<DonateNote> {
  /// Read once when the note opens: a signed btlabs.json verified meanwhile never changes
  /// what this note copies.
  final String? _address = btLabsContact?.address;

  @override
  Widget build(BuildContext context) {
    // No donation contact in app-config.toml: no note.
    final address = _address;
    if (address == null) return const SizedBox.shrink();
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(l.helpDonateTitle, style: text.titleMedium)),
          const SizedBox(height: 8),
          Text(l.helpDonateText),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: helpDonateCopyKey,
              icon: const Icon(Icons.copy_outlined),
              label: Text(l.helpDonateCopy),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: address));
                messenger.showSnackBar(SnackBar(content: Text(l.helpDonateCopied)));
              },
            ),
          ),
        ],
      ),
    );
  }
}
