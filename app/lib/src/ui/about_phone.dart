// SPDX-License-Identifier: Apache-2.0
/// The phone's About page body (Settings › About, and Help › About BT Wallet): the brand tile
/// and wordmark, the facts about this build, then What is new, Licences and the site, and last
/// the update check and the other links. The page frame is `SettingsPhonePage`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../address_format.dart' show shownUrl;
import '../dist_build.dart';
import '../network_gate.dart' show NetBlock;
import '../l10n.dart';
import '../settings_file/host_settings.dart' show hostSettings;
import '../tor_build.dart';
import '../tor_licence.dart';
import '../trust_ids.dart';
import '../updater.dart';
import 'common.dart' show copyText;
import 'kit/kit_brand_tile.dart';
import 'kit/kit_group.dart';
import 'kit/kit_row.dart';
import 'kit/kit_sheet.dart';
import 'kit/kit_support.dart' show kitId;
import 'kit/kit_tokens.dart';
import 'notices.dart' show NoticeLevel, noticeProvider;
import 'net_block.dart';
import 'network_mode_text.dart' show blockMode, networkModeName;
import 'settings_sections.dart' show LinkTile, appVersionProvider, epicCashUrl, privacyPolicyUrl, projectRepoUrl, settingsLicencesKey;
import 'theme/brand.dart' show BrandVariant, BrandWordmark;
import 'theme/epic1_mark.dart' show Epic1Mark;
import 'theme/tokens.dart';

/// The maker's name on the About page. A name, never translated.
const String _madeBy = 'BT Labs';

/// The release notes of the installed version, when the app has them: only an update found in
/// this run carries notes, so they show when that update is the version in use. Else null.
String? aboutNotes(UpdateState update, String? installed) {
  final found = update.update;
  if (found == null || installed == null || found.versionName != installed) return null;
  final notes = found.notes.trim();
  return notes.isEmpty ? null : notes;
}

/// The address "What is new" copies when the app has no notes: the release page it already
/// links, else none (the row is then left out).
String? aboutReleasesLink() => hostSettings.releasesPage;

