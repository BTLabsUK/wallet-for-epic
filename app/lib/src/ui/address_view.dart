// SPDX-License-Identifier: Apache-2.0
/// The phone's addresses and hosts, by address_format.dart's rules (the desktop's twins are
/// `EAddress`, `EFullAddress` and `EShortAddress`): always the mono face; in full the parts a
/// reader checks in the accent ([MarkedAddress]); in a row one line, shortened
/// ([ShortAddressText]); a server's host:port whole on one line ([HostText]). Nothing here
/// copies: the screen's copy control copies the address as it was given.
library;

import 'package:flutter/material.dart';

import '../address_format.dart' hide shortAddress;
import 'common.dart' show shortAddress;
import 'theme/tokens.dart';

/// An address in full, never cut: an Epicbox key's (or an onion name's) first and last six
/// characters and a link's host:port in the accent, the rest of a key in [style]'s colour (the
/// text colour by default), the scheme, a path and `@server` dim. An Epicbox server is on its
/// own line, shrunk rather than broken inside its name; a link breaks only before its path, its
/// host:port shrunk rather than broken. [selectable] for a long press (the text is then exactly
/// the address shown); [onTap] on a tap.
class MarkedAddress extends StatelessWidget {
  const MarkedAddress(
    this.address, {
    super.key,
    this.style,
    this.selectable = false,
    this.onTap,
    this.center = false,
  });

  final String address;

  /// The size and colour of the key; the face is always mono. bodyMedium by default.
  final TextStyle? style;
  final bool selectable;
  final VoidCallback? onTap;

  /// Each line centred (the share picture).
  final bool center;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final base = (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
        .merge(style)
        .copyWith(fontFamily: t.monoFamily, color: style?.color ?? t.text);
    final mark = TextStyle(color: t.accentText, fontWeight: FontWeight.w600);
    final quiet = TextStyle(color: t.dim, fontWeight: FontWeight.w400);
    final align = center ? TextAlign.center : TextAlign.start;
    final lines = addressLines(addressParts(address));
    if (lines.isEmpty) return const SizedBox.shrink();

    Widget line(List<AddressPart> parts) {
      // Only whole parts (an `@server`, a scheme and host:port): one line, shrunk to fit.
      if (parts.every((p) => p.whole)) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: center ? Alignment.center : AlignmentDirectional.centerStart,
          child: Text.rich(
            addressPartsSpan(parts, style: base, mark: mark, plain: base, quiet: quiet),
            maxLines: 1,
            softWrap: false,
          ),
        );
      }
      // A key wraps anywhere. The text is exactly the address (no joiners), so what a reader
      // or a finder sees is what is shown.
      final span = addressPartsSpan(parts, style: base, mark: mark, plain: base, quiet: quiet);
      return selectable
          ? SelectableText.rich(span, onTap: onTap, textAlign: align)
          : Text.rich(span, textAlign: align);
    }

    Widget column() => lines.length == 1
        ? line(lines.single)
        : Column(
            crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [for (final l in lines) line(l)],
          );
    // An Epicbox server always has its own line; a link's path stays beside its host when the
    // whole link fits on one line.
    final link = lines.length > 1 && !lines.last.first.text.startsWith('@');
    final body = !link
        ? column()
        : LayoutBuilder(
            builder: (context, box) {
              final parts = lines.expand((l) => l).toList();
              final tp = TextPainter(
                text: addressPartsSpan(parts, style: base, mark: mark, quiet: quiet),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                maxLines: 1,
              )..layout();
              final fits = !box.maxWidth.isFinite || tp.width <= box.maxWidth;
              tp.dispose();
              return fits ? line([for (final p in parts) AddressPart(p.text, p.tone, whole: true)]) : column();
            },
          );
    if (selectable) return body;
    final shown = Semantics(label: address, excludeSemantics: true, child: body);
    return onTap == null ? shown : GestureDetector(onTap: onTap, child: shown);
  }
}

/// An address in a row: its short form ([shortAddress], with [ownServer] and [relay] as there)
/// on one line in the mono face, the key in [style]'s colour and `@server` dim, shrunk rather
/// than cut; the whole address for a screen reader.
class ShortAddressText extends StatelessWidget {
  const ShortAddressText(this.address, {super.key, this.style, this.ownServer, this.relay = true});

  final String address;
  final TextStyle? style;
  final String? ownServer;
  final bool relay;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final base = (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
        .merge(style)
        .copyWith(fontFamily: t.monoFamily, color: style?.color ?? t.text);
    final shown = shortAddress(address, ownServer: ownServer, relay: relay);
    final at = shown.indexOf('@');
    return Semantics(
      label: address,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text.rich(
          TextSpan(
            style: base,
            children: [
              TextSpan(text: at < 0 ? shown : shown.substring(0, at)),
              if (at >= 0) TextSpan(text: shown.substring(at), style: TextStyle(color: t.dim)),
            ],
          ),
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }
}

/// A server's host or host:port ([hostPort] for a URL) on one line in the mono face, shrunk
/// rather than cut or broken inside the name.
class HostText extends StatelessWidget {
  const HostText(this.host, {super.key, this.style});

  final String host;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final st = (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
        .merge(style)
        .copyWith(fontFamily: t.monoFamily, color: style?.color ?? t.text);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(host, style: st, maxLines: 1, softWrap: false),
    );
  }
}
