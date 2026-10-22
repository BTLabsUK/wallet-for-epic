import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/kit.dart';
import '../../widgets/server_row.dart';
import 'settings_frame.dart';

export '../../widgets/server_row.dart' show ServerInfo, ServerKind, neutralOrder;

/// One row of [ServiceCombo]: a server ([server], spec §18), the local node ([local]) or a
/// plain row (host, sub, word) for typed addresses and old callers.
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
    this.server,
    this.local = false,
    this.onStar,
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

  /// Instead of the status dot (the local node's monitor).
  final IconData? icon;

  /// Small icon buttons at the row's end (☆ add to My nodes, ✎ edit).
  final List<Widget> actions;

  /// The §18 row: bars, tip, latency, version, star.
  final ServerInfo? server;

  /// The This computer row: [host] is its name, [sub] its state text.
  final bool local;

  /// The star of a [server] row.
  final VoidCallback? onStar;

  bool matches(String q) => '$host ${sub ?? ''} ${server?.operator ?? ''}'.toLowerCase().contains(q);
}

/// The node and Epicbox field of Settings (6.1.6 NodeCombo / EpicboxCombo; spec §2.4): a
/// button that shows the server in use and opens the list under it, with a search field at
/// the top of the list. Typing filters; a typed address that is not listed is offered first
/// ([typedRow]). A pick, or Enter on a typed address or on the only match, calls [onPicked].
/// Click, Space, Enter or ↓ opens; ↓ moves into the list; Esc closes. The closed field never
/// holds a text field, so nothing is ever painted as selected (F27). While [busy] the field
/// says [busyLabel] beside the server and the chevron stays; after [busyTimeout] it says
/// "No answer yet" and the field works again.
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
    this.kind = ServerKind.relay,
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

  /// The search field's hint ("Find or type a node address").
  final String hint;
  final List<ComboOption> options;

  /// The value in use.
  final String value;

  /// What the field shows: the host in use.
  final String fieldText;
  final String? fieldSub;
  final ETone tone;

  /// Which columns the §18 rows show.
  final ServerKind kind;
  final ValueChanged<String> onPicked;

  /// The row for a typed text that is not listed, or null when it is not an address.
  final ComboOption? Function(String typed)? typedRow;
  final String? Function(String typed)? typedNote;

  /// Every edit of the search text (the node page checks a typed address live).
  final ValueChanged<String>? onTyped;
  final String? listNote;
  final String emptyNote;
  final bool busy;
  final String busyLabel;
  final Duration busyTimeout;

  /// Under the field (a failed pick); the list keeps the typed text.
  final String? error;

  /// Rows after the list: (label, icon, action).
  final List<(String, IconData, void Function(String typed))> footer;
  final bool openInitially;
  final String? initialQuery;

  @override
  State<ServiceCombo> createState() => ServiceComboState();
}

