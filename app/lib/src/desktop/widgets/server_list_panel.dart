// SPDX-License-Identifier: Apache-2.0
/// The one Node and Epicbox picker of the desktop (Settings › Node, Settings › Transactions,
/// Setup): a field-like button with the server in use that opens the kind's list under it
/// ([deskServerListProvider], shared with the phone's lists).
///
/// The panel's field starts empty; the server in use shows only in its row (the check) and on
/// the button. Typing filters the rows by host or operator. Add shows as soon as nothing
/// matches, and for a typed address that is not listed: it says plainly when the text is no
/// address, else tests the server ([ServerListPanel.onTest]), adds it and offers the switch at
/// the foot. Every row has a bin; the row in use refuses ("In use. Switch first."), others go
/// with Undo. "Restore removed servers" shows while a public server is removed. A picked Node
/// row switches at once and the foot says so; a picked Epicbox row asks first in a dialog, as
/// the address changes. In Setup ([ServerListPanel.chooseOnly]) a pick simply chooses.
///
/// Keyboard: Click, Space, Enter or ↓ opens; ↓/↑ move between the field and the rows; Enter
/// picks a row, or on the field picks the only match or adds; Delete removes the focused row;
/// Esc closes and focus goes back to the button. While [ServerListPanel.busy] the button says
/// [ServerListPanel.busyLabel]; after [ServerListPanel.busyTimeout] it says "No answer yet"
/// and works again.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../legacy/gui_rules.dart' show isPrivateHost;
import '../../net/tor_switch.dart' show TorSwitch;
import '../../net/lan_node_relay.dart' show allowPlainHttpNode, needsPlainHttpConsent;
import '../../net/local_address.dart' show isLocalNodeUrl;
import '../../node/node_info.dart' show compareVersions;
import '../../relay_directory.dart' show NodeHealthState;
import '../../ui/server_tile.dart';
import '../data/desk_node.dart' show nodeHost;
import '../data/server_lists.dart';
import '../desk_l10n.dart';
import 'kit.dart';
import 'server_row.dart' show digitsText;

/// What a row shows of one server; what the source does not know is null.
@immutable
class PanelServer {
  const PanelServer({
    required this.value,
    required this.host,
    this.operator,
    this.listedAs,
    this.icon,
    this.state,
    this.checking = false,
    this.behind,
    this.latencyMs,
    this.version,
    this.versionOld = false,
    this.isDefault = false,
  });

  /// A listed server nothing is known about yet.
  factory PanelServer.bare(ServerKind kind, String value) => PanelServer(value: value, host: panelHost(kind, value));

  /// What the list stores: the node URL or the relay label.
  final String value;

  /// Shown in mono: without the scheme.
  final String host;

  /// The row's operator text: the built-in name, else the label of an own node.
  final String? operator;

  /// The operator as the status site names it: the tile's initials.
  final String? listedAs;
  final ServerIcon? icon;

  /// Null when nothing is known: "Health unknown" (or "Checking…" while [checking]).
  final NodeHealthState? state;
  final bool checking;

  /// Blocks behind the highest tip of the list; 0 at the tip.
  final int? behind;
  final int? latencyMs;
  final String? version;
  final bool versionOld;

  /// The Epicbox default: a tag on its row.
  final bool isDefault;

  bool get down => state == NodeHealthState.down;

  /// A node on this computer or the local network ([isLocalNodeUrl]): the wallet's own check
  /// is its only state, and down reads "Not reachable from this computer".
  bool get local => isLocalNodeUrl(value);
}

/// A value without its scheme and trailing slash: what a row and the field show.
String panelHost(ServerKind kind, String value) =>
    kind == ServerKind.node ? value.replaceFirst(RegExp('^[a-z]+://'), '').replaceFirst(RegExp(r'/+$'), '') : value;

/// The rows of the wallet's node list: health from the wallet's own checks, behind from the
/// highest height, older from [released] (else the newest version listed). [labels] are the old
/// My nodes' labels, shown as the operator of an own node.
/// [ownLabel] gives an own node's row its "Your node · home network" in the operator's place.
List<PanelServer> nodePanelRows(List<NodeServer> nodes, {String? released, Map<String, String> labels = const {}, String? Function(String url)? ownLabel}) {
  final heights = [for (final n in nodes) if (n.height != null && n.health != ServiceHealth.down) n.height!];
  final tip = heights.isEmpty ? null : heights.reduce(math.max);
  var newest = released;
  if (newest == null) {
    for (final n in nodes) {
      final v = n.version;
      if (v != null && (newest == null || (compareVersions(v, newest) ?? 0) > 0)) newest = v;
    }
  }
  return [
    for (final n in nodes)
      () {
        final down = n.health == ServiceHealth.down;
        final behind = down || tip == null || n.height == null ? null : (tip - n.height!).clamp(0, 1 << 30);
        final old = n.version != null && newest != null && (compareVersions(n.version!, newest) ?? 0) < 0;
        final label = labels[n.url]?.trim();
        return PanelServer(
          value: n.url,
          host: panelHost(ServerKind.node, n.url),
          operator: ownLabel?.call(n.url) ?? n.operator ?? (label != null && label.isNotEmpty ? label : (n.label.isEmpty || n.label == nodeHost(n.url) ? null : n.label)),
          listedAs: n.listedAs,
          icon: n.icon,
          state: switch (n.health) {
            ServiceHealth.down => NodeHealthState.down,
            ServiceHealth.slow => NodeHealthState.degraded,
            ServiceHealth.ok => (behind ?? 0) > 0 || old ? NodeHealthState.degraded : NodeHealthState.healthy,
            ServiceHealth.checking || ServiceHealth.off => null,
          },
          checking: n.health == ServiceHealth.checking,
          behind: behind,
          latencyMs: down ? null : n.latencyMs,
          version: n.version,
          versionOld: old,
        );
      }(),
  ];
}

