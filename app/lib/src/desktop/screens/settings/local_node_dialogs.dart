// SPDX-License-Identifier: Apache-2.0
/// The local node's dialogs: the one-time fallback question, Delete chain
/// data with a typed confirm, Reuse existing chain data, the node log, Change folder.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../log.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../data/desk_node.dart';
import '../../data/files.dart' show deskOpenFolderProvider;
import '../../data/node_view.dart';
import '../../widgets/kit.dart';
import '../../widgets/server_row.dart';
import '../wallet/tx_display.dart' show shortDay;
import '../../../settings_file/host_settings.dart' show hostSettings, localNodePortValues;
import '../../../settings_file/settings_providers.dart' show writeHostSettings;
import '../onboarding/local_node_step.dart' show LocalNodePorts, LocalNodePortsFields, findTakenPorts;
import 'settings_node.dart' show serverRows, nodeListNoteText;

/// The built-in node's ports from the panel's Ports row. Save checks a changed port is free
/// (a taken one is named with the next free port), writes `[local_node]` to settings.toml
/// (only while the ports differ from the defaults) and, with the node [running], restarts it
/// and moves the wallet to its new address.
Future<void> showLocalNodePortsDialog(BuildContext context, DeskNodeApi api, {required bool running}) =>
    showEDialog<void>(context, builder: (_) => LocalNodePortsDialog(api: api, running: running));

class LocalNodePortsDialog extends ConsumerStatefulWidget {
  const LocalNodePortsDialog({super.key, required this.api, required this.running});

  final DeskNodeApi api;
  final bool running;

  @override
  ConsumerState<LocalNodePortsDialog> createState() => _LocalNodePortsDialogState();
}

class _LocalNodePortsDialogState extends ConsumerState<LocalNodePortsDialog> {
  final _was = LocalNodePorts();
  late LocalNodePorts _ports = _was;
  Map<int, int> _taken = const {};
  bool _busy = false;

  Future<void> _save() async {
    final l = context.l10n;
    final p = _ports;
    setState(() => _busy = true);
    // The running node answers on its own ports: those are not another program's.
    final keep = widget.running ? {_was.api!, _was.p2p!} : const <int>{};
    final taken = await findTakenPorts(widget.api, p, keep: keep);
    if (!mounted) return;
    if (taken.isNotEmpty) {
      setState(() {
        _busy = false;
        _taken = taken;
      });
      return;
    }
    try {
      await writeHostSettings(localNodePortValues(hostSettings, api: p.api!, p2p: p.p2p!));
      if (widget.running) {
        await widget.api.restart();
        await ref.read(deskProvider.notifier).followBuiltInNode();
      }
    } on Object catch (e) {
      logWarn('desk', 'node ports not saved: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      showEToast(context, l.deskSetLnodePortsNotSaved, text: deskErrorText(e, l), tone: ETone.risk);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showEToast(context, l.deskSetLnodePortsSaved, text: widget.running ? l.deskSetLnodePortsRestarting : null, tone: ETone.ok);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final changed = _ports != _was;
    return EDialog(
      title: l.deskSetLnodePortsTitle,
      icon: EIcons.node,
      description: l.deskSetLnodePortsDesc,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LocalNodePortsFields(
            ports: _ports,
            taken: _taken,
            onChanged: (p) => setState(() {
              _taken = {for (final e in _taken.entries) if (e.key == p.api || e.key == p.p2p) e.key: e.value};
              _ports = p;
            }),
          ),
          if (widget.running) ...[SizedBox(height: Sp.x3), Text(l.deskSetLnodePortsRestart, style: context.ts.caption)],
        ],
      ),
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.of(context).pop()),
        EButton.primary(label: l.commonSave, busy: _busy, onPressed: changed && _ports.valid && !_busy ? _save : null),
      ],
    );
  }
}

/// The local node's fallback was asked this session (the dialog shows once).
bool fallbackAskedThisSession = false;

