import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/kit.dart';
import 'settings_frame.dart';

/// One row of [ServiceCombo].
class ComboOption {
  const ComboOption({
    required this.value,
    required this.host,
    this.sub,
    this.isDefault = false,
    this.tone = ETone.ok,
    this.word,
    this.height,
    this.tip,
    this.group,
    this.icon,
    this.actions = const [],
  });

  final String value;

  /// Shown in mono; what the filter matches with [sub].
  final String host;

  /// Operator or label, muted after the host.
  final String? sub;

  /// The factory default: a tiny muted "default" instead of [sub].
  final bool isDefault;
  final ETone tone;

  /// A state word after the host, only when it is not online ("Not responding").
  final String? word;
  final int? height;

  /// Response time and uptime: in the row's tooltip only.
  final String? tip;
  final String? group;

  /// Instead of the status dot (the built-in node's monitor).
  final IconData? icon;

  /// Small icon buttons at the row's end (☆ add to My nodes, ✎ edit).
  final List<Widget> actions;

  bool matches(String q) => '$host ${sub ?? ''}'.toLowerCase().contains(q);
}

/// The node and Epicbox field of Settings (6.1.6 NodeCombo / EpicboxCombo): a text field that
/// shows the server in use and opens the list under it. Typing filters the list; a typed
/// address that is not listed is offered first ([typedRow]). A pick, or Enter on a typed
/// address or on the only match, calls [onPicked]. ↓ moves into the list, Esc closes it.
/// While [busy] the field says [busyLabel] beside the server and the chevron stays; after
/// [busyTimeout] it says "No answer yet" and the field works again.
class ServiceCombo extends StatefulWidget {
  const ServiceCombo({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.value,
    required this.fieldText,
    required this.onPicked,
    this.fieldSub,
    this.tone = ETone.ok,
    this.typedRow,
    this.typedNote,
    this.onTyped,
    this.listNote,
    this.emptyNote = 'Nothing to show.',
    this.busy = false,
    this.busyLabel = 'Checking…',
    this.busyTimeout = const Duration(seconds: 20),
    this.error,
    this.footer = const [],
    this.openInitially = false,
    this.initialQuery,
  });

  final String label;
  final String hint;
  final List<ComboOption> options;

  /// The value in use.
  final String value;

  /// What the field shows when not typing: the host in use.
  final String fieldText;
  final String? fieldSub;
  final ETone tone;
  final ValueChanged<String> onPicked;

  /// The row for a typed text that is not listed, or null when it is not an address.
  final ComboOption? Function(String typed)? typedRow;
  final String? Function(String typed)? typedNote;

  /// Every edit of the field's text (the node page checks a typed address live).
  final ValueChanged<String>? onTyped;
  final String? listNote;
  final String emptyNote;
  final bool busy;
  final String busyLabel;
  final Duration busyTimeout;

  /// Under the field (a failed pick); the field keeps the typed text.
  final String? error;

  /// Rows after the list: (label, icon, action).
  final List<(String, IconData, VoidCallback)> footer;
  final bool openInitially;
  final String? initialQuery;

  @override
  State<ServiceCombo> createState() => ServiceComboState();
}

