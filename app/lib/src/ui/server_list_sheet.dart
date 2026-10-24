/// The phone's Node and Epicbox pickers: one list per kind ([serverListProvider]), seeded
/// from the built-in servers and status.btlabs.uk, which the user edits in place. One field at
/// the top starts empty, filters the list while typed in, and offers Add as soon as nothing
/// matches; the server in use shows only in its row (the check) and the Current card. A tap on
/// a Node row switches at once and the foot says so; on an Epicbox row it asks first, as the
/// address changes. Every row has a bin with Undo; the row in use refuses ("In use. Switch
/// first."); "Restore the public list" shows while a public server is removed. Tiles carry the
/// operator's icon from the monitor, else initials, and the health as a dot.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connection_state.dart' show walletStatusProvider;
import '../errors.dart';
import '../l10n.dart';
import '../network.dart';
import '../node_failover_phone.dart';
import '../providers.dart';
import '../public_servers.dart';
import '../push_registration.dart' show PushRegistration;
import '../relay_directory.dart';
import '../send_preflight.dart' show relayProbeProvider;
import '../server_list_store.dart';
import '../server_switch.dart';
import '../net/tor_net.dart' show isLoopbackUrl;
import '../tor_routes.dart' show TorRoute, torSkipsLocalNode;
import 'common.dart' show groupDigits;
import 'help_screen.dart' show HelpButton, HelpId;
import 'notices.dart';
import 'server_picker.dart'
    show networkStatusProvider, publicNodeStatusProvider, relaunchAfterSwitch;
import 'server_tile.dart';
import 'status.dart' hide NodeStatus;
import 'theme/protocol.dart';
import 'theme/tokens.dart';
import 'tor_ui.dart' show TorWayLine;

// The sheet.

/// Opens the node list over the current screen.
Future<void> showNodeListSheet(BuildContext context) => _show(context, ServerKind.node);

/// Opens the Epicbox list over the current screen.
Future<void> showEpicboxListSheet(BuildContext context) => _show(context, ServerKind.relay);

Future<void> _show(BuildContext context, ServerKind kind) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) {
    final sheet = DraggableScrollableController();
    return DraggableScrollableSheet(
      controller: sheet,
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 1,
      builder: (context, scroll) =>
          ServerListSheet(kind: kind, scrollController: scroll, sheetController: sheet),
    );
  },
);

/// The key of the address field at the top, for tests.
const Key serverListFieldKey = ValueKey('server-list-field');

/// The key of the pinned part above the list (field, its line, the card in use), for tests.
const Key serverListPinnedKey = ValueKey('server-list-pinned');

/// The key of the list, the one part of the sheet that scrolls, for tests.
const Key serverListListKey = ValueKey('server-list-list');

/// The key of the field's clear button, for tests.
const Key serverListClearKey = ValueKey('server-list-clear');

/// The key of the inline Add row, for tests.
const Key serverListAddKey = ValueKey('server-list-add');

/// The key of the Switch button in the Epicbox confirm, for tests.
const Key serverListSwitchKey = ValueKey('server-list-switch');

/// The key of the Cancel button in the Epicbox confirm, for tests.
const Key serverListCancelKey = ValueKey('server-list-cancel');

/// The key of the line at the foot that answers an action, for tests.
const Key serverListFootKey = ValueKey('server-list-foot');

/// The key of "Restore the public list", for tests.
const Key serverListRestoreKey = ValueKey('server-list-restore');

/// The key of a row, by its value.
Key serverListRowKey(String value) => ValueKey('server-list-row-$value');

/// The key of a row's remove button, by its value.
Key serverListRemoveKey(String value) => ValueKey('server-list-remove-$value');

/// One row's facts, from the list and the directory.
class _Entry {
  const _Entry({
    required this.value,
    required this.host,
    required this.operator,
    this.tileName,
    this.node,
    this.relay,
    this.icon,
    required this.directoryAnswered,
  });

  final String value;
  final String host;
  final String? operator;

  /// The name a tile takes its initials from: the monitor's, as status.btlabs.uk shows it
  /// ("epicnet.us" → EU), else [operator].
  final String? tileName;
  final NodeStatus? node;
  final RelayStatus? relay;

  /// The operator's icon from the monitor ([serverIconFor]), or null for initials.
  final ServerIcon? icon;

  /// Whether the directory answered at all: a row it did not list says "Health unknown".
  final bool directoryAnswered;

  NodeHealthState? get state => node != null
      ? node!.state
      : relay != null
      ? (relay!.healthy ? NodeHealthState.healthy : NodeHealthState.down)
      : null;
}

