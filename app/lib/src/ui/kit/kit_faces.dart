// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../theme/tokens.dart';
import 'kit_avatar.dart';
import 'kit_headers.dart' show KitIconButton;
import 'kit_icons.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// One face of a [KitFacesStrip]: a person or a shop, with the name under it.
class KitFace {
  const KitFace({required this.label, this.initials, this.icon, required this.onTap, this.semanticsId});

  final String label;
  final String? initials;
  final IconData? icon;
  final VoidCallback onTap;
  final String? semanticsId;
}

/// The row of faces under the Who field (HANDOFF 9, Send): 54 px avatars with the name under
/// each, scrolling sideways. Tapping one picks that contact.
class KitFacesStrip extends StatelessWidget {
  const KitFacesStrip({super.key, required this.faces, this.bleed = 0});

  final List<KitFace> faces;

  /// How far the strip reaches past its parent's padding on each side, so faces scroll to the
  /// screen edge.
  final double bleed;

  static const double _cell = 72;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    const stripHeight = Kit.avatarStrip + 34;
    final strip = SizedBox(
      height: stripHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: bleed + Kit.gutter - 6),
        itemCount: faces.length,
        itemBuilder: (context, i) {
          final f = faces[i];
          return kitId(
            f.semanticsId,
            Semantics(
              button: true,
              label: f.label,
              excludeSemantics: true,
              onTap: f.onTap,
              child: SizedBox(
                width: _cell,
                child: InkWell(
                  borderRadius: BorderRadius.circular(Kit.rButtonSmall),
                  onTap: f.onTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 2),
                      if (f.initials != null && f.initials!.isNotEmpty)
                        KitAvatar(initials: f.initials, large: true)
                      else
                        KitAvatar(icon: f.icon ?? KitIcons.contact, large: true),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          f.label,
                          style: KitType.rowSub.copyWith(color: t.dim),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    if (bleed == 0) return strip;
    return LayoutBuilder(
      builder: (context, box) => SizedBox(
        height: stripHeight,
        child: OverflowBox(
          minWidth: box.maxWidth + 2 * bleed,
          maxWidth: box.maxWidth + 2 * bleed,
          minHeight: stripHeight,
          maxHeight: stripHeight,
          child: strip,
        ),
      ),
    );
  }
}

/// The frame of a complete address (Send-5): a gold-edged box round the address field, which
/// shows the address in the mono face over as many lines as it needs, with a × to clear it. The
/// screen passes its own field as [child], so what is typed or pasted stays one field.
class KitAddressBox extends StatelessWidget {
  const KitAddressBox({super.key, required this.child, required this.onClear, this.clearId, this.clearKey, this.margin = EdgeInsets.zero});

  final Widget child;
  final VoidCallback onClear;
  final String? clearId;

  /// The key of the × button, for tests.
  final Key? clearKey;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    return Padding(
      padding: margin,
      child: Container(
        padding: const EdgeInsetsDirectional.only(start: 14, top: 4, bottom: 4, end: 2),
        decoration: BoxDecoration(
          color: t.fill,
          border: Border.all(color: t.goldLine),
          borderRadius: BorderRadius.circular(Kit.rButton),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: child)),
            KitIconButton(key: clearKey, icon: KitIcons.close, label: l.sendClearRecipient, onPressed: onClear, color: t.dim, semanticsId: clearId),
          ],
        ),
      ),
    );
  }
}
