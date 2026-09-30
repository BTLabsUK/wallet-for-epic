import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
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
import 'help_screen.dart';
import 'launch_screen.dart';
import 'pin.dart';
import 'restore_screen.dart'
    show ScanProgressView, formatDay, mainnetFirstDay, mainnetHeightForDate;
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

/// Under the payment notifications switch. No mailbox server registers push tokens yet
/// (`push.dart`), so it says so instead of naming one.
const String pushNotificationsHint =
    'Delivered by Google Firebase. No mailbox server supports it yet. You '
    'still need to open the app to accept a payment.';

/// Under the payment notifications switch after the system denied notification permission.
const String pushBlockedMessage =
    'Notifications are blocked in system settings';

/// Under the payment notifications switch after Firebase failed to start.
const String pushUnavailableMessage =
    'Notifications are not available in this build';

/// Said when a delete is asked for while a scan runs.
const String deleteDuringScanMessage =
    'Wait for the scan to finish before deleting the wallet.';

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
/// from (`pubspec.yaml`, passed in by `flutter build`).
final appVersionProvider = FutureProvider<String>((ref) async {
  final platform = ref.watch(updatePlatformProvider);
  if (platform != null) {
    try {
      final app = await platform.installedApp();
      return '${app.versionName} (${app.versionCode})';
    } catch (_) {
      // Fall back to the build's own version.
    }
  }
  const name = String.fromEnvironment('FLUTTER_BUILD_NAME');
  const number = String.fromEnvironment('FLUTTER_BUILD_NUMBER');
  if (name.isEmpty) return 'Unknown';
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
    final code = await _choose(
      title: 'Currency',
      current: s.fiatCurrency,
      options: [
        for (final c in fiatCurrencies)
          (value: c.code, label: '${c.name} (${c.code.toUpperCase()})'),
      ],
    );
    if (code != null) await _settings.setFiatCurrency(code);
  }

  Future<void> _pickTheme(AppSettings s) async {
    final mode = await _choose(
      title: 'Theme',
      current: s.themeMode,
      options: [
        for (final m in ThemeMode.values) (value: m, label: themeLabel(m)),
      ],
    );
    if (mode != null) await _settings.setThemeMode(mode);
  }

  // Security.

  Future<void> _pickAutoLock(AppSettings s) async {
    // A sentinel, because the dialog returns null when dismissed and null also means never.
    const never = -1;
    final minutes = await _choose<int>(
      title: 'Auto-lock',
      current: s.autoLockMinutes ?? never,
      options: [
        for (final m in autoLockChoices)
          (value: m ?? never, label: autoLockLabel(m)),
      ],
    );
    if (minutes != null) {
      await _settings.setAutoLockMinutes(minutes == never ? null : minutes);
    }
  }

  Future<void> _setPushNotifications(bool on) async {
    await _settings.setPushNotifications(on);
    if (!on && mounted) {
      _say('Notifications stop the next time the app starts.');
    }
  }

  Future<void> _setBiometrics(bool on) async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    final vault = ref.read(vaultProvider);
    if (!on) {
      await vault.disableBiometrics(config.chain);
      if (mounted) _say('Biometric unlock turned off');
    } else {
      final password = await askWalletPassword(
        context,
        reason: 'Enter your PIN to turn on biometric unlock.',
        allowBiometrics: false,
      );
      if (password == null) return;
      final ok = await vault.enableBiometrics(config.chain, password);
      if (mounted) {
        _say(
          ok ? 'Biometric unlock turned on' : 'Biometric unlock was not set up',
        );
      }
    }
    ref.invalidate(_biometricsProvider);
  }

  Future<void> _showPhrase() async {
    final done = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const BackupScreen()));
    if (done == true && mounted) _say('Recovery phrase confirmed');
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
    if (ok) _say('Rescan finished');
  }

  Future<void> _deleteWallet() async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    // A scan writes to the wallet's files until it ends.
    if (ref.read(scanProvider).running) {
      _say(deleteDuringScanMessage);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteWalletDialog(),
    );
    if (confirmed != true || !mounted) return;
    final password = await askWalletPassword(
      context,
      reason: 'Enter your PIN to delete this wallet.',
      allowBiometrics: false,
    );
    if (password == null || !mounted) return;
    if (ref.read(scanProvider).running) {
      _say(deleteDuringScanMessage);
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
        } catch (_) {
          // Leftover copies in the cache are harmless next to a deleted wallet; keep going.
        }
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
          (_) => false,
        );
      } catch (error) {
        if (mounted) _say(describeError(error));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final s = settings.value ?? const AppSettings();
    final config = ref.watch(walletConfigProvider);
    final network = ref.watch(networkChoiceProvider).value;
    final scan = ref.watch(scanProvider);
    final biometrics = ref.watch(_biometricsProvider).value;
    final version = ref.watch(appVersionProvider).value;
    final walletOpen = ref.watch(sessionProvider) != null;
    final updates = ref.read(updateProvider.notifier).supported;
    final chainName = config == null ? 'Unknown' : chainLabel(config.chain);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              children: [
                if (_busy) const LinearProgressIndicator(),
                if (scan.running || scan.error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ScanProgressView(scan: scan),
                  ),
                const _Header('Network'),
                ListTile(
                  leading: const Icon(Icons.settings_ethernet),
                  title: const Text('Network and node'),
                  subtitle: Text(
                    network == null
                        ? chainName
                        : '$chainName · ${Uri.tryParse(network.nodeUrl)?.host ?? network.nodeUrl}',
                  ),
                  onTap: () => _push(const SetupScreen()),
                ),
                const _Header('Display'),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Currency'),
                  subtitle: Text(_currencyName(s.fiatCurrency)),
                  enabled: s.showFiat,
                  onTap: () => _pickCurrency(s),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.show_chart),
                  title: const Text('Show prices'),
                  subtitle: const Text(
                    'Prices come from CoinGecko, which sees your IP address.',
                  ),
                  value: s.showFiat,
                  onChanged: _settings.setShowFiat,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off),
                  title: const Text('Hide balances'),
                  value: s.hideBalances,
                  onChanged: _settings.setHideBalances,
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Theme'),
                  subtitle: Text(themeLabel(s.themeMode)),
                  onTap: () => _pickTheme(s),
                ),
                if (ref.watch(pushConfiguredProvider).value ?? false) ...[
                  const _Header('Notifications'),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Payment notifications'),
                    subtitle: _PushSubtitle(ref.watch(pushProvider)),
                    value: s.pushNotifications,
                    onChanged: _setPushNotifications,
                  ),
                ],
                if (walletOpen) ...[
                  const _Header('Security'),
                  ListTile(
                    leading: const Icon(Icons.pin),
                    title: const Text('Change PIN'),
                    onTap: () => _push(const ChangePinScreen()),
                  ),
                  if (biometrics?.available ?? false)
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint),
                      title: const Text('Unlock with biometrics'),
                      value: biometrics!.enabled,
                      onChanged: _setBiometrics,
                    ),
                  ListTile(
                    leading: const Icon(Icons.lock_clock),
                    title: const Text('Auto-lock'),
                    subtitle: Text(autoLockLabel(s.autoLockMinutes)),
                    onTap: () => _pickAutoLock(s),
                  ),
                  ListTile(
                    leading: const Icon(Icons.key),
                    title: const Text('Back up recovery phrase'),
                    subtitle: const Text(
                      'The words that restore your wallet and funds',
                    ),
                    onTap: _showPhrase,
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Lock wallet'),
                    onTap: () => lockWallet(context, ref),
                  ),
                  const _Header('Payment history'),
                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: const Text('Export history backup'),
                    subtitle: const Text(
                      'Notes, recipients and fees. It does not hold your '
                      'funds; your recovery phrase does.',
                    ),
                    onTap: _busy
                        ? null
                        : () => _run(() => exportHistoryBackup(context, ref)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.table_view),
                    title: const Text('Export CSV'),
                    subtitle: const Text(
                      'A readable spreadsheet. Not encrypted.',
                    ),
                    onTap: _busy
                        ? null
                        : () => _run(() => exportHistoryCsv(context, ref)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Import history backup'),
                    subtitle: const Text(
                      'Brings back notes, recipients, fees and dates.',
                    ),
                    onTap: _busy
                        ? null
                        : () => _run(() => importHistoryBackup(context, ref)),
                  ),
                  const _Header('Wallet'),
                  ListTile(
                    leading: const Icon(Icons.contacts_outlined),
                    title: const Text('Contacts'),
                    subtitle: const Text('Add, edit or delete people you pay'),
                    onTap: () => _push(const ContactsScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('Rescan the chain'),
                    subtitle: const Text(
                      'Find missing funds. From a date, a block height or '
                      'the start.',
                    ),
                    enabled: !scan.running,
                    onTap: _rescan,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Delete this wallet',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    subtitle: const Text('Removes it from this device'),
                    enabled: !_busy,
                    onTap: _deleteWallet,
                  ),
                ],
                const _Header('About'),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  subtitle: Text(version ?? '…'),
                ),
                ListTile(
                  leading: const Icon(Icons.hub),
                  title: const Text('Network'),
                  subtitle: Text(chainName),
                ),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Mailbox server'),
                  subtitle: Text(
                    network?.relay.label ??
                        (config == null
                            ? 'Unknown'
                            : EpicboxRelay(
                                host: config.epicboxDomain,
                                port: config.epicboxPort,
                              ).label),
                  ),
                ),
                if (updates)
                  ListTile(
                    leading: const Icon(Icons.system_update),
                    title: const Text('Check for updates'),
                    onTap: () {
                      ref.read(updateProvider.notifier).check();
                      _say(
                        'Checking for updates. The result shows on the home '
                        'screen.',
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help'),
                  onTap: () => openHelp(context),
                ),
                const _LinkTile(title: 'Epic Cash', url: epicCashUrl),
                const _LinkTile(title: 'Source code', url: projectRepoUrl),
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
String _currencyName(String code) {
  for (final c in fiatCurrencies) {
    if (c.code == code) return '${c.name} (${code.toUpperCase()})';
  }
  return code.toUpperCase();
}

/// Plain words for a theme choice.
String themeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Same as the device',
  ThemeMode.light => 'Light',
  ThemeMode.dark => 'Dark',
};

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
    return ListTile(
      leading: const Icon(Icons.link),
      title: Text(title),
      subtitle: Text(url),
      trailing: const Icon(Icons.copy, semanticLabel: 'Copy link'),
      onTap: () => copyText(context, url, 'Link'),
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
    final BigInt? start;
    switch (_from) {
      case _RescanFrom.date:
        final date = _date;
        if (date == null) {
          setState(() => _error = 'Pick a date first.');
          return;
        }
        start = mainnetHeightForDate(date);
      case _RescanFrom.height:
        final height = BigInt.tryParse(_height.text.trim());
        if (height == null || height < BigInt.one) {
          setState(() => _error = 'Enter a block height of 1 or more.');
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
    final date = _date;
    return AlertDialog(
      title: const Text('Rescan the chain'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'The wallet looks for its funds again. An earlier start finds '
              'more but takes longer; the whole chain can take a long time.',
            ),
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
                    const RadioListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _RescanFrom.date,
                      title: Text('From a date'),
                    ),
                  const RadioListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _RescanFrom.height,
                    title: Text('From a block height'),
                  ),
                  const RadioListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _RescanFrom.start,
                    title: Text('The whole chain'),
                  ),
                ],
              ),
            ),
            if (_from == _RescanFrom.date)
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(date == null ? 'Pick a date' : formatDay(date)),
                onPressed: _pickDate,
              ),
            if (_from == _RescanFrom.height)
              TextField(
                controller: _height,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Start height',
                  border: OutlineInputBorder(),
                ),
              ),
            if (_error != null) ErrorText(_error!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _start, child: const Text('Rescan')),
      ],
    );
  }
}

