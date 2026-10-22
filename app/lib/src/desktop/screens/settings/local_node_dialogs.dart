/// The local node's dialogs (spec §19): the one-time fallback question (D-7), Delete chain
/// data with a typed confirm, Reuse existing chain data, the node log, Change folder.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/desk_node.dart';
import '../../data/files.dart' show deskOpenFolderProvider;
import '../../data/node_view.dart';
import '../../widgets/kit.dart';
import '../../widgets/server_row.dart';
import 'settings_node.dart' show serverRows, nodeListNote;

/// The local node's fallback was asked this session (the dialog shows once).
bool fallbackAskedThisSession = false;

/// The D-7 question: once, when the bundled node first syncs and nothing was answered yet.
/// [host] is the fallback's host. True = use it, false = wait, null = dismissed (asked again
/// later; the switch under While syncing answers it for good).
Future<bool?> showFallbackAskDialog(BuildContext context, {required String host}) => showEDialog<bool>(
  context,
  builder: (context) => EDialog(
    title: 'Use $host until the local node is synced?',
    icon: EIcons.server,
    description:
        'Syncing takes hours. Meanwhile the wallet can read the chain and send through $host, a public node. The local node takes over by itself once it is synced.',
    body: Text('Asked once. The node and the choice can be changed under Settings › Node › While syncing.', style: context.ts.caption),
    actions: [
      EButton.ghost(label: 'Wait for the local node', size: EBtnSize.md, onPressed: () => Navigator.of(context).pop(false)),
      EButton.primary(label: 'Use $host', onPressed: () => Navigator.of(context).pop(true)),
    ],
  ),
);

/// Shows the D-7 question when the decision asks for it, once per session, and saves the
/// answer. Call from a widget that watches [deskFallbackDecisionProvider].
Future<void> maybeAskFallback(BuildContext context, WidgetRef ref) async {
  final d = ref.read(deskFallbackDecisionProvider);
  if (d == null || d.action != FallbackAction.ask || fallbackAskedThisSession) return;
  fallbackAskedThisSession = true;
  final url = d.nodeUrl ?? defaultFallbackNodeUrl;
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
      final rows = serverRows(nodes.where((n) => !n.own).toList());
      return EDialog(
        title: 'Node while syncing',
        description: 'The public node the wallet uses until the local node is synced.',
        icon: EIcons.node,
        width: 560.u,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final r in rows) ServerRow(kind: ServerKind.node, info: r, selected: r.value == current, onTap: () => Navigator.of(context).pop(r.value)),
            SizedBox(height: Sp.x2),
            Text(nodeListNote, style: context.ts.caption),
          ],
        ),
        actions: [EButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop())],
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

  bool get _ok => _text.text.trim() == 'delete';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    setState(() => _busy = true);
    try {
      await widget.api.stop();
      final freed = await widget.api.deleteChainData();
      if (!mounted) return;
      Navigator.of(context).pop();
      showEToast(context, 'Chain data deleted', text: '${bytesText(freed)} freed');
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showEToast(context, 'Chain data not deleted', text: '$e', tone: ETone.risk);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    final s = widget.state;
    final size = s.chainDataBytes == null ? 'the chain data' : bytesText(s.chainDataBytes!);
    return EDialog(
      title: 'Delete chain data?',
      icon: EIcons.trash,
      tone: ETone.risk,
      description:
          'Removes $size from ${s.chainDataPath}. The node stops, and the whole chain downloads again on the next start (hours). Wallet keys and history are not touched.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Type '),
                TextSpan(text: 'delete', style: ts.mono(size: Fs.sm, color: c.text, weight: FontWeight.w600)),
                const TextSpan(text: ' to confirm.'),
              ],
            ),
            style: ts.small,
          ),
          SizedBox(height: Sp.x2),
          EInput(controller: _text, hint: 'delete', mono: true, autofocus: true, semanticLabel: 'Type delete to confirm', onChanged: (_) => setState(() {}), onSubmitted: (_) => _ok && !_busy ? _go() : null),
        ],
      ),
      actions: [
        EButton.ghost(label: 'Cancel', size: EBtnSize.md, onPressed: () => Navigator.of(context).pop()),
        EButton(label: 'Delete chain data', kind: EBtnKind.danger, busy: _busy, onPressed: _ok && !_busy ? _go : null),
      ],
    );
  }
}

