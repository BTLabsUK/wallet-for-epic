import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'tx_display.dart';

/// Where a label is being edited: the payment's [key] and the [place] on screen (the Activity
/// row or the details title), so the same payment can be open in both and only one field is.
typedef TxLabelSite = ({String key, String place});

/// Which inline label field is open, if any. Opening another one saves the first (its field
/// sees the change and commits).
class TxLabelEditing extends Notifier<TxLabelSite?> {
  @override
  TxLabelSite? build() => null;

  void open(String key, String place) => state = (key: key, place: place);

  /// Closes the field of [key] at [place]; a field another place opened meanwhile stays.
  void close(String key, String place) {
    if (state == (key: key, place: place)) state = null;
  }
}

final txLabelEditingProvider = NotifierProvider<TxLabelEditing, TxLabelSite?>(TxLabelEditing.new);

const String txLabelRowPlace = 'row';
const String txLabelDetailPlace = 'detail';

/// Saves [text] as [t]'s label (empty removes it) and says so; nothing when it did not change.
/// [context] must outlive the field (the row or the details, not the field itself).
Future<void> saveTxLabel(BuildContext context, WidgetRef ref, Tx t, String text) async {
  final l = context.l10n;
  final next = text.trim();
  final was = t.labelText ?? '';
  if (next == was) return;
  try {
    await ref.read(deskProvider.notifier).setTxLabel(t.key, next.isEmpty ? null : next);
  } on Object catch (e) {
    if (context.mounted) showEToast(context, l.deskTxLabelNotSaved, text: deskErrorText(e, l), tone: ETone.risk);
    return;
  }
  if (!context.mounted) return;
  showEToast(context, was.isEmpty ? l.deskTxLabelAdded : (next.isEmpty ? l.deskTxLabelRemoved : l.deskTxLabelSaved), tone: ETone.ok);
}

/// The single-line field a label is typed in, in place of the title: [style]'s size, a gold
/// border. Enter, blur and a tap outside save; Esc restores the title. An empty field removes
/// the label. [onSave] gets the text; [onClose] runs once after, with whether a key ended it
/// (the host then gives the focus back to its pen).
class TxLabelField extends ConsumerStatefulWidget {
  const TxLabelField({super.key, required this.site, required this.initial, required this.style, required this.onSave, required this.onClose});

  final TxLabelSite site;
  final String initial;
  final TextStyle style;
  final ValueChanged<String> onSave;
  final void Function({required bool byKey}) onClose;

  @override
  ConsumerState<TxLabelField> createState() => _TxLabelFieldState();
}

class _TxLabelFieldState extends ConsumerState<TxLabelField> {
  late final TextEditingController _text = TextEditingController(text: widget.initial)..selection = TextSelection.collapsed(offset: widget.initial.length);
  final FocusNode _focus = FocusNode();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!_focus.hasFocus) _commit(byKey: false);
  }

  void _commit({required bool byKey}) {
    if (_done) return;
    _done = true;
    widget.onSave(_text.text);
    widget.onClose(byKey: byKey);
  }

  void _cancel() {
    if (_done) return;
    _done = true;
    widget.onClose(byKey: true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final l = context.l10n;
    // Another field was opened: this one saves.
    ref.listen(txLabelEditingProvider, (_, now) {
      if (now != widget.site) _commit(byKey: false);
    });
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          _cancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        label: l.deskTxLabelField,
        textField: true,
        child: TextField(
          controller: _text,
          focusNode: _focus,
          autofocus: true,
          maxLength: txLabelMaxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          textInputAction: TextInputAction.done,
          style: widget.style,
          cursorColor: c.accent,
          onSubmitted: (_) => _commit(byKey: true),
          onEditingComplete: () {},
          onTapOutside: (_) => _focus.unfocus(),
          decoration: InputDecoration(
            isDense: true,
            counterText: '',
            hintText: l.deskTxLabelHint,
            hintStyle: widget.style.copyWith(color: c.faint, fontWeight: FontWeight.w400),
            contentPadding: EdgeInsets.symmetric(horizontal: Sp.x2, vertical: 5.u),
            filled: true,
            fillColor: c.s2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(Rad.xs), borderSide: BorderSide(color: c.accent)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Rad.xs), borderSide: BorderSide(color: c.accent)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Rad.xs), borderSide: BorderSide(color: c.accent)),
          ),
        ),
      ),
    );
  }
}

