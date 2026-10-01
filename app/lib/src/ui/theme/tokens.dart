/// The wallet's look: a token set per brightness, mapped onto Material by [buildWalletTheme].
///
/// The values come from the Protocol mockup (`docs/themes/protocol/protocol.css`), which takes
/// them from the devhub's Protocol scope system. Widgets read [WalletTokens] through
/// `context.tokens` for anything Material has no slot for.
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Every value the look may change. One instance per brightness.
@immutable
class WalletTokens extends ThemeExtension<WalletTokens> {
  const WalletTokens({
    required this.bg,
    required this.surface,
    required this.surfaceHi,
    required this.field,
    required this.line,
    required this.lineStrong,
    required this.text,
    required this.dim,
    required this.faint,
    required this.accent,
    required this.accentInk,
    required this.accentText,
    required this.accentSoft,
    required this.tick,
    required this.ok,
    required this.warn,
    required this.risk,
    required this.radius,
    required this.radiusSmall,
    required this.controlHeight,
    required this.headFamily,
    required this.monoFamily,
  });

  /// Screen background.
  final Color bg;

  /// Elevation: [surface] for panels and rows, [surfaceHi] for an object on a panel.
  final Color surface;
  final Color surfaceHi;

  /// Text field fill.
  final Color field;

  /// Hairlines: [line] separates, [lineStrong] encloses.
  final Color line;
  final Color lineStrong;

  /// Text: [text] for content, [dim] for secondary, [faint] for readouts only (below 4.5:1).
  final Color text;
  final Color dim;
  final Color faint;

  /// [accent] is a fill and the signal colour. [accentInk] is text on that fill. [accentText]
  /// is the accent used as text.
  final Color accent;
  final Color accentInk;
  final Color accentText;
  final Color accentSoft;

  /// Corner ticks on the balance panel: gold-deep in dark mode, charcoal in light.
  final Color tick;

  final Color ok;
  final Color warn;
  final Color risk;

  final double radius;
  final double radiusSmall;

  /// Height of buttons and fields.
  final double controlHeight;

  /// Display face (balance, titles, section heads) and data face (readouts, amounts in lists).
  /// Body text stays on the platform font.
  final String headFamily;
  final String monoFamily;

  @override
  WalletTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceHi,
    Color? field,
    Color? line,
    Color? lineStrong,
    Color? text,
    Color? dim,
    Color? faint,
    Color? accent,
    Color? accentInk,
    Color? accentText,
    Color? accentSoft,
    Color? tick,
    Color? ok,
    Color? warn,
    Color? risk,
    double? radius,
    double? radiusSmall,
    double? controlHeight,
    String? headFamily,
    String? monoFamily,
  }) => WalletTokens(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surfaceHi: surfaceHi ?? this.surfaceHi,
    field: field ?? this.field,
    line: line ?? this.line,
    lineStrong: lineStrong ?? this.lineStrong,
    text: text ?? this.text,
    dim: dim ?? this.dim,
    faint: faint ?? this.faint,
    accent: accent ?? this.accent,
    accentInk: accentInk ?? this.accentInk,
    accentText: accentText ?? this.accentText,
    accentSoft: accentSoft ?? this.accentSoft,
    tick: tick ?? this.tick,
    ok: ok ?? this.ok,
    warn: warn ?? this.warn,
    risk: risk ?? this.risk,
    radius: radius ?? this.radius,
    radiusSmall: radiusSmall ?? this.radiusSmall,
    controlHeight: controlHeight ?? this.controlHeight,
    headFamily: headFamily ?? this.headFamily,
    monoFamily: monoFamily ?? this.monoFamily,
  );

  @override
  WalletTokens lerp(WalletTokens? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    double d(double a, double b) => lerpDouble(a, b, t)!;
    return WalletTokens(
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surfaceHi: c(surfaceHi, other.surfaceHi),
      field: c(field, other.field),
      line: c(line, other.line),
      lineStrong: c(lineStrong, other.lineStrong),
      text: c(text, other.text),
      dim: c(dim, other.dim),
      faint: c(faint, other.faint),
      accent: c(accent, other.accent),
      accentInk: c(accentInk, other.accentInk),
      accentText: c(accentText, other.accentText),
      accentSoft: c(accentSoft, other.accentSoft),
      tick: c(tick, other.tick),
      ok: c(ok, other.ok),
      warn: c(warn, other.warn),
      risk: c(risk, other.risk),
      radius: d(radius, other.radius),
      radiusSmall: d(radiusSmall, other.radiusSmall),
      controlHeight: d(controlHeight, other.controlHeight),
      headFamily: t < 0.5 ? headFamily : other.headFamily,
      monoFamily: t < 0.5 ? monoFamily : other.monoFamily,
    );
  }
}

