// SPDX-License-Identifier: Apache-2.0
import '../../../ui/network_mode_text.dart' show blockMode, browserOffNote, networkModeName;
import '../../../network_gate.dart' show NetDial, NetGate;
import '../../../app_info.dart';
import '../../../dist_build.dart' show distStore;
import '../../../l10n.dart' show localInt;
import '../../../tor_build.dart' show inAppUpdates;
import '../../../tor_licence.dart' show TorSourceNote;
import '../../../ui/settings_screen.dart' show epicCashUrl, privacyPolicyUrl, projectRepoUrl;
import '../../../ui/theme/fonts.dart' show flagsLicenceNote, sasPicturesLicenceNote;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/desk_update.dart';
import '../../data/desk_update_apply.dart' show deskUpdateApplierProvider;
import '../../data/files.dart' show deskOpenUrlProvider;
import '../../data/net_mode_view.dart';
import '../../app/update_notice.dart' show deskUpdateAct, deskUpdateActLabel;
import '../../../network_gate.dart' show NetBlock;
import '../../desk_l10n.dart';
import '../../../ui/theme/brand.dart' show BrandVariant, BrandWordmark;
import '../../widgets/kit.dart';
import '../../app/title_bar.dart' show copyBuildInfo;
import 'licence_texts_dialog.dart';
import 'setting_ids.dart';
import 'settings_frame.dart';

/// The website, from `app-config.toml` (`links.website`); null when left out (the
/// row is not shown).
String? get websiteUrl => epicCashUrl;

/// The Licences group, the same words as the phone's Licences screen (lib/l10n, `licences*`).
List<String> licenceLines(AppLocalizations l) => [
  l.deskSetAboutLicenceApp,
  l.licencesFlutter,
  l.licencesLepic,
  if (DeskFeatures.tor) l.licencesTor,
  l.licencesFonts,
  flagsLicenceNote,
  sasPicturesLicenceNote,
];

/// Start states of About for the screenshots.
enum AboutShot { licencesOpen }

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
      // A store build has no in-app updates: nothing asks for the feed.
      if (mounted && inAppUpdates) ref.read(deskUpdateProvider.notifier).checkOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final node = ref.watch(deskProvider.select((s) => s.status?.node.version));
    final l = context.l10n;
    return SettingsFrame(
      route: DeskRoute.settingsAbout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The app first, then its updates as one row of the same card (the owner: "first About,
          // then Updates", and compact); the links and licences follow.
          ESetGroup(
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
                          // Two columns, as the other Settings pages lay out label and value (LD-004).
                          _Facts(rows: [
                            (l.deskSetAboutVersionLabel, versionLine(deskAppVersion), l.deskSetAboutVersion(versionLine(deskAppVersion))),
                            (l.deskSetAboutNodeLabel, node ?? '-', l.deskSetAboutNode(node ?? '-')),
                          ]),
                          // A store build: the store updates it, there is no Updates group.
                          if (distStore != null) ...[
                            SizedBox(height: Sp.x2),
                            Text(l.settingsUpdatesFrom(distStore!), key: const ValueKey('about-updates-from'), style: ts.small),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: Sp.x4),
                    // What the sidebar's version line copied (item 7).
                    EButton(
                      key: const ValueKey('about-copy-build'),
                      label: l.deskBarCopyBuild,
                      icon: EIcons.copy,
                      size: EBtnSize.sm,
                      onPressed: () => unawaited(copyBuildInfo()),
                    ),
                  ],
                ),
              ),
              if (deskUpdatesSupported) const SetAnchor(id: SetId.updates, child: _Updates()),
            ],
          ),
          // Folded (item 5): the heading and one line; open, one line per component with its
          // licence, the bundled tor's source note (its GPL asks for it) and the full texts.
          ESetGroup(rows: [_LicencesFold(open: widget.arg == AboutShot.licencesOpen)]),
          // The phone's rows in its order (GP2-020): the website, the source and the privacy policy.
          ESetGroup(
            rows: [
              if (websiteUrl case final w?) _LinkRow(anchor: SetId.website, title: shownUrl(w), shown: w, url: w),
              if (projectRepoUrl case final r?) _LinkRow(anchor: SetId.source, title: l.deskSetAboutSource, shown: shownUrl(r), url: r),
              if (privacyPolicyUrl case final url?) _LinkRow(anchor: SetId.privacyPolicy, title: l.settingsPrivacyPolicy, shown: shownUrl(url), url: url),
            ],
          ),
        ],
      ),
    );
  }
}

