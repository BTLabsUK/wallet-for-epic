// SPDX-License-Identifier: Apache-2.0
/// The app in a browser window wider than a phone: a phone-sized frame in the middle of the
/// page, so screens laid out for a phone keep their proportions instead of stretching across a
/// desktop. A phone's own browser, and every native build, get the whole screen.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'theme/tokens.dart';

/// The frame at its largest, in logical pixels: a 412 × 915 phone, the size the tour checks.
const Size phoneFrameSize = Size(412, 915);

/// Windows narrower than this are phones themselves, and get no frame.
const double phoneFrameBreakpoint = 600;

/// Space kept around the frame. A window too short to keep it gives the frame its full height.
const double phoneFrameMargin = 24;

/// The smallest frame height worth the margin; below it the frame takes the window's height.
const double _minFramedHeight = 560;

/// Puts [child], the app's navigator, in a phone-sized frame when [enabled] and the window is
/// at least [phoneFrameBreakpoint] wide. The child's `MediaQuery` then reports the frame's size,
/// so every route, dialog, sheet and tooltip lays out as on a phone.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child, this.enabled = kIsWeb});

  final Widget child;

  /// The web only by default; tests set it.
  final bool enabled;

  /// The frame for [window], or null when the window gets no frame.
  static Size? frameFor(Size window) {
    if (window.width < phoneFrameBreakpoint) return null;
    final roomy = window.height - 2 * phoneFrameMargin;
    final height = roomy >= _minFramedHeight
        ? math.min(roomy, phoneFrameSize.height)
        : window.height;
    return Size(phoneFrameSize.width, height);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final frame = enabled ? frameFor(media.size) : null;
    if (frame == null) return child;
    final t = context.tokens;
    return ColoredBox(
      // A shade apart from the app's own background, so the phone's edge reads in both themes.
      color: Color.alphaBlend(t.text.withValues(alpha: 0.06), t.bg),
      child: Center(
        child: Container(
          key: const ValueKey('phone-frame'),
          width: frame.width,
          height: frame.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: t.lineStrong),
            boxShadow: [
              BoxShadow(
                color: t.text.withValues(alpha: 0.18),
                blurRadius: 48,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: MediaQuery(
            // A desktop window has no notch or soft keyboard; the frame is the whole screen.
            data: media.copyWith(
              size: frame,
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
