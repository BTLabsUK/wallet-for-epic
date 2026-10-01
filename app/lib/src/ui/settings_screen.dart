import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../errors.dart';
import '../l10n.dart';
import '../network.dart';
import '../price.dart';
import '../providers.dart';
import '../push.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../updater.dart';
import '../wallet_service.dart';
import 'backup_screen.dart';
import 'common.dart';
import 'contacts_screen.dart';
import 'feedback_screen.dart';
import 'help_screen.dart';
import 'launch_screen.dart';
import 'pin.dart';
import 'restore_screen.dart'
    show ScanSlotLine, mainnetFirstDay, mainnetHeightForDate;
import 'settings_history.dart';
import 'settings_pin.dart';
import 'setup_screen.dart';

/// The project's source code.
const String projectRepoUrl = 'https://github.com/blacktyger/wallet-for-epic';
const String epicCashUrl = 'https://epiccash.com';

/// Deletes leftover copies of shared files; uisend's `clearSharedFiles`. Tests replace it.
final sharedFilesCleanupProvider = Provider<Future<void> Function()>(
  (ref) => clearSharedFiles,
);

/// Whether this device offers biometric unlock, and whether the open wallet uses it.
final _biometricsProvider =
    FutureProvider.autoDispose<({bool available, bool enabled})>((ref) async {
      final config = ref.watch(walletConfigProvider);
      final available = await ref.watch(biometricStoreProvider).isAvailable();
      final enabled =
          config != null &&
          await ref.watch(vaultProvider).biometricsEnabled(config.chain);
      return (available: available, enabled: enabled);
    });

/// The app version: the installed package's on Android, else the one this build was made
/// from (`pubspec.yaml`, passed in by `flutter build`). Null when neither is known.
final appVersionProvider = FutureProvider<String?>((ref) async {
  final platform = ref.watch(updatePlatformProvider);
  if (platform != null) {
    try {
      final app = await platform.installedApp();
      return '${app.versionName} (${app.versionCode})';
    } catch (error) {
      // Fall back to the build's own version.
      logInfo('app', 'installed version unknown: $error');
    }
  }
  const name = String.fromEnvironment('FLUTTER_BUILD_NAME');
  const number = String.fromEnvironment('FLUTTER_BUILD_NUMBER');
  if (name.isEmpty) return null;
  return number.isEmpty ? name : '$name ($number)';
});