/// Licences, folded: the heading and one line, with the ⇕ glyph; open, every component's
/// licence, the Tor source note and All licence texts.
class _LicencesFold extends StatefulWidget {
  const _LicencesFold({this.open = false});

  final bool open;

  @override
  State<_LicencesFold> createState() => _LicencesFoldState();
}

class _LicencesFoldState extends State<_LicencesFold> {
  late bool _open = widget.open;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    final head = Semantics(
      button: true,
      expanded: _open,
      label: l.deskSetAboutLicences,
      hint: l.deskSetAboutLicencesLead,
      excludeSemantics: true,
      child: EInkWell(
        key: const ValueKey('about-licences-fold'),
        onTap: () => setState(() => _open = !_open),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 56.u),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.deskSetAboutLicences, style: ts.strong),
                      const SizedBox(height: 2),
                      Text(l.deskSetAboutLicencesLead, style: ts.small),
                    ],
                  ),
                ),
                SizedBox(width: Sp.x3),
                Icon(_open ? EIcons.unfoldLess : EIcons.unfoldMore, size: Ctl.icon, color: c.dim),
              ],
            ),
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        head,
        if (_open) ...[
          Divider(height: 1, thickness: 1, color: c.line),
          Padding(
            key: const ValueKey('about-licences'),
            padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in licenceLines(l)) Padding(padding: EdgeInsets.only(bottom: Sp.x2), child: Text(line, style: ts.body)),
                if (DeskFeatures.tor) ...[SizedBox(height: Sp.x2), TorSourceNote(style: ts.caption)],
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: c.line),
          ESetRow(
            title: l.licencesFull,
            control: ERowControl(
              child: EButton(label: l.deskSetAboutView, size: EBtnSize.sm, onPressed: () => showLicenceTextsDialog(context)),
            ),
          ),
        ],
      ],
    );
  }
}

/// A link: its title, Open (the browser), and the address under it with a copy button.
class _LinkRow extends ConsumerWidget {
  const _LinkRow({required this.anchor, required this.title, required this.shown, required this.url});

  final String anchor;
  final String title;
  final String shown;
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final l = context.l10n;
    Future<void> open() async {
      // The mode keeps the browser shut: say so, with the address to copy.
      if (!NetGate.allows(NetDial.browser, '')) {
        showEToast(context, browserOffNote(l), text: url, tone: ETone.warn);
        return;
      }
      if (!await ref.read(deskOpenUrlProvider)(url) && context.mounted) showEToast(context, l.deskSetAboutBrowserNotOpened, text: url, tone: ETone.warn);
    }

    return ESetRow(
      anchor: anchor,
      title: title,
      control: ERowControl(child: EButton(label: l.deskSetAboutOpen, icon: EIcons.external, size: EBtnSize.sm, onPressed: open)),
      below: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(shown, style: context.ts.mono(size: Fs.sm, color: c.faint), overflow: TextOverflow.ellipsis)),
          SizedBox(width: Sp.x1),
          LinkCopyButton(url: url),
        ],
      ),
    );
  }
}