/// The rows of the public relays, with the monitor's health; [defaultHost] gets the tag.
List<PanelServer> relayPanelRows(List<EpicboxServer> boxes, {String? defaultHost}) => [
  for (final b in boxes)
    PanelServer(
      value: relayLabel(b),
      host: relayLabel(b),
      operator: b.operator,
      listedAs: b.listedAs,
      icon: b.icon,
      state: switch (b.health) {
        ServiceHealth.ok => NodeHealthState.healthy,
        ServiceHealth.slow => NodeHealthState.degraded,
        ServiceHealth.down => NodeHealthState.down,
        ServiceHealth.checking || ServiceHealth.off => null,
      },
      latencyMs: b.health == ServiceHealth.down ? null : b.latencyMs,
      isDefault: b.domain == defaultHost && b.port == 443,
    ),
];

/// The This computer row of the node list: first, never removed.
@immutable
class PanelLocalRow {
  const PanelLocalRow({required this.value, required this.stateText});

  final String value;

  /// `Not set up` / `Syncing 12 %` / `Synced` / `Stopped`.
  final String stateText;
}

/// A state the tour opens the panel in: [query] typed, [submit] pressed, [remove] binned.
@immutable
class ServerPanelDemo {
  const ServerPanelDemo({this.query, this.submit = false, this.remove, this.pick});

  final String? query;
  final bool submit;
  final String? remove;
  final String? pick;
}

class ServerListPanel extends ConsumerStatefulWidget {
  const ServerListPanel({
    super.key,
    required this.kind,
    required this.label,
    required this.value,
    required this.fieldText,
    required this.servers,
    required this.source,
    required this.onChoose,
    required this.onTest,
    this.fieldSub,
    this.tone = ETone.ok,
    this.state,
    this.chooseOnly = false,
    this.local,
    this.listNote,
    this.busy = false,
    this.busyLabel,
    this.busyTimeout = const Duration(seconds: 20),
    this.error,
    this.openInitially = false,
    this.demo,
    this.selection,
    this.keepBelow = 0,
    this.panelOverhang = 0,
  });

  /// Room the open list leaves free under it, so the page's main button stays in view.
  final double keepBelow;

  /// How far the open list reaches past the field on each side: a field inset in a column of
  /// cards (setup's node step) passes the inset, so the list lands flush with the cards' edges
  /// and none shows beside it.
  final double panelOverhang;

  final ServerKind kind;

  /// The panel takes a set of servers instead of one ([RelaySelection]): a checkbox per row, a
  /// tick applies at once and the panel stays open; nothing switches. Null keeps the one-server
  /// panel. [value] and [onChoose] are not used then.
  final RelaySelection? selection;

  /// The button's and the panel's name ("Node server").
  final String label;

  /// The value in use ('' none chosen yet).
  final String value;

  /// The button's text: the host in use; [fieldSub] muted after it.
  final String fieldText;
  final String? fieldSub;
  final ETone tone;

  /// The state of the server in use, drawn as the field's dot over [tone]: the same state the
  /// page's status line shows, so the two never disagree (#76).
  final EState? state;

  /// What the wallet knows of each server, in any order; the list's order is the store's.
  final List<PanelServer> servers;

  /// What the list is seeded with and kept in step with ([DeskServerListController.sync]).
  final DeskServerSource source;

  /// Switch (Settings) or choose (Setup). The panel has closed when it runs.
  final Future<void> Function(String value) onChoose;

  /// Tests a typed server before it joins: null when it answered, else why not.
  final Future<String?> Function(String value) onTest;

  /// Setup before a wallet exists: a pick chooses, Add tests then chooses; no Switch step.
  final bool chooseOnly;
  final PanelLocalRow? local;

  /// Under the rows: where the health comes from.
  final String? listNote;
  final bool busy;
  final String? busyLabel;
  final Duration busyTimeout;

  /// Under the button (a failed switch).
  final String? error;
  final bool openInitially;
  final ServerPanelDemo? demo;

  @override
  ConsumerState<ServerListPanel> createState() => ServerListPanelState();
}