/// App settings: network, display, security, history backup, wallet and about.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  void _say(String message) {
    ref.read(noticeProvider.notifier).show(message);
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
        for (final c in fiatCurrencies) (value: c, label: _currencyName(l, c)),
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
    );
    if (code != null) {
      await _settings.setLanguage(code == system ? null : code);
    }
  }

  Future<void> _setShowFiat(bool on) async {
    await _settings.setShowFiat(on);
    if (on && mounted) _say(context.l10n.settingsPricesOnNotice);
  }

  // Security.

  Future<void> _pickAutoLock(AppSettings s) async {
    final l = context.l10n;
    // A sentinel, because the dialog returns null when dismissed and null also means never.
    const never = -1;
    final minutes = await _choose<int>(
      title: l.settingsAutoLock,
      current: s.autoLockMinutes ?? never,
      options: [
        for (final m in autoLockChoices)
          (value: m ?? never, label: autoLockLabel(l, m)),
      ],
    );
    if (minutes != null) {
      await _settings.setAutoLockMinutes(minutes == never ? null : minutes);
    }
  }

  Future<void> _setPushNotifications(bool on) async {
    await _settings.setPushNotifications(on);
    if (!mounted) return;
    final l = context.l10n;
    _say(on ? l.settingsPushOnNotice : l.settingsPushOffNotice);
  }

  Future<void> _setBiometrics(bool on) async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    final vault = ref.read(vaultProvider);
    if (!on) {
      await vault.disableBiometrics(config.chain);
      if (mounted) _say(context.l10n.settingsBiometricsOff);
    } else {
      final password = await askWalletPassword(
        context,
        reason: context.l10n.settingsBiometricsPinReason,
        allowBiometrics: false,
      );
      if (password == null) return;
      final ok = await vault.enableBiometrics(config.chain, password);
      if (mounted) {
        final l = context.l10n;
        _say(ok ? l.settingsBiometricsOn : l.settingsBiometricsFailed);
      }
    }
    ref.invalidate(_biometricsProvider);
  }

  Future<void> _showPhrase() async {
    final done = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const BackupScreen()));
    if (done == true && mounted) _say(context.l10n.settingsPhraseConfirmed);
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
    ref.invalidate(homeProvider);
    if (ok) _say(context.l10n.settingsRescanFinished);
  }

  Future<void> _deleteWallet() async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    // A scan writes to the wallet's files until it ends.
    if (ref.read(scanProvider).running) {
      _say(context.l10n.settingsDeleteDuringScan);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteWalletDialog(),
    );
    if (confirmed != true || !mounted) return;
    final password = await askWalletPassword(
      context,
      reason: context.l10n.settingsDeletePinReason,
      allowBiometrics: false,
    );
    if (password == null || !mounted) return;
    if (ref.read(scanProvider).running) {
      _say(context.l10n.settingsDeleteDuringScan);
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
        if (mounted) _say(describeError(context.l10n, error));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = ref.watch(appSettingsProvider);
    final s = settings.value ?? const AppSettings();
    final config = ref.watch(walletConfigProvider);
    final network = ref.watch(networkChoiceProvider).value;
    final scan = ref.watch(scanProvider);
    final biometrics = ref.watch(_biometricsProvider).value;
    final version = ref.watch(appVersionProvider);
    final walletOpen = ref.watch(sessionProvider) != null;
    final updates = ref.read(updateProvider.notifier).supported;
    final chain = config == null ? l.commonUnknown : chainName(l, config.chain);

    return SlotScaffold(
      // A running scan shows in the slot. `_busy` shows nothing: most of its time is spent
      // waiting on a sheet or dialog, where a progress bar would say the wrong thing.
      idle: scan.running ? ScanSlotLine(scan: scan) : null,
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              children: [
                if (!scan.running && scan.error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ErrorText(describeError(l, scan.error!)),
                  ),
                _Header(l.settingsSectionNetwork),
                ListTile(
                  leading: const Icon(Icons.settings_ethernet),
                  title: Text(l.settingsNetworkAndNode),
                  subtitle: Text(
                    network == null
                        ? chain
                        : l.settingsNetworkSubtitle(
                            chain,
                            Uri.tryParse(network.nodeUrl)?.host ??
                                network.nodeUrl,
                          ),
                  ),
                  onTap: () => _push(const SetupScreen()),
                ),
                _Header(l.settingsSectionDisplay),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: Text(l.settingsCurrency),
                  subtitle: Text(_currencyName(l, s.fiatCurrency)),
                  enabled: s.showFiat,
                  onTap: () => _pickCurrency(s),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.show_chart),
                  title: Text(l.settingsShowPrices),
                  value: s.showFiat,
                  onChanged: _setShowFiat,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off),
                  title: Text(l.settingsHideBalances),
                  value: s.hideBalances,
                  onChanged: _settings.setHideBalances,
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: Text(l.settingsTheme),
                  subtitle: Text(themeLabel(l, s.themeMode)),
                  onTap: () => _pickTheme(s),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l.languageSetting),
                  subtitle: Text(_languageLabel(l, s.language)),
                  onTap: () => _pickLanguage(s),
                ),
                if (ref.watch(pushConfiguredProvider).value ?? false) ...[
                  _Header(l.settingsSectionNotifications),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: Text(l.settingsPaymentNotifications),
                    subtitle: _PushSubtitle(ref.watch(pushProvider)),
                    value: s.pushNotifications,
                    onChanged: _setPushNotifications,
                  ),
                ],
                if (walletOpen) ...[
                  _Header(l.settingsSectionSecurity),
                  ListTile(
                    leading: const Icon(Icons.pin),
                    title: Text(l.settingsChangePin),
                    onTap: () => _push(const ChangePinScreen()),
                  ),
                  if (biometrics?.available ?? false)
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
                  ListTile(
                    leading: const Icon(Icons.key),
                    title: Text(l.settingsBackupPhrase),
                    onTap: _showPhrase,
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: Text(l.settingsLockWallet),
                    onTap: () => lockWallet(context, ref),
                  ),
                  _Header(l.settingsSectionHistory),
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
                    onTap: _busy
                        ? null
                        : () => _run(() => exportHistoryCsv(context, ref)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: Text(l.settingsImportHistory),
                    onTap: _busy
                        ? null
                        : () => _run(() => importHistoryBackup(context, ref)),
                  ),
                  _Header(l.settingsSectionWallet),
                  ListTile(
                    leading: const Icon(Icons.contacts_outlined),
                    title: Text(l.settingsContacts),
                    onTap: () => _push(const ContactsScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: Text(l.settingsRescan),
                    enabled: !scan.running,
                    onTap: _rescan,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      l.settingsDeleteWallet,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    enabled: !_busy,
                    onTap: _deleteWallet,
                  ),
                ],
                _Header(l.settingsSectionAbout),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.settingsVersion),
                  subtitle: Text(
                    version.hasValue ? version.value ?? l.commonUnknown : '…',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.hub),
                  title: Text(l.settingsAboutNetwork),
                  subtitle: Text(chain),
                ),
                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: Text(l.settingsEpicboxServer),
                  subtitle: Text(
                    network?.relay.label ??
                        (config == null
                            ? l.commonUnknown
                            : EpicboxRelay(
                                host: config.epicboxDomain,
                                port: config.epicboxPort,
                              ).label),
                  ),
                ),
                if (updates)
                  ListTile(
                    leading: const Icon(Icons.system_update),
                    title: Text(l.settingsCheckUpdates),
                    onTap: () {
                      ref.read(updateProvider.notifier).check();
                      _say(l.settingsCheckingUpdates);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(l.settingsHelp),
                  onTap: () => openHelp(context),
                ),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: Text(l.settingsSendFeedback),
                  subtitle: Text(l.settingsSendFeedbackHint),
                  onTap: () => openFeedback(context),
                ),
                // A proper name, the same in every language.
                const _LinkTile(title: 'Epic Cash', url: epicCashUrl),
                _LinkTile(title: l.settingsSourceCode, url: projectRepoUrl),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `Euro (EUR)`, or the bare code for one the list does not know.
String _currencyName(AppLocalizations l, String code) =>
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
String _languageLabel(AppLocalizations l, String? code) {
  for (final a in appLanguages) {
    if (a.code == code) return a.name;
  }
  return l.languageSystem;
}

class _Header extends StatelessWidget {
  const _Header(this.title);

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

/// A web link. The app has no browser launcher, so tapping copies the address.
class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.title, required this.url});

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

/// The payment notifications hint, plus why the switch went back off when it did.
class _PushSubtitle extends StatelessWidget {
  const _PushSubtitle(this.push);

  final PushState push;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final problem = push.blocked
        ? l.settingsPushBlocked
        : push.unavailable
        ? l.settingsPushUnavailable
        : null;
    if (problem == null) return Text(l.settingsPushHint);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.settingsPushHint),
        const SizedBox(height: 4),
        Text(
          problem,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
    );
  }
}
