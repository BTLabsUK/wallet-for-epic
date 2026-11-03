// SPDX-License-Identifier: Apache-2.0
/// The Local node step of the first run and the same content as a dialog from
/// Settings › Node: what running the node here means, then the choice between a node already
/// running on this computer and the bundled node, with the fallback checkbox. Nothing here
/// starts or downloads anything: the caller does, on Save.
library;

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import '../../../mock_fixtures.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/desk_node.dart';
import '../../data/node_view.dart';
import '../../widgets/kit.dart';
import '../../../settings_file/host_settings.dart' show appConfig, hostSettings;
import '../../../settings_file/settings_layout.dart' show userPortMin;

enum LocalNodeHow { bundled, existing }

/// What the user chose on the step.
@immutable
class LocalNodeChoice {
  const LocalNodeChoice({required this.how, required this.existingUrl, required this.useFallback, this.probe, this.ports = const LocalNodePorts.typed(apiText: '', p2pText: '')});

  final LocalNodeHow how;

  /// The address of the node already running here (the existing option).
  final String existingUrl;

  /// Use the public fallback until the bundled node is synced (answered here).
  final bool useFallback;

  /// The last check of [existingUrl].
  final LocalNodeProbe? probe;

  /// The bundled node's ports as typed under Advanced (the settings' values until edited; the
  /// first run's step, which has no fold, leaves them empty and keeps the settings' ports).
  final LocalNodePorts ports;

  bool get existingFound => probe?.answers == true;

  LocalNodeChoice copyWith({LocalNodeHow? how, String? existingUrl, bool? useFallback, LocalNodeProbe? probe, bool clearProbe = false, LocalNodePorts? ports}) =>
      LocalNodeChoice(
        how: how ?? this.how,
        existingUrl: existingUrl ?? this.existingUrl,
        useFallback: useFallback ?? this.useFallback,
        probe: clearProbe ? null : (probe ?? this.probe),
        ports: ports ?? this.ports,
      );
}

/// The bundled node's two ports as typed: [apiText] and [p2pText] are the fields' text, so a
/// half-typed value is kept and judged. [api] and [p2p] are the numbers, null while a field
/// does not hold a port in range. [LocalNodePorts()] is the settings' current pair.
@immutable
class LocalNodePorts {
  const LocalNodePorts._(this.apiText, this.p2pText);

  /// The ports in use now: the user's `[local_node]` keys over `app-config.toml`.
  factory LocalNodePorts() => LocalNodePorts._('${hostSettings.localNodeApiPort}', '${hostSettings.localNodeP2pPort}');

  const LocalNodePorts.typed({required this.apiText, required this.p2pText});

  final String apiText;
  final String p2pText;

  int? get api => parsePort(apiText);
  int? get p2p => parsePort(p2pText);

  /// Both numbers in range and different from each other.
  bool get valid => api != null && p2p != null && api != p2p;

  /// Why [text] is not a port, as the field says it, or null.
  static PortProblem? problemOf(String text, {int? other}) {
    final n = parsePort(text);
    if (n == null) return PortProblem.range;
    if (other != null && n == other) return PortProblem.same;
    return null;
  }

  /// [text] as a port from [userPortMin] to 65535, or null.
  static int? parsePort(String text) {
    final n = int.tryParse(text.trim());
    return n == null || n < userPortMin || n > 65535 ? null : n;
  }

  LocalNodePorts copyWith({String? apiText, String? p2pText}) => LocalNodePorts._(apiText ?? this.apiText, p2pText ?? this.p2pText);

  @override
  bool operator ==(Object other) => other is LocalNodePorts && other.apiText == apiText && other.p2pText == p2pText;

  @override
  int get hashCode => Object.hash(apiText, p2pText);
}

/// What is wrong with a typed port.
enum PortProblem { range, same }

