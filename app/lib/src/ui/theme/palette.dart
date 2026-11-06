// SPDX-License-Identifier: Apache-2.0
/// The one colour palette of both front ends. The phone's [WalletTokens] (`ui/theme/tokens.dart`)
/// and the desktop's [DeskColors] (`desktop/theme/tokens.dart`) take every colour from here, so
/// a role holds the same value on the phone and the desktop and changes in one place.
/// `test/theme_test.dart` checks the pairs of text on surface for AA and that the shared roles
/// match.
///
/// Roles, by the desktop's names where the phone's differ:
///  - [bg] the window; [s1] panels and rows (phone `surface`); [s2] fields (phone `field`);
///    [s3] an object on a panel, hover and selection (phone `surfaceHi`); [s4] dialogs,
///    popovers and menus (phone `raised`).
///  - [line] separates, [lineStrong] encloses, [lineField] is a field's edge (3:1 on [s2]).
///  - [text], [dim], [faint]: content, secondary, hints and readouts; each AA on every surface.
///  - [shadow] is the one soft shadow under a floating surface, with its [lineStrong] border.
///  - [scrim] is the barrier behind a dialog. Never a shadow: at 40 % it draws a hard band.
library;

import 'dart:ui' show Color;

/// The dark set: the Protocol palette of the Electron wallet's Modern look.
abstract final class PaletteDark {
  static const bg = Color(0xFF08080A);
  static const s1 = Color(0xFF0D0D10);
  static const s2 = Color(0xFF131318);
  static const s3 = Color(0xFF1A1A21);
  static const s4 = Color(0xFF22222B);
  static const line = Color(0xFF24242A);
  static const lineStrong = Color(0xFF33333D);
  static const lineField = Color(0xFF62626D);
  static const text = Color(0xFFFFF9F9);
  static const dim = Color(0xFFA4A4AD);
  static const faint = Color(0xFF8A8A94);
  static const accent = Color(0xFFF6D471);
  static const accentDeep = Color(0xFFC98A3E);
  static const accentInk = Color(0xFF08080A);
  static const accentText = Color(0xFFF6D471);
  static const accentSoft = Color(0x24F6D471);
  static const accentFaint = Color(0x0FF6D471);
  static const tick = Color(0xFFC98A3E);
  static const ok = Color(0xFF8AD98A);
  static const okSoft = Color(0x1F8AD98A);
  static const warn = Color(0xFFF5A54A);
  static const warnSoft = Color(0x1FF5A54A);
  static const risk = Color(0xFFF08A8A);
  static const riskSoft = Color(0x1FF08A8A);
  static const info = Color(0xFF8FB8E8);
  static const infoSoft = Color(0x1F8FB8E8);
  static const txSent = Color(0xFFF3645F);
  static const txReceived = ok;
  static const txCancelled = faint;

  /// The phone's selected row: a neutral fill a step over [s3], and its outline.
  static const selected = s4;
  static const selectedLine = Color(0xFF4A4A56);

  static const hover = Color(0x0DFFF9F9);
  static const press = Color(0x17FFF9F9);
  static const grid = Color(0x09FFF9F9);
  static const scrim = Color(0xB8050506);
  static const shadow = Color(0x66000000);
  static const glow = Color(0x52F6D471);

  /// Dark has no resting shadow and no wash: a panel is its fill and hairline.
  static const lift = Color(0x00000000);
  static const wash = Color(0x00F6D471);
  static const hero = Color(0x00000000);
  static const tint = Color(0x00000000);
  static const dots = Color(0x00000000);
}

/// The light set. Gold becomes an AA brown, amber a burnt orange well apart from it in hue
/// (19° against the brown's 34°, so a warning never reads as the brand), the ticks the same
/// brand's gold-deep (a frame, never charcoal). The neutrals are the BT Wallet landing page's
/// Day look (look c): a warm paper window, white panels a clear step
/// above it, warm lines and ink, so nothing cool-grey sits beside the brown; hover, selection and
/// the cancelled grey stay neutral (theme_test). Fields are white
/// wells with a [lineField] edge, as on the desktop.
abstract final class PaletteLight {
  static const bg = Color(0xFFF5EFE4);
  static const s1 = Color(0xFFFFFFFF);
  static const s2 = Color(0xFFFFFFFF);
  static const s3 = Color(0xFFF1EDE6);
  static const s4 = Color(0xFFFFFFFF);
  static const line = Color(0xFFEAE0CE);
  static const lineStrong = Color(0xFFDACBB0);
  static const lineField = Color(0xFF8A7F70);
  static const text = Color(0xFF211A11);
  static const dim = Color(0xFF574D40);
  static const faint = Color(0xFF645D56);
  static const accent = Color(0xFF8F5E1F);
  static const accentDeep = Color(0xFF8F5E1F);
  static const accentInk = Color(0xFFFFFFFF);
  static const accentText = Color(0xFF815525);
  static const accentSoft = Color(0x1F8F5E1F);
  static const accentFaint = Color(0x0D8F5E1F);
  static const tick = Color(0xFFC98A3E);
  static const ok = Color(0xFF1F7A3A);
  static const okSoft = Color(0x1A1F7A3A);
  static const warn = Color(0xFFB54708);
  static const warnSoft = Color(0x1AB54708);
  static const risk = Color(0xFFB3261E);
  static const riskSoft = Color(0x14B3261E);
  static const info = Color(0xFF2F5F9E);
  static const infoSoft = Color(0x1A2F5F9E);
  static const txSent = Color(0xFFC41E3A);
  static const txReceived = ok;
  static const txCancelled = faint;

  /// The phone's selected row: the desktop's selection fill, and its outline.
  static const selected = s3;
  static const selectedLine = Color(0xFFBCB6AE);

  static const hover = Color(0x0A5A3A12);
  static const press = Color(0x145A3A12);
  static const grid = Color(0x0A8F5E1F);
  static const scrim = Color(0x66211A11);
  static const shadow = Color(0x245A3A12);
  static const glow = Color(0x298F5E1F);

  /// [lift] is the one low shadow under a resting panel, warm and soft, so the white panels
  /// sit on the paper without a grey band; [wash] is the gold glow at the top of the page
  /// backdrop (desktop `DeskBackdrop`), the Day look's light, never a brown tint over the page.
  static const lift = Color(0x145A3A12);
  static const wash = Color(0x66FFD27A);

  /// Light only, transparent in dark: [hero] the warm fill the balance frame starts from,
  /// [tint] the brand tint of an icon tile and the sidebar's selected item, [dots] the dot
  /// texture of the page backdrop (off: the paper is plain, as on the Day page).
  static const hero = Color(0xFFFFF4DE);
  static const tint = Color(0x1FC98A3E);
  static const dots = Color(0x00000000);
}
