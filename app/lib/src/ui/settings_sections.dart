// SPDX-License-Identifier: Apache-2.0
/// The phone's Settings pages, one per group of the hub (`settings_screen.dart`): Security,
/// Privacy & network, Wallet, Display and About. Each page is a short list of label-only rows
/// (an explanation sits behind an info icon, a value or a state on the row's second line), so
/// a page fits a 360 dp phone without a search. Help & feedback opens Help itself.
library;

import 'package:flutter/material.dart';
import 'status_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_info.dart';
import '../app_log.dart';
import '../app_version.dart';
import '../settings_file/host_settings.dart' show appConfig, hostSettings;
import '../demo.dart';
import '../dist_build.dart';
import '../errors.dart';
import '../l10n.dart';
import '../network.dart';
import '../network_gate.dart';
import '../payment_prefs.dart';
import '../phone_tor.dart';
import '../tor_build.dart';
import '../price.dart';
import '../devices/phone_devices.dart';
import '../pairing_providers.dart' show invoicesShownProvider;
import '../providers.dart';
import '../restore_scan.dart' show restoreScanProvider;
import '../settings.dart';
import '../smart_outputs.dart' show OutputLabel, outputWord;
import '../tor_phone.dart';
import '../tor_routes.dart';
import '../updater.dart';
import '../wallet_service.dart';
import 'backup_screen.dart';
import 'common.dart';
import 'confirmations_row.dart';
import 'contacts_screen.dart';
import 'devices/device_parts.dart' show devicesStateLine;
import 'devices/linked_devices_screen.dart';
import 'demo_screens.dart' show endDemo;
import 'info_hint.dart';
import 'language_flag.dart';
import 'launch_screen.dart';
import 'licences_screen.dart';
import 'network_menu.dart';
import 'network_mode_phone.dart';
import 'network_mode_text.dart' show blockMode, networkModeName;
import 'net_block.dart';
import 'payment_gate.dart' show pendingEpicboxSends;
import 'network_status.dart';
import 'home_parts.dart' show outputsShown;
import 'outputs_screen.dart';
import 'pin.dart';
import 'restore_screen.dart'
    show RestoreScreen, ScanSlotLine, mainnetFirstDay, mainnetHeightForDate;
import 'server_picker.dart' show showEpicboxPicker, showNodePicker;
import 'settings_history.dart';
import 'settings_invoices.dart';
import 'settings_pin.dart';
import 'settings_screen.dart' show openPrivacySettings;
import 'status.dart' show serverHost;
import 'theme/advanced.dart';
import 'theme/brand.dart' show BrandLockup, BrandVariant;
import 'theme/tokens.dart';
import 'tor_ui.dart';
import 'tour/tour_target.dart';
import 'wallet_delete.dart';
import '../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../settings_file/status_site.dart' show statusSiteConfigured, statusSiteHost;

export 'wallet_delete.dart' show sharedFilesCleanupProvider;

/// The project's source code; null when `app-config.toml` leaves it out (no link).
String? get projectRepoUrl => hostSettings.linkSource;

/// BT Labs' privacy policy; null when `app-config.toml` leaves it out (no link).
String? get privacyPolicyUrl => hostSettings.linkPrivacy;

String? get epicCashUrl => hostSettings.linkWebsite;

/// The Epic Cash community chat; null: no link.
String? get communityUrl => hostSettings.linkCommunity;

/// The public contact address, shown in Help and About. Never translated. Null: not shown.
String? get supportEmail => hostSettings.supportEmail;


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

String _withCore(String name) => withBuildId(withCoreVersion(name));

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
      SettingsSection.privacyNetwork => l.settingsSectionPrivacyNetwork,
      SettingsSection.wallet => l.settingsSectionWallet,
      SettingsSection.transactions => l.settingsSectionTransactions,
      SettingsSection.display => l.settingsSectionDisplay,
      SettingsSection.advanced => l.advTitle,
      SettingsSection.about => l.settingsSectionAbout,
    };

/// The group's glyph on the hub.
IconData settingsSectionIcon(SettingsSection section) => switch (section) {
  SettingsSection.security => Icons.shield_outlined,
  SettingsSection.privacyNetwork => Icons.hub_outlined,
  SettingsSection.wallet => Icons.account_balance_wallet_outlined,
  SettingsSection.transactions => Icons.swap_horiz,
  SettingsSection.display => Icons.tune,
  SettingsSection.advanced => Icons.terminal,
  SettingsSection.about => Icons.info_outline,
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
  AdvancedFeature.invoices => l.expInvoices,
  AdvancedFeature.linkedDevices => l.expLinkedDevices,
};

/// The key of the Privacy header on the Privacy & network page, for tests.
const Key settingsPrivacyKey = ValueKey('settings-privacy');

/// The Node and Epicbox rows of Privacy & network, for tests: the status card's rows while a
/// wallet is open, the plain rows otherwise.
const Key settingsNodeKey = netStatusNodeKey;
const Key settingsEpicboxKey = netStatusEpicboxKey;

/// The key of the Node failover switch on the Advanced page, for tests.
const Key advNodeFailoverKey = ValueKey('adv-nodeFailover');

/// The key of the Licences row in About, for tests.
const Key settingsLicencesKey = ValueKey('settings-licences');

/// The key of a section page's scaffold, for tests: `settingsSectionKey(SettingsSection.x)`.
Key settingsSectionKey(SettingsSection section) =>
    ValueKey('settings-section-${section.name}');

