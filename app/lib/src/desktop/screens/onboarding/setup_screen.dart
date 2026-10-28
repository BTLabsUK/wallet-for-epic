// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../network.dart' show EpicboxRelay, defaultEpicboxHost;
import '../../data/desk_node.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../settings/local_node_dialogs.dart' show showReuseChainDataDialog, fallbackAskedThisSession;
import '../settings/prefs.dart' show settingsPrefsProvider;
import '../settings/settings_node.dart' show hostOf, nodeUrlOf, serverRows, nodeListNoteText;
import '../../widgets/server_list_panel.dart';
import '../../data/server_lists.dart';
import '../../../log.dart';
import '../../../net/probe_not_run.dart';
import '../../../send_preflight.dart' show relayProbeProvider;
import 'local_node_step.dart';
import 'onboarding_parts.dart';

/// The steps: preferences (only with languages), node, the local node's own step when
/// Local was chosen (same rail position), Epicbox, review.
enum SetupStep { prefs, node, local, epicbox, review }

/// A tour start state: the step, and for the local step which probe answer to show.
@immutable
class SetupDemo {
  const SetupDemo(this.step, {this.local = LocalNodeDemo.none, this.localChosen = false, this.listOpen = false, this.first, this.saveFailed = false});

  final SetupStep step;
  final LocalNodeDemo local;

  /// The Review step with the local node chosen.
  final bool localChosen;

  /// The node or Epicbox step with its server list open.
  final bool listOpen;

  /// A first run (fresh or resumed) instead of Setup run again.
  final SetupFirstRun? first;

  /// Review after a failed Save (the wallet was locked).
  final bool saveFailed;
}

/// The first run of a wallet just made or restored (password, phrase, Node, Epicbox,
/// Review, Unlock): setup starts on the node step with no way back to the phrase, and Save goes
/// to Unlock with [added]. [second] marks one more wallet on a computer that has one: the node
/// is app-wide, so it starts as the current one.
@immutable
class SetupFirstRun {
  const SetupFirstRun(this.added, {this.second = false, this.resumed = false});

  final UnlockAdded added;
  final bool second;

  /// Unlock sent the wallet back: its setup was not saved before the app closed.
  final bool resumed;
}

/// Wallets whose first-run setup was skipped after Save failed: Unlock does not send them
/// back to Setup in this session, even when the pending mark could not be cleared.
final Set<String> setupSkippedThisSession = {};

