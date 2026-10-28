/// The wallet's look: a token set per brightness, mapped onto Material by [buildWalletTheme].
///
/// The values come from the Protocol mockup (`docs/themes/protocol/protocol.css`), which takes
/// them from the devhub's Protocol scope system. Widgets read [WalletTokens] through
/// `context.tokens` for anything Material has no slot for.
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'fonts.dart' show phoneFontFallback;

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
    required this.okSoft,
    required this.warn,
    required this.warnSoft,
    required this.risk,
    required this.riskSoft,
    required this.info,
    required this.infoSoft,
    required this.selected,
    required this.selectedLine,
    required this.txSent,
    required this.txReceived,
    required this.txCancelled,
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

  /// The brand gold: primary buttons, the FAB, focused borders, links as [accentText], the
  /// mark and section rules. Never a state: a connected, synced, selected or confirmed thing is
  /// [ok], [selected] or [info], not gold. [accentInk] is text on an [accent] fill.
  final Color accent;
  final Color accentInk;
  final Color accentText;
  final Color accentSoft;

  /// Corner ticks on the balance panel: gold-deep in dark mode, charcoal in light.
  final Color tick;

  /// Status colours, each AA as text on [bg], [surface], [surfaceHi], [field] and [selected].
  /// [ok] (green): connected, synced, confirmed, success notices, and the
  /// check on a current item that is working. [warn] (amber): something needs attention or is
  /// not ready. [risk] (red): an error or a failure. [info] (blue): an in-progress or
  /// informational state (confirming, the current timeline step, an info notice). The `Soft`
  /// twins are translucent fills behind that colour's icon or text.
  final Color ok;
  final Color okSoft;
  final Color warn;
  final Color warnSoft;
  final Color risk;
  final Color riskSoft;
  final Color info;
  final Color infoSoft;

  /// The current or selected item in a list or picker: a neutral fill and outline, never the
  /// accent, so being chosen does not read as a warning. Add an [ok] check only when the item
  /// is also working.
  final Color selected;
  final Color selectedLine;

  /// A transaction's direction, on its arrow, icon and amount wherever a payment shows
  /// (Activity, recent activity, details, outputs, invoices, notices). the owner's rule
  /// (26.10.18, after 26.10.8's gold): sent is red, received is green, cancelled is a neutral
  /// grey, so a list reads like a ledger at a glance. [txSent] is money out, not a problem:
  /// a vivid red apart from the softer [risk], which stays for errors and failures, and
  /// never the brand gold. States keep their own colours: confirming is [info], failed or
  /// stalled is [warn] or [risk]. Each is AA on every surface, like [ok].
  final Color txSent;
  final Color txReceived;
  final Color txCancelled;

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
    Color? okSoft,
    Color? warn,
    Color? warnSoft,
    Color? risk,
    Color? riskSoft,
    Color? info,
    Color? infoSoft,
    Color? selected,
    Color? selectedLine,
    Color? txSent,
    Color? txReceived,
    Color? txCancelled,
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
    okSoft: okSoft ?? this.okSoft,
    warn: warn ?? this.warn,
    warnSoft: warnSoft ?? this.warnSoft,
    risk: risk ?? this.risk,
    riskSoft: riskSoft ?? this.riskSoft,
    info: info ?? this.info,
    infoSoft: infoSoft ?? this.infoSoft,
    selected: selected ?? this.selected,
    selectedLine: selectedLine ?? this.selectedLine,
    txSent: txSent ?? this.txSent,
    txReceived: txReceived ?? this.txReceived,
    txCancelled: txCancelled ?? this.txCancelled,
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
      okSoft: c(okSoft, other.okSoft),
      warn: c(warn, other.warn),
      warnSoft: c(warnSoft, other.warnSoft),
      risk: c(risk, other.risk),
      riskSoft: c(riskSoft, other.riskSoft),
      info: c(info, other.info),
      infoSoft: c(infoSoft, other.infoSoft),
      selected: c(selected, other.selected),
      selectedLine: c(selectedLine, other.selectedLine),
      txSent: c(txSent, other.txSent),
      txReceived: c(txReceived, other.txReceived),
      txCancelled: c(txCancelled, other.txCancelled),
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

/// Protocol, dark. From `epic-devdocs/mockups/shared.css`; the status set (amber apart from the
/// gold, a blue for in-progress states, a neutral selection) is the wallet's own.
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
  okSoft: Color(0x1F8AD98A),
  warn: Color(0xFFF5A54A),
  warnSoft: Color(0x1FF5A54A),
  risk: Color(0xFFF08A8A),
  riskSoft: Color(0x1FF08A8A),
  info: Color(0xFF8FB8E8),
  infoSoft: Color(0x1F8FB8E8),
  selected: Color(0xFF22222B),
  selectedLine: Color(0xFF4A4A56),
  txSent: Color(0xFFF3645F),
  txReceived: Color(0xFF8AD98A),
  txCancelled: Color(0xFFA4A4AD),
  radius: 14,
  radiusSmall: 8,
  controlHeight: 48,
  headFamily: montserrat,
  monoFamily: jetBrainsMono,
);

/// Protocol, light. Gold becomes the devhub's AA brown, amber a burnt orange, and the ticks
/// turn charcoal.
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
  okSoft: Color(0x1A1F7A3A),
  warn: Color(0xFF9C4A00),
  warnSoft: Color(0x1A9C4A00),
  risk: Color(0xFFB3261E),
  riskSoft: Color(0x1AB3261E),
  info: Color(0xFF2F5F9E),
  infoSoft: Color(0x1A2F5F9E),
  selected: Color(0xFFECECEF),
  selectedLine: Color(0xFFB4B4BD),
  txSent: Color(0xFFC41E3A),
  txReceived: Color(0xFF1F7A3A),
  txCancelled: Color(0xFF55555F),
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
    fontFamilyFallback: phoneFontFallback,
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
    // The one floating action (Add contact) is a primary action, so it takes the accent fill.
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: t.accent,
      foregroundColor: t.accentInk,
      elevation: 0,
      highlightElevation: 0,
      shape: shape,
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
    // Every tooltip (the eye, the status icons, the info hints): a dark card from the palette,
    // never Material's light default.
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: t.surfaceHi,
        border: Border.all(color: t.lineStrong),
        borderRadius: BorderRadius.circular(t.radiusSmall),
      ),
      textStyle: TextStyle(color: t.text, fontSize: 13, height: 1.4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      waitDuration: const Duration(milliseconds: 400),
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
        // A selection is neutral: gold is the brand and the primary action only (UI-011).
        selectedBackgroundColor: t.selected,
        selectedForegroundColor: t.text,
        side: BorderSide(color: t.line),
        shape: shape,
      ),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: t.lineStrong),
      selectedColor: t.selected,
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
    // Progress is work in progress: the blue, never the gold (UI-062).
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.info,
      linearTrackColor: t.line,
      circularTrackColor: t.line,
    ),
  );
}

