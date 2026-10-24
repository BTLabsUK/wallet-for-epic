/// The phone's Node and Epicbox pickers as one list per kind (design mockup, branch
/// `design/server-list-crud`): one stored list seeded from the built-in servers and
/// status.btlabs.uk, which the user edits in place; one field at the top that holds the
/// address in use, filters the list while typed in, and adds what matches nothing.
///
/// Store: [serverListProvider], one JSON object per kind and chain under
/// `app.serverList.<kind>.<chain>`: `entries` (values in list order) and `removed` (keys of
/// public servers the user took out, so a directory update does not bring them back).
/// Directory servers not yet in the list are absorbed as they are seen ([ServerListNotifier.absorb]);
/// "Restore the public list" forgets `removed` and puts the public ones back.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals, setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../errors.dart';
import '../l10n.dart';
import '../models.dart' show Chain;
import '../network.dart';
import '../providers.dart';
import '../public_servers.dart';
import '../push_registration.dart' show PushRegistration;
import '../relay_directory.dart';
import '../secret_store_api.dart' show SecretStore;
import '../server_switch.dart';
import '../net/tor_net.dart' show isLoopbackUrl;
import '../tor_routes.dart' show TorRoute, torSkipsLocalNode;
import 'common.dart' show groupDigits;
import 'help_screen.dart' show HelpButton, HelpId;
import 'notices.dart';
import 'server_picker.dart'
    show
        ServerKind,
        builtInNodesFor,
        builtInRelaysFor,
        myNodesKey,
        myRelaysKey,
        networkStatusProvider,
        publicNodeStatusProvider,
        relaunchAfterSwitch,
        typedNodeUrl;
import 'status.dart' hide NodeStatus;
import 'theme/protocol.dart';
import 'theme/tokens.dart';
import 'tor_ui.dart' show TorWayLine;

// The store.

/// The secret-store key of a kind's list on a chain.
String serverListKey(ServerKind kind, Chain chain) =>
    'app.serverList.${kind.name}.${chain.name}';

/// What makes two values the same server: `host:port` for nodes, the label for relays.
String serverKeyOf(ServerKind kind, String value) => kind == ServerKind.node
    ? (nodeKey(value) ?? value)
    : (EpicboxRelay.parse(value)?.label ?? value);

/// One kind's list: the values in their order, and the keys of public servers the user removed.
class ServerListState {
  const ServerListState({required this.entries, required this.removed});

  final List<String> entries;
  final Set<String> removed;

  bool has(ServerKind kind, String value) {
    final key = serverKeyOf(kind, value);
    return entries.any((e) => serverKeyOf(kind, e) == key);
  }
}

/// The user's list of a kind on a chain, seeded once from the built-in servers (and the old
/// "My nodes" / "My servers" lists), then grown from the directory by [absorb].
final serverListProvider = AsyncNotifierProvider.family<
  ServerListNotifier,
  ServerListState,
  (ServerKind, Chain)
>(ServerListNotifier.new);

class ServerListNotifier extends AsyncNotifier<ServerListState> {
  ServerListNotifier(this.arg);

  final (ServerKind, Chain) arg;

  ServerKind get kind => arg.$1;
  Chain get chain => arg.$2;

  String _key(String value) => serverKeyOf(kind, value);

  List<String> get _builtIn {
    final preset = networkPresets.firstWhere((p) => p.chain == chain);
    return kind == ServerKind.node
        ? [for (final n in builtInNodesFor(preset)) n.url]
        : [for (final r in builtInRelaysFor(preset)) r.relay.label];
  }

