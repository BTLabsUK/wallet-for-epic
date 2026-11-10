// SPDX-License-Identifier: Apache-2.0
/// The depth dial on the desktop: three stops (Shallow · Deeper · Deep end) as a radio group, the
/// picked stop's name and line, and a small Overview picture that gains a layer per stop, on
/// Settings › Advanced › View; and the Tor only switch of Welcome (the first-start answer).
/// The words are the phone's (`lvPick*`); the picture is drawn with desktop colours and
/// carries no real data.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../app_info.dart' show appName;
import '../../../levels/wallet_level.dart';
import '../../../trust_ids.dart';
import '../../../ui/levels/level_art.dart';
import '../../../ui/levels/level_picker.dart' show levelLine, levelStopName;
import '../../../ui/status_icons.dart' show EpicGlyphs;
import '../../../ui/theme/brand.dart' show EpicMark;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// The key of a stop on the dial, for tests: `deskLevelStopKey(WalletLevel.casual)`.
Key deskLevelStopKey(WalletLevel level) => ValueKey('desk-level-stop-${level.number}');

/// The Undercover switch's key, for tests.
const Key deskUndercoverKey = ValueKey('desk-level-undercover');

LevelArtKind _art(WalletLevel level) => switch (level) {
  WalletLevel.justSendReceive => LevelArtKind.relaxed,
  WalletLevel.casual => LevelArtKind.curious,
  WalletLevel.everything => LevelArtKind.explorer,
};

/// What each depth is, as the "What this decides" dialog words it.
String _helpLine(AppLocalizations l, WalletLevel level) => switch (level) {
  WalletLevel.justSendReceive => l.deskLvStartHelpShallow,
  WalletLevel.casual => l.deskLvStartHelpDeeper,
  WalletLevel.everything => l.deskLvStartHelpDeep,
};

/// "What this decides": the one rule and a line per depth.
Future<void> showDepthHelp(BuildContext context) => showEDialog<void>(
  context,
  builder: (context) {
    final l = context.l10n;
    return EDialog(
      title: l.lvPickHelpTitle,
      icon: EIcons.help,
      description: l.lvPickHelpText,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final lv in WalletLevel.values) Padding(padding: EdgeInsets.only(bottom: Sp.x2), child: Text(_helpLine(l, lv), style: context.ts.body))],
      ),
      actions: [EButton(label: l.commonOk, autofocus: true, onPressed: () => Navigator.pop(context))],
    );
  },
);

/// The Undercover explanation: [later] is the Change level wording (no "from the start").
Future<void> showUndercoverHelp(BuildContext context, {required bool later}) => showEDialog<void>(
  context,
  builder: (context) {
    final l = context.l10n;
    return EDialog(
      title: later ? l.lvPickUndercover : l.levelUndercoverTitle,
      icon: EIcons.help,
      description: later ? l.lvPickUndercoverLaterHelp : l.lvPickUndercoverHelpNet,
      actions: [EButton(label: l.commonOk, autofocus: true, onPressed: () => Navigator.pop(context))],
    );
  },
);

/// The picker's panel: the dial, its caption, [foot] (the Undercover row, hints, buttons) on the
/// left and the Overview picture on the right; the picture goes under the dial in a narrow window.
class DeskDepthPicker extends StatelessWidget {
  const DeskDepthPicker({
    super.key,
    required this.level,
    required this.onLevel,
    required this.foot,
    required this.caption,
    this.compact = false,
    this.covered = false,
    this.title,
    this.lead,
    this.framed = true,
  });

  /// Its own panel (s1, border, rounded); false inside a Settings group, which draws one.
  final bool framed;

  /// A heading and a line above the dial (Welcome); Change level has its page title instead.
  final String? title;
  final String? lead;

  /// The picked stop; null before a pick on a fresh install.
  final WalletLevel? level;
  final ValueChanged<WalletLevel> onLevel;

  /// Under the caption: the Undercover row, the hint, the buttons.
  final Widget foot;