class ServerListPanelState extends ConsumerState<ServerListPanel> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _button = FocusNode(debugLabel: 'server list button');
  final _field = FocusNode(debugLabel: 'server list field');
  final _listScope = FocusScopeNode(debugLabel: 'server list rows');
  final _group = Object();
  final _text = TextEditingController();
  final _scroll = ScrollController();
  double _width = 480;
  Timer? _busyTimer;
  bool _slow = false;
  ServerList? _list;

  String? _fieldError;

  /// The value being tested before it joins.
  String? _adding;

  /// The foot's line: what the last action did, with Undo when it can be undone.
  String? _line;
  VoidCallback? _lineAction;
  String? _lineActionLabel;
  Key? _lineActionKey;
  Timer? _lineTimer;

  bool get _busy => widget.busy && !_slow;
  bool get _node => widget.kind == ServerKind.node;

  /// The set ticked now in a selection panel; null in the one-server panel.
  List<String>? _chosen;

  RelaySelection? get _sel => widget.selection;

  /// The list is open.
  bool get isOpen => _portal.isShowing;

  @override
  void initState() {
    super.initState();
    _chosen = _sel == null ? null : [..._sel!.chosen];
    if (widget.busy) _startBusy();
    if (widget.openInitially || widget.demo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        open();
        final d = widget.demo;
        if (d == null) return;
        if (d.query != null) {
          _text.text = d.query!;
          setState(() {});
        }
        if (d.submit) _submit();
        if (d.pick != null) _pick(d.pick!);
        if (d.remove != null) {
          // The list is read from the store first.
          for (var i = 0; i < 20 && (_list == null || !_list!.has(widget.kind, d.remove!)); i++) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
          }
          if (mounted) await _remove(_row(d.remove!));
        }
      });
    }
  }

  @override
  void didUpdateWidget(ServerListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sel = _sel;
    // The setting changed the set behind the panel's back: follow it.
    if (sel != null && !listEquals(sel.chosen, oldWidget.selection?.chosen)) _chosen = [...sel.chosen];
    if (widget.busy && !oldWidget.busy) _startBusy();
    if (!widget.busy && oldWidget.busy) {
      _busyTimer?.cancel();
      _slow = false;
    }  }

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
    _lineTimer?.cancel();
    _button.dispose();
    _field.dispose();
    _listScope.dispose();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _same(String a, String b) => sameServer(widget.kind, a, b);

  /// Opens the list with the field empty.
  void open() {
    if (_busy || _portal.isShowing || !mounted) return;
    _text.clear();
    setState(() {
      _fieldError = null;
      _portal.show();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_portal.isShowing) return;
      _field.requestFocus();
    });
  }

  /// Back to the closed button.
  void collapse() {
    if (!mounted) return;
    _lineTimer?.cancel();
    setState(() {
      _portal.hide();
      _fieldError = null;
      _line = null;
      _lineAction = null;
    });
    _button.requestFocus();
  }

  void _say(String text, {VoidCallback? undo, String? actionLabel, Key? actionKey}) {
    _lineTimer?.cancel();
    setState(() {
      _line = text;
      _lineAction = undo;
      _lineActionLabel = actionLabel;
      _lineActionKey = actionKey;
    });
    _lineTimer = Timer(Duration(seconds: undo != null ? 8 : 4), () {
      if (mounted) {
        setState(() {
          _line = null;
          _lineAction = null;
        });
      }
    });
  }

  String get _typed => _text.text.trim();

  /// Something is typed: the field filters.
  bool get _filtering => _typed.isNotEmpty;

  /// The typed text as the list stores it, or null when it is no address. A node typed without
  /// a scheme on this computer or the local network answers plain http.
  String? _typedValue() {
    final v = typedServerValue(widget.kind, _typed);
    if (v == null || !_node || _typed.contains('://')) return v;
    final host = Uri.tryParse(v)?.host ?? '';
    return isPrivateHost(host) ? v.replaceFirst('https://', 'http://') : v;
  }

  PanelServer _row(String value) {
    final k = serverKeyOf(widget.kind, value);
    for (final s in widget.servers) {
      if (serverKeyOf(widget.kind, s.value) == k) return s;
    }
    return PanelServer.bare(widget.kind, value);
  }

  /// Every listed server in the list's order; the source's while the store is read.
  List<PanelServer> get _all => [for (final v in _list?.entries ?? widget.source.public) _row(v)];

  List<PanelServer> _shown(List<PanelServer> all) {
    if (!_filtering) return all;
    return [
      for (final s in all)
        if (serverMatches(_typed, host: s.host, operator: s.operator)) s,
    ];
  }

  void _pick(String value) {
    if (_busy) return;
    if (_sel != null) return _tick(value);
    if (widget.value.isNotEmpty && _same(value, widget.value)) {
      collapse();
      return;
    }
    if (widget.chooseOnly) {
      collapse();
      unawaited(widget.onChoose(value));
      return;
    }
    setState(() => _fieldError = null);
    unawaited(_node ? _switchNow(value) : _confirmSwitch(value));
  }

  void _pickLocal(PanelLocalRow local) {
    collapse();
    if (widget.value != local.value) unawaited(widget.onChoose(local.value));
  }

  /// A Node pick: switches at once, the panel stays open and the foot says so once the switch
  /// took (the wallet's value follows).
  Future<void> _switchNow(String value) async {
    await widget.onChoose(value);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !isOpen || !_same(widget.value, value)) return;
      _text.clear();
      _say(context.l10n.serverSwitched(panelHost(widget.kind, value)));
    });
  }

  /// A plain-http node at a shared (CGNAT) address may be the user's tailnet or the provider's
  /// network, which cannot be told apart: a dialog asks before it is used.
  Future<bool> _plainHttpAgreed(String value) async {
    final l = context.l10n;
    final sure = await showEDialog<bool>(
      context,
      builder: (context) => EDialog(
        title: l.slPlainHttpTitle,
        description: l.slPlainHttpBody(panelHost(widget.kind, value)),
        icon: EIcons.lockOpen,
        actions: [
          EButton(
            key: const ValueKey('server-list-plain-cancel'),
            label: l.commonCancel,
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          EButton.primary(
            key: const ValueKey('server-list-plain-use'),
            label: l.slPlainHttpUse,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    return sure == true;
  }

  /// An Epicbox pick: the address changes, so a dialog asks first.
  Future<void> _confirmSwitch(String value) async {
    final l = context.l10n;
    collapse();
    final sure = await showEDialog<bool>(
      context,
      builder: (context) => EDialog(
        title: l.slSwitchTitle(panelHost(widget.kind, value)),
        description: l.slSwitchBody,
        icon: EIcons.epicbox,
        actions: [
          EButton(
            key: const ValueKey('server-list-cancel'),
            label: l.commonCancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          // Enter switches, Esc cancels: the primary button holds the focus on open.
          EButton.primary(
            key: const ValueKey('server-list-switch'),
            label: l.slSwitch,
            autofocus: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (sure == true && mounted) await widget.onChoose(value);
  }

  /// Enter on the field.
  void _submit() {
    if (!_filtering) return;
    final all = _all;
    final value = _typedValue();
    final listed = value == null ? null : all.where((s) => _same(s.value, value)).firstOrNull;
    if (listed != null) return _pick(listed.value);
    final shown = _shown(all);
    if (value == null && shown.length == 1) return _pick(shown.first.value);
    unawaited(_add());
  }

  Future<void> _add() async {
    final l = context.l10n;
    final value = _typedValue();
    if (value == null) {
      setState(() => _fieldError = l.slNotAnAddress);
      return;
    }
    if (_all.any((s) => _same(s.value, value))) return _pick(value);
    if (_node && needsPlainHttpConsent(value)) {
      if (!await _plainHttpAgreed(value) || !mounted) return;
      await allowPlainHttpNode(value);
      if (!mounted) return;
    }
    setState(() {
      _adding = value;
      _fieldError = null;
    });
    String? why;
    try {
      why = await widget.onTest(value);
    } on Object {
      why = _node ? l.deskSlNodeNoAnswer : l.slRelayNoAnswer;
    }
    if (!mounted) return;
    if (why != null) {
      setState(() {
        _adding = null;
        _fieldError = why;
      });
      return;
    }
    await ref.read(deskServerListProvider(widget.kind).notifier).add(value, own: true);
    if (!mounted) return;
    if (_sel != null) {
      _text.clear();
      setState(() => _adding = null);
      _addedInSelection(value);
      _field.requestFocus();
      return;
    }
    if (widget.chooseOnly) {
      setState(() => _adding = null);
      collapse();
      await widget.onChoose(value);
      return;
    }
    _text.clear();
    setState(() => _adding = null);
    _say(
      l.slAdded(panelHost(widget.kind, value)),
      undo: () => _pick(value),
      actionLabel: l.slSwitch,
      actionKey: const ValueKey('server-list-line-switch'),
    );
    _field.requestFocus();
    // The new row is the last: bring it into view once the list rebuilt with it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final reduce = MediaQuery.disableAnimationsOf(context);
      final end = _scroll.position.maxScrollExtent;
      reduce ? _scroll.jumpTo(end) : _scroll.animateTo(end, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    });
  }

  Future<void> _remove(PanelServer s) async {
    final l = context.l10n;
    if (_sel != null ? _isChosen(s.value) : widget.value.isNotEmpty && _same(s.value, widget.value)) {
      _say(_sel != null ? l.slChosenUntick : l.slInUseSwitchFirst);
      return;
    }
    final hadFocus = _listScope.hasFocus;
    final n = ref.read(deskServerListProvider(widget.kind).notifier);
    final at = await n.remove(s.value);
    if (!mounted) return;
    if (hadFocus) _field.requestFocus();
    _say(
      l.slRemoved(s.host),
      undo: () async {
        await n.add(s.value, at: at);
        if (mounted) _say(l.slAdded(s.host));
      },
    );
  }

  // The selection mode.

  bool _isChosen(String value) => _chosen!.any((c) => _same(c, value));

  void _setChosen(List<String> next) {
    setState(() => _chosen = next);
    _sel!.onChanged(next);
  }

  /// The foot line of a server that joined the set: plain for a default, else what a
  /// non-default means for who finds this wallet.
  String _chosenLine(String value) {
    final l = context.l10n;
    final host = panelHost(widget.kind, value);
    return _sel!.defaults.any((d) => _same(d, value)) ? l.slChosen(host) : l.slChosenNonDefault(host);
  }

  void _undoTo(List<String> before) {
    _setChosen(before);
    _lineTimer?.cancel();
    setState(() {
      _line = null;
      _lineAction = null;
    });
  }

  /// A click on a row: ticks or unticks at once; the foot says what happened, with Undo, or
  /// why not (the last one stays, the set is full).
  void _tick(String value) {
    final l = context.l10n;
    final sel = _sel!;
    final before = _chosen!;
    final r = toggleSelection(widget.kind, before, value, sel.limit, torOn: TorSwitch.on);
    switch (r.refusal) {
      case SelectionRefusal.keepOne:
        _say(l.slKeepOne);
        return;
      case SelectionRefusal.limit:
        _say(l.slLimit(sel.limit));
        return;
      case SelectionRefusal.localAddress:
        _say(l.slRefusedLocal);
        return;
      case SelectionRefusal.onionWithoutTor:
        _say(l.slRefusedOnion);
        return;
      case null:
        break;
    }
    final next = r.next!;
    _setChosen(next);
    _say(
      next.length > before.length ? _chosenLine(value) : l.slUnchosen(panelHost(widget.kind, value)),
      undo: () => _undoTo(before),
    );
  }

  /// A typed server was tested and listed: it joins the set while there is room, else the foot
  /// says to untick one.
  void _addedInSelection(String value) {
    final l = context.l10n;
    final sel = _sel!;
    final before = _chosen!;
    final host = panelHost(widget.kind, value);
    if (before.length >= sel.limit) {
      _say(l.slAddedUntick(host));
      return;
    }
    _setChosen([...before, value]);
    _say(
      sel.defaults.any((d) => _same(d, value)) ? l.slChosen(host) : l.slAddedNonDefault(host),
      undo: () => _undoTo(before),
    );
  }

  /// "Reset to defaults": the set is the defaults again; one the user took out of the list comes
  /// back with it.
  Future<void> _resetToDefaults() async {
    final sel = _sel!;
    final before = _chosen!;
    final n = ref.read(deskServerListProvider(widget.kind).notifier);
    for (final d in sel.defaults) {
      await n.add(d);
    }
    if (!mounted) return;
    _setChosen([...sel.defaults]);
    _say(context.l10n.slReset, undo: () => _undoTo(before));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    _list = ref.watch(deskServerListProvider(widget.kind));
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
            this.open();
            return null;
          },
        ),
      },
      child: Builder(
        builder: (context) {
          final focused = _button.hasFocus;
          // A host (or a chosen set of them) is data, in mono; a word ("Local node", "Pick a
          // node", "Checking…") is in the interface face.
          final isHost = typedServerValue(widget.kind, widget.fieldText.trim().split(RegExp(r'[\s,]+')).first) != null;
          final valueStyle = isHost ? ts.mono(size: 13.u, color: c.text) : ts.body.copyWith(color: c.text);
          return Semantics(
            button: true,
            label: '${widget.label}: ${widget.fieldText}${widget.fieldSub != null ? ', ${widget.fieldSub}' : ''}',
            hint: l.deskSetComboOpens,
            expanded: open,
            excludeSemantics: true,
            child: EInkWell(
              onTap: open ? collapse : this.open,
              // The detector above holds the focus: one Tab stop.
              canRequestFocus: false,
              borderRadius: BorderRadius.circular(Rad.sm),
              child: Container(
                // A selection shows every chosen host, wrapped at the spaces, never cut.
                constraints: BoxConstraints(minHeight: Ctl.sm),
                padding: EdgeInsets.only(left: Sp.x3, right: Sp.x2, top: _sel == null ? 0 : Sp.x2, bottom: _sel == null ? 0 : Sp.x2),
                decoration: BoxDecoration(
                  color: c.s2,
                  borderRadius: BorderRadius.circular(Rad.sm),
                  border: Border.all(color: widget.error != null ? c.risk : (open || focused ? c.accent : c.lineField)),
                ),
                child: Row(
                  children: [
                    if (widget.state case final st?) EStateDot(st, size: 8.u) else EStatusDot(widget.tone, size: 8.u),
                    SizedBox(width: Sp.x3),
                    // The value takes the room up to the chevron, which stays at the end whatever the
                    // value is (a bare host, a host and its operator, a word while it switches).
                    Expanded(
                      child: widget.busy || widget.fieldSub == null
                          ? Row(
                              children: [
                                Flexible(
                                  flex: 2,
                                  child: Text(widget.fieldText, maxLines: _sel == null ? 1 : 3, overflow: TextOverflow.ellipsis, softWrap: _sel != null, style: valueStyle),
                                ),
                                if (widget.busy) ...[
                                  SizedBox(width: Sp.x2),
                                  Flexible(
                                    child: Semantics(
                                      liveRegion: true,
                                      child: Text(
                                        _slow ? l.deskSetComboNoAnswer : (widget.busyLabel ?? l.deskSetFrameChecking),
                                        style: ts.small.copyWith(color: _slow ? c.warn : c.dim),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            )
                          // The host first, whole while it fits; the operator only in the room left.
                          : LayoutBuilder(
                              builder: (context, box) {
                                final tp = TextPainter(text: TextSpan(text: widget.fieldText, style: valueStyle), textDirection: Directionality.of(context), textScaler: MediaQuery.textScalerOf(context), maxLines: 1)..layout();
                                final hostW = tp.width;
                                tp.dispose();
                                final host = Text(widget.fieldText, maxLines: _sel == null ? 1 : 3, overflow: TextOverflow.ellipsis, softWrap: _sel != null, style: valueStyle);
                                if (hostW + Sp.x2 + 48.u > box.maxWidth) return Align(alignment: AlignmentDirectional.centerStart, child: host);
                                return Row(
                                  children: [
                                    host,
                                    SizedBox(width: Sp.x2),
                                    Flexible(child: Text(widget.fieldSub!, style: ts.caption.copyWith(color: c.dim), overflow: TextOverflow.ellipsis, maxLines: 1)),
                                  ],
                                );
                              },
                            ),
                    ),
                    SizedBox(width: Sp.x2),
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
                child: OverlayPortal(controller: _portal, overlayChildBuilder: _panel, child: field),
              );
            },
          ),
          if (widget.error != null) ...[
            SizedBox(height: 6.u),
            _ErrorLine(widget.error!),
          ],
        ],
      ),
    );
  }

  Widget _panel(BuildContext overlayContext) {
    final context = this.context;
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final sel = _sel;
    // A selection lists its defaults first; chosen rows keep their place.
    final all = sel == null ? _all : selectionOrder(widget.kind, _all, (s) => s.value, sel.defaults);
    final filtering = _filtering;
    final shown = _shown(all);
    final typedValue = filtering ? _typedValue() : null;
    final listed = typedValue != null && all.any((s) => _same(s.value, typedValue));
    // Only a text that parses as host or host:port can be added (UD-004): with an error shown,
    // the list keeps the error line and the match count alone.
    final addable = filtering && typedValue != null && !listed;
    final local = widget.local;
    final showLocal = local != null && (!filtering || serverMatches(_typed, host: l.deskSetNodeLocalNode, operator: local.stateText));
    final selected = sel != null ? '' : widget.value;
    final known = [for (final s in widget.servers) (operator: s.listedAs ?? s.operator, icon: s.icon)];

    final helper = _fieldError ?? (filtering ? l.slHelpMatches(shown.length) : (widget.chooseOnly ? l.deskSlHelpChoose : null));

    final rows = <Widget>[
      if (showLocal)
        _LocalRow(local: local, selected: widget.value == local.value, onTap: () => _pickLocal(local)),
      if (addable)
        _AddRow(
          host: panelHost(widget.kind, typedValue),
          note: _node ? l.slAddTestsNode : l.slAddTestsRelay,
          busy: _adding != null,
          onTap: _add,
        ),
      for (final s in shown)
        _Row(
          key: ValueKey('server-row-${s.value}'),
          kind: widget.kind,
          server: s,
          // Its own icon, else the one the monitor holds for the same operator.
          icon: serverIconFor(s.icon, s.listedAs ?? s.operator, known),
          // Before a wallet exists nothing is in use: the check marks the choice.
          inUse: sel == null && !widget.chooseOnly && widget.value.isNotEmpty && _same(s.value, widget.value),
          selected: sel != null ? _isChosen(s.value) : selected.isNotEmpty && _same(s.value, selected),
          addedByYou: _list?.isAddedByUser(widget.kind, s.value) ?? false,
          isDefault: sel != null ? sel.defaults.any((d) => _same(d, s.value)) : s.isDefault,
          // A checkbox in the selection; the rest of the set dims once it is full.
          ticked: sel == null ? null : _isChosen(s.value),
          dimmed: sel != null && !_isChosen(s.value) && _chosen!.length >= sel.limit,
          onTap: () => _pick(s.value),
          onRemove: () => _remove(s),
        ),
      if (sel != null && !filtering && !sameServerSet(widget.kind, _chosen!, sel.defaults))
        Padding(
          padding: EdgeInsets.only(top: Sp.x1),
          child: Align(
            alignment: Alignment.centerLeft,
            child: EButton.ghost(
              key: const ValueKey('server-list-reset'),
              label: l.slResetDefaults,
              icon: EIcons.history,
              onPressed: _resetToDefaults,
            ),
          ),
        ),
      if (widget.listNote != null && !filtering)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
          child: Text(widget.listNote!, style: ts.caption),
        ),
    ];

    final relayWarning = !_node && !widget.chooseOnly && !filtering && sel == null;
    final top = Padding(
      padding: EdgeInsets.fromLTRB(Sp.x3, Sp.x3, Sp.x3, Sp.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowDown): () => _listScope.nextFocus(),
            },
            child: EInput(
              key: const ValueKey('server-list-field'),
              controller: _text,
              focusNode: _field,
              mono: true,
              size: EBtnSize.sm,
              invalid: _fieldError != null,
              hint: l.slFieldHint,
              leading: filtering ? EIcons.search : (_node ? EIcons.node : EIcons.epicbox),
              semanticLabel: _node ? l.slNodeField : l.slRelayField,
              trailing: _adding != null
                  ? Padding(padding: EdgeInsets.all(Sp.x2), child: ESpinner(size: 14.u))
                  : _text.text.isEmpty
                  ? null
                  : EIconButton(
                      key: const ValueKey('server-list-clear'),
                      icon: EIcons.close,
                      label: l.slClear,
                      size: EBtnSize.inline,
                      tabStop: false,
                      onPressed: () {
                        _text.clear();
                        setState(() => _fieldError = null);
                        _field.requestFocus();
                      },
                    ),
              onChanged: (_) => setState(() => _fieldError = null),
              onSubmitted: (_) => _submit(),
            ),
          ),
          if (helper != null) ...[
            SizedBox(height: 6.u),
            Semantics(
              liveRegion: true,
              child: Text(
                helper,
                key: const ValueKey('server-list-helper'),
                style: _fieldError != null ? ts.small.copyWith(color: c.risk) : ts.caption.copyWith(color: c.dim),
              ),
            ),
          ],
          if (relayWarning) ...[
            SizedBox(height: Sp.x2),
            Text(l.slRelayWarning, key: const ValueKey('server-list-relay-note'), style: ts.caption.copyWith(color: c.dim)),
          ],
          if (sel != null) ...[
            SizedBox(height: Sp.x2),
            Row(
              children: [
                Expanded(child: Text(sel.note, key: const ValueKey('server-list-note'), style: ts.caption.copyWith(color: c.dim))),
                SizedBox(width: Sp.x2),
                EBadge(
                  l.slCount(_chosen!.length, sel.limit),
                  key: const ValueKey('server-list-count'),
                  tone: _chosen!.length >= sel.limit ? BadgeTone.info : BadgeTone.neutral,
                  liveRegion: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );

    final line = _line;
    final foot = [
      if (line != null)
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: EdgeInsets.fromLTRB(Sp.x3, Sp.x2, Sp.x2, Sp.x2),
            child: Row(
              children: [
                Expanded(child: Text(line, key: const ValueKey('server-list-line'), style: ts.small.copyWith(color: c.text))),
                if (_lineAction != null)
                  EButton.ghost(
                    key: _lineActionKey ?? const ValueKey('server-list-undo'),
                    label: _lineActionLabel ?? l.slUndo,
                    size: EBtnSize.inline,
                    onPressed: () {
                      final undo = _lineAction;
                      setState(() => _lineAction = null);
                      undo?.call();
                    },
                  ),
              ],
            ),
          ),
        ),
    ];

    // As tall as the window below the button allows; the button is as tall as it lays out (a
    // chosen set of hosts can wrap), so the list's foot (Reset, Undo) stays in the window.
    final box = context.findRenderObject() as RenderBox?;
    final anchor = (_link.leaderSize?.height ?? Ctl.sm) + Sp.x1;
    final below = box == null || !_laidOut(box) ? 480.u : MediaQuery.sizeOf(context).height - box.localToGlobal(Offset.zero).dy - anchor - Sp.x4 - widget.keepBelow;
    final maxHeight = below.clamp(widget.keepBelow > 0 ? 160.u : 260.u, 520.u);

    final reach = widget.panelOverhang;
    final width = _width + 2 * reach;
    return CompositedTransformFollower(
      link: _link,
      targetAnchor: Alignment.bottomLeft,
      offset: Offset(-reach, Sp.x1),
      child: Align(
        alignment: Alignment.topLeft,
        child: TapRegion(
          groupId: _group,
          child: CallbackShortcuts(
            bindings: {const SingleActivator(LogicalKeyboardKey.escape): collapse},
            // The popover look: s4, the lineStrong hairline dialogs use, the one soft shadow.
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(Rad.sm), boxShadow: c.popShadow),
              child: Material(
              color: c.s4,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rad.sm), side: BorderSide(color: c.lineStrong)),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: width, maxWidth: width, maxHeight: maxHeight),
                child: Semantics(
                  label: widget.label,
                  explicitChildNodes: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      top,
                      Flexible(
                        child: CallbackShortcuts(
                          bindings: {
                            const SingleActivator(LogicalKeyboardKey.arrowDown): () => _listScope.nextFocus(),
                            const SingleActivator(LogicalKeyboardKey.arrowUp): () => _listScope.previousFocus(),
                          },
                          child: FocusScope(
                            node: _listScope,
                            child: ListView(
                              controller: _scroll,
                              padding: EdgeInsets.fromLTRB(Sp.x2, 0, Sp.x2, Sp.x2),
                              shrinkWrap: true,
                              children: rows,
                            ),
                          ),
                        ),
                      ),
                      ...foot,
                    ],
                  ),
                ),
              ),
            ),
          ),
            ),
        ),
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(EIcons.error, size: Ctl.iconSm, color: c.risk)),
          SizedBox(width: 6.u),
          Expanded(child: Text(text, style: context.ts.small.copyWith(color: c.risk))),
        ],
      ),
    );
  }
}

