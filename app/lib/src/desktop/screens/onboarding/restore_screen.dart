import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../../log.dart';
import '../../../secret_store_api.dart' show SecretProtectError;
import '../../widgets/kit.dart';
import 'onboarding_parts.dart';
import 'phrase_grid.dart';
import 'reset_password_screen.dart' show ResetPasswordArg;
import 'same_wallet_dialog.dart';
import 'setup_screen.dart' show SetupFirstRun;
import 'unlock_screen.dart' show UnlockPick;

enum RestoreStep { words, wordsFilled, account, restoring, failed }

/// A phrase step for the screenshot tour: [text] pasted into the grid, or, with [typing], its
/// words typed up to a half-finished last one (the dim completion shows).
class RestoreSample {
  const RestoreSample(this.text, {this.typing = false});

  final String text;
  final bool typing;
}

/// Restore: the phrase, then name and password, then the wallet is restored and Unlock opens
/// with it. [arg] is a [RestoreStep] (`wordsFilled` starts with a pasted phrase that has one
/// word out of the list) or a [RestoreSample].
class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  static const _sample =
      'orbit hazard velvet cabin sudden meadow brick gesture lunar invest pledge saddle timber crisp wander echo faculty notable ripple garlic stamp dwarf enjoy h4rbor'; // l10n-ok: sample recovery words

  /// The name typed into the title; null keeps the default "Wallet N".
  String? _name;
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  /// Restore's start height: offered to everyone (a restore happens once), empty = the whole chain.
  final _fromHeight = TextEditingController();
  bool _fromOpen = false;
  late final PhraseEntry _entry;
  late RestoreStep _step = widget.arg is RestoreStep ? widget.arg as RestoreStep : RestoreStep.words;
  RestoreSample? get _sampleArg => widget.arg is RestoreSample ? widget.arg as RestoreSample : null;
  bool _locking = false;
  String? _failure;

  /// The shots' failed step: the permission failure, worded in build (initState has no l10n).
  bool _permissionDenied = false;

  /// The phrase is being looked up in the wallet list (Use N words pressed).
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final api = ref.read(deskApiProvider);
    _entry = PhraseEntry(check: api.checkPhrase)..addListener(_onEntry);
    final sample = _sampleArg;
    if (sample != null) {
      if (sample.typing) {
        final ws = PhraseEntry.split(sample.text);
        for (var i = 0; i < ws.length; i++) {
          _entry.controllers[i].text = ws[i];
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _entry.focusField(ws.length - 1));
      } else {
        _entry.paste(sample.text);
      }
    }
    switch (_step) {
      case RestoreStep.wordsFilled:
        _entry.paste(_sample);
      case RestoreStep.failed:
        _permissionDenied = true;
      case RestoreStep.words || RestoreStep.account || RestoreStep.restoring:
        break;
    }
  }

  void _onEntry() {
    _clipboardEmpty = false;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _fromHeight.dispose();
    _entry.removeListener(_onEntry);
    _entry.dispose();
    super.dispose();
  }

  bool get _accountOk => passwordLongEnough(_password.text) && _password.text == _confirm.text && _fromHeightOk;

  /// The typed start height: null when empty or not a number.
  BigInt? get _startHeight => _fromOpen ? BigInt.tryParse(_fromHeight.text.trim()) : null;

  bool get _fromHeightOk => !_fromOpen || _fromHeight.text.trim().isEmpty || _startHeight != null;

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (!mounted) return;
    if (PhraseEntry.split(text).isEmpty) {
      setState(() => _clipboardEmpty = true);
      return;
    }
    _clipboardEmpty = false;
    _entry.pasteAndFocus(text);
  }

  bool _clipboardEmpty = false;

  /// Use N words: the phrase of a wallet already in the list opens that wallet instead (O1);
  /// any other goes on to the password step. A list that cannot be read goes on too: restore
  /// checks again before it makes anything.
  Future<void> _toAccount() async {
    if (_checking) return;
    setState(() => _checking = true);
    WalletEntry? same;
    try {
      same = await ref.read(deskApiProvider).walletWithPhrase(_entry.phrase);
    } on Object {
      same = null;
    }
    if (!mounted) return;
    setState(() => _checking = false);
    if (same == null) {
      setState(() => _step = RestoreStep.account);
      return;
    }
    await _offerExisting(same);
  }

  /// "This wallet is already here": Open it goes to Unlock with [wallet] selected (the open
  /// wallet, if any, is locked first); a new password goes to Forgot password with the phrase
  /// typed here (R4); Cancel leaves the phrase on the grid.
  Future<void> _offerExisting(WalletEntry wallet) async {
    setState(() => _step = RestoreStep.words);
    final choice = await showSameWalletDialog(context, wallet);
    if (choice == SameWalletChoice.cancel || !mounted) return;
    if (choice == SameWalletChoice.newPassword) {
      ref.read(deskNavProvider.notifier).go(DeskRoute.resetPassword, ResetPasswordArg(wallet.id, phrase: _entry.phrase));
      return;
    }
    if (ref.read(deskProvider).account != null) {
      await ref.read(deskProvider.notifier).lock();
      if (!mounted) return;
    }
    ref.read(deskNavProvider.notifier).reset(DeskRoute.unlock, UnlockPick(wallet.id));
  }

  Future<void> _restore() async {
    final open = ref.read(deskProvider).account != null;
    setState(() {
      _step = RestoreStep.restoring;
      _failure = null;
      _locking = open;
    });
    try {
      final api = ref.read(deskApiProvider);
      final before = {for (final w in await api.wallets()) w.id};
      await api.restoreWallet(
        name: _name ?? '',
        password: _password.text,
        phrase: _entry.phrase,
        startHeight: _startHeight,
      );
      if (!mounted) return;
      if (open) {
        setState(() => _locking = true);
        await ref.read(deskProvider.notifier).lock();
        if (!mounted) return;
      }
      final added = await addedWallet(api, before, _name ?? defaultWalletName(ref), notice: context.l10n.deskOnbRestoreDone);
      if (!mounted) return;
      await markSetupPending(api, added.id, restored: true);
      if (!mounted) return;
      ref.read(deskNavProvider.notifier).reset(DeskRoute.setup, SetupFirstRun(added, second: before.isNotEmpty));
    } catch (e) {
      // The type, and for a refused DPAPI its code; never the password or the phrase.
      logWarn('desk', 'wallet not restored: ${e is SecretProtectError ? e : e.runtimeType}');
      if (!mounted) return;
      if (e is DeskError && e.sameWallet != null) {
        await _offerExisting(e.sameWallet!);
        return;
      }
      setState(() {
        _step = RestoreStep.failed;
        _failure = deskErrorText(e, context.l10n);
        _permissionDenied = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final flow = ref.watch(onbFlowProvider);
    final l = context.l10n;
    switch (_step) {
      case RestoreStep.restoring || RestoreStep.failed:
        // Back (mouse, Alt+Left) never leaves a restore that is running or has failed.
        return DeskStepBack(
          onBack: () {},
          child: ProgressView(
          title: _failure != null || _permissionDenied ? l.deskOnbRestoreNotRestored : l.deskOnbRestoreRestoring,
          stages: [
            Stage('restore', l.deskOnbRestoreRestoring),
            if (_locking) Stage('lock', l.deskOnbCreateLocking),
          ],
          current: 'restore',
          failed: 'restore',
          failure: _permissionDenied ? l.deskOnbRestorePermission : _failure,
          wait: l.deskOnbRestoreWait,
          onBack: () => setState(() {
            _step = RestoreStep.account;
            _failure = null;
          }),
          onRetry: _restore,
          ),
        );
      case RestoreStep.account:
        final (pe, ce) = accountErrors(context.l10n, _password.text, _confirm.text);
        // Back goes to the phrase, which stays filled in.
        return DeskStepBack(
          onBack: () => setState(() => _step = RestoreStep.words),
          child: EOnbFrame(
          sideTitle: l.deskOnbRestoreSide,
          steps: railOf([l.deskOnbStepPhrase, l.deskOnbStepPassword], 1),
          title: _name ?? defaultWalletName(ref),
          heading: WalletNameTitle(place: 'restore', name: _name, fallback: defaultWalletName(ref), onChanged: (v) => setState(() => _name = v)),
          lead: l.deskOnbRestorePasswordLead,
          actions: [
            backButton(() => setState(() => _step = RestoreStep.words)),
            EButton.primary(label: l.deskOnbRestoreSide, onPressed: _accountOk ? _restore : null),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (flow.testNet) ...[
                NetNote(flow.network, l.deskOnbCreateTestNote),
                SizedBox(height: Sp.x5),
              ],
              AccountForm(
                password: _password,
                confirm: _confirm,
                passwordError: pe,
                confirmError: ce,
                onChanged: () => setState(() {}),
                onSubmit: _accountOk ? _restore : null,
              ),
              SizedBox(height: Sp.x4),
              _startFrom(l),
            ],
          ),
          ),
        );
      case RestoreStep.words || RestoreStep.wordsFilled:
        // Typed words hold Back, so a thumb button never throws them away.
        return DeskStepBack(onBack: _entry.filled > 0 ? () {} : null, child: _wordsStep(context, nav));
    }
  }

  /// A small link, then the field: the block to start checking from (the whole chain when empty).
  Widget _startFrom(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ELink(
            key: const ValueKey('restore-from-link'),
            label: _fromOpen ? l.deskOnbRestoreFromHide : l.deskOnbRestoreFromLink,
            onPressed: () => setState(() => _fromOpen = !_fromOpen),
          ),
        ),
        ExpandFade(
          open: _fromOpen,
          child: Padding(
            padding: EdgeInsets.only(top: Sp.x3),
            child: EField(
              label: l.deskOnbRestoreFromLabel,
              help: _fromHeightOk ? l.deskOnbRestoreFromHelp : null,
              error: _fromHeightOk ? null : l.deskOnbRestoreFromInvalid,
              child: EInput(
                key: const ValueKey('restore-from-height'),
                controller: _fromHeight,
                mono: true,
                invalid: !_fromHeightOk,
                hint: l.deskOnbRestoreFromHint,
                semanticLabel: l.deskOnbRestoreFromLabel,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _wordsStep(BuildContext context, DeskNav nav) {
    final ts = context.ts;
    final c = context.dc;
    final l = context.l10n;
    final e = _entry;
    final filled = e.filled;
    final length = e.length;
    final bad = e.firstInvalid;
    final complete = e.complete;
    final narrow = MediaQuery.sizeOf(context).width < 760.u;
    final (String status, Color? tone) = switch (e) {
      _ when _clipboardEmpty => (l.deskOnbRestoreNothingToPaste, c.warn),
      _ when e.pasteError != null => (l.deskOnbRestorePasteCount(e.pasteError!), c.risk),
      _ when bad != null => (l.deskOnbRestoreBadWord(bad + 1, e.words[bad]), c.risk),
      _ when complete => (l.deskOnbRestoreAllOk(length), c.ok),
      _ when e.checksumOk == false && e.typingLast => (l.deskOnbRestoreStaysHere, null),
      _ when e.checksumOk == false && e.checksumFirm => (l.deskOnbRestoreChecksumFirm, c.risk),
      _ when e.checksumOk == false => (l.deskOnbRestoreChecksumSoFar(e.span), c.warn),
      _ => (l.deskOnbRestoreStaysHere, null),
    };
    return EOnbFrame(
      sideTitle: l.deskOnbRestoreSide,
      steps: railOf([l.deskOnbStepPhrase, l.deskOnbStepPassword], 0),
      title: l.deskOnbStepPhrase,
      lead: l.deskOnbRestoreWordsLead,
      actions: [
        backButton(() => nav.back()),
        // Words only on a narrow window, so the row fits "Use 24 words".
        EButton.ghost(label: l.commonPaste, icon: narrow ? null : EIcons.paste, onPressed: _pasteClipboard),
        EButton.ghost(label: l.deskOnbRestoreClear, icon: narrow ? null : EIcons.trash, onPressed: filled == 0 ? null : e.clear),
        // Names the length, so a typed 12-word phrase is never taken for 24 by mistake.
        EButton.primary(
          label: l.commonContinue,
          busy: _checking,
          onPressed: complete && !_checking ? _toAccount : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Semantics(header: true, child: Text(l.deskOnbRestoreWords, style: ts.label))),
              Text(
                l.deskOnbRestoreFilledOf(filled, length),
                style: ts.caption.copyWith(color: complete ? c.ok : null),
              ),
            ],
          ),
          SizedBox(height: Sp.x3),
          PhraseGrid(entry: e, autofocus: true, onSubmit: _toAccount),
          SizedBox(height: Sp.x3),
          // One line, always there, so the grid never moves when the verdict changes.
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 20.u),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.u),
                    child: Icon(
                      tone == c.risk
                          ? EIcons.error
                          : tone == c.ok
                          ? EIcons.check
                          : EIcons.info,
                      size: Ctl.iconSm,
                      color: tone ?? c.faint,
                    ),
                  ),
                  SizedBox(width: Sp.x2),
                  Expanded(child: Text(status, style: ts.small.copyWith(color: tone))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