  @override
  Future<ServerListState> build() async {
    final store = ref.watch(secretStoreProvider);
    final raw = await store.read(serverListKey(kind, chain));
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return ServerListState(
            entries: [
              if (decoded['entries'] is List)
                for (final e in decoded['entries'] as List)
                  if (e is String && e.isNotEmpty) e,
            ],
            removed: {
              if (decoded['removed'] is List)
                for (final e in decoded['removed'] as List)
                  if (e is String && e.isNotEmpty) e,
            },
          );
        }
      } on FormatException {
        // A broken record seeds again.
      }
    }
    // First use: the built-in servers, then what the old "My" list held by hand.
    final seed = [..._builtIn];
    final old = await store.read(
      kind == ServerKind.node ? myNodesKey(chain) : myRelaysKey(chain),
    );
    if (old != null) {
      try {
        final decoded = jsonDecode(old);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is String && e.isNotEmpty && !seed.any((s) => _key(s) == _key(e))) {
              seed.add(e);
            }
          }
        }
      } on FormatException {
        // Nothing to carry over.
      }
    }
    final state = ServerListState(entries: seed, removed: const {});
    await _write(store, state);
    return state;
  }

  Future<void> _write(SecretStore store, ServerListState s) async {
    state = AsyncData(s);
    await store.write(
      serverListKey(kind, chain),
      jsonEncode({'entries': s.entries, 'removed': [...s.removed]}),
    );
  }

  /// Directory servers seen now: those neither listed nor removed join the end of the list.
  Future<void> absorb(Iterable<String> values) async {
    final now = await future;
    final entries = [...now.entries];
    for (final v in values) {
      final k = _key(v);
      if (now.removed.contains(k)) continue;
      if (entries.any((e) => _key(e) == k)) continue;
      entries.add(v);
    }
    if (listEquals(entries, now.entries)) return;
    await _write(
      ref.read(secretStoreProvider),
      ServerListState(entries: entries, removed: now.removed),
    );
  }

  /// Adds [value] (at [at], else last). Its key leaves `removed`, so it stays.
  Future<void> add(String value, {int? at}) async {
    final now = await future;
    final k = _key(value);
    if (now.entries.any((e) => _key(e) == k)) return;
    final entries = [...now.entries];
    entries.insert(at == null ? entries.length : at.clamp(0, entries.length), value);
    await _write(
      ref.read(secretStoreProvider),
      ServerListState(entries: entries, removed: {...now.removed}..remove(k)),
    );
  }

  /// Takes [value] out; its key is remembered as removed, so a directory update does not
  /// bring it back. Returns where it was, for Undo.
  Future<int?> remove(String value) async {
    final now = await future;
    final k = _key(value);
    final i = now.entries.indexWhere((e) => _key(e) == k);
    if (i < 0) return null;
    await _write(
      ref.read(secretStoreProvider),
      ServerListState(
        entries: [...now.entries]..removeAt(i),
        removed: {...now.removed, k},
      ),
    );
    return i;
  }

  /// Forgets every removal and puts the public servers ([values], built-in first) back at
  /// the end of the list, in their order.
  Future<void> restore(Iterable<String> values) async {
    final now = await future;
    final entries = [...now.entries];
    for (final v in values) {
      final k = _key(v);
      if (!entries.any((e) => _key(e) == k)) entries.add(v);
    }
    if (listEquals(entries, now.entries) && setEquals(now.removed, const {})) {
      return;
    }
    await _write(
      ref.read(secretStoreProvider),
      ServerListState(entries: entries, removed: const {}),
    );
  }
}

// The sheet.

/// Opens the node list over the current screen.
Future<void> showNodeListSheet(BuildContext context) =>
    _show(context, ServerKind.node);

/// Opens the Epicbox list over the current screen.
Future<void> showEpicboxListSheet(BuildContext context) =>
    _show(context, ServerKind.relay);

Future<void> _show(BuildContext context, ServerKind kind) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 1,
        builder: (context, scroll) =>
            ServerListSheet(kind: kind, scrollController: scroll),
      ),
    );

/// The key of the address field at the top, for tests.
const Key serverListFieldKey = ValueKey('server-list-field');

/// The key of the field's clear button, for tests.
const Key serverListClearKey = ValueKey('server-list-clear');