/// The fallback question: once, when the bundled node first syncs and nothing was answered yet.
/// [host] is the fallback's host. True = use it, false = wait, null = dismissed (asked again
/// later; the switch under While syncing answers it for good).
Future<bool?> showFallbackAskDialog(BuildContext context, {required String host}) => showEDialog<bool>(
  context,
  builder: (context) {
    final l = context.l10n;
    return EDialog(
      title: l.deskSetLndAskTitle(host),
      icon: EIcons.server,
      description: l.deskSetLndAskDesc(host),
      body: Text(l.deskSetLndAskNote, style: context.ts.caption),
      actions: [
        EButton(label: l.deskSetLndAskWait, onPressed: () => Navigator.of(context).pop(false)),
        EButton.primary(label: l.deskSetLndAskUse(host), onPressed: () => Navigator.of(context).pop(true)),
      ],
    );
  },
);

/// Shows the fallback question when the decision asks for it, once per session, and saves the
/// answer. Call from a widget that watches [deskFallbackDecisionProvider].
Future<void> maybeAskFallback(BuildContext context, WidgetRef ref) async {
  final d = ref.read(deskFallbackDecisionProvider);
  if (d == null || d.action != FallbackAction.ask || fallbackAskedThisSession) return;
  fallbackAskedThisSession = true;
  final url = d.nodeUrl ?? defaultFallbackNodeUrl;
  // No public node to offer (an empty Node list): nothing to ask.
  if (url.isEmpty) return;
  final yes = await showFallbackAskDialog(context, host: nodeHost(url));
  if (yes == null) return;
  await ref.read(deskFallbackProvider.notifier).set(FallbackChoice(yes ? FallbackConsent.accepted : FallbackConsent.declined, nodeUrl: url, at: DateTime.now()));
}

/// The public node list of §18 without This computer, for the fallback choice. Returns the
/// picked URL.
Future<String?> showFallbackPickerDialog(BuildContext context, {required String current}) => showEDialog<String>(
  context,
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      final nodes = ref.watch(deskProvider.select((s) => s.nodes)) ?? const <NodeServer>[];
      // The fallback is kept only for an https node (FallbackChoice.fromJson): list only those.
      final rows = serverRows(nodes.where((n) => !n.own && n.url.startsWith('https://')).toList());
      final l = context.l10n;
      return EDialog(
        title: l.deskSetLndPickTitle,
        description: l.deskSetLndPickDesc,
        icon: EIcons.node,
        // Room for the host before the fixed operator, tip and latency columns.
        size: DialogWidth.wide,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (rows.isEmpty) Text(l.deskSlNoNodeTitle, style: context.ts.body),
            for (final r in rows) ServerRow(kind: ServerKind.node, info: r, selected: r.value == current, onTap: () => Navigator.of(context).pop(r.value)),
            SizedBox(height: Sp.x2),
            Text(nodeListNoteText(l), style: context.ts.caption),
          ],
        ),
        actions: [EButton(label: l.commonCancel, onPressed: () => Navigator.of(context).pop())],
      );
    },
  ),
);

/// Delete chain data: the button enables only once the field reads exactly `delete`.
Future<void> showDeleteChainDataDialog(BuildContext context, DeskNodeApi api, LocalNodeState s) =>
    showEDialog<void>(context, builder: (_) => DeleteChainDataDialog(api: api, state: s));

class DeleteChainDataDialog extends StatefulWidget {
  const DeleteChainDataDialog({super.key, required this.api, required this.state});

  final DeskNodeApi api;
  final LocalNodeState state;

  @override
  State<DeleteChainDataDialog> createState() => _DeleteChainDataDialogState();
}

class _DeleteChainDataDialogState extends State<DeleteChainDataDialog> {
  final _text = TextEditingController();
  bool _busy = false;

  /// The word typed to confirm; the same in every language.
  static const _word = 'delete'; // l10n-ok: the typed confirmation word

