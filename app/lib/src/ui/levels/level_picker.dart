// SPDX-License-Identifier: Apache-2.0
/// The parts of the level picker shared by the first-start step and Change level: the depth
/// dial (three stops as a radio group), the small home preview that shows more as the dial
/// goes deeper, the level's name and one-liner, and the Undercover row.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../l10n.dart';
import '../../levels/wallet_level.dart';
import '../level_step_screen.dart' show levelTitle;
import '../theme/brand.dart';
import '../theme/tokens.dart';
import 'level_art.dart';
import 'level_sheets.dart';

/// Expand and collapse alike (the motion rule): a layer of the preview, the dial's fill.
const Duration _motion = Duration(milliseconds: 220);

/// The key of a stop on the dial, for tests: `levelStopKey(WalletLevel.casual)`.
Key levelStopKey(WalletLevel level) => ValueKey('level-stop-${level.number}');

/// The Undercover switch row's key, for tests.
const Key levelUndercoverKey = ValueKey('level-undercover');

String levelStopName(AppLocalizations l, WalletLevel level) => switch (level) {
  WalletLevel.justSendReceive => l.lvPickStopOne,
  WalletLevel.casual => l.lvPickStopTwo,
  WalletLevel.everything => l.lvPickStopThree,
};

String levelLine(AppLocalizations l, WalletLevel level) => switch (level) {
  WalletLevel.justSendReceive => l.lvPickLineOne,
  WalletLevel.casual => l.lvPickLineTwo,
  WalletLevel.everything => l.lvPickLineThree,
};

LevelArtKind _art(WalletLevel level) => switch (level) {
  WalletLevel.justSendReceive => LevelArtKind.relaxed,
  WalletLevel.casual => LevelArtKind.curious,
  WalletLevel.everything => LevelArtKind.explorer,
};

/// The preview's height for the room the screen has: the prototype's steps.
double levelPreviewHeight(double screenHeight) => screenHeight < 640
    ? 84
    : screenHeight < 760
    ? 138
    : screenHeight < 900
    ? 168
    : 196;

/// Three stops on a track, Shallow to Deep end. A radio group: each stop is a radio a tap, a
/// screen reader or the keyboard (Tab, then Enter or Space) picks. The track fills up to the
/// picked stop, and the stops before it stay lit.
class LevelDial extends StatelessWidget {
  const LevelDial({super.key, required this.level, required this.onLevel, this.compact = false});

  final WalletLevel? level;
  final ValueChanged<WalletLevel> onLevel;