class ServerListSheet extends ConsumerStatefulWidget {
  const ServerListSheet({
    super.key,
    required this.kind,
    this.scrollController,
    this.sheetController,
    this.afterSave = relaunchAfterSwitch,
    this.liveSwitch = switchServersLive,
  });

  final ServerKind kind;
  final ScrollController? scrollController;

  /// The sheet around it: grown to full height while the field has the keyboard, so the
  /// matches and Add stay above it.
  final DraggableScrollableController? sheetController;
  final void Function(BuildContext context) afterSave;
  final Future<bool> Function(WidgetRef ref, {required String nodeUrl, required EpicboxRelay relay})
  liveSwitch;

  @override
  ConsumerState<ServerListSheet> createState() => _ServerListSheetState();
}

class _ServerListSheetState extends ConsumerState<ServerListSheet> {
  final _field = TextEditingController();
  final _focus = FocusNode();

  String? _fieldError;

  /// Whether a switch is running.
  bool _busy = false;

  /// Whether the typed server is being tested before it joins the list.
  bool _adding = false;

  /// What the last action did, at the foot for a few seconds, with Undo when it can be undone.
  String? _line;
  VoidCallback? _lineAction;
  String? _lineActionLabel;
  Timer? _lineTimer;

  /// Whether the foot line answers a refusal ("In use. Switch first.") rather than an action.
  bool _lineIsNote = false;