/// The setup steps. [arg] is a [SetupStep], a [SetupDemo] or a [SetupFirstRun].
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  /// The Epicbox server chosen (its label), and whether the wallet receives through Epicbox.
  String _relay = defaultEpicboxHost;
  bool _epicboxOn = true;
  SetupFirstRun? get _first => widget.arg is SetupFirstRun ? widget.arg! as SetupFirstRun : _demo?.first;
  late final List<SetupStep> _steps = [if (DeskFeatures.languages && _first == null) SetupStep.prefs, SetupStep.node, SetupStep.epicbox, SetupStep.review];

  SetupDemo? get _demo => widget.arg is SetupDemo ? widget.arg! as SetupDemo : null;
  SetupStep get _startStep => _demo?.step ?? (widget.arg is SetupStep ? widget.arg! as SetupStep : _steps.first);

  // Lazy: [_steps] needs the widget.
  late SetupStep _step = _startStep == SetupStep.local || _steps.contains(_startStep) ? _startStep : _steps.first;
  /// The language picked on Preferences: a code, or null for the computer's.
  late String? _language = ref.read(deskProvider).settings.language;

  /// Local node chosen on the node step (the bundled node or one already running here).
  late bool _local = _startStep == SetupStep.local || (_demo?.localChosen ?? false);
  LocalNodeChoice? _localChoice;

  /// The remote node: null until a node's check came back healthy or the user picked one.
  String? _nodeUrl;

  /// The user picked a node: nothing is preselected over it any more.
  bool _picked = false;

  /// Setup run again from Settings: it starts from the wallet's current node and preselects
  /// nothing; Save changes the node only when the choice changed.
  late final bool _rerun;
  late final bool _wasBuiltin;

  /// The node in use before this run (a second wallet's first run: the app-wide one).
  String? _currentNode;
  /// The newest node list, from the wallet's changes or the first fetch.
  List<NodeServer>? _nodes;
  StreamSubscription<void>? _changes;
  Timer? _refetch;
  List<EpicboxServer>? _boxes;
  bool _busy = false;
  bool _checking = false;

  /// Why the last Save failed on a first run: the Review step then offers to skip it.
  String? _saveFailed;

  @override
  void initState() {
    super.initState();
    final st = ref.read(deskProvider);
    final api0 = ref.read(deskApiProvider);
    if (st.status?.epicbox case final b?) _relay = relayLabel(b);
    _rerun = ref.read(deskNavProvider.notifier).canBack;
    _wasBuiltin = ref.read(settingsPrefsProvider).builtin;
    final first = _first;
    if (first != null && first.second) {
      // The node is app-wide: start from the current one; nothing is preselected over it.
      _picked = true;
      _local = _wasBuiltin;
      api0.status().then((x) {
        if (!mounted) return;
        _currentNode = x.node.url;
        if (!_wasBuiltin && _nodeUrl == null) setState(() => _nodeUrl = x.node.url);
        if (_relay == defaultEpicboxHost) setState(() => _relay = relayLabel(x.epicbox));
      });
    }
    if (_rerun) {
      if (_demo == null && widget.arg is! SetupStep) _local = _wasBuiltin;
      if (!_wasBuiltin) _nodeUrl = st.status?.node.url;
    }
    final api = ref.read(deskApiProvider);
    // The node list refreshes as each node's check comes in (the wallet's changes).
    ref.listenManual(deskProvider.select((s) => s.nodes), (_, n) {
      if (n != null) _setNodes(n);
    });
    api.nodes().then(_setNodes);
    // A locked wallet has no live loop: the checks that finish meanwhile arrive as changes.
    _changes = api.changes().listen((_) {
      _refetch?.cancel();
      _refetch = Timer(const Duration(milliseconds: 400), () => api.nodes().then(_setNodes, onError: (Object _) {}));
    });
    api.epicboxes().then((b) {
      if (!mounted) return;
      setState(() {
        _boxes = b;
        // A test network's own server when mainnet's default is not among its servers.
        if (_relay == defaultEpicboxHost) _relay = _defaultRelay(b);
      });
    });
  }

  /// The server a new wallet starts on: mainnet's default, or on a test network ([boxes]
  /// without it) its first server (LNX-6).
  static String _defaultRelay(List<EpicboxServer>? boxes) {
    if (boxes == null || boxes.isEmpty || boxes.any((b) => b.domain == defaultEpicboxHost)) return defaultEpicboxHost;
    return EpicboxRelay(host: boxes.first.domain, port: boxes.first.port).label;
  }

  /// On a first run, until the user picks: the healthiest, then fastest node whose check came
  /// back healthy, in the neutral order (no hard-coded host, never by list position). A node
  /// still being checked is not healthy; with none healthy yet, nothing is selected.
  void _preselect(List<NodeServer> nodes) {
    if (_picked || _rerun || !mounted) return;
    final best = serverRows(nodes.where((x) => !x.own).toList()).where((r) => r.state == EState.ok).map((r) => r.value).firstOrNull;
    if (best != _nodeUrl) setState(() => _nodeUrl = best);
  }

  void _setNodes(List<NodeServer> n) {
    if (!mounted) return;
    setState(() => _nodes = n);
    _preselect(n);
  }

  @override
  void dispose() {
    _changes?.cancel();
    _refetch?.cancel();
    super.dispose();
  }

  /// Save: the only place that starts the bundled node; the reuse question comes first
  /// when another node left chain data here.
  Future<void> _save() async {
    final local = _local ? _localChoice : null;
    final c = ref.read(deskProvider.notifier);
    final st = ref.read(deskProvider);
    final prefs = ref.read(settingsPrefsProvider.notifier);
    final node = ref.read(deskNodeProvider);
    // The bundled node: chosen on the local step, or kept as it was on a run again.
    final bundled = _local && (local == null ? _wasBuiltin : local.how == LocalNodeHow.bundled);
    if (bundled && !_wasBuiltin) {
      final found = await node.chainDataCandidates();
      if (!mounted) return;
      if (found.isNotEmpty) {
        final reused = await showReuseChainDataDialog(context, node);
        if (reused == null || !mounted) return;
      }
    }
    if (bundled && local != null) {
      // the fallback question answered here, once the node is going to run: the question of Settings › Node
      // never shows for this wallet.
      await ref.read(deskFallbackProvider.notifier).set(FallbackChoice(local.useFallback ? FallbackConsent.accepted : FallbackConsent.declined, at: DateTime.now()));
      fallbackAskedThisSession = true;
    }
    setState(() => _busy = true);
    final domain = _epicboxOn ? _relay : '';
    prefs.set(ref.read(settingsPrefsProvider).copyWith(epicboxOnStart: domain.isNotEmpty));
    if (_steps.contains(SetupStep.prefs)) await c.saveSettings(ref.read(deskProvider).settings.copyWith(language: () => _language)); // read now: the dialogs above may have saved settings
    try {
      if (bundled) {
        if (!_wasBuiltin) await c.useBuiltInNode(true);
        prefs.set(ref.read(settingsPrefsProvider).copyWith(builtin: true, clearTyped: true));
      } else {
        final url = local != null ? local.existingUrl : _nodeUrl;
        // Unchanged (same node, local node not in use before): nothing moves.
        if (url != null && (_wasBuiltin || url != (st.status?.node.url ?? _currentNode))) await c.useNode(url);
        prefs.set(ref.read(settingsPrefsProvider).copyWith(builtin: false));
      }
      if (domain.isNotEmpty && (st.status == null || domain != relayLabel(st.status!.epicbox))) await c.useEpicbox(domain);
      // A first run's wallet is locked: it listens once Unlock opens it (the epicboxOnStart choice).
      if (_first == null) {
        await c.setListening(domain.isNotEmpty);
        await c.refresh();
      }
    } on Object catch (e) {
      return _failed(e);
    }
    if (!mounted) return;
    final first = _first;
    if (first?.added.id case final id?) {
      // The choices are stored: a mark that cannot be cleared is said, not a failed Save that
      // a retry would repeat (node switch and all).
      if (!await _clearMark(id)) return;
    }
    if (!mounted) return;
    ref.read(deskNavProvider.notifier).reset(first == null ? DeskRoute.overview : DeskRoute.unlock, first?.added);
  }

  /// Clears the first-run mark of wallet [id]; never a way back into this Setup in this session.
  /// When it cannot be cleared, the toast says Setup opens again at the next start, and Unlock
  /// follows. False when the screen went meanwhile.
  Future<bool> _clearMark(String id) async {
    setupSkippedThisSession.add(id);
    try {
      await ref.read(deskApiProvider).setSetupPending(id, false);
    } on Object catch (e) {
      logWarn('desk', 'setup mark not cleared: ${e.runtimeType}');
      if (mounted) showEToast(context, context.l10n.deskSetupMarkNotCleared(_noStop(deskErrorText(e, context.l10n))), tone: ETone.warn);
    }
    return mounted;
  }

  void _failed(Object e) {
    // The kind and the English reason, never a password or a phrase (item 27).
    logWarn('desk', 'setup not saved${_first != null ? ' (first run)' : ''}: ${e.runtimeType}: ${deskErrorText(e)}');
    if (!mounted) return;
    final reason = deskErrorText(e, context.l10n);
    setState(() {
      _busy = false;
      if (_first != null) _saveFailed = reason;
    });
    // A first run shows the notice on Review instead (it offers the way out).
    if (_first == null) showEToast(context, context.l10n.deskSetupNotSaved, text: reason, tone: ETone.risk);
  }

  /// A first run left without saving (Skip from any step, or after a failed Save): Unlock
  /// without it. The wallet keeps what is stored (the defaults, or what an earlier Save stored);
  /// Settings changes it later. Never a way back into the same Setup in this session.
  Future<void> _skip() async {
    final first = _first;
    if (first == null || _busy) return;
    setState(() => _busy = true);
    if (first.added.id case final id?) {
      if (!await _clearMark(id)) return;
    }
    if (!mounted) return;
    ref.read(deskNavProvider.notifier).reset(DeskRoute.unlock, first.added);
  }

  /// [reason] for a sentence that adds its own full stop.
  static String _noStop(String reason) => reason.endsWith('.') || reason.endsWith('。') ? reason.substring(0, reason.length - 1) : reason;

  void _to(SetupStep s) => setState(() => _step = s);

  /// Continue on the node step: Local goes to its own step; a remote node is checked first.
  Future<void> _nodeNext() async {
    if (_checking) return;
    if (_local) return _to(SetupStep.local);
    if (_nodeUrl == null) return;
    setState(() => _checking = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _checking = false;
    _to(SetupStep.epicbox);
  }

  bool get _canContinue => switch (_step) {
    SetupStep.node => _local || _nodeUrl != null,
    SetupStep.local => _localChoice != null && (_localChoice!.how == LocalNodeHow.bundled || _localChoice!.existingFound),
    _ => true,
  };

  SetupStep get _back => _step == SetupStep.local ? SetupStep.node : _steps[_steps.indexOf(_step) - 1];

  /// The main button's action on the current step; Enter in a field runs the same one.
  VoidCallback get _continue => switch (_step) {
    SetupStep.review => _save,
    SetupStep.node => _nodeNext,
    SetupStep.local => () => _to(SetupStep.epicbox),
    _ => () => _to(_steps[_steps.indexOf(_step) + 1]),
  };

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final ts = context.ts;
    final l = context.l10n;
    final railIndex = _step == SetupStep.local ? _steps.indexOf(SetupStep.node) : _steps.indexOf(_step);
    final rail = railOf([if (_steps.contains(SetupStep.prefs)) l.deskSetupStepPrefs, l.deskSetupStepNode, l.deskSetupStepEpicbox, l.deskSetupStepReview], railIndex);
    final last = _step == SetupStep.review;
    final again = nav.canBack ? l.deskSetupAgain : null;
    final (title, lead, body) = switch (_step) {
      SetupStep.prefs => (l.deskSetupStepPrefs, again ?? l.deskSetupPrefsLead, _prefs(context)),
      SetupStep.node => (l.deskSetupNodeTitle, again ?? (_first?.resumed ?? false ? l.deskSetupResumeLead : l.deskSetupNodeLead), _node(context)),
      SetupStep.local => (
        l.deskSetupLocalTitle,
        l.deskSetupLocalLead,
        LocalNodeStep(demo: _demo?.local ?? LocalNodeDemo.none, onChanged: (c) => setState(() => _localChoice = c)),
      ),
      SetupStep.epicbox => (l.deskSetupEpicboxTitle, again, _epicbox(context)),
      SetupStep.review => (l.deskSetupReviewTitle, again ?? l.deskSetupReviewLead, _review(context)),
    };
    final first = _step == _steps.first;
    // Back (mouse, Alt+Left) goes one step back first; held while saving.
    return DeskStepBack(
      onBack: _busy || _checking ? () {} : (first ? null : () => _to(_back)),
      child: EOnbFrame(
        sideTitle: l.deskSetupSideTitle,
        steps: rail,
        title: title,
        lead: lead,
        sideFoot: first && nav.canBack
            ? Align(
                alignment: Alignment.centerLeft,
                child: EButton.ghost(label: l.deskSetupBackToWallet, icon: EIcons.arrowLeft, tabStop: false, onPressed: nav.back),
              )
            : (_first != null ? Text(l.deskSetupSkipKeeps, style: ts.caption) : null),
        actions: [
          // A first run can be left from the start: the defaults stay, Settings changes them.
          if (_first != null) EButton.ghost(key: const ValueKey('setup-skip'), label: l.deskSetupSkip, tabStop: false, onPressed: _busy || _checking ? null : _skip),
          if (!first) backButton(() => _to(_back)),
          EButton.primary(label: last ? l.deskSetupSave : l.commonContinue, busy: _busy || _checking, onPressed: _canContinue ? _continue : null),
        ],
        child: body,
      ),
    );
  }

  Widget _prefs(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EField(
        label: context.l10n.deskSetupLanguage,
        child: ESelect<String>(
          semanticLabel: context.l10n.deskSetupLanguage,
          value: _language ?? deskSystemLanguage,
          onChanged: (v) => setState(() => _language = v == deskSystemLanguage ? null : v),
          items: deskLanguageItems(context.l10n),
        ),
      ),
    ],
  );

  Widget _node(BuildContext context) {
    final nodes = _nodes;
    final l = context.l10n;
    final st = ref.watch(deskProvider);
    final current = nodes?.where((n) => n.url == _nodeUrl).firstOrNull;
    final rows = nodes == null ? const <PanelServer>[] : nodePanelRows(nodes);
    final row = rows.where((r) => r.value == _nodeUrl).firstOrNull;
    final picker = ServerListPanel(
      kind: ServerKind.node,
      label: l.deskSetupNodeServer,
      value: _nodeUrl ?? '',
      fieldText: nodes == null ? l.deskSetupCheckingNodes : (row?.host ?? (_nodeUrl == null ? l.deskSetupPickNode : hostOf(_nodeUrl!))),
      fieldSub: row?.operator,
      tone: switch (current?.health) {
        null || ServiceHealth.checking || ServiceHealth.off => ETone.neutral,
        ServiceHealth.ok => (row?.state == NodeHealthState.healthy ? ETone.ok : ETone.warn),
        ServiceHealth.slow => ETone.warn,
        ServiceHealth.down => ETone.risk,
      },
      servers: rows,
      source: nodeSource(nodes ?? const [], removedNodes: ref.watch(settingsPrefsProvider).removedNodes, inUse: st.status?.node.url ?? _currentNode),
      listNote: nodeListNoteText(l),
      chooseOnly: true,
      keepBelow: Ctl.md + Sp.x8,
      openInitially: _demo?.listOpen ?? false,
      onChoose: (v) async => setState(() {
        _picked = true;
        _nodeUrl = nodeUrlOf(v);
      }),
      onTest: _testNode,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EChoiceCard(
          title: l.deskSetupRemoteNode,
          description: l.deskSetupRemoteNodeText,
          icon: EIcons.server,
          selected: !_local,
          onTap: () => setState(() => _local = false),
        ),
        ExpandFade(
          open: !_local,
          child: Padding(padding: EdgeInsets.fromLTRB(Sp.x4, Sp.x3, 0, Sp.x1), child: picker),
        ),
        if (DeskFeatures.builtInNode) ...[
          SizedBox(height: Sp.x3),
          EChoiceCard(
            title: l.deskSetupLocalTitle,
            description: l.deskSetupLocalNodeText,
            icon: EIcons.monitor,
            selected: _local,
            onTap: () => setState(() => _local = true),
          ),
        ],
      ],
    );
  }

  /// Add's test on the node step: the node gives its tip, then it is kept with the wallet's
  /// nodes. Null when it answered, else why not.
  Future<String?> _testNode(String url) async {
    final l = context.l10n;
    final api = ref.read(deskApiProvider);
    final r = await api.checkNode(url);
    if (r.health == ServiceHealth.down) return l.deskSlNodeNoAnswer;
    if (r.health == ServiceHealth.checking) return DeskFeatures.tor ? l.deskSlTorWait : l.deskSlNodeNoAnswer;
    await api.addNode(NodeServer(url: url, label: r.label, health: r.health, latencyMs: r.latencyMs, height: r.height, version: r.version, own: true));
    return null;
  }

  /// Add's test on the Epicbox step: a WebSocket handshake with the relay.
  Future<String?> _testRelay(String value) async {
    final l = context.l10n;
    final relay = EpicboxRelay.parse(value);
    if (relay == null) return l.slNotAnAddress;
    try {
      return await ref.read(relayProbeProvider).reachable(relay) ? null : l.slRelayNoAnswer;
    } on ProbeNotRun {
      return DeskFeatures.tor ? l.deskSlTorWait : l.slRelayNoAnswer;
    }
  }

  Widget _epicbox(BuildContext context) {
    final ts = context.ts;
    final boxes = _boxes;
    final l = context.l10n;
    final rows = relayPanelRows(boxes ?? const [], defaultHost: _defaultRelay(boxes));
    final row = rows.where((r) => r.value == _relay).firstOrNull;
    // Ctrl+Enter is Continue; Enter on the server opens its list.
    return EForm(
      onSubmit: _continue,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.deskSetupEpicboxText, style: ts.body),
        SizedBox(height: Sp.x2),
        Text(l.deskSetupEpicboxPrivacy, style: ts.bodyDim),
        SizedBox(height: Sp.x6),
        ESwitch(
          value: _epicboxOn,
          label: l.deskSlSetupEpicboxOn,
          semanticLabel: l.deskSlSetupEpicboxOn,
          onChanged: (v) => setState(() => _epicboxOn = v),
        ),
        ExpandFade(
          open: _epicboxOn,
          child: Padding(
            padding: EdgeInsets.only(top: Sp.x4),
            child: EField(
              label: l.deskSetupEpicboxServer,
              child: ServerListPanel(
                kind: ServerKind.relay,
                label: l.deskSetupEpicboxServer,
                value: _relay,
                fieldText: _relay,
                fieldSub: row?.operator,
                tone: switch (row?.state) {
                  NodeHealthState.healthy => ETone.ok,
                  NodeHealthState.degraded => ETone.warn,
                  NodeHealthState.down => ETone.risk,
                  _ => ETone.neutral,
                },
                servers: [...rows, if (row == null) PanelServer.bare(ServerKind.relay, _relay)],
                source: relaySource(boxes ?? const [], inUse: _relay),
                chooseOnly: true,
                keepBelow: Ctl.md + Sp.x8,
                openInitially: _demo?.listOpen ?? false,
                onChoose: (v) async => setState(() => _relay = v),
                onTest: _testRelay,
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, String changeLabel, List<(String, Widget)> rows, SetupStep to, {String? caption}) {
    final ts = context.ts;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Sp.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(title, style: ts.label)),
                SizedBox(height: Sp.x1),
                EFacts(rows, labelWidth: 120.u),
                if (caption != null) ...[SizedBox(height: Sp.x2), Text(caption, style: ts.caption)],
              ],
            ),
          ),
          Semantics(
            label: changeLabel,
            button: true,
            excludeSemantics: true,
            onTap: () => _to(to),
            child: ELink(label: context.l10n.deskSetupChange, onPressed: () => _to(to)),
          ),
        ],
      ),
    );
  }

  Widget _review(BuildContext context) {
    final ts = context.ts;
    final domain = _epicboxOn ? _relay : '';
    final local = _local ? _localChoice : null;
    final bundled = local == null ? _local : local.how == LocalNodeHow.bundled;
    final fallback = nodeHost(defaultFallbackNodeUrl);
    final folder = ref.watch(deskLocalNodeProvider).value?.dataFolder ?? mockDataFolder;
    final l = context.l10n;
    final nodeRows = <(String, Widget)>[
      if (local == null && !_local) ...[
        (l.deskSetupType, Text(l.deskSetupRemoteNode, style: ts.body)),
        (l.deskSetupAddress, Text(_nodeUrl ?? '–', style: ts.mono())),
      ] else if (!bundled) ...[
        (l.deskSetupType, Text(l.deskSetupExistingNode(hostOf(local!.existingUrl)), style: ts.body)),
      ] else ...[
        (l.deskSetupType, Text(l.deskSetupBundledNode, style: ts.body)),
        (l.deskSetupWhileSyncing, Text(local?.useFallback ?? true ? fallback : l.deskSetupWait, style: ts.mono())),
        (l.deskSetupDataFolder, Text(folder, style: ts.mono(), overflow: TextOverflow.ellipsis)),
      ],
    ];
    final failed = _first == null ? null : _saveFailed ?? (_demo?.saveFailed ?? false ? l.deskErrWalletLocked : null);
    final panel = EPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_steps.contains(SetupStep.prefs)) ...[
            _section(context, l.deskSetupStepPrefs, l.deskSetupChangePrefsSem, [(l.deskSetupLanguage, Text(deskLanguageName(l, _language), style: ts.body))], SetupStep.prefs),
            EDivider(space: Sp.x2),
          ],
          _section(
            context,
            l.deskSetupStepNode,
            l.deskSetupChangeNodeSem,
            nodeRows,
            _local ? SetupStep.local : SetupStep.node,
            caption: bundled && _local
                ? (local?.useFallback ?? true ? l.deskSetupSaveStartsFallback(fallback) : l.deskSetupSaveStarts)
                : null,
          ),
          EDivider(space: Sp.x2),
          _section(context, l.deskSetupStepEpicbox, l.deskSetupChangeEpicboxSem, [
            (l.deskSetupServer, domain.isEmpty ? Text(l.deskSetupOff, style: ts.body) : Text(domain, style: ts.mono())),
          ], SetupStep.epicbox),
        ],
      ),
    );
    if (failed == null) return panel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ENotice(
          tone: ETone.risk,
          title: l.deskSetupSaveFailedTitle,
          // The string adds the full stop.
          text: l.deskSetupSaveFailedText(failed.endsWith('.') || failed.endsWith('。') ? failed.substring(0, failed.length - 1) : failed),
        ),
        SizedBox(height: Sp.x4),
        panel,
      ],
    );
  }
}