/// Opens [section]'s page over the current route.
Future<void> openSettingsSection(BuildContext context, SettingsSection section, {bool toExperimental = false, bool toNetwork = false}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsSectionScreen(section: section, toExperimental: toExperimental, toNetwork: toNetwork),
      ),
    );

/// One group's page: its rows under the group's title, with the actions they need.
class SettingsSectionScreen extends ConsumerStatefulWidget {
  const SettingsSectionScreen({super.key, required this.section, this.toExperimental = false, this.toNetwork = false});

  final SettingsSection section;

  /// Advanced opened from an "experimental" sheet: scrolled to the Pairing and Invoices
  /// switches, not its top (LNX3-1).
  final bool toExperimental;

  /// Advanced opened from the mode mark or an Off (mode) status: scrolled to the Network
  /// section.
  final bool toNetwork;

  @override
  ConsumerState<SettingsSectionScreen> createState() =>
      _SettingsSectionScreenState();
}

class _SettingsSectionScreenState extends ConsumerState<SettingsSectionScreen> {
  bool _busy = false;
  final _scroll = ScrollController();
  final _experimentalKey = GlobalKey();
  final _networkKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.toExperimental) WidgetsBinding.instance.addPostFrameCallback((_) => _showExperimental());
    if (widget.toNetwork) WidgetsBinding.instance.addPostFrameCallback((_) => _showNetwork());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The group sits near the end of a lazy list: towards the end first, so it is built, then
  /// it to the top.
  void _showExperimental([int tries = 0]) {
    if (!mounted || !_scroll.hasClients) return;
    final at = _experimentalKey.currentContext;
    if (at == null) {
      if (tries > 2) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) => _showExperimental(tries + 1));
      return;
    }
    Scrollable.ensureVisible(at, alignment: 0);
  }

  /// The Network section sits in the middle of the list: the list is built that far first.
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

  Future<T?> _choose<T>({
    required String title,
    required List<({T value, String label})> options,
    required T current,
    Widget? Function(T value)? leadingOf,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          RadioGroup<T>(
            groupValue: current,
            onChanged: (value) => Navigator.pop(context, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in options)
                  RadioListTile<T>(
                    value: option.value,
                    title: Text(option.label),
                    secondary: leadingOf?.call(option.value),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Display.

  Future<void> _pickCurrency(AppSettings s) async {
    final l = context.l10n;
    final code = await _choose(
      title: l.settingsCurrency,
      current: s.fiatCurrency,
      options: [
        for (final c in fiatCurrencies) (value: c, label: currencyLabel(l, c)),
      ],
    );
    if (code != null) await _settings.setFiatCurrency(code);
  }

  Future<void> _pickTheme(AppSettings s) async {
    final l = context.l10n;
    final mode = await _choose(
      title: l.settingsTheme,
      current: s.themeMode,
      options: [
        for (final m in ThemeMode.values) (value: m, label: themeLabel(l, m)),
      ],
    );
    if (mode != null) await _settings.setThemeMode(mode);
  }

  Future<void> _pickLanguage(AppSettings s) async {
    // A sentinel, because the dialog returns null when dismissed and null also means the
    // system's language.
    const system = '';
    final code = await _choose<String>(
      title: context.l10n.languageSetting,
      current: s.language ?? system,
      options: [
        (value: system, label: context.l10n.languageSystem),
        for (final a in appLanguages) (value: a.code, label: a.name),
      ],
      // The system row gets a neutral globe, as wide as a flag, so the names line up.
      leadingOf: (code) => code == system
          ? SizedBox(
              width: 16 * 4 / 3,
              child: Icon(
                Icons.language,
                size: 16,
                color: context.tokens.dim,
              ),
            )
          : LanguageFlag(code),
    );
    if (code != null) {
      await _settings.setLanguage(code == system ? null : code);
    }
  }

  Future<void> _setShowFiat(bool on) async {
    await _settings.setShowFiat(on);
    if (on && mounted) {
      _say(context.l10n.settingsPricesOnNotice, level: NoticeLevel.info);
    }
  }

  // Security.

  Future<void> _pickAutoLock(AppSettings s) async {
    final l = context.l10n;
    // A sentinel, because the dialog returns null when dismissed and null also means never.
    const never = -1;
    final current = s.autoLockMinutes;
    final minutes = await _choose<int>(
      title: l.settingsAutoLock,
      current: current == null ? never : autoLockChoice(current),
      options: [
        for (final m in autoLockChoices) (value: m, label: autoLockLabel(l, m)),
        (value: never, label: autoLockLabel(l, null)),
      ],
    );
    if (minutes != null) {
      await _settings.setAutoLockMinutes(minutes == never ? null : minutes);
    }
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
        reason: context.l10n.settingsBiometricsPinReason,
        allowBiometrics: false,
        action: (pin) => vault.enableBiometrics(session, config, pin),
      );
      if (ok == null) return;
      if (mounted) {
        final l = context.l10n;
        if (ok) {
          _say(l.settingsBiometricsOn, level: NoticeLevel.success);
        } else {
          _say(l.settingsBiometricsFailed, level: NoticeLevel.error);
        }
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
    final start = await showDialog<BigInt>(
      context: context,
      builder: (_) => _RescanDialog(
        datesSupported: chain == Chain.mainnet,
        // Advanced › Recheck from a height: without it the dialog only confirms.
        choice: AdvancedOptions.has(context, AdvancedFeature.recheckFromHeight),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteWalletDialog(),
    );
    if (confirmed != true || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final vault = ref.read(vaultProvider);
    final checked = await askPin(
      context,
      reason: context.l10n.settingsDeletePinReason,
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
    await _run(() async {
      try {
        await deleteWalletEverywhere(ref, config);
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scan = ref.watch(scanProvider);
    final rows = switch (widget.section) {
      SettingsSection.security => _security(l),
      SettingsSection.privacyNetwork => _privacyNetwork(l),
      SettingsSection.wallet => _wallet(l),
      SettingsSection.transactions => _transactions(l),
      SettingsSection.display => _display(l),
      SettingsSection.advanced => _advanced(l),
      SettingsSection.about => _about(l),
    };
    return SlotScaffold(
      key: settingsSectionKey(widget.section),
      // A running scan shows in the slot. `_busy` shows nothing: most of its time is spent
      // waiting on a sheet or dialog, where a progress bar would say the wrong thing.
      idle: scan.running ? ScanSlotLine(scan: scan) : null,
      appBar: AppBar(title: Text(settingsSectionTitle(l, widget.section))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Builder(
              builder: (context) => ListView(
              controller: _scroll,
              padding: DockSlack.pad(context, const EdgeInsets.only(top: 8, bottom: 24)),
              children: [
                if (!scan.running && scan.error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ErrorText(describeError(l, scan.error!)),
                  ),
                ...rows,
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  /// Security: the phrase first (the one thing that guards the funds), then how the wallet
  /// unlocks, then Lock wallet on its own at the end.
  List<Widget> _security(AppLocalizations l) {
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final biometrics = ref.watch(biometricsProvider).value;
    final demo = ref.watch(demoModeProvider);
    final backedUp = ref.watch(backedUpProvider).value ?? true;
    final t = context.tokens;
    return [
      if (!demo)
        ListTile(
          leading: const Icon(Icons.key),
          title: Text(l.settingsBackupPhrase),
          // The one state that matters here: not done yet, in the warning colour.
          subtitle: backedUp
              ? null
              : Text(
                  l.settingsStateNotBackedUp,
                  style: TextStyle(color: t.warn),
                ),
          onTap: _showPhrase,
        ),
      ListTile(
        leading: const Icon(Icons.lock_clock),
        title: Text(l.settingsAutoLock),
        subtitle: Text(autoLockLabel(l, s.autoLockMinutes)),
        onTap: () => _pickAutoLock(s),
      ),
      // The demo wallet opens with the demo PIN, filled in; another would lock the visitor
      // out.
      if (!demo)
        ListTile(
          leading: const Icon(Icons.pin),
          title: Text(l.settingsChangePin),
          onTap: () => _push(const ChangePinScreen()),
        ),
      if (!demo && (biometrics?.available ?? false))
        SwitchListTile(
          secondary: const Icon(Icons.fingerprint),
          title: Text(l.settingsBiometrics),
          value: biometrics!.enabled,
          onChanged: _setBiometrics,
        ),
      const Divider(height: 24),
      ListTile(
        leading: const Icon(Icons.lock),
        title: Text(l.settingsLockWallet),
        onTap: () => lockWallet(context, ref),
      ),
    ];
  }

  /// Privacy & network: the status card from Home first (its rows open the pickers), then the
  /// one Tor switch, the status site, and the servers.
  List<Widget> _privacyNetwork(AppLocalizations l) {
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final walletOpen = ref.watch(sessionProvider) != null;
    final torAvailable = ref.watch(phoneTorProvider.select(torShown));
    final torState = phoneTorState(ref.watch(phoneTorProvider));
    // The switch left on without a tor bundle blocks the wallet (fail closed): it stays in
    // view so it can be turned off.
    final torBlocking = ref.watch(
      phoneTorProvider.select((t) => t.phase == PhoneTorPhase.unavailable && phoneTorState(t) == TorState.failed),
    );
    final config = ref.watch(walletConfigProvider);
    final network = ref.watch(networkChoiceProvider).value;
    final demo = ref.watch(demoModeProvider);
    final devNetworks = ref.watch(devNetworksProvider);
    final advanced = AdvancedOptions.of(context);
    final chain = config == null ? l.commonUnknown : chainName(l, config.chain);
    // One row per thing (26.10.11): Node and Epicbox with their host and health, each
    // opening its picker (the status card's rows, the same pickers as the icons on Home), the
    // Tor switch, then the other privacy settings. With no wallet open there is no health to
    // show: plain rows open the same pickers.
    return [
      if (walletOpen)
        const PhoneTourTarget(
          id: 'tour-privacy-servers',
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: NetworkStatusCard(showTor: false),
          ),
        )
      else if (!demo) ...[
        ListTile(
          key: settingsNodeKey,
          leading: const Icon(EpicGlyphs.node),
          title: Text(l.serverNodeTitle),
          subtitle: withTorWay(
            network == null ? null : Text(serverHost(network.nodeUrl)),
            nodeTorWay(network?.nodeUrl, torState),
          ),
          onTap: () => showNodePicker(context),
        ),
        ListTile(
          key: settingsEpicboxKey,
          leading: const Icon(EpicGlyphs.epicbox),
          title: Text(l.serverEpicboxTitle),
          subtitle: withTorWay(
            Text(
              network?.relay.label ??
                  (config == null
                      ? l.commonUnknown
                      : EpicboxRelay(
                          host: config.epicboxDomain,
                          port: config.epicboxPort,
                        ).label),
            ),
            torWay(TorRoute.epicbox, torState),
          ),
          onTap: () => showEpicboxPicker(context),
        ),
      ],
      // The one Tor switch (phoneTorProvider): Send, Receive and the status card read its
      // state; it moves nothing the user chose.
      SettingsHeader(l.settingsSectionPrivacy, key: settingsPrivacyKey),
      if (walletOpen && (torAvailable || torBlocking))
        const PhoneTourTarget(id: 'tour-privacy-tor', child: TorSwitchTile()),
      // No status site in app-config.toml: no switch.
      if (statusSiteConfigured)
      HintSwitchTile(
        icon: Icons.travel_explore,
        title: l.settingsUseStatusSite(statusSiteHost),
        hint: l.settingsUseStatusSiteSubtitle,
        value: s.useStatusSite,
        onChanged: _settings.setUseStatusSite,
      ),
      // Development builds only: the network itself, each with its own wallet.
      if (!demo && advanced.has(AdvancedFeature.serverDetails) && devNetworks)
        ListTile(
          leading: const Icon(Icons.hub),
          title: Text(l.settingsAboutNetwork),
          subtitle: Text(chain),
          onTap: () => showNetworkChooser(context),
        ),
    ];
  }

  /// Wallet: the everyday lists, the history files, the technical recheck, and Delete at the
  /// end on its own.
  List<Widget> _wallet(AppLocalizations l) {
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final walletOpen = ref.watch(sessionProvider) != null;
    final scan = ref.watch(scanProvider);
    final demo = ref.watch(demoModeProvider);
    // Invoices only on a core that has them (UP-14); until then no entry at all.
    final invoices = ref.watch(invoicesShownProvider);
    final outputs = walletOpen ? ref.watch(walletOutputsProvider).value : null;
    final outputsSubtitle = outputs == null
        ? null
        : Text(
            l.outputsSettingsSubtitle(
              outputs.where((o) => outputWord(o) != OutputLabel.spent).length,
              s.sendStrategy == SelectionStrategy.smallest
                  ? l.outputsSmallest
                  : l.outputsAll,
            ),
          );
    final error = Theme.of(context).colorScheme.error;
    // Recheck balance asks the node only: Node only lets it run.
    final block = watchNetBlock(context, ref, node: true);
    return [
      ListTile(
        leading: const Icon(Icons.contacts_outlined),
        title: Text(l.settingsContacts),
        onTap: () => _push(const ContactsScreen()),
      ),
      // Advanced › Outputs; a split or consolidation mid-way keeps the row (never hide what is
      // in use).
      if (outputsShown(context, ref))
        ListTile(
          leading: const Icon(Icons.grain),
          title: Text(l.outputsTitle),
          subtitle: outputsSubtitle,
          onTap: () => _push(const OutputsScreen()),
        ),
      if (invoices)
        ListTile(
          leading: const Icon(Icons.request_quote_outlined),
          title: TitleWithHint(
            l.settingsInvoices,
            hint: l.invSetLead,
            icon: Icons.request_quote_outlined,
          ),
          subtitle: Text(l.settingsInvoicesSubtitle),
          onTap: () => _push(const InvoiceSettingsScreen()),
        ),
      // Linked devices (Experimental, on unless turned off): the state line names the device
      // seen last.
      if (walletOpen && ref.watch(linkedDevicesOnProvider))
        ListTile(
          key: settingsLinkedDevicesKey,
          leading: const Icon(Icons.devices_outlined),
          title: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [Text(l.expLinkedDevices), EBadge(l.advExperimental)],
          ),
          subtitle: Text(devicesStateLine(l, ref.watch(phoneDevices.devices), ref.watch(clockProvider)())),
          onTap: () => _push(const LinkedDevicesScreen()),
        ),
      if (!demo) ...[
        SettingsHeader(l.settingsSectionHistory),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: TitleWithHint(
            l.settingsExportHistory,
            hint: '${l.backupFileHolds} ${l.backupFileRestoreOrder}',
            icon: Icons.upload_file,
          ),
          onTap: _busy
              ? null
              : () => _run(() => exportHistoryBackup(context, ref)),
        ),
        ListTile(
          leading: const Icon(Icons.table_view),
          title: Text(l.settingsExportCsv),
          onTap: _busy ? null : () => _run(() => exportHistoryCsv(context, ref)),
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: TitleWithHint(
            l.settingsImportHistory,
            hint: l.backupImportLead,
            icon: Icons.download,
          ),
          onTap: _busy
              ? null
              : () => _run(() => importHistoryBackup(context, ref)),
        ),
      ],
      // Recheck balance is the fix for a wrong balance: for everyone. From a height is Advanced.
      // It reads the chain, so it waits for the network.
      if (!demo)
        ListTile(
          leading: const Icon(Icons.sync),
          title: Text(l.settingsRescan),
          subtitle: block == NetBlock.none
              ? null
              : Text(block == NetBlock.killSwitch ? l.recheckOffKill : netBlockReason(l, block)!),
          enabled: !scan.running && block == NetBlock.none,
          onTap: block == NetBlock.none ? _rescan : null,
        ),
      const Divider(height: 24),
      // Restore from a phrase replaces this wallet (one per network), so it sits with Delete
      // and goes through its warning and PIN once the phrase checks out. Help names this place.
      if (!demo)
        ListTile(
          key: settingsRestoreKey,
          leading: const Icon(Icons.restore),
          title: Text(l.firstRunRestore),
          enabled: !_busy,
          onTap: _restoreFromPhrase,
        ),
      ListTile(
        leading: Icon(Icons.delete_forever, color: error),
        title: Text(
          demo ? l.demoEnd : l.settingsDeleteWallet,
          style: TextStyle(color: error),
        ),
        enabled: !_busy,
        onTap: demo ? () => _run(() => endDemo(context, ref)) : _deleteWallet,
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
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = context.l10n;
        return AlertDialog(
          title: Text(l.txEpicboxOffTitle),
          content: Text(l.txEpicboxOffPending(waiting)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.txEpicboxOffAction)),
          ],
        );
      },
    );
    return yes == true;
  }

  /// Transactions: how payments are made. The methods Send and Receive offer, one switch each,
  /// grouped by family (Epicbox; Link › HTTP, Tor; Direct › QR Payment, File Transfer), the one
  /// Send starts on, and, with Advanced › Send options, the defaults a send uses (which outputs
  /// it spends and whether its change is split).
  List<Widget> _transactions(AppLocalizations l) {
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final payments = s.payments;
    final torAvailable = ref.watch(phoneTorProvider.select(torShown));
    final torOff = ref.watch(phoneTorProvider.select((t) => t.settled && !t.receiving));
    // Send options on shows the defaults; one that is not at its default stays (never hide a
    // choice in use), as Outputs did before they moved here.
    final showDefaults = _txDefaultsShown |=
        s.advanced.has(AdvancedFeature.sendOptions) ||
        s.sendStrategy != SelectionStrategy.smallest ||
        !s.splitChange;
    // Link · HTTP works on any phone (this Wi-Fi network); Link · Tor needs Tor, so where the
    // app has none (and the switch is off) there is nothing to turn on.
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
      MethodKind.epicbox || MethodKind.linkHttp => true,
      MethodKind.linkTor => showTor,
      MethodKind.directQr => phone,
      MethodKind.directFile => showFile,
    };
    // Send starts on: the methods on, Link once for the family (the address picks HTTP or
    // Tor), on the one Send would open on.
    final start = payments.startMethod;
    final offered = <MethodKind>[];
    for (final m in payments.on) {
      if (!shown(m)) continue;
      if (m.family == MethodFamily.link) {
        if (offered.any((o) => o.family == MethodFamily.link)) continue;
        offered.add(start.family == MethodFamily.link ? start : m);
      } else {
        offered.add(m);
      }
    }
    String startName(MethodKind m) =>
        m.family == MethodFamily.link ? l.methodDirect : MethodIcons.fullName(l, m);
    Future<void> save(PaymentPrefs next) => _settings.setPayments(next);
    // The last method on stays on: Send and Receive always keep a way. The switch does not
    // move; the notice says why.
    Future<void> set(MethodKind m, bool on) async {
      if (!on && !payments.canTurnOff(m)) {
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

    // The row is the label only; what the method does is behind its info icon.
    Widget methodTile(MethodKind m) {
      final hint = switch (m) {
        MethodKind.epicbox => l.txEpicboxHint,
        MethodKind.linkHttp => torBuilt ? l.txLinkHttpHint('${appConfig.httpListenPort}') : l.txLinkHttpHintNoTor('${appConfig.httpListenPort}'),
        MethodKind.linkTor => l.txLinkTorHint,
        MethodKind.directQr => l.txQrHint,
        MethodKind.directFile => l.txFileHint,
      };
      return HintSwitchTile(
        key: txMethodKey(m),
        icon: MethodIcons.of(m),
        title: MethodIcons.groupName(l, m),
        sheetTitle: MethodIcons.fullName(l, m),
        hint: hint,
        value: payments.offers(m),
        onChanged: (on) => set(m, on),
      );
    }

    return [
      SettingsHeader(l.txMethodsHeader),
      for (final f in MethodFamily.values) ...[
        // Epicbox is a family of one: its row stands alone.
        if (f != MethodFamily.epicbox) _MethodFamilyHeader(f),
        for (final m in MethodKind.values)
          if (m.family == f && shown(m)) ...[
            methodTile(m),
            if (m == MethodKind.linkTor && payments.linkTor && torOff)
              _TorNeededLine(onTap: () => openPrivacySettings(context)),
          ],
      ],
      // Only a choice when there is one: a single method is what Send opens on.
      if (offered.length > 1) ...[
        SettingsHeader(l.txStartHeader),
        RadioGroup<MethodKind>(
          groupValue: start,
          onChanged: (m) {
            if (m != null) save(payments.copyWith(defaultMethod: m));
          },
          child: Column(
            children: [
              for (final m in offered)
                RadioListTile<MethodKind>(
                  key: txStartKey(m),
                  value: m,
                  secondary: Icon(
                    m.family == MethodFamily.link
                        ? MethodIcons.family(MethodFamily.link)
                        : MethodIcons.of(m),
                  ),
                  title: Text(startName(m)),
                ),
            ],
          ),
        ),
      ],
      if (showDefaults) ...[
        SettingsHeader(l.txDefaultsHeader),
        ListTile(
          key: const ValueKey('tx-strategy'),
          leading: const Icon(Icons.tune),
          title: TitleWithHint(
            l.outputsStrategy,
            hint: l.outputsStrategyHint,
            icon: Icons.tune,
          ),
          subtitle: Text(
            s.sendStrategy == SelectionStrategy.smallest
                ? l.outputsSmallest
                : l.outputsAll,
          ),
          onTap: () => _pickStrategy(s.sendStrategy),
        ),
        HintSwitchTile(
          key: const ValueKey('tx-split'),
          icon: Icons.call_split,
          title: l.outputsSplitChange,
          hint: l.outputsSplitChangeText,
          value: s.splitChange,
          onChanged: _settings.setSplitChange,
        ),
      ],
    ];
  }

  /// The strategy a send spends outputs by: the two choices, each with its one line.
  Future<void> _pickStrategy(SelectionStrategy current) async {
    final l = context.l10n;
    final picked = await showModalBottomSheet<SelectionStrategy>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final strategy in SelectionStrategy.values)
              Semantics(
                inMutuallyExclusiveGroup: true,
                checked: strategy == current,
                child: ListTile(
                  key: ValueKey('tx-strategy-${strategy.name}'),
                  minVerticalPadding: 12,
                  leading: Icon(
                    strategy == current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: strategy == current
                        ? context.tokens.accent
                        : context.tokens.dim,
                  ),
                  title: Text(
                    strategy == SelectionStrategy.smallest
                        ? l.outputsSmallest
                        : l.outputsAll,
                  ),
                  subtitle: Text(
                    strategy == SelectionStrategy.smallest
                        ? l.outputsSmallestText
                        : l.outputsAllText,
                  ),
                  onTap: () => Navigator.pop(context, strategy),
                ),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await _settings.setSendStrategy(picked);
  }

  /// Advanced: the switches that show more of the wallet, each explained in a sheet, and the
  /// one network mode. Nothing here is a value the simple path needs.
  List<Widget> _advanced(AppLocalizations l) {
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final adv = s.advanced;
    final t = context.tokens;
    Widget feature(
      AdvancedFeature f,
      IconData icon,
      String title,
      String hint,
    ) => HintSwitchTile(
      key: ValueKey('adv-${f.name}'),
      icon: icon,
      title: title,
      hint: hint,
      value: adv.has(f),
      onChanged: (on) => _settings.setFeature(f, on),
    );
    // Pairing and Invoices: on as the rule between them says; an Experimental tag on each.
    Widget experimental(AdvancedFeature f, IconData icon, String title, String hint) => HintSwitchTile(
      key: ValueKey('adv-${f.name}'),
      icon: icon,
      title: title,
      hint: hint,
      subtitle: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [EBadge(l.advExperimental)]),
      ),
      value: switch (f) {
        AdvancedFeature.pairing => adv.pairingOn,
        AdvancedFeature.invoices => adv.invoicesOn,
        _ => adv.has(f),
      },
      onChanged: (on) => _settings.setExperimental(f, on),
    );
    return [
      PhoneTourTarget(
        id: 'tour-advanced-top',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            l.advIntro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.dim),
          ),
        ),
      ),
      SettingsHeader(
        l.advShowsHeader,
        // As on the desktop: the way back sits in the section's header (GP-038).
        trailing: adv.shownFeatures.isEmpty
            ? null
            : TextButton(
                key: const ValueKey('adv-reset'),
                onPressed: () => _settings.setAdvanced(adv.withoutShown()),
                child: Text(l.advReset),
              ),
      ),
      feature(AdvancedFeature.outputs, Icons.grain, l.advOutputs, l.advOutputsHint),
      feature(
        AdvancedFeature.technicalDetails,
        Icons.data_object,
        l.advTechnical,
        l.advTechnicalHint,
      ),
      feature(
        AdvancedFeature.sendOptions,
        Icons.call_split,
        l.advSendOptions,
        l.advSendOptionsHint,
      ),
      feature(
        AdvancedFeature.serverDetails,
        EpicGlyphs.node,
        l.advServerDetails,
        l.advServerDetailsHint,
      ),
      feature(
        AdvancedFeature.recheckFromHeight,
        Icons.sync,
        l.advRecheckHeight,
        l.advRecheckHeightHint,
      ),
      feature(
        AdvancedFeature.transactionFiles,
        Icons.description_outlined,
        l.advTransactionFiles,
        l.advTransactionFilesHint,
      ),
      const SizedBox(height: 8),
      NetworkModeSection(
        headerKey: _networkKey,
        tourId: (rows) => PhoneTourTarget(id: 'tour-advanced-modes', child: rows),
      ),
      // On by default: the one switch here that keeps the simple app working.
      HintSwitchTile(
        key: advNodeFailoverKey,
        icon: Icons.alt_route,
        title: l.advNodeFailover,
        hint: l.advNodeFailoverHint,
        value: adv.nodeFailover,
        onChanged: _settings.setNodeFailover,
      ),
      // The wallet's own count, stored in the core: how long received coins wait.
      const SizedBox(height: 8),
      SettingsHeader(l.advBalanceHeader),
      const ConfirmationsRow(),
      // Experimental, so last: Pairing and Invoices (off by default).
      const SizedBox(height: 8),
      SettingsHeader(l.advExperimental, key: _experimentalKey),
      experimental(AdvancedFeature.pairing, Icons.handshake_outlined, l.expPairing, l.expPairingHint),
      experimental(AdvancedFeature.invoices, Icons.request_quote_outlined, l.expInvoices, l.expInvoicesHint),
      Padding(
        key: const ValueKey('adv-exp-rule'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          l.expNeedsPairing,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.dim),
        ),
      ),
      // Linked devices stands on its own: it runs the pairing engine for the devices only.
      experimental(AdvancedFeature.linkedDevices, Icons.devices_outlined, l.expLinkedDevices, l.expLinkedDevicesHint),
    ];
  }

  List<Widget> _display(AppLocalizations l) {
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    return [
      ListTile(
        leading: const Icon(Icons.brightness_6),
        title: Text(l.settingsTheme),
        subtitle: Text(themeLabel(l, s.themeMode)),
        onTap: () => _pickTheme(s),
      ),
      ListTile(
        leading: const Icon(Icons.language),
        title: Text(l.languageSetting),
        subtitle: Text(languageLabel(l, s.language)),
        onTap: () => _pickLanguage(s),
      ),
      SwitchListTile(
        secondary: const Icon(Icons.visibility_off),
        title: Text(l.settingsHideBalances),
        value: s.hideBalances,
        onChanged: _settings.setHideBalances,
      ),
      // No price source in app-config.toml, or `[online] price` off in settings.toml: no rows.
      if (pricesOffered(ref.watch(hostSettingsProvider))) ...[
        SwitchListTile(
          secondary: const Icon(Icons.show_chart),
          title: Text(l.settingsShowPrices),
          value: s.showFiat,
          onChanged: _setShowFiat,
        ),
        ListTile(
          leading: const Icon(Icons.attach_money),
          title: Text(l.settingsCurrency),
          subtitle: Text(currencyLabel(l, s.fiatCurrency)),
          enabled: s.showFiat,
          onTap: () => _pickCurrency(s),
        ),
      ],
    ];
  }

  /// About: the app, its version and updates, then the rare things: Licences and the links.
  /// Advanced is a hub row of its own.
  List<Widget> _about(AppLocalizations l) {
    final version = ref.watch(appVersionProvider);
    final demo = ref.watch(demoModeProvider);
    final updates = !demo && ref.read(updateProvider.notifier).supported;
    final block = watchNetBlock(context, ref);
    return [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: BrandLockup(variant: BrandVariant.mobile, size: 40),
      ),
      ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(l.settingsVersion),
        subtitle: Text(
          [
            version.hasValue ? version.value ?? l.commonUnknown : '…',
            // A store build: the store updates it, the app has no updater.
            if (distStore != null) l.settingsUpdatesFrom(distStore!),
          ].join('\n'),
        ),
      ),
      if (updates)
        ListTile(
          leading: const Icon(Icons.system_update),
          title: Text(l.settingsCheckUpdates),
          subtitle: block == NetBlock.none
              ? null
              : Text(
                  blockMode(block) != null ? l.updatesOffMode(networkModeName(l, blockMode(block)!)) : netBlockReason(l, block)!,
                ),
          enabled: block == NetBlock.none,
          onTap: block != NetBlock.none
              ? null
              : () {
                  ref.read(updateProvider.notifier).check();
                  // The result follows as a notice of its own.
                  _say(l.updateChecking, level: NoticeLevel.info);
                },
        ),
      // The short Licences screen; the full texts (the packages', the fonts', the word
      // lists' and the bundled tor's) are one tap further.
      ListTile(
        key: settingsLicencesKey,
        leading: const Icon(Icons.article_outlined),
        title: Text(l.settingsLicences),
        onTap: () => _push(LicencesScreen(version: version.value)),
      ),
      // A proper name, the same in every language.
      if (epicCashUrl case final site?) LinkTile(title: 'Epic Cash', url: site),
      if (projectRepoUrl != null) LinkTile(title: l.settingsSourceCode, url: projectRepoUrl!),
      if (privacyPolicyUrl case final url?) LinkTile(title: l.settingsPrivacyPolicy, url: url),
      if (supportEmail case final email?) LinkTile(title: l.contactLabel, url: email, email: true),
    ];
  }
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

/// [subtitle] with the [TorWayLine] under it while the Epicbox connection goes over Tor or
/// waits for it ([way]); [subtitle] alone otherwise.
Widget? withTorWay(Widget? subtitle, TorWay way) {
  if (way != TorWay.overTor && way != TorWay.wait && way != TorWay.blocked) {
    return subtitle;
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [?subtitle, const TorWayLine(route: TorRoute.epicbox)],
  );
}

/// A small header over a run of rows on a Settings page.
/// The Linked devices row on the Wallet page, for tests.
const Key settingsLinkedDevicesKey = ValueKey('settings-linked-devices');

class SettingsHeader extends StatelessWidget {
  const SettingsHeader(this.title, {super.key, this.trailing});

  final String title;

  /// A small action at the header's end (the desktop's "Hide everything again").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Neutral, as the desktop's section headers: gold is for the brand and the primary
    // action only.
    final text = Semantics(
      header: true,
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(color: context.tokens.dim),
      ),
    );
    if (trailing == null) {
      return Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 4), child: text);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
      child: Row(
        children: [
          Expanded(child: text),
          trailing!,
        ],
      ),
    );
  }
}

