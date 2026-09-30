import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../providers.dart';
import '../secure_screen.dart';
import '../wallet_service.dart';
import 'centered_body.dart';
import 'common.dart';
import 'launch_screen.dart';
import 'pin.dart';
import 'settings_history.dart';

/// Mainnet block 1 was mined at 2019-09-03T02:10:08Z (`get_header` at height 1 on
/// node.btlabs.uk, checked 2026-09-30). The genesis block is dated 2019-08-09T17:04:38Z, 24 days
/// earlier; counting from genesis at 60 s per block overshoots real heights by up to 20,000
/// blocks, which would skip outputs, so the estimate counts from block 1.
const int mainnetBlockOneUnix = 1567476608;

/// Target block time. Real blocks averaged 58.6 to 59.8 s from block 1, so the estimate runs
/// behind the chain, which is the safe side: the scan starts early rather than late.
const int blockSeconds = 60;

/// Two days of blocks subtracted on top, for clock skew and the day boundary.
const int restoreMarginBlocks = 2 * 24 * 3600 ~/ blockSeconds;

/// A mainnet height at or before the first block mined on [date]. Checked against real headers
/// from height 100,000 to 3,700,000: the estimate was 13,600 to 65,100 blocks early.
BigInt mainnetHeightForDate(DateTime date) {
  final seconds =
      date.toUtc().millisecondsSinceEpoch ~/ 1000 - mainnetBlockOneUnix;
  final estimate = 1 + seconds ~/ blockSeconds - restoreMarginBlocks;
  return BigInt.from(max(1, estimate));
}

/// The first day a mainnet wallet can hold funds.
final DateTime mainnetFirstDay = DateTime(2019, 9, 3);

/// `1 Sep 2026`, the way the history screen writes days.
String formatDay(DateTime day) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${day.day} ${months[day.month - 1]} ${day.year}';
}

/// Lowercases the phrase and collapses whitespace, so pasted phrases validate.
String normalizePhrase(String input) =>
    input.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');

/// Restores a wallet from its recovery phrase, protects it with a PIN, then scans the chain.
///
/// A wallet the first run created in the meantime is deleted first: its phrase was never
/// shown, so it cannot hold funds.
class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

enum _RestoreStep { phrase, pin, scan, importOffer }