/// The two port fields of the bundled node (API, P2P), with the tooltip on why one would
/// change them, the errors under them and, after a Save found a port taken, the next free one
/// as a link that fills it in ([taken]: port → suggested free port).
class LocalNodePortsFields extends StatefulWidget {
  const LocalNodePortsFields({super.key, required this.ports, required this.onChanged, this.taken = const {}});

  final LocalNodePorts ports;
  final ValueChanged<LocalNodePorts> onChanged;
  final Map<int, int> taken;

  @override
  State<LocalNodePortsFields> createState() => _LocalNodePortsFieldsState();
}

class _LocalNodePortsFieldsState extends State<LocalNodePortsFields> {
  late final _api = TextEditingController(text: widget.ports.apiText);
  late final _p2p = TextEditingController(text: widget.ports.p2pText);

  @override
  void didUpdateWidget(LocalNodePortsFields old) {
    super.didUpdateWidget(old);
    if (widget.ports.apiText != _api.text) _api.text = widget.ports.apiText;
    if (widget.ports.p2pText != _p2p.text) _p2p.text = widget.ports.p2pText;
  }

  @override
  void dispose() {
    _api.dispose();
    _p2p.dispose();
    super.dispose();
  }

  String? _error(AppLocalizations l, String text, {required int? other}) {
    final n = LocalNodePorts.parsePort(text);
    final next = n == null ? null : widget.taken[n];
    if (n != null && next != null) return l.deskOnbNodePortTaken('$n', '$next');
    return switch (LocalNodePorts.problemOf(text, other: other)) {
      PortProblem.range => l.deskOnbNodePortRange('$userPortMin', '65535'),
      PortProblem.same => l.deskOnbNodePortsSame,
      null => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    final p = widget.ports;
    final apiError = _error(l, p.apiText, other: p.p2p);
    // The "same" error shows once, under the P2P field.
    final apiShown = apiError == l.deskOnbNodePortsSame ? null : apiError;
    final p2pError = _error(l, p.p2pText, other: p.api);
    final apiNext = p.api == null ? null : widget.taken[p.api];
    final p2pNext = p.p2p == null ? null : widget.taken[p.p2p];
    final formatters = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)];

    Widget field({required String label, required TextEditingController ctl, required int byDefault, required String? error, required int? next, required void Function(String) set}) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: ts.small.copyWith(fontWeight: FontWeight.w600, color: c.text)),
                SizedBox(width: Sp.x1),
                EInfoHint(l.deskOnbNodePortsWhy),
              ],
            ),
            SizedBox(height: Sp.x1),
            EInput(
              size: EBtnSize.sm,
              controller: ctl,
              mono: true,
              hint: '$byDefault',
              invalid: error != null,
              keyboardType: TextInputType.number,
              inputFormatters: formatters,
              semanticLabel: label,
              onChanged: set,
            ),
            if (error != null) ...[
              SizedBox(height: Sp.x1),
              Semantics(
                liveRegion: true,
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Sp.x2,
                  children: [
                    Text(error, style: ts.caption.copyWith(color: c.risk)),
                    if (next != null) ELink(label: l.deskOnbNodePortUse('$next'), onPressed: () => set('$next')),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field(label: l.deskOnbNodeApiPort, ctl: _api, byDefault: appConfig.localNodeApiPort, error: apiShown, next: apiNext, set: (v) => widget.onChanged(p.copyWith(apiText: v))),
        SizedBox(width: Sp.x3),
        field(label: l.deskOnbNodeP2pPort, ctl: _p2p, byDefault: appConfig.localNodeP2pPort, error: p2pError, next: p2pNext, set: (v) => widget.onChanged(p.copyWith(p2pText: v))),
      ],
    );
  }
}

/// The tour's start states of the step.
enum LocalNodeShot { none, found, notFound }

/// "5 GB", "4.8 GB".
String _gb(AppLocalizations l, int bytes) => bytesText(bytes, l);

class LocalNodeStep extends ConsumerStatefulWidget {
  const LocalNodeStep({super.key, required this.onChanged, this.shot = LocalNodeShot.none, this.compact = false, this.ports = false, this.portsOpen = false, this.taken = const {}});

