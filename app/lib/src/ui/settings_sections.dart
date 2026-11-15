// SPDX-License-Identifier: Apache-2.0
/// The phone's Settings pages, one per group of the hub (`settings_screen.dart`): Security,
/// Network & privacy, Wallet, Display and About. Each page is a short list of label-only rows
/// (an explanation sits behind an info icon, a value or a state on the row's second line), so
/// a page fits a 360 dp phone without a search. Help & feedback opens Help itself.
library;

import 'dart:async';

import 'address_view.dart' show HostText;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_info.dart';
import '../app_log.dart';
import '../announcements/announcements_service.dart' show announcementsOffered;
import '../settings_file/host_settings.dart' show hostSettings;
import '../dev_networks.dart';
import '../epic1.dart' show PaymentMode;
import '../l10n.dart';
import '../network.dart';
import '../network_gate.dart';
import '../payment_prefs.dart';
import '../phone_tor.dart';
import '../tor_pay.dart';
import '../tor_build.dart';
import '../price.dart';
import '../pairing_providers.dart' show invoicesShownProvider;
import '../providers.dart';
import '../restore_scan.dart' show restoreScanProvider;
import '../settings.dart';
import '../tor_phone.dart';
import '../tor_routes.dart';
import '../help/help_content.dart' show HelpId;
import '../trust_ids.dart';
import '../updater.dart';
import '../wallet_service.dart';
import 'about_phone.dart';
import 'app_dialog.dart';
import 'backup_screen.dart';
import 'common.dart';
import 'confirmations_row.dart';
import 'epic1/epic1_settings.dart';
import 'language_flag.dart';
import 'launch_screen.dart';
import 'network_menu.dart';
import 'network_mode_phone.dart';
import 'net_block.dart';
import 'payment_gate.dart' show pendingEpicboxSends;
import 'network_status.dart';
import 'home_parts.dart' show outputsShown;
import 'outputs_screen.dart';
import 'pin.dart';
import 'restore_screen.dart' show RestoreScreen;
import 'scan_start.dart';
import 'server_picker.dart' show showEpicboxPicker, showNodePicker;
import 'settings_history.dart';
import 'settings_invoices.dart';
import 'settings_pin.dart';
import 'kit/kit_group.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_row.dart';
import 'kit/kit_settings.dart';
import 'kit/kit_sheet.dart';
import 'kit/kit_tokens.dart';
import 'settings_phone.dart';
import 'status.dart' show serverHost;
import 'theme/advanced.dart';
import 'theme/tokens.dart';
import 'tor_ui.dart';
import 'tour/tour_target.dart';
import 'wallet_delete.dart';
import '../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../settings_file/status_site.dart' show statusSiteConfigured, statusSiteHost;

export 'wallet_delete.dart' show sharedFilesCleanupProvider;
export 'settings_rows.dart' show SettingsHeader, SettingsSubHeader, NavChevron, RadioRow;
export '../seed_contacts.dart' show projectRepoUrl;

/// BT Labs' privacy policy; null when `app-config.toml` leaves it out (no link).
String? get privacyPolicyUrl => hostSettings.linkPrivacy;

String? get epicCashUrl => hostSettings.linkWebsite;


/// The app version and the core's: the installed package's on Android, else the one this
/// build was made from (`pubspec.yaml`, passed in by `flutter build`), with the build's commit
/// when the release script passed one: `26.10.0 · core 0.1.0 (ba10dec)`. Null when neither is
/// known.
final appVersionProvider = FutureProvider<String?>((ref) async {
  final platform = ref.watch(updatePlatformProvider);
  if (platform != null) {
    try {
      final app = await platform.installedApp();
      return _withCore(app.versionName);
    } catch (error) {
      // Fall back to the build's own version.
      logInfo('app', 'installed version unknown: $error');
    }
  }
  const name = String.fromEnvironment('FLUTTER_BUILD_NAME');
  if (name.isEmpty) return null;
  return _withCore(name);
});

String _withCore(String name) => versionLine(name);

/// Whether this device offers biometric unlock, and whether the open wallet uses it.
final biometricsProvider =
    FutureProvider.autoDispose<({bool available, bool enabled})>((ref) async {
      final config = ref.watch(walletConfigProvider);
      final available = await ref.watch(biometricStoreProvider).isAvailable();
      final enabled =
          config != null &&
          await ref.watch(vaultProvider).biometricsEnabled(config.chain);
      return (available: available, enabled: enabled);
    });

/// The groups of the Settings hub that open a page of their own. Help & feedback opens Help,
/// so it is not here.
enum SettingsSection { security, privacyNetwork, wallet, transactions, display, advanced, about }

/// The group's title, on the hub's row and on its page's app bar.
String settingsSectionTitle(AppLocalizations l, SettingsSection section) =>
    switch (section) {
      SettingsSection.security => l.settingsSectionSecurity,
      SettingsSection.privacyNetwork => l.settingsSectionNetworkPrivacy,
      SettingsSection.wallet => l.settingsSectionWallet,
      SettingsSection.transactions => l.phoneSettingsPayments,
      SettingsSection.display => l.settingsSectionDisplay,
      SettingsSection.advanced => l.advTitle,
      SettingsSection.about => l.settingsSectionAbout,
    };

/// The group's glyph on the hub.
IconData settingsSectionIcon(SettingsSection section) => switch (section) {
  SettingsSection.security => KitIcons.security,
  SettingsSection.privacyNetwork => KitIcons.network,
  SettingsSection.wallet => KitIcons.wallet,
  SettingsSection.transactions => KitIcons.exchange,
  SettingsSection.display => KitIcons.tuning,
  SettingsSection.advanced => KitIcons.code,
  SettingsSection.about => KitIcons.info,
};

/// A feature's name as the Advanced page shows it (the hub's state line reuses it).
String advancedFeatureName(AppLocalizations l, AdvancedFeature f) => switch (f) {
  AdvancedFeature.outputs => l.advOutputs,
  AdvancedFeature.technicalDetails => l.advTechnical,
  AdvancedFeature.sendOptions => l.advSendOptions,
  AdvancedFeature.serverDetails => l.advServerDetails,
  AdvancedFeature.recheckFromHeight => l.advRecheckHeight,
  // Desktop only; never on a phone's list.
  AdvancedFeature.builtInNode => l.advBuiltInNode,
  AdvancedFeature.logs => l.advLogs,
  AdvancedFeature.transactionFiles => l.advTransactionFiles,
  AdvancedFeature.pairing => l.expPairing,
  AdvancedFeature.invoices => l.invoicesTitle,
  AdvancedFeature.linkedDevices => l.expLinkedDevices,
};

/// The key of the Servers header on the Network & privacy page, for tests.
const Key settingsServersKey = ValueKey('settings-servers');

