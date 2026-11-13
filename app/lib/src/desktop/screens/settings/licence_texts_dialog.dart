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
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  bool _focused = false;

  /// The package whose texts are open; null for the list.
  String? _open;

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// The packages whose names hold the search, in their order.
  List<MapEntry<String, List<LicenseEntry>>> _matches(Map<String, List<LicenseEntry>> packages) {
    final q = _search.text.trim().toLowerCase();
    return [
      for (final e in packages.entries)
        if (q.isEmpty || licencePackageName(e.key).toLowerCase().contains(q)) e,
    ];
  }

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
          // Dlg-Licences: a search over the packages, then one row each: the name, its licence
          // and how many texts; a row opens its texts.
          final shown = _matches(packages);
          // The field is built after the wait, when the dialog's focus has settled elsewhere.
          if (!_focused) {
            _focused = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _searchFocus.requestFocus();
            });
          }
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ESearch(
                controller: _search,
                focusNode: _searchFocus,
                autofocus: true,
                hint: l.deskLicSearch(packages.length),
                label: l.deskLicSearch(packages.length),
                clearLabel: l.deskActClearSearch,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (shown.isNotEmpty) setState(() => _open = shown.first.key);
                },
              ),
              SizedBox(height: Sp.x3),
              DecoratedBox(
                decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (shown.isEmpty) Padding(padding: EdgeInsets.all(Sp.x4), child: Text(packages.isEmpty ? l.deskLicEmpty : l.deskLicNone, style: ts.bodyDim)),
                    for (final (i, MapEntry(key: name, value: entries)) in shown.indexed)
                      EInkWell(
                        onTap: () => setState(() => _open = name),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: 10.u),
                          decoration: i == 0 ? null : BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(licencePackageName(name), style: ts.strong),
                                    Text(
                                      metaLine([licenceKind(entries), l.licencesPackageCount(entries.length)]),
                                      style: ts.small.copyWith(color: c.dim),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(EIcons.chevronRight, size: Ctl.icon, color: c.dim),
                            ],
                          ),
                        ),
                      ),
                  ],
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
          title: open == null ? l.deskLicTitle : licencePackageName(open),
          description: open == null ? l.deskLicDesc : metaLine([licenceKind(packages?[open] ?? const []), l.licencesPackageCount(packages?[open]?.length ?? 0)]),
          icon: EIcons.file,
          size: DialogWidth.wide,
          // Enter in the search opens the first package it shows.
          keys: [if (open == null && (packages?.isNotEmpty ?? false)) EKeyHint(keys: l.deskSetSearchKeyEnter, does: l.deskLicKeyOpen)],
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

/// The licence a package's texts name, by its usual short name (Apache-2.0, MIT, BSD-3-Clause,
/// …); null when the texts name none the app knows.
String? licenceKind(List<LicenseEntry> entries) {
  for (final e in entries) {
    final t = licenceText(e);
    if (t.contains('Apache License') && t.contains('Version 2.0')) return 'Apache-2.0';
    if (t.contains('SIL OPEN FONT LICENSE') || t.contains('SIL Open Font License')) return 'OFL-1.1';
    if (t.contains('Mozilla Public License') && t.contains('2.0')) return 'MPL-2.0';
    if (t.contains('Permission is hereby granted, free of charge')) return 'MIT';
    if (t.contains('Redistribution and use in source and binary forms')) {
      return t.contains('Neither the name') || t.contains('names of its') ? 'BSD-3-Clause' : 'BSD-2-Clause';
    }
    if (t.contains('Permission to use, copy, modify, and/or distribute')) return 'ISC';
    if (t.contains("This software is provided 'as-is'")) return 'Zlib'; // l10n-ok: a licence's SPDX name
  }
  return null;
}
