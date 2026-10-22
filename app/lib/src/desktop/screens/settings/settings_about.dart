import '../../../app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shell.dart' show deskVersion;
import '../../data/desk_update.dart';
import '../../data/files.dart' show deskOpenUrlProvider;
import '../../widgets/kit.dart';
import 'settings_frame.dart';

/// The Epic Cash community links (D-11: the public Telegram group).
const telegramUrl = 'https://t.me/EpicCash';
const websiteUrl = 'https://epiccash.com';

class SettingsAboutScreen extends ConsumerStatefulWidget {
  const SettingsAboutScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsAboutScreen> createState() => _SettingsAboutScreenState();
}

class _SettingsAboutScreenState extends ConsumerState<SettingsAboutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(deskUpdateProvider.notifier).checkOnce();
    });
  }

  Future<void> _open(String url) async {
    if (!await ref.read(deskOpenUrlProvider)(url) && mounted) showEToast(context, 'Browser not opened', text: url, tone: ETone.warn);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final network = ref.watch(deskProvider.select((s) => s.account?.network));
    final node = ref.watch(deskProvider.select((s) => s.status?.node.version));
    Widget linkRow(String title, String shown, String url) => ESetRow(
      title: title,
      control: EButton(label: 'Open', icon: EIcons.external, size: EBtnSize.sm, onPressed: () => _open(url)),
      below: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(shown, style: ts.mono(size: Fs.sm, color: c.faint), overflow: TextOverflow.ellipsis)),
          SizedBox(width: Sp.x1),
          LinkCopyButton(url: url),
        ],
      ),
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
                          Text('$appName $deskVersion', style: ts.h3),
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
            ],
          ),
          ESetGroup(
            title: 'Community',
            rows: [
              linkRow('Telegram', 't.me/EpicCash', telegramUrl),
              linkRow('epiccash.com', 'epiccash.com', websiteUrl),
            ],
          ),
          const _Updates(),
          ESetGroup(
            title: 'Credits',
            rows: [
              ESetRow(
                title: 'Epic Wallet by BT Labs',
                text: 'Built on open-source software, including Flutter, the Epic Cash wallet and node code, and Tor.',
              ),
              ESetRow(
                title: 'Licences',
                text: 'The licence of each component.',
                control: EButton(
                  label: 'View',
                  size: EBtnSize.sm,
                  onPressed: () => showLicensePage(context: context, applicationName: appName, applicationVersion: deskAppVersion),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "0.1.0 is the latest · checked 5 min ago", "Update available: 0.1.1", or "Could not check"
/// with the reason; Check now.
class _Updates extends ConsumerWidget {
  const _Updates();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(deskUpdateProvider);
    final now = ref.read(deskUpdateClockProvider)();
    final checked = u.checkedAt == null ? null : 'Checked ${_ago(now.difference(u.checkedAt!))}.';
    final (title, text) = switch (u.phase) {
      DeskUpdatePhase.idle || DeskUpdatePhase.checking => ('Checking for updates…', checked),
      DeskUpdatePhase.latest => ('$deskAppVersion is the latest', checked),
      DeskUpdatePhase.available => ('Update available: ${u.version}', checked),
      DeskUpdatePhase.failed => ('Could not check', [u.reason, checked].nonNulls.join(' ')),
    };
    final busy = u.phase == DeskUpdatePhase.checking || u.phase == DeskUpdatePhase.idle;
    return ESetGroup(
      title: 'Updates',
      rows: [
        ESetRow(
          title: title,
          text: text,
          control: Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              if (u.phase == DeskUpdatePhase.available && u.page != null)
                EButton.primary(
                  label: 'Get ${u.version}',
                  icon: EIcons.external,
                  size: EBtnSize.sm,
                  onPressed: () async {
                    if (!await ref.read(deskOpenUrlProvider)(u.page!) && context.mounted) {
                      showEToast(context, 'Browser not opened', text: u.page, tone: ETone.warn);
                    }
                  },
                ),
              EButton(
                label: 'Check now',
                icon: EIcons.refresh,
                size: EBtnSize.sm,
                busy: busy,
                onPressed: busy ? null : () => ref.read(deskUpdateProvider.notifier).check(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _ago(Duration d) {
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

/// The small copy icon beside a link, with Copied (or Not copied) in place for a moment.
class LinkCopyButton extends StatefulWidget {
  const LinkCopyButton({super.key, required this.url});

  final String url;

  @override
  State<LinkCopyButton> createState() => _LinkCopyButtonState();
}

class _LinkCopyButtonState extends State<LinkCopyButton> {
  bool? _copied;

  Future<void> _copy() async {
    final ok = await copyLink(widget.url);
    if (!mounted) return;
    setState(() => _copied = ok);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _copied = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final (icon, label, color) = switch (_copied) {
      null => (EIcons.copy, 'Copy link', null),
      true => (EIcons.check, 'Copied', c.ok),
      false => (EIcons.alert, 'Not copied', c.risk),
    };
    return Semantics(liveRegion: true, child: EIconButton(icon: icon, label: label, color: color, onPressed: _copy));
  }
}