  bool get _node => widget.kind == ServerKind.node;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_growForKeyboard);
  }

  void _growForKeyboard() {
    final sheet = widget.sheetController;
    if (!_focus.hasFocus || sheet == null || !sheet.isAttached || sheet.size >= 1) return;
    sheet.animateTo(
      1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _lineTimer?.cancel();
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _text => _field.text.trim();

  void _say(String text, {VoidCallback? action, String? actionLabel, bool note = false}) {
    _lineTimer?.cancel();
    setState(() {
      _line = text;
      _lineAction = action;
      _lineActionLabel = actionLabel;
      _lineIsNote = note;
    });
    _lineTimer = Timer(
      action != null
          ? const Duration(seconds: 8)
          : noticeDuration(
              NoticeLevel.success,
              accessible: MediaQuery.accessibleNavigationOf(context),
            ),
      () {
        if (mounted) {
          setState(() {
            _line = null;
            _lineAction = null;
          });
        }
      },
    );
  }

  /// The value the field holds, as the list stores it, or null when it is not an address.
  String? _typedValue() => typedServerValue(widget.kind, _text);

  bool _same(String a, String b) => sameServer(widget.kind, a, b);

  /// The server in use: for nodes the one node failover moved to, if it did, so picking the
  /// chosen node again goes back to it.
  String _current(NetworkChoice choice) =>
      _node ? (ref.read(nodeFailoverProvider)?.inUse ?? choice.nodeUrl) : choice.relay.label;

  /// A tap on a row: the server in use says so; a node is switched to at once; an Epicbox
  /// server asks first, as the address changes.
  Future<void> _pick(String value, NetworkChoice choice) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_same(value, _current(choice))) {
      _say(context.l10n.serverAlreadyInUse, note: true);
      return;
    }
    if (_busy) return;
    if (_node) return _switchTo(value, choice);
    final l = context.l10n;
    final host = serverHost(value);
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: _FitTitle(l.slSwitchTitle(host)),
        content: Text(l.slSwitchBody),
        actions: [
          TextButton(
            key: serverListCancelKey,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            key: serverListSwitchKey,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.slSwitch),
          ),
        ],
      ),
    );
    if (sure == true && mounted) await _switchTo(value, choice);
  }

  /// Done on the field: a listed address is picked, anything else goes to [_add], which says
  /// when it is no address.
  void _submit(NetworkChoice choice, List<_Entry> all) {
    if (_text.isEmpty) return;
    final value = _typedValue();
    final listed = value == null ? null : all.where((e) => _same(e.value, value)).firstOrNull;
    if (listed != null) {
      _pick(listed.value, choice);
      return;
    }
    _add(choice);
  }

  /// Add: a typed text that is no address is answered under the field; an address is tested
  /// (the node gives its tip, the relay answers a handshake), then added and selected, so the
  /// Switch strip offers it. A failed test adds nothing.
  Future<void> _add(NetworkChoice choice) async {
    final l = context.l10n;
    final value = _typedValue();
    if (value == null) {
      setState(() => _fieldError = l.slNotAnAddress);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _adding = true;
      _fieldError = null;
    });
    try {
      if (_node) {
        // The node call needs no wallet, so no data directory.
        await askNodeTip(
          ref.read(walletServiceProvider),
          ref.read(sessionProvider),
          choice.preset.config(dataDir: '', nodeUrl: value),
        );
      } else {
        final relay = EpicboxRelay.parse(value)!;
        if (!await ref.read(relayProbeProvider).reachable(relay)) {
          if (!mounted) return;
          setState(() {
            _adding = false;
            _fieldError = l.slRelayNoAnswer;
          });
          return;
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _adding = false;
        _fieldError = l.serverTestFailed(describeError(l, error));
      });
      return;
    }
    if (!mounted) return;
    await ref.read(serverListProvider((widget.kind, choice.preset.chain)).notifier).add(value);
    if (!mounted) return;
    _field.clear();
    setState(() => _adding = false);
    _say(
      l.slAdded(serverHost(value)),
      action: () => _pick(value, choice),
      actionLabel: l.slSwitch,
    );
    // The new row is the last: bring it into view once the store has written and the list
    // rebuilt with it (a frame or two later).
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      final scroll = widget.scrollController;
      if (!mounted || scroll == null || !scroll.hasClients) return;
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _remove(_Entry e, NetworkChoice choice) async {
    final l = context.l10n;
    if (_same(e.value, _current(choice))) {
      _say(l.slInUseSwitchFirst, note: true);
      return;
    }
    final notifier = ref.read(serverListProvider((widget.kind, choice.preset.chain)).notifier);
    final at = await notifier.remove(e.value);
    if (!mounted) return;
    _say(
      l.slRemoved(e.host),
      action: () async {
        await notifier.add(e.value, at: at);
        if (mounted) _say(l.slAdded(e.host));
      },
    );
  }

  Future<void> _restore(NetworkChoice choice, List<String> public) async {
    await ref.read(serverListProvider((widget.kind, choice.preset.chain)).notifier).restore(public);
    if (mounted) _say(context.l10n.slRestored);
  }

  Future<void> _switchTo(String value, NetworkChoice choice) async {
    setState(() => _busy = true);
    try {
      final nodeUrl = _node ? value : choice.nodeUrl;
      final relay = _node ? choice.relay : EpicboxRelay.parse(value);
      if (relay == null) {
        setState(() => _busy = false);
        return;
      }
      final live = await widget.liveSwitch(ref, nodeUrl: nodeUrl, relay: relay);
      if (!mounted) return;
      if (live) {
        _field.clear();
        setState(() => _busy = false);
        _say(context.l10n.serverSwitched(serverHost(value)));
        return;
      }
      widget.afterSave(context);
      if (mounted) setState(() => _busy = false);
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _say(describeError(context.l10n, error), note: true);
      }
    }
  }

  // Rows.

  /// Every row of the list in its order, with what the directory knows of each.
  List<_Entry> _entries(NetworkChoice choice, ServerList list) {
    final preset = choice.preset;
    final nodes = ref.watch(publicNodeStatusProvider(preset));
    final relays = ref.watch(relayStatusProvider(preset));
    // Every icon the monitor holds, by operator: a server without one shows its operator's.
    final known = [
      for (final n in nodes.value ?? const <NodeStatus>[]) (operator: n.operator, icon: n.icon),
      for (final r in relays.value ?? const <RelayStatus>[]) (operator: r.operator, icon: r.icon),
    ];
    if (_node) {
      final public = mergePublicNodes(nodes.value, builtIn: builtInNodesFor(preset));
      return [
        for (final v in list.entries)
          () {
            final p = public.where((n) => _same(n.url, v)).firstOrNull;
            final s = p?.status ?? nodeStatusFor(nodes.value ?? const [], v);
            final operator = p?.operator ?? s?.operator;
            return _Entry(
              value: v,
              host: serverHost(v),
              operator: operator,
              tileName: s?.operator ?? operator,
              node: s,
              icon: serverIconFor(s?.icon, s?.operator ?? operator, known),
              directoryAnswered: nodes is AsyncData,
            );
          }(),
      ];
    }
    final public = mergePublicRelays(relays.value, builtIn: builtInRelaysFor(preset));
    return [
      for (final v in list.entries)
        () {
          final relay = EpicboxRelay.parse(v);
          final p = relay == null ? null : public.where((r) => r.relay == relay).firstOrNull;
          final op = p?.operator ?? '';
          final operator = op.isEmpty ? p?.status?.operator : op;
          return _Entry(
            value: v,
            host: v,
            operator: operator,
            tileName: p?.status?.operator ?? operator,
            relay: p?.status,
            icon: serverIconFor(p?.status?.icon, p?.status?.operator ?? operator, known),
            directoryAnswered: relays is AsyncData,
          );
        }(),
    ];
  }

  /// The public servers of the kind, built-in first, then the directory's, as values.
  List<String> _publicValues(NetworkChoice choice) {
    final preset = choice.preset;
    if (_node) {
      final status = ref.read(publicNodeStatusProvider(preset));
      return [
        for (final n in mergePublicNodes(status.value, builtIn: builtInNodesFor(preset))) n.url,
      ];
    }
    final status = ref.read(relayStatusProvider(preset));
    return [
      for (final r in mergePublicRelays(status.value, builtIn: builtInRelaysFor(preset)))
        r.relay.label,
    ];
  }

  bool _matches(_Entry e, String q) => serverMatches(q, host: e.host, operator: e.operator);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final choice = ref.watch(networkChoiceProvider).value;
    final title = _node ? l.serverNodeTitle : l.serverEpicboxTitle;
    final media = MediaQuery.of(context);
    final foot = math.max(media.padding.bottom, media.viewInsets.bottom);
    final line = _line;
    return LayoutBuilder(
      builder: (context, box) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                ),
                HelpButton(_node ? HelpId.node : HelpId.epicbox),
                IconButton(
                  tooltip: l.commonClose,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: choice == null
                ? const Center(child: CircularProgressIndicator())
                : _body(context, choice),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: line == null
                ? const SizedBox(width: double.infinity)
                : _FootLine(
                    line,
                    action: _lineAction,
                    actionLabel: _lineActionLabel ?? l.slUndo,
                    note: _lineIsNote,
                  ),
          ),
          SizedBox(height: foot),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, NetworkChoice choice) {
    final l = context.l10n;
    final t = context.tokens;
    final chain = choice.preset.chain;
    final listState = ref.watch(serverListProvider((widget.kind, chain))).value;
    final all = listState == null ? const <_Entry>[] : _entries(choice, listState);
    final q = _text;
    final filtering = q.isNotEmpty;
    final shown = filtering
        ? [
            for (final e in all)
              if (_matches(e, q)) e,
          ]
        : all;
    final typed = filtering ? _typedValue() : null;
    // Add shows as soon as nothing matches, whatever is typed (a tap says when it is no
    // address), and for an address no row has even while some rows match its text.
    final listedTyped = typed != null && all.any((e) => _same(e.value, typed));
    final showAdd = filtering && !listedTyped && (shown.isEmpty || typed != null || _adding);
    final addHost = typed == null ? q : (_node ? serverHost(typed) : typed);
    if (_node) ref.watch(nodeFailoverProvider);
    final current = _current(choice);
    final public = _publicValues(choice);
    if (listState != null) {
      // Directory servers join the list as they are seen; removed ones stay out. After the
      // frame, as the store is written and the list rebuilt.
      final missing = listState.missing(widget.kind, public);
      if (missing.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(serverListProvider((widget.kind, chain)).notifier).absorb(missing);
        });
      }
    }
    final restorable = listState == null
        ? const <String>[]
        : listState.restorable(widget.kind, public);
    final dirStatus = _node
        ? ref.watch(publicNodeStatusProvider(choice.preset))
        : ref.watch(relayStatusProvider(choice.preset));
    final nodeLocal = _node && torSkipsLocalNode && isLoopbackUrl(Uri.parse(choice.nodeUrl));
    // The health is the server's; the wallet's own connection to it can be down while the
    // server is up. Then the row in use says so, with Retry, which restarts the listener.
    final relayNotConnected = !_node && epicboxNotConnected(ref);

    // The field's helper: what typing does now.
    final String? helper;
    if (_fieldError != null) {
      helper = _fieldError!;
    } else if (!filtering) {
      helper = null;
    } else if (shown.isNotEmpty && showAdd) {
      helper = l.slHelpAddable;
    } else {
      // The one "No match." when nothing matches; the Add row sits under it.
      helper = l.slHelpMatches(shown.length);
    }

    // Only the list scrolls: the field with its line and the card of the server in use stay
    // put above it. The card folds away while the field filters or the keyboard is up, so the
    // field and the matches stay in view and the list takes the room left.
    final folded = filtering || MediaQuery.viewInsetsOf(context).bottom > 0;
    final pinned = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: serverListFieldKey,
          controller: _field,
          focusNode: _focus,
          keyboardType: TextInputType.url,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          style: TextStyle(fontFamily: t.monoFamily, fontSize: 14),
          onChanged: (_) => setState(() => _fieldError = null),
          onSubmitted: (_) => _submit(choice, all),
          decoration: InputDecoration(
            labelText: _node ? l.slNodeField : l.slRelayField,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: l.slFieldHint,
            hintMaxLines: 1,
            helperText: helper,
            helperMaxLines: 2,
            helperStyle: _fieldError != null ? TextStyle(color: t.risk) : null,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(
              filtering ? Icons.search : (_node ? Icons.dns_outlined : Icons.mail_outline),
              size: 20,
            ),
            suffixIcon: _adding
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _field.text.isEmpty
                ? null
                : IconButton(
                    key: serverListClearKey,
                    tooltip: l.slClear,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      _field.clear();
                      setState(() => _fieldError = null);
                    },
                  ),
          ),
        ),
        // The server in use: the node's facts, or the relay's address warning. Typing folds
        // them away so the matches sit by the field.
        AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: folded
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    if (_node)
                      _CurrentNodeFacts(choice: choice)
                    else
                      EdgeCard(
                        edge: t.warn,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 20, color: t.warn),
                              const SizedBox(width: 8),
                              Expanded(child: Text(l.slRelayWarning)),
                            ],
                          ),
                        ),
                      ),
                    if (!nodeLocal) ...[
                      const SizedBox(height: 8),
                      TorWayLine(route: _node ? TorRoute.node : TorRoute.epicbox),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 12),
      ],
    );
    final list = [
      if (showAdd)
        _AddRow(
          host: addHost,
          note: _node ? l.slAddTestsNode : l.slAddTestsRelay,
          busy: _adding,
          onTap: () => _add(choice),
        ),
      for (final e in shown) ...[
        _ServerRow(
          key: serverListRowKey(e.value),
          kind: widget.kind,
          entry: e,
          isDefault: !_node && EpicboxRelay.parse(e.value) == choice.preset.defaultRelay,
          current: _same(e.value, current),
          selected: _same(e.value, current),
          check: _same(e.value, current),
          onTap: () => _pick(e.value, choice),
          onRemove: () => _remove(e, choice),
        ),
        if (relayNotConnected &&
            _same(e.value, current) &&
            e.state == NodeHealthState.healthy)
          NotConnectedLine(
            onRetry: () => ref.read(listenerProvider.notifier).restart(),
          ),
      ],
      if (restorable.isNotEmpty && !filtering)
        _RestoreRow(count: restorable.length, onTap: () => _restore(choice, public)),
      _HealthCaption(status: dirStatus, preset: choice.preset),
    ];
    return LayoutBuilder(
      builder: (context, box) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // On a short phone with large text the pinned part could pass the sheet: it then
          // scrolls itself, within most of the height, and the list keeps the rest.
          ConstrainedBox(
            key: serverListPinnedKey,
            constraints: BoxConstraints(maxHeight: box.maxHeight * 0.7),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: pinned,
            ),
          ),
          Expanded(
            child: ListView(
              key: serverListListKey,
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: list,
            ),
          ),
        ],
      ),
    );
  }
}

