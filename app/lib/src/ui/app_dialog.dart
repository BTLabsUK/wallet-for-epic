// SPDX-License-Identifier: Apache-2.0
/// The one phone dialog, the twin of the desktop's `EDialog` (the anatomy and its numbers are
/// in `theme/dialog_metrics.dart`): a 40 px icon tile, the title and a short description
/// beside it, the body indented to the title's column, and a footer of [DialogButton]s laid
/// out here: outlined secondaries, then the destructive (outlined risk) action, then the one
/// filled primary, all one height, right-aligned. When they do not fit on one line they stack
/// full width, the primary on top. Bottom sheets are not dialogs and keep their own look.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../trust_ids.dart';
import 'common.dart' show DangerButton;
import 'theme/dialog_metrics.dart';
import 'theme/epic1_mark.dart';
import 'theme/tokens.dart';

export 'theme/dialog_metrics.dart' show DialogWidth;

/// The tile's colour: a dialog about a problem or a destructive step says so in its tile, and
/// in its words; never by colour alone.
enum DialogTone { neutral, info, ok, warn, risk }

/// Opens an [AppDialog] (or any widget) over the scrim. Returns what the dialog pops.
Future<T?> showAppDialog<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) =>
    showDialog<T>(context: context, barrierDismissible: dismissible, builder: builder);

/// A question with one answer: [cancelLabel] (the outlined secondary) or [confirmLabel] (the
/// filled primary, or with [risk] the outlined risk style). True only for the confirm; closing
/// the dialog is false.
Future<bool> confirmAppDialog(
  BuildContext context, {
  required String title,
  required IconData icon,
  DialogTone tone = DialogTone.neutral,
  String? description,
  Widget? body,
  required String cancelLabel,
  required String confirmLabel,
  bool risk = false,
  Key? confirmKey,
  Key? cancelKey,
  String? confirmId,
}) async {
  final yes = await showAppDialog<bool>(
    context,
    builder: (context) => AppDialog(
      title: title,
      icon: icon,
      tone: tone,
      description: description,
      body: body,
      actions: [
        DialogButton.secondary(key: cancelKey, label: cancelLabel, onPressed: () => Navigator.pop(context, false)),
        risk
            ? DialogButton.risk(key: confirmKey, label: confirmLabel, semanticsId: confirmId, onPressed: () => Navigator.pop(context, true))
            : DialogButton.primary(key: confirmKey, label: confirmLabel, semanticsId: confirmId, onPressed: () => Navigator.pop(context, true)),
      ],
    ),
  );
  return yes == true;
}