/// The pen beside a title: "Add label" or "Edit label". A Tab stop with a visible focus ring;
/// [visible] false hides it until it has the focus (an Activity row shows it on hover or when
/// anything in the row has the focus). Its own screen-reader node, so a row's one sentence
/// does not swallow it.
class TxPen extends StatefulWidget {
  const TxPen({super.key, required this.tx, required this.onPressed, this.visible = true, this.focusNode});

  final Tx tx;
  final VoidCallback onPressed;
  final bool visible;
  final FocusNode? focusNode;

  @override
  State<TxPen> createState() => _TxPenState();
}

class _TxPenState extends State<TxPen> {
  bool _hover = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final l = context.l10n;
    final label = widget.tx.labelText == null ? l.deskTxLabelAdd : l.deskTxLabelEdit;
    return Opacity(
      opacity: widget.visible || _focused || _hover ? 1 : 0,
      // Hidden is only a look: a screen reader and the Tab key still find the pen.
      alwaysIncludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Semantics(
          container: true,
          button: true,
          label: label,
          onTap: widget.onPressed,
          excludeSemantics: true,
          child: FocusableActionDetector(
            focusNode: widget.focusNode,
            mouseCursor: SystemMouseCursors.click,
            onShowHoverHighlight: (v) => setState(() => _hover = v),
            onShowFocusHighlight: (v) => setState(() => _focused = v),
            actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed())},
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onPressed,
              child: FocusRing(
                focused: _focused,
                child: Container(
                  width: Ctl.inline,
                  height: Ctl.inline,
                  decoration: BoxDecoration(color: _hover ? c.hover : Colors.transparent, borderRadius: BorderRadius.circular(Rad.sm)),
                  child: Icon(EIcons.pencil, size: Ctl.iconSm, color: _hover || _focused ? c.text : c.faint),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Added by you", with a pen: on a value the user typed. The tooltip says when, and for the
/// sender that it is not verified. [field] picks the tooltip.
class ManualTag extends StatelessWidget {
  const ManualTag(this.tx, this.field, {super.key});

  final Tx tx;
  final ManualField field;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final at = tx.manualEditedAt;
    final from = field == ManualField.counterparty;
    final tip = at == null
        ? (from ? l.deskTxManualTipFromNoDate : l.deskTxManualTipNoDate)
        : (from ? l.deskTxManualTipFrom(shortDay(l, at)) : l.deskTxManualTip(shortDay(l, at)));
    return Tooltip(
      message: tip,
      child: Semantics(label: '${l.deskTxManualTag}. $tip', excludeSemantics: true, child: EBadge(l.deskTxManualTag, icon: EIcons.pencil)),
    );
  }
}

/// The details panel's title: "Received transaction" until the payment has a label, then the
/// label with "Added by you"; the pen opens the same inline field as Activity's. Reads
/// [fallback] when there is no label.
class TxPanelTitle extends ConsumerStatefulWidget {
  const TxPanelTitle({super.key, required this.tx, required this.fallback});

  final Tx tx;
  final String fallback;

  @override
  ConsumerState<TxPanelTitle> createState() => _TxPanelTitleState();
}

class _TxPanelTitleState extends ConsumerState<TxPanelTitle> {
  final FocusNode _pen = FocusNode();

  @override
  void dispose() {
    _pen.dispose();
    super.dispose();
  }

  TxLabelSite get _site => (key: widget.tx.key, place: txLabelDetailPlace);

  void _close({required bool byKey}) {
    ref.read(txLabelEditingProvider.notifier).close(widget.tx.key, txLabelDetailPlace);
    if (byKey) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _pen.requestFocus() : null);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tx;
    final style = context.ts.h3;
    if (ref.watch(txLabelEditingProvider) == _site) {
      return TxLabelField(site: _site, initial: t.labelText ?? '', style: style, onSave: (text) => saveTxLabel(context, ref, t, text), onClose: _close);
    }
    final title = t.labelText ?? widget.fallback;
    // Two lines at most; the whole label is in the tooltip.
    return Row(
      children: [
        Flexible(
          child: Tooltip(
            message: title,
            child: Semantics(header: true, child: Text(title, style: style, maxLines: 2, overflow: TextOverflow.ellipsis)),
          ),
        ),
        SizedBox(width: Sp.x1),
        TxPen(tx: t, focusNode: _pen, onPressed: () => ref.read(txLabelEditingProvider.notifier).open(t.key, txLabelDetailPlace)),
        if (t.labelText != null) ...[SizedBox(width: Sp.x1), ManualTag(t, ManualField.label)],
      ],
    );
  }
}
