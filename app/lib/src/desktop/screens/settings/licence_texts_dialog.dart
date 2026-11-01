// SPDX-License-Identifier: Apache-2.0
/// Settings › About › Licences › View: every full licence text the app carries, in the
/// desktop's own dialog. One row per package; a row opens its texts in the same dialog, each
/// as one preformatted mono block, left-aligned and selectable (the phone's
/// [LicenceTextsScreen] shows the same).
library;

import 'package:flutter/foundation.dart' show LicenseEntry;
import 'package:flutter/material.dart';

import '../../../licence_texts.dart';
import '../../../ui/licences_screen.dart' show licencePackageName;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// The key of the licence texts dialog, for tests.
const Key deskLicenceTextsKey = ValueKey('desk-licence-texts');

Future<void> showLicenceTextsDialog(BuildContext context) =>
    showEDialog<void>(context, builder: (_) => const LicenceTextsDialog(key: deskLicenceTextsKey));

class LicenceTextsDialog extends StatefulWidget {
  const LicenceTextsDialog({super.key});

  @override
  State<LicenceTextsDialog> createState() => _LicenceTextsDialogState();
}

class _LicenceTextsDialogState extends State<LicenceTextsDialog> {
  late final Future<Map<String, List<LicenseEntry>>> _packages = collectLicences();

  /// The package whose texts are open; null for the list.
  String? _open;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    return FutureBuilder(
      future: _packages,
      builder: (context, snapshot) {
        final packages = snapshot.data;
        final open = _open;
        final Widget body;
        if (packages == null) {
          body = Center(child: Padding(padding: EdgeInsets.all(Sp.x6), child: const ESpinner()));
        } else if (open == null) {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final MapEntry(key: name, value: entries) in packages.entries)
                InkWell(
                  borderRadius: BorderRadius.circular(Rad.sm),
                  onTap: () => setState(() => _open = name),
                  child: Container(
                    constraints: BoxConstraints(minHeight: Ctl.md),
                    padding: EdgeInsets.symmetric(horizontal: Sp.x2),
                    child: Row(
                      children: [
                        Expanded(child: Text(licencePackageName(name), style: ts.body)),
                        Text(MaterialLocalizations.of(context).licensesPackageDetailText(entries.length), style: ts.small),
                        SizedBox(width: Sp.x2),
                        Icon(EIcons.chevronRight, size: Ctl.icon, color: c.dim),
                      ],
                    ),
                  ),
                ),
            ],
          );
        } else {
          final entries = packages[open] ?? const <LicenseEntry>[];
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (n, entry) in entries.indexed) ...[
                if (n > 0) EDivider(space: Sp.x4),
                // One preformatted block per licence, left-aligned, as the text is written.
                Text(licenceText(entry), style: ts.mono(size: Fs.xs).copyWith(height: 1.4)),
              ],
            ],
          );
        }
        return EDialog(
          title: open == null ? l.licencesFull : licencePackageName(open),
          width: 720.u,
          body: body,
          actions: [
            if (open != null) EButton(label: l.deskSendBack, onPressed: () => setState(() => _open = null)),
            EButton(label: l.commonClose, kind: EBtnKind.primary, onPressed: () => Navigator.of(context).pop()),
          ],
        );
      },
    );
  }
}