/// The key of the inline Add row, for tests.
const Key serverListAddKey = ValueKey('server-list-add');

/// The key of the Switch button in the confirm strip, for tests.
const Key serverListSwitchKey = ValueKey('server-list-switch');

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
    this.node,
    this.relay,
    required this.directoryAnswered,
  });

  final String value;
  final String host;
  final String? operator;
  final NodeStatus? node;
  final RelayStatus? relay;

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
    this.afterSave = relaunchAfterSwitch,
    this.liveSwitch = switchServersLive,
  });

  final ServerKind kind;
  final ScrollController? scrollController;
  final void Function(BuildContext context) afterSave;
  final Future<bool> Function(
    WidgetRef ref, {
    required String nodeUrl,
    required EpicboxRelay relay,
  })
  liveSwitch;

  @override
  ConsumerState<ServerListSheet> createState() => _ServerListSheetState();
}

class _ServerListSheetState extends ConsumerState<ServerListSheet> {
  final _field = TextEditingController();
  final _focus = FocusNode();

  /// The value tapped but not yet switched to.
  String? _pending;
  String? _fieldError;
  String? _switchError;
  bool _busy = false;

  /// Whether the typed server is being tested before it joins the list.
  bool _adding = false;

  /// What the last action did, at the foot for a few seconds, with Undo when it can be undone.
  String? _line;
  VoidCallback? _lineAction;
  Timer? _lineTimer;

  /// The address the field was last filled with by the sheet (the one in use).
  String _filled = '';

  bool get _node => widget.kind == ServerKind.node;