// Rows.

/// One server: the operator's tile with the health dot, host in mono and its lag, under it
/// the facts; the check on the selected row and a remove button on every row.
class _ServerRow extends StatelessWidget {
  const _ServerRow({
    super.key,
    required this.kind,
    required this.entry,
    required this.isDefault,
    required this.current,
    required this.selected,
    required this.check,
    required this.onTap,
    required this.onRemove,
  });

  final ServerKind kind;
  final _Entry entry;
  final bool isDefault;
  final bool current;
  final bool selected;
  final bool check;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final e = entry;
    final state = e.state;
    final down = state == NodeHealthState.down;
    final unknown = state == null && e.directoryAnswered;
    final healthWord = switch (state) {
      NodeHealthState.healthy => l.serverHealthy,
      NodeHealthState.degraded => l.serverDegraded,
      NodeHealthState.down => l.serverNotResponding,
      _ => l.serverHealthNone,
    };
    final n = e.node;
    final lag = n?.tipLag;
    final tip = down || lag == null
        ? null
        : lag <= 0
        ? (text: l.serverAtTip, words: l.serverAtTip, color: t.ok)
        : (
            text: l.serverBehindShort(groupDigits(l, lag)),
            words: l.serverBehindLabel(lag),
            color: t.warn,
          );
    final latency = n?.latencyMs ?? e.relay?.latencyMs;
    final push = kind == ServerKind.relay && e.host == PushRegistration.relayHost;
    final facts = [
      if (current) l.serverCurrent,
      if (tip != null) tip.text,
      if (state == NodeHealthState.degraded) l.serverDegraded,
      if (down) l.serverNotResponding,
      if (unknown) l.serverHealthNone,
      if (e.operator != null && e.operator!.isNotEmpty) e.operator!,
      if (!down && latency != null) l.serverLatency(groupDigits(l, latency)),
      if (!down && n?.nodeVersion != null && n!.nodeVersion!.isNotEmpty) n.nodeVersion!,
      if (e.relay?.uptime24h != null)
        l.serverUptime(localDigits(l, (e.relay!.uptime24h! * 100).toStringAsFixed(1))),
    ];
    final words = down ? t.faint : t.text;
    final small = theme.textTheme.bodySmall?.copyWith(color: down ? t.faint : t.dim);
    final label = l.serverRowLabel(
      e.host,
      [
        if (current) l.serverCurrent,
        if (isDefault) l.serverDefault,
        if (push) l.serverSupportsNotifications,
        healthWord,
        if (e.operator != null && e.operator!.isNotEmpty) e.operator!,
        ?tip?.words,
        if (!down && latency != null) l.serverLatency(groupDigits(l, latency)),
      ].join(', '),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(t.radiusSmall),
          child: Ink(
            decoration: BoxDecoration(
              color: selected ? t.selected : null,
              border: Border.all(color: selected ? t.selectedLine : Colors.transparent),
              borderRadius: BorderRadius.circular(t.radiusSmall),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Row(
                  children: [
                    ServerTile(
                      operator: e.tileName,
                      host: e.host,
                      icon: e.icon,
                      state: state,
                      dimmed: down,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      e.host,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: t.monoFamily,
                                        fontSize: 13,
                                        color: words,
                                      ),
                                    ),
                                  ),
                                  if (isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: t.lineStrong),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        l.serverDefault,
                                        style: theme.textTheme.labelSmall?.copyWith(color: t.dim),
                                      ),
                                    ),
                                  ],
                                  if (push) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.notifications_outlined,
                                      size: 16,
                                      color: down ? t.faint : t.dim,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              _Facts(facts: facts, style: small, tip: tip),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 20,
                      child: check
                          ? Icon(
                              Icons.check,
                              size: 20,
                              color: state == NodeHealthState.healthy ? t.ok : t.dim,
                            )
                          : null,
                    ),
                    IconButton(
                      key: serverListRemoveKey(e.value),
                      tooltip: l.slRemove,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      icon: Icon(Icons.delete_outline, color: t.dim),
                      onPressed: onRemove,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The inline Add: the first row while the field holds an address that is not listed.
/// Tapping it tests the server, adds it and selects it for the switch.
class _AddRow extends StatelessWidget {
  const _AddRow({required this.host, required this.note, required this.busy, required this.onTap});

  final String host;
  final String note;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: l.slAddRow(host),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: serverListAddKey,
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(t.radiusSmall),
          child: Ink(
            decoration: BoxDecoration(
              border: Border.all(color: t.lineStrong),
              borderRadius: BorderRadius.circular(t.radiusSmall),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8, end: 12),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 36,
                      child: Center(
                        child: busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.add, color: t.accentText),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ExcludeSemantics(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: '${l.serverAdd} '),
                                  TextSpan(
                                    text: host,
                                    style: TextStyle(fontFamily: t.monoFamily, fontSize: 13),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: t.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(note, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                          ],
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
    );
  }
}

/// "Restore the public list" at the end of the list, only while a public server is removed.
class _RestoreRow extends StatelessWidget {
  const _RestoreRow({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: serverListRestoreKey,
          style: TextButton.styleFrom(foregroundColor: t.dim, minimumSize: const Size(48, 44)),
          onPressed: onTap,
          icon: const Icon(Icons.restore, size: 18),
          label: Text('${l.slRestore} · ${l.slRemovedCount(count)}'),
        ),
      ),
    );
  }
}

