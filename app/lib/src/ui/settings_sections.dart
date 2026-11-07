// SPDX-License-Identifier: Apache-2.0
/// The phone's Settings pages, one per group of the hub (`settings_screen.dart`): Security,
/// Network & privacy, Wallet, Display and About. Each page is a short list of label-only rows
/// (an explanation sits behind an info icon, a value or a state on the row's second line), so
/// a page fits a 360 dp phone without a search. Help & feedback opens Help itself.
library;

import 'dart:async';

import 'phone_sheet.dart';
import '../address_format.dart' show shownUrl;
import 'address_view.dart' show HostText;
import '../seed_contacts.dart' show projectRepoUrl;
import 'package:flutter/material.dart';
import 'status_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_info.dart';
import '../app_log.dart';
import '../settings_file/host_settings.dart' show appConfig, hostSettings;
import '../dev_networks.dart';
import '../dist_build.dart';
import '../errors.dart';
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
import '../smart_outputs.dart' show OutputLabel, outputWord;
import '../tor_phone.dart';
import '../tor_routes.dart';
import '../trust_ids.dart';
import '../updater.dart';
import '../wallet_service.dart';
import 'app_dialog.dart';
import 'backup_screen.dart';
import 'common.dart';
import 'confirmations_row.dart';
import 'contacts_screen.dart';
import 'language_flag.dart';
import 'launch_screen.dart';
import 'level_step_screen.dart';
import 'levels/change_level_screen.dart';
import '../levels/level_features.dart' show AdvancedPageKind;
import '../levels/level_providers.dart' show currentLevelProvider, levelFeaturesProvider;
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
import 'restore_screen.dart' show RestoreScreen, ScanSlotLine;
import 'scan_start.dart';
import 'server_picker.dart' show showEpicboxPicker, showNodePicker;
import 'settings_history.dart';
import 'settings_invoices.dart';
import 'settings_pin.dart';
import 'settings_rows.dart';
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

