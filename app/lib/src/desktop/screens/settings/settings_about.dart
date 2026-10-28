// SPDX-License-Identifier: Apache-2.0
import '../../../app_info.dart';
import '../../../app_version.dart';
import '../../../dist_build.dart' show distStore;
import '../../../l10n.dart' show localInt;
import '../../../tor_build.dart' show inAppUpdates;
import '../../../tor_licence.dart' show torSourceNote;
import '../../../ui/settings_screen.dart' show projectRepoPublic, projectRepoUrl, supportEmail;
import '../../../ui/theme/fonts.dart' show flagsLicenceNote;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/desk_update.dart';
import '../../data/files.dart' show deskOpenUrlProvider;
import '../../data/net_mode_view.dart';
import '../../app/update_notice.dart' show deskUpdateAct, deskUpdateActLabel;
import '../../../network_gate.dart' show NetBlock;
import '../../desk_l10n.dart';
import '../../../ui/theme/brand.dart' show BrandVariant, BrandWordmark;
import '../../widgets/kit.dart';
import 'settings_frame.dart';

/// The Epic Cash community links (the public Telegram group).
const telegramUrl = 'https://t.me/EpicCash';
const websiteUrl = 'https://epiccash.com';

/// The Licences group, the same words as the phone's Licences screen (lib/l10n, `licences*`).
List<String> licenceLines(AppLocalizations l) => [
  l.deskSetAboutLicenceApp,
  l.licencesFlutter,
  l.licencesLepic,
  if (DeskFeatures.tor) l.licencesTor,
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
      // The build without Tor has no in-app updates: nothing asks update.json.
      if (mounted && inAppUpdates) ref.read(deskUpdateProvider.notifier).checkOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final node = ref.watch(deskProvider.select((s) => s.status?.node.version));
    final l = context.l10n;
    Widget linkRow(String title, String shown, String url) => _LinkRow(title: title, shown: shown, url: url);
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
                          // A store build: the store updates it, there is no Updates group.
                          if (distStore != null) ...[
                            SizedBox(height: Sp.x2),
                            Text(l.settingsUpdatesFrom(distStore!), key: const ValueKey('about-updates-from'), style: ts.small),
                          ],
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
              _LinkRow(title: l.contactLabel, shown: supportEmail, url: 'mailto:$supportEmail', copy: supportEmail),
            ],
          ),
          if (deskUpdatesSupported) const _Updates(),
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
                    if (DeskFeatures.tor) ...[SizedBox(height: Sp.x2), Text(torSourceNote, style: ts.caption)],
                  ],
                ),
              ),
              if (projectRepoPublic) linkRow(l.deskSetAboutSource, 'gitlab.com/epic-cash-bt/wallet-for-epic', projectRepoUrl),
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

/// A link: its title, Open (the browser), and the address under it with a copy button.
class _LinkRow extends ConsumerWidget {
  const _LinkRow({required this.title, required this.shown, required this.url, this.copy});

  final String title;
  final String shown;
  final String url;

  /// What the copy button puts on the clipboard, when it is not [url].
  final String? copy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final l = context.l10n;
    Future<void> open() async {
      if (!await ref.read(deskOpenUrlProvider)(url) && context.mounted) showEToast(context, l.deskSetAboutBrowserNotOpened, text: url, tone: ETone.warn);
    }

    return ESetRow(
      title: title,
      control: ERowControl(child: EButton(label: l.deskSetAboutOpen, icon: EIcons.external, size: EBtnSize.sm, onPressed: open)),
      below: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(shown, style: context.ts.mono(size: Fs.sm, color: c.faint), overflow: TextOverflow.ellipsis)),
          SizedBox(width: Sp.x1),
          LinkCopyButton(url: copy ?? url),
        ],
      ),
    );
  }
}

/// "0.1.0 is the latest · checked 5 min ago", or "Could not check" with the reason, and Check
/// now; while an update is offered, what it is at and the button for its next step, the same
/// steps as the sidebar's slot (`app/update_notice.dart`): Download and install, Restart to
/// update, Try again, or the download page where this copy cannot install it by itself. The
/// download page's address is always there, to open or copy.
class _Updates extends ConsumerWidget {
  const _Updates();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(deskUpdateProvider);
    final now = ref.read(deskUpdateClockProvider)();
    final l = context.l10n;
    final v = u.version ?? '';
    final checked = u.checkedAt == null ? null : l.deskSetAboutChecked(_ago(l, now.difference(u.checkedAt!)));
    // Where this copy cannot install the update, it says so: every step opens the page.
    final manual = u.file == null ? l.deskUpdManual : null;
    final (title, text) = switch (u.phase) {
      DeskUpdatePhase.idle || DeskUpdatePhase.checking => (l.updateChecking, checked),
      DeskUpdatePhase.latest => (l.deskSetAboutLatest(deskAppVersion), checked),
      DeskUpdatePhase.failed => (l.deskSetAboutCouldNotCheck, [u.reason, checked].nonNulls.join(' ')),
      DeskUpdatePhase.downloading => (l.deskSetAboutAvailable(v), l.deskUpdDownloading(localInt(l, ((u.progress ?? 0) * 100).floor()))),
      DeskUpdatePhase.ready when u.problem == null => (l.deskUpdReady(v), l.deskUpdRestartHint),
      DeskUpdatePhase.ready => (l.deskUpdInstallFailed, u.problem),
      DeskUpdatePhase.unfinished => (l.deskUpdUnfinished, [u.problem, manual].nonNulls.join(' ')),
      _ when u.problem != null => (l.deskUpdFailed, [u.problem, manual].nonNulls.join(' ')),
      _ => (l.deskSetAboutAvailable(v), [manual, checked].nonNulls.join(' ')),
    };
    final busy = u.phase == DeskUpdatePhase.checking || u.phase == DeskUpdatePhase.idle;
    final block = ref.watch(deskNetBlockProvider);
    final act = deskUpdateActLabel(l, u);
    // A check changes nothing while the update downloads, waits for its restart or for Try again.
    final checks = !(u.phase == DeskUpdatePhase.downloading ||
        u.phase == DeskUpdatePhase.unfinished ||
        (u.phase == DeskUpdatePhase.ready && u.problem == null));
    final check = EButton(
      label: l.deskSetAboutCheckNow,
      icon: EIcons.refresh,
      size: EBtnSize.sm,
      busy: busy,
      onPressed: busy || block != NetBlock.none ? null : () => ref.read(deskUpdateProvider.notifier).check(),
    );
    // While an update is offered: the button for its step (it waits while the download runs),
    // after Check now where a check still tells something.
    final step = u.offered
        ? EButton(
            key: const ValueKey('about-update-act'),
            label: act ?? l.deskUpdDownloadInstall,
            icon: act == l.deskUpdOpenPage ? EIcons.external : null,
            kind: EBtnKind.primary,
            size: EBtnSize.sm,
            busy: u.phase == DeskUpdatePhase.downloading,
            onPressed: act == null ? null : () => deskUpdateAct(context, ref),
          )
        : null;
    return ESetGroup(
      title: l.deskSetAboutUpdates,
      rows: [
        ESetRow(
          title: title,
          text: block == NetBlock.none || u.offered ? text : netBlockReason(l, block),
          wrap: step != null,
          control: step == null
              ? ERowControl(child: check)
              : Row(mainAxisSize: MainAxisSize.min, children: [if (checks) ...[check, SizedBox(width: Sp.x2)], step]),
        ),
        _LinkRow(title: l.deskSetAboutDownloadPage, shown: 'examples.btlabs.uk/epic-cash-wallets', url: deskReleasesUrl), // l10n-ok: an address
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
