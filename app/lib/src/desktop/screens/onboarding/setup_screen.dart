import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../network.dart' show defaultEpicboxHost;
import '../../data/desk_node.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import '../settings/combo.dart';
import '../settings/local_node_dialogs.dart' show showReuseChainDataDialog, fallbackAskedThisSession;
import '../settings/prefs.dart' show settingsPrefsProvider;
import '../settings/settings_node.dart' show hostOf, nodeUrlOf, serverRows, nodeListNote;
import 'local_node_step.dart';
import 'onboarding_parts.dart';

/// The steps (D-14): preferences (only with languages), node, the local node's own step when
/// Local was chosen (same rail position), Epicbox, review.
enum SetupStep { prefs, node, local, epicbox, review }

/// A tour start state: the step, and for the local step which probe answer to show.
@immutable
class SetupDemo {
  const SetupDemo(this.step, {this.local = LocalNodeDemo.none, this.localChosen = false});

  final SetupStep step;
  final LocalNodeDemo local;

  /// The Review step with the local node chosen.
  final bool localChosen;
}

/// The setup steps. [arg] is a [SetupStep] or a [SetupDemo].
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _domain = TextEditingController(text: defaultEpicboxHost);
  static final _steps = [if (DeskFeatures.languages) SetupStep.prefs, SetupStep.node, SetupStep.epicbox, SetupStep.review];

  SetupDemo? get _demo => widget.arg is SetupDemo ? widget.arg! as SetupDemo : null;
  SetupStep get _startStep => _demo?.step ?? (widget.arg is SetupStep ? widget.arg! as SetupStep : _steps.first);

  late SetupStep _step = _startStep == SetupStep.local || _steps.contains(_startStep) ? _startStep : _steps.first;
  String _language = 'English';

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
  List<NodeServer>? _fetched;
  List<EpicboxServer>? _boxes;
  bool _busy = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final st = ref.read(deskProvider);
    _domain.text = st.status?.epicbox.domain ?? _domain.text;
    _rerun = ref.read(deskNavProvider.notifier).canBack;
    _wasBuiltin = ref.read(settingsPrefsProvider).builtin;
    if (_rerun) {
      if (_demo == null && widget.arg is! SetupStep) _local = _wasBuiltin;
      if (!_wasBuiltin) _nodeUrl = st.status?.node.url;
    }
    final api = ref.read(deskApiProvider);
    // The node list refreshes as each node's check comes in (the wallet's changes).
    ref.listenManual(deskProvider.select((s) => s.nodes), (_, n) {
      if (n != null) _preselect(n);
    });
    api.nodes().then((n) {
      if (!mounted) return;
      setState(() => _fetched = n);
      _preselect(ref.read(deskProvider).nodes ?? n);
    });
    api.epicboxes().then((b) => mounted ? setState(() => _boxes = b) : null);
  }

  /// On a first run, until the user picks: the healthiest, then fastest node whose check came
  /// back healthy, in the neutral order (no hard-coded host, never by list position). A node
  /// still being checked is not healthy; with none healthy yet, nothing is selected.
  void _preselect(List<NodeServer> nodes) {
    if (_picked || _rerun || !mounted) return;
    final best = serverRows(nodes.where((x) => !x.own).toList()).where((r) => r.state == EState.ok).map((r) => r.value).firstOrNull;
    if (best != _nodeUrl) setState(() => _nodeUrl = best);
  }

  @override
  void dispose() {
    _domain.dispose();
    super.dispose();
  }

  /// Save: the only place that starts the bundled node (O2); the reuse question comes first
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
      // D-7 answered here, once the node is going to run: the question of Settings › Node
      // never shows for this wallet.
      await ref.read(deskFallbackProvider.notifier).set(FallbackChoice(local.useFallback ? FallbackConsent.accepted : FallbackConsent.declined, at: DateTime.now()));
      fallbackAskedThisSession = true;
    }
    setState(() => _busy = true);
    final domain = _domain.text.trim();
    prefs.set(ref.read(settingsPrefsProvider).copyWith(epicboxOnStart: domain.isNotEmpty));
    if (DeskFeatures.languages) await c.saveSettings(st.settings.copyWith(language: _language));
    try {
      if (bundled) {
        if (!_wasBuiltin) await c.useBuiltInNode(true);
        prefs.set(ref.read(settingsPrefsProvider).copyWith(builtin: true, clearTyped: true));
      } else {
        final url = local != null ? local.existingUrl : _nodeUrl;
        // Unchanged (same node, local node not in use before): nothing moves.
        if (url != null && (_wasBuiltin || url != st.status?.node.url)) await c.useNode(url);
        prefs.set(ref.read(settingsPrefsProvider).copyWith(builtin: false));
      }
      if (domain.isNotEmpty && domain != st.status?.epicbox.domain) await c.useEpicbox(domain);
      await c.setListening(domain.isNotEmpty);
      await c.refresh();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showEToast(context, 'Not saved', text: deskErrorText(e));
      return;
    }
    if (!mounted) return;
    ref.read(deskNavProvider.notifier).reset(DeskRoute.overview);
  }

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
    final railIndex = _step == SetupStep.local ? _steps.indexOf(SetupStep.node) : _steps.indexOf(_step);
    final rail = railOf([if (DeskFeatures.languages) 'Preferences', 'Node', 'Epicbox', 'Review'], railIndex);
    final last = _step == SetupStep.review;
    final again = nav.canBack ? 'Running setup again. Nothing changes until Save on the last step.' : null;
    final (title, lead, body) = switch (_step) {
      SetupStep.prefs => ('Preferences', again ?? 'App language. It can be changed later.', _prefs(context)),
      SetupStep.node => ('Choose a node', again ?? 'The wallet reads the chain and sends through an Epic node.', _node(context)),
      SetupStep.local => (
        'Local node',
        'What running the node here means, and which node to use.',
        LocalNodeStep(demo: _demo?.local ?? LocalNodeDemo.none, onChanged: (c) => setState(() => _localChoice = c)),
      ),
      SetupStep.epicbox => ('Receive when offline', again, _epicbox(context)),
      SetupStep.review => ('Check settings', again ?? 'Change anything that is not right, then save.', _review(context)),
    };
    final first = _step == _steps.first;
    // Back (mouse, Alt+Left) goes one step back first; held while saving.
    return DeskStepBack(
      onBack: _busy || _checking ? () {} : (first ? null : () => _to(_back)),
      child: EOnbFrame(
        sideTitle: 'Set up',
        steps: rail,
        title: title,
        lead: lead,
        sideFoot: first && nav.canBack
            ? Align(
                alignment: Alignment.centerLeft,
                child: EButton.ghost(label: 'Back to wallet', icon: EIcons.arrowLeft, tabStop: false, onPressed: nav.back),
              )
            : Text('Everything here can be changed later in Settings.', style: ts.caption),
        actions: [
          if (!first) backButton(() => _to(_back)),
          EButton.primary(label: last ? 'Save settings' : 'Continue', busy: _busy || _checking, onPressed: _canContinue ? _continue : null),
        ],
        child: body,
      ),
    );
  }

  Widget _prefs(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EField(
        label: 'Language',
        child: ESelect<String>(
          semanticLabel: 'Language',
          value: _language,
          onChanged: (v) => setState(() => _language = v),
          items: [for (final l in deskLanguages) ESelectItem(l, l)],
        ),
      ),
    ],
  );

  Widget _node(BuildContext context) {
    final nodes = ref.watch(deskProvider.select((s) => s.nodes)) ?? _fetched;
    final rows = nodes == null ? const <ServerInfo>[] : serverRows(nodes.where((n) => !n.own).toList());
    final current = rows.where((r) => r.value == _nodeUrl).firstOrNull;
    final picker = ServiceCombo(
      label: 'Node server',
      hint: 'Find or type a node address',
      kind: ServerKind.node,
      value: _nodeUrl ?? '',
      fieldText: nodes == null ? 'Checking nodes…' : (current?.host ?? (_nodeUrl == null ? 'Pick a node' : hostOf(_nodeUrl!))),
      fieldSub: current?.operator,
      tone: switch (current?.state) {
        null || EState.off => ETone.neutral,
        EState.ok => ETone.ok,
        EState.risk => ETone.risk,
        EState.warn => ETone.warn,
      },
      options: [for (final r in rows) ComboOption(value: r.value, host: r.host, sub: r.operator, server: r, group: 'Public nodes')],
      typedRow: (t) => RegExp(r'^[^\s]*[.:][^\s]*$').hasMatch(t) ? ComboOption(value: t, host: hostOf(t), sub: 'not in the public list', tone: ETone.neutral) : null,
      typedNote: (_) => 'Enter uses it.',
      listNote: nodeListNote,
      emptyNote: nodes == null ? 'Checking nodes…' : 'No nodes to show.',
      onPicked: (v) => setState(() {
        _picked = true;
        _nodeUrl = nodeUrlOf(v);
      }),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EChoiceCard(
          title: 'Remote node',
          description: 'Any public node. Ready at once.',
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
            title: 'Local node',
            description: 'Runs the Epic node on this computer. Nothing is shared with an operator. Needs disk space and hours to sync.',
            icon: EIcons.monitor,
            selected: _local,
            onTap: () => setState(() => _local = true),
          ),
        ],
      ],
    );
  }

  Widget _epicbox(BuildContext context) {
    final ts = context.ts;
    final boxes = _boxes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Epicbox delivers payments to the Epicbox address and holds them until the wallet is online.', style: ts.body),
        SizedBox(height: Sp.x2),
        Text('It does not hide the IP address from the Epicbox server. Use a VPN if that matters.', style: ts.bodyDim),
        SizedBox(height: Sp.x6),
        EField(
          label: 'Epicbox server',
          help: 'Leave empty to turn receiving through Epicbox off.',
          // Enter is Continue.
          child: EForm(
            onSubmit: _continue,
            child: EInput(controller: _domain, mono: true, semanticLabel: 'Epicbox server', onChanged: (_) => setState(() {})),
          ),
        ),
        SizedBox(height: Sp.x3),
        if (boxes == null)
          const Align(alignment: Alignment.centerLeft, child: ESpinner())
        else
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              for (final b in boxes)
                EButton(
                  label: b.domain,
                  icon: _domain.text.trim() == b.domain ? EIcons.check : null,
                  size: EBtnSize.inline,
                  tabStop: false,
                  onPressed: () => setState(() => _domain.text = b.domain),
                ),
            ],
          ),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<(String, Widget)> rows, SetupStep to, {String? caption}) {
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
            label: 'Change ${title.toLowerCase()}',
            button: true,
            excludeSemantics: true,
            onTap: () => _to(to),
            child: ELink(label: 'Change', onPressed: () => _to(to)),
          ),
        ],
      ),
    );
  }

  Widget _review(BuildContext context) {
    final ts = context.ts;
    final domain = _domain.text.trim();
    final local = _local ? _localChoice : null;
    final bundled = local == null ? _local : local.how == LocalNodeHow.bundled;
    final fallback = nodeHost(defaultFallbackNodeUrl);
    final folder = ref.watch(deskLocalNodeProvider).value?.dataFolder ?? mockDataFolder;
    final nodeRows = <(String, Widget)>[
      if (local == null && !_local) ...[
        ('Type', Text('Remote node', style: ts.body)),
        ('Address', Text(_nodeUrl ?? '–', style: ts.mono())),
      ] else if (!bundled) ...[
        ('Type', Text('Existing node at ${hostOf(local!.existingUrl)}', style: ts.body)),
      ] else ...[
        ('Type', Text('Local node, bundled', style: ts.body)),
        ('While syncing', Text(local?.useFallback ?? true ? fallback : 'wait', style: ts.mono())),
        ('Data folder', Text(folder, style: ts.mono(), overflow: TextOverflow.ellipsis)),
      ],
    ];
    return EPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (DeskFeatures.languages) ...[
            _section(context, 'Preferences', [('Language', Text(_language, style: ts.body))], SetupStep.prefs),
            EDivider(space: Sp.x2),
          ],
          _section(
            context,
            'Node',
            nodeRows,
            _local ? SetupStep.local : SetupStep.node,
            caption: bundled && _local
                ? 'Save starts the node. The first sync takes hours; the wallet opens meanwhile${local?.useFallback ?? true ? ' and uses $fallback until then' : ''}.'
                : null,
          ),
          EDivider(space: Sp.x2),
          _section(context, 'Epicbox', [
            ('Server', domain.isEmpty ? Text('Off', style: ts.body) : Text(domain, style: ts.mono())),
          ], SetupStep.epicbox),
        ],
      ),
    );
  }
}
