import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'combo.dart';
import 'dialogs.dart';
import 'prefs.dart';
import 'settings_frame.dart';

/// Start states of Settings › Node.
enum NodeDemo { comboOpen, typed, pickFailed, builtin, chainInUse }

String hostOf(String url) => url.replaceFirst(RegExp('^https?://'), '').replaceFirst(RegExp(r'/+$'), '');

/// Something typed that may be an address: a dot or a colon, no spaces.
final _addressLike = RegExp(r'^[^\s]*[.:][^\s]*$');

/// The oldest node version the wallet works well with.
const minNodeVersion = '3.6.0';

bool versionOld(String? v) {
  if (v == null) return false;
  final a = v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final b = minNodeVersion.split('.').map(int.parse).toList();
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0;
    if (x != b[i]) return x < b[i];
  }
  return false;
}

ETone nodeTone(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => ETone.ok,
  ServiceHealth.slow || ServiceHealth.checking => ETone.warn,
  ServiceHealth.down => ETone.risk,
  ServiceHealth.off => ETone.neutral,
};

const _portNote = 'Check the address and the port (usually 3413).';

class SettingsNodeScreen extends ConsumerStatefulWidget {
  const SettingsNodeScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsNodeScreen> createState() => _SettingsNodeScreenState();
}

class _SettingsNodeScreenState extends ConsumerState<SettingsNodeScreen> {
  final _combo = GlobalKey<ServiceComboState>();
  bool _saving = false;
  String? _error;
  bool _chainAsk = false;
  late bool _chainInUse = widget.arg == NodeDemo.chainInUse;

  // The live check of a typed address.
  String _typed = '';
  NodeServer? _typedCheck;
  Timer? _debounce;

  static const _demoTyped = 'http://10.0.0.5:3413';