/// The Epicbox and Node rows of Network & privacy, for tests: the status card's rows while a
/// wallet is open, the plain rows otherwise.
const Key settingsNodeKey = netStatusNodeKey;
const Key settingsEpicboxKey = netStatusEpicboxKey;

/// The key of the Node failover switch on the Network & privacy page, for tests.
const Key advNodeFailoverKey = ValueKey('adv-nodeFailover');

/// The key of the Licences row in About, for tests.
const Key settingsLicencesKey = ValueKey('settings-licences');

/// The key of a section page's scaffold, for tests: `settingsSectionKey(SettingsSection.x)`.
Key settingsSectionKey(SettingsSection section) =>
    ValueKey('settings-section-${section.name}');

/// Opens [section]'s page over the current route.
Future<void> openSettingsSection(BuildContext context, SettingsSection section, {bool toNetwork = false, String? backLabel}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsSectionScreen(section: section, toNetwork: toNetwork, backLabel: backLabel),
      ),
    );

/// One group's page: its rows under the group's title, with the actions they need.
class SettingsSectionScreen extends ConsumerStatefulWidget {
  const SettingsSectionScreen({super.key, required this.section, this.toNetwork = false, this.backLabel});

  final SettingsSection section;

  /// The back link's words when the page is not opened from the Settings hub (About from Help).
  final String? backLabel;

  /// Network & privacy opened from the mode mark or an Off (mode) status: scrolled to the
  /// Network section (its first group, so the page opens on it).
  final bool toNetwork;

  @override
  ConsumerState<SettingsSectionScreen> createState() =>
      _SettingsSectionScreenState();
}

