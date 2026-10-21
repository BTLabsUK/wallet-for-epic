import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// The file a flow produced: name in mono with Save and Copy.
class FileChip extends StatelessWidget {
  const FileChip(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
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
          Expanded(child: SelectableText(name, style: ts.mono(size: Fs.sm), maxLines: 1)),
          SizedBox(width: Sp.x2),
          EButton(
            label: 'Save',
            icon: EIcons.download,
            size: EBtnSize.inline,
            onPressed: () => showEToast(context, 'File saved', text: name),
          ),
          SizedBox(width: Sp.x2),
          EButton(
            label: 'Copy',
            icon: EIcons.copy,
            size: EBtnSize.inline,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: name));
              showEToast(context, 'Copied');
            },
          ),
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
