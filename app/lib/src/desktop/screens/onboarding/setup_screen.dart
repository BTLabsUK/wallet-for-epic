import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import '../settings/prefs.dart' show settingsPrefsProvider;
import 'onboarding_parts.dart';

enum SetupStep { prefs, node, epicbox, review }


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
  bool _builtIn = DeskFeatures.builtInNode;
  String _nodeUrl = 'https://node.epiccash.com';
  List<NodeServer>? _nodes;
  List<EpicboxServer>? _boxes;
  bool _busy = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final st = ref.read(deskProvider);
    _name.text = ref.read(settingsPrefsProvider).walletLabel ?? '';
    _domain.text = st.status?.epicbox.domain ?? _domain.text;
    _nodeUrl = st.status?.node.url ?? _nodeUrl;
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
    final st = ref.read(deskProvider);
    final prefs = ref.read(settingsPrefsProvider.notifier);
    final domain = _domain.text.trim();
    prefs.set(ref.read(settingsPrefsProvider).copyWith(walletLabel: _name.text.trim(), epicboxOnStart: domain.isNotEmpty));
    if (DeskFeatures.languages) await c.saveSettings(st.settings.copyWith(language: _language));
    try {
      if (!_builtIn && _nodeUrl != st.status?.node.url) await c.useNode(_nodeUrl);
      if (domain.isNotEmpty && domain != st.status?.epicbox.domain) await c.useEpicbox(domain);
      await c.setListening(domain.isNotEmpty);
      await c.refresh();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showEToast(context, 'Not saved', text: '$e');
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

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final ts = context.ts;
    final rail = railOf(['Preferences', 'Node', 'Epicbox', 'Review'], _step.index);
    final last = _step == SetupStep.review;
    final again = nav.canBack ? 'Running setup again. Nothing changes until Save on the last step.' : null;
    final (title, lead, body) = switch (_step) {
      SetupStep.prefs => ('Preferences', again ?? (DeskFeatures.languages ? 'Wallet name and app language. Both can be changed later.' : 'Wallet name. It can be changed later.'), _prefs(context)),
      SetupStep.node => ('Choose a node', again ?? 'The wallet reads the chain and sends through an Epic node.', _node(context)),
      SetupStep.epicbox => ('Receive when offline', again, _epicbox(context)),
      SetupStep.review => ('Check settings', again ?? 'Change anything that is not right, then save.', _review(context)),
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
          busy: _busy || _checking,
          onPressed: last
              ? _save
              : _step == SetupStep.node
              ? _nodeNext
              : () => _to(SetupStep.values[_step.index + 1]),
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
      if (DeskFeatures.languages) ...[
      SizedBox(height: Sp.x5),
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
        EChoiceCard(
          title: 'Remote node',
          description: 'Starts faster. The operator sees the IP address and which outputs the wallet asks about.',
          icon: EIcons.server,
          selected: !_builtIn,
          onTap: () => setState(() => _builtIn = false),
        ),
        if (!_builtIn) ...[
          SizedBox(height: Sp.x5),
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
          child: EInput(controller: _domain, mono: true, semanticLabel: 'Epicbox server', onChanged: (_) => setState(() {})),
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
          _section(context, 'Preferences', [
            ('Name', Text(_name.text.isEmpty ? 'No name' : _name.text, style: ts.body)),
            if (DeskFeatures.languages) ('Language', Text(_language, style: ts.body)),
          ], SetupStep.prefs),
          EDivider(space: Sp.x2),
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