  @override
  void dispose() {
    _lineTimer?.cancel();
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _label(NetworkChoice choice) =>
      _node ? serverHost(choice.nodeUrl) : choice.relay.label;

  /// Fills the field with the address in use when the sheet opens and after a switch.
  void _fill(NetworkChoice choice) {
    final label = _label(choice);
    if (label == _filled) return;
    _filled = label;
    _field.text = label;
  }

  String get _text => _field.text.trim();

  /// Whether the field differs from the address in use: then it filters the list.
  bool get _dirty => _text != _filled;

  void _say(String text, {VoidCallback? action}) {
    _lineTimer?.cancel();
    setState(() {
      _line = text;
      _lineAction = action;
    });
    _lineTimer = Timer(
      noticeDuration(
        NoticeLevel.success,
        accessible:
            MediaQuery.accessibleNavigationOf(context) || action != null,
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
  String? _typedValue() => _node
      ? typedNodeUrl(_text)
      : EpicboxRelay.parse(_text)?.label;

  bool _same(String a, String b) =>
      serverKeyOf(widget.kind, a) == serverKeyOf(widget.kind, b);

  String _current(NetworkChoice choice) =>
      _node ? choice.nodeUrl : choice.relay.label;

  void _pick(String value, NetworkChoice choice) {
    final same = _same(value, _current(choice));
    FocusManager.instance.primaryFocus?.unfocus();
    if (same) {
      // The server in use: a pending choice is taken back, else the sheet says so and the
      // field goes back to the address in use.
      if (_pending == null) {
        _say(context.l10n.serverAlreadyInUse);
        if (_dirty) _field.text = _filled;
      }
      setState(() {
        _pending = null;
        _switchError = null;
      });
      return;
    }
    setState(() {
      _pending = value;
      _switchError = null;
    });
  }

  /// Done on the field: a listed address is picked, an unlisted one added, anything else
  /// answered under the field.
  void _submit(NetworkChoice choice, List<_Entry> all) {
    final value = _typedValue();
    if (value == null) {
      setState(() {
        _fieldError = _node
            ? context.l10n.serverOtherNodeInvalid
            : context.l10n.setupCustomRelayInvalid;
      });
      return;
    }
    final listed = all.where((e) => _same(e.value, value)).firstOrNull;
    if (listed != null) {
      _pick(listed.value, choice);
      return;
    }
    _add(value, choice);
  }

  Future<void> _add(String value, NetworkChoice choice) async {
    final l = context.l10n;
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
        // A relay handshake check is a LEPIC request (E-16); the mockup takes a moment.
        await Future<void>.delayed(const Duration(milliseconds: 700));
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
    await ref
        .read(serverListProvider((widget.kind, choice.preset.chain)).notifier)
        .add(value);
    if (!mounted) return;
    _field.text = _filled;
    setState(() {
      _adding = false;
      _pending = value;
      _switchError = null;
    });
    _say(l.slAdded(serverHost(value)));
  }

  Future<void> _remove(_Entry e, NetworkChoice choice) async {
    final l = context.l10n;
    if (_same(e.value, _current(choice))) {
      _say(l.slInUseSwitchFirst);
      return;
    }
    final notifier = ref.read(
      serverListProvider((widget.kind, choice.preset.chain)).notifier,
    );
    final at = await notifier.remove(e.value);
    if (!mounted) return;
    if (_pending != null && _same(_pending!, e.value)) {
      setState(() => _pending = null);
    }
    _say(
      l.slRemoved(e.host),
      action: () async {
        await notifier.add(e.value, at: at);
        if (mounted) _say(l.slAdded(e.host));
      },
    );
  }

  Future<void> _restore(NetworkChoice choice, List<String> public) async {
    await ref
        .read(serverListProvider((widget.kind, choice.preset.chain)).notifier)
        .restore(public);
    if (mounted) _say(context.l10n.slRestored);
  }

  Future<void> _switch(NetworkChoice choice) async {
    final value = _pending;
    if (value == null) return;
    setState(() {
      _busy = true;
      _switchError = null;
    });
    try {
      final nodeUrl = _node ? value : choice.nodeUrl;
      final relay = _node ? choice.relay : EpicboxRelay.parse(value);
      if (relay == null) return;
      final live = await widget.liveSwitch(ref, nodeUrl: nodeUrl, relay: relay);
      if (!mounted) return;
      if (live) {
        final host = _node ? serverHost(nodeUrl) : relay.label;
        Navigator.of(context).maybePop();
        ref
            .read(noticeProvider.notifier)
            .show(context.l10n.serverSwitched(host), level: NoticeLevel.success);
        return;
      }
      widget.afterSave(context);
      if (mounted) {
        setState(() {
          _busy = false;
          _pending = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _switchError = describeError(context.l10n, error);
        });
      }
    }
  }

  // Rows.

  /// Every row of the list in its order, with what the directory knows of each.
  List<_Entry> _entries(NetworkChoice choice, ServerListState list) {
    final preset = choice.preset;
    if (_node) {
      final status = ref.watch(publicNodeStatusProvider(preset));
      final public = mergePublicNodes(status.value, builtIn: builtInNodesFor(preset));
      return [
        for (final v in list.entries)
          () {
            final p = public.where((n) => _same(n.url, v)).firstOrNull;
            final s = p?.status ?? nodeStatusFor(status.value ?? const [], v);
            return _Entry(
              value: v,
              host: serverHost(v),
              operator: p?.operator ?? s?.operator,
              node: s,
              directoryAnswered: status is AsyncData,
            );
          }(),
      ];
    }
    final status = ref.watch(relayStatusProvider(preset));
    final public = mergePublicRelays(status.value, builtIn: builtInRelaysFor(preset));
    return [
      for (final v in list.entries)
        () {
          final relay = EpicboxRelay.parse(v);
          final p = relay == null
              ? null
              : public.where((r) => r.relay == relay).firstOrNull;
          final op = p?.operator ?? '';
          return _Entry(
            value: v,
            host: v,
            operator: op.isEmpty ? p?.status?.operator : op,
            relay: p?.status,
            directoryAnswered: status is AsyncData,
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
        for (final n in mergePublicNodes(status.value, builtIn: builtInNodesFor(preset)))
          n.url,
      ];
    }
    final status = ref.read(relayStatusProvider(preset));
    return [
      for (final r in mergePublicRelays(status.value, builtIn: builtInRelaysFor(preset)))
        r.relay.label,
    ];
  }

  bool _matches(_Entry e, String q) {
    final needle = q.contains('://') ? serverHost(q) : q;
    return e.host.toLowerCase().contains(needle.toLowerCase()) ||
        (e.operator ?? '').toLowerCase().contains(q.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final choice = ref.watch(networkChoiceProvider).value;
    final title = _node ? l.serverNodeTitle : l.serverEpicboxTitle;
    final media = MediaQuery.of(context);
    final foot = math.max(media.padding.bottom, media.viewInsets.bottom);
    if (choice != null) _fill(choice);
    final line = _line;
    return Column(
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
        if (choice != null)
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (line != null)
                  _FootLine(line, action: _lineAction, actionLabel: l.slUndo),
                if (_pending != null || _switchError != null)
                  _ConfirmStrip(
                    host: _pending == null ? null : serverHost(_pending!),
                    note: _node ? l.serverNodeSwitchNote : l.serverRelaySwitchNote,
                    warn: !_node,
                    error: _switchError,
                    busy: _busy,
                    onSwitch: () => _switch(choice),
                    onCancel: () => setState(() {
                      _pending = null;
                      _switchError = null;
                    }),
                  ),
              ],
            ),
          ),
        SizedBox(height: foot),
      ],
    );
  }

  Widget _body(BuildContext context, NetworkChoice choice) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final chain = choice.preset.chain;
    final listState = ref.watch(serverListProvider((widget.kind, chain))).value;
    final all = listState == null
        ? const <_Entry>[]
        : _entries(choice, listState);
    final q = _text;
    final filtering = _dirty && q.isNotEmpty;
    final shown = filtering ? [for (final e in all) if (_matches(e, q)) e] : all;
    final typed = filtering ? _typedValue() : null;
    final addable =
        typed != null && !all.any((e) => _same(e.value, typed)) && !_adding
        ? typed
        : _adding
        ? typed
        : null;
    final current = _current(choice);
    final selected = _pending ?? current;
    final selectedListed = all.any((e) => _same(e.value, selected));
    final public = _publicValues(choice);
    if (listState != null) {
      // Directory servers join the list as they are seen; removed ones stay out. After the
      // frame, as the store is written and the list rebuilt.
      final missing = [
        for (final v in public)
          if (!listState.has(widget.kind, v) &&
              !listState.removed.contains(serverKeyOf(widget.kind, v)))
            v,
      ];
      if (missing.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref
              .read(serverListProvider((widget.kind, chain)).notifier)
              .absorb(missing);
        });
      }
    }
    final restorable = listState == null
        ? const <String>[]
        : [
            for (final v in public)
              if (listState.removed.contains(serverKeyOf(widget.kind, v))) v,
          ];
    final dirStatus = _node
        ? ref.watch(publicNodeStatusProvider(choice.preset))
        : ref.watch(relayStatusProvider(choice.preset));
    final nodeLocal =
        _node && torSkipsLocalNode && isLoopbackUrl(Uri.parse(choice.nodeUrl));
    final small = theme.textTheme.bodySmall?.copyWith(color: t.dim);

