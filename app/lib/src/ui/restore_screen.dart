// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../errors.dart';
import '../help/help_content.dart' show HelpId;
import '../bip39_words.dart';
import '../levels/first_run_servers_phone.dart';
import '../l10n.dart';
import '../phrase_problem.dart';
import '../providers.dart';
import '../restore_scan.dart';
import '../trust_ids.dart';
import '../secure_screen.dart' show hidePreview, keepScreenOn;
import '../settings.dart' show autoLockHoldProvider;
import '../wallet_service.dart';
import 'app_dialog.dart';
import 'common.dart';
import 'help_screen.dart' show openHelp;
import 'kit/kit_button.dart';
import 'kit/kit_empty_state.dart';
import 'kit/kit_group.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_help_sheet.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_progress_ring.dart';
import 'kit/kit_tokens.dart';
import 'launch_screen.dart';
import 'pin.dart';
import 'scan_screen.dart' show offersQrScan, qrScannerProvider;
import 'scan_start.dart';
import 'settings_history.dart';
import 'settings_sections.dart' show DeleteWalletDialog;
import 'wallet_delete.dart';
import 'work_status.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';
import 'devices/device_parts.dart' show LinkDeviceOffer;

export '../start_month.dart' show mainnetHeightForDate, mainnetFirstDay, mainnetBlockOneUnix, blockSeconds, restoreMarginBlocks;

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

