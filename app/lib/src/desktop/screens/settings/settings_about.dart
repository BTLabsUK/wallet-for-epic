import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'settings_frame.dart';

class SettingsAboutScreen extends ConsumerWidget {
  const SettingsAboutScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final st = ref.watch(deskProvider);
    Widget link(String label, String url, IconData icon) => EButton(
      label: label,
      icon: icon,
      size: EBtnSize.sm,
      onPressed: () => copyLink(context, url),
    );
    return SettingsFrame(
      route: DeskRoute.settingsAbout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const EGlyphTile(size: 56),
              const SizedBox(width: Sp.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wallet for Epic', style: ts.h2),
                    Text('Version 1.7.1', style: ts.mono(size: Fs.sm, color: c.dim)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.x6),
          ESetGroup(
            title: 'Credits',
            rows: [
              const ESetRow(title: 'Wallet by Johannes Hahn', text: 'Theme by BT Labs'),
              ESetRow(
                title: 'Links',
                stacked: true,
                control: Wrap(
                  spacing: Sp.x2,
                  runSpacing: Sp.x2,
                  children: [
                    link('Website', 'https://epiccash.com', EIcons.web),
                    link('Source on GitHub', 'https://github.com/EpicCash', EIcons.github),
                    link('Licences', 'https://epiccash.com/licenses', EIcons.file),
                  ],
                ),
              ),
            ],
          ),
          ESetGroup(
            title: 'Versions',
            rows: [
              ESetRow(
                title: 'Components',
                stacked: true,
                control: EFacts([
                  ('Wallet', Text('1.7.1', style: ts.mono(size: Fs.sm))),
                  ('Node', Text(st.status?.node.version ?? '-', style: ts.mono(size: Fs.sm))),
                  ('Network', Text(st.account?.network ?? '-', style: ts.mono(size: Fs.sm))),
                ], labelWidth: 100),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