  /// A short screen: smaller tiles.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final tile = compact ? 48.0 : 56.0;
    final depth = level?.number ?? 0;
    final fill = depth <= 1 ? 0.0 : (depth - 1) / 2;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      container: true,
      role: SemanticsRole.radioGroup,
      label: l.lvPickDepth,
      explicitChildNodes: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: Stack(
          children: [
            // From the first stop's centre to the last one's, through the tiles' middles.
            Positioned(
              left: 0,
              right: 0,
              top: 4 + tile / 2 - 2,
              height: 4,
              child: FractionallySizedBox(
                widthFactor: 2 / 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: t.lineStrong, borderRadius: BorderRadius.circular(2)),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: fill),
                      duration: reduced ? Duration.zero : _motion,
                      curve: Curves.easeOut,
                      builder: (context, f, _) => FractionallySizedBox(
                        widthFactor: f,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final lv in WalletLevel.values)
                  Expanded(
                    child: _Stop(
                      key: levelStopKey(lv),
                      level: lv,
                      on: lv == level,
                      passed: lv.number < depth,
                      tile: tile,
                      compact: compact,
                      onTap: () => onLevel(lv),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    super.key,
    required this.level,
    required this.on,
    required this.passed,
    required this.tile,
    required this.compact,
    required this.onTap,
  });

  final WalletLevel level;
  final bool on;

  /// Before the picked stop: lit, not picked.
  final bool passed;
  final double tile;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final border = on ? t.accent : (passed ? t.tick : t.line);
    final ink = on ? t.accentText : (passed ? t.dim : t.faint);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: on,
      child: InkWell(
        borderRadius: BorderRadius.circular(t.radiusSmall),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : _motion,
                width: tile,
                height: tile,
                decoration: BoxDecoration(
                  color: on ? t.selected : t.surface,
                  border: Border.all(color: border, width: on ? 2 : 1),
                  borderRadius: BorderRadius.circular(t.radiusSmall),
                  boxShadow: [
                    if (on)
                      BoxShadow(
                        color: t.accent.withValues(alpha: dark ? 0.40 : 0.22),
                        blurRadius: 24,
                        spreadRadius: -4,
                      ),
                  ],
                ),
                child: Center(
                  child: LevelArt(_art(level), size: tile * 0.54, color: ink),
                ),
              ),
              SizedBox(height: compact ? 6 : 8),
              Text(
                levelStopName(l, level),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: on ? t.text : t.dim,
                  fontWeight: on ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The picked level's name and one-liner under the dial, or "Pick a stop" before a pick. Read
/// out when it changes.
class LevelCaption extends StatelessWidget {
  const LevelCaption({super.key, required this.level, this.compact = false});

  final WalletLevel? level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final theme = Theme.of(context);
    final level = this.level;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            level == null ? l.lvPickNone : levelTitle(l, level),
            textAlign: TextAlign.center,
            style: (compact ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)?.copyWith(
              color: level == null ? t.dim : t.text,
              fontWeight: level == null ? FontWeight.w500 : FontWeight.w600,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            level == null ? l.lvPickNoneLine : levelLine(l, level),
            textAlign: TextAlign.center,
            style: (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)?.copyWith(color: t.dim),
          ),
        ],
      ),
    );
  }
}

/// A small, calm home screen that gains a layer per level: level 1 the balance and the latest
/// payments, level 2 the status in words and the balance tiles, level 3 the status icons,
/// method chips and Outputs. Before a pick it shows level 1, faded. A static picture: screen
/// readers hear [LevelPreview]'s one label instead of its parts.
class LevelPreview extends StatelessWidget {
  const LevelPreview({super.key, required this.level, required this.height});

