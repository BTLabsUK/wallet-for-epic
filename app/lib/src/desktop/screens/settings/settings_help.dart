import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'help_topics.dart';
import 'settings_frame.dart';

class SettingsHelpScreen extends ConsumerStatefulWidget {
  const SettingsHelpScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsHelpScreen> createState() => _SettingsHelpScreenState();
}

class _SettingsHelpScreenState extends ConsumerState<SettingsHelpScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final q = _query.text.trim().toLowerCase();
    final hits = [
      for (final t in helpTopics)
        if (q.isEmpty || '${t.title} ${t.short} ${t.body}'.toLowerCase().contains(q)) t,
    ];
    return SettingsFrame(
      route: DeskRoute.settingsHelp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EInput(
            controller: _query,
            hint: 'Search help: file, confirmations, phrase',
            leading: EIcons.search,
            semanticLabel: 'Search help',
            onChanged: (_) => setState(() {}),
            trailing: q.isEmpty
                ? null
                : EIconButton(icon: EIcons.close, label: 'Clear search', onPressed: () => setState(_query.clear)),
          ),
          const SizedBox(height: Sp.x5),
          if (hits.isEmpty)
            EEmpty(icon: EIcons.search, title: 'No topic matches', text: 'Nothing found for “${_query.text.trim()}”. Try another word.')
          else ...[
            if (q.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: Sp.x3), child: Text('Topics found: ${hits.length}', style: ts.small)),
            for (final (id, name) in helpSections)
              if (hits.any((t) => t.section == id)) ...[
                ESectionHead(name, top: Sp.x2),
                Container(
                  margin: const EdgeInsets.only(bottom: Sp.x6),
                  decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
                  child: Column(
                    children: [
                      for (final t in hits.where((t) => t.section == id))
                        _Topic(
                          key: ValueKey('${t.title}-$q'),
                          topic: t,
                          initiallyOpen: q.isNotEmpty && hits.length == 1,
                        ),
                    ],
                  ),
                ),
              ],
          ],
        ],
      ),
    );
  }
}

/// One expandable topic. Own widget: the kit's EDetails does not wrap long titles.
class _Topic extends StatefulWidget {
  const _Topic({super.key, required this.topic, this.initiallyOpen = false});

  final HelpTopic topic;
  final bool initiallyOpen;

  @override
  State<_Topic> createState() => _TopicState();
}

class _TopicState extends State<_Topic> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final t = widget.topic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Container(
              constraints: const BoxConstraints(minHeight: Ctl.md),
              padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x2),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _open ? 0.25 : 0,
                    duration: Dur.base,
                    child: Icon(EIcons.chevronRight, size: Ctl.icon, color: c.dim),
                  ),
                  const SizedBox(width: Sp.x2),
                  Expanded(child: Text(t.title, style: ts.strong)),
                ],
              ),
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.x4 + Ctl.icon + Sp.x2, 0, Sp.x4, Sp.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.short, style: ts.body),
                const SizedBox(height: Sp.x2),
                Text(t.body, style: ts.bodyDim),
              ],
            ),
          ),
      ],
    );
  }
}
