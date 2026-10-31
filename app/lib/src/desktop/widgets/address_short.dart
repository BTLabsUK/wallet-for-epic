// SPDX-License-Identifier: Apache-2.0
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
        // Lists drop a link's scheme (http://, https://); the tooltip and Copy keep it.
        final link = RegExp(r'^\s*https?://', caseSensitive: false).hasMatch(address);
        var shown = shortAddress(address, compact: link);
        if (!link && box.maxWidth.isFinite) {
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

/// An address in full where a detail view shows it (never cut): the checked part in chunks
/// of as many characters as the column holds (measured from the mono style; [chunk] caps
/// it), one per line, its first and last six in the accent as on Receive; a server part
/// ("@epicbox.example.org") whole on its own line. No line holds fewer than six characters:
/// the chunk shrinks until the last line has them (UD-001).
class EFullAddress extends StatelessWidget {
  const EFullAddress(this.address, {super.key, this.chunk = 26, this.size});

  final String address;

  /// The most characters on a line; the column's width may give fewer.
  final int chunk;
  final double? size;

  /// The characters per line for [key] in a column [width] wide where one glyph is
  /// [glyph] wide: the most that fit (at most [max]), reduced until the last line
  /// holds at least six (or every line, when the key is short).
  static int chunkFor(int keyLength, double width, double glyph, int max) {
    var n = glyph <= 0 || !width.isFinite ? max : (width / glyph).floor().clamp(6, max);
    while (n > 6 && keyLength > n && keyLength % n != 0 && keyLength % n < 6) {
      n--;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final base = context.ts.mono(size: size ?? Fs.xs, color: c.text);
    final hl = base.copyWith(color: c.accentText, fontWeight: FontWeight.w600);
    final (key, rest) = splitAddress(address);
    final mark = key.length > 14 && !key.toLowerCase().startsWith('http');
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final tp = TextPainter(text: TextSpan(text: '0', style: base), textDirection: dir, textScaler: scaler, maxLines: 1)..layout();
        final glyph = tp.width;
        tp.dispose();
        final n = chunkFor(key.length, box.maxWidth - _drawSlack, glyph, chunk);
        final spans = <TextSpan>[];
        var i = 0;
        while (i < key.length) {
          // The next stop: a chunk's end or the edge of a highlighted end.
          final stops = [((i ~/ n) + 1) * n, if (mark && i < 6) 6, if (mark && i < key.length - 6) key.length - 6, key.length];
          final end = stops.reduce((a, b) => a < b ? a : b);
          final lit = mark && (i < 6 || i >= key.length - 6);
          spans.add(TextSpan(text: key.substring(i, end), style: lit ? hl : null));
          i = end;
          if (i < key.length && i % n == 0) spans.add(const TextSpan(text: '\n'));
        }
        if (rest.isNotEmpty) spans.add(TextSpan(text: rest.startsWith('@') ? '\n$rest' : rest, style: base.copyWith(color: c.dim)));
        return Semantics(
          label: address,
          excludeSemantics: true,
          child: Text.rich(TextSpan(style: base, children: spans), softWrap: true),
        );
      },
    );
  }
}

/// [address] as the part people check and the server or kind after it: `(key, @host)`,
/// `(onion label, .onion)`, or `(address, '')`.
(String, String) splitAddress(String address) {
  final at = address.indexOf('@');
  final onion = at < 0 && address.toLowerCase().endsWith('.onion');
  final cut = at > 0 ? at : (onion ? address.length - 6 : address.length);
  return (address.substring(0, cut), address.substring(cut));
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
  // clipped the last letter of the domain.
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

/// The two text lines of a row that carries an address: name, [nameTrailing] and
/// the kind tag; then the short address and the note. When the row is narrow the note gives way
/// first (down to 12 characters), then the address falls to its compact form, then the note
/// goes. Nothing wraps. A contact with several [addresses] shows its default one short, then
/// their kind tags; a row too narrow for both shows the tags alone.
class EAddressLines extends StatelessWidget {
  const EAddressLines({super.key, required this.name, required this.address, this.addresses, this.note, this.nameTrailing, this.addressStyle, this.full = false});

  /// The contact list's row (UD-029): the kind badge with its short name beside the glyph,
  /// as on the phone, and the note as a third line instead of after the address.
  final bool full;

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
            // A contact with no address (paired only) has no kind to tag.
            if (address.trim().isNotEmpty && !several) ...[SizedBox(width: Sp.x2), EKindTag(addressKindOf(address), compact: !full)],
          ],
        ),
        const SizedBox(height: 2),
        LayoutBuilder(
          builder: (context, box) {
            if (full) {
              // The address (its tags when several), then the note as its own line.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (several)
                    Row(children: [for (final a in addresses!) ...[EKindTag(addressKindOf(a), compact: false), SizedBox(width: Sp.x1)]])
                  else if (address.trim().isNotEmpty)
                    EShortAddress(address, style: aStyle),
                  if (n.isNotEmpty) ...[const SizedBox(height: 2), Text(n, style: nStyle, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis)],
                ],
              );
            }
            if (address.trim().isEmpty) return Text(n, style: nStyle, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis);
            if (several) {
              // The default address, short, before the tags when the row has room for both
              //; a narrow row keeps the tags alone.
              final tags = addresses!.length * (22.u + Sp.x1);
              final withAddress = _width(context, shortAddress(address, compact: true), aStyle) + 1 + Sp.x2 + tags <= box.maxWidth;
              return Row(
                children: [
                  if (withAddress) ...[Flexible(child: EShortAddress(address, style: aStyle)), SizedBox(width: Sp.x2)],
                  for (final a in addresses!) ...[EKindTag(addressKindOf(a), compact: true), SizedBox(width: Sp.x1)],
                  if (n.isNotEmpty) Flexible(child: Text(' · $n', style: nStyle, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis)),
                ],
              );
            }
            if (n.isEmpty) return EShortAddress(address, style: aStyle);
            final noteMin = _width(context, ' · ${n.length > 12 ? n.substring(0, 12) : n}', nStyle);
            final fullW = shortAddressWidth(context, address, aStyle);
            final compact = _width(context, shortAddress(address, compact: true), aStyle) + 1;
            final double? w = fullW + noteMin <= box.maxWidth ? fullW : (compact + noteMin <= box.maxWidth ? compact : null);
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
