// SPDX-License-Identifier: Apache-2.0
/// The wallet's look: a token set per brightness, mapped onto Material by [buildWalletTheme].
///
/// The values come from the Protocol design system's scope colours. Widgets read [WalletTokens] through
/// `context.tokens` for anything Material has no slot for.
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'fonts.dart' show phoneFontFallback;
import 'palette.dart';

/// Every value the look may change. One instance per brightness.
@immutable
class WalletTokens extends ThemeExtension<WalletTokens> {
  const WalletTokens({
    required this.bg,
    required this.surface,
    required this.surfaceHi,
    required this.raised,
    required this.field,
    required this.line,
    required this.lineStrong,
    required this.lineField,
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
    required this.scrim,
    required this.shadow,
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

  /// Dialogs, sheets' menus, popup menus and tooltips: the desktop's `s4`.
  final Color raised;

  /// Text field fill: a white well in light, as on the desktop, so a field reads by its
  /// [lineField] edge.
  final Color field;

  /// Hairlines: [line] separates, [lineStrong] encloses.
  final Color line;
  final Color lineStrong;

  /// The edge of a text field: 3:1 against the field, which [lineStrong] is not.
  final Color lineField;

  /// Text: [text] for content, [dim] for secondary, [faint] for hints and readouts (at least 4.5:1).
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
  /// (Activity, recent activity, details, outputs, invoices, notices). the rule
  /// (26.10.18, after 26.10.8's gold): sent is red, received is green, cancelled is a neutral
  /// grey, so a list reads like a ledger at a glance. [txSent] is money out, not a problem:
  /// a vivid red apart from the softer [risk], which stays for errors and failures, and
  /// never the brand gold. States keep their own colours: confirming is [info], failed or
  /// stalled is [warn] or [risk]. Each is AA on every surface, like [ok].
  final Color txSent;
  final Color txReceived;
  final Color txCancelled;

  /// The barrier behind a dialog. Never a shadow: at its strength a shadow turns into a band.
  final Color scrim;

  /// The one soft shadow under a floating surface (a menu, a popover, the tour card), drawn
  /// with [popShadow] next to a [lineStrong] border.
  final Color shadow;

  final double radius;
  final double radiusSmall;

  /// Height of buttons and fields.
  final double controlHeight;

  /// Display face (balance, titles, section heads) and data face (readouts, amounts in lists).
  /// Body text stays on the platform font.
  final String headFamily;
  final String monoFamily;

  /// The shadow under a floating surface: soft and low, one for every popover and menu.
  List<BoxShadow> get popShadow => [BoxShadow(color: shadow, blurRadius: 24, offset: const Offset(0, 8))];

  /// [shadow] at full strength, for a Material `shadowColor` (menus that draw their own
  /// elevation): Material thins it to the same soft shadow.
  Color get shadowInk => shadow.withValues(alpha: 1);

  /// A read-only box of text inside a panel, a sheet or a dialog (a commitment, a code's text,
  /// the payee's note): the field fill with a hairline on every side, so it shows in both
  /// themes. The desktop's `DeskColors.well` is the same.
  BoxDecoration get well => BoxDecoration(
    color: field,
    border: Border.all(color: line),
    borderRadius: BorderRadius.circular(radiusSmall),
  );

  @override
  WalletTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceHi,
    Color? raised,
    Color? field,
    Color? line,
    Color? lineStrong,
    Color? lineField,
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
    Color? scrim,
    Color? shadow,
    double? radius,
    double? radiusSmall,
    double? controlHeight,
    String? headFamily,
    String? monoFamily,
  }) => WalletTokens(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surfaceHi: surfaceHi ?? this.surfaceHi,
    raised: raised ?? this.raised,
    field: field ?? this.field,
    line: line ?? this.line,
    lineStrong: lineStrong ?? this.lineStrong,
    lineField: lineField ?? this.lineField,
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
    scrim: scrim ?? this.scrim,
    shadow: shadow ?? this.shadow,
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
      raised: c(raised, other.raised),
      field: c(field, other.field),
      line: c(line, other.line),
      lineStrong: c(lineStrong, other.lineStrong),
      lineField: c(lineField, other.lineField),
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
      scrim: c(scrim, other.scrim),
      shadow: c(shadow, other.shadow),
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

/// Protocol, dark, from the shared palette (`palette.dart`), as the desktop's.
const WalletTokens protocolDark = WalletTokens(
  bg: PaletteDark.bg,
  surface: PaletteDark.s1,
  surfaceHi: PaletteDark.s3,
  raised: PaletteDark.s4,
  field: PaletteDark.s2,
  line: PaletteDark.line,
  lineStrong: PaletteDark.lineStrong,
  lineField: PaletteDark.lineField,
  text: PaletteDark.text,
  dim: PaletteDark.dim,
  faint: PaletteDark.faint,
  accent: PaletteDark.accent,
  accentInk: PaletteDark.accentInk,
  accentText: PaletteDark.accentText,
  accentSoft: PaletteDark.accentSoft,
  tick: PaletteDark.tick,
  ok: PaletteDark.ok,
  okSoft: PaletteDark.okSoft,
  warn: PaletteDark.warn,
  warnSoft: PaletteDark.warnSoft,
  risk: PaletteDark.risk,
  riskSoft: PaletteDark.riskSoft,
  info: PaletteDark.info,
  infoSoft: PaletteDark.infoSoft,
  selected: PaletteDark.selected,
  selectedLine: PaletteDark.selectedLine,
  txSent: PaletteDark.txSent,
  txReceived: PaletteDark.txReceived,
  txCancelled: PaletteDark.txCancelled,
  scrim: PaletteDark.scrim,
  shadow: PaletteDark.shadow,
  radius: 14,
  radiusSmall: 8,
  controlHeight: 48,
  headFamily: montserrat,
  monoFamily: jetBrainsMono,
);

/// Protocol, light, from the shared palette: gold an AA brown, amber a burnt orange, the
/// ticks charcoal, fields white.
const WalletTokens protocolLight = WalletTokens(
  bg: PaletteLight.bg,
  surface: PaletteLight.s1,
  surfaceHi: PaletteLight.s3,
  raised: PaletteLight.s4,
  field: PaletteLight.s2,
  line: PaletteLight.line,
  lineStrong: PaletteLight.lineStrong,
  lineField: PaletteLight.lineField,
  text: PaletteLight.text,
  dim: PaletteLight.dim,
  faint: PaletteLight.faint,
  accent: PaletteLight.accent,
  accentInk: PaletteLight.accentInk,
  accentText: PaletteLight.accentText,
  accentSoft: PaletteLight.accentSoft,
  tick: PaletteLight.tick,
  ok: PaletteLight.ok,
  okSoft: PaletteLight.okSoft,
  warn: PaletteLight.warn,
  warnSoft: PaletteLight.warnSoft,
  risk: PaletteLight.risk,
  riskSoft: PaletteLight.riskSoft,
  info: PaletteLight.info,
  infoSoft: PaletteLight.infoSoft,
  selected: PaletteLight.selected,
  selectedLine: PaletteLight.selectedLine,
  txSent: PaletteLight.txSent,
  txReceived: PaletteLight.txReceived,
  txCancelled: PaletteLight.txCancelled,
  scrim: PaletteLight.scrim,
  shadow: PaletteLight.shadow,
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
    scrim: t.scrim,
    shadow: t.shadowInk,
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
      border: border(t.lineField),
      enabledBorder: border(t.lineField),
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
        color: t.raised,
        border: Border.all(color: t.lineStrong),
        borderRadius: BorderRadius.circular(t.radiusSmall),
      ),
      textStyle: TextStyle(color: t.text, fontSize: 13, height: 1.4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      // One look, width and timing for every tip (ui/tip.dart): a name, never a paragraph.
      constraints: const BoxConstraints(maxWidth: 280),
      waitDuration: const Duration(milliseconds: 400),
      showDuration: const Duration(seconds: 3),
    ),
    // Every popup menu: the desktop's menu look (raised fill, lineStrong edge, soft shadow).
    popupMenuTheme: PopupMenuThemeData(
      color: t.raised,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: t.shadowInk,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusSmall),
        side: BorderSide(color: t.lineStrong),
      ),
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
    // A row's subtitle (a setting's value: "Dark", "After 15 minutes") is secondary: dim, set
    // here once. The title keeps the text colour.
    listTileTheme: ListTileThemeData(
      iconColor: t.dim,
      subtitleTextStyle: text.bodyMedium?.copyWith(color: t.dim),
    ),
    dividerTheme: DividerThemeData(color: t.line, thickness: 1, space: 1),
    // A disabled switch fades to 40%, as the desktop's ESwitch: a locked one never looks live.
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => _switchFade(s, s.contains(WidgetState.selected) ? t.accentInk : t.dim),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => _switchFade(s, s.contains(WidgetState.selected) ? t.accent : t.field),
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => _switchFade(s, s.contains(WidgetState.selected) ? t.accent : t.lineStrong),
      ),
    ),
    // A selected radio is neutral: gold is the brand and the primary action only.
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.text : t.dim,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: t.field,
        foregroundColor: t.dim,
        // A selection is neutral: gold is the brand and the primary action only.
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
    // Every bar and spinner takes the app's accent; none stays stock.
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.accent,
      refreshBackgroundColor: t.surface,
      linearTrackColor: t.line,
      circularTrackColor: t.line,
    ),
  );
}


/// [color] at 40% while the switch is disabled.
Color _switchFade(Set<WidgetState> states, Color color) =>
    states.contains(WidgetState.disabled) ? color.withValues(alpha: 0.4) : color;