  bool get _ok => _text.text.trim() == _word;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await widget.api.stop();
      final freed = await widget.api.deleteChainData();
      if (!mounted) return;
      Navigator.of(context).pop();
      showEToast(context, l.deskSetLndDeleted, text: l.deskSetLndFreed(bytesText(freed, l)), tone: ETone.ok);
    } on Object catch (e) {
      logWarn('desk', 'node chain data not deleted: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      showEToast(context, l.deskSetLndNotDeleted, text: deskErrorText(e, l), tone: ETone.risk);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    final s = widget.state;
    final l = context.l10n;
    return EDialog(
      title: l.deskSetLndDeleteQuestion,
      icon: EIcons.trash,
      tone: ETone.risk,
      description: s.chainDataBytes == null ? l.deskSetLndDeleteDescNoSize(s.chainDataPath) : l.deskSetLndDeleteDesc(bytesText(s.chainDataBytes!, l), s.chainDataPath),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _withWord(l.deskSetLndTypeToConfirm('\u0000'), _word, ts.mono(size: Fs.sm, color: c.text, weight: FontWeight.w600), style: ts.small),
          SizedBox(height: Sp.x2),
          EInput(controller: _text, hint: _word, mono: true, autofocus: true, semanticLabel: l.deskSetLndTypeToConfirmLabel(_word), onChanged: (_) => setState(() {}), onSubmitted: (_) => _ok && !_busy ? _go() : null),
        ],
      ),
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.of(context).pop()),
        EButton(label: l.deskSetLndDeleteTitle, kind: EBtnKind.danger, busy: _busy, onPressed: _ok && !_busy ? _go : null),
      ],
    );
  }
}

/// [text] with the placeholder `\u0000` replaced by [word] in [wordStyle]: a sentence around a typed word.
Widget _withWord(String text, String word, TextStyle wordStyle, {TextStyle? style}) {
  final i = text.indexOf('\u0000');
  return Text.rich(
    TextSpan(children: [TextSpan(text: text.substring(0, i)), TextSpan(text: word, style: wordStyle), TextSpan(text: text.substring(i + 1))]),
    style: style,
  );
}

/// Chain data found on this computer, the one dialog for every offer (setup, Settings › Node):
/// one card per candidate (a folder another program holds shows, dimmed, as in use), a last
/// card to download fresh. Returns true when a folder was taken into use, false for fresh.
Future<bool?> showReuseChainDataDialog(BuildContext context, DeskNodeApi api) =>
    showEDialog<bool>(context, builder: (_) => ReuseChainDataDialog(api: api));

class ReuseChainDataDialog extends StatefulWidget {
  const ReuseChainDataDialog({super.key, required this.api});

  final DeskNodeApi api;

  @override
  State<ReuseChainDataDialog> createState() => _ReuseChainDataDialogState();
}

class _ReuseChainDataDialogState extends State<ReuseChainDataDialog> {
  List<ChainDataInfo>? _found;
  LocalNodeFacts? _facts;
  String? _pick;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    () async {
      final found = await widget.api.chainDataCandidates();
      final facts = await widget.api.facts();
      if (!mounted) return;
      setState(() {
        _found = found;
        _facts = facts;
        _pick ??= found.where((f) => f.lock != FolderLock.locked).map((f) => f.path).firstOrNull ?? '';
      });
    }();
  }

  String _source(AppLocalizations l, ChainDataInfo f) => switch (f.source) {
    ChainDataSource.cli => l.deskSetLndSourceCli,
    ChainDataSource.gui => l.deskSetLndSourceGui,
    ChainDataSource.bundled => l.deskSetLndSourceBundled,
    ChainDataSource.custom => l.deskSetLndSourceCustom,
  };

  Future<void> _go() async {
    final pick = _pick;
    if (pick == null) return;
    if (pick.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    final f = _found!.firstWhere((f) => f.path == pick);
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await widget.api.reuseChainData(f, ReuseMode.point);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showEToast(context, l.deskSetLndInUse, text: f.path, tone: ETone.ok);
    } on Object catch (e) {
      logWarn('desk', 'node chain data not reused: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      showEToast(context, l.deskSetLndNotInUse, text: deskErrorText(e, l), tone: ETone.risk);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    final l = context.l10n;
    final found = _found;
    return EDialog(
      title: l.deskSetLndReuseTitle,
      icon: EIcons.folder,
      size: DialogWidth.wide,
      description: l.deskSetLndReuseDesc,
      body: found == null
          ? SizedBox(height: 80.u, child: Center(child: Text(l.deskSetLndLooking, style: ts.small.copyWith(color: c.dim))))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final f in found) ...[
                  _ReuseCard(
                    // Each option named by its owner and size: the titles differ (UD-018).
                    title: metaLine([_source(l, f), bytesText(f.bytes, l)]),
                    path: f.path,
                    line: f.modified == null ? '' : l.deskSetLndLastWritten(shortDay(l, f.modified!)),
                    sub: f.lock == FolderLock.locked ? l.deskSetLndLocked : l.deskSetLndNothingCopied,
                    selected: _pick == f.path,
                    enabled: f.lock != FolderLock.locked,
                    onTap: () => setState(() => _pick = f.path),
                  ),
                  SizedBox(height: Sp.x2),
                ],
                _ReuseCard(
                  title: l.deskSetLndFresh,
                  line: l.deskSetLndFreshLine(_facts == null ? '5 GB' : bytesText(_facts!.chainBytes, l)),
                  selected: _pick == '',
                  enabled: true,
                  onTap: () => setState(() => _pick = ''),
                ),
              ],
            ),
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.of(context).pop()),
        EButton.primary(label: l.commonContinue, busy: _busy, onPressed: found == null || _pick == null || _busy ? null : _go),
      ],
    );
  }
}