/// The About card's Updates row: the label, one status line ("26.10.24 is the latest Checked
/// 5 min ago." / "Could not check" with the reason / "Update available: 26.11.0") with the
/// download page as a link at its end, and a small Check button. While an update is offered,
/// the button for its next step joins it, the same steps as the sidebar's slot
/// (`app/update_notice.dart`): Download and install, Restart to update, Try again, or the
/// download page where this copy cannot install it by itself.
class _Updates extends ConsumerWidget {
  const _Updates();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(deskUpdateProvider);
    final now = ref.read(deskUpdateClockProvider)();
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    final v = u.version ?? '';
    final checked = u.checkedAt == null ? null : l.deskSetAboutChecked(_ago(l, now.difference(u.checkedAt!)));
    // Where this copy cannot install the update, it says so: every step opens the page.
    final manual = u.file == null ? l.deskUpdManual : null;
    final byHand = ref.read(deskUpdateApplierProvider)?.byHand ?? false;
    final (state, detail) = switch (u.phase) {
      DeskUpdatePhase.idle || DeskUpdatePhase.checking => (l.updateChecking, null),
      DeskUpdatePhase.latest => (l.deskSetAboutLatest(deskAppVersion), checked),
      DeskUpdatePhase.failed => (l.deskSetAboutCouldNotCheck, [u.reason, checked].nonNulls.join(' ')),
      DeskUpdatePhase.downloading => (l.deskSetAboutAvailable(v), l.deskUpdDownloading(localInt(l, ((u.progress ?? 0) * 100).floor()))),
      DeskUpdatePhase.ready when u.problem == null => (l.deskUpdReady(v), byHand ? l.deskUpdDmgHint : l.deskUpdRestartHint),
      DeskUpdatePhase.ready => (l.deskUpdInstallFailed, u.problem),
      DeskUpdatePhase.unfinished => (l.deskUpdUnfinished, [u.problem, manual].nonNulls.join(' ')),
      _ when u.problem != null => (l.deskUpdFailed, [u.problem, manual].nonNulls.join(' ')),
      _ => (l.deskSetAboutAvailable(v), [manual, checked].nonNulls.join(' ')),
    };
    final busy = u.phase == DeskUpdatePhase.checking || u.phase == DeskUpdatePhase.idle;
    final block = ref.watch(deskNetBlockProvider);
    // Off by the network mode: says which mode, as the other blocked notes do.
    final blocked = block == NetBlock.none || u.offered
        ? null
        : blockMode(block) != null
        ? l.updatesOffMode(networkModeName(l, blockMode(block)!))
        : netBlockReason(l, block);
    final act = deskUpdateActLabel(l, u, byHand: byHand);
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
    // While an update is offered: the button for its step (it waits while the download runs).
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
    final page = deskReleasesUrl;
    Future<void> openPage() async {
      if (page == null) return;
      if (!await ref.read(deskOpenUrlProvider)(page) && context.mounted) showEToast(context, l.deskSetAboutBrowserNotOpened, text: page, tone: ETone.warn);
    }

    // The state stands out while something is offered or wrong; the rest stays dim.
    final stateStyle = u.offered || u.phase == DeskUpdatePhase.failed ? ts.small.copyWith(color: c.text) : ts.small;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x4),
      // The buttons beside the words while the words keep their room, else under them.
      child: EBesideOrUnder(
        top: true,
        words: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.deskSetAboutUpdates, style: ts.strong),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 560.u),
              child: Wrap(
                spacing: Sp.x2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(blocked ?? state, style: stateStyle),
                  if (blocked == null && detail != null && detail.isNotEmpty) Text(detail, style: ts.small),
                  if (page != null) ELink(label: l.deskSetAboutDownloadPage, onPressed: openPage),
                ],
              ),
            ),
          ],
        ),
        control: Padding(
          // Level with the label, as a row's control is.
          padding: EdgeInsets.only(top: 1.u),
          child: Wrap(spacing: Sp.x2, runSpacing: Sp.x2, children: [if (checks || step == null) check, ?step]),
        ),
      ),
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

/// Label / value rows: a muted label column as wide as its longest word, the values beside
/// it; each row reads as one sentence to a screen reader.
class _Facts extends StatelessWidget {
  const _Facts({required this.rows});

  /// (label, value, spoken).
  final List<(String, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        for (final (label, value, spoken) in rows)
          TableRow(
            children: [
              Semantics(
                label: spoken,
                excludeSemantics: true,
                child: Padding(padding: EdgeInsetsDirectional.only(end: Sp.x4, bottom: 2.u), child: Text(label, style: ts.small.copyWith(color: c.faint))),
              ),
              ExcludeSemantics(child: Text(value, style: ts.small.copyWith(color: c.text))),
            ],
          ),
      ],
    );
  }
}