  @override
  void initState() {
    super.initState();
    final arg = widget.arg;
    if (arg == NodeDemo.typed) _onTyped(_demoTyped);
    if (arg == NodeDemo.pickFailed) _error = _portNote;
    if (arg == NodeDemo.builtin || arg == NodeDemo.chainInUse) {
      Future.microtask(() {
        final p = ref.read(settingsPrefsProvider.notifier);
        p.set(ref.read(settingsPrefsProvider).copyWith(builtin: true, clearTyped: true));
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onTyped(String t) {
    _debounce?.cancel();
    setState(() {
      _typed = t;
      _typedCheck = null;
      _error = null;
    });
    if (!_addressLike.hasMatch(t)) return;
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final url = t.startsWith('http') ? t : 'http://$t';
      final r = await ref.read(deskApiProvider).checkNode(url);
      if (mounted && _typed == t) setState(() => _typedCheck = r);
    });
  }

  Future<void> _pick(String value) async {
    final prefs = ref.read(settingsPrefsProvider.notifier);
    final p = ref.read(settingsPrefsProvider);
    if (value == builtinNode) {
      final ok = await showChainOfferDialog(context);
      if (!mounted || ok == null) {
        _combo.currentState?.collapse();
        return;
      }
      prefs.set(p.copyWith(builtin: true, clearTyped: true));
      _combo.currentState?.collapse();
      showEToast(context, 'Built-in node in use', text: ok ? 'Using the blockchain data found.' : 'It downloads the whole chain.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final url = value.startsWith('http') ? value : 'http://$value';
    final known = (ref.read(deskProvider).nodes ?? const <NodeServer>[]).any((n) => n.url == url);
    final r = await ref.read(deskApiProvider).checkNode(url);
    if (!mounted) return;
    if (r.health == ServiceHealth.down) {
      setState(() {
        _saving = false;
        _error = _portNote;
      });
      _combo.currentState?.keepTyped(hostOf(url));
      return;
    }
    await ref.read(deskProvider.notifier).useNode(url);
    if (!mounted) return;
    prefs.set(ref.read(settingsPrefsProvider).copyWith(builtin: false, typedNode: known ? null : r, clearTyped: known));
    setState(() => _saving = false);
    _combo.currentState?.collapse();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(deskProvider);
    final prefs = ref.watch(settingsPrefsProvider);
    final nodes = st.nodes;
    final status = st.status;
    if (nodes == null || status == null) {
      return const SettingsFrame(route: DeskRoute.settingsNode, child: SettingsLoading());
    }
    final p = ref.read(settingsPrefsProvider.notifier);
    final visible = nodes.where((n) => !prefs.removedNodes.contains(n.url)).toList();
    final mine = visible.where((n) => n.own).toList();
    final current = prefs.typedNode ?? status.node;
    final value = prefs.builtin ? builtinNode : current.url;
    final defaultUrl = nodes.first.url;
    String labelOf(NodeServer n) => prefs.nodeLabels[n.url] ?? n.label;
    String? tip(NodeServer n) => n.latencyMs == null ? null : 'Response time ${n.latencyMs} ms.';

    final options = <ComboOption>[
      for (final n in mine)
        ComboOption(
          value: n.url,
          host: hostOf(n.url),
          sub: labelOf(n).isEmpty ? null : labelOf(n),
          tone: nodeTone(n.health),
          height: n.height,
          tip: tip(n),
          group: 'My nodes',
          actions: [
            EIconButton(icon: EIcons.pencil, label: 'Edit ${labelOf(n)}', size: EBtnSize.inline, onPressed: () => showMyNodeDialog(context, initial: n.url, label: labelOf(n))),
            EIconButton(
              icon: EIcons.star,
              label: 'Remove ${labelOf(n)} from my nodes',
              size: EBtnSize.inline,
              selected: true,
              onPressed: () {
                p.forgetNode(n.url);
                showEToast(context, 'Removed from my nodes', text: hostOf(n.url));
              },
            ),
          ],
        ),
      for (final n in visible.where((n) => !n.own))
        ComboOption(
          value: n.url,
          host: hostOf(n.url),
          sub: n.operator,
          isDefault: n.url == defaultUrl,
          tone: nodeTone(n.health),
          word: n.health == ServiceHealth.ok ? null : nodeWord(n.health),
          height: n.height,
          tip: tip(n),
          group: 'Public nodes',
          actions: [
            EIconButton(
              icon: EIcons.starOutline,
              label: 'Add ${hostOf(n.url)} to my nodes',
              size: EBtnSize.inline,
              onPressed: () => showMyNodeDialog(context, initial: n.url, label: n.operator ?? '', adding: true),
            ),
          ],
        ),
      if (DeskFeatures.builtInNode) const ComboOption(value: builtinNode, host: 'Built-in node', sub: 'downloads the whole chain', icon: EIcons.monitor, group: 'This computer'),
    ];

    ComboOption? typedRow(String t) {
      if (!_addressLike.hasMatch(t)) return null;
      final r = _typedCheck;
      final checking = r == null || _typed != t;
      return ComboOption(
        value: t,
        host: hostOf(t),
        word: checking ? 'Checking…' : (r.health == ServiceHealth.down ? 'Not responding' : null),
        sub: !checking && r.health != ServiceHealth.down ? (versionOld(r.version) ? 'Version older than $minNodeVersion' : nodeWord(r.health)) : null,
        tone: checking ? ETone.warn : nodeTone(r.health),
        height: checking ? null : r.height,
        actions: [
          if (!mine.any((n) => n.url == t))
            EIconButton(icon: EIcons.starOutline, label: 'Add to my nodes', size: EBtnSize.inline, onPressed: () => showMyNodeDialog(context, initial: t, adding: true)),
        ],
      );
    }

    final health = prefs.builtin ? ServiceHealth.ok : (current.health == ServiceHealth.ok ? status.nodeHealth : current.health);
    return SettingsFrame(
      route: DeskRoute.settingsNode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JumpSection(
            section: SettingsJump.node,
            child: ESetGroup(
              title: 'Node',
              rows: [
                ESetRow(
                  title: 'Node server',
                  stacked: true,
                  control: ServiceCombo(
                    key: _combo,
                    label: 'Node server',
                    hint: 'Find or type a node address',
                    options: options,
                    value: value,
                    fieldText: prefs.builtin ? 'Built-in node' : hostOf(current.url),
                    fieldSub: prefs.builtin ? null : (prefs.nodeLabels[current.url] ?? current.operator),
                    tone: nodeTone(health),
                    busy: _saving,
                    busyLabel: 'Checking the node…',
                    error: _error,
                    openInitially: widget.arg == NodeDemo.comboOpen,
                    initialQuery: widget.arg == NodeDemo.typed || widget.arg == NodeDemo.pickFailed ? (widget.arg == NodeDemo.typed ? _demoTyped : 'bad.example:3413') : null,
                    onTyped: _onTyped,
                    typedRow: typedRow,
                    typedNote: (t) => _typedCheck?.health == ServiceHealth.down && _typed == t ? _portNote : 'Enter uses it. The star keeps it in My nodes.',
                    emptyNote: 'No nodes to show.',
                    onPicked: _pick,
                    footer: [
                      ('Add to my nodes…', EIcons.plus, () => showMyNodeDialog(context, adding: true)),
                      ('Node directory…', EIcons.book, () => showNodeDirectoryDialog(context)),
                    ],
                  ),
                  below: _error == null ? _StatusLine(node: current, health: health, height: status.nodeHeight, builtin: prefs.builtin) : null,
                ),
                if (_chainInUse) _chainRow(context),
                if (prefs.builtin)
                  ESetRow(
                    title: 'Sync in background',
                    text: 'Keeps syncing while the app is closed.',
                    control: ESwitch(
                      value: prefs.nodeBackground,
                      semanticLabel: 'Sync in background',
                      onChanged: (v) => p.set(prefs.copyWith(nodeBackground: v)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chainRow(BuildContext context) {
    final ts = context.ts;
    const dir = '~/.epic/main/chain_data';
    return ESetRow(
      title: 'Blockchain data',
      text: 'The built-in node uses blockchain data from this folder, which an older Epic Wallet made.',
      stacked: _chainAsk,
      control: _chainAsk
          ? null
          : EButton(label: 'Download again…', icon: EIcons.download, size: EBtnSize.sm, onPressed: () => setState(() => _chainAsk = true)),
      below: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(dir, style: ts.mono(size: Fs.sm, color: context.dc.dim), overflow: TextOverflow.ellipsis),
          if (_chainAsk) ...[
            SizedBox(height: Sp.x3),
            ENotice(
              title: 'Download the blockchain again?',
              text: 'The built-in node will use its own folder and download the whole chain. The data above stays where it is: nothing is deleted.',
              tone: ETone.gold,
              actions: [
                EButton(label: 'Cancel', size: EBtnSize.inline, kind: EBtnKind.ghost, onPressed: () => setState(() => _chainAsk = false)),
                EButton.primary(
                  label: 'Download again',
                  size: EBtnSize.inline,
                  onPressed: () {
                    setState(() {
                      _chainAsk = false;
                      _chainInUse = false;
                    });
                    showEToast(context, 'Downloading the blockchain again', text: 'The older data stays in $dir.');
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The line under the node field: state · height · last block age · old version.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.node, required this.health, required this.height, required this.builtin});

  final NodeServer node;
  final ServiceHealth health;
  final int height;
  final bool builtin;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final tone = nodeTone(health);
    final fg = switch (tone) {
      ETone.ok => c.ok,
      ETone.warn => c.warn,
      ETone.risk => c.risk,
      _ => c.faint,
    };
    final answers = health != ServiceHealth.down;
    final sep = TextSpan(text: '  ·  ', style: ts.small.copyWith(color: c.faint));
    return Semantics(
      liveRegion: true,
      child: Text.rich(
        TextSpan(
          style: ts.small,
          children: [
            TextSpan(text: nodeWord(health), style: ts.small.copyWith(color: fg, fontWeight: FontWeight.w600)),
            if (answers) ...[
              sep,
              TextSpan(text: groupDigits(height), style: ts.mono(size: Fs.sm, color: c.text)),
              if (DeskFeatures.nodeBlockTime) ...[sep, const TextSpan(text: 'last block 40 s ago')],
            ] else ...[
              sep,
              const TextSpan(text: 'no answer from the node'),
            ],
            if (!builtin && versionOld(node.version)) ...[
              sep,
              TextSpan(text: 'Version older than $minNodeVersion', style: ts.small.copyWith(color: c.warn)),
            ],
          ],
        ),
      ),
    );
  }
}
