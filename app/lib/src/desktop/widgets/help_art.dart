// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';

/// A Help illustration (`assets/help/<name>.svg`, 160 × 96), drawn in the theme's colours: the
/// strokes in dim, the one thing that matters in accent, the one fill in the surface colour.
class HelpArt extends StatelessWidget {
  const HelpArt(this.name, {super.key, required this.width});

  /// help-start, help-how, help-safety, help-network, help-trouble, help-maintenance or help-support.
  final String name;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: width * 96 / 160,
        child: SvgPicture(SvgAssetLoader('assets/help/$name.svg', colorMapper: _HelpColors(dim: c.dim, accent: c.accent, fill: c.s1))),
      ),
    );
  }
}

/// The drawings' three colours to the theme's.
class _HelpColors extends ColorMapper {
  const _HelpColors({required this.dim, required this.accent, required this.fill});

  final Color dim, accent, fill;

  static const _dim = Color(0xFFA4A4AD), _accent = Color(0xFFF6D471), _fill = Color(0xFF0D0D10);

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) => switch (color) {
    _dim => dim,
    _accent => accent,
    _fill => fill,
    _ => color,
  };

  @override
  bool operator ==(Object other) => other is _HelpColors && other.dim == dim && other.accent == accent && other.fill == fill;

  @override
  int get hashCode => Object.hash(dim, accent, fill);
}