  /// Under the picture.
  final String caption;

  /// A short window: smaller tiles and gaps.
  final bool compact;

  /// The picture is faded under "Pick a stop to see the preview" until a stop is picked.
  final bool covered;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final l = context.l10n;
    final preview = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l.deskLvStartPreviewLabel,
          child: ExcludeSemantics(child: DeskOverviewPreview(level: level, cover: covered && level == null)),
        ),
        SizedBox(height: Sp.x3),
        Text(caption, style: context.ts.small, textAlign: TextAlign.center),
      ],
    );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? Sp.x6 : Sp.x8, vertical: compact ? Sp.x5 : Sp.x6),
      decoration: framed
          ? BoxDecoration(
              color: c.s1,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(Rad.lg),
            )
          : null,
      child: LayoutBuilder(
        builder: (context, box) {
          // Beside while the picture keeps 340 u next to the capped dial (a 1280 px window's
          // Settings page); stacked below that.
          final beside = box.maxWidth >= Max.dial + Sp.x10 + 340.u;
          final gap = compact ? Sp.x3 : Sp.x4;
          Widget head() => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Semantics(header: true, child: Text(title!, style: context.ts.h2)),
                if (lead != null) Text(lead!, style: context.ts.bodyDim),
                SizedBox(height: compact ? Sp.x2 : Sp.x4),
              ],
            ],
          );
          if (!beside) {
            // Stacked: the dial and its caption centred in one column, a divider, the rest of
            // the card left-aligned, then the picture under, capped and centred.
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                head(),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: Max.dial),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DeskDial(level: level, onLevel: onLevel, compact: compact),
                        SizedBox(height: gap),
                        DeskLevelCaption(level: level, centered: true),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: gap),
                Divider(height: 1, thickness: 1, color: c.line),
                SizedBox(height: gap),
                _StackedScope(child: foot),
                SizedBox(height: Sp.x5),
                Center(
                  child: ConstrainedBox(constraints: BoxConstraints(maxWidth: Max.preview), child: preview),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: Max.dial),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        head(),
                        DeskDial(level: level, onLevel: onLevel, compact: compact),
                        SizedBox(height: gap),
                        DeskLevelCaption(level: level),
                        SizedBox(height: gap),
                        foot,
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? Sp.x8 : Sp.x10),
              // The dial keeps its full width; the picture takes the rest, up to its cap.
              SizedBox(width: (box.maxWidth - Max.dial - (compact ? Sp.x8 : Sp.x10)).clamp(340.u, Max.preview), child: preview),
            ],
          );
        },
      ),
    );
  }
}

/// Tells the Undercover row inside [DeskDepthPicker]'s stacked layout that the picker already
/// drew the divider above it.
class _StackedScope extends InheritedWidget {
  const _StackedScope({required super.child});

  @override
  bool updateShouldNotify(_StackedScope old) => false;
}

/// Three stops on a rail, Shallow to Deep end: a radio group, each stop a radio a click or the
/// keyboard (Tab, then Enter or Space) picks.
class DeskDial extends StatelessWidget {
  const DeskDial({super.key, required this.level, required this.onLevel, this.compact = false});