enum _StartBy { date, height }

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  final _phrase = TextEditingController();
  final _startHeight = TextEditingController();
  _RestoreStep _step = _RestoreStep.phrase;
  _StartBy _startBy = _StartBy.date;
  DateTime? _startDate;
  String _validPhrase = '';
  BigInt? _height;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    setSecureScreen(true);
  }

  @override
  void dispose() {
    setSecureScreen(false);
    _phrase.dispose();
    _startHeight.dispose();
    super.dispose();
  }

  void _checkPhrase() {
    final service = ref.read(walletServiceProvider);
    final phrase = normalizePhrase(_phrase.text);
    String? problem;
    if (!service.validateMnemonic(phrase: phrase)) {
      problem = describeError(
        const WalletError(kind: WalletErrorKind.invalidMnemonic, message: ''),
      );
    }
    final byDate = _startBy == _StartBy.date && _datesSupported;
    final heightText = byDate ? '' : _startHeight.text.trim();
    final date = byDate ? _startDate : null;
    final startHeight = date != null
        ? mainnetHeightForDate(date)
        : heightText.isEmpty
        ? null
        : BigInt.tryParse(heightText);
    if (problem == null && heightText.isNotEmpty && startHeight == null) {
      problem = 'Start height must be a whole number.';
    }
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    _phrase.clear();
    setState(() {
      _validPhrase = phrase;
      _height = startHeight;
      _error = null;
      _step = _RestoreStep.pin;
    });
  }

  Future<void> _restore(String pin, bool useBiometrics) async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(walletSetupProvider.notifier).discard(config);
      final service = ref.read(walletServiceProvider);
      // A wallet still here after discard has a PIN or a password; never replace it.
      if (await service.walletExists(config: config)) {
        throw const WalletError(
          kind: WalletErrorKind.walletAlreadyExists,
          message: 'wallet exists',
        );
      }
      final vault = ref.read(vaultProvider);
      final password = await vault.pendingPassword(config.chain);
      final session = await service.create(
        config: config,
        mnemonic: _validPhrase,
        password: password,
      );
      _validPhrase = '';
      await vault.seal(
        config.chain,
        pin: pin,
        password: password,
        useBiometrics: useBiometrics,
      );
      // The user typed the phrase in, so they have it.
      await vault.markBackedUp(config.chain);
      ref.read(sessionProvider.notifier).unlocked(session);
      if (!mounted) return;
      setState(() => _step = _RestoreStep.scan);
      unawaited(setSecureScreen(false));
      final scanned = await ref
          .read(scanProvider.notifier)
          .run(startHeight: _height);
      if (scanned && mounted) {
        setState(() => _step = _RestoreStep.importOffer);
      }
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = switch (_step) {
      _RestoreStep.phrase => _form(context),
      _RestoreStep.pin => [
        if (_busy)
          const LinearProgressIndicator()
        else
          PinSetupView(onDone: _restore),
        if (_error != null) ...[
          ErrorText(_error!),
          TextButton(
            onPressed: () => setState(() {
              _error = null;
              _step = _RestoreStep.phrase;
            }),
            child: const Text('Back to the phrase'),
          ),
        ],
      ],
      _RestoreStep.scan => _scanView(context),
      _RestoreStep.importOffer => _importOffer(),
    };
    // The phrase form is long; the later steps are short and sit in the middle.
    final form = _step == _RestoreStep.phrase;
    return SlotScaffold(
      centered: !form,
      appBar: AppBar(
        title: const Text('Restore wallet'),
        // Reached by replacing the first-run screen, so back means starting over there.
        leading: _step == _RestoreStep.phrase
            ? BackButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
                ),
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: form
          ? ScreenBody(children: steps)
          : CenteredBody(children: steps),
    );
  }

  List<Widget> _form(BuildContext context) {
    return [
      TextField(
        controller: _phrase,
        minLines: 3,
        maxLines: 5,
        autocorrect: false,
        enableSuggestions: false,
        enableIMEPersonalizedLearning: false,
        keyboardType: TextInputType.visiblePassword,
        decoration: const InputDecoration(
          labelText: 'Recovery phrase',
          helperText: 'The 12 or 24 words, separated by spaces.',
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      if (_datesSupported) ...[
        Text(
          'Where to start scanning',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<_StartBy>(
          segments: const [
            ButtonSegment(value: _StartBy.date, label: Text('Date')),
            ButtonSegment(value: _StartBy.height, label: Text('Block height')),
          ],
          selected: {_startBy},
          onSelectionChanged: (s) => setState(() => _startBy = s.first),
        ),
        const SizedBox(height: 12),
      ],
      if (_startBy == _StartBy.date && _datesSupported)
        _DateChoice(
          date: _startDate,
          onChanged: (date) => setState(() => _startDate = date),
        )
      else
        TextField(
          controller: _startHeight,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Start height (optional)',
            helperText:
                'Scan from this block. Leave empty to scan the whole chain.',
            border: OutlineInputBorder(),
          ),
        ),
      const SizedBox(height: 16),
      if (_error != null) ErrorText(_error!),
      BusyButton(label: 'Continue', onPressed: _checkPhrase),
    ];
  }

  /// Dates map to heights only on mainnet; test networks have their own history.
  bool get _datesSupported =>
      ref.read(walletConfigProvider)?.chain == Chain.mainnet;

  List<Widget> _importOffer() {
    final theme = Theme.of(context);
    return [
      Icon(
        Icons.check_circle,
        size: 48,
        color: theme.colorScheme.primary,
        semanticLabel: 'Done',
      ),
      const SizedBox(height: 16),
      Text(
        'Your wallet is restored',
        style: theme.textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      const Text(
        'The chain holds your balance, but not who you paid, fees or notes. '
        'If you exported a history backup from this wallet, import it now to '
        'get them back. It is the .wfeh file you shared or saved outside your '
        'old phone.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      BusyButton(
        label: 'Import a history backup',
        onPressed: () async {
          final imported = await importHistoryBackup(context, ref);
          if (imported && mounted) goHome(context);
        },
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: () => goHome(context),
        child: const Text('Not now'),
      ),
      const SizedBox(height: 8),
      const Text(
        'You can import one later from Settings.',
        textAlign: TextAlign.center,
      ),
    ];
  }

  List<Widget> _scanView(BuildContext context) {
    final scan = ref.watch(scanProvider);
    return [
      Text(
        'Looking for your funds on the blockchain. Keep the app open until '
        'this finishes.',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 16),
      ScanProgressView(scan: scan),
      if (_error != null) ErrorText(_error!),
      if (!scan.running) ...[
        const SizedBox(height: 16),
        BusyButton(label: 'Open wallet', onPressed: () => goHome(context)),
        const SizedBox(height: 8),
        const Text('You can run a full rescan later from Settings.'),
      ],
    ];
  }
}

/// An optional start date with a date picker. Null means the whole chain.
class _DateChoice extends StatelessWidget {
  const _DateChoice({required this.date, required this.onChanged});

  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: mainnetFirstDay,
      lastDate: now,
      helpText: 'When did you create the wallet?',
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final chosen = date;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.calendar_today),
          label: Text(
            chosen == null
                ? 'Pick the date you created the wallet'
                : 'From ${formatDay(chosen)}',
          ),
          onPressed: () => _pick(context),
        ),
        const SizedBox(height: 4),
        Text(
          chosen == null
              ? 'Optional. If you are not sure, pick an earlier date. A date '
                    'after your first payment misses funds. Without a date '
                    'the whole chain is scanned, which takes longer.'
              : 'Scanning starts two days before this date, from block '
                    '${groupDigits(mainnetHeightForDate(chosen))}.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (chosen != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => onChanged(null),
              child: const Text('Scan the whole chain instead'),
            ),
          ),
      ],
    );
  }
}

/// Progress bar and latest message of a scan, or its error.
class ScanProgressView extends StatelessWidget {
  const ScanProgressView({super.key, required this.scan});

  final ScanState scan;

  @override
  Widget build(BuildContext context) {
    final percent = scan.percent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scan.running)
          LinearProgressIndicator(
            value: percent == null ? null : percent / 100,
            semanticsLabel: 'Scan progress',
            // A number: Flutter asserts that a progress bar's semantic value parses as one.
            semanticsValue: percent == null ? null : '$percent',
          ),
        if (scan.message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              percent == null || !scan.running
                  ? scan.message!
                  : '${scan.message} ($percent%)',
            ),
          ),
        if (scan.error != null) ErrorText(scan.error!),
      ],
    );
  }
}

/// A running scan in one line for a notice slot: a thin bar along the top and the latest
/// message with its percentage.
class ScanSlotLine extends StatelessWidget {
  const ScanSlotLine({super.key, required this.scan});

  final ScanState scan;

  @override
  Widget build(BuildContext context) {
    final percent = scan.percent;
    final message = scan.message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          minHeight: 2,
          value: percent == null ? null : percent / 100,
          semanticsLabel: 'Scan progress',
          semanticsValue: percent == null ? null : '$percent',
        ),
        if (message != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  percent == null ? message : '$message ($percent%)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
