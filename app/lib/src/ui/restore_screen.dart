// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../errors.dart';
import '../bip39_words.dart';
import '../levels/first_run_servers_phone.dart';
import '../levels/level_providers.dart';
import '../l10n.dart';
import '../phrase_problem.dart';
import '../providers.dart';
import '../restore_scan.dart';
import '../secure_screen.dart' show hidePreview, keepScreenOn;
import '../settings.dart' show autoLockHoldProvider;
import '../wallet_service.dart';
import 'centered_body.dart';
import 'common.dart';
import 'launch_screen.dart';
import 'pin.dart';
import 'scan_screen.dart' show offersQrScan, qrScannerProvider;
import 'settings_history.dart';
import 'settings_sections.dart' show DeleteWalletDialog;
import 'wallet_delete.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';
import 'devices/device_parts.dart' show LinkDeviceOffer;

/// Mainnet block 1 was mined at 2019-09-03T02:10:08Z (`get_header` at height 1 on
/// the built-in node, checked 2026-09-30). The genesis block is dated 2019-08-09T17:04:38Z, 24 days
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

/// The Scan QR button in the phrase field.
const Key restoreScanKey = ValueKey('restore-scan-qr');

/// Restores a wallet from its recovery phrase, protects it with a PIN, then scans the chain.
class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key, this.replace = false});

  /// Settings › Restore from a phrase: the open wallet is replaced. The phrase comes first;
  /// once it checks out, the delete warning and the PIN confirm, and the wallet is deleted and
  /// restored in one step with the same PIN. Back before that leaves the wallet as it is.
  final bool replace;

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

enum _RestoreStep { phrase, pin, scan, importOffer }

enum _StartBy { date, height }

/// The key of the "Start from a date or height" link, for tests.
const Key restoreStartLinkKey = ValueKey('restore-start-link');

