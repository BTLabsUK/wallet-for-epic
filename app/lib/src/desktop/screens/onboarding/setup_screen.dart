import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'onboarding_parts.dart';

enum SetupStep { prefs, node, epicbox, review }

const _languages = ['English', 'Deutsch', 'Español', 'Français', 'Polski', 'Русский', '中文'];

/// The four setup steps: name and language, node, Epicbox, review. [arg] is a [SetupStep].
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _name = TextEditingController();
  final _domain = TextEditingController(text: 'epicbox.epiccash.com');
  late SetupStep _step = widget.arg is SetupStep ? widget.arg as SetupStep : SetupStep.prefs;
  String _language = 'English';
  bool _builtIn = true;
  String _nodeUrl = 'https://node.epiccash.com';
  List<NodeServer>? _nodes;
  List<EpicboxServer>? _boxes;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final api = ref.read(deskApiProvider);
    api.nodes().then((n) => mounted ? setState(() => _nodes = n) : null);
    api.epicboxes().then((b) => mounted ? setState(() => _boxes = b) : null);
  }

  @override
  void dispose() {
    _name.dispose();
    _domain.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final c = ref.read(deskProvider.notifier);
    await c.refresh();
    await c.saveSettings(ref.read(deskProvider).settings.copyWith(language: _language));
    if (!_builtIn) await c.useNode(_nodeUrl);
    if (_domain.text.trim().isNotEmpty) await c.useEpicbox(_domain.text.trim());
    if (!mounted) return;
    ref.read(deskNavProvider.notifier).reset(DeskRoute.overview);
  }

  void _to(SetupStep s) => setState(() => _step = s);

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final ts = context.ts;
    final rail = railOf(['Preferences', 'Node', 'Epicbox', 'Review'], _step.index);
    final last = _step == SetupStep.review;
    final (title, lead, body) = switch (_step) {
      SetupStep.prefs => ('Preferences', 'Wallet name and app language. Both can be changed later.', _prefs(context)),
      SetupStep.node => ('Choose a node', 'The wallet reads the chain and sends through an Epic node.', _node(context)),
      SetupStep.epicbox => ('Receive when offline', null, _epicbox(context)),
      SetupStep.review => ('Check settings', 'Change anything that is not right, then save.', _review(context)),
    };
    return EOnbFrame(
      sideTitle: 'Set up',
      steps: rail,
      title: title,
      lead: lead,
      sideFoot: _step == SetupStep.prefs && nav.canBack
          ? Align(
              alignment: Alignment.centerLeft,
              child: EButton.ghost(label: 'Back to wallet', icon: EIcons.arrowLeft, onPressed: nav.back),
            )
          : Text('Everything here can be changed later in Settings.', style: ts.caption),
      actions: [
        if (_step != SetupStep.prefs) backButton(() => _to(SetupStep.values[_step.index - 1])),
        EButton.primary(
          label: last ? 'Save settings' : 'Continue',
          busy: _busy,
          onPressed: last ? _save : () => _to(SetupStep.values[_step.index + 1]),
        ),
      ],
      child: body,
    );
  }

  Widget _prefs(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EField(
        label: 'Name',
        optional: true,
        help: 'Shown in the wallet list.',
        child: EInput(controller: _name, hint: 'Main wallet', semanticLabel: 'Wallet name', onChanged: (_) => setState(() {})),
      ),
      const SizedBox(height: Sp.x5),
      EField(
        label: 'Language',
        child: ESelect<String>(
          semanticLabel: 'Language',
          value: _language,
          onChanged: (v) => setState(() => _language = v),
          items: [for (final l in _languages) ESelectItem(l, l)],
        ),
      ),
    ],
  );

  Widget _node(BuildContext context) {
    final nodes = _nodes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EChoiceCard(
          title: 'Built-in node',
          description: 'Runs on this computer. Slower to start, nothing is shared.',
          icon: EIcons.node,
          selected: _builtIn,
          onTap: () => setState(() => _builtIn = true),
        ),
        const SizedBox(height: Sp.x3),
        EChoiceCard(
          title: 'Remote node',
          description: 'Starts faster. The operator sees the IP address and which outputs the wallet asks about.',
          icon: EIcons.server,
          selected: !_builtIn,
          onTap: () => setState(() => _builtIn = false),
        ),
        if (!_builtIn) ...[
          const SizedBox(height: Sp.x5),
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
        const SizedBox(height: Sp.x2),
        Text('It does not hide the IP address from the Epicbox server. Use a VPN if that matters.', style: ts.bodyDim),
        const SizedBox(height: Sp.x6),
        EField(
          label: 'Epicbox server',
          help: 'Leave empty to turn receiving through Epicbox off.',
          child: EInput(controller: _domain, mono: true, semanticLabel: 'Epicbox server', onChanged: (_) => setState(() {})),
        ),
        const SizedBox(height: Sp.x3),
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
                  size: EBtnSize.inline,
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
      padding: const EdgeInsets.symmetric(vertical: Sp.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(title, style: ts.label)),
                const SizedBox(height: Sp.x1),
                EFacts(rows, labelWidth: 120),
              ],
            ),
          ),
          ELink(label: 'Change', onPressed: () => _to(to)),
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
          _section(context, 'Preferences', [
            ('Name', Text(_name.text.isEmpty ? 'No name' : _name.text, style: ts.body)),
            ('Language', Text(_language, style: ts.body)),
          ], SetupStep.prefs),
          const EDivider(space: Sp.x2),
          _section(context, 'Node', [
            ('Type', Text(_builtIn ? 'Built-in node' : 'Remote node', style: ts.body)),
            if (!_builtIn) ('Address', Text(_nodeUrl, style: ts.mono())),
          ], SetupStep.node),
          const EDivider(space: Sp.x2),
          _section(context, 'Epicbox', [
            ('Server', domain.isEmpty ? Text('Off', style: ts.body) : Text(domain, style: ts.mono())),
          ], SetupStep.epicbox),
        ],
      ),
    );
  }
}