/// A family's subhead inside Payment methods (Settings › Transactions): its glyph and name,
/// and one line on what the family is, over its methods' switches.
class _MethodFamilyHeader extends StatelessWidget {
  const _MethodFamilyHeader(this.family);

  final MethodFamily family;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    return Padding(
      key: ValueKey('tx-family-${family.name}'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(MethodIcons.family(family), size: 18, color: t.dim),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    MethodIcons.familyName(context.l10n, family),
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The key of a method's switch on Settings › Transactions, for tests and the tour:
/// `tx-epicbox`, `tx-http`, `tx-tor`, `tx-qr`, `tx-file`.
Key txMethodKey(MethodKind m) => ValueKey('tx-${_txKeyName(m)}');

/// The key of a "Send starts on" choice, for tests: Link is one (`tx-start-link`).
Key txStartKey(MethodKind m) =>
    ValueKey('tx-start-${m.family == MethodFamily.link ? 'link' : _txKeyName(m)}');

String _txKeyName(MethodKind m) => switch (m) {
  MethodKind.epicbox => 'epicbox',
  MethodKind.linkHttp => 'http',
  MethodKind.linkTor => 'tor',
  MethodKind.directQr => 'qr',
  MethodKind.directFile => 'file',
};

/// The key of the line under Link · Tor that Tor is off, for tests.
const Key txTorNeededKey = ValueKey('tx-tor-needs-tor');

/// Under the Link · Tor switch while it is on and Tor is off: "Needs Tor. Turn it on under
/// Privacy & network." A tap opens Privacy & network, where the one Tor switch is.
class _TorNeededLine extends StatelessWidget {
  const _TorNeededLine({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.l10n.txLinkTorNeedsTor;
    return Semantics(
      key: txTorNeededKey,
      button: true,
      label: text,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          // Lined up with the switch's title, past its icon.
          padding: const EdgeInsets.fromLTRB(56, 0, 16, 10),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: t.info),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.info),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: t.info),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flutter's licence page under the app's name and [version]. The app writes British English
/// ("Licences", "Cancelled"), and Flutter's own strings for `en` are American ("Licenses"):
/// in English the page takes the `en_GB` Material strings so its title matches the row.
void openFlutterLicences(BuildContext context, String? version) {
  final locale = Localizations.localeOf(context);
  final page = LicensePage(
    applicationName: context.l10n.appTitle,
    applicationVersion: version,
  );
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => locale.languageCode == 'en'
          ? Localizations.override(
              context: context,
              locale: const Locale('en', 'GB'),
              child: page,
            )
          : page,
    ),
  );
}

/// A web link. The app has no browser launcher, so tapping copies the address.
class LinkTile extends StatelessWidget {
  const LinkTile({super.key, required this.title, required this.url, this.email = false});

  final String title;
  final String url;

  /// [url] is an email address: a mail icon, and the notice says the address was copied.
  final bool email;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListTile(
      leading: Icon(email ? Icons.mail_outline : Icons.link),
      title: Text(title),
      subtitle: Text(url),
      trailing: Icon(Icons.copy, semanticLabel: email ? l.settingsCopyAddress : l.settingsCopyLink),
      onTap: () => copyText(context, url, email ? l.settingsAddressCopied : l.settingsLinkCopied),
    );
  }
}

enum _RescanFrom { date, height, start }

/// Where a rescan starts. Pops the start height, or null when cancelled.
class _RescanDialog extends StatefulWidget {
  const _RescanDialog({required this.datesSupported, required this.choice});