class _SettingsSectionScreenState extends ConsumerState<SettingsSectionScreen> {
  bool _busy = false;
  final _scroll = ScrollController();
  final _networkKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.toNetwork) WidgetsBinding.instance.addPostFrameCallback((_) => _showNetwork());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The Network mode section sits under the servers; the list is built that far first.
  void _showNetwork([int tries = 0]) {
    if (!mounted || !_scroll.hasClients) return;
    final at = _networkKey.currentContext;
    if (at == null) {
      if (tries > 3) return;
      _scroll.jumpTo((_scroll.position.maxScrollExtent * (tries + 1) / 4).clamp(0, _scroll.position.maxScrollExtent));
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNetwork(tries + 1));
      return;
    }
    Scrollable.ensureVisible(at, alignment: 0);
  }

  /// Transactions rows shown once stay while the page is open: a setting never disappears
  /// because it was changed (Split change back on, Link · Tor off without Tor).
  bool _txDefaultsShown = false;
  bool _txTorShown = false;
  bool _txFileShown = false;

  void _say(String message, {required NoticeLevel level}) {
    ref.read(noticeProvider.notifier).show(message, level: level);
  }

  Future<void> _push(Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  AppSettingsNotifier get _settings => ref.read(appSettingsProvider.notifier);

  // Display.

  Future<void> _pickCurrency(AppSettings s) {
    final l = context.l10n;
    return KitPickerSheet.show<String>(
      context: context,
      title: l.settingsCurrency,
      selected: s.fiatCurrency,
      choices: [for (final c in fiatCurrencies) KitChoice(value: c, title: currencyLabel(l, c), semanticsId: TrustIds.appearanceCurrencyChoiceAt(c))],
      onSelected: _settings.setFiatCurrency,
    );
  }

  Future<void> _pickTheme(AppSettings s) {
    final l = context.l10n;
    return KitPickerSheet.show<ThemeMode>(
      context: context,
      title: l.settingsTheme,
      selected: s.themeMode,
      choices: [
        for (final m in ThemeMode.values)
          KitChoice(
            value: m,
            title: themeLabel(l, m),
            semanticsId: switch (m) {
              ThemeMode.system => TrustIds.appearanceThemeSystem,
              ThemeMode.dark => TrustIds.appearanceThemeDark,
              ThemeMode.light => TrustIds.appearanceThemeLight,
            },
          ),
      ],
      onSelected: _settings.setThemeMode,
    );
  }

  Future<void> _pickLanguage(AppSettings s) {
    // A sentinel, because null is the system's language and a picker row needs a value.
    const system = '';
    return KitPickerSheet.show<String>(
      context: context,
      title: context.l10n.languageSetting,
      selected: s.language ?? system,
      choices: [
        KitChoice(
          value: system,
          title: context.l10n.languageSystem,
          semanticsId: TrustIds.appearanceLanguageChoiceAt('system'),
          // A neutral globe, as wide as a flag, so the names line up.
          leading: SizedBox(width: 16 * 4 / 3, child: Icon(KitIcons.language, size: 16, color: context.tokens.dim)),
        ),
        for (final a in appLanguages) KitChoice(value: a.code, title: a.name, leading: LanguageFlag(a.code), semanticsId: TrustIds.appearanceLanguageChoiceAt(a.code)),
      ],
      onSelected: (code) => _settings.setLanguage(code == system ? null : code),
    );
  }

  Future<void> _setShowFiat(bool on) async {
    await _settings.setShowFiat(on);
    if (on && mounted) {
      _say(context.l10n.settingsPricesOnNotice, level: NoticeLevel.info);
    }
  }

  // Security.

  /// The picker's value for Never (no minutes).
  static const int _autoLockNever = 0;

  Future<void> _pickAutoLock(AppSettings s) {
    final l = context.l10n;
    final current = s.autoLockMinutes;
    return KitPickerSheet.show<int>(
      context: context,
      title: l.settingsAutoLock,
      subtitle: l.phoneSettingsAutoLockSub,
      note: l.phoneSettingsPickerNote,
      // Never is the stored "none" (`autoLockMinutes` null), as on main and the desktop; 0 stands for it in the list.
      selected: current == null ? _autoLockNever : autoLockChoice(current),
      choices: [
        for (final m in autoLockChoices) KitChoice(value: m, title: autoLockDuration(l, m), semanticsId: TrustIds.securityAutoLockChoiceAt(m)),
        KitChoice(value: _autoLockNever, title: l.autoLockNever, semanticsId: TrustIds.securityAutoLockChoiceAt('never')),
      ],
      onSelected: (m) => _settings.setAutoLockMinutes(m == _autoLockNever ? null : m),
    );
  }

  Future<void> _setBiometrics(bool on) async {
    final config = ref.read(walletConfigProvider);
    final session = ref.read(sessionProvider);
    if (config == null || session == null) return;
    final vault = ref.read(vaultProvider);
    if (!on) {
      await vault.disableBiometrics(config.chain);
      if (mounted) {
        _say(context.l10n.settingsBiometricsOff, level: NoticeLevel.success);
      }
    } else {
      final ok = await askPin(
        context,
        reason: usesPassphrase(ref)
            ? context.l10n.settingsBiometricsPassphraseReason
            : context.l10n.settingsBiometricsPinReason,
        allowBiometrics: false,
        action: (pin) => vault.enableBiometrics(session, config, pin),
      );
      if (ok == null) return;
      // On: the switch says so, and the next unlock offers biometrics.
      if (!ok && mounted) {
        _say(context.l10n.settingsBiometricsFailed, level: NoticeLevel.error);
      }
    }
    ref.invalidate(biometricsProvider);
  }

  Future<void> _showPhrase() async {
    final done = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const BackupScreen()));
    if (done == true && mounted) {
      _say(context.l10n.settingsPhraseConfirmed, level: NoticeLevel.success);
    }
  }

  // Wallet.

  Future<void> _rescan() async {
    final chain = ref.read(walletConfigProvider)?.chain;
    final start = await showAppDialog<BigInt>(
      context,
      builder: (_) => _RescanDialog(
        datesSupported: chain == Chain.mainnet,
        // Advanced › Recheck from a height: the height row, and on a test network the choice.
        heights: AdvancedOptions.has(context, AdvancedFeature.recheckFromHeight),
      ),
    );
    if (start == null || !mounted) return;
    final ok = await ref.read(scanProvider.notifier).run(startHeight: start);
    if (!mounted) return;
    if (ok) {
      _say(context.l10n.settingsRescanFinished, level: NoticeLevel.success);
    }
  }

  /// Deletes this wallet after the warning dialog and the PIN, then starts over on the first
  /// screen. A delete that fails after the wallet closed leaves for the launch screen.
  Future<void> _deleteWallet() async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    // A scan writes to the wallet's files until it ends. The automatic restore scan is stopped
    // by the delete; a Recheck the user started is theirs to finish.
    if (_userScanRunning()) {
      _say(context.l10n.settingsDeleteDuringScan, level: NoticeLevel.warning);
      return;
    }
    final confirmed = await showAppDialog<bool>(
      context,
      builder: (_) => const DeleteWalletDialog(),
    );
    if (confirmed != true || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final vault = ref.read(vaultProvider);
    final checked = await askPin(
      context,
      reason: usesPassphrase(ref)
          ? context.l10n.settingsDeletePassphraseReason
          : context.l10n.settingsDeletePinReason,
      allowBiometrics: false,
      action: (pin) async {
        await vault.checkPin(session, config, pin);
        return true;
      },
    );
    if (checked == null || !mounted) return;
    if (_userScanRunning()) {
      _say(context.l10n.settingsDeleteDuringScan, level: NoticeLevel.warning);
      return;
    }
    final step = ValueNotifier<DeleteStep?>(null);
    // Closed by the screen that follows: both ways out replace every route.
    unawaited(
      showAppDialog<void>(
        context,
        dismissible: false,
        builder: (_) => DeleteProgressDialog(step: step),
      ),
    );
    await _run(() async {
      try {
        await deleteWalletEverywhere(ref, config, onStep: (s) => step.value = s);
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
          (_) => false,
        );
      } catch (error) {
        if (mounted) leaveAfterFailedDelete(context, ref, error);
      }
    });
  }

  bool _userScanRunning() =>
      ref.read(scanProvider).running && !ref.read(restoreScanProvider.notifier).scanning;

  /// Restore from a phrase replaces this wallet (one per network): the phrase comes first, and
  /// the wallet is deleted only once it checks out and the user confirmed with the PIN
  /// (`restore_screen.dart`, [RestoreScreen.replace]). Back before that leaves it as it is.
  void _restoreFromPhrase() {
    if (ref.read(walletConfigProvider) == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RestoreScreen(replace: true)),
    );
  }

  /// What the page's "?" shows: the lines that used to sit behind the page's info icons.
  SettingsPageHelp? _help(AppLocalizations l) => switch (widget.section) {
    SettingsSection.security => SettingsPageHelp(
      title: l.settingsSectionSecurity,
      lines: [l.phoneSettingsSecurityHelp1, l.phoneSettingsSecurityHelp2, l.phoneSettingsSecurityHelp3],
      topic: HelpId.phrase,
      sheetId: TrustIds.settingsHelpSheet,
      moreId: TrustIds.settingsHelpMore,
    ),
    SettingsSection.privacyNetwork => SettingsPageHelp(
      title: l.settingsSectionNetworkPrivacy,
      lines: [l.advNodeFailoverHint, l.phoneSettingsNetworkHelp, if (statusSiteConfigured) l.settingsUseStatusSiteSubtitle],
      topic: HelpId.modes,
      sheetId: TrustIds.settingsHelpSheet,
      moreId: TrustIds.settingsHelpMore,
    ),
    SettingsSection.wallet => SettingsPageHelp(
      title: l.settingsSectionWallet,
      lines: [l.phoneSettingsWalletHelp1, l.phoneSettingsWalletHelp2, l.backupFileRestoreOrder],
      topic: HelpId.backup,
      sheetId: TrustIds.settingsHelpSheet,
      moreId: TrustIds.settingsHelpMore,
    ),
    SettingsSection.transactions => SettingsPageHelp(
      title: l.phoneSettingsPayments,
      lines: [l.phoneSettingsPaymentsHelp1, l.phoneSettingsPaymentsHelp2, l.phoneSettingsPaymentsHelp3],
      topic: HelpId.methods,
      sheetId: TrustIds.settingsHelpSheet,
      moreId: TrustIds.settingsHelpMore,
    ),
    SettingsSection.display => SettingsPageHelp(
      title: l.settingsSectionDisplay,
      lines: [l.phoneSettingsAppearanceHelp1, l.phoneSettingsAppearanceHelp2],
      sheetId: TrustIds.settingsHelpSheet,
      moreId: TrustIds.settingsHelpMore,
    ),
    SettingsSection.advanced => SettingsPageHelp(
      title: l.advTitle,
      lines: [
        l.advIntro,
        l.advOutputsHint,
        l.advTechnicalHint,
        l.advSendOptionsHint,
        l.advServerDetailsHint,
        l.advRecheckHeightHint,
        if (announcementsOffered(ref.watch(hostSettingsProvider))) l.announcementsHint,
      ],
      topic: HelpId.advanced,
      sheetId: TrustIds.settingsHelpSheet,
      moreId: TrustIds.settingsHelpMore,
    ),
    SettingsSection.about => SettingsPageHelp(
      title: l.phoneAboutHelpTitle,
      lines: [l.phoneAboutHelp1, l.phoneAboutHelp2],
      sheetId: TrustIds.aboutHelpSheet,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rows = switch (widget.section) {
      SettingsSection.security => _security(l),
      SettingsSection.privacyNetwork => _privacyNetwork(l),
      SettingsSection.wallet => _wallet(l),
      SettingsSection.transactions => _transactions(l),
      SettingsSection.display => _display(l),
      SettingsSection.advanced => _advanced(l),
      SettingsSection.about => _about(l),
    };
    return SettingsPhonePage(
      pageKey: settingsSectionKey(widget.section),
      title: settingsSectionTitle(l, widget.section),
      backLabel: widget.backLabel,
      controller: _scroll,
      help: _help(l),
      helpId: widget.section == SettingsSection.about ? TrustIds.aboutHelp : TrustIds.settingsPageHelp,
      backId: widget.section == SettingsSection.about ? TrustIds.aboutBack : TrustIds.settingsPageBack,
      children: rows,
    );
  }

  /// Security: the phrase first (the one thing that guards the funds), then how the wallet
  /// unlocks, then Lock now on its own at the end.
  List<Widget> _security(AppLocalizations l) {
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final biometrics = ref.watch(biometricsProvider).value;
    final backedUp = ref.watch(backedUpProvider).value ?? true;
    final t = context.tokens;
    final minutes = s.autoLockMinutes;
    return [
      KitGroup(
        dividerInset: Kit.dividerInsetPlain,
        children: [
          KitRow(
            size: KitRowSize.list,
            title: l.backupTitle,
            subtitle: l.phoneSettingsPhraseLine,
            value: backedUp ? l.phoneSettingsBackedUp : l.settingsStateNotBackedUp,
            valueIcon: backedUp ? KitIcons.check : null,
            valueColor: backedUp ? t.ok : t.warn,
            chevron: true,
            semanticsId: TrustIds.backupRow,
            onTap: _showPhrase,
          ),
        ],
      ),
      KitGroupLabel(l.phoneSettingsUnlocking),
      KitGroup(
        dividerInset: Kit.dividerInsetPlain,
        children: [
          if (biometrics?.available ?? false)
            KitRow.toggle(
              title: l.phoneSettingsBiometrics,
              subtitle: l.phoneSettingsBiometricsLine,
              value: biometrics!.enabled,
              onChanged: _setBiometrics,
              semanticsId: TrustIds.securityBiometrics,
            ),
          KitRow(
            size: KitRowSize.settings,
            title: l.settingsAutoLock,
            value: autoLockValue(l, minutes),
            chevron: true,
            semanticsId: TrustIds.securityAutoLock,
            onTap: () => _pickAutoLock(s),
          ),
          if (!previewNoLock)
            KitRow(
              size: KitRowSize.settings,
              title: l.settingsChangePin,
              chevron: true,
              semanticsId: TrustIds.securityChangePin,
              onTap: () => _push(const ChangePinScreen()),
            ),
          // Optional: a passphrase in place of the 6-digit PIN (WAL-03). Change PIN goes back to a PIN.
          if (!previewNoLock)
            KitRow(
              size: KitRowSize.list,
              title: l.phoneSettingsPassphrase,
              subtitle: l.phoneSettingsPassphraseLine,
              value: (ref.watch(usesPassphraseProvider).value ?? false) ? l.netStatusOn : l.netStatusOff,
              chevron: true,
              semanticsId: TrustIds.securityPassphrase,
              onTap: () => _push(const ChangePinScreen(passphrase: true)),
            ),
        ],
      ),
      if (minutes != null) KitFootnote(l.phoneSettingsAutoLockFootnote(autoLockDuration(l, minutes))),
      if (!previewNoLock) ...[
        const SizedBox(height: 22),
        KitGroup(
          dividerInset: Kit.dividerInsetPlain,
          children: [
            KitRow(
              size: KitRowSize.settings,
              title: l.phoneSettingsLockNow,
              titleColor: t.accentText,
              semanticsId: TrustIds.homeLock,
              onTap: () => lockWallet(context, ref),
            ),
          ],
        ),
      ],
    ];
  }

  /// Network & privacy: the servers first (Epicbox, then Node, the status card from Home with
  /// its rows opening the pickers), Node failover under them, then the connection mode (Tor
  /// only is the one whole-wallet Tor control) and the status site.
  List<Widget> _privacyNetwork(AppLocalizations l) {
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final walletOpen = ref.watch(sessionProvider) != null;
    final torState = phoneTorState(ref.watch(phoneTorProvider));
    final mode = ref.watch(networkModeProvider);
    final config = ref.watch(walletConfigProvider);
    final network = ref.watch(networkChoiceProvider).value;
    final devNetworks = ref.watch(devNetworksProvider);
    final advanced = AdvancedOptions.of(context);
    final chain = config == null ? l.commonUnknown : chainName(l, config.chain);
    final dim = context.tokens.dim;
    // One page for how the wallet reaches the network (B-03): the servers (Epicbox and Node
    // with their host and health, each opening its picker; with no wallet open, plain rows
    // open the same pickers), Node failover, the mode, then the status site.
    // On by default: the one switch here that keeps the simple app working.
    final failover = KitRow.toggle(
      key: advNodeFailoverKey,
      title: l.phoneSettingsFailover,
      subtitle: l.phoneSettingsFailoverLine,
      subtitleLines: 3,
      size: KitRowSize.list,
      value: s.advanced.nodeFailover,
      onChanged: _settings.setNodeFailover,
      semanticsId: TrustIds.networkFailover,
    );
    return [
      KitGroupLabel(l.netPageServers, key: settingsServersKey, top: 0),
      if (walletOpen)
        PhoneTourTarget(id: 'tour-privacy-servers', child: NetworkStatusCard(showTor: false, extraRows: [failover]))
      else
        KitGroup(
          dividerInset: Kit.dividerInsetPlain,
          children: [
            KitRow(
              key: settingsEpicboxKey,
              size: KitRowSize.settings,
              title: l.serverEpicboxTitle,
              subtitleWidget: withTorWay(
                switch (network?.relay.label ?? (config == null ? null : EpicboxRelay(host: config.epicboxDomain, port: config.epicboxPort).label)) {
                  final host? => HostText(host, style: TextStyle(color: dim)),
                  null => Text(l.commonUnknown),
                },
                torWayIn(TorRoute.epicbox, torState, mode),
                TorRoute.epicbox,
              ),
              chevron: true,
              semanticsId: TrustIds.networkEpicbox,
              onTap: () => showEpicboxPicker(context),
            ),
            KitRow(
              key: settingsNodeKey,
              size: KitRowSize.settings,
              title: l.serverNodeTitle,
              subtitleWidget: withTorWay(
                network == null ? null : HostText(serverHost(network.nodeUrl), style: TextStyle(color: dim)),
                nodeTorWay(network?.nodeUrl, torState, mode),
                TorRoute.node,
              ),
              chevron: true,
              semanticsId: TrustIds.networkNode,
              onTap: () => showNodePicker(context),
            ),
            failover,
          ],
        ),
      NetworkModeSection(
        headerKey: _networkKey,
        tourId: (rows) => PhoneTourTarget(id: 'tour-privacy-modes', child: rows),
      ),
      // No status site in app-config.toml: no switch.
      if (statusSiteConfigured) ...[
        const SizedBox(height: 14),
        KitGroup(
          dividerInset: Kit.dividerInsetPlain,
          children: [
            KitRow.toggle(
              size: KitRowSize.list,
              subtitleLines: 3,
              title: l.phoneSettingsServerStatus,
              subtitle: l.phoneSettingsServerStatusLine(statusSiteHost),
              value: s.useStatusSite,
              onChanged: _settings.setUseStatusSite,
              semanticsId: TrustIds.networkStatusSite,
            ),
          ],
        ),
      ],
      // Development builds only: the network itself, each with its own wallet.
      if (advanced.has(AdvancedFeature.serverDetails) && devNetworks) ...[
        const SettingsGap(),
        KitGroup(
          dividerInset: Kit.dividerInsetPlain,
          children: [
            KitRow(
              size: KitRowSize.settings,
              title: l.settingsAboutNetwork,
              value: chain,
              chevron: true,
              semanticsId: TrustIds.networkChooser,
              onTap: () => showNetworkChooser(context),
            ),
          ],
        ),
      ],
    ];
  }

  /// This wallet: the phrase, the data files, the upkeep (recheck, outputs, restore) and Delete
  /// on its own at the end.
  List<Widget> _wallet(AppLocalizations l) {
    final scan = ref.watch(scanProvider);
    final backedUp = ref.watch(backedUpProvider).value ?? true;
    final t = context.tokens;
    // Recheck balance asks the node only: Node only lets it run.
    final block = watchNetBlock(context, ref, node: true);
    final recheckOff = scan.running || block != NetBlock.none;
    return [
      KitGroup(
        dividerInset: Kit.dividerInsetPlain,
        children: [
          KitRow(
            size: KitRowSize.list,
            title: l.backupTitle,
            subtitle: l.phoneSettingsPhraseLine,
            value: backedUp ? l.phoneSettingsBackedUp : l.settingsStateNotBackedUp,
            valueIcon: backedUp ? KitIcons.check : null,
            valueColor: backedUp ? t.ok : t.warn,
            chevron: true,
            semanticsId: TrustIds.walletPhrase,
            onTap: _showPhrase,
          ),
        ],
      ),
      KitGroupLabel(l.settingsSectionHistory),
      KitGroup(
        dividerInset: Kit.dividerInsetPlain,
        children: [
          KitRow(
            size: KitRowSize.list,
            title: l.phoneSettingsExport,
            subtitle: l.phoneSettingsExportLine,
            chevron: true,
            semanticsId: TrustIds.walletExport,
            onTap: _busy ? null : () => _run(() => exportHistoryBackup(context, ref)),
          ),
          KitRow(
            size: KitRowSize.settings,
            title: l.phoneSettingsImport,
            chevron: true,
            semanticsId: TrustIds.walletImport,
            onTap: _busy ? null : () => _run(() => importHistoryBackup(context, ref)),
          ),
          KitRow(
            size: KitRowSize.list,
            title: l.phoneSettingsCsv,
            subtitle: l.phoneSettingsCsvLine,
            chevron: true,
            semanticsId: TrustIds.walletCsv,
            onTap: _busy ? null : () => _run(() => exportHistoryCsv(context, ref)),
          ),
        ],
      ),
      KitGroupLabel(l.phoneSettingsUpkeep),
      KitGroup(
        dividerInset: Kit.dividerInsetPlain,
        children: [
          // Recheck balance is the fix for a wrong balance: for everyone. From a height is Advanced.
          // It reads the chain, so it waits for the network.
          KitRow(
            size: KitRowSize.list,
            title: l.settingsRescan,
            subtitle: scan.running
                ? l.workChecking
                : block == NetBlock.none
                    ? l.phoneSettingsRecheckLine
                    : (block == NetBlock.killSwitch ? l.recheckOffKill : netBlockReason(l, block)!),
            subtitleLines: 2,
            trailing: scan.running
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, value: MediaQuery.disableAnimationsOf(context) ? 0.3 : null),
                  )
                : null,
            semanticsId: TrustIds.walletRecheck,
            enabled: !recheckOff,
            onTap: recheckOff ? null : _rescan,
          ),
          // Advanced › Outputs; a split or consolidation mid-way keeps the row (never hide what is
          // in use).
          if (outputsShown(context, ref))
            KitRow(
              size: KitRowSize.list,
              title: l.outputsTitle,
              subtitle: l.phoneSettingsOutputsLine,
                            chevron: true,
              semanticsId: TrustIds.walletOutputs,
              onTap: () => _push(const OutputsScreen()),
            ),
          // Restore from a phrase replaces this wallet (one per network), so it goes through its
          // warning and PIN once the phrase checks out. Help names this place.
          KitRow(
            key: settingsRestoreKey,
            size: KitRowSize.list,
            title: l.phoneSettingsRestore,
            subtitle: l.phoneSettingsRestoreLine,
            subtitleLines: 2,
            chevron: true,
            semanticsId: TrustIds.walletRestore,
            onTap: _busy ? null : _restoreFromPhrase,
          ),
        ],
      ),
      const SizedBox(height: 14),
      KitGroup(
        dividerInset: Kit.dividerInsetPlain,
        children: [
          KitRow(
            size: KitRowSize.settings,
            title: l.settingsDeleteWallet,
            titleColor: t.risk,
            semanticsId: TrustIds.walletDelete,
            enabled: !_busy,
            onTap: _busy ? null : _deleteWallet,
          ),
        ],
      ),
    ];
  }

  /// The wallet's transactions as last listed (Home's, else the session's own list); empty
  /// when nothing answers.
  Future<List<TxEntry>> _walletTransactions() async {
    final home = ref.read(homeProvider).value;
    if (home != null) return home.transactions;
    try {
      return await ref.read(sessionProvider)?.transactions(refresh: false) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  /// "Turn Epicbox off?" while [waiting] sends still wait for their replies over Epicbox.
  Future<bool> _confirmEpicboxOff(int waiting) async {
    final yes = await showAppDialog<bool>(
      context,
      builder: (context) {
        final l = context.l10n;
        return AppDialog(
          title: l.txEpicboxOffTitle,
          icon: MethodIcons.epicbox,
          tone: DialogTone.warn,
          description: l.txEpicboxOffPending(waiting),
          actions: [
            DialogButton.secondary(label: l.commonCancel, onPressed: () => Navigator.pop(context, false)),
            DialogButton.primary(label: l.txEpicboxOffAction, onPressed: () => Navigator.pop(context, true)),
          ],
        );
      },
    );
    return yes == true;
  }

  /// Payments: how payments are made. The methods Send and Receive offer, one switch each; with
  /// Advanced › Send options, the defaults a send uses (which outputs it spends and whether its
  /// change is split); the experimental epic1 switch; the invoice settings.
  List<Widget> _transactions(AppLocalizations l) {
    // epic1 (spec P1): its own sections in place of the methods, and the switch last.
    final epic1Rows = ref.watch(epic1Provider) == null ? const <Widget>[] : epic1ExperimentalRows(l);
    if (ref.watch(paymentModeProvider) == PaymentMode.epic1) {
      return [...epic1ModeRows(l, confirmations: const ConfirmationsRow()), ...epic1Rows];
    }
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final payments = s.payments;
    final torAvailable = ref.watch(phoneTorProvider.select(torShown));
    // Invoices only on a core that has them (UP-14); until then no entry at all.
    final invoices = ref.watch(invoicesShownProvider);
    // Send options on shows the defaults; one that is not at its default stays (never hide a
    // choice in use), as Outputs did before they moved here.
    final showDefaults = _txDefaultsShown |=
        s.advanced.has(AdvancedFeature.sendOptions) ||
        s.sendStrategy != SelectionStrategy.smallest ||
        !s.splitChange;
    // Link · Tor needs Tor, so where the app has none (and the switch is off) there is nothing
    // to turn on. The phone's Link · HTTP only sends, always: no switch there.
    final showTor = _txTorShown |= torBuilt && (torAvailable || payments.linkTor);
    // The phone's Direct methods: QR Payment for everyone, File Transfer behind Advanced ›
    // Transaction files (a phone that has it on keeps the row, so it can still be turned off).
    final phone = ref.watch(phonePaymentsProvider);
    final loaded = ref.watch(appSettingsProvider).value != null;
    final showFile = !phone ||
        (_txFileShown |= loaded &&
            (payments.directFile ||
                s.advanced.has(AdvancedFeature.transactionFiles)));
    bool shown(MethodKind m) => switch (m) {
      MethodKind.epicbox => true,
      MethodKind.linkHttp => !phone,
      MethodKind.linkTor => showTor,
      MethodKind.directQr => phone,
      MethodKind.directFile => showFile,
    };
    Future<void> save(PaymentPrefs next) => _settings.setPayments(next);
    // The last method on stays on: Send and Receive always keep a way. The switch does not
    // move; the notice says why.
    Future<void> set(MethodKind m, bool on) async {
      // On the phone a stored Link · HTTP switch receives nothing: it keeps no way open.
      if (!on && !(phone ? payments.copyWith(linkHttp: false) : payments).canTurnOff(m)) {
        _say(l.txLastMethodNotice, level: NoticeLevel.warning);
        return;
      }
      // Epicbox off while a send still waits for its reply over it: one confirm first.
      if (!on && m == MethodKind.epicbox) {
        final waiting = pendingEpicboxSends(await _walletTransactions());
        if (!mounted || (waiting > 0 && !await _confirmEpicboxOff(waiting))) return;
      }
      await save(payments.withMethod(m, on));
    }

    // The row is the name and one line; what the method does is in the page's help sheet.
    Widget methodRow(MethodKind m) {
      final (String title, String? line) = switch (m) {
        MethodKind.epicbox => (MethodIcons.groupName(l, m), l.phoneSettingsEpicboxLine),
        MethodKind.directQr => (l.phoneSettingsInPerson, l.phoneSettingsInPersonLine),
        MethodKind.directFile => (l.phoneSettingsWithFile, l.phoneSettingsWithFileLine),
        MethodKind.linkTor => (l.phoneSettingsTorAddress, l.phoneSettingsTorAddressLine),
        MethodKind.linkHttp => (MethodIcons.fullName(l, m), null),
      };
      return KitRow.toggle(
        key: txMethodKey(m),
        leading: KitIconWell(
          switch (m) { MethodKind.directQr => KitIcons.qr, MethodKind.directFile => KitIcons.file, _ => MethodIcons.of(m) },
          color: context.tokens.accentText,
          iconSize: 20,
        ),
        title: title,
        size: KitRowSize.list,
        subtitle: line,
        subtitleLines: 2,
        value: payments.offers(m),
        // Link · Tor starts and stops tor: it waits while a change is being applied.
        onChanged: m == MethodKind.linkTor && (!torPayCanSwitch(ref.watch(phoneTorPayProvider)) || ref.watch(phoneTorProvider.select((s) => s.changing)))
            ? null
            : (on) => set(m, on),
        semanticsId: _methodId(m),
      );
    }

    final methods = [
      for (final m in const [MethodKind.epicbox, MethodKind.directQr, MethodKind.directFile, MethodKind.linkTor, MethodKind.linkHttp])
        if (shown(m)) m,
    ];
    return [
      KitGroupLabel(l.phoneSettingsPayWays, key: const ValueKey('tx-methods'), top: 0),
      KitGroup(children: [for (final m in methods) methodRow(m)]),
      // Tor for payments (item 2): its state, never a "turn Tor on" card.
      if (payments.linkTor && showTor) const _TorPayLine(),
      if (showDefaults) ...[
        KitGroupLabel(l.txDefaultsHeader),
        KitGroup(
          dividerInset: Kit.dividerInsetPlain,
          children: [
            KitRow(
              key: const ValueKey('tx-strategy'),
              size: KitRowSize.settings,
              title: l.outputsStrategy,
              value: s.sendStrategy == SelectionStrategy.smallest ? l.outputsSmallest : l.outputsAll,
              chevron: true,
              semanticsId: TrustIds.paymentsStrategy,
              onTap: () => _pickStrategy(s.sendStrategy),
            ),
            KitRow.toggle(
              key: const ValueKey('tx-split'),
              title: l.outputsSplitChange,
              subtitle: l.phoneSettingsSplitLine,
              value: s.splitChange,
              onChanged: _settings.setSplitChange,
              semanticsId: TrustIds.paymentsSplit,
            ),
          ],
        ),
      ],
      ...epic1Rows,
      if (invoices) ...[
        const SizedBox(height: 14),
        KitGroup(
          dividerInset: Kit.dividerInsetPlain,
          children: [
            KitRow(
              size: KitRowSize.list,
              title: l.settingsInvoices,
              subtitle: l.phoneSettingsInvoicesLine,
              subtitleLines: 2,
              chevron: true,
              semanticsId: TrustIds.paymentsInvoices,
              onTap: () => _push(const InvoiceSettingsScreen()),
            ),
          ],
        ),
      ],
    ];
  }

  /// The strategy a send spends outputs by: the two choices, each with its one line.
  Future<void> _pickStrategy(SelectionStrategy current) {
    final l = context.l10n;
    return KitPickerSheet.show<SelectionStrategy>(
      context: context,
      title: l.outputsStrategy,
      selected: current,
      choices: [
        for (final strategy in SelectionStrategy.values)
          KitChoice(
            value: strategy,
            title: strategy == SelectionStrategy.smallest ? l.outputsSmallest : l.outputsAll,
            subtitle: strategy == SelectionStrategy.smallest ? l.outputsSmallestText : l.outputsAllText,
            semanticsId: strategy == SelectionStrategy.smallest ? TrustIds.paymentsStrategySmallest : TrustIds.paymentsStrategyAll,
          ),
      ],
      onSelected: _settings.setSendStrategy,
    );
  }

  /// Advanced: the switches that show more of the wallet, each with its one line, and the
  /// confirmations count. Nothing here is a value the simple path needs. The View level row is
  /// not on the phone: the switches are all there is.
  List<Widget> _advanced(AppLocalizations l) {
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final adv = s.advanced;
    final t = context.tokens;
    Widget feature(AdvancedFeature f, String title, String line, String id) => KitRow.toggle(
      key: ValueKey('adv-${f.name}'),
      title: title,
      subtitle: line,
      size: KitRowSize.list,
      subtitleLines: 2,
      value: adv.has(f),
      onChanged: (on) => _settings.setFeature(f, on),
      semanticsId: id,
    );
    return [
      PhoneTourTarget(id: 'tour-advanced-top', child: KitLead(l.phoneSettingsAdvIntro)),
      KitGroupLabel(l.phoneSettingsAdvShows),
      KitGroup(
        dividerInset: Kit.dividerInsetPlain,
        children: [
          feature(AdvancedFeature.outputs, l.advOutputs, l.phoneSettingsAdvOutputsLine, TrustIds.advancedOutputs),
          feature(AdvancedFeature.technicalDetails, l.advTechnical, l.phoneSettingsAdvTechnicalLine, TrustIds.advancedTechnical),
          feature(AdvancedFeature.sendOptions, l.advSendOptions, l.phoneSettingsAdvSendLine, TrustIds.advancedSendOptions),
          feature(AdvancedFeature.serverDetails, l.advServerDetails, l.phoneSettingsAdvServersLine, TrustIds.advancedServerDetails),
          feature(AdvancedFeature.recheckFromHeight, l.advRecheckHeight, l.phoneSettingsAdvRecheckLine, TrustIds.advancedRecheck),
        ],
      ),
      // The wallet's own count, stored in the core: how long received coins wait.
      KitGroupLabel(l.advBalanceHeader),
      ConfirmationsRow(subtitle: l.phoneSettingsConfirmationsLine, showDefaultTag: false),
      // The frame draws five switches: this one is a group of its own below Balance.
      const SizedBox(height: 14),
      KitGroup(
        dividerInset: Kit.dividerInsetPlain,
        children: [feature(AdvancedFeature.transactionFiles, l.advTransactionFiles, l.phoneSettingsAdvFilesLine, TrustIds.advancedFiles)],
      ),
      // In every view (no level gate): anyone can turn the messages off. No feed in
      // app-config.toml: no row. Label only; the explanation is in the page's "?".
      if (announcementsOffered(ref.watch(hostSettingsProvider))) ...[
        const SizedBox(height: 14),
        KitGroup(
          dividerInset: Kit.dividerInsetPlain,
          children: [
            KitRow.toggle(
              key: const ValueKey('adv-announcements'),
              title: l.announcementsTitle,
              size: KitRowSize.list,
              value: ref.watch(hostSettingsProvider).announcementsEnabled,
              onChanged: (on) => ref.read(hostSettingsProvider.notifier).set('online.announcements', on),
              semanticsId: TrustIds.advancedAnnouncements,
            ),
          ],
        ),
      ],
      // As on the desktop: the way back (GP-038).
      if (adv.shownFeatures.isNotEmpty)
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
            child: TrustId(
              TrustIds.advancedReset,
              child: TextButton(
                key: const ValueKey('adv-reset'),
                onPressed: () => _settings.setAdvanced(adv.withoutShown()),
                child: Text(l.advReset, style: KitType.navLink.copyWith(color: t.accentText)),
              ),
            ),
          ),
        ),
    ];
  }

  /// Appearance: theme, language and currency as pickers, then the two display switches.
  List<Widget> _display(AppLocalizations l) {
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    // No price source in app-config.toml, or `[online] price` off in settings.toml: no rows.
    final prices = pricesOffered(ref.watch(hostSettingsProvider));
    return [
      KitGroup(
        dividerInset: Kit.dividerInsetPlain,
        children: [
          KitRow(
            size: KitRowSize.settings,
            title: l.settingsTheme,
            value: themeLabel(l, s.themeMode),
            chevron: true,
            semanticsId: TrustIds.appearanceTheme,
            onTap: () => _pickTheme(s),
          ),
          KitRow(
            size: KitRowSize.settings,
            title: l.languageSetting,
            value: languageLabel(l, s.language),
            chevron: true,
            semanticsId: TrustIds.appearanceLanguage,
            onTap: () => _pickLanguage(s),
          ),
          if (prices)
            KitRow(
              size: KitRowSize.settings,
              title: l.settingsCurrency,
              value: currencyLabel(l, s.fiatCurrency),
              chevron: true,
              semanticsId: TrustIds.appearanceCurrency,
              onTap: s.showFiat ? () => _pickCurrency(s) : null,
            ),
        ],
      ),
      const SizedBox(height: 14),
      KitGroup(
        dividerInset: Kit.dividerInsetPlain,
        children: [
          if (prices)
            KitRow.toggle(
              size: KitRowSize.list,
              subtitleLines: 2,
              title: l.settingsShowPrices,
              subtitle: l.phoneSettingsShowPricesLine,
              value: s.showFiat,
              onChanged: _setShowFiat,
              semanticsId: TrustIds.appearanceShowPrices,
            ),
          KitRow.toggle(
            size: KitRowSize.list,
            subtitleLines: 2,
            title: l.phoneSettingsHideAmounts,
            subtitle: l.phoneSettingsHideAmountsLine,
            value: s.hideBalances,
            onChanged: _settings.setHideBalances,
            semanticsId: TrustIds.appearanceHideAmounts,
          ),
        ],
      ),
    ];
  }

  /// About: the mark and name, the facts about this build, then What is new, Licences and the
  /// links (`about_phone.dart`). The page's back link reads "Help": About sits in Help's list too.
  List<Widget> _about(AppLocalizations l) => const [AboutPhoneBody()];
}

