/// Settings on the phone: a hub of groups that fits one screen, in the order people reach for
/// them. Security, Privacy & network, Wallet, Transactions, Display, Advanced and About open a
/// page each (`settings_sections.dart`); Help & feedback opens Help, which starts with Send
/// feedback. A group's row shows its state on a
/// second line ("btlabs.uk · epiccash.com · Tor off"), so the state is visible without opening
/// the page. No search: the hub is scanned at a glance, and Help has its own search for
/// questions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo.dart';
import '../l10n.dart';
import '../errors.dart';
import '../providers.dart';
import '../settings.dart';
import 'backup_screen.dart';
import 'common.dart';
import 'help_screen.dart';
import 'restore_screen.dart' show ScanSlotLine;
import 'settings_sections.dart';
import 'theme/advanced.dart';
import 'theme/tokens.dart';

export 'push_switch.dart' show settingsPushKey, pushStateLine;
export 'settings_sections.dart';

/// Opens Settings at Privacy & network, where the Tor switch is: the page over the hub, so
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

/// The Settings hub. With [section] (or [privacy], the Privacy & network page), that page
/// opens over the hub on arrival.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.privacy = false, this.section});

  /// Opens the Privacy & network page at once.
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
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final scan = ref.watch(scanProvider);
    final walletOpen = ref.watch(sessionProvider) != null;
    final demo = ref.watch(demoModeProvider);
    final backedUp = ref.watch(backedUpProvider).value ?? true;
    final t = context.tokens;


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
                    // The hub's second lines name what is inside, never live values
                    // (the owner, 26.10.11); Security warns instead while the recovery phrase
                    // is not backed up.
                    state: demo
                        // The demo's Security page holds none of these.
                        ? null
                        : backedUp
                        ? [
                            l.settingsHubBackup,
                            l.pinLabel,
                            l.pinBiometricsIconLabel,
                          ].reduce(l.settingsStateJoin)
                        : l.settingsStateBackUp,
                    stateColor: demo || backedUp ? null : t.warn,
                  ),
                _GroupRow(
                  key: settingsGroupKey(SettingsSection.privacyNetwork),
                  section: SettingsSection.privacyNetwork,
                  state: [
                    l.serverNodeTitle,
                    l.serverEpicboxTitle,
                    l.netStatusTor,
                  ].reduce(l.settingsStateJoin),
                ),
                if (walletOpen)
                  _GroupRow(
                    key: settingsGroupKey(SettingsSection.wallet),
                    section: SettingsSection.wallet,
                    // Outputs is named only while Advanced shows it.
                    state: [
                      l.settingsContacts,
                      if (s.advanced.has(AdvancedFeature.outputs)) l.outputsTitle,
                      l.settingsSectionHistory,
                    ].reduce(l.settingsStateJoin),
                  ),
                if (walletOpen)
                  _GroupRow(
                    key: settingsGroupKey(SettingsSection.transactions),
                    section: SettingsSection.transactions,
                    // What is inside, never live values; the send defaults only while
                    // Advanced › Send options shows them.
                    state: [
                      l.settingsHubMethods,
                      l.settingsHubDefault,
                      if (s.advanced.has(AdvancedFeature.sendOptions))
                        l.settingsHubSendDefaults,
                    ].reduce(l.settingsStateJoin),
                  ),
                _GroupRow(
                  key: settingsGroupKey(SettingsSection.display),
                  section: SettingsSection.display,
                  state: [
                    l.settingsTheme,
                    l.languageSetting,
                    l.settingsCurrency,
                  ].reduce(l.settingsStateJoin),
                ),
                _GroupRow(
                  key: settingsHelpKey,
                  icon: Icons.help_outline,
                  title: l.settingsSectionHelpFeedback,
                  onTap: () => openHelp(context),
                ),
                _GroupRow(
                  key: settingsGroupKey(SettingsSection.advanced),
                  section: SettingsSection.advanced,
                  state: advancedStateLine(l, s.advanced),
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

/// The Advanced row's state line: "Off", or what is on ("Outputs · Tor only").
String advancedStateLine(AppLocalizations l, AdvancedPrefs adv) {
  final parts = <String>[
    for (final f in AdvancedFeature.values)
      if (adv.has(f)) advancedFeatureName(l, f),
    if (adv.networkMode != NetworkMode.standard)
      networkModeName(l, adv.networkMode),
  ];
  return parts.isEmpty ? l.advStateOff : parts.reduce(l.settingsStateJoin);
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

/// A hub row: the group's glyph, its title, its state on a second line, a chevron. With
/// [section] it opens that page; else [icon], [title] and [onTap] describe it.
class _GroupRow extends StatelessWidget {
  const _GroupRow({
    super.key,
    this.section,
    this.icon,
    this.title,
    this.onTap,
    this.state,
    this.stateColor,
  }) : assert(section != null || (icon != null && title != null && onTap != null));

  final SettingsSection? section;
  final IconData? icon;
  final String? title;
  final VoidCallback? onTap;
  final String? state;
  final Color? stateColor;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final section = this.section;
    final state = this.state;
    return ListTile(
      minVerticalPadding: 12,
      leading: _GroupGlyph(section == null ? icon! : settingsSectionIcon(section)),
      title: Text(section == null ? title! : settingsSectionTitle(l, section)),
      subtitle: state == null
          ? null
          // Wraps rather than cuts: every part counts (node · Epicbox · Tor ends on Tor).
          : Text(
              state,
              style: stateColor == null ? null : TextStyle(color: stateColor),
            ),
      trailing: Icon(Icons.chevron_right, color: t.dim),
      onTap: section == null
          ? onTap
          : () => openSettingsSection(context, section),
    );
  }
}