/// A message to read: one outlined [closeLabel] (Done, OK, Close), never gold.
Future<void> tellAppDialog(
  BuildContext context, {
  required String title,
  required IconData icon,
  DialogTone tone = DialogTone.neutral,
  String? description,
  Widget? body,
  required String closeLabel,
}) => showAppDialog<void>(
  context,
  builder: (context) => AppDialog(
    title: title,
    icon: icon,
    tone: tone,
    description: description,
    body: body,
    actions: [DialogButton.secondary(label: closeLabel, onPressed: () => Navigator.pop(context))],
  ),
);

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.icon,
    this.tone = DialogTone.neutral,
    this.description,
    this.body,
    this.actions = const [],
    this.size = DialogWidth.standard,
    this.stackActions = false,
  });

  final String title;

  /// The tile's glyph; the [tone]'s own when null.
  final IconData? icon;
  final DialogTone tone;

  /// One or two sentences under the title, in the dim colour.
  final String? description;

  /// What follows, in the title's column; scrolls when the screen is short.
  final Widget? body;

  /// [DialogButton]s in any order (the footer orders them), or other widgets kept in place
  /// among the secondaries.
  final List<Widget> actions;
  final DialogWidth size;

  /// Always stacked full width, in the given order (a list of choices with lines between
  /// them, as the cancel choices).
  final bool stackActions;

  static IconData toneIcon(DialogTone tone) => switch (tone) {
    DialogTone.ok => Icons.check_circle_outline,
    DialogTone.warn => Icons.warning_amber_outlined,
    DialogTone.risk => Icons.error_outline,
    DialogTone.info || DialogTone.neutral => Icons.info_outline,
  };

  /// The footer's order: secondaries as given, the destructive action, the primary last;
  /// only the last primary is filled.
  static List<Widget> footer(List<Widget> actions) {
    int rank(Widget w) => w is DialogButton
        ? switch (w.kind) {
            DialogButtonKind.primary => 2,
            DialogButtonKind.risk => 1,
            DialogButtonKind.secondary => 0,
          }
        : 0;
    final ordered = [for (var i = 0; i < actions.length; i++) (i, actions[i])]
      ..sort((a, b) {
        final r = rank(a.$2).compareTo(rank(b.$2));
        return r != 0 ? r : a.$1.compareTo(b.$1);
      });
    final lastPrimary = ordered.lastIndexWhere((e) => rank(e.$2) == 2);
    return [
      for (var i = 0; i < ordered.length; i++)
        if (rank(ordered[i].$2) == 2 && i != lastPrimary)
          (ordered[i].$2 as DialogButton)._as(DialogButtonKind.secondary)
        else
          ordered[i].$2,
    ];
  }

  /// 18 px, or smaller (16, then 14) when the title's longest word (a host) would not fit its
  /// column, so a host never breaks mid-word on a narrow phone. Measured from the screen: an
  /// AlertDialog sizes its title intrinsically, so no LayoutBuilder.
  TextStyle? _fitTitle(BuildContext context, TextStyle? base) {
    if (base == null) return null;
    final media = MediaQuery.of(context);
    final line = math.min(media.size.width - 2 * _inset, DialogMetrics.widthOf(size)) - 2 * DialogMetrics.pad - DialogMetrics.bodyIndent;
    final longest = title.split(' ').reduce((a, b) => a.length >= b.length ? a : b);
    for (final px in const [18.0, 16.0]) {
      final style = base.copyWith(fontSize: px);
      final painter = TextPainter(
        text: TextSpan(text: longest, style: style),
        textDirection: Directionality.of(context),
        textScaler: media.textScaler,
        maxLines: 1,
      )..layout();
      final fits = painter.width <= line;
      painter.dispose();
      if (fits) return style;
    }
    return base.copyWith(fontSize: 14);
  }

  static const double _inset = 20;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final (iconColor, tileFill) = switch (tone) {
      DialogTone.ok => (t.ok, t.okSoft),
      DialogTone.warn => (t.warn, t.warnSoft),
      DialogTone.risk => (t.risk, t.riskSoft),
      DialogTone.info => (t.info, t.infoSoft),
      DialogTone.neutral => (t.dim, Colors.transparent),
    };
    const pad = DialogMetrics.pad;
    final titleStyle = _fitTitle(context, theme.textTheme.titleMedium?.copyWith(height: 1.3, color: t.text));
    final descStyle = theme.textTheme.bodyMedium?.copyWith(color: t.dim);
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: DialogMetrics.iconTile,
          height: DialogMetrics.iconTile,
          decoration: BoxDecoration(
            color: tileFill,
            borderRadius: BorderRadius.circular(t.radiusSmall),
            border: Border.all(color: t.lineStrong),
          ),
          child: Icon(icon ?? toneIcon(tone), size: DialogMetrics.icon, color: iconColor),
        ),
        const SizedBox(width: DialogMetrics.titleGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: description == null ? DialogMetrics.iconTile : 0),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Semantics(header: true, child: Epic1Text(title, style: titleStyle)),
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: DialogMetrics.descriptionGap),
                Text(description!, style: descStyle),
              ],
            ],
          ),
        ),
      ],
    );
    final footer = actions.isEmpty
        ? null
        : stackActions
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: actions)
        : _FooterBar(gap: DialogMetrics.actionGap, runGap: DialogMetrics.actionRunGap, children: AppDialog.footer(actions));
    // Built on AlertDialog: its route semantics, its scrolling of title and body together
    // above the pinned footer, and the type finders tests and the tour use.
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: _inset, vertical: 24),
      constraints: BoxConstraints(minWidth: 280, maxWidth: DialogMetrics.widthOf(size)),
      semanticLabel: title,
      scrollable: true,
      titlePadding: const EdgeInsets.fromLTRB(pad, pad, pad, 0),
      title: header,
      contentPadding: body == null
          ? EdgeInsets.zero
          : const EdgeInsetsDirectional.fromSTEB(pad + DialogMetrics.bodyIndent, DialogMetrics.bodyGap, pad, 0),
      contentTextStyle: theme.textTheme.bodyMedium?.copyWith(color: t.text),
      content: body,
      actionsPadding: const EdgeInsets.all(pad),
      actions: [footer ?? const SizedBox.shrink()],
    );
  }
}