class AboutPhoneBody extends ConsumerWidget {
  const AboutPhoneBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final version = ref.watch(appVersionProvider);
    final installed = version.hasValue ? version.value : null;
    final updates = ref.read(updateProvider.notifier).supported;
    final block = watchNetBlock(context, ref);
    final notes = aboutNotes(ref.watch(updateProvider), installed);
    final releases = aboutReleasesLink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The frame's `.tile.brk` at `margin-top: 36`; the tile's box carries 9 px of corner-mark
        // room on every side.
        const SizedBox(height: 7),
        const Center(child: KitBrandTile()),
        const SizedBox(height: 30 - 9),
        const Center(child: BrandWordmark(variant: BrandVariant.mobile, size: 24)),
        const SizedBox(height: 30),
        KitGroup(
          dividerInset: Kit.dividerInsetPlain,
          children: [
            _KvRow(
              title: l.settingsVersion,
              value: Text(version.hasValue ? version.value ?? l.commonUnknown : '…', textAlign: TextAlign.end, style: KitType.rowAmount.copyWith(color: t.text)),
              semanticsValue: version.hasValue ? version.value ?? l.commonUnknown : null,
              // A store build: the store updates it, the app has no updater.
              note: distStore == null ? null : l.settingsUpdatesFrom(distStore!),
            ),
            _KvRow(title: l.phoneSettingsMadeBy, value: Text(_madeBy, style: KitType.rowTitle.copyWith(fontWeight: FontWeight.w400, color: t.text)), semanticsValue: _madeBy),
            _KvRow(title: l.phoneAboutProtocol, value: const Epic1Mark(fontSize: 16), semanticsValue: 'epic1'),
            _KvRow(title: l.phoneSettingsEngine, value: Text('LEPIC', style: KitType.rowAmount.copyWith(color: t.text)), semanticsValue: 'LEPIC'),
          ],
        ),
        const SizedBox(height: 14),
        KitGroup(
          dividerInset: Kit.dividerInsetPlain,
          children: [
            if (notes != null || releases != null)
              KitRow(
                size: KitRowSize.settings,
                minHeight: 54,
                title: l.phoneAboutWhatsNew,
                // Notes open in a sheet; the release page is copied, as every link here. The frame
                // ends the row in a chevron either way.
                chevron: true,
                semanticsId: TrustIds.aboutWhatsNew,
                onTap: () => notes != null
                    ? _showNotes(context, l.phoneAboutNotesTitle(installed ?? ''), notes)
                    : copyText(context, releases!, l.settingsLinkCopied),
              ),
            // The full texts are a web page: the row is an external link, as the others here.
            if (hostSettings.linkLicences case final url?)
              LinkTile(key: settingsLicencesKey, title: l.settingsLicences, url: url, id: TrustIds.aboutLicences, minHeight: 54),
            // The site's address as its name, the same in every language and on the desktop. The
            // app has no browser launcher: a tap copies the address.
            if (epicCashUrl case final site?) LinkTile(title: shownUrl(site), url: site, id: TrustIds.aboutSite, minHeight: 54),
          ],
        ),
        // Tor's GPL notice and where its source is, readable offline (the packages' licence texts
        // ship as assets/licenses/third_party.txt).
        if (torBuilt)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TorSourceNote(style: KitType.rowSub.copyWith(fontSize: 12, color: t.faint)),
          ),
        if (updates || projectRepoUrl != null || privacyPolicyUrl != null) ...[
          const SizedBox(height: Kit.groupGap),
          KitGroup(
            dividerInset: Kit.dividerInsetPlain,
            children: [
              if (updates)
                KitRow(
                  size: KitRowSize.settings,
                  title: l.settingsCheckUpdates,
                  subtitle: block == NetBlock.none
                      ? null
                      : (blockMode(block) != null ? l.updatesOffMode(networkModeName(l, blockMode(block)!)) : netBlockReason(l, block)!),
                  subtitleLines: 2,
                  semanticsId: TrustIds.aboutUpdates,
                  onTap: block != NetBlock.none
                      ? null
                      : () {
                          ref.read(updateProvider.notifier).check();
                          // The result follows as a notice of its own.
                          ref.read(noticeProvider.notifier).show(l.updateChecking, level: NoticeLevel.info);
                        },
                ),
              if (projectRepoUrl != null) LinkTile(title: l.settingsSourceCode, url: projectRepoUrl!, id: TrustIds.aboutSource),
              if (privacyPolicyUrl case final url?) LinkTile(title: l.settingsPrivacyPolicy, url: url, id: TrustIds.aboutPrivacy),
            ],
          ),
        ],
      ],
    );
  }
}

/// A fact of this build: the dim name and its value at the end (`.kv`, 15, 13 px above and below).
class _KvRow extends StatelessWidget {
  const _KvRow({required this.title, required this.value, this.semanticsValue, this.note});

  final String title;
  final Widget value;
  final String? semanticsValue;

  /// A small faint line under the value (the store that updates this build).
  final String? note;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      container: true,
      label: semanticsValue == null ? title : '$title, $semanticsValue',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Text(title, style: KitType.rowTitle.copyWith(fontWeight: FontWeight.w400, color: t.dim)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                value,
                if (note != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(note!, textAlign: TextAlign.end, style: KitType.rowSub.copyWith(fontSize: 12, color: t.faint))),
              ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showNotes(BuildContext context, String title, String notes) => showKitSheet<void>(
  context: context,
  builder: (sheet) => KitSheet(
    title: title,
    primaryId: TrustIds.aboutNotesDone,
    primaryLabel: sheet.l10n.commonDone,
    onPrimary: () => Navigator.of(sheet).pop(),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: kitId(TrustIds.aboutNotesSheet, Text(notes, style: KitType.body.copyWith(color: sheet.tokens.text))),
    ),
  ),
);
