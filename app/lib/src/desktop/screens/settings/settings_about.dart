import '../../../app_info.dart';
import '../../../app_version.dart';
import '../../../tor_licence.dart' show torSourceNote;
import '../../../ui/settings_screen.dart' show projectRepoUrl;
import '../../../ui/theme/fonts.dart' show flagsLicenceNote;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/desk_update.dart';
import '../../data/files.dart' show deskOpenUrlProvider;
import '../../desk_l10n.dart';
import '../../../ui/theme/brand.dart' show BrandVariant, BrandWordmark;
import '../../widgets/kit.dart';
import 'settings_frame.dart';

/// The Epic Cash community links (D-11: the public Telegram group).
const telegramUrl = 'https://t.me/EpicCash';
const websiteUrl = 'https://epiccash.com';

/// The Licences group, the same words as the phone's Licences screen (lib/l10n, `licences*`).
List<String> licenceLines(AppLocalizations l) => [
  l.deskSetAboutLicenceApp,
  l.licencesFlutter,
  l.licencesLepic,
  l.licencesTor,
  l.licencesFonts,
  flagsLicenceNote,
];

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
    if (!await ref.read(deskOpenUrlProvider)(url) && mounted) showEToast(context, context.l10n.deskSetAboutBrowserNotOpened, text: url, tone: ETone.warn);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final node = ref.watch(deskProvider.select((s) => s.status?.node.version));
    final l = context.l10n;
    Widget linkRow(String title, String shown, String url) => ESetRow(
      title: title,
      control: ERowControl(child: EButton(label: l.deskSetAboutOpen, icon: EIcons.external, size: EBtnSize.sm, onPressed: () => _open(url))),
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
            title: l.deskSetFrameAbout,
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
                          BrandWordmark(variant: BrandVariant.desktop, size: Fs.h2.u),
                          SizedBox(height: Sp.x2),
                          // The version and the node; no network line (a release runs on one).
                          Wrap(
                            spacing: Sp.x4,
                            children: [
                              Text(l.deskSetAboutVersion(withBuildId(withCoreVersion(deskAppVersion))), style: ts.small),
                              Text(l.deskSetAboutNode(node ?? '-'), style: ts.small),
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
            title: l.deskSetAboutCommunity,
            rows: [
              linkRow('Telegram', 't.me/EpicCash', telegramUrl), // l10n-ok: a name
              linkRow('epiccash.com', 'epiccash.com', websiteUrl),
            ],
          ),
          const _Updates(),
          // A few sentences, not a catalogue: one line per component with its licence, the
          // bundled tor's source note (its GPL asks for it), and the full texts one click away.
          ESetGroup(
            title: l.deskSetAboutLicences,
            rows: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.deskSetAboutLicencesLead, style: ts.small),
                    SizedBox(height: Sp.x3),
                    for (final line in licenceLines(l)) Padding(padding: EdgeInsets.only(bottom: Sp.x2), child: Text(line, style: ts.body)),
                    SizedBox(height: Sp.x2),
                    Text(torSourceNote, style: ts.caption),
                  ],
                ),
              ),
              linkRow(l.deskSetAboutSource, 'github.com/BTLabs-EPIC/wallet-for-epic', projectRepoUrl),
              ESetRow(
                title: l.licencesFull,
                control: ERowControl(
                  child: EButton(
                    label: l.deskSetAboutView,
                    size: EBtnSize.sm,
                    onPressed: () => showLicensePage(context: context, applicationName: appName, applicationVersion: deskAppVersion),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "0.1.0 is the latest · checked 5 min ago", "Update available: 26.10.1", or "Could not check"
/// with the reason; Check now.
class _Updates extends ConsumerWidget {
  const _Updates();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(deskUpdateProvider);
    final now = ref.read(deskUpdateClockProvider)();
    final l = context.l10n;
    final checked = u.checkedAt == null ? null : l.deskSetAboutChecked(_ago(l, now.difference(u.checkedAt!)));
    final (title, text) = switch (u.phase) {
      DeskUpdatePhase.idle || DeskUpdatePhase.checking => (l.updateChecking, checked),
      DeskUpdatePhase.latest => (l.deskSetAboutLatest(deskAppVersion), checked),
      DeskUpdatePhase.available => (l.deskSetAboutAvailable(u.version ?? ''), checked),
      DeskUpdatePhase.failed => (l.deskSetAboutCouldNotCheck, [u.reason, checked].nonNulls.join(' ')),
    };
    final busy = u.phase == DeskUpdatePhase.checking || u.phase == DeskUpdatePhase.idle;
    return ESetGroup(
      title: l.deskSetAboutUpdates,
      rows: [
        // Two row buttons (an update to get): under the text when the card is narrow.
        LayoutBuilder(
          builder: (context, box) => ESetRow(
          title: title,
          text: text,
          stacked: u.phase == DeskUpdatePhase.available && u.page != null && box.maxWidth < 720.u,
          control: Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              if (u.phase == DeskUpdatePhase.available && u.page != null)
                ERowControl(
                  child: EButton.primary(
                    label: l.deskSetAboutGet(u.version ?? ''),
                    icon: EIcons.external,
                    size: EBtnSize.sm,
                    onPressed: () async {
                      if (!await ref.read(deskOpenUrlProvider)(u.page!) && context.mounted) {
                        showEToast(context, l.deskSetAboutBrowserNotOpened, text: u.page, tone: ETone.warn);
                      }
                    },
                  ),
                ),
              ERowControl(
                child: EButton(
                  label: l.deskSetAboutCheckNow,
                  icon: EIcons.refresh,
                  size: EBtnSize.sm,
                  busy: busy,
                  onPressed: busy ? null : () => ref.read(deskUpdateProvider.notifier).check(),
                ),
              ),
            ],
          ),
        ),
        ),
      ],
    );
  }
}

String _ago(AppLocalizations l, Duration d) {
  if (d.inMinutes < 1) return l.deskSetAboutAgoNow;
  if (d.inMinutes < 60) return l.deskSetAboutAgoMin(d.inMinutes);
  if (d.inHours < 24) return l.deskSetAboutAgoHours(d.inHours);
  return l.deskSetAboutAgoDays(d.inDays);
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
    final l = context.l10n;
    final (icon, label, color) = switch (_copied) {
      null => (EIcons.copy, l.deskSetAboutCopyLink, null),
      true => (EIcons.check, l.deskSetAboutCopied, c.ok),
      false => (EIcons.alert, l.deskSetAboutNotCopied, c.risk),
    };
    return Semantics(liveRegion: true, child: EIconButton(icon: icon, label: label, color: color, onPressed: _copy));
  }
}