/// The restore scan's Stop, Try again and Open wallet buttons, for tests.
const Key restoreStopKey = ValueKey('restore-stop');
const Key restoreRetryKey = ValueKey('restore-retry');
const Key restoreOpenKey = ValueKey('restore-open');

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

  /// "Start from a date or height" was tapped: the choice shows. Restore is a one-off, so it
  /// is not behind the Recheck from a height switch.
  bool _startOpen = false;

  /// [RestoreScreen.replace]: the old wallet is deleted now, so Back and Continue work as on a
  /// first run.
  bool _replaced = false;

  /// The restore runs its own scan; the Home one waits until this screen is gone.
  late final RestoreScanNotifier _restoreScan;
  bool _released = false;

  /// Leaving the app does not count towards auto-lock while this screen is up: a lock at the
  /// scan's end skipped the history backup offer.
  final Completer<void> _autoLockHold = Completer<void>();

  @override
  void initState() {
    super.initState();
    // The typed phrase stays out of the app switcher's preview.
    unawaited(hidePreview(true));
    _restoreScan = ref.read(restoreScanProvider.notifier)..hold();
    // After the first frame: a provider may not change while the tree builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _released) return;
      unawaited(
        ref.read(autoLockHoldProvider.notifier).during(() => _autoLockHold.future),
      );
    });
  }

  @override
  void dispose() {
    _release();
    unawaited(keepScreenOn(false));
    unawaited(hidePreview(false));
    // Drop the phrase from the controller and the state, so they no longer point at it.
    _phrase.clear();
    _validPhrase = '';
    _phrase.dispose();
    _startHeight.dispose();
    super.dispose();
  }

  void _release() {
    if (_released) return;
    _released = true;
    _restoreScan.release();
    if (!_autoLockHold.isCompleted) _autoLockHold.complete();
  }

  /// To Home, where an unfinished restore goes on by itself.
  void _openWallet() {
    _release();
    goHome(context);
  }

  /// The core refused [phrase]: which word, the count, or the check bits.
  String _phraseError(AppLocalizations l, String phrase) {
    final problem = phraseProblem(phrase);
    return switch (problem.kind) {
      PhraseProblemKind.word when problem.unknown.length > 1 => l.restorePhraseUnknownWords(
        unknownWordsText(problem.unknown),
      ),
      PhraseProblemKind.word => l.restorePhraseUnknownWord(
        problem.position!,
        problem.word!,
      ),
      PhraseProblemKind.count => l.restorePhraseWordCount(problem.count),
      PhraseProblemKind.checksum => l.restorePhraseChecksum,
    };
  }

  Future<void> _checkPhrase() async {
    final l = context.l10n;
    final service = ref.read(walletServiceProvider);
    final phrase = normalizePhrase(_phrase.text);
    String? problem;
    if (!service.validateMnemonic(phrase: phrase)) {
      problem = _phraseError(l, phrase);
    }
    // The start choice is offered to everyone behind a small link; until it is opened the scan
    // covers the whole chain.
    final advanced = _startOpen;
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
    if (widget.replace && !_replaced) {
      setState(() => _error = null);
      return _replace(phrase, startHeight);
    }
    _phrase.clear();
    setState(() {
      _validPhrase = phrase;
      _height = startHeight;
      _error = null;
      _step = _RestoreStep.pin;
    });
  }

  /// Settings › Restore from a phrase, once the phrase checked out: the delete warning and the
  /// PIN, then the old wallet goes and the phrase's wallet comes with the same PIN (and
  /// biometrics when they were on). Cancel at either leaves everything as it was.
  Future<void> _replace(String phrase, BigInt? startHeight) async {
    final config = ref.read(walletConfigProvider);
    final session = ref.read(sessionProvider);
    if (config == null || session == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteWalletDialog(restore: true),
    );
    if (confirmed != true || !mounted) return;
    final vault = ref.read(vaultProvider);
    final pin = await askPin<String>(
      context,
      reason: usesPassphrase(ref)
          ? context.l10n.restoreReplacePassphraseReason
          : context.l10n.restoreReplacePinReason,
      allowBiometrics: false,
      action: (pin) async {
        await vault.checkPin(session, config, pin);
        return pin;
      },
    );
    if (pin == null || !mounted) return;
    final biometrics = await vault.biometricsEnabled(config.chain);
    if (!mounted) return;
    // Read now: the restore below has to finish even if the screen is gone by then.
    final sessions = ref.read(sessionProvider.notifier);
    _phrase.clear();
    setState(() {
      _validPhrase = phrase;
      _height = startHeight;
      _busy = true;
      _step = _RestoreStep.pin;
    });
    try {
      // The old wallet's scan writes to its files until it ends; the user chose to replace it.
      await deleteWalletEverywhere(ref, config, stopScan: true);
    } catch (error) {
      if (mounted) leaveAfterFailedDelete(context, ref, error);
      return;
    }
    _replaced = true;
    if (!mounted) {
      // The screen went during the delete: the phrase's wallet still comes, so the phone is
      // never left with none. Home's own scan carries the restore on.
      try {
        final created = await vault.create(
          config,
          pin: pin,
          mnemonic: phrase,
          useBiometrics: biometrics,
        );
        await vault.markBackedUp(config.chain);
        await sessions.open(created.session);
      } catch (error) {
        logWarn('restore', 'create after the screen closed failed: ${error.runtimeType}');
      }
      return;
    }
    await _restore(pin, biometrics);
  }

  Future<void> _restore(String pin, bool useBiometrics) async {
    if (ref.read(walletConfigProvider) == null) return;
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // On the servers first run picked: the restored wallet's address names a relay that
      // answers.
      final config = await configAfterFirstRunServers(ref);
      if (config == null || !mounted) return;
      // The vault never replaces a wallet, or sealed text, already on this chain.
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
            .show(
              l.firstRunBiometricsNotSetUp,
              level: NoticeLevel.warning,
              // Stays until closed: the first-run tour opens over Home and a timed notice
              // ran out under it unseen.
              persistent: true,
            );
      }
      await ref.read(sessionProvider.notifier).open(session);
      if (!mounted) return;
      await _scan();
    } catch (error) {
      if (mounted) setState(() => _error = describeError(l, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Back, from the AppBar or the system: never while a step is under way, and never back to
  /// Settings once the old wallet is gone.
  bool get _canPop => !_busy && !(widget.replace && _replaced);

  /// The AppBar's Back on the phrase step. Reached by replacing the first-run screen, so back
  /// means starting over there; from Settings, back to Settings while the wallet is still there.
  void _back() {
    if (_busy) return;
    if (widget.replace && !_replaced) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
      );
    }
  }

  /// The restore's scan, from the start the user chose. The screen stays on meanwhile, so
  /// Android does not cut the network; Try again goes on from the last stored page.
  Future<void> _scan() async {
    setState(() {
      _error = null;
      _step = _RestoreStep.scan;
    });
    unawaited(keepScreenOn(true));
    final bool scanned;
    try {
      scanned = await ref.read(scanProvider.notifier).run(startHeight: _height);
    } finally {
      unawaited(keepScreenOn(false));
    }
    if (scanned && mounted) {
      setState(() => _step = _RestoreStep.importOffer);
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
              // The phrase that checked out comes back, so nothing is typed twice.
              if (_validPhrase.isNotEmpty) _phrase.text = _validPhrase;
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
    // The phrase form is long and keeps Continue at the foot; the import offer keeps its
    // two choices there too; the scan sits in the middle.
    final form = _step == _RestoreStep.phrase;
    final offer = _step == _RestoreStep.importOffer;
    final scaffold = SlotScaffold(
      centered: !form && !offer,
      glow: _step == _RestoreStep.importOffer ? heroGlow : null,
      appBar: AppBar(
        title: Text(l.restoreTitle),
        leading: _step == _RestoreStep.phrase
            ? BackButton(onPressed: _back)
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
          : offer
          ? ScreenBody(
              bottom: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BusyButton(
                    label: l.restoreImportButton,
                    onPressed: () async {
                      final imported = await importHistoryBackup(context, ref);
                      if (imported && mounted) _openWallet();
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: _openWallet,
                    child: Text(l.restoreImportNotNow),
                  ),
                ],
              ),
              children: steps,
            )
          : CenteredBody(children: steps),
    );
    return PopScope(
      canPop: _canPop,
      // A system Back the screen keeps does what the AppBar's Back does there, if anything.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy && _step == _RestoreStep.phrase) _back();
      },
      child: scaffold,
    );
  }

  /// Fills the field from a QR code of the phrase: its words, checked as typed ones are. A code
  /// that holds anything but words is refused without showing what it holds.
  Future<void> _scanPhrase() async {
    final l = context.l10n;
    final text = await ref.read(qrScannerProvider).scan(context, hint: l.scanQrPhraseHint);
    if (text == null || !mounted) return;
    final words = normalizePhrase(text.replaceAll(',', ' '));
    setState(() {
      if (RegExp(r'^[a-z]+( [a-z]+)*$').hasMatch(words)) {
        _phrase.text = words;
        _error = null;
      } else {
        _error = l.restoreScanNoPhrase;
      }
    });
  }

  List<Widget> _form(BuildContext context) {
    final l = context.l10n;
    final advanced = _startOpen;
    return [
      // From Settings: nothing changes before the phrase checks out and the user confirms.
      if (widget.replace && !_replaced) ...[
        Text(l.restoreReplaceLead),
        const SizedBox(height: 16),
      ],
      TextField(
        controller: _phrase,
        // A phrase error is about the words as they were: an edit takes it away; the word
        // chips under the field follow every keystroke.
        onChanged: (_) => setState(() => _error = null),
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
          // The phrase as a QR code (Show QR on the backup screen).
          suffixIcon: offersQrScan(ref)
              ? IconButton(
                  key: restoreScanKey,
                  tooltip: l.scanQrTooltip,
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanPhrase,
                )
              : null,
        ),
      ),
      RestoreWordCheck(text: _phrase.text),
      // Level 1 starts every restore from the beginning: no date or height to get wrong.
      if (!advanced && ref.watch(levelFeaturesProvider.select((f) => f.restoreHeightField)))
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            key: restoreStartLinkKey,
            style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
            onPressed: () => setState(() => _startOpen = true),
            child: Text(l.restoreStartFromLink),
          ),
        ),
      const SizedBox(height: 12),
      if (advanced && _datesSupported) ...[
        Text(
          l.restoreStartHeading,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        // The app's tab style, no check mark.
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
          showSelectedIcon: false,
          style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, 44))),
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
      // From a start height the funds after it are found; the scan from block 0 finishes the
      // restore from Home before receiving and sending open.
      if (_height != null) ...[
        const SizedBox(height: 8),
        Text(l.restoreFinishOnHome, textAlign: TextAlign.center),
      ],
      const SizedBox(height: 16),
      Text(l.restoreImportLater, textAlign: TextAlign.center),
      // The quiet offer: this wallet may live on another device too (hidden while Linked
      // devices is off).
      const SizedBox(height: 24),
      LinkDeviceOffer(text: l.offerLinkRestore),
    ];
  }

  List<Widget> _scanView(BuildContext context) {
    final l = context.l10n;
    final scan = ref.watch(scanProvider);
    final outline = OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48));
    return [
      Text(l.restoreScanIntro, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 16),
      ScanProgressView(scan: scan),
      if (_error != null) ErrorText(_error!),
      if (scan.running) ...[
        const SizedBox(height: 8),
        Text(l.restoreScanScreenOn, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        OutlinedButton(
          key: restoreStopKey,
          style: outline,
          onPressed: () => ref.read(scanProvider.notifier).stop(),
          child: Text(l.restoreScanStop),
        ),
      ] else ...[
        // Stopped or failed: the wallet is there, but cannot receive or send until the scan
        // finishes; Home goes on with it.
        const SizedBox(height: 8),
        Text(scan.stopped ? l.restoreScanStopped : l.restoreScanUnfinished),
        const SizedBox(height: 16),
        BusyButton(
          key: restoreRetryKey,
          label: l.launchTryAgain,
          onPressed: _scan,
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: restoreOpenKey,
          style: outline,
          onPressed: _openWallet,
          child: Text(l.restoreOpenWallet),
        ),
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
    final t = context.tokens;
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: mainnetFirstDay,
      lastDate: now,
      helpText: context.l10n.restoreDatePickerTitle,
      // The app's faces and a neutral selection instead of Material's stock look.
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            backgroundColor: t.surface,
            headerHeadlineStyle: TextStyle(fontFamily: t.headFamily, fontWeight: FontWeight.w600, fontSize: 24, color: t.text),
            headerHelpStyle: TextStyle(fontFamily: t.headFamily, fontWeight: FontWeight.w600, fontSize: 13, color: t.dim),
            dayStyle: TextStyle(fontFamily: t.monoFamily, fontSize: 14),
            yearStyle: TextStyle(fontFamily: t.monoFamily, fontSize: 14),
            dayBackgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? t.selected : null),
            dayForegroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? t.faint : t.text),
            todayBackgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            todayForegroundColor: WidgetStatePropertyAll(t.text),
            todayBorder: BorderSide(color: t.selectedLine),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radiusSmall)),
          ),
        ),
        child: child!,
      ),
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

