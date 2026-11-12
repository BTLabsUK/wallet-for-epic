// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../theme/tokens.dart';
import 'kit_headers.dart' show KitIconButton;
import 'kit_icons.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The search or address field (HANDOFF 7.4): 42 tall, radius 13, the quiet fill, a search
/// glyph, a [hint], and optionally a "Paste" text button and a scan icon at the end. The paste
/// and scan buttons show when their callbacks are set.
class KitSearchField extends StatelessWidget {
  const KitSearchField({
    super.key,
    this.controller,
    this.focusNode,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onPaste,
    this.onScan,
    this.icon = KitIcons.search,
    this.semanticsId,
    this.pasteId,
    this.scanId,
    this.margin = const EdgeInsets.symmetric(horizontal: Kit.gutter),
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onPaste;
  final VoidCallback? onScan;
  final IconData icon;
  final String? semanticsId;
  final String? pasteId;
  final String? scanId;
  final EdgeInsetsGeometry margin;

  static const double _hit = 48;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    return Padding(
      padding: margin,
      // The pill is 42 tall; the row around it is 48, so the field is a full touch target.
      child: SizedBox(
        height: _hit,
        child: Stack(
          children: [
            Positioned.fill(
              top: (_hit - Kit.searchField) / 2,
              bottom: (_hit - Kit.searchField) / 2,
              child: DecoratedBox(decoration: BoxDecoration(color: t.fill, borderRadius: BorderRadius.circular(Kit.rSearch))),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
          children: [
            ExcludeSemantics(child: Icon(icon, size: 20, color: t.faint)),
            const SizedBox(width: 9),
            Expanded(
              child: kitId(
                semanticsId,
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: KitType.body.copyWith(color: t.text),
                  cursorColor: t.accent,
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: hint,
                    hintStyle: KitType.body.copyWith(color: t.faint),
                  ),
                ),
              ),
            ),
            if (onPaste != null)
              kitId(
                pasteId,
                Semantics(
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Kit.rButtonSmall),
                    onTap: onPaste,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: Kit.hitMin - 2, minWidth: Kit.hitMin),
                      child: Center(
                        widthFactor: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(l.commonPaste, style: KitType.buttonSmall.copyWith(color: t.accentText)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (onScan != null)
              KitIconButton(icon: KitIcons.scan, label: l.sendScanButton, onPressed: onScan, color: t.dim, semanticsId: scanId),
          ],
        ),
            ),
          ],
        ),
      ),
    );
  }
}