/// `Euro (EUR)`, or the bare code for one the list does not know.
String currencyLabel(AppLocalizations l, String code) =>
    fiatCurrencies.contains(code)
    ? l.settingsCurrencyWithCode(currencyName(l, code), code.toUpperCase())
    : code.toUpperCase();

/// Plain words for a theme choice.
String themeLabel(AppLocalizations l, ThemeMode mode) => switch (mode) {
  ThemeMode.system => l.settingsThemeSystem,
  ThemeMode.light => l.settingsThemeLight,
  ThemeMode.dark => l.settingsThemeDark,
};

/// The language setting as the user reads it: [AppLocalizations.languageSystem] for null, else
/// the language's own name from [appLanguages], which is never translated.
String languageLabel(AppLocalizations l, String? code) {
  for (final a in appLanguages) {
    if (a.code == code) return a.name;
  }
  return l.languageSystem;
}

/// [subtitle] with the [TorWayLine] for [route] under it while that connection goes over Tor or
/// waits for it ([way]); [subtitle] alone otherwise.
Widget? withTorWay(Widget? subtitle, TorWay way, TorRoute route) {
  if (way != TorWay.overTor && way != TorWay.wait && way != TorWay.blocked) {
    return subtitle;
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [?subtitle, TorWayLine(route: route)],
  );
}