/// A row's second line: the facts joined by ` · `.
class _Facts extends StatelessWidget {
  const _Facts({required this.facts, required this.style, this.tip});

  final List<String> facts;
  final TextStyle? style;

  /// The node's lag (`at tip`, `−12`) and its colour, shown in mono among the facts.
  final ({String text, String words, Color color})? tip;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < facts.length; i++) ...[
            if (i > 0) const TextSpan(text: ' · '),
            TextSpan(
              text: facts[i],
              style: tip != null && facts[i] == tip!.text
                  ? TextStyle(color: tip!.color, fontFamily: t.monoFamily)
                  : facts[i] == l.serverNotResponding
                  ? TextStyle(color: t.risk)
                  : facts[i] == l.serverDegraded
                  ? TextStyle(color: t.warn)
                  : facts[i] == l.serverCurrent
                  ? TextStyle(color: t.text, fontWeight: FontWeight.w600)
                  : null,
            ),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

// The tile.

/// A server's tile in the phone's colours ([ServerTileView]): 36 dp, the operator's icon or
/// initials on a muted tint, the health dot green, amber or red, hollow when the monitor has
/// nothing on the server.
class ServerTile extends StatelessWidget {
  const ServerTile({
    super.key,
    required this.operator,
    required this.host,
    required this.icon,
    required this.state,
    this.dimmed = false,
    this.size = 36,
  });

  final String? operator;
  final String host;
  final ServerIcon? icon;
  final NodeHealthState? state;
  final bool dimmed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ServerTileView(
      operator: operator,
      host: host,
      icon: icon,
      state: state,
      dimmed: dimmed,
      size: size,
      radius: t.radiusSmall,
      fontFamily: montserrat,
      colors: ServerTileColors(
        surface: t.surface,
        line: t.line,
        initials: t.dim,
        tints: [
          t.accent.withValues(alpha: 0.14),
          t.info.withValues(alpha: 0.16),
          t.text.withValues(alpha: 0.08),
        ],
        ok: t.ok,
        warn: t.warn,
        risk: t.risk,
        unknown: t.faint,
        ring: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}

/// The key of the "Server up · not connected" line under the Epicbox server in use.
const Key serverNotConnectedKey = ValueKey('server-list-not-connected');

/// Whether the open wallet expects its Epicbox listener to be connected and it is not, as the
/// status shows it (offline once it lasts, or stopped). False without a wallet and in Offline
/// mode, where no listener runs.
bool epicboxNotConnected(WidgetRef ref) {
  if (ref.watch(sessionProvider) == null) return false;
  if (ref.watch(listenerProvider.select((l) => l.offline))) return false;
  final epicbox = ref.watch(walletStatusProvider.select((s) => s.epicbox));
  return epicbox == null || epicbox == EpicboxState.offline;
}

/// Under the Epicbox server in use while the monitor says it is up and this wallet is not
/// connected to it: "Server up · not connected" and Retry, which restarts the listener.
class NotConnectedLine extends StatelessWidget {
  const NotConnectedLine({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Padding(
      key: serverNotConnectedKey,
      padding: const EdgeInsetsDirectional.only(start: 8, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.unsubscribe_outlined, size: 18, color: t.risk),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                l.serverUpNotConnected,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.risk),
              ),
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l.commonRetry),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

// The foot.

/// One line at the sheet's foot that says what the last action did, with a check before it
/// and, when the action can be undone, Undo at its end; read out as it appears.
class _FootLine extends StatelessWidget {
  const _FootLine(this.text, {this.action, required this.actionLabel, this.note = false});

  final String text;
  final VoidCallback? action;
  final String actionLabel;

  /// A refusal: an info mark in the dim colour instead of the green check.
  final bool note;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      key: serverListFootKey,
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.line)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 4),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(
              note ? Icons.info_outline : Icons.check_circle_outline,
              size: 18,
              color: note ? t.dim : t.ok,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.text),
              ),
            ),
            if (action != null)
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
                onPressed: action,
                child: Text(actionLabel),
              )
            else
              const SizedBox(height: 44),
          ],
        ),
      ),
    );
  }
}