  final WalletLevel? level;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final theme = Theme.of(context);
    final depth = level?.number ?? 0;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final motion = reduced ? Duration.zero : _motion;
    TextStyle s(double size, {Color? color, FontWeight? weight}) => (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(fontSize: size, height: 1.3, color: color ?? t.text, fontWeight: weight, letterSpacing: 0);
    Widget dot(Color c, [double d = 6]) => Container(
      width: d,
      height: d,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
    // A layer shows and hides by size and fade alike.
    Widget layer(bool show, Widget child) => AnimatedSize(
      duration: motion,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: motion,
        opacity: show ? 1 : 0,
        child: show ? child : const SizedBox(width: double.infinity),
      ),
    );
    Widget statusTile(IconData icon, bool ok) => Container(
      width: 15,
      height: 15,
      margin: const EdgeInsetsDirectional.only(start: 3),
      decoration: BoxDecoration(color: t.surfaceHi, borderRadius: BorderRadius.circular(4)),
      child: Stack(
        children: [
          Center(child: Icon(icon, size: 9, color: t.dim)),
          PositionedDirectional(end: 2, bottom: 2, child: dot(ok ? t.ok : t.faint, 4)),
        ],
      ),
    );
    Widget chip(String text, {bool on = false}) => Container(
      margin: const EdgeInsetsDirectional.only(end: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: on ? t.surfaceHi : null,
        border: Border.all(color: on ? t.lineStrong : t.line),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(text, style: s(8, color: on ? t.text : t.dim)),
    );
    Widget tile(String label, String value, Color colour) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: t.bg,
          border: Border.all(color: t.line),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: s(7.5, color: t.dim),
            ),
            Text(
              value,
              style: s(10, color: colour, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
    Widget row(String name, String amount, {Color? tick, Color? colour, String? count}) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          if (tick != null) ...[dot(tick, 6), const SizedBox(width: 6)],
          Expanded(child: Text(name, style: s(9.5))),
          if (count != null) Text(count, style: s(9.5, color: t.dim)) else Text(amount, style: s(9.5, color: colour)),
        ],
      ),
    );
    return MediaQuery.withNoTextScaling(
      child: AnimatedOpacity(
        duration: motion,
        opacity: depth == 0 ? 0.45 : 1,
        child: Container(
          height: height,
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 300),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: depth == 3 ? t.lineStrong : t.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              // Clipped by the frame, so a short screen sees the top of it, never an overflow.
              OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 18,
                      child: Row(
                        children: [
                          const EpicMark(size: 13),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              BrandWordmark.brand,
                              style: s(9.5, color: t.accentText, weight: FontWeight.w600),
                            ),
                          ),
                          if (depth == 3) ...[
                            statusTile(Icons.lan_outlined, true),
                            statusTile(Icons.inbox_outlined, true),
                            statusTile(Icons.shield_outlined, false),
                          ] else ...[
                            dot(t.ok),
                            const SizedBox(width: 4),
                            dot(t.ok),
                          ],
                          const SizedBox(width: 6),
                          Icon(Icons.settings_outlined, size: 11, color: t.dim),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('1,234.5678', style: s(22, weight: FontWeight.w500).copyWith(height: 1)),
                        const SizedBox(width: 4),
                        Text(
                          'EPIC',
                          style: s(7, color: t.accentText, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('≈ 518.52 USD', style: s(8, color: t.dim)),
                    const SizedBox(height: 10),
                    layer(
                      depth >= 2,
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              dot(t.ok, 5),
                              const SizedBox(width: 3),
                              Text(l.lvPickNetworkOk, style: s(8.5, color: t.dim)),
                              const SizedBox(width: 10),
                              dot(t.ok, 5),
                              const SizedBox(width: 3),
                              Text(l.lvPickEpicboxOk, style: s(8.5, color: t.dim)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              tile(l.homeBalanceConfirming, '12.5000', t.accentText),
                              const SizedBox(width: 6),
                              tile(l.homeTileLocked, '26.0000', t.text),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    layer(
                      depth == 3,
                      Column(
                        children: [
                          Row(children: [chip(l.methodEpicbox, on: true), chip(l.methodDirect), chip(l.methodFile)]),
                          const SizedBox(height: 8),
                          row(l.outputsTitle, '', count: '12'),
                        ],
                      ),
                    ),
                    row('Bob', '+12.5000', tick: t.txReceived, colour: t.txReceived),
                    row('Alice', '−25.0000', tick: t.txSent, colour: t.txSent),
                    row('Alice', '+150.0000', tick: t.txReceived, colour: t.txReceived),
                  ],
                ),
              ),
              // The list runs on under the frame's foot.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 28,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [t.surface.withValues(alpha: 0), t.surface],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Undercover (Tor only) as a quiet row: the agent, the name, the switch, and its ⓘ.
class UndercoverRow extends StatelessWidget {
  const UndercoverRow({super.key, required this.value, required this.onChanged, this.later = false});

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Change level: "Undercover" and its later sheet, not "from the start".
  final bool later;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final onChanged = this.onChanged;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: MergeSemantics(
                child: InkWell(
                  key: levelUndercoverKey,
                  borderRadius: BorderRadius.circular(t.radiusSmall),
                  onTap: onChanged == null ? null : () => onChanged(!value),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        const SizedBox(width: 2),
                        LevelArt(LevelArtKind.agent, size: 22, color: value ? t.accentText : t.faint),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            later ? l.lvPickUndercover : l.levelUndercoverTitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.text),
                          ),
                        ),
                        Switch(value: value, onChanged: onChanged),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            UndercoverHelpHint(later: later),
          ],
        ),
      ),
    );
  }
}
