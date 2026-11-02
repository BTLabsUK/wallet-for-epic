// SPDX-License-Identifier: Apache-2.0
/// The phone's settings-row anatomy, in one place. Every row is a [ListTile] on the theme's
/// insets (16 dp at the start, 24 at the end; an icon in the leading slot puts the title at
/// 56 dp), so titles line up down a page whatever the row holds:
///
/// - a navigation row (opens a page of its own): the title, and [NavChevron] at the end;
/// - a value row (opens a picker in place): the title and its value on the second line, no
///   chevron (the subtitle's colour is the theme's);
/// - a switch row: [HintSwitchTile], the switch at the end;
/// - a radio row: [RadioRow], the radio at the end, where a switch or a chevron goes, so its
///   icon leads as on every other row;
/// - a section header, [SettingsHeader], and under it a quieter [SettingsSubHeader].
///
/// An action (Lock wallet, Delete wallet, Recheck balance) is a plain row: no chevron, no value.
library;

import 'package:flutter/material.dart';

import 'info_hint.dart';
import 'theme/tokens.dart';

export 'info_hint.dart' show HintSwitchTile, TitleWithHint;

/// The end of a navigation row: a row with it opens a page, a row without it does something
/// in place. Dim, and silent to screen readers (the row says it is a button).
class NavChevron extends StatelessWidget {
  const NavChevron({super.key, this.size = 24, this.color});

  /// 24 on a row; 18 on a one-line link under a row.
  final double size;

  /// [WalletTokens.dim] unless the line it ends has a colour of its own (a state line).
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Icon(Icons.chevron_right, size: size, color: color ?? context.tokens.dim),
  );
}

/// One choice of a [RadioGroup]<[T]>: a row on the settings insets with [icon] leading and the
/// radio at the end. A tap anywhere on the row chooses [value]. With [hint] the title carries
/// an info icon ([TitleWithHint]) and the row keeps its parts apart for screen readers; without
/// one it reads as one radio button with its title.
class RadioRow<T> extends StatelessWidget {
  const RadioRow({
    super.key,
    required this.value,
    required this.title,
    this.icon,
    this.leading,
    this.subtitle,
    this.hint,
    this.hintKey,
    this.hintIcon,
    this.onHint,
    this.enabled = true,
    this.tileKey,
  });

  final T value;
  final String title;

  /// The row's glyph, in the leading slot as on every other row.
  final IconData? icon;

  /// A leading widget in place of [icon] (a language's flag).
  final Widget? leading;

  /// A line on what the choice does, under the title.
  final String? subtitle;

  /// The explanation behind an info icon after the title.
  final String? hint;

  /// The key of the info icon, for tests.
  final Key? hintKey;

  /// The glyph beside the info sheet's title; [icon] when null.
  final IconData? hintIcon;

  /// Opens a richer explanation than the info sheet ([InfoHint.onOpen]).
  final VoidCallback? onHint;

  final bool enabled;

  /// The key of the [ListTile] itself, for tests that read the tile.
  final Key? tileKey;

  @override
  Widget build(BuildContext context) {
    final group = RadioGroup.maybeOf<T>(context);
    final leading = this.leading ?? (icon == null ? null : Icon(icon));
    final hint = this.hint;
    final tile = ListTile(
      key: tileKey,
      enabled: enabled,
      leading: leading,
      title: hint == null
          ? Text(title)
          : TitleWithHint(title, hint: hint, hintKey: hintKey, icon: hintIcon ?? icon, labelled: enabled, onOpen: onHint),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Radio<T>(value: value, enabled: enabled),
      onTap: enabled && group != null ? () => group.onChanged(value) : null,
    );
    return hint == null ? MergeSemantics(child: tile) : tile;
  }
}

/// A section's header on a settings page: dim, in the title face's small size, 24 dp above it.
/// [trailing] puts a small action at its end (Advanced's "Hide everything again").
class SettingsHeader extends StatelessWidget {
  const SettingsHeader(this.title, {super.key, this.trailing}) : inBody = false;

  /// The same header on a settings page laid out in a padded body of cards (Linked devices,
  /// Invoices) rather than a list of rows: no inset of its own, room above and below.
  const SettingsHeader.inBody(this.title, {super.key, this.trailing}) : inBody = true;

  final String title;

  /// Laid out by [SettingsHeader.inBody].
  final bool inBody;

  /// A small action at the header's end (the desktop's "Hide everything again").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Neutral, as the desktop's section headers: gold is for the brand and the primary
    // action only.
    final text = Semantics(
      header: true,
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(color: context.tokens.dim, fontWeight: FontWeight.w600),
      ),
    );
    if (inBody) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: trailing == null ? text : Row(children: [Expanded(child: text), trailing!]),
      );
    }
    if (trailing == null) {
      return Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 4), child: text);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
      child: Row(children: [Expanded(child: text), trailing!]),
    );
  }
}

/// A group inside a section (Settings › Transactions: Link, Direct): one step quieter than
/// [SettingsHeader] (smaller, regular weight, dim), with an optional 16 dp glyph before it.
class SettingsSubHeader extends StatelessWidget {
  const SettingsSubHeader(this.title, {super.key, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(color: t.dim, fontWeight: FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: t.dim),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Semantics(header: true, child: Text(title, style: style)),
          ),
        ],
      ),
    );
  }
}