/// The Linked devices row on the Wallet page, for tests.
const Key settingsLinkedDevicesKey = ValueKey('settings-linked-devices');

/// The key of a method's switch on Settings › Transactions, for tests and the tour:
/// `tx-epicbox`, `tx-http`, `tx-tor`, `tx-qr`, `tx-file`.
Key txMethodKey(MethodKind m) => ValueKey('tx-${_txKeyName(m)}');

String _methodId(MethodKind m) => switch (m) {
  MethodKind.epicbox => TrustIds.paymentsEpicbox,
  MethodKind.linkHttp => TrustIds.paymentsHttp,
  MethodKind.linkTor => TrustIds.paymentsTor,
  MethodKind.directQr => TrustIds.paymentsInPerson,
  MethodKind.directFile => TrustIds.paymentsFile,
};

String _txKeyName(MethodKind m) => switch (m) {
  MethodKind.epicbox => 'epicbox',
  MethodKind.linkHttp => 'http',
  MethodKind.linkTor => 'tor',
  MethodKind.directQr => 'qr',
  MethodKind.directFile => 'file',
};

/// The key of the line under Link · Tor that Tor is off, for tests.
const Key txTorPayLineKey = ValueKey('tx-tor-pay-line');

/// Under the Link · Tor switch while it is on: what Tor for payments does now (starting,
/// receiving, off in Node only or Kill switch) and whether Tor also carries the rest.
class _TorPayLine extends ConsumerWidget {
  const _TorPayLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = ref.watch(phoneTorPayProvider);
    final text = p.kind == TorPayKind.ready ? '${torPayLine(l, p)} · ${torPayRestLine(l, p)}' : torPayLine(l, p);
    return KitFootnote(text, key: txTorPayLineKey);
  }
}

