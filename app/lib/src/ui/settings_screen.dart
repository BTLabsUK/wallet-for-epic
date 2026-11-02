// SPDX-License-Identifier: Apache-2.0
/// Settings on the phone: a hub of groups that fits one screen, in the order people reach for
/// them. Security, Network & privacy, Wallet, Transactions, Display, Advanced and About open a
/// page each (`settings_sections.dart`); Help & feedback opens Help, which starts with Send
/// feedback, and Donate the donation page. A hub row is its glyph and its name, never a second
/// line (item 3): a state belongs on the page. No search: the hub is scanned at a glance, and
/// Help has its own search for questions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo.dart';
import '../donate.dart' show donateLinkProvider;
import '../l10n.dart';
import '../errors.dart';
import '../providers.dart';
import '../devices/phone_devices.dart' show linkedDevicesOnProvider;
import 'backup_screen.dart';
import 'common.dart';
import 'devices/linked_devices_screen.dart' show LinkedDevicesScreen;
import 'donate_screen.dart';
import 'help_screen.dart';
import 'restore_screen.dart' show ScanSlotLine;
import 'settings_sections.dart';
import 'theme/tokens.dart';
import 'tip.dart';
import '../levels/level_providers.dart';

export 'settings_sections.dart';

/// Opens Settings at Network & privacy, where the Tor switch is: the page over the hub, so
/// Back lands on the hub.
Future<void> openPrivacySettings(BuildContext context) => Navigator.of(context)
    .push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(privacy: true),
      ),
    );

/// The Settings row that offers an update, for tests.

/// The key of a hub row, for tests: `settingsGroupKey(SettingsSection.x)`.
Key settingsGroupKey(SettingsSection section) =>
    ValueKey('settings-group-${section.name}');

/// The key of the hub's Help & feedback row, for tests.
const Key settingsHelpKey = ValueKey('settings-group-help');

/// The key of the hub's Donate row, for tests.
const Key settingsDonateKey = ValueKey('settings-group-donate');

/// The Settings hub. With [section] (or [privacy], the Network & privacy page), that page
/// opens over the hub on arrival.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.privacy = false, this.section});

  /// Opens the Network & privacy page at once.
  final bool privacy;

  /// The page to open at once.
  final SettingsSection? section;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    final section =
        widget.section ??
        (widget.privacy ? SettingsSection.privacyNetwork : null);
    if (section != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) openSettingsSection(context, section);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scan = ref.watch(scanProvider);
    final walletOpen = ref.watch(sessionProvider) != null;
    final demo = ref.watch(demoModeProvider);
    final backedUp = ref.watch(backedUpProvider).value ?? true;
    // Level 1 hides Network & privacy and Transactions.
    final features = ref.watch(levelFeaturesProvider);

    return SlotScaffold(
      idle: scan.running ? ScanSlotLine(scan: scan) : null,
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Builder(
              builder: (context) => ListView(
              padding: DockSlack.pad(context, const EdgeInsets.only(top: 4, bottom: 24)),
              children: [
                if (!scan.running && scan.error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ErrorText(describeError(l, scan.error!)),
                  ),
                if (walletOpen)
                  _GroupRow(
                    key: settingsGroupKey(SettingsSection.security),
                    section: SettingsSection.security,
                    // A warning mark, not a line, while the recovery phrase is not backed up.
                    warning: !demo && !backedUp ? l.settingsStateBackUp : null,
                  ),
                // The shared sections in the desktop's order (GP2-021): Transactions ·
                // Privacy · Appearance · This wallet; Security keeps its place first.
                if (walletOpen && features.transactionsSettings)
                  _GroupRow(
                    key: settingsGroupKey(SettingsSection.transactions),
                    section: SettingsSection.transactions,
                  ),
                if (features.serverSettings)
                _GroupRow(
                  key: settingsGroupKey(SettingsSection.privacyNetwork),
                  section: SettingsSection.privacyNetwork,
                ),
                _GroupRow(
                  key: settingsGroupKey(SettingsSection.display),
                  section: SettingsSection.display,
                ),
                if (walletOpen)
                  _GroupRow(
                    key: settingsGroupKey(SettingsSection.wallet),
                    section: SettingsSection.wallet,
                  ),
                // Every level, marked as an experiment (item 10), right after the wallet it
                // links.
                if (walletOpen && ref.watch(linkedDevicesOnProvider))
                  _GroupRow(
                    key: settingsLinkedDevicesKey,
                    icon: Icons.devices_outlined,
                    title: l.expLinkedDevices,
                    tag: l.settingsExperimentTag,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(builder: (_) => const LinkedDevicesScreen()),
                    ),
                  ),
                _GroupRow(
                  key: settingsHelpKey,
                  icon: Icons.help_outline,
                  title: l.settingsSectionHelpFeedback,
                  onTap: () => openHelp(context),
                ),
                // Directly under Help (item 4): the donation page, its fallback the address;
                // none without either in the settings files.
                if (ref.watch(donateLinkProvider).any)
                _GroupRow(
                  key: settingsDonateKey,
                  icon: Icons.volunteer_activism_outlined,
                  title: l.settingsDonate,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(builder: (_) => const DonateScreen()),
                  ),
                ),
                _GroupRow(
                  key: settingsGroupKey(SettingsSection.advanced),
                  section: SettingsSection.advanced,
                ),
                _GroupRow(
                  key: settingsGroupKey(SettingsSection.about),
                  section: SettingsSection.about,
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A group's glyph in a small hairline tile, so the hub reads as a short list of places
/// rather than a run of settings rows.
class _GroupGlyph extends StatelessWidget {
  const _GroupGlyph(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(t.radiusSmall),
      ),
      child: Icon(icon, size: 20, color: t.accentText),
    );
  }
}

/// A hub row: the group's glyph, its title and a chevron; one line, always (item 3: the
/// settings navigation never gets a second row, so the row has no place for one). With
/// [section] it opens that page; else [icon], [title] and [onTap] describe it. [warning] puts a
/// warning mark before the chevron, its text the mark's tooltip and spoken label; [tag] a
/// small badge after the title, on the same line (Linked devices' "Experiment").
class _GroupRow extends StatelessWidget {
  const _GroupRow({
    super.key,
    this.section,
    this.icon,
    this.title,
    this.onTap,
    this.warning,
    this.tag,
  }) : assert(section != null || (icon != null && title != null && onTap != null));

  final SettingsSection? section;
  final IconData? icon;
  final String? title;
  final VoidCallback? onTap;
  final String? warning;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final section = this.section;
    final warning = this.warning;
    return ListTile(
      minVerticalPadding: 12,
      leading: _GroupGlyph(section == null ? icon! : settingsSectionIcon(section)),
      title: Row(
        children: [
          Flexible(
            child: Text(
              section == null ? title! : settingsSectionTitle(l, section),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (tag case final tag?) ...[const SizedBox(width: 8), EBadge(tag)],
        ],
      ),
      trailing: warning == null
          ? const NavChevron()
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The glyph carries the same words as its label.
                Tip(
                  warning,
                  excludeFromSemantics: true,
                  child: Semantics(
                    label: warning,
                    child: Icon(Icons.error_outline, size: 20, color: context.tokens.warn),
                  ),
                ),
                const SizedBox(width: 4),
                const NavChevron(),
              ],
            ),
      onTap: section == null
          ? onTap
          : () => openSettingsSection(context, section),
    );
  }
}
