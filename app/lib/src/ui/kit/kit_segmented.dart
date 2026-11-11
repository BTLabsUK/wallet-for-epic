// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// One choice of a [KitSegmented].
class KitSegment<T> {
  const KitSegment({required this.value, required this.label, this.semanticsId});

  final T value;
  final String label;
  final String? semanticsId;
}

/// A short row of exclusive choices (the Activity filter): a quiet track, the chosen segment a
/// raised pill, in the frame's 38 px track. Each segment reads as a button, the chosen one as
/// selected, to a screen reader.
class KitSegmented<T> extends StatelessWidget {
  const KitSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.margin = const EdgeInsets.symmetric(horizontal: Kit.gutter),
  });

  final List<KitSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final EdgeInsetsGeometry margin;

  static const double _pad = 3;
  static const double _hit = 48;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: margin,
      child: Container(
        height: Kit.segmented,
        padding: const EdgeInsets.all(_pad),
        decoration: BoxDecoration(color: t.fill, borderRadius: BorderRadius.circular(Kit.rSegmented)),
        child: Row(
          children: [
            for (final s in segments)
              Expanded(
                // The pill is 32 tall inside the 38 track; the touch target is 48.
                child: OverflowBox(
                  minHeight: _hit,
                  maxHeight: _hit,
                  child: kitId(
                    s.semanticsId,
                    Semantics(
                      button: true,
                      selected: s.value == value,
                      excludeSemantics: true,
                      label: s.label,
                      onTap: () => onChanged(s.value),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(s.value),
                        child: Center(
                          child: Container(
                            height: Kit.segmented - 2 * _pad,
                            alignment: Alignment.center,
                            decoration: s.value == value
                                ? BoxDecoration(
                                    color: t.raised,
                                    borderRadius: BorderRadius.circular(Kit.rSegment),
                                    boxShadow: [BoxShadow(color: t.bg.withValues(alpha: 0.4), blurRadius: 2, offset: const Offset(0, 1))],
                                  )
                                : null,
                            child: Text(
                              s.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: KitType.pill.copyWith(fontSize: 13.5, color: s.value == value ? t.text : t.dim),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
