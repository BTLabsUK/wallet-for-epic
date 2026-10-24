/// Settings on the phone: a hub of seven groups that fits one screen, in the order people
/// reach for them. Security, Privacy & network, Wallet, Display and About open a page each
/// (`settings_sections.dart`); Notifications is its one switch, right on the hub; Help &
/// feedback opens Help, which starts with Send feedback. A group's row shows its state on a
/// second line ("btlabs.uk · epiccash.com · Tor off"), so the state is visible without opening
/// the page. No search: the hub is scanned at a glance, and Help has its own search for
/// questions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../demo.dart';
import '../errors.dart';
import '../l10n.dart';
import '../network.dart';
import '../phone_tor.dart';
import '../providers.dart';
import '../push.dart';
import '../push_controller.dart';
import '../push_registration.dart';
import '../server_switch.dart';
import '../settings.dart';
import '../tor_phone.dart';
import '../tor_routes.dart';
import '../updater.dart';
import '../wallet_service.dart';
import 'backup_screen.dart';
import 'common.dart';
import 'help_screen.dart';
import 'info_hint.dart';
import 'restore_screen.dart' show ScanSlotLine;
import 'settings_sections.dart';
import 'theme/tokens.dart';

export 'settings_sections.dart';

/// Opens Settings at Privacy & network, where the Tor switch is: the page over the hub, so
/// Back lands on the hub.
Future<void> openPrivacySettings(BuildContext context) => Navigator.of(context)
    .push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(privacy: true),
      ),
    );

/// The key of the push notifications switch, for tests.
const Key settingsPushKey = ValueKey('settings-push');

/// The Settings row that offers an update, for tests.
const Key settingsUpdateRowKey = ValueKey('settings-update-row');

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

  void _say(String message, {required NoticeLevel level}) {
    ref.read(noticeProvider.notifier).show(message, level: level);
  }

  /// On: one confirm, then the registration. Only the BT Labs relay can push, so a wallet on
  /// another relay is told so, and that its Epicbox address changes, and is moved there live
  /// first. Off never moves the relay back.
  Future<void> _setPushNotifications(bool on) async {
    final push = ref.read(pushControllerProvider.notifier);
    if (!on) return push.turnOff();
    final l = context.l10n;
    final config = ref.read(walletConfigProvider);
    final moveRelay =
        config != null && config.epicboxDomain != PushRegistration.relayHost;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.pushConfirmTitle),
        content: moveRelay
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.pushConfirmRelayBody),
                  const SizedBox(height: 12),
                  Text(l.pushConfirmRelayAddress),
                ],
              )
            : Text(l.pushConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.pushConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (moveRelay) {
      try {
        await switchServersLive(
          ref,
          nodeUrl: config.nodeUrl,
          nodeApiSecret: config.nodeApiSecret,
          relay: const EpicboxRelay(host: PushRegistration.relayHost),
        );
      } on WalletError catch (e) {
        logWarn('push', 'relay switch refused: ${e.kind.name}');
        if (mounted) _say(l.pushRelaySwitchFailed, level: NoticeLevel.error);
        return;
      }
      if (!mounted) return;
    }
    await push.turnOn();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final scan = ref.watch(scanProvider);
    final walletOpen = ref.watch(sessionProvider) != null;
    final demo = ref.watch(demoModeProvider);
    final updates = !demo && ref.read(updateProvider.notifier).supported;
    final torState = phoneTorState(ref.watch(phoneTorProvider));
    final backedUp = ref.watch(backedUpProvider).value ?? true;
    final push = ref.watch(pushProvider);
    final pushOffered =
        !demo && (ref.watch(pushConfiguredProvider).value ?? false);
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
                if (updates) const _UpdateRow(),
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
                        ? null
                        : backedUp
                        ? [l.backupTitle, l.pinLabel, l.settingsAutoLock].reduce(l.settingsStateJoin)
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
                if (pushOffered)
                  // Tor on pauses them (a registration would show this phone's address):
                  // turning them off still works, turning them on is not offered.
                  _GroupSwitch(
                    key: settingsPushKey,
                    icon: Icons.notifications_outlined,
                    title: l.settingsNotifications,
                    hint: l.settingsNotificationsHint,
                    state: pushStateLine(l, push, s, torState),
                    value: s.pushNotifications,
                    onChanged:
                        torWay(TorRoute.push, torState) == TorWay.off &&
                            !s.pushNotifications
                        ? null
                        : _setPushNotifications,
                  ),
                if (walletOpen)
                  _GroupRow(
                    key: settingsGroupKey(SettingsSection.wallet),
                    section: SettingsSection.wallet,
                    state: [
                      l.settingsContacts,
                      l.outputsTitle,
                      l.settingsSectionHistory,
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

/// The Notifications row's state line, only when there is a state to say: paused by Tor, or
/// why the switch went back off.
String? pushStateLine(
  AppLocalizations l,
  PushState push,
  AppSettings settings,
  TorState tor,
) {
  if (torWay(TorRoute.push, tor) == TorWay.off) {
    return settings.pushNotifications ? l.settingsPushPaused : null;
  }
  return push.blocked
      ? l.settingsPushBlocked
      : push.unavailable
      ? l.settingsPushUnavailable
      : null;
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

/// The hub's one inline setting, Notifications: the group's glyph and title with the
/// explanation behind an info icon, the state line, and the switch.
class _GroupSwitch extends StatelessWidget {
  const _GroupSwitch({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.state,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? state;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final state = this.state;
    return ListTile(
      minVerticalPadding: 12,
      leading: _GroupGlyph(icon),
      title: TitleWithHint(title, hint: hint, icon: icon),
      subtitle: state == null ? null : Text(state),
      trailing: Switch(value: value, onChanged: onChanged),
      enabled: onChanged != null,
      onTap: onChanged == null ? null : () => onChanged(!value),
    );
  }
}

/// The first row while an update is on offer: its version, with Install. While it downloads
/// or installs, the row says how far it got and Install waits.
class _UpdateRow extends ConsumerWidget {
  const _UpdateRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateProvider);
    final update = state.update;
    if (update == null) return const SizedBox.shrink();
    final l = context.l10n;
    final version = update.versionName;
    final busy =
        state.phase == UpdatePhase.downloading ||
        state.phase == UpdatePhase.installing;
    return ListTile(
      key: settingsUpdateRowKey,
      leading: Icon(Icons.system_update, color: context.tokens.accentText),
      title: Text(l.settingsUpdateTo(version)),
      subtitle: switch (state.phase) {
        UpdatePhase.downloading => Text(
          l.updateDownloading(version, ((state.progress ?? 0) * 100).floor()),
        ),
        UpdatePhase.installing => Text(l.updateInstalling(version)),
        UpdatePhase.needsPermission => Text(l.updateAllowInstalls),
        // Why the last try did not install, as the banner says it.
        _ => state.text == null ? null : Text(state.text!(l)),
      },
      trailing: FilledButton(
        onPressed: busy ? null : ref.read(updateProvider.notifier).install,
        child: Text(l.settingsUpdateInstall),
      ),
    );
  }
}
