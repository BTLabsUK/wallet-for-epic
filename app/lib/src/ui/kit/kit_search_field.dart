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
    this.fieldKey,
    this.textInputAction,
    this.keyboardType,
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

  /// The key of the inner text field, for tests that type into it.
  final Key? fieldKey;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
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
                  key: fieldKey,
                  textInputAction: textInputAction,
                  keyboardType: keyboardType,
                  autocorrect: false,
                  enableSuggestions: false,
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

/// The Who field of a flow (`.field` in wallet.css; Send-1): 52 tall at least, radius 16, the
/// quiet fill and a hair border (gold while the field has focus), a search glyph, the [hint], a
/// gold "Paste" and a gold scan mark without a fill. The buttons are 48 to touch, the frame's 40
/// drawn inside them.
class KitAddressField extends StatelessWidget {
  const KitAddressField({
    super.key,
    this.controller,
    this.focusNode,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onPaste,
    this.onScan,
    this.semanticsId,
    this.pasteId,
    this.scanId,
    this.fieldKey,
    this.textInputAction,
    this.keyboardType,
    this.margin = EdgeInsets.zero,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onPaste;
  final VoidCallback? onScan;
  final String? semanticsId;
  final String? pasteId;
  final String? scanId;
  final Key? fieldKey;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final focus = focusNode;
    if (focus == null) return _field(context, false);
    return ListenableBuilder(listenable: focus, builder: (context, _) => _field(context, focus.hasFocus));
  }

  Widget _field(BuildContext context, bool on) {
    final t = context.tokens;
    final l = context.l10n;
    final text = KitType.body.copyWith(fontSize: 16, color: t.text);
    return Padding(
      padding: margin,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsetsDirectional.fromSTEB(14, 2, 2, 2),
        decoration: BoxDecoration(
          color: t.fill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: on ? t.goldLine : t.hair),
        ),
        child: Row(
          children: [
            ExcludeSemantics(child: Icon(KitIcons.search, size: 18, color: t.faint)),
            const SizedBox(width: 10),
            Expanded(
              child: kitId(
                semanticsId,
                TextField(
                  key: fieldKey,
                  textInputAction: textInputAction,
                  keyboardType: keyboardType,
                  autocorrect: false,
                  enableSuggestions: false,
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: text,
                  cursorColor: t.accent,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: hint,
                    hintStyle: text.copyWith(color: t.faint),
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
                      constraints: const BoxConstraints(minHeight: Kit.hitTarget, minWidth: Kit.hitTarget),
                      child: Center(
                        widthFactor: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(l.commonPaste, style: KitType.body.copyWith(fontSize: 15, fontWeight: FontWeight.w500, color: t.accentText)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (onScan != null)
              KitIconButton(icon: KitIcons.scan, label: l.sendScanButton, onPressed: onScan, color: t.accentText, bare: true, glyphSize: 22, semanticsId: scanId),
          ],
        ),
      ),
    );
  }
}
