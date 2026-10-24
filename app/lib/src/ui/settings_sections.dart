/// The phone's Settings pages, one per group of the hub (`settings_screen.dart`): Security,
/// Privacy & network, Wallet, Display and About. Each page is a short list of label-only rows
/// (an explanation sits behind an info icon, a value or a state on the row's second line), so
/// a page fits a 360 dp phone without a search. Help & feedback opens Help itself, and
/// Notifications is one switch on the hub.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_info.dart';
import '../app_log.dart';
import '../app_version.dart';
import '../demo.dart';
import '../errors.dart';
import '../l10n.dart';
import '../network.dart';
import '../phone_tor.dart';
import '../price.dart';
import '../providers.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../smart_outputs.dart' show OutputLabel, outputWord;
import '../tor_phone.dart';
import '../tor_routes.dart';
import '../updater.dart';
import '../wallet_service.dart';
import 'backup_screen.dart';
import 'common.dart';
import 'contacts_screen.dart';
import 'demo_screens.dart' show endDemo;
import 'info_hint.dart';
import 'language_flag.dart';
import 'launch_screen.dart';
import 'licences_screen.dart';
import 'network_menu.dart';
import 'network_status.dart';
import 'home_parts.dart' show outputsShown;
import 'outputs_screen.dart';
import 'pin.dart';
import 'restore_screen.dart'
    show ScanSlotLine, mainnetFirstDay, mainnetHeightForDate;
import 'server_picker.dart' show showEpicboxPicker, showNodePicker;
import 'settings_history.dart';
import 'settings_invoices.dart';
import 'settings_pin.dart';
import 'status.dart' show serverHost;
import 'theme/advanced.dart';
import 'theme/brand.dart' show BrandLockup, BrandVariant;
import 'theme/tokens.dart';
import 'tor_ui.dart';

/// The project's source code.
const String projectRepoUrl = 'https://github.com/BTLabs-EPIC/wallet-for-epic';

/// Whether the repositories are public. Until they are, no screen links to them (the phone's
/// and the desktop's About, the Licences page) and no text says the code is on GitHub; set it
/// to true when they are, and the links come back.
const bool projectRepoPublic = false;
const String epicCashUrl = 'https://epiccash.com';

/// Deletes leftover copies of shared files; uisend's `clearSharedFiles`. Tests replace it.
final sharedFilesCleanupProvider = Provider<Future<void> Function()>(
  (ref) => clearSharedFiles,
);

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

/// The groups of the Settings hub that open a page of their own. Help & feedback opens Help
/// and Notifications is a switch on the hub, so neither is here.
enum SettingsSection { security, privacyNetwork, wallet, display, advanced, about }

/// The group's title, on the hub's row and on its page's app bar.
String settingsSectionTitle(AppLocalizations l, SettingsSection section) =>
    switch (section) {
      SettingsSection.security => l.settingsSectionSecurity,
      SettingsSection.privacyNetwork => l.settingsSectionPrivacyNetwork,
      SettingsSection.wallet => l.settingsSectionWallet,
      SettingsSection.display => l.settingsSectionDisplay,
      SettingsSection.advanced => l.advTitle,
      SettingsSection.about => l.settingsSectionAbout,
    };

/// The group's glyph on the hub.
IconData settingsSectionIcon(SettingsSection section) => switch (section) {
  SettingsSection.security => Icons.shield_outlined,
  SettingsSection.privacyNetwork => Icons.hub_outlined,
  SettingsSection.wallet => Icons.account_balance_wallet_outlined,
  SettingsSection.display => Icons.tune,
  SettingsSection.advanced => Icons.terminal,
  SettingsSection.about => Icons.info_outline,
};

/// A feature's name as the Advanced page shows it (the hub's state line reuses it).
String advancedFeatureName(AppLocalizations l, AdvancedFeature f) => switch (f) {
  AdvancedFeature.outputs => l.advOutputs,
  AdvancedFeature.technicalDetails => l.advTechnical,
  AdvancedFeature.sendOptions => l.advSendOptions,
  AdvancedFeature.directReceiving => l.advDirect,
  AdvancedFeature.serverDetails => l.advServerDetails,
  AdvancedFeature.recheckFromHeight => l.advRecheckHeight,
  // Desktop only; never on a phone's list.
  AdvancedFeature.builtInNode => l.advBuiltInNode,
  AdvancedFeature.logs => l.advLogs,
};

/// A network mode's name.
String networkModeName(AppLocalizations l, NetworkMode m) => switch (m) {
  NetworkMode.standard => l.advModeStandard,
  NetworkMode.torOnly => l.advModeTorOnly,
  NetworkMode.offline => l.advModeOffline,
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
Future<void> openSettingsSection(BuildContext context, SettingsSection section) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsSectionScreen(section: section),
      ),
    );

