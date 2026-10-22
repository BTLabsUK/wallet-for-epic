import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import 'onboarding_parts.dart';
import 'phrase_grid.dart';

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
      'orbit hazard velvet cabin sudden meadow brick gesture lunar invest pledge saddle timber crisp wander echo faculty notable ripple garlic stamp dwarf enjoy h4rbor';

  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final PhraseEntry _entry;
  late RestoreStep _step = widget.arg is RestoreStep ? widget.arg as RestoreStep : RestoreStep.words;
  RestoreSample? get _sampleArg => widget.arg is RestoreSample ? widget.arg as RestoreSample : null;
  bool _locking = false;
  String? _failure;

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
        _failure = 'The wallet files could not be written: permission denied in ~/.config/Epic Wallet.';
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
    _entry.removeListener(_onEntry);
    _entry.dispose();
    super.dispose();
  }

  bool get _accountOk => _password.text.length >= 8 && _password.text == _confirm.text;

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (!mounted) return;
    if (PhraseEntry.split(text).isEmpty) {
      setState(() => _clipboardEmpty = true);
      return;
    }
    _clipboardEmpty = false;
    _entry.paste(text);
  }

  bool _clipboardEmpty = false;

  void _toAccount() => setState(() => _step = RestoreStep.account);

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
        password: _password.text,
        phrase: _entry.phrase,
      );
      if (!mounted) return;
      if (open) {
        setState(() => _locking = true);
        await ref.read(deskProvider.notifier).lock();
        if (!mounted) return;
      }
      final added = await addedWallet(api, before, 'Restored wallet', notice: 'Wallet restored.');
      if (!mounted) return;
      ref.read(deskNavProvider.notifier).reset(DeskRoute.unlock, added);
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = RestoreStep.failed;
          _failure = deskErrorText(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final flow = ref.watch(onbFlowProvider);
    switch (_step) {
      case RestoreStep.restoring || RestoreStep.failed:
        // Back (mouse, Alt+Left) never leaves a restore that is running or has failed.
        return DeskStepBack(
          onBack: () {},
          child: ProgressView(
          title: _failure != null ? 'Wallet not restored' : 'Restoring the wallet',
          failureTitle: 'The wallet could not be restored',
          stages: [
            const Stage('restore', 'Restoring the wallet'),
            if (_locking) const Stage('lock', 'Locking the open wallet'),
          ],
          current: 'restore',
          failed: 'restore',
          failure: _failure,
          wait: 'This can take up to a minute. The balance appears after the first scan of the chain.',
          onBack: () => setState(() {
            _step = RestoreStep.account;
            _failure = null;
          }),
          onRetry: _restore,
          ),
        );
      case RestoreStep.account:
        final (pe, ce) = accountErrors(_password.text, _confirm.text);
        // Back goes to the phrase, which stays filled in.
        return DeskStepBack(
          onBack: () => setState(() => _step = RestoreStep.words),
          child: EOnbFrame(
          sideTitle: 'Restore wallet',
          steps: railOf(['Recovery phrase', 'Password'], 1),
          title: 'Choose a password',
          lead: 'The ${_entry.length}-word phrase checks out. Set the password that unlocks this wallet on this computer. The wallet opens when it is restored.',
          actions: [
            backButton(() => setState(() => _step = RestoreStep.words)),
            EButton.primary(label: 'Restore wallet', onPressed: _accountOk ? _restore : null),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (flow.testNet) ...[
                NetNote(flow.network, 'A wallet on a test network, not for real EPIC'),
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
            ],
          ),
          ),
        );
      case RestoreStep.words || RestoreStep.wordsFilled:
        // Typed words hold Back, so a thumb button never throws them away.
        return DeskStepBack(onBack: _entry.filled > 0 ? () {} : null, child: _wordsStep(context, nav));
    }
  }

  Widget _wordsStep(BuildContext context, DeskNav nav) {
    final ts = context.ts;
    final c = context.dc;
    final e = _entry;
    final filled = e.filled;
    final length = e.length;
    final bad = e.firstInvalid;
    final complete = e.complete;
    final narrow = MediaQuery.sizeOf(context).width < 760.u;
    final (String status, Color? tone) = switch (e) {
      _ when _clipboardEmpty => ('Nothing to paste: the clipboard holds no words.', c.warn),
      _ when e.pasteError != null => (e.pasteError!, c.risk),
      _ when bad != null => ('Word ${bad + 1}, "${e.words[bad]}", is not in the word list.', c.risk),
      _ when complete => ('All $length words check out.', c.ok),
      _ when e.checksumOk == false && e.checksumFirm => (
        "This phrase's check number does not match. Compare every word with the paper.",
        c.risk,
      ),
      _ when e.checksumOk == false => (
        "${e.span} words so far; the check number does not match. Keep typing, or compare every word with the paper.",
        c.warn,
      ),
      _ => ('The phrase never leaves this computer.', null),
    };
    return EOnbFrame(
      sideTitle: 'Restore wallet',
      steps: railOf(['Recovery phrase', 'Password'], 0),
      title: 'Recovery phrase',
      lead: 'Type the words in order, or paste the whole phrase into any box. Line breaks, commas and numbering are ignored.',
      actions: [
        backButton(() => nav.back()),
        // Words only on a narrow window, so the row fits "Use 24 words".
        EButton.ghost(label: 'Paste', icon: narrow ? null : EIcons.paste, onPressed: _pasteClipboard),
        EButton.ghost(label: 'Clear', icon: narrow ? null : EIcons.trash, onPressed: filled == 0 ? null : e.clear),
        // Names the length, so a typed 12-word phrase is never taken for 24 by mistake.
        EButton.primary(label: complete ? 'Use $length words' : 'Continue', onPressed: complete ? _toAccount : null),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Semantics(header: true, child: Text('Words', style: ts.label))),
              Text(
                '$filled of $length words',
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