extension WalletTokensOf on BuildContext {
  /// The active tokens. Every theme built by [buildWalletTheme] carries them; a bare
  /// `ThemeData` (a widget test, a dialog built outside the app) gets Protocol by brightness.
  WalletTokens get tokens {
    final theme = Theme.of(this);
    return theme.extension<WalletTokens>() ??
        (theme.brightness == Brightness.dark ? protocolDark : protocolLight);
  }
}

/// Font families declared in pubspec.yaml.
const String montserrat = 'Montserrat';
const String jetBrainsMono = 'JetBrainsMonoNL';

/// Protocol, dark. From `epic-devdocs/mockups/shared.css`.
const WalletTokens protocolDark = WalletTokens(
  bg: Color(0xFF08080A),
  surface: Color(0xFF0D0D10),
  surfaceHi: Color(0xFF1A1A21),
  field: Color(0xFF131318),
  line: Color(0xFF24242A),
  lineStrong: Color(0xFF33333D),
  text: Color(0xFFFFF9F9),
  dim: Color(0xFFA4A4AD),
  faint: Color(0xFF70707A),
  accent: Color(0xFFF6D471),
  accentInk: Color(0xFF08080A),
  accentText: Color(0xFFF6D471),
  accentSoft: Color(0x24F6D471),
  tick: Color(0xFFC98A3E),
  ok: Color(0xFF8AD98A),
  warn: Color(0xFFF0C274),
  risk: Color(0xFFF08A8A),
  radius: 14,
  radiusSmall: 8,
  controlHeight: 48,
  headFamily: montserrat,
  monoFamily: jetBrainsMono,
);

/// Protocol, light. Gold becomes the devhub's AA brown, and the ticks turn charcoal.
const WalletTokens protocolLight = WalletTokens(
  bg: Color(0xFFF7F7F8),
  surface: Color(0xFFFFFFFF),
  surfaceHi: Color(0xFFEEEEF0),
  field: Color(0xFFEEEEF0),
  line: Color(0xFFE0E0E4),
  lineStrong: Color(0xFFC9C9D0),
  text: Color(0xFF1C1E21),
  dim: Color(0xFF55555F),
  faint: Color(0xFF767680),
  accent: Color(0xFF8F5E1F),
  accentInk: Color(0xFFFFFFFF),
  accentText: Color(0xFF8F5E1F),
  accentSoft: Color(0x1F8F5E1F),
  tick: Color(0xFF1C1E21),
  ok: Color(0xFF1F7A3A),
  warn: Color(0xFF8F5E1F),
  risk: Color(0xFFB3261E),
  radius: 14,
  radiusSmall: 8,
  controlHeight: 48,
  headFamily: montserrat,
  monoFamily: jetBrainsMono,
);