    // The field's helper: what typing does now.
    final String helper;
    if (_fieldError != null) {
      helper = _fieldError!;
    } else if (!filtering) {
      helper = _node ? l.slHelpIdleNode : l.slHelpIdleRelay;
    } else if (addable != null) {
      helper = l.slHelpAddable;
    } else {
      helper = l.slHelpMatches(shown.length);
    }

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
            helperText: helper,
            helperMaxLines: 2,
            helperStyle: _fieldError != null
                ? TextStyle(color: t.risk)
                : null,
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
        // The server in use, while the field still holds it: the node's facts, or the
        // relay's address warning. Typing folds them away so the matches sit by the field.
        AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: filtering
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
        if (addable != null)
          _AddRow(
            host: _node ? serverHost(addable) : addable,
            note: _node ? l.slAddTestsNode : l.slAddTestsRelay,
            busy: _adding,
            onTap: () => _add(addable, choice),
          ),
        for (final e in shown)
          _ServerRow(
            key: serverListRowKey(e.value),
            kind: widget.kind,
            entry: e,
            isDefault: !_node &&
                EpicboxRelay.parse(e.value) == choice.preset.defaultRelay,
            current: _same(e.value, current),
            selected: _same(e.value, selected),
            check: _same(e.value, selected) ||
                (_same(e.value, current) && !selectedListed),
            onTap: () => _pick(e.value, choice),
            onRemove: () => _remove(e, choice),
          ),
        if (shown.isEmpty && addable == null && filtering)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(l.slNoMatchHint, style: small),
          ),
        if (restorable.isNotEmpty && !filtering)
          _RestoreRow(
            count: restorable.length,
            onTap: () => _restore(choice, public),
          ),
        _HealthCaption(status: dirStatus, preset: choice.preset),
      ],
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
              border: Border.all(
                color: selected ? t.selectedLine : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(t.radiusSmall),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Row(
                  children: [
                    ServerTile(
                      operator: e.operator,
                      host: e.host,
                      state: state,
                      known: state != null,
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
                                  if (tip != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      tip.text,
                                      style: TextStyle(
                                        fontFamily: t.monoFamily,
                                        fontSize: 12,
                                        color: tip.color,
                                      ),
                                    ),
                                  ],
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
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(color: t.dim),
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
                              _Facts(facts: facts, style: small),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 24,
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
  const _AddRow({
    required this.host,
    required this.note,
    required this.busy,
    required this.onTap,
  });

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
                            Text(
                              note,
                              style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
                            ),
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
          style: TextButton.styleFrom(
            foregroundColor: t.dim,
            minimumSize: const Size(48, 44),
          ),
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
  const _Facts({required this.facts, required this.style});

  final List<String> facts;
  final TextStyle? style;

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
              style: facts[i] == l.serverNotResponding
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

/// Operators whose mark the app carries.
const String _btLabs = 'BT Labs';

/// The initials a tile shows for an operator, else for a host: two letters from the first
/// two words (a camel-cased name splits), or the first two of a one-word name; a host gives
/// the first two of its first label past `node.` or `epicbox.`.
String serverInitials(String? operator, String host) {
  final name = (operator ?? '').trim();
  if (name.isNotEmpty) {
    final words = name
        .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
        .split(RegExp(r'[\s\-_.]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length >= 2) return (words[0][0] + words[1][0]).toUpperCase();
    if (words.length == 1) {
      final w = words[0];
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
  }
  final labels = host
      .split(':')
      .first
      .split('.')
      .where((p) => p.isNotEmpty && !const {'node', 'epicbox', 'www'}.contains(p))
      .toList();
  if (labels.isEmpty) return '?';
  final w = labels.first;
  return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
}

/// A server's tile: 36 dp in the surface colour with the hairline and the small radius, the
/// operator's mark (BT Labs) or its initials on a muted tint, and the health dot in the
/// corner: green, amber or red, hollow when the directory has nothing on the server.
class ServerTile extends StatelessWidget {
  const ServerTile({
    super.key,
    required this.operator,
    required this.host,
    required this.state,
    required this.known,
    this.dimmed = false,
    this.size = 36,
  });

  final String? operator;
  final String host;
  final NodeHealthState? state;

  /// Whether the directory has the server's health: false draws the dot hollow.
  final bool known;
  final bool dimmed;
  final double size;

  bool get _logo => operator == _btLabs || host.endsWith('btlabs.uk');

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dot = switch (state) {
      NodeHealthState.healthy => t.ok,
      NodeHealthState.degraded => t.warn,
      NodeHealthState.down => t.risk,
      _ => t.faint,
    };
    // A muted tint per operator, from the palette: the accent, the info blue or the text
    // colour at a low alpha, picked by the name so one operator keeps its tint everywhere.
    final seed = (operator ?? host).toLowerCase().codeUnits.fold<int>(
      17,
      (a, c) => (a * 31 + c) & 0x7fffffff,
    );
    final tint = switch (seed % 3) {
      0 => t.accent.withValues(alpha: 0.14),
      1 => t.info.withValues(alpha: 0.16),
      _ => t.text.withValues(alpha: 0.08),
    };
    return ExcludeSemantics(
      child: Opacity(
        opacity: dimmed ? 0.55 : 1,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: _logo ? t.surface : Color.alphaBlend(tint, t.surface),
                  border: Border.all(color: t.line),
                  borderRadius: BorderRadius.circular(t.radiusSmall),
                ),
                alignment: Alignment.center,
                child: _logo
                    ? Padding(
                        padding: EdgeInsets.all(size * 0.14),
                        child: SvgPicture(
                          SvgAssetLoader(
                            'assets/brand/btlabs-lion.svg',
                            colorMapper: _LionColors(gold: t.accent, silver: t.dim),
                          ),
                        ),
                      )
                    : Text(
                        serverInitials(operator, host),
                        style: TextStyle(
                          fontFamily: montserrat,
                          fontWeight: FontWeight.w600,
                          fontSize: size * 0.33,
                          letterSpacing: 0.5,
                          color: t.dim,
                          height: 1,
                        ),
                      ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: known ? dot : t.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: known ? Theme.of(context).colorScheme.surface : t.faint,
                      width: known ? 2 : 1.5,
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

/// The lion's two flat colours to the theme's: the gold to the accent, the silver to dim.
class _LionColors extends ColorMapper {
  const _LionColors({required this.gold, required this.silver});

  final Color gold, silver;

  static const _gold = Color(0xFFC9A24A), _silver = Color(0xFFC4C6CC);

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) =>
      switch (color) {
        _gold => gold,
        _silver => silver,
        _ => color,
      };

  @override
  bool operator ==(Object other) =>
      other is _LionColors && other.gold == gold && other.silver == silver;

  @override
  int get hashCode => Object.hash(gold, silver);
}

// The foot.

/// One line at the sheet's foot that says what the last action did, with a check before it
/// and, when the action can be undone, Undo at its end; read out as it appears.
class _FootLine extends StatelessWidget {
  const _FootLine(this.text, {this.action, required this.actionLabel});

  final String text;
  final VoidCallback? action;
  final String actionLabel;

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
            Icon(Icons.check_circle_outline, size: 18, color: t.ok),
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

/// The strip at the sheet's foot: what a switch does with Cancel beside it, then
/// `Switch to host` full width and 48 dp tall.
class _ConfirmStrip extends StatelessWidget {
  const _ConfirmStrip({
    required this.host,
    required this.note,
    required this.warn,
    required this.error,
    required this.busy,
    required this.onSwitch,
    required this.onCancel,
  });

  final String? host;
  final String note;
  final bool warn;
  final String? error;
  final bool busy;
  final VoidCallback onSwitch;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    error ?? note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: error != null
                          ? t.risk
                          : warn
                          ? t.warn
                          : t.dim,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
                onPressed: busy ? null : onCancel,
                child: Text(l.commonCancel),
              ),
            ],
          ),
          if (host != null) ...[
            const SizedBox(height: 4),
            FilledButton(
              key: serverListSwitchKey,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: busy ? null : onSwitch,
              child: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l.serverSwitchTo(host!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ],
        ],
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
    final dirNode = nodeStatusFor(listed ?? const [], choice.nodeUrl);
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
        (
          l.serverFactUptime,
          '${localDigits(l, (dirNode!.uptime24h! * 100).toStringAsFixed(1))} %',
        ),
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
            label: [l.serverCurrent, serverHost(choice.nodeUrl), face.word].join(', '),
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
