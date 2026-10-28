// SPDX-License-Identifier: Apache-2.0
// Metadata beside each tour screenshot, for the release screen catalog (tools/screens.sh): with
// SHOTS_META=1 a tour writes `<shot>.json` next to `<shot>.png` holding the text the screen shows
// and the widget classes on stage, so an agent can find a screen by its words or its code.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final bool shotMeta = Platform.environment['SHOTS_META'] == '1';

/// Widget classes worth naming: screens and what opens over them. tools/screens.sh keeps the ones
/// the app's lib/ declares and finds their files.
final RegExp _named = RegExp(r'(Screen|Page|View|Sheet|Dialog|Drawer|Panel|Pane|Tab|Card|Step)$');

final RegExp _icons = RegExp(r'[\uE000-\uF8FF\u{F0000}-\u{10FFFD}]', unicode: true);

/// Writes `<png without .png>.json`: [fields], the visible text in tree order and the named
/// widget classes, from what is on stage under [root].
void writeShotMeta(String png, Element root, Map<String, Object?> fields) {
  final clock = Stopwatch()..start();
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
  final interactive = countInteractive(root, screen);
  final out = File('${png.substring(0, png.length - 4)}.json');
  out.writeAsStringSync(
    jsonEncode({...fields, 'text': texts, 'widgets': classes, 'interactive': interactive, 'meta_ms': clock.elapsedMicroseconds / 1000}),
  );
}

/// The controls a person can reach on stage under [root]: buttons, rows and chips that answer a
/// tap, switches, checkboxes, radios, sliders and text fields. A control inside another counted
/// one (a switch in its row, an icon in its button) is the same control and counts once.
int countInteractive(Element root, Rect screen) {
  var n = 0;
  void visit(Element e, bool inside) {
    final w = e.widget;
    final control = !inside &&
        switch (w) {
          InkResponse() => w.onTap != null || w.onLongPress != null,
          GestureDetector() => w.onTap != null || w.onLongPress != null,
          EditableText() || Switch() || Checkbox() || Radio() || Slider() => true,
          _ => false,
        };
    if (control) {
      final box = e.renderObject;
      if (box is RenderBox && box.hasSize && box.attached && box.size.width > 0 && box.size.height > 0) {
        final rect = box.localToGlobal(Offset.zero) & box.size;
        if (rect.overlaps(screen)) n++;
      }
    }
    // Onstage only, as the text above: routes under the top one and offstage children skip.
    e.debugVisitOnstageChildren((c) => visit(c, inside || control));
  }
  visit(root, false);
  return n;
}