/// The key of the Tor header on the Network & privacy page, for tests.
const Key settingsPrivacyKey = ValueKey('settings-privacy');

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

  Future<T?> _choose<T>({
    required String title,
    required IconData icon,
    required List<({T value, String label})> options,
    required T current,
    Widget? Function(T value)? leadingOf,
  }) {
    return showAppDialog<T>(
      context,
      builder: (context) => AppDialog(
        title: title,
        icon: icon,
        body: RadioGroup<T>(
          groupValue: current,
          onChanged: (value) => Navigator.pop(context, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in options)
                RadioRow<T>(
                  value: option.value,
                  title: option.label,
                  leading: leadingOf?.call(option.value),
                ),
            ],
          ),
        ),
        actions: [
          DialogButton.secondary(label: context.l10n.commonCancel, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  // Display.

  Future<void> _pickCurrency(AppSettings s) async {
    final l = context.l10n;
    final code = await _choose(
      title: l.settingsCurrency,
      icon: Icons.payments_outlined,
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
      icon: Icons.palette_outlined,
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
      icon: Icons.translate,
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
      icon: Icons.lock_clock_outlined,
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
    final backedUp = ref.watch(backedUpProvider).value ?? true;
    final t = context.tokens;
    return [
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
        trailing: const NavChevron(),
        onTap: _showPhrase,
      ),
      ListTile(
        leading: const Icon(Icons.lock_clock),
        title: Text(l.settingsAutoLock),
        subtitle: Text(autoLockLabel(l, s.autoLockMinutes)),
        onTap: () => _pickAutoLock(s),
      ),
      if (!previewNoLock) ListTile(
        leading: const Icon(Icons.pin),
        title: Text(l.settingsChangePin),
        trailing: const NavChevron(),
        onTap: () => _push(const ChangePinScreen()),
      ),
      // Optional: a passphrase in place of the 6-digit PIN (WAL-03). Change PIN goes back to a PIN.
      if (!previewNoLock) ListTile(
        leading: const Icon(Icons.password),
        title: Text(
          ref.watch(usesPassphraseProvider).value ?? false
              ? l.settingsChangePassphrase
              : l.settingsUsePassphrase,
        ),
        trailing: const NavChevron(),
        onTap: () => _push(const ChangePinScreen(passphrase: true)),
      ),
      if (biometrics?.available ?? false)
        HintSwitchTile(
          icon: Icons.fingerprint,
          title: l.settingsBiometrics,
          value: biometrics!.enabled,
          onChanged: _setBiometrics,
        ),
      if (!previewNoLock) ...[
        const Divider(height: 24),
        ListTile(
          leading: const Icon(Icons.lock),
          title: Text(l.settingsLockWallet),
          onTap: () => lockWallet(context, ref),
        ),
      ],
    ];
  }

  /// Network & privacy: the servers first (Epicbox, then Node, the status card from Home with
  /// its rows opening the pickers), Node failover under them, then the network mode (Tor only
  /// is the one whole-wallet Tor control) and the status site.
  List<Widget> _privacyNetwork(AppLocalizations l) {
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final walletOpen = ref.watch(sessionProvider) != null;
    final torState = phoneTorState(ref.watch(phoneTorProvider));
    final config = ref.watch(walletConfigProvider);
    final network = ref.watch(networkChoiceProvider).value;
    final devNetworks = ref.watch(devNetworksProvider);
    final advanced = AdvancedOptions.of(context);
    final chain = config == null ? l.commonUnknown : chainName(l, config.chain);
    // Level 2 and up (the levels that had Advanced's Network section): the mode and failover.
    final networkShown = ref.watch(levelFeaturesProvider).serverSettings;
    final adv = s.advanced;
    // One page for how the wallet reaches the network (B-03): the servers (Epicbox and Node
    // with their host and health, each opening its picker; with no wallet open, plain rows
    // open the same pickers), Node failover, the mode, then the status site.
    return [
      SettingsHeader(l.netPageServers, key: settingsServersKey),
      if (walletOpen)
        const PhoneTourTarget(
          id: 'tour-privacy-servers',
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: NetworkStatusCard(showTor: false),
          ),
        )
      else ...[
        ListTile(
          key: settingsEpicboxKey,
          leading: const Icon(EpicGlyphs.epicbox),
          title: Text(l.serverEpicboxTitle),
          subtitle: withTorWay(
            switch (network?.relay.label ??
                (config == null ? null : EpicboxRelay(host: config.epicboxDomain, port: config.epicboxPort).label)) {
              final host? => HostText(host, style: TextStyle(color: context.tokens.dim)),
              null => Text(l.commonUnknown),
            },
            torWay(TorRoute.epicbox, torState),
          ),
          onTap: () => showEpicboxPicker(context),
        ),
        ListTile(
          key: settingsNodeKey,
          leading: const Icon(EpicGlyphs.node),
          title: Text(l.serverNodeTitle),
          subtitle: withTorWay(
            network == null ? null : HostText(serverHost(network.nodeUrl), style: TextStyle(color: context.tokens.dim)),
            nodeTorWay(network?.nodeUrl, torState),
          ),
          onTap: () => showNodePicker(context),
        ),
      ],
      // On by default: the one switch here that keeps the simple app working.
      if (networkShown)
        HintSwitchTile(
          key: advNodeFailoverKey,
          icon: Icons.alt_route,
          title: l.advNodeFailover,
          hint: l.advNodeFailoverHint,
          value: adv.nodeFailover,
          onChanged: _settings.setNodeFailover,
        ),
      if (networkShown)
        NetworkModeSection(
          headerKey: _networkKey,
          tourId: (rows) => PhoneTourTarget(id: 'tour-privacy-modes', child: rows),
        ),
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
      if (advanced.has(AdvancedFeature.serverDetails) && devNetworks)
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
        trailing: const NavChevron(),
        onTap: () => _push(const ContactsScreen()),
      ),
      // Advanced › Outputs; a split or consolidation mid-way keeps the row (never hide what is
      // in use).
      if (outputsShown(context, ref))
        ListTile(
          leading: const Icon(Icons.grain),
          title: Text(l.outputsTitle),
          subtitle: outputsSubtitle,
          trailing: const NavChevron(),
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
          trailing: const NavChevron(),
          onTap: () => _push(const InvoiceSettingsScreen()),
        ),
      // Linked devices is a hub row of its own (item 10).
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
      // Recheck balance is the fix for a wrong balance: for everyone. From a height is Advanced.
      // It reads the chain, so it waits for the network.
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
      ListTile(
        key: settingsRestoreKey,
        leading: const Icon(Icons.restore),
        title: Text(l.firstRunRestore),
        enabled: !_busy,
        trailing: const NavChevron(),
        onTap: _restoreFromPhrase,
      ),
      ListTile(
        leading: Icon(Icons.delete_forever, color: error),
        title: Text(l.settingsDeleteWallet, style: TextStyle(color: error)),
        enabled: !_busy,
        onTap: _deleteWallet,
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

  /// Transactions: how payments are made. The methods Send and Receive offer, one switch each,
  /// grouped by family (Epicbox; Link › HTTP, Tor; Direct › QR Payment, File Transfer), the one
  /// Send starts on, and, with Advanced › Send options, the defaults a send uses (which outputs
  /// it spends and whether its change is split).
  List<Widget> _transactions(AppLocalizations l) {
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final payments = s.payments;
    final torAvailable = ref.watch(phoneTorProvider.select(torShown));
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
    // The desktop's list in the short names (UD-031): Epicbox, Link, Direct · QR, Direct · File.
    String startName(MethodKind m) =>
        m.family == MethodFamily.link ? MethodIcons.familyName(l, MethodFamily.link) : MethodIcons.shortName(l, m);
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

    // The row is the label only; what the method does is behind its info icon.
    Widget methodTile(MethodKind m) {
      final hint = switch (m) {
        MethodKind.epicbox => l.txEpicboxHint,
        MethodKind.linkHttp => torBuilt ? l.txLinkHttpHint('${appConfig.httpListenPort}') : l.txLinkHttpHintNoTor('${appConfig.httpListenPort}'),
        MethodKind.linkTor => l.deskSetRowTorPayInfo,
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
        onChanged: m == MethodKind.linkTor && !torPayCanSwitch(ref.watch(phoneTorPayProvider)) ? null : (on) => set(m, on),
      );
    }

    return [
      SettingsHeader(l.txMethodsHeader),
      for (final f in MethodFamily.values) ...[
        // Epicbox is a family of one: its row stands alone.
        if (f != MethodFamily.epicbox)
          SettingsSubHeader(
            MethodIcons.familyName(l, f),
            key: ValueKey('tx-family-${f.name}'),
            icon: MethodIcons.family(f),
          ),
        for (final m in MethodKind.values)
          if (m.family == f && shown(m)) ...[
            methodTile(m),
            // Tor for payments (item 2): its state, never a "turn Tor on" card.
            if (m == MethodKind.linkTor && payments.linkTor) const _TorPayLine(),
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
                RadioRow<MethodKind>(
                  key: txStartKey(m),
                  value: m,
                  icon: m.family == MethodFamily.link
                      ? MethodIcons.family(MethodFamily.link)
                      : MethodIcons.of(m),
                  title: startName(m),
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
    final picked = await showPhoneSheet<SelectionStrategy>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: RadioGroup<SelectionStrategy>(
          groupValue: current,
          onChanged: (strategy) => Navigator.pop(context, strategy),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final strategy in SelectionStrategy.values)
                RadioRow<SelectionStrategy>(
                  key: ValueKey('tx-strategy-${strategy.name}'),
                  value: strategy,
                  title: strategy == SelectionStrategy.smallest ? l.outputsSmallest : l.outputsAll,
                  subtitle: strategy == SelectionStrategy.smallest ? l.outputsSmallestText : l.outputsAllText,
                ),
            ],
          ),
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
    ) {
      final tile = HintSwitchTile(
        key: ValueKey('adv-${f.name}'),
        icon: icon,
        title: title,
        hint: hint,
        value: adv.has(f),
        onChanged: (on) => _settings.setFeature(f, on),
      );
      return f == AdvancedFeature.technicalDetails ? trustId(TrustIds.advancedTechnical, tile) : tile;
    }
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
        AdvancedFeature.invoices => adv.invoicesOn,
        _ => adv.has(f),
      },
      onChanged: (on) => _settings.setExperimental(f, on),
    );
    return [
      trustId(
        TrustIds.advancedLevel,
        ListTile(
          key: const ValueKey('adv-level'),
          leading: const Icon(Icons.tune),
          title: Text(l.levelRowTitle),
          subtitle: Text(levelTitle(l, ref.watch(currentLevelProvider))),
          trailing: const NavChevron(),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChangeLevelScreen())),
        ),
      ),
      // Level 1: the level row alone, and what more levels do.
      if (ref.watch(levelFeaturesProvider).advancedPage == AdvancedPageKind.changeLevelOnly)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            l.lvShellLevelCaption,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.dim),
          ),
        )
      else ...[
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
      // The network mode and Node failover live on Network & privacy (B-03).
      // The wallet's own count, stored in the core: how long received coins wait.
      const SizedBox(height: 8),
      SettingsHeader(l.advBalanceHeader),
      const ConfirmationsRow(),
      // Experimental, so last: Pairing and Invoices (off by default).
      const SizedBox(height: 8),
      SettingsHeader(l.advExperimental, key: _experimentalKey),
      experimental(AdvancedFeature.invoices, Icons.request_quote_outlined, l.expInvoices, l.expInvoicesHint),
      Padding(
        key: const ValueKey('adv-exp-rule'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          l.expNeedsPairing,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.dim),
        ),
      ),
      ],
    ];
  }

  List<Widget> _display(AppLocalizations l) {
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    return [
      trustId(
        TrustIds.appearanceTheme,
        ListTile(
          leading: const Icon(Icons.brightness_6),
          title: Text(l.settingsTheme),
          subtitle: Text(themeLabel(l, s.themeMode)),
          onTap: () => _pickTheme(s),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.language),
        title: Text(l.languageSetting),
        subtitle: Text(languageLabel(l, s.language)),
        onTap: () => _pickLanguage(s),
      ),
      HintSwitchTile(
        icon: Icons.visibility_off,
        title: l.settingsHideBalances,
        value: s.hideBalances,
        onChanged: _settings.setHideBalances,
      ),
      // No price source in app-config.toml, or `[online] price` off in settings.toml: no rows.
      if (pricesOffered(ref.watch(hostSettingsProvider))) ...[
        HintSwitchTile(
          icon: Icons.show_chart,
          title: l.settingsShowPrices,
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
    final updates = ref.read(updateProvider.notifier).supported;
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
      // Licences, folded until tapped (item 5); the full texts (the packages', the fonts',
      // the word lists' and the bundled tor's) are one tap further.
      const LicencesFold(rowKey: settingsLicencesKey),
      // The site's address as its name, the same in every language and on the desktop.
      if (epicCashUrl case final site?) LinkTile(title: shownUrl(site), url: site),
      if (projectRepoUrl != null) LinkTile(title: l.settingsSourceCode, url: projectRepoUrl!),
      if (privacyPolicyUrl case final url?) LinkTile(title: l.settingsPrivacyPolicy, url: url),
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

/// The Linked devices row on the Wallet page, for tests.
const Key settingsLinkedDevicesKey = ValueKey('settings-linked-devices');

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
const Key txTorPayLineKey = ValueKey('tx-tor-pay-line');

/// Under the Link · Tor switch while it is on: what Tor for payments does now (starting,
/// receiving, off in Node only or Kill switch) and whether Tor also carries the rest.
class _TorPayLine extends ConsumerWidget {
  const _TorPayLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;
    final p = ref.watch(phoneTorPayProvider);
    final text = p.kind == TorPayKind.ready ? '${torPayLine(l, p)} · ${torPayRestLine(l, p)}' : torPayLine(l, p);
    return Padding(
      key: txTorPayLineKey,
      // Lined up with the switch's title, past its icon.
      padding: const EdgeInsets.fromLTRB(56, 0, 16, 10),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.dim)),
    );
  }
}

/// A web link. The app has no browser launcher, so tapping copies the address.
class LinkTile extends StatelessWidget {
  const LinkTile({super.key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListTile(
      leading: const Icon(Icons.link),
      title: Text(title),
      subtitle: Text(url),
      trailing: Icon(Icons.copy, semanticLabel: l.settingsCopyLink),
      onTap: () => copyText(context, url, l.settingsLinkCopied),
    );
  }
}

/// Where a rescan starts: the shared scan-start block (`scan_start.dart`), as on a restore.
/// Pops the start height, or null when cancelled. On mainnet, at every level, a month
/// (January 2025 unless another is picked) or the start, and with [heights] a block height
/// too (the owner, 2026-11-03). A test network: the start, with [heights] a height.
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