/// A web link row. The app has no browser launcher, so tapping copies the address.
class LinkTile extends StatelessWidget {
  const LinkTile({super.key, required this.title, required this.url, this.id, this.minHeight});

  final double? minHeight;
  final String title;
  final String url;
  final String? id;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return KitRow(
      size: KitRowSize.settings,
      minHeight: minHeight,
      title: title,
      trailing: Icon(KitIcons.external, size: 16, color: context.tokens.dim, semanticLabel: l.settingsCopyLink),
      semanticsId: id,
      onTap: () => copyText(context, url, l.settingsLinkCopied),
    );
  }
}

/// Where a rescan starts: the shared scan-start block (`scan_start.dart`), as on a restore.
/// Pops the start height, or null when cancelled. On mainnet, at every level, a month
/// (January 2025 unless another is picked) or the start, and with [heights] a block height
/// too. A test network: the start, with [heights] a height.
class _RescanDialog extends StatefulWidget {
  const _RescanDialog({required this.datesSupported, required this.heights});

  final bool datesSupported;

  /// Advanced › Recheck from a height is on: a block height may be typed.
  final bool heights;

  @override
  State<_RescanDialog> createState() => _RescanDialogState();
}

class _RescanDialogState extends State<_RescanDialog> {
  late final _scanStart = ScanStartController(dates: widget.datesSupported);

