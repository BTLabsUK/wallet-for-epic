// SPDX-License-Identifier: Apache-2.0
/// The one dialog anatomy, shared by the desktop's `EDialog` and the phone's `AppDialog`
/// (the owner, 2026-11-01): a 40 px icon tile, the title beside it, the body indented to the
/// title's column, and a footer of outlined secondaries and one filled primary of the same
/// height, right-aligned, the primary (or the destructive action) last. Gold is only the
/// affirmative action; a destructive one is the outlined risk style.
///
/// The numbers are logical pixels before the desktop's interface scale: the desktop reads them
/// through `.u`, the phone as they are. The button height is each platform's own control
/// height (desktop `Ctl.md`, phone `WalletTokens.controlHeight`), as on its pages.
library;

/// The dialog widths. Two, never one per dialog.
enum DialogWidth {
  /// Confirms, questions and short forms.
  standard,

  /// Tables, logs, lists of choices and the payment review.
  wide,
}

abstract final class DialogMetrics {
  /// The icon tile left of the title, and the glyph in it.
  static const double iconTile = 40;
  static const double icon = 20;

  /// Between the tile and the title.
  static const double titleGap = 12;

  /// Between the title and its one-line description.
  static const double descriptionGap = 6;

  /// The dialog's inner padding, every side.
  static const double pad = 24;

  /// Between the header and the body, and between the body and the footer.
  static const double bodyGap = 20;

  /// The body's (and a pinned foot's) start: the title's column.
  static const double bodyIndent = iconTile + titleGap;

  /// Between footer buttons, side by side and stacked.
  static const double actionGap = 12;
  static const double actionRunGap = 8;

  /// A checkbox row in a dialog's body: the box, the gap to its label (body text) and the
  /// row's least height (a 44 px touch target).
  static const double checkBox = 20;
  static const double checkGap = 12;
  static const double checkRow = 44;

  /// The widths before scaling.
  static const double standardWidth = 520;
  static const double wideWidth = 640;

  static double widthOf(DialogWidth w) => switch (w) {
    DialogWidth.standard => standardWidth,
    DialogWidth.wide => wideWidth,
  };

  /// The size an old per-call width (in unscaled pixels) maps to: up to the standard width is
  /// standard, anything wider is wide.
  static DialogWidth snap(double width) => width <= standardWidth ? DialogWidth.standard : DialogWidth.wide;
}