/// Chain data found on this computer: one card per candidate, a last card to download fresh.
/// Returns true when a folder was taken into use.
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

  String _source(ChainDataInfo f) => switch (f.source) {
    ChainDataSource.cli => 'epic (the command-line node)',
    ChainDataSource.gui => 'Epic GUI',
    ChainDataSource.bundled => 'an earlier Epic Wallet',
    ChainDataSource.custom => 'another folder',
  };

  Future<void> _go() async {
    final pick = _pick;
    if (pick == null) return;
    if (pick.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    final f = _found!.firstWhere((f) => f.path == pick);
    setState(() => _busy = true);
    try {
      await widget.api.reuseChainData(f, ReuseMode.point);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showEToast(context, 'Chain data in use', text: f.path);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showEToast(context, 'The folder is not in use', text: '$e', tone: ETone.risk);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    final found = _found;
    return EDialog(
      title: 'Chain data found on this computer',
      icon: EIcons.folder,
      width: 640.u,
      description: 'Another Epic node left chain data here. The local node can read that folder instead of downloading the chain.',
      body: found == null
          ? SizedBox(height: 80.u, child: Center(child: Text('Looking…', style: ts.small.copyWith(color: c.dim))))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final f in found) ...[
                  _ReuseCard(
                    title: 'Use it',
                    path: f.path,
                    line: [bytesText(f.bytes), if (f.modified != null) 'last written ${_date(f.modified!)}', _source(f)].join(' · '),
                    sub: f.lock == FolderLock.locked ? 'In use by another program' : 'Nothing is copied: the node reads that folder, and Delete chain data is off for it.',
                    selected: _pick == f.path,
                    enabled: f.lock != FolderLock.locked,
                    onTap: () => setState(() => _pick = f.path),
                  ),
                  SizedBox(height: Sp.x2),
                ],
                _ReuseCard(
                  title: 'Download fresh',
                  line: 'Into the wallet’s own folder. About ${_facts == null ? '5 GB' : bytesText(_facts!.chainBytes)}.',
                  selected: _pick == '',
                  enabled: true,
                  onTap: () => setState(() => _pick = ''),
                ),
              ],
            ),
      actions: [
        EButton.ghost(label: 'Cancel', size: EBtnSize.md, onPressed: () => Navigator.of(context).pop()),
        EButton.primary(label: 'Continue', busy: _busy, onPressed: found == null || _pick == null || _busy ? null : _go),
      ],
    );
  }
}

String _date(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
        description: [line, ?sub].join('\n'),
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
    final lines = _lines;
    final stamp = RegExp(r'^(\d{8} \d\d:\d\d:\d\d(?:\.\d+)?)\s*(.*)$');
    return EDialog(
      title: 'Node log',
      icon: EIcons.log,
      width: 640.u,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 320.u,
            padding: EdgeInsets.all(Sp.x3),
            decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.line)),
            child: lines == null
                ? Text('Reading…', style: ts.small.copyWith(color: c.dim))
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
          Text('Last 200 lines of epic-server.log in the data folder. Newest at the bottom.', style: ts.caption),
        ],
      ),
      actions: [
        EButton.ghost(
          label: 'Open file',
          size: EBtnSize.md,
          onPressed: _path == null
              ? null
              : () async {
                  final p = _path!;
                  final dir = p.substring(0, p.lastIndexOf(RegExp(r'[\\/]')).clamp(0, p.length));
                  final ok = await ref.read(deskOpenFolderProvider)(dir);
                  if (!ok && context.mounted) showEToast(context, 'Folder not opened', text: dir);
                },
        ),
        EButton.ghost(
          label: 'Copy',
          size: EBtnSize.md,
          onPressed: lines == null
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: lines.join('\n')));
                  if (context.mounted) showEToast(context, 'Copied', text: '${lines.length} lines');
                },
        ),
        EButton.primary(label: 'Close', onPressed: () => Navigator.of(context).pop()),
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
          title: 'That folder does not work',
          icon: EIcons.alert,
          tone: ETone.risk,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final p in plan.problems) Text(moveProblemText(p, plan), style: context.ts.small.copyWith(color: context.dc.risk))],
          ),
          actions: [
            EButton.ghost(label: 'Cancel', size: EBtnSize.md, onPressed: () => Navigator.of(context).pop(false)),
            EButton.primary(label: 'Choose another', onPressed: () => Navigator.of(context).pop(true)),
          ],
        ),
      );
      if (again != true) return null;
      continue;
    }
    final how = await showEDialog<FolderChange>(
      context,
      builder: (context) => EDialog(
        title: 'Move ${bytesText(s.chainDataBytes ?? plan.bytesNeeded)} to $folder?',
        icon: EIcons.folder,
        description: 'The node stops while the data moves, then starts again from the new folder. Start fresh there downloads the chain again into it instead.',
        actions: [
          EButton.ghost(label: 'Start fresh there', size: EBtnSize.md, onPressed: () => Navigator.of(context).pop(FolderChange.point)),
          EButton.primary(label: 'Move', onPressed: () => Navigator.of(context).pop(FolderChange.move)),
        ],
      ),
    );
    return how == null ? null : (folder, how);
  }
}

String moveProblemText(MoveProblem p, MovePlan plan) => switch (p) {
  MoveProblem.targetNotEmpty => 'The folder is not empty.',
  MoveProblem.targetInsideSource => 'It is inside the current folder.',
  MoveProblem.sourceInsideTarget => 'The current folder is inside it.',
  MoveProblem.notEnoughSpace => 'Not enough space: ${bytesText(plan.bytesNeeded)} needed, ${plan.freeOnTarget == null ? 'unknown' : bytesText(plan.freeOnTarget!)} free.',
  MoveProblem.sourceLocked => 'Another program holds it.',
  MoveProblem.sourceMissing => 'The current chain data is missing.',
  MoveProblem.targetNotWritable => 'It cannot be written to.',
  MoveProblem.layoutIncomplete => 'The current chain data is incomplete.',
  MoveProblem.targetForeign => 'Another program’s chain data is there.',
};

/// The OS directory picker (the app sets it; tests and the tour pass [pick]).
Future<String?> Function() deskPickFolder = () async => null;