  @override
  void dispose() {
    _scanStart.dispose();
    super.dispose();
  }

  // Block 0, not 1, for the start: only a scan from block 0 finishes a restore
  // (restore_scan.dart), and it goes on from where a stopped one of the same start left off.
  void _start() => Navigator.pop(context, _scanStart.start ?? BigInt.zero);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppDialog(
      title: l.settingsRescanTitle,
      icon: Icons.manage_search,
      description: l.settingsRescanBody,
      body: ScanStart(controller: _scanStart, heights: widget.heights),
      actions: [
        DialogButton.secondary(label: l.commonCancel, onPressed: () => Navigator.pop(context)),
        DialogButton.primary(label: l.settingsRescanButton, onPressed: _start),
      ],
    );
  }
}

/// The Settings › Wallet › Restore from a phrase row, for tests.
const Key settingsRestoreKey = ValueKey('settings-restore');

/// A strong warning before deleting the wallet. Pops true only after the user typed the
/// confirm word ([AppLocalizations.settingsDeleteConfirmWord]) and confirmed they have the
/// recovery phrase. With [restore] it opens with why a restore deletes first.
class DeleteWalletDialog extends StatefulWidget {
  const DeleteWalletDialog({super.key, this.restore = false});

  /// The delete is the first step of Restore from a phrase.
  final bool restore;

