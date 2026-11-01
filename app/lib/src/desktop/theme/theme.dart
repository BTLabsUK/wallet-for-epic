// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import '../../ui/theme/fonts.dart' show bundledFallback;
import 'tokens.dart';

/// Material mapped onto the desktop tokens, so stock widgets (scrollbars, tooltips, text
/// selection, menus) match. Desktop widgets read [DeskColors] directly.
ThemeData buildDeskTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? deskDark : deskLight;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.accentInk,
    secondary: c.accent,
    onSecondary: c.accentInk,
    error: c.risk,
    onError: c.bg,
    surface: c.s1,
    onSurface: c.text,
    surfaceContainerHighest: c.s3,
    outline: c.lineField,
    outlineVariant: c.line,
    scrim: c.scrim,
    shadow: c.shadowInk,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    dividerColor: c.line,
    splashFactory: NoSplash.splashFactory,
    hoverColor: c.hover,
    highlightColor: c.press,
    focusColor: c.accentSoft,
    visualDensity: VisualDensity.standard,
    // An icon given no colour (a select's leading icon) takes the normal icon colour, not
    // Material's black, which vanishes on the dark fields.
    iconTheme: IconThemeData(size: Ctl.iconLg, color: c.dim),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    fontFamilyFallback: bundledFallback,
    extensions: [c],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: c.text, displayColor: c.text),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accent.withValues(alpha: 0.28),
      selectionHandleColor: c.accent,
    ),
    scrollbarTheme: ScrollbarThemeData(
      // Always drawn while the content overflows (the framework hides it when it does not),
      // so a page that runs on below the window edge says so; hover and drag brighten it.
      thumbVisibility: const WidgetStatePropertyAll(true),
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.hovered) || s.contains(WidgetState.dragged) ? c.faint : c.lineField),
      thickness: const WidgetStatePropertyAll(6),
      radius: Radius.circular(6.u),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.s4,
        border: Border.all(color: c.lineStrong),
        borderRadius: BorderRadius.circular(Rad.sm),
      ),
      textStyle: TextStyle(color: c.text, fontSize: Fs.sm),
      padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
      // One look, width and timing for every tip (widgets/tip.dart), the phone's too.
      constraints: BoxConstraints(maxWidth: 320.u),
      waitDuration: const Duration(milliseconds: 400),
      showDuration: const Duration(seconds: 3),
    ),
    dialogTheme: DialogThemeData(backgroundColor: c.s4),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.line,
    ),
    // Every menu, popup or anchored, has the popover look ([DeskColors.popover]): s4, a
    // lineStrong hairline, the one soft shadow. A menu sets only its size and padding.
    popupMenuTheme: PopupMenuThemeData(
      color: c.s4,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: c.shadowInk,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.sm),
        side: BorderSide(color: c.lineStrong),
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.s4),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        padding: WidgetStatePropertyAll(EdgeInsets.all(Sp.x2)),
        elevation: const WidgetStatePropertyAll(8),
        shadowColor: WidgetStatePropertyAll(c.shadowInk),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rad.sm), side: BorderSide(color: c.lineStrong)),
        ),
      ),
    ),
  );
}