class ServiceComboState extends State<ServiceCombo> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _field = FocusNode(debugLabel: 'combo field');
  final _listScope = FocusScopeNode(debugLabel: 'combo list');
  final _group = Object();
  late final _text = TextEditingController(text: widget.fieldText);
  bool _editing = false;
  double _width = 400;
  Timer? _busyTimer;

  /// The check outlived [ServiceCombo.busyTimeout]: the field works again.
  bool _slow = false;

  bool get _busy => widget.busy && !_slow;

  String get _q => _editing ? _text.text.trim().toLowerCase().replaceFirst(RegExp('^https?://'), '').replaceFirst(RegExp(r'/+$'), '') : '';

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuery;
    if (q != null) {
      _text.text = q;
      _editing = true;
    }
    if (widget.busy) _startBusy();
    if (widget.openInitially || q != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(_portal.show);
      });
    }
  }

  @override
  void didUpdateWidget(ServiceCombo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.fieldText != widget.fieldText) _show(widget.fieldText);
    if (widget.busy && !oldWidget.busy) _startBusy();
    if (!widget.busy && oldWidget.busy) {
      _busyTimer?.cancel();
      _slow = false;
    }
  }

  void _startBusy() {
    _slow = false;
    _busyTimer?.cancel();
    _busyTimer = Timer(widget.busyTimeout, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  /// Shows [t] with the cursor at its end: the host never paints as selected text.
  void _show(String t) => _text.value = TextEditingValue(
    text: t,
    selection: TextSelection.collapsed(offset: t.length),
  );

  @override
  void dispose() {
    _busyTimer?.cancel();
    _field.dispose();
    _listScope.dispose();
    _text.dispose();
    super.dispose();
  }

  void _open() {
    if (_busy || _portal.isShowing) return;
    setState(_portal.show);
  }

  /// Back to showing the server in use.
  void collapse() {
    if (!mounted) return;
    setState(() {
      _portal.hide();
      _editing = false;
      _show(widget.fieldText);
    });
  }

  /// After a failed pick: the typed text stays in the field.
  void keepTyped(String text) {
    setState(() {
      _editing = true;
      _show(text);
    });
  }

  void _pick(String v) {
    if (_busy) return;
    final typed = _text.text.trim();
    setState(() => _portal.hide());
    _field.requestFocus();
    if (v == widget.value) {
      collapse();
      return;
    }
    _editing = false;
    _show(v == typed ? typed : widget.fieldText);
    widget.onPicked(v);
  }

  List<ComboOption> get _shown => [
    for (final o in widget.options)
      if (_q.isEmpty || o.matches(_q)) o,
  ];

  ComboOption? get _typed {
    final t = _editing ? _text.text.trim() : '';
    if (t.isEmpty || widget.typedRow == null) return null;
    if (widget.options.any((o) => o.value == t || o.host == _q)) return null;
    return widget.typedRow!(t);
  }

  void _enter() {
    if (!_portal.isShowing) return _open();
    final typed = _typed;
    if (typed != null) return _pick(typed.value);
    final shown = _shown;
    if (shown.length == 1) _pick(shown.first.value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final open = _portal.isShowing;
    final field = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          _open();
          WidgetsBinding.instance.addPostFrameCallback((_) => _listScope.nextFocus());
        },
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        // Esc closes the list or drops the typing; with neither it goes on up (a dialog).
        onKeyEvent: (_, e) {
          if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.escape || !(_portal.isShowing || _editing)) return KeyEventResult.ignored;
          collapse();
          return KeyEventResult.handled;
        },
        child: Semantics(
          textField: true,
          label: widget.label,
          expanded: open,
          child: Container(
            height: Ctl.md,
            padding: EdgeInsets.only(left: Sp.x3, right: Sp.x1),
            decoration: BoxDecoration(
              color: c.s2,
              borderRadius: BorderRadius.circular(Rad.sm),
              border: Border.all(color: widget.error != null ? c.risk : (open ? c.accent : c.lineField)),
            ),
            child: Row(
              children: [
                EStatusDot(_editing && _typed != null ? _typed!.tone : widget.tone),
                SizedBox(width: Sp.x3),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _text,
                    focusNode: _field,
                    readOnly: _busy,
                    // A focus gain (after a pick, Esc or Tab) never selects the host.
                    selectAllOnFocus: false,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: ts.mono(size: Fs.md, color: c.text),
                    cursorColor: c.accent,
                    decoration: InputDecoration.collapsed(
                      hintText: widget.hint,
                      hintStyle: ts.body.copyWith(color: c.faint),
                    ),
                    onTap: _open,
                    onChanged: (t) {
                      setState(() {
                        _editing = true;
                        _portal.show();
                      });
                      widget.onTyped?.call(t.trim());
                    },
                    onSubmitted: (_) {
                      _enter();
                      _field.requestFocus();
                    },
                  ),
                ),
                if (widget.busy) ...[
                  SizedBox(width: Sp.x2),
                  if (!_slow) ...[ESpinner(size: Ctl.iconSm), SizedBox(width: Sp.x2)],
                  Flexible(
                    flex: 1,
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _slow ? 'No answer yet' : widget.busyLabel,
                        style: ts.small.copyWith(color: _slow ? c.warn : c.dim),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ] else if (!_editing && widget.fieldSub != null) ...[
                  SizedBox(width: Sp.x2),
                  Flexible(
                    flex: 1,
                    child: Text(
                      widget.fieldSub!,
                      style: ts.small.copyWith(color: c.faint),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
                SizedBox(width: Sp.x1),
                // The chevron stays while a check runs; the list opens again once it ends.
                ExcludeFocus(
                  child: EIconButton(
                    icon: EIcons.chevronDown,
                    label: widget.label,
                    size: EBtnSize.inline,
                    onPressed: () {
                      if (open) {
                        collapse();
                      } else {
                        _open();
                        _field.requestFocus();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return TapRegion(
      groupId: _group,
      // A click outside only closes the list: it does not also press what is under it.
      consumeOutsideTaps: open,
      onTapOutside: (_) {
        if (_portal.isShowing) collapse();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              _width = box.maxWidth;
              return CompositedTransformTarget(
                link: _link,
                child: OverlayPortal(controller: _portal, overlayChildBuilder: _list, child: field),
              );
            },
          ),
          if (widget.error != null) ...[
            SizedBox(height: 6.u),
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(EIcons.error, size: Ctl.iconSm, color: c.risk),
                  ),
                  SizedBox(width: 6.u),
                  Expanded(
                    child: Text(widget.error!, style: ts.small.copyWith(color: c.risk)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _list(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final typed = _typed;
    final shown = _shown;
    final note = typed != null && widget.typedNote != null ? widget.typedNote!(_text.text.trim()) : null;
    final children = <Widget>[];
    if (typed != null) {
      children.add(_row(context, typed));
      if (note != null) children.add(_note(context, note));
    }
    String? lastGroup;
    for (final o in shown) {
      if (o.group != null && o.group != lastGroup) {
        children.add(
          Padding(
            padding: EdgeInsets.fromLTRB(Sp.x3, Sp.x3, Sp.x3, Sp.x1),
            child: ExcludeSemantics(
              child: Text(o.group!.toUpperCase(), style: ts.caption.copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w600)),
            ),
          ),
        );
      }
      lastGroup = o.group;
      children.add(_row(context, o));
    }
    if (typed == null && shown.isEmpty) children.add(_note(context, widget.emptyNote));
    if (widget.listNote != null) children.add(_note(context, widget.listNote!));
    for (var i = 0; i < widget.footer.length; i++) {
      final (label, icon, run) = widget.footer[i];
      if (i == 0) children.add(Divider(height: Sp.x3, color: c.line));
      children.add(
        InkWell(
          onTap: () {
            collapse();
            run();
          },
          borderRadius: BorderRadius.circular(Rad.sm),
          child: Container(
            height: 40.u,
            padding: EdgeInsets.symmetric(horizontal: Sp.x3),
            child: Row(
              children: [
                Icon(icon, size: Ctl.iconSm, color: c.accentText),
                SizedBox(width: Sp.x2),
                Text(label, style: ts.body.copyWith(color: c.accentText)),
              ],
            ),
          ),
        ),
      );
    }
    return CompositedTransformFollower(
      link: _link,
      targetAnchor: Alignment.bottomLeft,
      offset: Offset(0, Sp.x1),
      child: Align(
        alignment: Alignment.topLeft,
        child: TapRegion(
          groupId: _group,
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () {
                collapse();
                _field.requestFocus();
              },
              const SingleActivator(LogicalKeyboardKey.arrowDown): () => _listScope.nextFocus(),
              const SingleActivator(LogicalKeyboardKey.arrowUp): () => _listScope.previousFocus(),
            },
            child: FocusScope(
              node: _listScope,
              child: Material(
                color: c.s4,
                elevation: 8,
                shadowColor: c.scrim,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Rad.sm),
                  side: BorderSide(color: c.lineStrong),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: _width, minWidth: _width, maxHeight: 420.u),
                  child: Semantics(
                    label: widget.label,
                    child: ListView(padding: EdgeInsets.all(Sp.x2), shrinkWrap: true, children: children),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _note(BuildContext context, String text) => Padding(
    padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
    child: Text(text, style: context.ts.caption),
  );

  Widget _row(BuildContext context, ComboOption o) {
    final c = context.dc;
    final ts = context.ts;
    final selected = o.value == widget.value;
    final row = InkWell(
      onTap: () => _pick(o.value),
      borderRadius: BorderRadius.circular(Rad.sm),
      focusColor: c.s3,
      hoverColor: c.s3,
      child: Container(
        constraints: BoxConstraints(minHeight: 40.u),
        padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: 6.u),
        decoration: BoxDecoration(color: selected ? c.s3 : null, borderRadius: BorderRadius.circular(Rad.sm)),
        child: Row(
          children: [
            SizedBox(
              width: Ctl.iconSm,
              child: o.icon != null ? Icon(o.icon, size: Ctl.iconSm, color: c.dim) : Center(child: EStatusDot(o.tone)),
            ),
            SizedBox(width: Sp.x2),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: o.host,
                      style: o.icon != null ? ts.body : ts.mono(size: Fs.sm, color: c.text),
                    ),
                    if (o.word != null)
                      TextSpan(
                        text: '  ${o.word}',
                        style: ts.caption.copyWith(color: o.tone == ETone.risk ? c.risk : c.warn),
                      ),
                    if (o.isDefault)
                      TextSpan(text: '  default', style: ts.caption)
                    else if (o.sub != null)
                      TextSpan(
                        text: '  ${o.sub}',
                        style: ts.small.copyWith(color: c.faint),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (o.height != null) ...[
              SizedBox(width: Sp.x2),
              Text(
                groupDigits(o.height!),
                style: ts.mono(size: Fs.xs, color: c.dim),
              ),
            ],
            ...o.actions,
            SizedBox(
              width: Ctl.iconSm + Sp.x1,
              child: selected
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Icon(EIcons.check, size: Ctl.iconSm, color: c.accentText),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: 'Use ${o.host}${o.sub != null ? ', ${o.sub}' : ''}${o.word != null ? ', ${o.word}' : ''}',
      child: o.tip == null ? row : Tooltip(message: o.tip!, waitDuration: const Duration(milliseconds: 500), child: row),
    );
  }
}
