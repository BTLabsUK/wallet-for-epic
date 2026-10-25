import 'package:flutter/material.dart';

import '../../recipient.dart' show RecipientKind;

import '../desk_l10n.dart';
import '../../address_format.dart';
import '../data/addresses.dart';
import '../theme/tokens.dart';
import 'surfaces.dart';

/// An address in a list row: the first and last six of the checked part (`shortAddress`), the
/// compact form when the full short form does not fit. Never a tail ellipsis, which would eat
/// the last six. The whole address is in the tooltip and the screen-reader label; the widget
/// never copies (the row's detail view has the one copy control).
class EShortAddress extends StatelessWidget {
  const EShortAddress(this.address, {super.key, this.style, this.tooltip = true});

  final String address;
  final TextStyle? style;
  final bool tooltip;

  @override
  Widget build(BuildContext context) {
    final st = style ?? context.ts.mono(size: Fs.sm, color: context.dc.dim);
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    Widget text = LayoutBuilder(
      builder: (context, box) {
        var shown = shortAddress(address);
        if (box.maxWidth.isFinite) {
          final tp = TextPainter(text: TextSpan(text: shown, style: st), textDirection: dir, textScaler: scaler, maxLines: 1)..layout();
          if (tp.width + _drawSlack > box.maxWidth) shown = shortAddress(address, compact: true);
          tp.dispose();
        }
        return Text(shown, style: st, maxLines: 1, softWrap: false, overflow: TextOverflow.clip);
      },
    );
    text = Semantics(label: address, excludeSemantics: true, child: text);
    if (!tooltip) return text;
    return Tooltip(
      richMessage: TextSpan(text: address, style: context.ts.mono(size: Fs.xs, color: context.dc.text)),
      waitDuration: const Duration(milliseconds: 400),
      child: text,
    );
  }
}

/// The width [EShortAddress] takes for [address] in [style] when it is not squeezed: the full
/// short form. Rows use it to give the address its own width before the note.
double shortAddressWidth(BuildContext context, String address, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: shortAddress(address), style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final w = tp.width;
  tp.dispose();
  // A few pixels over the measure: Windows draws monospace a little wider than measured, which
  // clipped the last letter of the domain (PAIR-WIN-3).
  return w.ceilToDouble() + _drawSlack;
}

/// Room left over a measured address for the way Windows draws it.
const double _drawSlack = 6;

/// The kind badge of an address row: Epicbox, Link · HTTP or Link · Tor, each
/// with its glyph.
class EKindTag extends StatelessWidget {
  const EKindTag(this.kind, {super.key, this.compact = false});

  final AddressKind kind;

  /// The glyph alone, its name in the tooltip: list rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return switch (kind) {
      AddressKind.epicbox => EBadge.kind(RecipientKind.epicbox, l: l, compact: compact),
      AddressKind.http => EBadge.kind(RecipientKind.http, l: l, compact: compact),
      AddressKind.tor => EBadge.kind(RecipientKind.tor, l: l, compact: compact),
      AddressKind.none => EBadge(l.deskKitUnknown),
    };
  }
}

/// The two text lines of a row that carries an address (spec 7.1): name, [nameTrailing] and
/// the kind tag; then the short address and the note. When the row is narrow the note gives way
/// first (down to 12 characters), then the address falls to its compact form, then the note
/// goes. Nothing wraps. A contact with several [addresses] shows their kind tags instead of
/// one address (SPEC 2.5).
class EAddressLines extends StatelessWidget {
  const EAddressLines({super.key, required this.name, required this.address, this.addresses, this.note, this.nameTrailing, this.addressStyle});

  final String name;
  final String address;

  /// Every address of the contact, when it can have several; [address] is the first.
  final List<String>? addresses;
  final String? note;
  final Widget? nameTrailing;
  final TextStyle? addressStyle;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final aStyle = addressStyle ?? ts.mono(size: Fs.sm, color: c.dim);
    final nStyle = ts.small.copyWith(color: c.faint);
    final n = note?.split('\n').first.trim() ?? '';
    final several = (addresses?.length ?? 0) > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(child: Text(name, style: ts.strong, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ?nameTrailing,
            // A contact with no address (paired only) has no kind to tag (PAIR-LNX-5).
            if (address.trim().isNotEmpty && !several) ...[SizedBox(width: Sp.x2), EKindTag(addressKindOf(address), compact: true)],
          ],
        ),
        const SizedBox(height: 2),
        LayoutBuilder(
          builder: (context, box) {
            if (address.trim().isEmpty) return Text(n, style: nStyle, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis);
            if (several) {
              return Row(
                children: [
                  for (final a in addresses!) ...[EKindTag(addressKindOf(a), compact: true), SizedBox(width: Sp.x1)],
                  if (n.isNotEmpty) Flexible(child: Text(' · $n', style: nStyle, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis)),
                ],
              );
            }
            if (n.isEmpty) return EShortAddress(address, style: aStyle);
            final noteMin = _width(context, ' · ${n.length > 12 ? n.substring(0, 12) : n}', nStyle);
            final full = shortAddressWidth(context, address, aStyle);
            final compact = _width(context, shortAddress(address, compact: true), aStyle) + 1;
            final double? w = full + noteMin <= box.maxWidth ? full : (compact + noteMin <= box.maxWidth ? compact : null);
            if (w == null) return EShortAddress(address, style: aStyle);
            return Row(
              children: [
                SizedBox(width: w, child: EShortAddress(address, style: aStyle)),
                Flexible(child: Text(' · $n', style: nStyle, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis)),
              ],
            );
          },
        ),
      ],
    );
  }

  static double _width(BuildContext context, String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final w = tp.width;
    tp.dispose();
    return w.ceilToDouble();
  }
}