/// The restore scan's Stop, Try again and Open wallet buttons, for tests.
const Key restoreStopKey = ValueKey('restore-stop');
const Key restoreRetryKey = ValueKey('restore-retry');
const Key restoreOpenKey = ValueKey('restore-open');

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  final _phrase = TextEditingController();
  _RestoreStep _step = _RestoreStep.phrase;

  /// Where the scan starts, at every level: restore is a one-off, so the height is not behind
  /// the Recheck from a height switch. Made on first use: the chain comes from the provider.
  late final _scanStart = ScanStartController(dates: _datesSupported);
  String _validPhrase = '';
  BigInt? _height;
  String? _error;
  bool _busy = false;

  /// The phrase is being checked after Continue.
  bool _checking = false;

  /// [RestoreScreen.replace]: the old wallet is deleted now, so Back and Continue work as on a
  /// first run.
  bool _replaced = false;

  /// The step of the old wallet's delete under way, for the line under the PIN step.
  DeleteStep? _deleting;

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
    _scanStart.dispose();
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
    // Mainnet starts from a month (January 2025 unless another is chosen), or from block 0 on
    // Scan from the start; a test network from block 0 unless a height is typed. Null is
    // block 0, for the wallet and its scan alike.
    final startHeight = _scanStart.start;
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
    final confirmed = await showAppDialog<bool>(
      context,
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
      _deleting = DeleteStep.files;
    });
    try {
      // The old wallet's scan writes to its files until it ends; the user chose to replace it.
      await deleteWalletEverywhere(
        ref,
        config,
        stopScan: true,
        onStep: (step) {
          if (mounted) setState(() => _deleting = step);
        },
      );
    } catch (error) {
      if (mounted) leaveAfterFailedDelete(context, ref, error);
      return;
    }
    _replaced = true;
    if (mounted) setState(() => _deleting = null);
    if (!mounted) {
      // The screen went during the delete: the phrase's wallet still comes, so the phone is
      // never left with none. Home's own scan carries the restore on.
      try {
        final created = await vault.create(
          config,
          pin: pin,
          mnemonic: phrase,
          restoreFromHeight: startHeight,
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
        restoreFromHeight: _height,
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

  /// The restore's scan, from the start the wallet was made with (null: block 0), which then
  /// finishes the restore. The screen stays on meanwhile, so
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
    final Widget body = switch (_step) {
      _RestoreStep.phrase => _phraseStep(context),
      _RestoreStep.pin => _pinStep(context),
      _RestoreStep.scan => _scanStep(context),
      _RestoreStep.importOffer => _doneStep(context),
    };
    final scaffold = SlotScaffold(
      glow: _step == _RestoreStep.importOffer ? heroGlow : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: body),
        ),
      ),
    );
    return PopScope(
      canPop: _canPop,
      // A system Back the screen keeps does what the header's Back does there, if anything.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _busy) return;
        if (_step == _RestoreStep.phrase) _back();
      },
      child: scaffold,
    );
  }

  void _help(String title, List<String> lines, {VoidCallback? more}) =>
      showKitHelp(context, title: title, lines: lines, onMore: more);

  void _phraseHelp() {
    final l = context.l10n;
    _help(l.phoneRestoreHelpTitle, [l.phoneRestoreHelpPhrase, l.phoneRestoreHelpStart], more: () => openHelp(context, HelpId.phrase));
  }

  void _pinHelp() {
    final l = context.l10n;
    _help(l.phoneStartPinHelpTitle, [l.phoneStartPinHelpUnlock, l.phoneStartPinHelpLost], more: () => openHelp(context, HelpId.phrase));
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

  /// Pastes the clipboard's text into the field (read on the press, never before).
  Future<void> _pastePhrase() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty || !mounted) return;
    setState(() {
      _phrase.text = normalizePhrase(text.replaceAll(',', ' '));
      _error = null;
    });
  }

  /// Continue on the phrase step: one press at a time while the phrase is checked.
  Future<void> _continue() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await _checkPhrase();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  /// Back on the PIN step, to the phrase that checked out.
  void _backToPhrase() {
    if (_busy) return;
    setState(() {
      if (_validPhrase.isNotEmpty) _phrase.text = _validPhrase;
      _error = null;
      _step = _RestoreStep.phrase;
    });
  }

  /// The space under the foot buttons: 34 in all, of which the phone's own bottom inset counts
  /// (the SafeArea has taken it from this subtree, so it is read from the route).
  double _footBottom(BuildContext context) =>
      (34 - MediaQuery.viewPaddingOf(Navigator.of(context).context).bottom).clamp(0, 34).toDouble();

  Widget _phraseStep(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Column(
      children: [
        KitFlowHeader(title: l.phoneRestoreTitle, back: true, onLeading: _back, onHelp: _phraseHelp, leadingId: TrustIds.restoreBack, helpId: TrustIds.restoreHelp),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: Kit.gutter),
            children: [
              // From Settings: nothing changes before the phrase checks out and the user confirms.
              if (widget.replace && !_replaced)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 8, Kit.gutter + 4, 0),
                  child: Text(l.restoreReplaceLead, style: KitType.rowSub.copyWith(color: t.dim)),
                ),
              KitGroupLabel(l.restorePhraseLabel, top: 22),
              Padding(padding: const EdgeInsets.symmetric(horizontal: Kit.gutter), child: _phraseBox(context)),
              RestoreWordCheck(text: _phrase.text),
              if (_error != null)
                Padding(padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 8, Kit.gutter + 4, 0), child: ErrorText(_error!)),
              KitGroupLabel(l.phoneRestoreStartGroup, top: 26),
              ScanStart(controller: _scanStart, ids: ScanStartIds.restore, rowTitle: l.phoneRestoreCreated, note: l.phoneRestoreStartNote, rowMinHeight: 62),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Kit.gutter, 8, Kit.gutter, _footBottom(context)),
          child: KitButton(
            label: l.commonContinue,
            onPressed: _checking ? null : _continue,
            semanticsId: TrustIds.restoreContinue,
          ),
        ),
      ],
    );
  }

  /// The phrase box (`.field.on`): the words in the mono face, Paste and Scan as gold links at
  /// its foot.
  Widget _phraseBox(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.field,
        borderRadius: BorderRadius.circular(Kit.rField),
        border: Border.all(color: t.line),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 168),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              trustId(
                TrustIds.restorePhrase,
                Semantics(
                  label: l.restorePhraseLabel,
                  child: TextField(
                    controller: _phrase,
                    // A phrase error is about the words as they were: an edit takes it away; the
                    // count line under the box follows every keystroke.
                    onChanged: (_) => setState(() => _error = null),
                    minLines: 3,
                    maxLines: 6,
                    autocorrect: false,
                    enableSuggestions: false,
                    enableIMEPersonalizedLearning: false,
                    keyboardType: TextInputType.visiblePassword,
                    style: KitType.body.copyWith(color: t.text, fontFamily: t.monoFamily, fontSize: 15, height: 1.7),
                    decoration: InputDecoration(
                      filled: false,
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: l.restorePhraseHelper,
                      hintStyle: KitType.body.copyWith(color: t.dim, fontSize: 15, height: 1.7),
                    ),
                  ),
                ),
              ),
              // Three lines of phrase, this gap and the links make the frame's 168.
              const SizedBox(height: 23),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TrustId(TrustIds.restorePaste, child: _PhraseLink(label: l.commonPaste, onPressed: _pastePhrase)),
                  // The phrase as a QR code (Show QR on the backup screen).
                  if (offersQrScan(ref)) ...[
                    const SizedBox(width: 4),
                    _PhraseLink(key: restoreScanKey, label: l.phoneRestoreScan, icon: KitIcons.scan, onPressed: _scanPhrase),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pinStep(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Column(
      children: [
        KitFlowHeader(
          title: '',
          back: true,
          // Not while the wallet is made, and not once the old wallet is gone.
          onLeading: _canPop ? _backToPhrase : null,
          onHelp: _pinHelp,
          leadingId: TrustIds.restoreBack,
          helpId: TrustIds.restoreHelp,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Kit.gutter, 4, Kit.gutter, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ErrorText(_error!),
                KitButton(label: l.restoreBackToPhrase, kind: KitButtonKind.ghost, onPressed: _backToPhrase, semanticsId: TrustIds.restoreBackToPhrase),
              ],
            ),
          ),
        Expanded(
          child: _busy
              // The PIN step stays while the wallet is made; the line says what is going on.
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Kit.gutter),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: Kit.gutter),
                        WorkStatus(
                          key: ValueKey(_deleting == null),
                          text: _deleting == null ? null : deleteStepText(l, _deleting!),
                          lines: [l.workRestoring, l.firstRunSecuring, l.workOpening],
                          showAfter: PinCheckBar.showAfter,
                          style: KitType.body.copyWith(color: t.dim),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: EdgeInsets.zero,
                  // A failure starts the PIN over (the error is its key).
                  child: PinSetupView(key: ValueKey(_error), onDone: _restore, actionsAtFoot: true),
                ),
        ),
      ],
    );
  }

  /// Dates map to heights only on mainnet; test networks have their own history.
  bool get _datesSupported => ref.read(walletConfigProvider)?.chain == Chain.mainnet;

  /// The search under way (HANDOFF 7.8, Gap-9), or stopped before the end.
  Widget _scanStep(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final scan = ref.watch(scanProvider);
    final percent = scan.percent;
    final waiting = scan.paused || scan.resuming;
    final running = scan.running;
    return Column(
      children: [
        KitFlowHeader(title: l.phoneRestoreRestoring, showLeading: false, onLeading: null, onHelp: _phraseHelp, helpId: TrustIds.restoreHelp),
        Expanded(
          child: running
              ? ListView(
                  padding: const EdgeInsets.only(top: 44),
                  children: [
                    Center(
                      child: KitProgressRing(
                        value: percent == null ? null : percent / 100,
                        label: percent == null ? '…' : '$percent%',
                        semanticsLabel: l.restoreScanProgressLabel,
                        // A number: the screen reader reads it as the progress.
                        semanticsValue: percent == null ? null : '$percent',
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
                      child: Semantics(
                        header: true,
                        child: Text(l.phoneRestoreScanTitle, style: KitType.pageTitle.copyWith(color: t.text, fontSize: 24, letterSpacing: -0.48), textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        waiting ? l.scanResuming : l.phoneRestoreScanBody,
                        style: KitType.body.copyWith(color: t.dim, height: 1.45),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 28),
                    KitGroup(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          child: Row(
                            children: [
                              Expanded(child: Text(l.phoneRestoreLookingFrom, style: KitType.rowTitle.copyWith(fontWeight: FontWeight.w400, color: t.dim))),
                              Text(ScanStart.value(l, _scanStart), style: KitType.rowAmount.copyWith(color: t.text)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 8, Kit.gutter + 4, 0),
                      child: Text(l.phoneRestoreScanNote, style: KitType.rowSub.copyWith(color: t.faint)),
                    ),
                    if (_error != null)
                      Padding(padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 8, Kit.gutter + 4, 0), child: ErrorText(_error!)),
                  ],
                )
              // Stopped or failed: the wallet is there, but cannot receive or send until the
              // scan finishes; Home goes on with it.
              : KitEmptyState(
                  icon: KitIcons.warning,
                  title: l.phoneRestoreStoppedTitle,
                  message: scan.stopped ? l.restoreScanStopped : l.restoreScanUnfinished,
                  extra: [
                    if (scan.error != null) ErrorText(describeError(l, scan.error!)),
                    if (_error != null) ErrorText(_error!),
                  ],
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Kit.gutter, 8, Kit.gutter, _footBottom(context)),
          child: running
              ? KitButton(key: restoreStopKey, label: l.restoreScanStop, kind: KitButtonKind.quiet, onPressed: () => ref.read(scanProvider.notifier).stop())
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    KitButton(key: restoreRetryKey, label: l.launchTryAgain, onPressed: _scan, semanticsId: TrustIds.restoreRetry),
                    const SizedBox(height: 12),
                    KitButton(key: restoreOpenKey, label: l.restoreOpenWallet, kind: KitButtonKind.quiet, onPressed: _openWallet, semanticsId: TrustIds.restoreOpen),
                  ],
                ),
        ),
      ],
    );
  }

  /// The restore is done (HANDOFF 7.8, Gap-10): Open wallet, and the offer of a wallet data file.
  Widget _doneStep(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Column(
      children: [
        KitFlowHeader(title: '', onLeading: _openWallet, leadingId: TrustIds.restoreClose),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Kit.gutter, 36, Kit.gutter, Kit.gutter),
            children: [
              Center(
                child: Semantics(
                  label: l.restoreDoneIconLabel,
                  image: true,
                  // The frame's `.okring`: a 76 disc at 12 % with a 10 px ring at 5 % around it.
                  child: Container(
                    width: Kit.okRing,
                    height: Kit.okRing,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.okSoft,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: t.ok.withValues(alpha: 0.05), spreadRadius: 10)],
                    ),
                    child: Icon(KitIcons.check, size: 36, color: t.ok),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Semantics(
                header: true,
                child: Text(l.restoreDoneTitle, style: KitType.doneTitle.copyWith(color: t.text), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(l.phoneRestoreDoneBody, style: KitType.body.copyWith(color: t.dim), textAlign: TextAlign.center),
              ),
              // The restore is still due after its scan (a wallet whose start the core did not
              // take): Home finishes it before receiving and sending open.
              if (ref.watch(restoreScanProvider).required) ...[
                const SizedBox(height: 12),
                Text(l.restoreFinishOnHome, style: KitType.rowSub.copyWith(color: t.dim), textAlign: TextAlign.center),
              ],
              // The quiet offer: this wallet may live on another device too (hidden while Linked
              // devices is off).
              const SizedBox(height: 24),
              LinkDeviceOffer(text: l.offerLinkRestore),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Kit.gutter, 8, Kit.gutter, _footBottom(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KitButton(key: restoreOpenKey, label: l.restoreOpenWallet, onPressed: _openWallet, semanticsId: TrustIds.restoreOpen),
              const SizedBox(height: 6),
              KitButton(
                label: l.restoreImportButton,
                kind: KitButtonKind.quiet,
                onPressed: () async {
                  final imported = await importHistoryBackup(context, ref);
                  if (imported && mounted) _openWallet();
                },
              ),
              const SizedBox(height: 12),
              Text(l.restoreImportLater, style: KitType.rowSub.copyWith(color: t.dim), textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}

/// The count line under the phrase box, as the desktop's grid says it: "All 24 words check
/// out." for 12 or 24 known words, else the count; a word the list lacks is named in a risk
/// coloured chip, so a typo is found without reading every word.
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
    final unknownWords = [for (final (i, w) in words.indexed) if (!bip39Words.contains(w)) (i + 1, w)];
    final unknown = unknownWords.length;
    final complete = unknown == 0 && (words.length == 12 || words.length == 24);
    final line = complete
        ? l.restoreWordsAllOk(words.length)
        : unknown > 0
        ? l.restoreWordsUnknown(unknown)
        : l.phoneRestoreWordsHint(words.length);
    return Padding(
      key: restoreWordCheckKey,
      padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 8, Kit.gutter + 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(line, style: KitType.rowSub.copyWith(color: complete ? t.ok : unknown > 0 ? t.risk : t.faint)),
          if (unknownWords.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (position, w) in unknownWords)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: t.riskSoft,
                      borderRadius: BorderRadius.circular(Kit.rButtonSmall),
                      border: Border.all(color: t.risk),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '$position ', style: TextStyle(color: t.dim)),
                          TextSpan(text: w, style: TextStyle(color: t.risk)),
                        ],
                      ),
                      style: KitType.chip.copyWith(fontFamily: t.monoFamily),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A gold text link at the foot of the phrase box (`.field .lnk`: 15/500, 40 px high, with a 44 tap area).
class _PhraseLink extends StatelessWidget {
  const _PhraseLink({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return KitHitReach(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onPressed,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18, color: t.accentText), const SizedBox(width: 6)],
                  Text(label, style: KitType.rowTitle.copyWith(fontSize: 15, fontWeight: FontWeight.w500, color: t.accentText)),
                ],
              ),
            ),
          ),
        ),
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