  final WalletLevel? level;
  final ValueChanged<WalletLevel> onLevel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final tile = (compact ? 64 : 76).u;
    final stops = WalletLevel.values;
    return Semantics(
      container: true,
      role: SemanticsRole.radioGroup,
      label: context.l10n.lvPickDepth,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth.clamp(0.0, Max.dial);
          // The connector takes what the tiles leave, clamped so the rail never vanishes or sprawls.
          final connector = ((w - 3 * (tile + Sp.x6)) / 2).clamp(32.u, 96.u);
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 3 * (tile + Sp.x6) + 2 * connector,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < stops.length; i++) ...[
                    if (i > 0)
                      SizedBox(
                        width: connector,
                        child: Padding(
                          padding: EdgeInsets.only(top: tile / 2 + Sp.x2 - 1.u, left: Sp.x2, right: Sp.x2),
                          child: AnimatedContainer(
                            duration: Dur.base,
                            height: 2.u,
                            // The rail fills up to the picked stop.
                            color: (level?.number ?? 0) > i ? c.accent : c.lineStrong,
                          ),
                        ),
                      ),
                    _Stop(key: deskLevelStopKey(stops[i]), level: stops[i], on: stops[i] == level, tile: tile, onTap: () => onLevel(stops[i])),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({super.key, required this.level, required this.on, required this.tile, required this.onTap});

  final WalletLevel level;
  final bool on;
  final double tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final name = levelStopName(context.l10n, level);
    return TrustId(TrustIds.levelStop(level.number), child: Semantics(
      inMutuallyExclusiveGroup: true,
      checked: on,
      label: name,
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => onTap())},
        child: Builder(
          builder: (context) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(
              width: tile + Sp.x6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FocusRing(
                    focused: Focus.of(context).hasFocus,
                    child: AnimatedContainer(
                      duration: Dur.base,
                      transform: Matrix4.translationValues(0, on ? -2.u : 0, 0),
                      width: tile,
                      height: tile,
                      decoration: BoxDecoration(
                        color: on ? c.s3 : c.s2,
                        border: Border.all(color: on ? c.accent : c.line, width: on ? 2 : 1),
                        borderRadius: BorderRadius.circular(Rad.sm),
                        boxShadow: [if (on) BoxShadow(color: c.accent.withValues(alpha: 0.35), blurRadius: 28.u, spreadRadius: -4.u)],
                      ),
                      child: Center(child: LevelArt(_art(level), size: tile * 0.54, color: on ? c.accentText : c.dim)),
                    ),
                  ),
                  SizedBox(height: Sp.x2),
                  Text(name, style: ts.strong.copyWith(color: on ? c.text : c.dim), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

/// The picked depth's name and line under the dial; "Pick a stop" before a pick. Read out when
/// it changes.
class DeskLevelCaption extends StatelessWidget {
  const DeskLevelCaption({super.key, required this.level, this.centered = false});

  final WalletLevel? level;

  /// Text centred, for the stacked layout.
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final level = this.level;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            level == null ? l.lvPickNone : levelStopName(l, level),
            style: ts.h3.copyWith(color: level == null ? context.dc.dim : context.dc.text),
            textAlign: centered ? TextAlign.center : null,
          ),
          SizedBox(height: Sp.x1),
          Text(level == null ? l.lvPickNoneLine : levelLine(l, level), style: ts.bodyDim, textAlign: centered ? TextAlign.center : null),
        ],
      ),
    );
  }
}