enum DialogButtonKind {
  /// Outlined, neutral: Cancel, Keep, Not now, Close.
  secondary,

  /// Filled gold: the affirmative action. One per dialog.
  primary,

  /// Outlined in the risk colour: cancel a payment, delete, remove.
  risk,
}

/// The phone's dialog button: one recipe for the three kinds, the platform's control height,
/// and the one disabled look (theme/tokens.dart). [busy] shows a small spinner and ignores
/// presses. Use it on screens too wherever the same three kinds apply.
class DialogButton extends StatelessWidget {
  const DialogButton.secondary({super.key, required this.label, required this.onPressed, this.icon, this.busy = false, this.semanticsId})
    : kind = DialogButtonKind.secondary;

  const DialogButton.primary({super.key, required this.label, required this.onPressed, this.icon, this.busy = false, this.semanticsId})
    : kind = DialogButtonKind.primary;

  const DialogButton.risk({super.key, required this.label, required this.onPressed, this.icon, this.busy = false, this.semanticsId})
    : kind = DialogButtonKind.risk;

  const DialogButton._({super.key, required this.kind, required this.label, required this.onPressed, this.icon, this.busy = false, this.semanticsId});

  final DialogButtonKind kind;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  /// The test drivers' stable name for this button ([TrustIds]).
  final String? semanticsId;

  DialogButton _as(DialogButtonKind k) => DialogButton._(key: key, kind: k, label: label, onPressed: onPressed, icon: icon, busy: busy, semanticsId: semanticsId);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final pressed = busy ? null : onPressed;
    final minimum = Size(64, t.controlHeight);
    final lead = busy
        ? SizedBox.square(
            dimension: 18,
            child: MediaQuery.disableAnimationsOf(context)
                ? const Icon(Icons.hourglass_empty, size: 18)
                : const CircularProgressIndicator(strokeWidth: 2),
          )
        : (icon == null ? null : Icon(icon, size: 18));
    final text = TrustId(semanticsId, child: Text(label, textAlign: TextAlign.center));
    switch (kind) {
      case DialogButtonKind.primary:
        final style = FilledButton.styleFrom(minimumSize: minimum);
        return lead == null
            ? FilledButton(style: style, onPressed: pressed, child: text)
            : FilledButton.icon(style: style, onPressed: pressed, icon: lead, label: text);
      case DialogButtonKind.secondary:
        final style = OutlinedButton.styleFrom(minimumSize: minimum);
        return lead == null
            ? OutlinedButton(style: style, onPressed: pressed, child: text)
            : OutlinedButton.icon(style: style, onPressed: pressed, icon: lead, label: text);
      case DialogButtonKind.risk:
        // The app's one destructive look (common.dart), as on screens.
        return lead == null
            ? DangerButton(onPressed: pressed, child: text)
            : DangerButton.icon(onPressed: pressed, icon: lead, label: text);
    }
  }
}

