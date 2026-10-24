// Metadata beside each tour screenshot, for the release screen catalog (tools/screens.sh): with
// SHOTS_META=1 a tour writes `<shot>.json` next to `<shot>.png` holding the text the screen shows
// and the widget classes on stage, so an agent can find a screen by its words or its code.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final bool shotMeta = Platform.environment['SHOTS_META'] == '1';

/// Widget classes worth naming: screens and what opens over them. tools/screens.sh keeps the ones
/// the app's lib/ declares and finds their files.
final RegExp _named = RegExp(r'(Screen|Page|View|Sheet|Dialog|Drawer|Panel|Pane|Tab|Card|Step)$');

final RegExp _icons = RegExp('[\uE000-\uF8FF]');

/// Writes `<png without .png>.json`: [fields], the visible text in tree order and the named
/// widget classes, from what is on stage under [root].
void writeShotMeta(String png, Element root, Map<String, Object?> fields) {
  final screen = Offset.zero & ((root.renderObject as RenderBox?)?.size ?? Size.zero);
  final texts = <String>[];
  final seen = <String>{};
  final classes = <String>[];
  for (final e in collectAllElementsFrom(root, skipOffstage: true)) {
    final w = e.widget;
    final name = w.runtimeType.toString();
    if (_named.hasMatch(name) && !name.startsWith('_') && !classes.contains(name)) classes.add(name);
    final String? text = switch (w) {
      RichText() => w.text.toPlainText(includeSemanticsLabels: false, includePlaceholders: false),
      EditableText() => w.controller.text,
      _ => null,
    };
    if (text == null) continue;
    // Icons draw as private-use glyphs.
    final t = text.replaceAll(_icons, '').trim();
    if (t.isEmpty || seen.contains(t)) continue;
    final box = e.renderObject;
    if (box is! RenderBox || !box.hasSize || !box.attached) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (!rect.overlaps(screen)) continue;
    seen.add(t);
    texts.add(t);
  }
  final out = File('${png.substring(0, png.length - 4)}.json');
  out.writeAsStringSync(jsonEncode({...fields, 'text': texts, 'widgets': classes}));
}
