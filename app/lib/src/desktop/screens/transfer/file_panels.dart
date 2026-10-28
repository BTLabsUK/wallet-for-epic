// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/files.dart' show deskOpenFolderProvider;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// A square outlined glyph with a status tone, as the original's `e-glyph-sq`.
class ResultGlyph extends StatelessWidget {
  const ResultGlyph({super.key, this.icon = EIcons.check, this.tone = ETone.ok});

  final IconData icon;
  final ETone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final (fg, bg) = switch (tone) {
      ETone.risk => (c.risk, c.riskSoft),
      ETone.warn => (c.warn, c.warnSoft),
      ETone.ok => (c.ok, c.okSoft),
      ETone.info => (c.info, c.infoSoft),
      _ => (c.accentText, c.accentSoft),
    };
    return ExcludeSemantics(
      child: Container(
        width: 48.u,
        height: 48.u,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Rad.sm)),
        child: Icon(icon, size: Ctl.iconLg, color: fg),
      ),
    );
  }
}

/// [path]'s folder with its separator, or '' for a bare name.
String _folderOf(String path) {
  final i = path.lastIndexOf(RegExp(r'[\\/]'));
  return i < 0 ? '' : path.substring(0, i + 1);
}

/// [path]'s file name.
String _baseOf(String path) => path.substring(_folderOf(path).length);

/// The file a flow produced: name in mono with Copy, and Open folder while it is on disk (the
/// wallet writes every file it makes; the mock's names are not).
class FileChip extends ConsumerWidget {
  const FileChip(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    return Container(
      padding: EdgeInsets.fromLTRB(Sp.x4, Sp.x2, Sp.x2, Sp.x2),
      decoration: BoxDecoration(
        color: c.s2,
        borderRadius: BorderRadius.circular(Rad.sm),
        border: Border.all(color: c.lineStrong),
      ),
      child: Row(
        children: [
          Icon(EIcons.file, size: Ctl.icon, color: c.dim),
          SizedBox(width: Sp.x3),
          // The folder gives way, the file name stays whole (never overflow): the full path on
          // hover and in Copy (WIN2-2).
          Expanded(
            child: Tooltip(
              message: name,
              child: LayoutBuilder(
                builder: (context, box) => Row(
                  children: [
                    Flexible(child: Text(_folderOf(name), style: ts.mono(size: Fs.sm), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    // First served; cut only when the name alone is wider than the chip.
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: box.maxWidth),
                      child: Text(_baseOf(name), style: ts.mono(size: Fs.sm), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: Sp.x2),
          if (File(name).existsSync()) ...[
            EButton(
              label: context.l10n.deskFinOpenFolder,
              icon: EIcons.folderOpen,
              size: EBtnSize.inline,
              onPressed: () async {
                if (!await ref.read(deskOpenFolderProvider)(File(name).parent.path) && context.mounted) showEToast(context, context.l10n.deskFinFolderNotOpened, text: name, tone: ETone.warn);
              },
            ),
            SizedBox(width: Sp.x2),
          ],
          ECopyButton(text: name, label: context.l10n.commonCopy, withLabel: true, kind: EBtnKind.secondary),
        ],
      ),
    );
  }
}

/// A centered result card: glyph, title, text, optional body and actions.
class ResultPanel extends StatelessWidget {
  const ResultPanel({super.key, required this.title, required this.text, this.glyph, this.body, this.actions = const []});

  final String title;
  final String text;
  final Widget? glyph;
  final Widget? body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    return EPanel(
      padding: EdgeInsets.all(Sp.x8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          glyph ?? const ResultGlyph(),
          SizedBox(height: Sp.x4),
          Semantics(header: true, child: Text(title, style: ts.h3)),
          SizedBox(height: Sp.x2),
          Text(text, style: ts.bodyDim),
          if (body != null) ...[SizedBox(height: Sp.x5), body!],
          if (actions.isNotEmpty) ...[
            SizedBox(height: Sp.x6),
            Wrap(spacing: Sp.x3, runSpacing: Sp.x2, children: actions),
          ],
        ],
      ),
    );
  }
}