/// A tick box with its label in a dialog's body: body text, the box on the body's start edge,
/// the whole row the touch target (at least 44 tall).
class DialogCheckRow extends StatelessWidget {
  const DialogCheckRow({super.key, required this.value, required this.onChanged, required this.label});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: onChanged == null ? t.faint : t.text);
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        borderRadius: BorderRadius.circular(t.radiusSmall),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: DialogMetrics.checkRow),
          child: Row(
            children: [
              SizedBox.square(
                dimension: DialogMetrics.checkBox,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: DialogMetrics.checkGap),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(label, style: style),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line, right-aligned, when the buttons fit; otherwise stacked full width with the last
/// (the primary) on top.
class _FooterBar extends MultiChildRenderObjectWidget {
  const _FooterBar({required this.gap, required this.runGap, required super.children});

  final double gap;
  final double runGap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFooterBar(gap: gap, runGap: runGap, direction: Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderFooterBar renderObject) {
    renderObject
      ..gap = gap
      ..runGap = runGap
      ..direction = Directionality.of(context);
  }
}

class _FooterParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderFooterBar extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _FooterParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _FooterParentData> {
  _RenderFooterBar({required this._gap, required this._runGap, required this._direction});

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  double _runGap;
  set runGap(double v) {
    if (v == _runGap) return;
    _runGap = v;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection v) {
    if (v == _direction) return;
    _direction = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FooterParentData) child.parentData = _FooterParentData();
  }

  List<RenderBox> get _kids {
    final out = <RenderBox>[];
    var c = firstChild;
    while (c != null) {
      out.add(c);
      c = childAfter(c);
    }
    return out;
  }

  double _rowWidth(List<RenderBox> kids) =>
      kids.fold<double>(0, (w, c) => w + c.getMaxIntrinsicWidth(double.infinity)) + _gap * math.max(0, kids.length - 1);

  @override
  double computeMinIntrinsicWidth(double height) => _kids.fold(0, (w, c) => math.max(w, c.getMinIntrinsicWidth(height)));

  @override
  double computeMaxIntrinsicWidth(double height) => _rowWidth(_kids);

  @override
  Size computeDryLayout(BoxConstraints constraints) => _layout(constraints, dry: true);

  @override
  void performLayout() => size = _layout(constraints, dry: false);

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final kids = _kids;
    if (kids.isEmpty) return constraints.smallest;
    final maxW = constraints.maxWidth;
    if (_rowWidth(kids) <= maxW) {
      final sizes = [
        for (final c in kids)
          dry ? c.getDryLayout(const BoxConstraints()) : (c..layout(const BoxConstraints(), parentUsesSize: true)).size,
      ];
      final h = sizes.fold<double>(0, (m, s) => math.max(m, s.height));
      final total = sizes.fold<double>(0, (w, s) => w + s.width) + _gap * (kids.length - 1);
      final width = constraints.hasBoundedWidth ? maxW : total;
      if (!dry) {
        // Right-aligned (the end edge), in order, each centred on the line.
        final ltr = _direction == TextDirection.ltr;
        var x = ltr ? width - total : total;
        for (var i = 0; i < kids.length; i++) {
          final s = sizes[i];
          final left = ltr ? x : x - s.width;
          (kids[i].parentData! as _FooterParentData).offset = Offset(left, (h - s.height) / 2);
          x = ltr ? x + s.width + _gap : x - s.width - _gap;
        }
      }
      return constraints.constrain(Size(width, h));
    }
    // Stacked: full width, the last one (the primary) on top.
    final child = BoxConstraints.tightFor(width: maxW);
    var y = 0.0;
    for (final c in kids.reversed) {
      final s = dry ? c.getDryLayout(child) : (c..layout(child, parentUsesSize: true)).size;
      if (!dry) (c.parentData! as _FooterParentData).offset = Offset(0, y);
      y += s.height + _runGap;
    }
    return constraints.constrain(Size(maxW, y - _runGap));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => defaultHitTestChildren(result, position: position);
}
