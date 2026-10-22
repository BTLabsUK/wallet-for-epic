import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shell.dart' show deskVersion;
import '../../widgets/kit.dart';
import 'settings_frame.dart';

const _github = 'https://github.com/EpicCash/epic-gui-wallet';
const _community = 'https://epiccash.com/';

class SettingsAboutScreen extends ConsumerWidget {
  const SettingsAboutScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final network = ref.watch(deskProvider.select((s) => s.account?.network));
    final node = ref.watch(deskProvider.select((s) => s.status?.node.version));
    Widget linkRow(String title, String host, String url, {String? text, IconData? icon}) => ESetRow(
      title: title,
      text: text,
      control: EButton(label: 'Copy link', icon: icon ?? EIcons.external, size: EBtnSize.sm, kind: EBtnKind.ghost, onPressed: () => copyLink(context, url)),
      below: Text(host, style: ts.mono(size: Fs.sm, color: c.faint)),
    );
    return SettingsFrame(
      route: DeskRoute.settingsAbout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ESetGroup(
            title: 'About',
            rows: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x4),
                child: Row(
                  children: [
                    EGlyphTile(size: 56.u),
                    SizedBox(width: Sp.x4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Epic Cash wallet $deskVersion', style: ts.h3),
                          SizedBox(height: Sp.x1),
                          Wrap(
                            spacing: Sp.x4,
                            children: [
                              Text('Network  ${network ?? '-'}', style: ts.small),
                              Text('Node  ${node ?? '-'}', style: ts.small),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              linkRow('Source code on GitHub', 'github.com/EpicCash/epic-gui-wallet', _github, icon: EIcons.github),
              linkRow('Epic Cash community', 'epiccash.com', _community, text: 'News about Epic Cash, questions and the community’s social media.'),
            ],
          ),
          const ESetGroup(
            title: 'Updates',
            rows: [ESetRow(title: 'Nothing to report yet', text: 'Messages about updates of the wallet show here.')],
          ),
          ESetGroup(
            title: 'Credits',
            rows: [
              ESetRow(
                title: 'Epic Wallet by BT Labs',
                text: 'Built on open-source software, including Flutter (BSD-3-Clause), the Epic Cash wallet and node code (Apache-2.0) and Tor (BSD-3-Clause).',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