/// The words of the phrase as typed, each checked against the word list, with a count line
/// (as the desktop's grid): a word the list lacks is in the risk colour; 12 or 24
/// known words read "All 24 words check out."
class RestoreWordCheck extends StatelessWidget {
  const RestoreWordCheck({super.key, required this.text});

  final String text;

  /// The words typed so far.
  static List<String> wordsOf(String text) => [for (final w in text.trim().toLowerCase().split(RegExp(r'\s+'))) if (w.isNotEmpty) w];

  @override
  Widget build(BuildContext context) {
    final words = wordsOf(text);
    if (words.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final unknown = words.where((w) => !bip39Words.contains(w)).length;
    final complete = unknown == 0 && (words.length == 12 || words.length == 24);
    final line = complete
        ? l.restoreWordsAllOk(words.length)
        : unknown > 0
        ? l.restoreWordsUnknown(unknown)
        : l.restoreWordsSoFar(words.length);
    return Padding(
      key: restoreWordCheckKey,
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (i, w) in words.indexed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.surfaceHi,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: bip39Words.contains(w) ? t.line : t.risk),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${i + 1} ', style: TextStyle(color: t.dim, fontSize: 11)),
                        TextSpan(text: w, style: TextStyle(color: bip39Words.contains(w) ? t.text : t.risk)),
                      ],
                    ),
                    style: TextStyle(fontFamily: t.monoFamily, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            line,
            style: theme.textTheme.bodySmall?.copyWith(color: complete ? t.ok : unknown > 0 ? t.risk : t.dim),
          ),
        ],
      ),
    );
  }
}

/// The key of the word check under the phrase field, for tests.
const Key restoreWordCheckKey = ValueKey('restore-word-check');

/// The words for a scan's progress: starting, a percentage, or complete. Null when no scan
/// has run, or the last one failed (the error says so instead).
String? _scanLine(AppLocalizations l, ScanState scan) {
  final percent = scan.percent;
  if (scan.paused || scan.resuming) return l.scanResuming;
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
          // Holds still: the empty track until a percent comes; the line below says it runs.
          LinearProgressIndicator(
            value: (percent ?? 0) / 100,
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
          value: (percent ?? 0) / 100,
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