/// Tor only: at first start a hairline and one quiet line (the Tor mark, lit when on, the name,
/// its ⓘ; the line is the toggle); [later] is the Change level wording, with a switch.
class DeskUndercoverRow extends StatelessWidget {
  const DeskUndercoverRow({super.key, required this.value, required this.onChanged, this.later = false});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool later;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final l = context.l10n;
    final title = later ? l.lvPickUndercover : l.levelUndercoverTitle;
    final onChanged = this.onChanged;
    if (!later) {
      // First start: a hairline, then one quiet centred line: the Tor mark, dim while off and
      // lit when on, "Tor only" and its ⓘ (the owner). The line is the toggle: a click, or Enter
      // or Space once focused.
      void toggle() => onChanged?.call(!value);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, thickness: 1, color: c.line),
          SizedBox(height: Sp.x2),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Semantics(
                    container: true,
                    toggled: value,
                    label: title,
                    excludeSemantics: true,
                    onTap: onChanged == null ? null : toggle,
                    child: FocusableActionDetector(
                      enabled: onChanged != null,
                      mouseCursor: onChanged == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
                      actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => toggle())},
                      child: Builder(
                        builder: (context) => GestureDetector(
                          key: deskUndercoverKey,
                          behavior: HitTestBehavior.opaque,
                          onTap: onChanged == null ? null : toggle,
                          child: FocusRing(
                            focused: Focus.of(context).hasFocus,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: 40.u),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: Sp.x3),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: Dur.base,
                                      child: Icon(EpicGlyphs.tor, key: ValueKey(value), size: 18.u, color: value ? c.accentText : c.faint),
                                    ),
                                    SizedBox(width: Sp.x2),
                                    Flexible(child: Text(title, style: context.ts.small.copyWith(color: value ? c.text : c.dim))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                EIconButton(icon: EIcons.info, label: l.deskLvStartUndercoverAbout, size: EBtnSize.inline, onPressed: () => showUndercoverHelp(context, later: false)),
              ],
            ),
          ),
        ],
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(border: context.getInheritedWidgetOfExactType<_StackedScope>() == null ? Border(top: BorderSide(color: c.line)) : null),
      child: Padding(
        padding: EdgeInsets.only(top: Sp.x3),
        child: Row(
          children: [
            ESwitch(key: deskUndercoverKey, value: value, onChanged: onChanged, semanticLabel: title),
            SizedBox(width: Sp.x3),
            LevelArt(LevelArtKind.agent, size: 22.u, color: value ? c.accentText : c.faint),
            SizedBox(width: Sp.x2),
            Flexible(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onChanged == null ? null : () => onChanged(!value),
                child: ExcludeSemantics(child: Text(title, style: context.ts.body)),
              ),
            ),
            SizedBox(width: Sp.x1),
            EIconButton(icon: EIcons.info, label: l.deskLvStartUndercoverAbout, size: EBtnSize.inline, onPressed: () => showUndercoverHelp(context, later: later)),
          ],
        ),
      ),
    );
  }
}

/// A small Overview that gains a layer per depth: Shallow the balance, its sentence and the
/// latest payments; Deeper the status icons, the balance tiles and the methods; Deep end
/// Outputs and Invoices on the rail and the payment ids. Before a pick it shows Shallow, faded
/// under [cover]. A static picture drawn from its own width, so it scales with the window.
class DeskOverviewPreview extends StatelessWidget {
  const DeskOverviewPreview({super.key, required this.level, this.cover = false});

  final WalletLevel? level;