class ServiceComboState extends State<ServiceCombo> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _button = FocusNode(debugLabel: 'combo button');
  final _search = FocusNode(debugLabel: 'combo search');
  final _listScope = FocusScopeNode(debugLabel: 'combo list');
  final _group = Object();
  final _text = TextEditingController();
  double _width = 400;
  Timer? _busyTimer;

  /// The check outlived [ServiceCombo.busyTimeout]: the field works again.
  bool _slow = false;

  bool get _busy => widget.busy && !_slow;

  String get _q => _text.text.trim().toLowerCase().replaceFirst(RegExp('^https?://'), '').replaceFirst(RegExp(r'/+$'), '');

  /// The list is open.
  bool get isOpen => _portal.isShowing;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuery;
    if (q != null) _text.text = q;
    if (widget.busy) _startBusy();
    if (widget.openInitially || q != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _open();
      });
    }
  }

  @override
  void didUpdateWidget(ServiceCombo oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  @override
  void dispose() {
    _busyTimer?.cancel();
    _button.dispose();
    _search.dispose();
    _listScope.dispose();
    _text.dispose();
    super.dispose();
  }

  void _open() {
    if (_busy || _portal.isShowing || !mounted) return;
    setState(_portal.show);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _portal.isShowing) _search.requestFocus();
    });
  }

  /// Back to the closed button; the search text is dropped.
  void collapse() {
    if (!mounted) return;
    setState(() {
      _portal.hide();
      _text.clear();
    });
    _button.requestFocus();
  }

  /// After a failed pick: the list opens again with the typed text.
  void keepTyped(String text) {
    _text.text = text;
    _open();
    setState(() {});
  }

  void _pick(String v) {
    if (_busy) return;
    setState(() {
      _portal.hide();
      _text.clear();
    });
    _button.requestFocus();
    if (v == widget.value) return;
    widget.onPicked(v);
  }

  List<ComboOption> get _shown => [
    for (final o in widget.options)
      if (_q.isEmpty || o.matches(_q)) o,
  ];

  ComboOption? get _typed {
    final t = _text.text.trim();
    if (t.isEmpty || widget.typedRow == null) return null;
    if (widget.options.any((o) => o.value == t || o.host == _q)) return null;
    return widget.typedRow!(t);
  }

  void _enter() {
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
    final field = FocusableActionDetector(
      focusNode: _button,
      enabled: !_busy,
      mouseCursor: SystemMouseCursors.click,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowDown): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _open();
            return null;
          },
        ),
      },
      child: Builder(
        builder: (context) {
          final focused = _button.hasFocus;
          return Semantics(
            button: true,
            label: '${widget.label}: ${widget.fieldText}${widget.fieldSub != null ? ', ${widget.fieldSub}' : ''}',
            hint: 'Opens the list',
            expanded: open,
            excludeSemantics: true,
            child: InkWell(
              onTap: open ? collapse : _open,
              borderRadius: BorderRadius.circular(Rad.sm),
              child: Container(
                height: Ctl.sm,
                padding: EdgeInsets.only(left: Sp.x3, right: Sp.x2),
                decoration: BoxDecoration(
                  color: c.s2,
                  borderRadius: BorderRadius.circular(Rad.sm),
                  border: Border.all(color: widget.error != null ? c.risk : (open || focused ? c.accent : c.lineField)),
                ),
                child: Row(
                  children: [
                    EStatusDot(widget.tone, size: 8.u),
                    SizedBox(width: Sp.x3),
                    Flexible(
                      flex: 2,
                      child: Text(widget.fieldText, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: ts.mono(size: 13.u, color: c.text)),
                    ),
                    if (widget.busy) ...[
                      SizedBox(width: Sp.x2),
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
                    ] else if (widget.fieldSub != null) ...[
                      SizedBox(width: Sp.x2),
                      Flexible(
                        flex: 1,
                        child: Text(widget.fieldSub!, style: ts.caption.copyWith(color: c.dim), overflow: TextOverflow.ellipsis, maxLines: 1),
                      ),
                    ],
                    const Spacer(),
                    SizedBox(width: Sp.x2),
                    // The chevron stays while a check runs; the list opens again once it ends.
                    Icon(EIcons.chevronDown, size: 16.u, color: c.dim),
                  ],
                ),
              ),
            ),
          );
        },
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
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(EIcons.error, size: Ctl.iconSm, color: c.risk),
                  ),
                  SizedBox(width: 6.u),
                  Expanded(child: Text(widget.error!, style: ts.small.copyWith(color: c.risk))),
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
      if (o.group != null && o.group != lastGroup) children.add(ListGroupHead(o.group!));
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
            final typed = _text.text.trim();
            collapse();
            run(typed);
          },
          borderRadius: BorderRadius.circular(Rad.sm),
          child: Container(
            height: Ctl.sm,
            padding: EdgeInsets.symmetric(horizontal: 12.u),
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
    final search = Padding(
      padding: EdgeInsets.fromLTRB(Sp.x2, Sp.x2, Sp.x2, Sp.x1),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowDown): () => _listScope.nextFocus(),
        },
        child: EInput(
          controller: _text,
          focusNode: _search,
          hint: widget.hint,
          leading: EIcons.search,
          mono: true,
          semanticLabel: widget.hint,
          onChanged: (t) {
            setState(() {});
            widget.onTyped?.call(t.trim());
          },
          onSubmitted: (_) => _enter(),
        ),
      ),
    );
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
              const SingleActivator(LogicalKeyboardKey.escape): collapse,
            },
            child: Material(
              color: c.s4,
              elevation: 8,
              shadowColor: c.scrim,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Rad.sm),
                side: BorderSide(color: c.lineStrong),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _width, minWidth: _width, maxHeight: 440.u),
                child: Semantics(
                  label: widget.label,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      search,
                      Flexible(
                        child: CallbackShortcuts(
                          bindings: {
                            const SingleActivator(LogicalKeyboardKey.arrowDown): () => _listScope.nextFocus(),
                            const SingleActivator(LogicalKeyboardKey.arrowUp): () => _listScope.previousFocus(),
                          },
                          child: FocusScope(
                            node: _listScope,
                            child: ListView(padding: EdgeInsets.all(Sp.x2), shrinkWrap: true, children: children),
                          ),
                        ),
                      ),
                    ],
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
    padding: EdgeInsets.symmetric(horizontal: 12.u, vertical: Sp.x2),
    child: Text(text, style: context.ts.caption),
  );

  Widget _row(BuildContext context, ComboOption o) {
    final c = context.dc;
    final ts = context.ts;
    final selected = o.value == widget.value;
    if (o.local) return LocalNodeRow(stateText: o.sub ?? '', selected: selected, onTap: () => _pick(o.value));
    final server = o.server;
    if (server != null) {
      final row = ServerRow(kind: widget.kind, info: server, selected: selected, onTap: () => _pick(o.value), onStar: o.onStar);
      return o.tip == null ? row : Tooltip(message: o.tip!, waitDuration: const Duration(milliseconds: 500), child: row);
    }
    final row = InkWell(
      onTap: () => _pick(o.value),
      borderRadius: BorderRadius.circular(Rad.sm),
      focusColor: c.s3,
      hoverColor: c.s3,
      child: Container(
        constraints: BoxConstraints(minHeight: 36.u),
        padding: EdgeInsets.symmetric(horizontal: 12.u, vertical: 4.u),
        decoration: BoxDecoration(color: selected ? c.s3 : null, borderRadius: BorderRadius.circular(Rad.sm)),
        child: Row(
          children: [
            SizedBox(
              width: Ctl.iconSm,
              child: o.icon != null ? Icon(o.icon, size: Ctl.iconSm, color: c.dim) : Center(child: EStatusDot(o.tone)),
            ),
            SizedBox(width: 10.u),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: o.host, style: o.icon != null ? ts.body : ts.mono(size: Fs.sm, color: c.text)),
                    if (o.word != null) TextSpan(text: '  ${o.word}', style: ts.caption.copyWith(color: o.tone == ETone.risk ? c.risk : c.warn)),
                    if (o.isDefault)
                      TextSpan(text: '  default', style: ts.caption)
                    else if (o.sub != null)
                      TextSpan(text: '  ${o.sub}', style: ts.small.copyWith(color: c.faint)),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (o.height != null) ...[
              SizedBox(width: Sp.x2),
              Text(groupDigits(o.height!), style: ts.mono(size: Fs.xs, color: c.dim)),
            ],
            ...o.actions,
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