class _ReuseCard extends StatelessWidget {
  const _ReuseCard({required this.title, this.path, required this.line, this.sub, required this.selected, required this.enabled, required this.onTap});

  final String title;
  final String? path;
  final String line;
  final String? sub;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: EChoiceCard(
        title: title,
        selected: selected,
        onTap: enabled ? onTap : () {},
        tag: path == null ? null : Text(path!, style: ts.mono(size: Fs.xs, color: c.dim), maxLines: 1, overflow: TextOverflow.ellipsis),
        description: [if (line.isNotEmpty) line, ?sub].join('\n'),
      ),
    );
  }
}

/// The last 200 lines of epic-server.log, newest at the bottom.
Future<void> showNodeLogDialog(BuildContext context, DeskNodeApi api) => showEDialog<void>(context, builder: (_) => NodeLogDialog(api: api));

class NodeLogDialog extends ConsumerStatefulWidget {
  const NodeLogDialog({super.key, required this.api});

  final DeskNodeApi api;

  @override
  ConsumerState<NodeLogDialog> createState() => _NodeLogDialogState();
}

class _NodeLogDialogState extends ConsumerState<NodeLogDialog> {
  List<String>? _lines;
  String? _path;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    () async {
      final lines = await widget.api.logTail();
      final path = await widget.api.logPath();
      if (!mounted) return;
      setState(() {
        _lines = lines;
        _path = path;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l10n = context.l10n;
    final lines = _lines;
    final stamp = RegExp(r'^(\d{8} \d\d:\d\d:\d\d(?:\.\d+)?)\s*(.*)$');
    return EDialog(
      title: l10n.deskSetLndLogTitle,
      icon: EIcons.log,
      size: DialogWidth.wide,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 320.u,
            padding: EdgeInsets.all(Sp.x3),
            decoration: c.well,
            child: lines == null
                ? Text(l10n.deskSetLndReading, style: ts.small.copyWith(color: c.dim))
                : SingleChildScrollView(
                    controller: _scroll,
                    child: SelectableText.rich(
                      TextSpan(
                        style: ts.mono(size: 12.u, color: c.dim),
                        children: [
                          for (final l in lines) ...[
                            () {
                              final m = stamp.firstMatch(l);
                              final level = l.contains(' ERROR ')
                                  ? c.risk
                                  : l.contains(' WARN ')
                                  ? c.warn
                                  : c.dim;
                              if (m == null) return TextSpan(text: l, style: TextStyle(color: level));
                              return TextSpan(
                                children: [
                                  TextSpan(text: '${m[1]} ', style: TextStyle(color: c.text)),
                                  TextSpan(text: m[2], style: TextStyle(color: level)),
                                ],
                              );
                            }(),
                            const TextSpan(text: '\n'),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
          SizedBox(height: Sp.x2),
          Text(l10n.deskSetLndLogNote, style: ts.caption),
        ],
      ),
      actions: [
        EButton(
          label: l10n.deskSetBackupOpenFolder,
          onPressed: _path == null
              ? null
              : () async {
                  final p = _path!;
                  final dir = p.substring(0, p.lastIndexOf(RegExp(r'[\\/]')).clamp(0, p.length));
                  final ok = await ref.read(deskOpenFolderProvider)(dir);
                  if (!ok && context.mounted) showEToast(context, l10n.deskSetLnodeFolderNotOpened, text: dir, tone: ETone.warn);
                },
        ),
        EButton(
          label: l10n.commonCopy,
          onPressed: lines == null
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: lines.join('\n')));
                  if (context.mounted) showEToast(context, l10n.deskSetLndCopied, text: l10n.deskSetLndLines(lines.length), tone: ETone.ok);
                },
        ),
        EButton(label: l10n.commonClose, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}

/// A folder is picked, its move is planned; the user chooses Move or Start fresh there.
/// Returns (folder, how) or null.
Future<(String, FolderChange)?> showChangeFolderDialog(BuildContext context, DeskNodeApi api, LocalNodeState s, {Future<String?> Function()? pick}) async {
  final choose = pick ?? deskPickFolder;
  while (true) {
    final folder = await choose();
    if (folder == null || folder.isEmpty || !context.mounted) return null;
    final plan = await api.planMove(folder);
    if (!context.mounted) return null;
    if (plan.problems.isNotEmpty) {
      final again = await showEDialog<bool>(
        context,
        builder: (context) => EDialog(
          title: context.l10n.deskSetLndBadFolder,
          icon: EIcons.alert,
          tone: ETone.risk,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final p in plan.problems) Text(moveProblemText(context.l10n, p, plan), style: context.ts.small.copyWith(color: context.dc.risk))],
          ),
          actions: [
            EButton(label: context.l10n.commonCancel, onPressed: () => Navigator.of(context).pop(false)),
            EButton.primary(label: context.l10n.deskSetLndChooseAnother, onPressed: () => Navigator.of(context).pop(true)),
          ],
        ),
      );
      if (again != true) return null;
      continue;
    }
    final how = await showEDialog<FolderChange>(
      context,
      builder: (context) => EDialog(
        title: context.l10n.deskSetLndMoveTitle(bytesText(s.chainDataBytes ?? plan.bytesNeeded, context.l10n), folder),
        icon: EIcons.folder,
        description: context.l10n.deskSetLndMoveDesc,
        actions: [
          EButton(label: context.l10n.deskSetLndStartFresh, onPressed: () => Navigator.of(context).pop(FolderChange.point)),
          EButton.primary(label: context.l10n.deskSetLndMove, onPressed: () => Navigator.of(context).pop(FolderChange.move)),
        ],
      ),
    );
    return how == null ? null : (folder, how);
  }
}

String moveProblemText(AppLocalizations l, MoveProblem p, MovePlan plan) => switch (p) {
  MoveProblem.targetNotEmpty => l.deskSetLndProbNotEmpty,
  MoveProblem.targetInsideSource => l.deskSetLndProbInsideSource,
  MoveProblem.sourceInsideTarget => l.deskSetLndProbSourceInside,
  MoveProblem.notEnoughSpace =>
    plan.freeOnTarget == null ? l.deskSetLndProbSpaceUnknown(bytesText(plan.bytesNeeded, l)) : l.deskSetLndProbSpace(bytesText(plan.bytesNeeded, l), bytesText(plan.freeOnTarget!, l)),
  MoveProblem.sourceLocked => l.deskSetLndProbLocked,
  MoveProblem.sourceMissing => l.deskSetLndProbMissing,
  MoveProblem.targetNotWritable => l.deskSetLndProbNotWritable,
  MoveProblem.layoutIncomplete => l.deskSetLndProbIncomplete,
  MoveProblem.targetForeign => l.deskSetLndProbForeign,
};

/// The OS directory picker (the app sets it; tests and the tour pass [pick]).
Future<String?> Function() deskPickFolder = () async => null;