  @override
  State<DeleteWalletDialog> createState() => _DeleteWalletDialogState();
}

class _DeleteWalletDialogState extends State<DeleteWalletDialog> {
  final _word = TextEditingController();
  bool _understood = false;

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  // Lower case on both sides only to match what was typed, never for display.
  bool _ready(String word) =>
      _understood && _word.text.trim().toLowerCase() == word.toLowerCase();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final word = l.settingsDeleteConfirmWord;
    return AppDialog(
      icon: Icons.delete_outline,
      tone: DialogTone.risk,
      title: l.settingsDeleteTitle,
      description: widget.restore ? l.settingsRestoreReplaces : null,
      body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.settingsDeleteBody),
            const SizedBox(height: 8),
            // The box first, as every consent in the app (UP-010): body text, on the body's
            // edge (#65).
            DialogCheckRow(
              value: _understood,
              onChanged: (value) => setState(() => _understood = value),
              label: l.settingsDeleteHavePhrase,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _word,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l.settingsDeleteTypeToConfirm(word),
              ),
            ),
          ],
        ),
      actions: [
        DialogButton.secondary(label: l.settingsDeleteKeep, onPressed: () => Navigator.pop(context, false)),
        DialogButton.risk(label: l.settingsDeleteConfirm, onPressed: _ready(word) ? () => Navigator.pop(context, true) : null),
      ],
    );
  }
}