/// Under the list: a thin bar while status.btlabs.uk is asked, the "health unknown" line when
/// it did not answer, nothing when the user turned it off or the network has no monitor.
class _HealthCaption extends ConsumerWidget {
  const _HealthCaption({required this.status, required this.preset});

  final AsyncValue<Object?> status;
  final NetworkPreset preset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (preset.statusChain == null) return const SizedBox.shrink();
    return switch (status) {
      AsyncData() => const SizedBox.shrink(),
      AsyncError() when ref.watch(useStatusSiteProvider) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          context.l10n.serverHealthUnknown,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.tokens.dim),
        ),
      ),
      AsyncError() => const SizedBox.shrink(),
      _ => const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(minHeight: 2),
      ),
    };
  }
}

/// The node in use, under the field that holds its address: its state word, then Height
/// (with `at tip`), Version, Peers and Uptime 24 h as a grid, each only when known; then the
/// monitor's view of the network and when it last checked.
class _CurrentNodeFacts extends ConsumerWidget {
  const _CurrentNodeFacts({required this.choice});

  final NetworkChoice choice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final wallet = watchWalletStatus(ref).node;
    final listed = ref.watch(publicNodeStatusProvider(choice.preset)).value;
    final net = ref.watch(networkStatusProvider(choice.preset)).value;
    final nodeUrl = ref.watch(nodeFailoverProvider)?.inUse ?? choice.nodeUrl;
    final dirNode = nodeStatusFor(listed ?? const [], nodeUrl);
    final height = wallet.tip?.height.toInt() ?? dirNode?.height;
    final tipHeight = net?.tipHeight;
    final behind = height != null && tipHeight != null
        ? (tipHeight - height).clamp(0, 1 << 31)
        : dirNode?.tipLag;
    final face = nodeNetFace(context, wallet, behind: behind);
    final version = wallet.tip?.nodeVersion.isNotEmpty == true
        ? wallet.tip!.nodeVersion
        : dirNode?.nodeVersion;
    final facts = <(String, String)>[
      if (height != null)
        (
          l.serverFactHeight,
          behind != null && behind < behindAfter
              ? l.serverHeightAtTip(groupDigits(l, height))
              : groupDigits(l, height),
        ),
      if (version != null && version.isNotEmpty) (l.serverFactVersion, version),
      if (dirNode?.peers != null) (l.serverFactPeers, groupDigits(l, dirNode!.peers!)),
      if (dirNode?.uptime24h != null)
        (l.serverFactUptime, '${localDigits(l, (dirNode!.uptime24h! * 100).toStringAsFixed(1))} %'),
    ];
    final age = net?.tipAgeSeconds;
    final network = [
      if (net?.tipHeight != null) l.serverNodesAgree(groupDigits(l, net!.tipHeight!)),
      if (net?.nodesHealthy != null && net?.nodesTotal != null)
        l.serverNodesUp(net!.nodesHealthy!, net.nodesTotal!),
      if (age != null)
        age < 120 ? l.serverLastBlockSeconds(age) : l.serverLastBlockMinutes(age ~/ 60),
    ];
    final checked = dirNode?.lastCheckedAt;
    final small = theme.textTheme.bodySmall?.copyWith(color: t.dim);
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(t.radiusSmall),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            liveRegion: true,
            label: [l.serverCurrent, serverHost(nodeUrl), face.word].join(', '),
            excludeSemantics: true,
            child: Row(
              children: [
                SignalBars(
                  level: face.level,
                  color: face.color,
                  pulse: wallet.state == NodeState.syncing,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.serverCurrent,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: t.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(face.word, style: theme.textTheme.bodySmall?.copyWith(color: face.color)),
              ],
            ),
          ),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, box) {
                final w = (box.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final (label, value) in facts)
                      SizedBox(
                        width: w,
                        child: MergeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label, style: small),
                              Text(
                                value,
                                style: TextStyle(
                                  fontFamily: t.monoFamily,
                                  fontSize: 13,
                                  color: t.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          if (network.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(network.join(' · '), style: small),
          ],
          if (checked != null)
            Text(l.serverCheckedAt(localClock(l, checked.toLocal())), style: small),
        ],
      ),
    );
  }
}

/// A dialog title that carries a host: the usual title size when every word fits the line,
/// else the next size down, so a long host never breaks mid-word on a narrow phone. The line
/// is measured from the screen (an AlertDialog sizes its title intrinsically, so no
/// LayoutBuilder): the dialog's inset and its title padding, 24 dp each side.
class _FitTitle extends StatelessWidget {
  const _FitTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usual = theme.dialogTheme.titleTextStyle ?? theme.textTheme.headlineSmall!;
    final sizes = [usual, theme.textTheme.titleLarge!, theme.textTheme.titleMedium!];
    final longest = text.split(' ').reduce((a, b) => a.length >= b.length ? a : b);
    final media = MediaQuery.of(context);
    final line = math.min(media.size.width, 560.0) - 2 * 40 - 2 * 24;
    final style = sizes.firstWhere((s) {
      final painter = TextPainter(
        text: TextSpan(text: longest, style: s),
        textDirection: Directionality.of(context),
        textScaler: media.textScaler,
        maxLines: 1,
      )..layout();
      return painter.width <= line;
    }, orElse: () => sizes.last);
    return Text(text, style: style);
  }
}
