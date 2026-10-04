import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../secure_screen.dart';
import '../wallet_service.dart';
import 'centered_body.dart';
import 'common.dart';
import 'launch_screen.dart';
import 'pin.dart';
import 'settings_history.dart';
import 'theme/advanced.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';

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

/// Lowercases the phrase and collapses whitespace, so pasted phrases validate.
String normalizePhrase(String input) =>
    input.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');

/// Restores a wallet from its recovery phrase, protects it with a PIN, then scans the chain.
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
    final l = context.l10n;
    final service = ref.read(walletServiceProvider);
    final phrase = normalizePhrase(_phrase.text);
    String? problem;
    if (!service.validateMnemonic(phrase: phrase)) {
      problem = l.errorInvalidMnemonic;
    }
    // Without Advanced options the choice is hidden and the scan covers the whole chain.
    final advanced = AdvancedOptions.of(context);
    final byDate = _startBy == _StartBy.date && _datesSupported;
    final heightText = byDate || !advanced ? '' : _startHeight.text.trim();
    final date = byDate && advanced ? _startDate : null;
    final startHeight = date != null
        ? mainnetHeightForDate(date)
        : heightText.isEmpty
        ? null
        : BigInt.tryParse(heightText);
    if (problem == null && heightText.isNotEmpty && startHeight == null) {
      problem = l.restoreStartHeightInvalid;
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
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // The vault never replaces a wallet that opens with a PIN; one the first run left
      // without its sealed text is deleted first, since its phrase was never shown.
      final vault = ref.read(vaultProvider);
      final created = await vault.create(
        config,
        pin: pin,
        mnemonic: _validPhrase,
        useBiometrics: useBiometrics,
      );
      _validPhrase = '';
      final session = created.session;
      // The user typed the phrase in, so they have it.
      await vault.markBackedUp(config.chain);
      if (useBiometrics && !created.biometrics && mounted) {
        ref
            .read(noticeProvider.notifier)
            .show(l.firstRunBiometricsNotSetUp, level: NoticeLevel.warning);
      }
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
      if (mounted) setState(() => _error = describeError(l, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
            child: Text(l.restoreBackToPhrase),
          ),
        ],
      ],
      _RestoreStep.scan => _scanView(context),
      _RestoreStep.importOffer => _importOffer(),
    };
    // The phrase form is long and keeps Continue at the foot; the later steps are short and
    // sit in the middle.
    final form = _step == _RestoreStep.phrase;
    return SlotScaffold(
      centered: !form,
      glow: _step == _RestoreStep.importOffer ? heroGlow : null,
      appBar: AppBar(
        title: Text(l.restoreTitle),
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
          ? ScreenBody(
              bottom: BusyButton(
                label: l.commonContinue,
                onPressed: _checkPhrase,
              ),
              children: steps,
            )
          : CenteredBody(children: steps),
    );
  }

  List<Widget> _form(BuildContext context) {
    final l = context.l10n;
    final advanced = AdvancedOptions.of(context);
    return [
      TextField(
        controller: _phrase,
        minLines: 3,
        maxLines: 5,
        autocorrect: false,
        enableSuggestions: false,
        enableIMEPersonalizedLearning: false,
        keyboardType: TextInputType.visiblePassword,
        decoration: InputDecoration(
          labelText: l.restorePhraseLabel,
          helperText: l.restorePhraseHelper,
          alignLabelWithHint: true,
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      if (advanced && _datesSupported) ...[
        Text(
          l.restoreStartHeading,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<_StartBy>(
          segments: [
            ButtonSegment(
              value: _StartBy.date,
              label: Text(l.restoreStartByDate),
            ),
            ButtonSegment(
              value: _StartBy.height,
              label: Text(l.restoreStartByHeight),
            ),
          ],
          selected: {_startBy},
          onSelectionChanged: (s) => setState(() => _startBy = s.first),
        ),
        const SizedBox(height: 12),
      ],
      if (advanced) ...[
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
            decoration: InputDecoration(
              labelText: l.restoreStartHeightLabel,
              helperText: l.restoreStartHeightHelper,
              border: const OutlineInputBorder(),
            ),
          ),
      ],
      const SizedBox(height: 16),
      if (_error != null) ErrorText(_error!),
    ];
  }

  /// Dates map to heights only on mainnet; test networks have their own history.
  bool get _datesSupported =>
      ref.read(walletConfigProvider)?.chain == Chain.mainnet;

  List<Widget> _importOffer() {
    final theme = Theme.of(context);
    final l = context.l10n;
    return [
      Center(
        child: Semantics(
          label: l.restoreDoneIconLabel,
          image: true,
          child: GlyphTile(
            size: 88,
            child: Icon(Icons.check, color: context.tokens.ok),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        l.restoreDoneTitle,
        style: theme.textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(l.restoreImportExplanation, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      BusyButton(
        label: l.restoreImportButton,
        onPressed: () async {
          final imported = await importHistoryBackup(context, ref);
          if (imported && mounted) goHome(context);
        },
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: () => goHome(context),
        child: Text(l.restoreImportNotNow),
      ),
      const SizedBox(height: 8),
      Text(l.restoreImportLater, textAlign: TextAlign.center),
    ];
  }

  List<Widget> _scanView(BuildContext context) {
    final l = context.l10n;
    final scan = ref.watch(scanProvider);
    return [
      Text(l.restoreScanIntro, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 16),
      ScanProgressView(scan: scan),
      if (_error != null) ErrorText(_error!),
      if (!scan.running) ...[
        const SizedBox(height: 16),
        BusyButton(
          label: l.restoreOpenWallet,
          onPressed: () => goHome(context),
        ),
        const SizedBox(height: 8),
        Text(l.restoreRescanLater),
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
      helpText: context.l10n.restoreDatePickerTitle,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
                ? l.restorePickDate
                : l.restoreFromDate(localDay(l, chosen)),
          ),
          onPressed: () => _pick(context),
        ),
        const SizedBox(height: 4),
        Text(
          chosen == null
              ? l.restoreDateHint
              : l.restoreDateStart(
                  groupDigits(l, mainnetHeightForDate(chosen)),
                ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (chosen != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => onChanged(null),
              child: Text(l.restoreWholeChain),
            ),
          ),
      ],
    );
  }
}

/// The words for a scan's progress: starting, a percentage, or complete. Null when no scan
/// has run, or the last one failed (the error says so instead).
String? _scanLine(AppLocalizations l, ScanState scan) {
  final percent = scan.percent;
  if (scan.running) {
    return percent == null ? l.scanStarting : l.scanProgress(percent);
  }
  return scan.done ? l.scanComplete : null;
}

/// Progress bar and progress line of a scan, or its error.
class ScanProgressView extends StatelessWidget {
  const ScanProgressView({super.key, required this.scan});

  final ScanState scan;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final percent = scan.percent;
    final line = _scanLine(l, scan);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scan.running)
          LinearProgressIndicator(
            value: percent == null ? null : percent / 100,
            semanticsLabel: l.restoreScanProgressLabel,
            // A number: Flutter asserts that a progress bar's semantic value parses as one.
            semanticsValue: percent == null ? null : '$percent',
          ),
        if (line != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(line)),
        if (scan.error != null) ErrorText(describeError(l, scan.error!)),
      ],
    );
  }
}

/// A running scan in one line for a notice slot: a thin bar along the top and the progress
/// line with its percentage.
class ScanSlotLine extends StatelessWidget {
  const ScanSlotLine({super.key, required this.scan});

  final ScanState scan;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final percent = scan.percent;
    final line = _scanLine(l, scan);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          minHeight: 2,
          value: percent == null ? null : percent / 100,
          semanticsLabel: l.restoreScanProgressLabel,
          semanticsValue: percent == null ? null : '$percent',
        ),
        if (line != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  line,
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
