/// The Local node step of the first run (spec §21) and the same content as a dialog from
/// Settings › Node: what running the node here means, then the choice between a node already
/// running on this computer and the bundled node, with the fallback checkbox. Nothing here
/// starts or downloads anything: the caller does, on Save.
library;

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/desk_node.dart';
import '../../data/node_view.dart';
import '../../widgets/kit.dart';

enum LocalNodeHow { bundled, existing }

/// What the user chose on the step.
@immutable
class LocalNodeChoice {
  const LocalNodeChoice({required this.how, required this.existingUrl, required this.useFallback, this.probe});

  final LocalNodeHow how;

  /// The address of the node already running here (the existing option).
  final String existingUrl;

  /// Use the public fallback until the bundled node is synced (D-7, answered here).
  final bool useFallback;

  /// The last check of [existingUrl].
  final LocalNodeProbe? probe;

  bool get existingFound => probe?.answers == true;

  LocalNodeChoice copyWith({LocalNodeHow? how, String? existingUrl, bool? useFallback, LocalNodeProbe? probe, bool clearProbe = false}) => LocalNodeChoice(
    how: how ?? this.how,
    existingUrl: existingUrl ?? this.existingUrl,
    useFallback: useFallback ?? this.useFallback,
    probe: clearProbe ? null : (probe ?? this.probe),
  );
}

/// The tour's start states of the step.
enum LocalNodeDemo { none, found, notFound }

/// "5 GB", "4.8 GB".
String _gb(int bytes) => bytesText(bytes);

class LocalNodeStep extends ConsumerStatefulWidget {
  const LocalNodeStep({super.key, required this.onChanged, this.demo = LocalNodeDemo.none, this.compact = false});

  final ValueChanged<LocalNodeChoice> onChanged;
  final LocalNodeDemo demo;

  /// Tighter spacing for the dialog.
  final bool compact;

  @override
  ConsumerState<LocalNodeStep> createState() => _LocalNodeStepState();
}

class _LocalNodeStepState extends ConsumerState<LocalNodeStep> {
  LocalNodeFacts? _facts;
  late final _url = TextEditingController(text: 'http://127.0.0.1:3413');
  var _choice = const LocalNodeChoice(how: LocalNodeHow.bundled, existingUrl: 'http://127.0.0.1:3413', useFallback: true);
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
      final p = switch (widget.demo) {
        LocalNodeDemo.found => LocalNodeProbe(url: 'http://127.0.0.1:3413', answers: true, version: '4.1.1', height: mockTip, readyForTxs: true, latencyMs: 3),
        LocalNodeDemo.notFound => const LocalNodeProbe(url: 'http://127.0.0.1:3413', answers: false),
        LocalNodeDemo.none => await api.probe(),
      };
      if (!mounted) return;
      _url.text = p.url;
      final found = p.answers && !p.ours;
      _set(_choice.copyWith(existingUrl: p.url, probe: widget.demo == LocalNodeDemo.notFound || found ? p : null, how: found ? LocalNodeHow.existing : LocalNodeHow.bundled));
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
    final free = f?.freeBytes == null ? l.deskOnbNodeFreeUnknown : l.deskOnbNodeFreeHere(_gb(f!.freeBytes!));
    final chain = f == null ? l.deskOnbNodeDiskAbout('5 GB') : (f.chainBytesMeasured ? l.deskOnbNodeDisk(_gb(f.chainBytes)) : l.deskOnbNodeDiskAbout(_gb(f.chainBytes)));
    final windows = f?.firewallPrompt ?? Platform.isWindows;
    final facts = <(IconData, String, String)>[
      (EIcons.server, l.deskOnbNodeSeparate, l.deskOnbNodeSeparateText),
      if (windows) (EIcons.shield, l.deskOnbNodeFirewall, l.deskOnbNodeFirewallText),
      (EIcons.folder, chain, l.deskOnbNodeGrowing(free)),
      (EIcons.clock, l.deskOnbNodeHours, l.deskOnbNodeHoursText),
      (EIcons.download, l.deskOnbNodeDownload, l.deskOnbNodeDownloadText),
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
                  text: [
                    '',
                    l.deskOnbNodeFoundAt(p.version ?? '?', '${nodeHost(p.url)}:${Uri.parse(p.url).port}'),
                    if (p.height != null) l.deskOnbNodeHeight(digits(p.height!)),
                    if (p.readyForTxs == true) l.deskOnbNodeSynced,
                  ].join(' · '),
                  style: ts.small.copyWith(color: c.dim),
                ),
              ],
            ),
          )
        : Text.rich(
            TextSpan(
              children: [
                TextSpan(text: l.deskOnbNodeNoAnswer, style: ts.small.copyWith(color: c.risk, fontWeight: FontWeight.w600)),
                TextSpan(text: ' · ${l.deskOnbNodeNoAnswerAt('${nodeHost(p.url)}:${Uri.parse(p.url).port}')}', style: ts.small.copyWith(color: c.dim)),
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
                    // Field and button one height and one of the row widths (R4).
                    ERowControl(
                      child: EInput(
                        size: EBtnSize.sm,
                        controller: _url,
                        mono: true,
                        hint: '127.0.0.1:3413',
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
        ExpandFade(
          open: !existing,
          child: Padding(
            padding: EdgeInsets.fromLTRB(Sp.x4, Sp.x3, 0, Sp.x1),
            child: ECheckbox(
              value: _choice.useFallback,
              label: l.deskOnbNodeFallback(nodeHost(defaultFallbackNodeUrl)),
              onChanged: (v) => _set(_choice.copyWith(useFallback: v)),
            ),
          ),
        ),
      ],
    );
  }
}

/// The step as a dialog from Settings › Node (picking the Local node row while it is not set
/// up). Returns the choice, or null on Cancel.
Future<LocalNodeChoice?> showLocalNodeSetupDialog(BuildContext context, {LocalNodeDemo demo = LocalNodeDemo.none}) =>
    showEDialog<LocalNodeChoice>(context, builder: (_) => LocalNodeSetupDialog(demo: demo));

class LocalNodeSetupDialog extends StatefulWidget {
  const LocalNodeSetupDialog({super.key, this.demo = LocalNodeDemo.none});

  final LocalNodeDemo demo;

  @override
  State<LocalNodeSetupDialog> createState() => _LocalNodeSetupDialogState();
}

class _LocalNodeSetupDialogState extends State<LocalNodeSetupDialog> {
  LocalNodeChoice? _choice;

  @override
  Widget build(BuildContext context) {
    final c = _choice;
    final l = context.l10n;
    final existing = c?.how == LocalNodeHow.existing;
    return EDialog(
      title: l.deskOnbNodeDialogTitle,
      description: l.deskOnbNodeDialogBody,
      icon: EIcons.monitor,
      width: 640.u,
      body: LocalNodeStep(compact: true, demo: widget.demo, onChanged: (v) => setState(() => _choice = v)),
      actions: [
        EButton.ghost(label: l.commonCancel, size: EBtnSize.md, onPressed: () => Navigator.of(context).pop()),
        EButton.primary(
          label: existing ? l.deskOnbNodeUseThis : l.deskOnbNodeStart,
          onPressed: c == null || (existing && !c.existingFound) ? null : () => Navigator.of(context).pop(c),
        ),
      ],
    );
  }
}
