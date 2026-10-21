import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'combo.dart';
import 'dialogs.dart';
import 'settings_frame.dart';

/// Start states of Settings › Node.
enum NodeDemo { comboOpen }

String _host(String url) => url.replaceFirst(RegExp('^https?://'), '');

class SettingsNodeScreen extends ConsumerStatefulWidget {
  const SettingsNodeScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsNodeScreen> createState() => _SettingsNodeScreenState();
}

class _SettingsNodeScreenState extends ConsumerState<SettingsNodeScreen> {
  bool _checking = false;
  NodeServer? _checked;
  DateTime? _checkedAt;
  final Set<String> _removed = {};

  Future<void> _check(String url) async {
    setState(() => _checking = true);
    final r = await ref.read(deskApiProvider).checkNode(url);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _checked = r;
      _checkedAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(deskProvider);
    final notifier = ref.read(deskProvider.notifier);
    final nodes = st.nodes;
    final status = st.status;
    if (nodes == null || status == null) {
      return const SettingsFrame(route: DeskRoute.settingsNode, child: SettingsLoading());
    }
    final c = context.dc;
    final ts = context.ts;
    final mine = nodes.where((n) => n.own && !_removed.contains(n.url)).toList();
    final visible = nodes.where((n) => !_removed.contains(n.url)).toList();
    final current = status.node;
    final shown = _checked != null && _checked!.url == current.url ? _checked! : current;
    final options = [
      for (final n in visible.where((n) => !n.own))
        ComboOption(value: n.url, title: n.label, host: _host(n.url), health: n.health, latencyMs: n.latencyMs, group: 'Public nodes'),
      for (final n in mine)
        ComboOption(value: n.url, title: n.label, host: _host(n.url), health: n.health, latencyMs: n.latencyMs, group: 'My nodes'),
    ];
    return SettingsFrame(
      route: DeskRoute.settingsNode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ESetGroup(
            title: 'Node',
            rows: [
              ESetRow(
                title: 'Node server',
                text: 'The node the wallet reads the chain from.',
                stacked: true,
                control: ServiceCombo(
                  label: 'Node server',
                  options: options,
                  value: current.url,
                  openInitially: widget.arg == NodeDemo.comboOpen,
                  onChanged: (u) {
                    notifier.useNode(u);
                    setState(() => _checked = null);
                  },
                  footerActions: [
                    ('Add node…', EIcons.plus, () => showMyNodeDialog(context)),
                    ('Node directory…', EIcons.book, () => showNodeDirectoryDialog(context)),
                  ],
                ),
              ),
              ESetRow(
                title: 'Switch automatically',
                text: 'Use the next healthy node when this one stops answering.',
                control: ESwitch(
                  value: st.settings.nodeFailover,
                  onChanged: (v) => notifier.saveSettings(st.settings.copyWith(nodeFailover: v)),
                ),
              ),
            ],
          ),
          EPanel(
            title: 'Node status',
            headTrailing: EButton(
              label: 'Check now',
              icon: EIcons.refresh,
              size: EBtnSize.inline,
              busy: _checking,
              onPressed: () => _check(current.url),
            ),
            child: EFacts([
              ('Status', HealthLine(shown.health == ServiceHealth.ok ? status.nodeHealth : shown.health, latencyMs: shown.latencyMs)),
              ('Height', Text(status.nodeHeight.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ','), style: ts.mono(size: Fs.sm))),
              ('Version', Text(shown.version ?? '-', style: ts.mono(size: Fs.sm))),
              ('Answer time', Text(shown.latencyMs == null ? '-' : '${shown.latencyMs} ms', style: ts.mono(size: Fs.sm))),
              ('Last check', Text(ago(_checkedAt ?? status.lastUpdate), style: ts.small.copyWith(color: c.text))),
            ]),
          ),
          const SizedBox(height: Sp.x8),
          ESetGroup(
            title: 'My nodes',
            trailing: EButton(label: 'Add node…', icon: EIcons.plus, size: EBtnSize.inline, onPressed: () => showMyNodeDialog(context)),
            rows: mine.isEmpty
                ? [const ESetRow(title: 'No nodes of your own', text: 'Add a node by address to use it here.')]
                : [
                    for (final n in mine)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.label, style: ts.strong, overflow: TextOverflow.ellipsis),
                                  Text(_host(n.url), style: ts.mono(size: Fs.xs, color: c.faint), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const SizedBox(width: Sp.x3),
                            HealthLine(n.health, latencyMs: n.latencyMs),
                            EIconButton(icon: EIcons.pencil, label: 'Edit ${n.label}', onPressed: () => showMyNodeDialog(context, initial: n.url)),
                            EIconButton(
                              icon: EIcons.trash,
                              label: 'Remove ${n.label}',
                              onPressed: () {
                                setState(() => _removed.add(n.url));
                                showEToast(context, 'Node removed', text: n.label);
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
          ),
        ],
      ),
    );
  }
}