  /// Show "Pick a stop to see the preview" over it.
  final bool cover;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final l = context.l10n;
    final depth = level?.number ?? 0;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final motion = reduced ? Duration.zero : Motion.expand;
    final monoFamily = context.ts.mono().fontFamily;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: LayoutBuilder(
        builder: (context, box) {
          // Everything is drawn for 520 wide and scaled by the width it gets.
          final k = box.maxWidth / 520;
          TextStyle s(double size, {Color? color, FontWeight? weight, String? family}) =>
              TextStyle(fontSize: size * k, height: 1.3, color: color ?? c.text, fontWeight: weight, letterSpacing: 0, fontFamily: family);
          Widget layer(bool show, Widget child, {Axis axis = Axis.vertical}) => AnimatedSize(
            duration: motion,
            curve: Motion.easeOut,
            alignment: axis == Axis.vertical ? Alignment.topCenter : Alignment.centerLeft,
            child: AnimatedOpacity(
              duration: motion,
              curve: show ? Motion.easeOut : Motion.easeIn,
              opacity: show ? 1 : 0,
              child: show ? child : SizedBox(width: axis == Axis.vertical ? double.infinity : 0, height: axis == Axis.vertical ? 0 : null),
            ),
          );
          Widget navItem(String text, {bool on = false}) => Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 2 * k),
            padding: EdgeInsets.symmetric(horizontal: 7 * k, vertical: 4 * k),
            decoration: BoxDecoration(color: on ? c.s3 : null, borderRadius: BorderRadius.circular(5 * k)),
            child: Text(text, style: s(9, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.clip),
          );
          Widget statusTile(IconData icon, bool ok) => Container(
            width: 11 * k,
            height: 11 * k,
            margin: EdgeInsetsDirectional.only(start: 4 * k),
            decoration: BoxDecoration(color: c.s3, borderRadius: BorderRadius.circular(3 * k)),
            child: Stack(
              children: [
                Center(child: Icon(icon, size: 7 * k, color: c.dim)),
                PositionedDirectional(
                  end: 1 * k,
                  bottom: 1 * k,
                  child: Container(width: 3.5 * k, height: 3.5 * k, decoration: BoxDecoration(color: ok ? c.ok : c.faint, shape: BoxShape.circle)),
                ),
              ],
            ),
          );
          Widget tile(String label, String value) => Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6 * k, vertical: 5 * k),
              decoration: BoxDecoration(border: Border(left: BorderSide(color: c.line))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: s(7.5, color: c.dim)),
                  Text(value, style: s(9, family: monoFamily)),
                ],
              ),
            ),
          );
          // A payment row. Deeper adds the method; Deep end the id in mono. [casual] and
          // [technical] are the line under the first (pending) payment: plain words at Deeper,
          // the kernel and the count at Deep end, so the two depths differ at a glance.
          Widget payment(String name, String amount, {required Color tone, String? how, String? id, String? casual, String? technical}) => Container(
            padding: EdgeInsets.symmetric(horizontal: 8 * k, vertical: 5 * k),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 11 * k,
                  height: 11 * k,
                  margin: EdgeInsets.only(top: 0.5 * k),
                  decoration: BoxDecoration(border: Border.all(color: tone), borderRadius: BorderRadius.circular(3 * k)),
                ),
                SizedBox(width: 6 * k),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: name, style: s(9, weight: FontWeight.w500)),
                            if (depth >= 2 && how != null) TextSpan(text: ' · $how', style: s(8, color: c.dim)),
                            if (depth == 3 && id != null) TextSpan(text: ' · $id', style: s(7.5, color: c.dim, family: monoFamily)),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (casual != null && technical != null)
                        layer(
                          depth >= 2,
                          Padding(
                            padding: EdgeInsets.only(top: 1.5 * k),
                            child: Text(
                              depth == 3 ? technical : casual,
                              style: depth == 3 ? s(7.5, color: c.dim, family: monoFamily) : s(8, color: c.dim),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(amount, style: s(8.5, color: tone, family: monoFamily)),
              ],
            ),
          );
          final rail = SizedBox(
            width: box.maxWidth * 0.21,
            child: Padding(
              padding: EdgeInsets.fromLTRB(7 * k, 8 * k, 7 * k, 8 * k),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [EpicMark(size: 10 * k, color: c.accent), SizedBox(width: 4 * k), Flexible(child: Text(appName, style: s(8.5, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                        SizedBox(height: 8 * k),
                        navItem(l.deskShellNavOverview, on: true),
                        navItem(l.deskShellNavActivity),
                        layer(depth == 3, navItem(l.deskShellNavOutputs)),
                        navItem(l.deskShellNavContacts),
                        layer(depth == 3, navItem(l.deskInvNav)),
                        navItem(l.deskShellNavSend),
                        navItem(l.deskShellNavReceive),
                      ],
                    ),
                  ),
                  Positioned(left: 0, right: 0, bottom: 0, child: navItem(l.deskShellNavSettings)),
                ],
              ),
            ),
          );
          final hero = Container(
            decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(6 * k)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(10 * k, 8 * k, 10 * k, 8 * k),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.deskOvBalance, style: s(8, color: c.dim)),
                            SizedBox(height: 3 * k),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: '1,281.', style: s(20, weight: FontWeight.w600)),
                                  TextSpan(text: '5261', style: s(20, weight: FontWeight.w600, color: c.dim)),
                                  TextSpan(text: ' EPIC', style: s(7, color: c.dim)), // l10n-ok: the unit
                                ],
                              ),
                            ),
                            layer(depth <= 1, Padding(padding: EdgeInsets.only(top: 2 * k), child: Text(l.deskLvStartMiniLine, style: s(8.5, color: c.dim), maxLines: 1, overflow: TextOverflow.ellipsis))),
                          ],
                        ),
                      ),
                      SizedBox(width: 6 * k),
                      for (final (i, text) in [l.deskOvSend, l.deskOvReceive].indexed)
                        Container(
                          margin: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 4 * k),
                          padding: EdgeInsets.symmetric(horizontal: 9 * k, vertical: 4 * k),
                          decoration: BoxDecoration(
                            color: i == 0 ? c.accent : c.s2,
                            border: Border.all(color: i == 0 ? c.accent : c.lineStrong),
                            borderRadius: BorderRadius.circular(4 * k),
                          ),
                          child: Text(text, style: s(8.5, weight: FontWeight.w500, color: i == 0 ? c.accentInk : c.text)),
                        ),
                    ],
                  ),
                ),
                layer(
                  depth >= 2,
                  DecoratedBox(
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                    child: Row(
                      children: [
                        tile(l.deskOvBreakConfirming, '50.0'),
                        tile(depth == 2 ? l.deskLvStartMiniFresh : l.deskOvBreakImmature, '2.0'),
                        tile(depth == 2 ? l.deskLvPayTileAwaiting : l.deskOvBreakAwaiting, '12.5'),
                        tile(l.deskOvBreakLocked, '18.91'),
                        tile(l.deskOvBreakTotal, '1,352.44'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
          final main = SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(10 * k, 7 * k, 10 * k, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 14 * k,
                  child: Row(
                    children: [
                      Expanded(child: Text(l.deskLvStartMiniWallet, style: s(9, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      statusTile(Icons.public, true),
                      statusTile(Icons.inbox_outlined, true),
                      layer(depth >= 2, Row(children: [statusTile(Icons.shield_outlined, false), statusTile(Icons.link, false)]), axis: Axis.horizontal),
                    ],
                  ),
                ),
                // Deep end: the node's numbers in a line of their own, in mono.
                layer(
                  depth == 3,
                  Padding(
                    padding: EdgeInsets.only(top: 4 * k),
                    child: Text(
                      '${l.lvShellLatestBlock} 2,934,118 · ${l.lvShellUpToDate} · ${l.deskKitFactPeers} 8', // l10n-ok: sample numbers
                      style: s(7.5, color: c.dim, family: monoFamily),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(height: 7 * k),
                hero,
                SizedBox(height: 7 * k),
                Container(
                  decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(6 * k)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      payment(
                        'Bob', // l10n-ok: sample payment
                        '+12.5', // l10n-ok: sample payment
                        tone: c.txReceived,
                        how: l.methodEpicbox,
                        id: 'a1f9e8d7', // l10n-ok: sample payment
                        casual: metaLine([l.lvPayArriving, l.lvPayConfirming(2, 6)]),
                        technical: '${l.txDetailsKernel} 8f1c2e…9a3b · ${l.lvPayConfirmations} 2/6', // l10n-ok: sample numbers
                      ),
                      payment('Alice', '−25.0', tone: c.txSent, how: l.methodEpicbox, id: '7c21b0e4'), // l10n-ok: sample payment
                      payment('Alice', '+148.7321', tone: c.txReceived, how: l.methodEpicbox, id: '02ab9c11'), // l10n-ok: sample payment
                    ],
                  ),
                ),
              ],
            ),
          );
          return Stack(
            children: [
              AnimatedContainer(
                duration: motion,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: c.bg,
                  border: Border.all(color: depth == 3 ? c.lineStrong : c.line),
                  borderRadius: BorderRadius.circular(10 * k),
                ),
                child: AnimatedOpacity(
                  duration: motion,
                  opacity: depth == 0 ? 0.35 : 1,
                  child: MediaQuery.withNoTextScaling(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DecoratedBox(decoration: BoxDecoration(border: Border(right: BorderSide(color: c.line))), child: rail),
                        Expanded(child: main),
                      ],
                    ),
                  ),
                ),
              ),
              if (cover)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x2),
                      decoration: c.popover,
                      child: Text(l.deskLvStartCover, style: context.ts.body),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