  final ValueChanged<LocalNodeChoice> onChanged;
  final LocalNodeShot shot;

  /// Tighter spacing for the dialog.
  final bool compact;

  /// The Advanced fold with the bundled node's port fields (the Settings dialog; the first
  /// run keeps the defaults).
  final bool ports;

  /// The fold open from the start (the tour).
  final bool portsOpen;

  /// Ports a Save found taken, each with the next free one (see [LocalNodePortsFields]).
  final Map<int, int> taken;

  @override
  ConsumerState<LocalNodeStep> createState() => _LocalNodeStepState();
}

class _LocalNodeStepState extends ConsumerState<LocalNodeStep> {
  LocalNodeFacts? _facts;
  /// A node of its own on this computer, at the built-in node's API port (`node.local.api_port`).
  static String get _localUrl => 'http://127.0.0.1:${appConfig.localNodeApiPort}';

  late final _url = TextEditingController(text: _localUrl);
  // No fallback to offer with an empty Node list: the wallet waits for the local node.
  var _choice = LocalNodeChoice(how: LocalNodeHow.bundled, existingUrl: _localUrl, useFallback: hasFallbackNode, ports: LocalNodePorts());
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final api = ref.read(deskNodeProvider);
    api.facts().then((f) => mounted ? setState(() => _facts = f) : null);
    // Something already answering on this computer, that is not the wallet's own node?
    () async {
      // Never inside the first build: the parent gets the choice a microtask later.
      await Future<void>.delayed(Duration.zero);
      final p = switch (widget.shot) {
        LocalNodeShot.found => LocalNodeProbe(url: _localUrl, answers: true, version: mockNodeVersion, height: mockTip, readyForTxs: true, latencyMs: 3),
        LocalNodeShot.notFound => LocalNodeProbe(url: _localUrl, answers: false),
        LocalNodeShot.none => await api.probe(),
      };
      if (!mounted) return;
      _url.text = p.url;
      final found = p.answers && !p.ours;
      _set(_choice.copyWith(existingUrl: p.url, probe: widget.shot == LocalNodeShot.notFound || found ? p : null, how: found ? LocalNodeHow.existing : LocalNodeHow.bundled));
    }();
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _set(LocalNodeChoice c) {
    setState(() => _choice = c);
    widget.onChanged(c);
  }

