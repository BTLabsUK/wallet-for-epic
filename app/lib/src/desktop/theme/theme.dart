import 'package:flutter/material.dart';

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
    iconTheme: IconThemeData(size: Ctl.iconLg),
    materialTapTargetSize: MaterialTapTargetSize.padded,
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
      thumbColor: WidgetStatePropertyAll(c.lineStrong),
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
      waitDuration: const Duration(milliseconds: 400),
    ),
    dialogTheme: DialogThemeData(backgroundColor: c.s4),
    popupMenuTheme: PopupMenuThemeData(
      color: c.s4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.sm),
        side: BorderSide(color: c.lineStrong),
      ),
    ),
  );
}
