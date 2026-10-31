// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../../log.dart';
import '../../widgets/kit.dart';
import 'onboarding_parts.dart';
import 'phrase_grid.dart';
import 'restore_screen.dart' show RestoreSample;
import 'unlock_screen.dart' show UnlockPick;

/// Forgot password for the listed wallet [walletId]: its recovery phrase, then a new
/// password. [phrase]: already typed (Restore's "This wallet is already here"), so the flow
/// starts on the password.
class ResetPasswordArg {
  const ResetPasswordArg(this.walletId, {this.phrase});

  final String walletId;
  final List<String>? phrase;
}

enum _Step { words, password, working, failed, unverifiable }

/// The phrase of a listed wallet sets a new password for it. The history, notes and labels
/// stay; nothing is scanned again. An open wallet is locked first. Unlock follows with the
/// wallet selected.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.arg});

  final Object? arg;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final PhraseEntry _entry;
  _Step _step = _Step.words;
  WalletEntry? _wallet;

  /// Under the grid: the phrase is not this wallet's, until the words change.
  String? _phraseError;
  String? _phraseErrorFor;
  String? _failure;
  bool _clipboardEmpty = false;
  bool _locking = false;

  ResetPasswordArg? get _arg => widget.arg is ResetPasswordArg ? widget.arg! as ResetPasswordArg : null;

  @override
  void initState() {
    super.initState();
    _entry = PhraseEntry(check: ref.read(deskApiProvider).checkPhrase)..addListener(_onEntry);
    final typed = _arg?.phrase;
    if (typed != null) {
      _entry.paste(typed.join(' '));
      if (_entry.complete) _step = _Step.password;
    }
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    final id = _arg?.walletId;
    try {
      final w = (await ref.read(deskApiProvider).wallets()).where((e) => e.id == id).firstOrNull;
      if (mounted) setState(() => _wallet = w);
    } on Object catch (e) {
      logWarn('desk', 'reset password: wallet list: ${e.runtimeType}');
    }
  }

  void _onEntry() {
    _clipboardEmpty = false;
    if (_phraseErrorFor != _entry.phrase.join(' ')) _phraseError = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _password.clear();
    _confirm.clear();
    _password.dispose();
    _confirm.dispose();
    _entry.removeListener(_onEntry);
    _entry.dispose();
    super.dispose();
  }

  bool get _passwordOk => passwordLongEnough(_password.text) && _password.text == _confirm.text;

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (!mounted) return;
    if (PhraseEntry.split(text).isEmpty) {
      setState(() => _clipboardEmpty = true);
      return;
    }
    _entry.pasteAndFocus(text);
  }

  /// Unlock, with the wallet the flow was for selected.
  void _toUnlock({String? notice}) {
    final w = _wallet;
    final id = _arg?.walletId;
    ref
        .read(deskNavProvider.notifier)
        .reset(
          DeskRoute.unlock,
          id == null
              ? null
              : notice == null
              ? UnlockPick(id)
              : UnlockAdded(w?.name ?? '', id: id, notice: notice),
        );
  }

  /// The phrase is looked up in the list before the password step: a phrase of another wallet
  /// stays on the grid at once when the list knows this wallet's fingerprint (the core checks
  /// again at the end either way).
  bool _checking = false;

  Future<void> _toPassword() async {
    final id = _arg?.walletId;
    if (id == null || _checking) return;
    setState(() => _checking = true);
    bool? mine;
    try {
      mine = await ref.read(deskApiProvider).phraseIsOf(id, _entry.phrase);
    } on Object {
      mine = null;
    }
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (mine == false) {
        _phraseError = context.l10n.deskOnbForgotOtherWallet(_wallet?.name ?? context.l10n.deskOnbUnlockThisWallet);
        _phraseErrorFor = _entry.phrase.join(' ');
      } else {
        _step = _Step.password;
      }
    });
  }

  /// The way out when the wallet's files cannot confirm the phrase: the wallet leaves the list
  /// (its files stay, Settings › All wallets can add it back) and Restore opens with the phrase.
  Future<void> _restoreInstead() async {
    final id = _arg?.walletId;
    if (id == null) return;
    setState(() => _checking = true);
    try {
      await ref.read(deskProvider.notifier).removeWallet(id, WalletRemoval.list);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _failure = deskErrorText(e, context.l10n);
      });
      return;
    }
    if (!mounted) return;
    ref.read(deskNavProvider.notifier).reset(DeskRoute.restore, RestoreSample(_entry.phrase.join(' ')));
  }

  Future<void> _reset() async {
    final id = _arg?.walletId;
    if (id == null || !_passwordOk) return;
    final open = ref.read(deskProvider).account?.id == id;
    setState(() {
      _step = _Step.working;
      _failure = null;
      _locking = open;
    });
    try {
      // The core changes only a closed wallet.
      if (open) await ref.read(deskProvider.notifier).lock();
      if (!mounted) return;
      await ref.read(deskApiProvider).resetPassword(id, phrase: _entry.phrase, newPassword: _password.text);
      if (!mounted) return;
      _toUnlock(notice: context.l10n.deskSetDlgPwChanged);
    } on Object catch (e) {
      logWarn('desk', 'password not reset: ${e.runtimeType}');
      if (!mounted) return;
      final text = deskErrorText(e, context.l10n);
      if (e is DeskError && e.resetUnverifiable) {
        setState(() {
          _step = _Step.unverifiable;
          _failure = text;
        });
        return;
      }
      if (e is DeskError && e.wrongPhrase) {
        setState(() {
          _step = _Step.words;
          _phraseError = text;
          _phraseErrorFor = _entry.phrase.join(' ');
        });
        return;
      }
      setState(() {
        _step = _Step.failed;
        _failure = text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = _wallet?.name ?? l.deskOnbUnlockThisWallet;
    switch (_step) {
      case _Step.unverifiable:
        return DeskStepBack(
          onBack: () => setState(() => _step = _Step.words),
          child: EOnbFrame(
            sideTitle: l.deskOnbForgotTitle,
            steps: railOf([l.deskOnbStepPhrase, l.deskOnbStepPassword], 1),
            title: l.deskErrPasswordNotChanged,
            actions: [
              backButton(() => setState(() => _step = _Step.words)),
              EButton.primary(key: const ValueKey('reset-restore-instead'), label: l.deskOnbForgotRestoreInstead, busy: _checking, onPressed: _checking ? null : _restoreInstead),
            ],
            child: ENotice(tone: ETone.warn, title: l.deskOnbForgotTitle, text: _failure),
          ),
        );
      case _Step.working || _Step.failed:
        return DeskStepBack(
          onBack: () {},
          child: ProgressView(
            title: _failure != null ? l.deskErrPasswordNotChanged : l.deskOnbForgotTitle,
            stages: [if (_locking) Stage('lock', l.deskOnbCreateLocking), Stage('reset', l.deskOnbForgotTitle)],
            current: 'reset',
            failed: 'reset',
            failure: _failure,
            onBack: () => setState(() {
              _step = _Step.password;
              _failure = null;
            }),
            onRetry: _reset,
          ),
        );
      case _Step.password:
        final (pe, ce) = accountErrors(l, _password.text, _confirm.text);
        return DeskStepBack(
          onBack: () => setState(() => _step = _Step.words),
          child: EOnbFrame(
            sideTitle: l.deskOnbForgotTitle,
            steps: railOf([l.deskOnbStepPhrase, l.deskOnbStepPassword], 1),
            title: l.deskSetDlgPwNew,
            lead: l.deskOnbForgotPasswordLead,
            actions: [
              backButton(() => setState(() => _step = _Step.words)),
              EButton.primary(key: const ValueKey('reset-password-save'), label: l.deskOnbForgotSet, onPressed: _passwordOk ? _reset : null),
            ],
            child: AccountForm(password: _password, confirm: _confirm, passwordError: pe, confirmError: ce, onChanged: () => setState(() {}), onSubmit: _passwordOk ? _reset : null),
          ),
        );
      case _Step.words:
        return DeskStepBack(onBack: _entry.filled > 0 ? () {} : () => _toUnlock(), child: _words(context, name));
    }
  }

  Widget _words(BuildContext context, String name) {
    final ts = context.ts;
    final c = context.dc;
    final l = context.l10n;
    final e = _entry;
    final bad = e.firstInvalid;
    final complete = e.complete;
    final narrow = MediaQuery.sizeOf(context).width < Lay.lg;
    final (String? status, Color? tone) = switch (e) {
      _ when _phraseError != null => (_phraseError!, c.risk),
      _ when _clipboardEmpty => (l.deskOnbRestoreNothingToPaste, c.warn),
      _ when e.pasteError != null => (l.deskOnbRestorePasteCount(e.pasteError!), c.risk),
      _ when bad != null => (l.deskOnbRestoreBadWord(bad + 1, e.words[bad]), c.risk),
      _ when complete => (l.deskOnbRestoreAllOk(e.length), c.ok),
      _ when e.checksumOk == false && e.checksumFirm => (l.deskOnbRestoreChecksumFirm, c.risk),
      _ => (null, null),
    };
    return EOnbFrame(
      sideTitle: l.deskOnbForgotTitle,
      steps: railOf([l.deskOnbStepPhrase, l.deskOnbStepPassword], 0),
      title: l.deskOnbStepPhrase,
      lead: l.deskOnbForgotLead(name),
      actions: [
        backButton(() => _toUnlock()),
        EButton.ghost(label: l.commonPaste, icon: narrow ? null : EIcons.paste, onPressed: _pasteClipboard),
        EButton.ghost(label: l.deskOnbRestoreClear, icon: narrow ? null : EIcons.trash, onPressed: e.filled == 0 ? null : e.clear),
        EButton.primary(
          key: const ValueKey('reset-password-words'),
          label: l.commonContinue,
          busy: _checking,
          onPressed: complete && !_checking ? _toPassword : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhraseGrid(entry: e, autofocus: true, onSubmit: complete && !_checking ? _toPassword : null),
          SizedBox(height: Sp.x3),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 20.u),
            child: status == null ? null : Semantics(
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
                  Expanded(
                    child: Text(
                      status,
                      key: const ValueKey('reset-password-status'),
                      style: ts.small.copyWith(color: tone),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