/// The word the user types to confirm deleting the wallet.
const String deleteConfirmWord = 'delete';

/// A strong warning before deleting the wallet. Pops true only after the user typed
/// [deleteConfirmWord] and confirmed they have the recovery phrase.
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

  bool get _ready =>
      _understood && _word.text.trim().toLowerCase() == deleteConfirmWord;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      icon: Icon(Icons.warning_amber, color: error, semanticLabel: 'Warning'),
      title: const Text('Delete this wallet?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This removes the wallet, its history and its PIN from this '
              'device. Only the recovery phrase can bring the funds back. '
              'Without it, they are lost for good.',
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _understood,
              onChanged: (value) =>
                  setState(() => _understood = value ?? false),
              title: const Text('I have written down my recovery phrase'),
            ),
            TextField(
              controller: _word,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Type "$deleteConfirmWord" to confirm',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep wallet'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: error),
          onPressed: _ready ? () => Navigator.pop(context, true) : null,
          child: const Text('Delete wallet'),
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
    final problem = push.blocked
        ? pushBlockedMessage
        : push.unavailable
        ? pushUnavailableMessage
        : null;
    if (problem == null) return const Text(pushNotificationsHint);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(pushNotificationsHint),
        const SizedBox(height: 4),
        Text(
          problem,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
    );
  }
}
