/// A payment's label, edited in place: the pen, the one-line field that takes the title's
/// place, and the "Added by you" tag beside every value the user typed.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'theme/tokens.dart';

/// [raw] as a label is kept: one line of single spaces, empty when nothing is left.
String cleanLabel(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

/// The pen at the end of a title: a dim 48 dp target, "Add label" or "Edit label" for screen
/// readers.
class LabelPen extends StatelessWidget {
  const LabelPen({super.key, required this.hasLabel, required this.onPressed});

  final bool hasLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = hasLabel ? l.txLabelEdit : l.txLabelAdd;
    return Semantics(
      button: true,
      label: text,
      onTap: onPressed,
      excludeSemantics: true,
      child: IconButton(
        tooltip: text,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        padding: EdgeInsets.zero,
        icon: Icon(Icons.edit_outlined, size: 18, color: context.tokens.dim),
        onPressed: onPressed,
      ),
    );
  }
}

/// Shows [idle] until its `edit` callback is called, then a one-line field with the label in
/// the same place. Enter, Done, tapping elsewhere or leaving the screen saves; Esc puts the old
/// label back; an empty field removes it. At most one field has the focus, so opening another
/// saves the first.
class TxLabelEditor extends ConsumerStatefulWidget {
  const TxLabelEditor({
    super.key,
    required this.tx,
    required this.idle,
    this.style,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.wrap,
  });

  final TxEntry tx;

  /// What shows while the field is closed; call `edit` to open it.
  final Widget Function(BuildContext context, VoidCallback edit) idle;

  /// The text style of the field: the title's.
  final TextStyle? style;

  final EdgeInsetsGeometry padding;

  /// Puts the open field into its surroundings (an icon beside it), where [idle] has them.
  final Widget Function(Widget field)? wrap;

  @override
  ConsumerState<TxLabelEditor> createState() => _TxLabelEditorState();
}

class _TxLabelEditorState extends ConsumerState<TxLabelEditor> {
  final _controller = TextEditingController();
  late final FocusNode _focus = FocusNode(
    debugLabel: 'label',
    onKeyEvent: (_, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        _cancel();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
  )..addListener(_onFocus);
  bool _editing = false;

  // What saving needs, kept while the field is open: the screen may leave before it is saved.
  WalletSession? _session;
  late NoticeNotifier _notices;
  late HomeNotifier _home;
  late AppLocalizations _l;

  @override
  void dispose() {
    final pending = _editing ? _controller.text : null;
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    if (pending != null) unawaited(_save(pending));
    super.dispose();
  }

  void _onFocus() {
    if (_editing && !_focus.hasFocus) _commit();
  }

  void _edit() {
    _session = ref.read(sessionProvider);
    _notices = ref.read(noticeProvider.notifier);
    _home = ref.read(homeProvider.notifier);
    _l = context.l10n;
    final text = widget.tx.label ?? '';
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing) _focus.requestFocus();
    });
  }

  void _cancel() {
    if (!_editing) return;
    setState(() => _editing = false);
    _focus.unfocus();
  }

  void _commit() {
    if (!_editing) return;
    final text = _controller.text;
    setState(() => _editing = false);
    _focus.unfocus();
    unawaited(_save(text));
  }

  Future<void> _save(String raw) async {
    final session = _session;
    if (session == null) return;
    final label = cleanLabel(raw);
    final before = widget.tx.label ?? '';
    if (label == before) return;
    try {
      await session.setTxLabel(
        key: widget.tx.key,
        label: label.isEmpty ? null : label,
      );
    } catch (error) {
      _say(describeError(_l, error), NoticeLevel.error);
      return;
    }
    _say(
      label.isEmpty
          ? _l.txLabelRemovedNotice
          : before.isEmpty
          ? _l.txLabelAddedNotice
          : _l.txLabelSavedNotice,
      NoticeLevel.info,
    );
    try {
      await _home.reload();
    } catch (_) {
      // The list shows what it still has.
    }
  }

  /// A notice, unless the app's providers are gone already (the whole app closing).
  void _say(String text, NoticeLevel level) {
    try {
      _notices.show(text, level: level);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) return widget.idle(context, _edit);
    final l = context.l10n;
    final accent = context.tokens.accent;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: accent, width: 1.5),
    );
    final field = Semantics(
      label: l.txLabel,
      child: Center(
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          style: widget.style,
          maxLength: txLabelMaxLength,
          maxLines: 1,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => _commit(),
          onTapOutside: (_) => _focus.unfocus(),
          decoration: InputDecoration(
            isDense: true,
            counterText: '',
            hintText: l.txLabelHint,
            contentPadding: widget.padding,
            border: border,
            enabledBorder: border,
            focusedBorder: border,
          ),
        ),
      ),
    );
    return widget.wrap?.call(field) ?? field;
  }
}

/// The small "Added by you" tag: a pen and the words (or the pen alone, [compact]), with the day it was entered in its tooltip.
/// [from] says the value is a sender nobody checked.
class ManualTag extends StatelessWidget {
  const ManualTag({
    super.key,
    required this.editedAtUnix,
    this.from = false,
    this.compact = false,
  });

  /// [TxEntry.manualEditedAtUnix]; null when not known.
  final int? editedAtUnix;
  final bool from;

  /// Only the pen, for a row too narrow for the words; the tooltip and screen readers say them.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final at = editedAtUnix;
    final date = at == null ? null : formatDateTime(l, localTime(at));
    final tip = switch ((date, from)) {
      (null, false) => l.txManualTipNoDate,
      (null, true) => l.txManualTipFromNoDate,
      (final d?, false) => l.txManualTip(d),
      (final d?, true) => l.txManualTipFrom(d),
    };
    if (compact) {
      return Semantics(
        label: l.txManualTag,
        child: Icon(Icons.edit_outlined, size: 12, color: t.accentText),
      );
    }
    return Tooltip(
      message: tip,
      triggerMode: TooltipTriggerMode.tap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_outlined, size: 12, color: t.accentText),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              l.txManualTag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: t.accentText),
            ),
          ),
        ],
      ),
    );
  }
}
