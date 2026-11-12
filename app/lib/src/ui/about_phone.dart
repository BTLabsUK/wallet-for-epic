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
import '../trust_ids.dart';
import '../updater.dart';
import 'common.dart' show copyText;
import 'kit/kit_corner_marks.dart';
import 'kit/kit_group.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_row.dart';
import 'kit/kit_sheet.dart';
import 'kit/kit_support.dart' show kitId;
import 'kit/kit_tokens.dart';
import 'licences_screen.dart';
import 'notices.dart' show NoticeLevel, noticeProvider;
import 'net_block.dart';
import 'network_mode_text.dart' show blockMode, networkModeName;
import 'settings_sections.dart' show LinkTile, appVersionProvider, epicCashUrl, privacyPolicyUrl, projectRepoUrl, settingsLicencesKey;
import 'theme/brand.dart' show BrandVariant, BrandWordmark, EpicMark;
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
        const SizedBox(height: Kit.gutter),
        Center(
          child: KitCornerMarks(
            inset: 8,
            child: SizedBox(
              width: Kit.brandTile,
              height: Kit.brandTile,
              child: Center(child: EpicMark(size: Kit.brandTile * 0.6, color: t.accentText)),
            ),
          ),
        ),
        const SizedBox(height: Kit.gutter * 2),
        const Center(child: BrandWordmark(variant: BrandVariant.mobile, size: 24)),
        const SizedBox(height: Kit.gutter * 2),
        KitGroup(
          dividerInset: Kit.dividerInsetPlain,
          children: [
            KitRow(
              size: KitRowSize.settings,
              title: l.settingsVersion,
              value: version.hasValue ? version.value ?? l.commonUnknown : '…',
              // A store build: the store updates it, the app has no updater.
              subtitle: distStore == null ? null : l.settingsUpdatesFrom(distStore!),
            ),
            KitRow(size: KitRowSize.settings, title: l.phoneSettingsMadeBy, value: _madeBy),
            KitRow(size: KitRowSize.settings, title: l.phoneAboutProtocol, trailing: const Epic1Mark(fontSize: 16)),
            KitRow(size: KitRowSize.settings, title: l.phoneSettingsEngine, value: 'LEPIC'),
          ],
        ),
        const SizedBox(height: Kit.groupGap),
        KitGroup(
          dividerInset: Kit.dividerInsetPlain,
          children: [
            if (notes != null || releases != null)
              KitRow(
                size: KitRowSize.settings,
                title: l.phoneAboutWhatsNew,
                // Notes open in a sheet; the release page is copied, as every link here.
                chevron: notes != null,
                trailing: notes != null ? null : Icon(KitIcons.external, size: 18, color: t.dim, semanticLabel: l.settingsCopyLink),
                semanticsId: TrustIds.aboutWhatsNew,
                onTap: () => notes != null
                    ? _showNotes(context, l.phoneAboutNotesTitle(installed ?? ''), notes)
                    : copyText(context, releases!, l.settingsLinkCopied),
              ),
            KitRow(
              key: settingsLicencesKey,
              size: KitRowSize.settings,
              title: l.settingsLicences,
              chevron: true,
              semanticsId: TrustIds.aboutLicences,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LicenceTextsScreen())),
            ),
            // The site's address as its name, the same in every language and on the desktop. The
            // app has no browser launcher: a tap copies the address.
            if (epicCashUrl case final site?) LinkTile(title: shownUrl(site), url: site, id: TrustIds.aboutSite),
          ],
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
