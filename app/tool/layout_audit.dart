// SPDX-License-Identifier: Apache-2.0
// Layout audit beside each desktop tour screenshot: with LAYOUT_AUDIT=1 the tour writes
// `<shot>.layout.json` listing what reads badly in a narrow window: an address that wraps, text
// squeezed into a thin column (three or more short lines), and text cut by an ellipsis.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

final bool layoutAudit = Platform.environment['LAYOUT_AUDIT'] == '1';

// Epicbox (base58 key @ host), onion and HTTP addresses, whole or as the start of a text.
final RegExp _address = RegExp(r'([1-9A-HJ-NP-Za-km-z]{40,}(@[\w.-]+)?|[a-z2-7]{56}\.onion|https?://\S{12,})');

int _lines(RenderParagraph p) {
  final len = p.text.toPlainText().length;
  if (len == 0) return 0;
  final boxes = p.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: len));
  return boxes.map((b) => b.top.round()).toSet().length;
}

/// Writes `<png without .png>.layout.json` for what is on stage under [root]; [unit] is the
/// interface scale's pixel factor, so widths are compared in 100 % pixels.
void writeLayoutAudit(String png, Element root, double unit) {
  final screen = Offset.zero & ((root.renderObject as RenderBox?)?.size ?? Size.zero);
  final findings = <Map<String, Object?>>[];
  void visit(RenderObject o) {
    if (o is RenderParagraph && o.hasSize && o.attached) {
      final rect = o.localToGlobal(Offset.zero) & o.size;
      if (rect.overlaps(screen) && rect.width > 0) {
        final text = o.text.toPlainText(includeSemanticsLabels: false).trim();
        final lines = _lines(o);
        final w = rect.width / unit;
        String? kind;
        if (_address.hasMatch(text) && lines > 1) {
          kind = lines >= 3 ? 'address-3-lines' : 'address-2-lines';
        } else if (lines >= 3 && w < 220 && text.length > 24) {
          kind = 'squeezed';
        } else if (o.didExceedMaxLines && text.length > 3) {
          kind = 'cut';
        }
        if (kind != null) {
          findings.add({
            'kind': kind,
            'text': text.length > 80 ? '${text.substring(0, 77)}…' : text,
            'lines': lines,
            'rect': [rect.left.round(), rect.top.round(), rect.width.round(), rect.height.round()],
          });
        }
      }
    }
    o.visitChildren(visit);
  }

  final ro = root.renderObject;
  if (ro != null) visit(ro);
  File('${png.substring(0, png.length - 4)}.layout.json').writeAsStringSync(jsonEncode(findings));
}
