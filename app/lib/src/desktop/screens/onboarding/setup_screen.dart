import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import '../settings/prefs.dart' show settingsPrefsProvider;
import 'onboarding_parts.dart';

enum SetupStep { prefs, node, epicbox, review }


/// The setup steps: language (only when the app offers one), node, Epicbox, review. [arg] is a [SetupStep].
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _domain = TextEditingController(text: 'epicbox.epiccash.com');
  static final _steps = [if (DeskFeatures.languages) SetupStep.prefs, SetupStep.node, SetupStep.epicbox, SetupStep.review];

  late SetupStep _step = widget.arg is SetupStep && _steps.contains(widget.arg) ? widget.arg as SetupStep : _steps.first;
  String _language = 'English';
  // A public or own node stays the default (D10); the built-in node is opt-in.
  bool _builtIn = false;
  String _nodeUrl = 'https://node.epiccash.com';
  List<NodeServer>? _nodes;
  List<EpicboxServer>? _boxes;
  bool _busy = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final st = ref.read(deskProvider);
    _domain.text = st.status?.epicbox.domain ?? _domain.text;
    _nodeUrl = st.status?.node.url ?? _nodeUrl;
    final api = ref.read(deskApiProvider);
    api.nodes().then((n) => mounted ? setState(() => _nodes = n) : null);
    api.epicboxes().then((b) => mounted ? setState(() => _boxes = b) : null);
  }

  @override
  void dispose() {
    _domain.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final c = ref.read(deskProvider.notifier);
    final st = ref.read(deskProvider);
    final prefs = ref.read(settingsPrefsProvider.notifier);
    final domain = _domain.text.trim();
    prefs.set(ref.read(settingsPrefsProvider).copyWith(epicboxOnStart: domain.isNotEmpty));
    if (DeskFeatures.languages) await c.saveSettings(st.settings.copyWith(language: _language));
    try {
      if (_builtIn) {
        await c.useBuiltInNode(true);
      } else if (_nodeUrl != st.status?.node.url) {
        await c.useNode(_nodeUrl);
      }
      prefs.set(ref.read(settingsPrefsProvider).copyWith(builtin: _builtIn));
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

  /// Continue on the node step: a remote node is checked first.
  Future<void> _nodeNext() async {
    if (_checking) return;
    if (!_builtIn) {
      setState(() => _checking = true);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _checking = false;
    }
    _to(SetupStep.epicbox);
  }

  /// The main button's action on the current step; Enter in a field runs the same one.
  VoidCallback get _continue => _step == SetupStep.review
      ? _save
      : _step == SetupStep.node
      ? _nodeNext
      : () => _to(_steps[_steps.indexOf(_step) + 1]);

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final ts = context.ts;
    final rail = railOf([if (DeskFeatures.languages) 'Preferences', 'Node', 'Epicbox', 'Review'], _steps.indexOf(_step));
    final last = _step == SetupStep.review;
    final again = nav.canBack ? 'Running setup again. Nothing changes until Save on the last step.' : null;
    final (title, lead, body) = switch (_step) {
      SetupStep.prefs => ('Preferences', again ?? 'App language. It can be changed later.', _prefs(context)),
      SetupStep.node => ('Choose a node', again ?? 'The wallet reads the chain and sends through a remote Epic node. Its operator sees the IP address and which outputs the wallet asks about.', _node(context)),
      SetupStep.epicbox => ('Receive when offline', again, _epicbox(context)),
      SetupStep.review => ('Check settings', again ?? 'Change anything that is not right, then save.', _review(context)),
    };
    final first = _step == _steps.first;
    // Back (mouse, Alt+Left) goes one step back first; held while saving.
    return DeskStepBack(
      onBack: _busy || _checking ? () {} : (first ? null : () => _to(_steps[_steps.indexOf(_step) - 1])),
      child: EOnbFrame(
      sideTitle: 'Set up',
      steps: rail,
      title: title,
      lead: lead,
      sideFoot: _step == _steps.first && nav.canBack
          ? Align(
              alignment: Alignment.centerLeft,
              child: EButton.ghost(label: 'Back to wallet', icon: EIcons.arrowLeft, tabStop: false, onPressed: nav.back),
            )
          : Text('Everything here can be changed later in Settings.', style: ts.caption),
      actions: [
        if (_step != _steps.first) backButton(() => _to(_steps[_steps.indexOf(_step) - 1])),
        EButton.primary(
          label: last ? 'Save settings' : 'Continue',
          busy: _busy || _checking,
          onPressed: _continue,
        ),
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
    final nodes = _nodes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (DeskFeatures.builtInNode) ...[
          EChoiceCard(
            title: 'Built-in node',
            description: 'Runs on this computer. Slower to start, nothing is shared.',
            icon: EIcons.node,
            selected: _builtIn,
            onTap: () => setState(() => _builtIn = true),
          ),
          SizedBox(height: Sp.x3),
        ],
        if (DeskFeatures.builtInNode) ...[
        EChoiceCard(
          title: 'Remote node',
          description: 'Starts faster. The operator sees the IP address and which outputs the wallet asks about.',
          icon: EIcons.server,
          selected: !_builtIn,
          onTap: () => setState(() => _builtIn = false),
        ),
          SizedBox(height: Sp.x5),
        ],
        if (!_builtIn) ...[
          EField(
            label: 'Server',
            child: nodes == null
                ? const Align(alignment: Alignment.centerLeft, child: ESpinner())
                : ESelect<String>(
                    semanticLabel: 'Node server',
                    mono: true,
                    value: _nodeUrl,
                    onChanged: (v) => setState(() => _nodeUrl = v),
                    items: [
                      for (final n in nodes)
                        ESelectItem(n.url, n.url, subtitle: n.latencyMs == null ? n.label : '${n.label} · ${n.latencyMs} ms'),
                    ],
                  ),
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
        Text('Epicbox delivers payments to the Epic address and holds them until the wallet is online.', style: ts.body),
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

  Widget _section(BuildContext context, String title, List<(String, Widget)> rows, SetupStep to) {
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
    return EPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (DeskFeatures.languages) ...[
            _section(context, 'Preferences', [('Language', Text(_language, style: ts.body))], SetupStep.prefs),
            EDivider(space: Sp.x2),
          ],
          _section(context, 'Node', [
            ('Type', Text(_builtIn ? 'Built-in node' : 'Remote node', style: ts.body)),
            if (!_builtIn) ('Address', Text(_nodeUrl, style: ts.mono())),
          ], SetupStep.node),
          EDivider(space: Sp.x2),
          _section(context, 'Epicbox', [
            ('Server', domain.isEmpty ? Text('Off', style: ts.body) : Text(domain, style: ts.mono())),
          ], SetupStep.epicbox),
        ],
      ),
    );
  }
}