  final bool datesSupported;

  /// Offer the start (a date, a height, the whole chain); else the whole chain without asking.
  final bool choice;

  @override
  State<_RescanDialog> createState() => _RescanDialogState();
}

class _RescanDialogState extends State<_RescanDialog> {
  late _RescanFrom _from = !widget.choice
      ? _RescanFrom.start
      : widget.datesSupported
      ? _RescanFrom.date
      : _RescanFrom.height;
  DateTime? _date;
  final _height = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _height.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: mainnetFirstDay,
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _start() {
    final l = context.l10n;
    final BigInt? start;
    switch (_from) {
      case _RescanFrom.date:
        final date = _date;
        if (date == null) {
          setState(() => _error = l.settingsRescanPickDateFirst);
          return;
        }
        start = mainnetHeightForDate(date);
      case _RescanFrom.height:
        final height = BigInt.tryParse(_height.text.trim());
        if (height == null || height < BigInt.one) {
          setState(() => _error = l.settingsRescanHeightInvalid);
          return;
        }
        start = height;
      // Block 0, not 1: only a scan from block 0 finishes a restore (restore_scan.dart), and
      // it goes on from where a stopped one of the same start left off.
      case _RescanFrom.start:
        start = BigInt.zero;
    }
    Navigator.pop(context, start);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final date = _date;
    return AlertDialog(
      title: Text(l.settingsRescanTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.choice ? l.settingsRescanBody : l.settingsRescanBodyPlain),
            const SizedBox(height: 8),
            if (widget.choice)
              RadioGroup<_RescanFrom>(
                groupValue: _from,
                onChanged: (value) => setState(() {
                  _from = value ?? _from;
                  _error = null;
                }),
                child: Column(
                  children: [
                    if (widget.datesSupported)
                      RadioListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _RescanFrom.date,
                        title: Text(l.settingsRescanFromDate),
                      ),
                    RadioListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _RescanFrom.height,
                      title: Text(l.settingsRescanFromHeight),
                    ),
                    RadioListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _RescanFrom.start,
                      title: Text(l.settingsRescanWholeChain),
                    ),
                  ],
                ),
              ),
            if (_from == _RescanFrom.date)
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  date == null ? l.settingsRescanPickDate : localDay(l, date),
                ),
                onPressed: _pickDate,
              ),
            if (_from == _RescanFrom.height)
              TextField(
                controller: _height,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l.settingsRescanStartHeight,
                  border: const OutlineInputBorder(),
                ),
              ),
            if (_error != null) ErrorText(_error!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(onPressed: _start, child: Text(l.settingsRescanButton)),
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
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      icon: Icon(
        Icons.warning_amber,
        color: error,
        semanticLabel: l.settingsDeleteWarningIcon,
      ),
      title: Text(l.settingsDeleteTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.restore) ...[
              Text(l.settingsRestoreReplaces),
              const SizedBox(height: 12),
            ],
            Text(l.settingsDeleteBody),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _understood,
              onChanged: (value) =>
                  setState(() => _understood = value ?? false),
              title: Text(l.settingsDeleteHavePhrase),
            ),
            TextField(
              controller: _word,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l.settingsDeleteTypeToConfirm(word),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.settingsDeleteKeep),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: error),
          onPressed: _ready(word) ? () => Navigator.pop(context, true) : null,
          child: Text(l.settingsDeleteConfirm),
        ),
      ],
    );
  }
}