/// One group's page: its rows under the group's title, with the actions they need.
class SettingsSectionScreen extends ConsumerStatefulWidget {
  const SettingsSectionScreen({super.key, required this.section});

  final SettingsSection section;

  @override
  ConsumerState<SettingsSectionScreen> createState() =>
      _SettingsSectionScreenState();
}

class _SettingsSectionScreenState extends ConsumerState<SettingsSectionScreen> {
  bool _busy = false;

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
      builder: (_) => _RescanDialog(datesSupported: chain == Chain.mainnet),
    );
    if (start == null || !mounted) return;
    final ok = await ref.read(scanProvider.notifier).run(startHeight: start);
    if (!mounted) return;
    if (ok) {
      _say(context.l10n.settingsRescanFinished, level: NoticeLevel.success);
    }
  }

  Future<void> _deleteWallet() async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    // A scan writes to the wallet's files until it ends.
    if (ref.read(scanProvider).running) {
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
    if (ref.read(scanProvider).running) {
      _say(context.l10n.settingsDeleteDuringScan, level: NoticeLevel.warning);
      return;
    }
    await _run(() async {
      try {
        ref.read(sessionProvider.notifier).lock();
        // The core waits until every call on this wallet has ended before it removes the files.
        await ref.read(walletServiceProvider).deleteWallet(config: config);
        await ref.read(vaultProvider).forget(config.chain);
        await ref
            .read(appSettingsProvider.notifier)
            .forgetHistoryBackup(config.chain);
        try {
          await ref.read(sharedFilesCleanupProvider)();
        } catch (error) {
          // Leftover copies in the cache are harmless next to a deleted wallet; keep going.
          logWarn('delete', 'clearing shared files failed: $error');
        }
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
          (_) => false,
        );
      } catch (error) {
        if (mounted) {
          _say(describeError(context.l10n, error), level: NoticeLevel.error);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scan = ref.watch(scanProvider);
    final rows = switch (widget.section) {
      SettingsSection.security => _security(l),
      SettingsSection.privacyNetwork => _privacyNetwork(l),
      SettingsSection.wallet => _wallet(l),
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
      ListTile(
        leading: const Icon(Icons.lock_clock),
        title: Text(l.settingsAutoLock),
        subtitle: Text(autoLockLabel(l, s.autoLockMinutes)),
        onTap: () => _pickAutoLock(s),
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
    final config = ref.watch(walletConfigProvider);
    final network = ref.watch(networkChoiceProvider).value;
    final demo = ref.watch(demoModeProvider);
    final devNetworks = ref.watch(devNetworksProvider);
    final advanced = AdvancedOptions.of(context);
    final chain = config == null ? l.commonUnknown : chainName(l, config.chain);
    // One row per thing (the owner, 26.10.11): Node and Epicbox with their host and health, each
    // opening its picker (the status card's rows, the same pickers as the icons on Home), the
    // Tor switch, then the other privacy settings. With no wallet open there is no health to
    // show: plain rows open the same pickers.
    return [
      if (walletOpen)
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: NetworkStatusCard(showTor: false),
        )
      else if (!demo) ...[
        ListTile(
          key: settingsNodeKey,
          leading: const Icon(Icons.dns_outlined),
          title: Text(l.serverNodeTitle),
          subtitle: withTorWay(
            network == null ? null : Text(serverHost(network.nodeUrl)),
            nodeTorWay(network?.nodeUrl, torState),
          ),
          onTap: () => showNodePicker(context),
        ),
        ListTile(
          key: settingsEpicboxKey,
          leading: const Icon(Icons.mail_outline),
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
      if (walletOpen && torAvailable) const TorSwitchTile(),
      HintSwitchTile(
        icon: Icons.travel_explore,
        title: l.settingsUseStatusSite,
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
    final invoices = ref.watch(sessionProvider)?.supportsInvoices ?? false;
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
            hint: l.settingsInvoicesSubtitle,
            icon: Icons.request_quote_outlined,
          ),
          onTap: () => _push(const InvoiceSettingsScreen()),
        ),
      if (!demo) ...[
        SettingsHeader(l.settingsSectionHistory),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: Text(l.settingsExportHistory),
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
          title: Text(l.settingsImportHistory),
          onTap: _busy
              ? null
              : () => _run(() => importHistoryBackup(context, ref)),
        ),
      ],
      // Recheck balance is the fix for a wrong balance: for everyone. From a height is Advanced.
      if (!demo)
        ListTile(
          leading: const Icon(Icons.sync),
          title: Text(l.settingsRescan),
          enabled: !scan.running,
          onTap: _rescan,
        ),
      const Divider(height: 24),
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

  /// Advanced: the switches that show more of the wallet, each explained in a sheet, and the
  /// one network mode. Nothing here is a value the simple path needs.
  List<Widget> _advanced(AppLocalizations l) {
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final adv = s.advanced;
    final t = context.tokens;
    final torAvailable = ref.watch(phoneTorProvider.select(torShown));
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
    Widget mode(NetworkMode m, String title, String line, {bool enabled = true}) =>
        RadioListTile<NetworkMode>(
          key: ValueKey('adv-mode-${m.name}'),
          value: m,
          enabled: enabled,
          title: Text(title),
          subtitle: Text(line),
        );
    final note = switch (adv.networkMode) {
      NetworkMode.torOnly => l.advTorOnlyNote,
      NetworkMode.offline => l.advOfflineNote,
      _ => null,
    };
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(
          l.advIntro,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.dim),
        ),
      ),
      SettingsHeader(l.advShowsHeader),
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
      if (torAvailable)
        feature(AdvancedFeature.directReceiving, Icons.link, l.advDirect, l.advDirectHint),
      feature(
        AdvancedFeature.serverDetails,
        Icons.dns_outlined,
        l.advServerDetails,
        l.advServerDetailsHint,
      ),
      feature(
        AdvancedFeature.recheckFromHeight,
        Icons.sync,
        l.advRecheckHeight,
        l.advRecheckHeightHint,
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          children: [
            Expanded(child: SettingsHeader(l.advNetworkHeader)),
            InfoHint(l.advNetworkHint, title: l.advNetworkHeader, icon: Icons.hub_outlined),
          ],
        ),
      ),
      RadioGroup<NetworkMode>(
        groupValue: adv.networkMode,
        onChanged: (v) {
          if (v != null) _settings.setNetworkMode(v);
        },
        child: Column(
          children: [
            mode(NetworkMode.standard, l.advModeStandard, l.advModeStandardLine),
            mode(
              NetworkMode.torOnly,
              l.advModeTorOnly,
              l.advModeTorOnlyLine,
              enabled: torAvailable,
            ),
            mode(NetworkMode.offline, l.advModeOffline, l.advModeOfflineLine),
          ],
        ),
      ),
      if (note != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            note,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.warn),
          ),
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
      const Divider(height: 24),
      ListTile(
        key: const ValueKey('adv-reset'),
        leading: const Icon(Icons.visibility_off_outlined),
        title: Text(l.advReset),
        enabled: adv.features.isNotEmpty,
        onTap: adv.features.isEmpty
            ? null
            : () => _settings.setAdvanced(
                AdvancedPrefs(
                  networkMode: adv.networkMode,
                  nodeFailover: adv.nodeFailover,
                ),
              ),
      ),
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
    ];
  }

  /// About: the app, its version and updates, then the rare things: Licences and the links.
  /// Advanced is a hub row of its own.
  List<Widget> _about(AppLocalizations l) {
    final version = ref.watch(appVersionProvider);
    final demo = ref.watch(demoModeProvider);
    final updates = !demo && ref.read(updateProvider.notifier).supported;
    return [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: BrandLockup(variant: BrandVariant.mobile, size: 40),
      ),
      ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(l.settingsVersion),
        subtitle: Text(
          version.hasValue ? version.value ?? l.commonUnknown : '…',
        ),
      ),
      if (updates)
        ListTile(
          leading: const Icon(Icons.system_update),
          title: Text(l.settingsCheckUpdates),
          onTap: () {
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
      const LinkTile(title: 'Epic Cash', url: epicCashUrl),
      if (projectRepoPublic) LinkTile(title: l.settingsSourceCode, url: projectRepoUrl),
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
class SettingsHeader extends StatelessWidget {
  const SettingsHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
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

enum _RescanFrom { date, height, start }

/// Where a rescan starts. Pops the start height, or null when cancelled.
class _RescanDialog extends StatefulWidget {
  const _RescanDialog({required this.datesSupported});

  final bool datesSupported;

  @override
  State<_RescanDialog> createState() => _RescanDialogState();
}

class _RescanDialogState extends State<_RescanDialog> {
  late _RescanFrom _from = widget.datesSupported
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
      case _RescanFrom.start:
        start = BigInt.one;
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
            Text(l.settingsRescanBody),
            const SizedBox(height: 8),
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

/// A strong warning before deleting the wallet. Pops true only after the user typed the
/// confirm word ([AppLocalizations.settingsDeleteConfirmWord]) and confirmed they have the
/// recovery phrase.
class DeleteWalletDialog extends StatefulWidget {
  const DeleteWalletDialog({super.key});

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
