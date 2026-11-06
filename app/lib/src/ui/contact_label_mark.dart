// SPDX-License-Identifier: Apache-2.0
/// The contact label as a small mark in the avatar's bottom-right corner. Display only
/// except where [onTap] is given (the contact page and the desktop details), where the mark
/// opens the label picker. The label is local to this wallet's user: it is drawn here and
/// nowhere else.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../contact_label.dart';
import '../l10n.dart';
import 'theme/tokens.dart';
import 'tip.dart';

/// The rounded-line glyphs (24 px grid, 1.5 px stroke): a wallet, opposing arrows, a
/// storefront, stacked servers.
/// The tappable mark, for tests and the screenshot tour.
const Key contactLabelMarkKey = ValueKey('contact-label-mark');

const _glyphs = <ContactLabel, String>{
  ContactLabel.wallet:
      '<path d="M4 7.5h14.5A1.5 1.5 0 0 1 20 9v8.5a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 17.5z"/><path d="M4 7.5V6.3A1.3 1.3 0 0 1 5.3 5H16.5"/><path d="M15 11.5h5v4h-5a2 2 0 0 1 0-4z"/>',
  ContactLabel.exchange:
      '<path d="M4 8h15"/><path d="M15.5 4.5 19 8l-3.5 3.5"/><path d="M20 16H5"/><path d="M8.5 12.5 5 16l3.5 3.5"/>',
  ContactLabel.vendor:
      '<path d="M4.5 9 6 4.5h12L19.5 9"/><path d="M3.5 9a2.1 2.1 0 0 0 4.25 0 2.1 2.1 0 0 0 4.25 0 2.1 2.1 0 0 0 4.25 0 2.1 2.1 0 0 0 4.25 0"/><path d="M5.5 11.5v8h13v-8"/><path d="M10 19.5v-4.5h4v4.5"/>',
  ContactLabel.service:
      '<rect x="4" y="4.5" width="16" height="6" rx="1.5"/><rect x="4" y="13.5" width="16" height="6" rx="1.5"/><path d="M7.5 7.5h.01M7.5 16.5h.01"/>',
};

String _svg(ContactLabel label) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" '
    'stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">${_glyphs[label]}</svg>';

/// The label's name as the user reads it.
String contactLabelName(AppLocalizations l, ContactLabel label) => switch (label) {
  ContactLabel.wallet => l.deskConLabelWallet,
  ContactLabel.exchange => l.deskConLabelExchange,
  ContactLabel.vendor => l.deskConLabelVendor,
  ContactLabel.service => l.deskConLabelService,
};

/// The tooltip and screen-reader name of the mark: the label's name, and for the default the
/// "Label: Just a wallet" that says what the faint mark is for.
String contactLabelMarkText(AppLocalizations l, ContactLabel label) =>
    label == ContactLabel.wallet ? l.deskConLabelCurrent(contactLabelName(l, label)) : contactLabelName(l, label);

/// A label's glyph alone, in [color].
class ContactLabelGlyph extends StatelessWidget {
  const ContactLabelGlyph(this.label, {super.key, required this.size, required this.color});

  final ContactLabel label;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SvgPicture.string(
    _svg(label),
    width: size,
    height: size,
    theme: SvgTheme(currentColor: color),
  );
}

/// The avatar corner mark's side for an avatar of [avatar] px.
double contactLabelMarkSize(double avatar) => avatar * 0.4 < 18 ? 18 : avatar * 0.4;

/// How far the mark sticks out past the avatar's corner.
double contactLabelMarkOverhang(double avatar) => avatar * 0.1;

/// The mark: a small tile with the label's glyph. The default label draws in the faint colour
/// (it is shown only where it can be tapped).
class ContactLabelMark extends StatelessWidget {
  const ContactLabelMark({super.key, required this.label, required this.avatar});

  final ContactLabel label;
  final double avatar;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final side = contactLabelMarkSize(avatar);
    final faint = label == ContactLabel.wallet;
    return Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.surfaceHi,
        border: Border.all(color: faint ? t.line : t.lineStrong),
        borderRadius: BorderRadius.circular(avatar * 0.09),
        // The ring in the page colour parts the mark from the avatar's corner tick.
        boxShadow: [BoxShadow(color: t.bg, spreadRadius: 2)],
      ),
      child: ContactLabelGlyph(label, size: side * 0.72, color: faint ? t.faint : t.dim),
    );
  }
}

/// [avatar] (the tile) with the label mark at its bottom-right corner. With [onTap] the mark
/// is a button whose hit area is [hit] px, and the widget is larger by the part of that area
/// that lies past the avatar; without it the mark is drawn and the layout is the avatar's own.
class AvatarLabelMark extends StatelessWidget {
  const AvatarLabelMark({
    super.key,
    required this.avatar,
    required this.size,
    required this.label,
    this.onTap,
    this.hit = 48,
    this.tip,
  });

  final Widget avatar;
  final double size;
  final ContactLabel label;
  final VoidCallback? onTap;
  final double hit;

  /// Wraps the mark to name it on hover or long press; the phone's `Tip` by default.
  final Widget Function(String message, Widget child)? tip;

  @override
  Widget build(BuildContext context) {
    final onTap = this.onTap;
    // Nothing to draw: the default label in a list or a header.
    if (label == ContactLabel.wallet && onTap == null) return avatar;
    // The mark sits in every contact header: where no localizations are installed (a bare
    // test host) it names itself in English instead of throwing.
    final l = Localizations.of<AppLocalizations>(context, AppLocalizations) ?? lookupAppLocalizations(const Locale('en'));
    final text = contactLabelMarkText(l, label);
    final side = contactLabelMarkSize(size);
    final over = contactLabelMarkOverhang(size);
    final mark = ContactLabelMark(label: label, avatar: size);
    if (onTap == null) {
      return Semantics(
        label: text,
        container: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            Positioned(right: -over, bottom: -over, child: mark),
          ],
        ),
      );
    }
    // The mark's centre is (side / 2 - over) inside the avatar's corner; the hit box is
    // centred on it and stays inside this widget's own bounds so that it receives the tap.
    final centre = size + over - side / 2;
    final box = hit < side ? side : hit;
    final total = centre + box / 2 > size ? centre + box / 2 : size;
    Widget button = Semantics(
      button: true,
      label: text,
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          key: contactLabelMarkKey,
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(width: box, height: box, child: Center(child: mark)),
        ),
      ),
    );
    button = (tip ?? _phoneTip)(text, button);
    return SizedBox(
      width: total,
      height: total,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, top: 0, child: avatar),
          Positioned(left: centre - box / 2, top: centre - box / 2, child: button),
        ],
      ),
    );
  }
}

Widget _phoneTip(String message, Widget child) => Tip(message, excludeFromSemantics: true, child: child);