/// Maps tokens onto Material, so stock widgets look right without per-screen styling.
ThemeData buildWalletTheme(WalletTokens t, Brightness brightness) {
  Color over(Color tint, double alpha, Color base) =>
      Color.alphaBlend(tint.withValues(alpha: alpha), base);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: t.accent,
    onPrimary: t.accentInk,
    primaryContainer: over(t.accent, 0.14, t.surface),
    onPrimaryContainer: t.text,
    secondary: t.accentText,
    onSecondary: t.bg,
    // Notices, tonal buttons and the "confirming" chip sit one elevation step up.
    secondaryContainer: t.surfaceHi,
    onSecondaryContainer: t.text,
    tertiary: t.warn,
    onTertiary: t.bg,
    // Waiting states: a faint warm wash.
    tertiaryContainer: over(t.warn, 0.14, t.surface),
    onTertiaryContainer: t.text,
    error: t.risk,
    onError: t.bg,
    errorContainer: over(t.risk, 0.14, t.surface),
    onErrorContainer: t.text,
    surface: t.bg,
    onSurface: t.text,
    onSurfaceVariant: t.dim,
    surfaceContainerLowest: t.bg,
    surfaceContainerLow: t.surface,
    surfaceContainer: t.surface,
    surfaceContainerHigh: t.field,
    surfaceContainerHighest: t.surfaceHi,
    surfaceTint: Colors.transparent,
    outline: t.lineStrong,
    outlineVariant: t.line,
    inverseSurface: t.text,
    onInverseSurface: t.bg,
    inversePrimary: t.accent,
  );
  final base = ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: t.bg,
    canvasColor: t.bg,
  );
  final text = base.textTheme.apply(bodyColor: t.text, displayColor: t.text);
  const tabular = [FontFeature.tabularFigures()];
  TextStyle? head(TextStyle? s, {double tracking = -0.3}) => s?.copyWith(
    fontFamily: t.headFamily,
    fontWeight: FontWeight.w600,
    letterSpacing: tracking,
  );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(t.radiusSmall),
  );
  final minSize = Size(64, t.controlHeight);
  // From the text theme, so a button keeps the body font and the reader's text scale.
  final buttonText = text.labelLarge?.copyWith(fontWeight: FontWeight.w600);
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.radiusSmall),
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    extensions: [t],
    textTheme: text.copyWith(
      // The balance: Montserrat, tight, tabular.
      displaySmall: head(
        text.displaySmall,
        tracking: -0.8,
      )?.copyWith(fontFeatures: tabular),
      headlineSmall: head(text.headlineSmall, tracking: -0.5),
      titleLarge: head(text.titleLarge, tracking: -0.4),
      titleMedium: head(text.titleMedium),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: t.bg,
      foregroundColor: t.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: head(
        text.titleLarge,
        tracking: -0.4,
      )?.copyWith(color: t.text, fontSize: 19),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minSize,
        shape: shape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.text,
        side: BorderSide(color: t.lineStrong),
        minimumSize: minSize,
        shape: shape,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.accentText,
        textStyle: buttonText,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: shape,
        minimumSize: const Size(48, 48),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.field,
      border: border(t.line),
      enabledBorder: border(t.line),
      focusedBorder: border(t.accent, 1.5),
      errorBorder: border(t.risk),
      focusedErrorBorder: border(t.risk, 1.5),
      disabledBorder: border(t.line),
      hintStyle: TextStyle(color: t.faint),
    ),
    cardTheme: CardThemeData(
      color: t.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusSmall),
        side: BorderSide(color: t.line),
      ),
    ),
    listTileTheme: ListTileThemeData(iconColor: t.dim, textColor: t.text),
    dividerTheme: DividerThemeData(color: t.line, thickness: 1, space: 1),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.accentInk : t.dim,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.accent : t.field,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.accent : t.lineStrong,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: t.field,
        foregroundColor: t.dim,
        selectedBackgroundColor: t.surfaceHi,
        selectedForegroundColor: t.accentText,
        side: BorderSide(color: t.line),
        shape: shape,
      ),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: t.lineStrong),
      selectedColor: t.accentSoft,
      shape: shape,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.field,
      modalBackgroundColor: t.field,
      dragHandleColor: t.lineStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(t.radius)),
        side: BorderSide(color: t.lineStrong),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.field,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radius),
        side: BorderSide(color: t.lineStrong),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.text,
      contentTextStyle: TextStyle(color: t.bg),
      actionTextColor: t.bg,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.accent,
      linearTrackColor: t.line,
      circularTrackColor: t.line,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: t.text,
        borderRadius: BorderRadius.circular(t.radiusSmall),
      ),
      textStyle: TextStyle(color: t.bg),
    ),
  );
}