/// A server tile in the desktop's colours, shared with the status popovers.
ServerTileColors deskTileColors(DeskColors c) => ServerTileColors(
  surface: c.s2,
  line: c.line,
  initials: c.dim,
  tints: [c.accent.withValues(alpha: 0.14), c.info.withValues(alpha: 0.16), c.text.withValues(alpha: 0.08)],
  ok: c.ok,
  warn: c.warn,
  risk: c.risk,
  unknown: c.faint,
  info: c.info,
  ring: c.s4,
);

/// One server: tile, host in mono, the facts under it; the check on the selected row and the bin.
class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.kind,
    required this.server,
    required this.icon,
    required this.inUse,
    required this.selected,
    required this.isDefault,
    this.addedByYou = false,
    this.ticked,
    this.dimmed = false,
    required this.onTap,
    required this.onRemove,
  });

  final ServerKind kind;
  final PanelServer server;
  final ServerIcon? icon;
  final bool inUse;
  final bool selected;

  /// The "Default" badge: the network's default, or a selection's defaults.
  final bool isDefault;

  /// The user typed this server in: the "Added by you" badge.
  final bool addedByYou;

  /// In a selection panel: whether the row's checkbox is ticked. Null in the one-server panel.
  final bool? ticked;

  /// The row is not chosen and the set is full: shown lighter, a click says why not.
  final bool dimmed;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final s = server;
    final down = s.down;
    final dim = down ? c.faint : c.dim;
    // (text, colour, bold)
    final facts = <(String, Color, bool)>[
      if (inUse) (l.deskSlInUse, c.text, true),
      if (kind == ServerKind.node && !down && s.behind != null)
        s.behind! <= 0 ? (l.deskKitAtTip, c.ok, false) : (l.deskKitBehind(s.behind!, digitsText(l, s.behind!)), c.warn, false),
      // One word per state (state_language.dart), as the tile's dot.
      if (s.state == NodeHealthState.degraded && (s.behind ?? 0) <= 0 && !s.versionOld) (ShownState.slow.word(l), c.warn, false),
      if (down) (kind == ServerKind.node && s.local ? l.serverLocalNotReachable : ShownState.notAnswering.word(l), c.risk, false),
      if (s.state == null) ((s.checking ? ShownState.checking : ShownState.unchecked).word(l), c.dim, false),
      if (s.operator != null && s.operator!.isNotEmpty) (s.operator!, dim, false),
      if (s.latencyMs != null) (l.deskSlLatency(digitsText(l, s.latencyMs!)), dim, false),
      if (kind == ServerKind.node && !down && s.version != null) (s.version!, s.versionOld ? c.warn : dim, false),
    ];
    final row = Semantics(
      button: ticked == null,
      selected: ticked == null ? selected : null,
      checked: ticked,
      label: [l.deskSetComboUse(s.host), if (isDefault) l.deskSlDefault, if (addedByYou) l.slAddedByYou, for (final f in facts) f.$1].join(', '),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.delete): onRemove,
          const SingleActivator(LogicalKeyboardKey.backspace): onRemove,
        },
        child: EInkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Rad.sm),
          focusColor: c.s3,
          hoverColor: c.s3,
          child: Container(
            constraints: BoxConstraints(minHeight: 52.u),
            padding: EdgeInsets.only(left: Sp.x2, right: Sp.x1),
            decoration: BoxDecoration(
              color: selected ? c.s3 : null,
              borderRadius: BorderRadius.circular(Rad.sm),
              border: Border.all(color: selected ? c.lineStrong : Colors.transparent),
            ),
            child: Row(
              children: [
                ServerTileView(
                  operator: s.listedAs ?? s.operator,
                  host: s.host,
                  icon: icon,
                  state: s.state,
                  colors: deskTileColors(c),
                  dimmed: down,
                  fontFamily: ts.mono().fontFamily,
                ),
                SizedBox(width: Sp.x3),
                Expanded(
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.u),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: ETip.value(
                                  s.value,
                                  mono: true,
                                  child: Text(s.host, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: ts.mono(size: Fs.sm, color: down ? c.faint : c.text)),
                                ),
                              ),
                              if (isDefault) ...[SizedBox(width: Sp.x2), EBadge(l.deskSlDefault)] else if (addedByYou) ...[SizedBox(width: Sp.x2), EBadge(l.slAddedByYou)],
                            ],
                          ),
                          SizedBox(height: 2.u),
                          Text.rich(
                            TextSpan(
                              children: [
                                for (var i = 0; i < facts.length; i++) ...[
                                  if (i > 0) TextSpan(text: metaSeparator, style: TextStyle(color: c.faint)),
                                  TextSpan(
                                    text: facts[i].$1,
                                    style: TextStyle(color: facts[i].$2, fontWeight: facts[i].$3 ? FontWeight.w600 : null),
                                  ),
                                ],
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ts.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (ticked != null)
                  // The row is the control: the box only shows the state.
                  ExcludeSemantics(
                    child: Container(
                      width: 20.u,
                      height: 20.u,
                      margin: EdgeInsets.only(right: Sp.x2),
                      decoration: BoxDecoration(
                        color: ticked! ? c.accent : c.s2,
                        borderRadius: BorderRadius.circular(Rad.xs),
                        border: Border.all(color: ticked! ? c.accent : c.lineField),
                      ),
                      child: ticked! ? Icon(EIcons.check, size: 16.u, color: c.accentInk) : null,
                    ),
                  )
                else
                  SizedBox(
                    width: 20.u,
                    child: selected ? Icon(EIcons.check, size: 16.u, color: s.state == NodeHealthState.healthy ? c.ok : c.dim) : null,
                  ),
                EIconButton(
                  key: ValueKey('server-row-remove-${s.value}'),
                  icon: EIcons.trash,
                  // The server in use cannot go: switch first.
                  label: inUse ? l.slInUseSwitchFirst : l.deskSlRemoveHost(s.host),
                  size: EBtnSize.inline,
                  tabStop: false,
                  onPressed: inUse ? null : onRemove,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return dimmed ? Opacity(opacity: 0.55, child: row) : row;
  }
}

/// The This computer row: the monitor, "Local node" and its state.
class _LocalRow extends StatelessWidget {
  const _LocalRow({required this.local, required this.selected, required this.onTap});

  final PanelLocalRow local;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    return Semantics(
      button: true,
      selected: selected,
      label: l.deskKitLocalNodeUse(local.stateText),
      child: EInkWell(
        key: const ValueKey('server-row-local'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(Rad.sm),
        focusColor: c.s3,
        hoverColor: c.s3,
        child: Container(
          constraints: BoxConstraints(minHeight: 52.u),
          padding: EdgeInsets.symmetric(horizontal: Sp.x2),
          decoration: BoxDecoration(
            color: selected ? c.s3 : null,
            borderRadius: BorderRadius.circular(Rad.sm),
            border: Border.all(color: selected ? c.lineStrong : Colors.transparent),
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                Container(
                  width: 36.u,
                  height: 36.u,
                  decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(6)),
                  child: Icon(EIcons.monitor, size: 18.u, color: c.dim),
                ),
                SizedBox(width: Sp.x3),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.deskSetNodeLocalNode, style: ts.body.copyWith(color: c.text, height: 1.3)),
                      Text(
                        metaLine([l.deskSetNodeGroupComputer, local.stateText]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts.caption.copyWith(color: c.dim),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20.u, child: selected ? Icon(EIcons.check, size: 16.u, color: c.dim) : null),
                SizedBox(width: Ctl.inline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Add: the first row while nothing matches or the typed address is not listed.
class _AddRow extends StatelessWidget {
  const _AddRow({required this.host, required this.note, required this.busy, required this.onTap});

  final String host;
  final String note;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: Sp.x1),
      child: Semantics(
        button: true,
        label: l.slAddRow(host),
        child: EInkWell(
          key: const ValueKey('server-list-add'),
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(Rad.sm),
          focusColor: c.s3,
          hoverColor: c.s3,
          child: Container(
            constraints: BoxConstraints(minHeight: 52.u),
            padding: EdgeInsets.symmetric(horizontal: Sp.x2),
            decoration: BoxDecoration(border: Border.all(color: c.lineStrong), borderRadius: BorderRadius.circular(Rad.sm)),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 36.u,
                    child: Center(child: busy ? ESpinner(size: 16.u) : Icon(EIcons.plus, size: 18.u, color: c.accentText)),
                  ),
                  SizedBox(width: Sp.x3),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          busy ? l.deskSlTesting(host) : l.slAddRow(host),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ts.body.copyWith(color: c.text, fontWeight: FontWeight.w600, height: 1.3),
                        ),
                        Text(note, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts.caption.copyWith(color: c.dim)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Whether [r] and every box above it has a size: [RenderBox.localToGlobal] needs them all, and
/// an ancestor that first lays out in this frame (a transform that just appeared) has none yet.
bool _laidOut(RenderObject r) {
  for (RenderObject? p = r; p != null; p = p.parent) {
    if (p is RenderBox && !p.hasSize) return false;
  }
  return true;
}