  Future<void> _check() async {
    final url = _url.text.trim();
    if (url.isEmpty) return;
    setState(() => _checking = true);
    final p = await ref.read(deskNodeProvider).probe(url: url.contains('://') ? url : 'http://$url');
    if (!mounted) return;
    _checking = false;
    _set(_choice.copyWith(existingUrl: p.url, probe: p, how: LocalNodeHow.existing));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final f = _facts;
    final free = f?.freeBytes == null ? l.deskOnbNodeFreeUnknown : l.deskOnbNodeFreeHere(_gb(l, f!.freeBytes!));
    final chain = f == null ? l.deskOnbNodeDiskAbout('5 GB') : (f.chainBytesMeasured ? l.deskOnbNodeDisk(_gb(l, f.chainBytes)) : l.deskOnbNodeDiskAbout(_gb(l, f.chainBytes)));
    final windows = f?.firewallPrompt ?? Platform.isWindows;
    final facts = <(IconData, String, String)>[
      if (windows) (EIcons.shield, l.deskOnbNodeFirewall, l.deskOnbNodeFirewallText),
      (EIcons.folder, chain, l.deskOnbNodeGrowing(free)),
    ];
    final p = _choice.probe;
    final existing = _choice.how == LocalNodeHow.existing;
    final gap = widget.compact ? Sp.x2 : Sp.x3;
    final Widget? stateLine = p == null
        ? null
        : p.answers
        ? Text.rich(
            TextSpan(
              children: [
                TextSpan(text: l.deskOnbNodeFound, style: ts.small.copyWith(color: c.ok, fontWeight: FontWeight.w600)),
                TextSpan(
                  // The dot after "Found" leads the line (metaLine drops a blank part).
                  text: metaSeparator + metaLine([
                    l.deskOnbNodeFoundAt(p.version ?? '?', hostPort(p.url)),
                    if (p.height != null) l.deskOnbNodeHeight(digits(context.l10n, p.height!)),
                    if (p.readyForTxs == true) l.deskOnbNodeSynced,
                  ]),
                  style: ts.small.copyWith(color: c.dim),
                ),
              ],
            ),
          )
        : Text.rich(
            TextSpan(
              children: [
                TextSpan(text: l.deskOnbNodeNoAnswer, style: ts.small.copyWith(color: c.risk, fontWeight: FontWeight.w600)),
                TextSpan(text: '$metaSeparator${l.deskOnbNodeNoAnswerAt(hostPort(p.url))}', style: ts.small.copyWith(color: c.dim)),
              ],
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (icon, lead, text) in facts)
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: EdgeInsets.only(top: 2.u), child: Icon(icon, size: Ctl.iconSm, color: c.dim)),
                SizedBox(width: Sp.x3),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: lead, style: ts.small.copyWith(fontWeight: FontWeight.w600, color: c.text)),
                        TextSpan(text: ' $text', style: ts.small.copyWith(color: c.dim)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: gap),
        EChoiceCard(
          title: l.deskOnbNodeExisting,
          description: l.deskOnbNodeExistingText,
          icon: EIcons.monitor,
          selected: existing,
          onTap: () => _set(_choice.copyWith(how: LocalNodeHow.existing)),
        ),
        ExpandFade(
          open: existing,
          child: Padding(
            padding: EdgeInsets.fromLTRB(Sp.x4, Sp.x3, 0, Sp.x1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Field and button one height and one of the row widths.
                    ERowControl(
                      child: EInput(
                        size: EBtnSize.sm,
                        controller: _url,
                        mono: true,
                        hint: '127.0.0.1:${appConfig.localNodeApiPort}',
                        semanticLabel: l.deskOnbNodeAddress,
                        onChanged: (_) => _set(_choice.copyWith(clearProbe: true)),
                        onSubmitted: (_) => _check(),
                      ),
                    ),
                    SizedBox(width: Sp.x2),
                    ERowControl(child: EButton(label: l.deskOnbNodeCheck, size: EBtnSize.sm, busy: _checking, onPressed: _checking ? null : _check)),
                  ],
                ),
                if (stateLine != null) ...[SizedBox(height: Sp.x2), Semantics(liveRegion: true, child: stateLine)],
              ],
            ),
          ),
        ),
        SizedBox(height: gap),
        EChoiceCard(
          title: l.deskOnbNodeBundled,
          description: l.deskOnbNodeBundledText,
          icon: EIcons.node,
          selected: !existing,
          onTap: () => _set(_choice.copyWith(how: LocalNodeHow.bundled)),
        ),
        // The fallback checkbox only with a node to fall back to; the ports fold regardless.
        ExpandFade(
          open: !existing && (hasFallbackNode || widget.ports),
          child: Padding(
            padding: EdgeInsets.fromLTRB(Sp.x4, Sp.x3, 0, Sp.x1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasFallbackNode)
                  ECheckbox(
                    value: _choice.useFallback,
                    label: l.deskOnbNodeFallback(nodeHost(defaultFallbackNodeUrl)),
                    onChanged: (v) => _set(_choice.copyWith(useFallback: v)),
                  ),
                if (widget.ports) ...[
                  if (hasFallbackNode) SizedBox(height: gap),
                  EDetails(
                    key: const ValueKey('local-node-advanced'),
                    title: l.deskOnbNodeAdvanced,
                    subtitle: _portsSubtitle(l),
                    initiallyOpen: widget.portsOpen || widget.taken.isNotEmpty,
                    child: LocalNodePortsFields(ports: _choice.ports, taken: widget.taken, onChanged: (p) => _set(_choice.copyWith(ports: p))),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The ports beside the fold's title while they are not the defaults.
  String? _portsSubtitle(AppLocalizations l) {
    final p = _choice.ports;
    if (p.api == appConfig.localNodeApiPort && p.p2p == appConfig.localNodeP2pPort) return null;
    return '· ${l.deskOnbNodePortsSub(p.apiText, p.p2pText)}';
  }
}

/// The step as a dialog from Settings › Node (picking the Local node row while it is not set
/// up), with the Advanced fold for the bundled node's ports. Returns the choice, or null on
/// Cancel. The primary action checks the ports are free on this computer first; a taken one
/// is named with the next free port, and nothing is returned until both are free.
Future<LocalNodeChoice?> showLocalNodeSetupDialog(BuildContext context, {LocalNodeShot shot = LocalNodeShot.none, bool portsOpen = false}) =>
    showEDialog<LocalNodeChoice>(context, builder: (_) => LocalNodeSetupDialog(shot: shot, portsOpen: portsOpen));

class LocalNodeSetupDialog extends ConsumerStatefulWidget {
  const LocalNodeSetupDialog({super.key, this.shot = LocalNodeShot.none, this.portsOpen = false});

  final LocalNodeShot shot;

  /// The Advanced fold open from the start (the tour's shot).
  final bool portsOpen;

  @override
  ConsumerState<LocalNodeSetupDialog> createState() => _LocalNodeSetupDialogState();
}

class _LocalNodeSetupDialogState extends ConsumerState<LocalNodeSetupDialog> {
  LocalNodeChoice? _choice;
  Map<int, int> _taken = const {};
  bool _checking = false;

  Future<void> _start() async {
    final c = _choice!;
    setState(() => _checking = true);
    final taken = await findTakenPorts(ref.read(deskNodeProvider), c.ports);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _taken = taken;
    });
    if (taken.isEmpty) Navigator.of(context).pop(c);
  }

  @override
  Widget build(BuildContext context) {
    final c = _choice;
    final l = context.l10n;
    final existing = c?.how == LocalNodeHow.existing;
    final ready = c != null && (existing ? c.existingFound : c.ports.valid);
    return EDialog(
      title: l.deskOnbNodeDialogTitle,
      description: l.deskOnbNodeDialogBody,
      icon: EIcons.monitor,
      size: DialogWidth.wide,
      body: LocalNodeStep(
        compact: true,
        shot: widget.shot,
        ports: true,
        portsOpen: widget.portsOpen,
        taken: _taken,
        onChanged: (v) => setState(() {
          // A typed port is judged afresh: the taken mark goes with the number.
          if (_choice?.ports != v.ports) _taken = {for (final e in _taken.entries) if (e.key == v.ports.api || e.key == v.ports.p2p) e.key: e.value};
          _choice = v;
        }),
      ),
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.of(context).pop()),
        EButton.primary(
          label: existing ? l.deskOnbNodeUseThis : l.deskOnbNodeStart,
          busy: _checking,
          onPressed: !ready || _checking ? null : (existing ? () => Navigator.of(context).pop(c) : _start),
        ),
      ],
    );
  }
}

/// The ports of [ports] something else answers on, each with the next free port above it (not
/// the other port of the pair); empty when both are free. [keep] are ports the running
/// built-in node holds itself, not counted as taken.
Future<Map<int, int>> findTakenPorts(DeskNodeApi api, LocalNodePorts ports, {Set<int> keep = const {}}) async {
  final api0 = ports.api, p2p0 = ports.p2p;
  if (api0 == null || p2p0 == null) return const {};
  final out = <int, int>{};
  for (final (port, other) in [(api0, p2p0), (p2p0, api0)]) {
    if (keep.contains(port) || !await api.portInUse(port)) continue;
    var next = port + 1;
    while (next <= 65535 && (next == other || await api.portInUse(next))) {
      next++;
    }
    out[port] = next;
  }
  return out;
}
