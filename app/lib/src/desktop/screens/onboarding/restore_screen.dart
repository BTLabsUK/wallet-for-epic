import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import 'onboarding_parts.dart';

enum RestoreStep { words, wordsFilled, account, restoring, failed }

/// Restore: the phrase, then name and password, then the wallet is restored and Unlock opens
/// with it. [arg] is a [RestoreStep]; `wordsFilled` starts with a pasted phrase that has one
/// word out of the list.
class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

const _lengths = [12, 15, 18, 21, 24];

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  static const _sample =
      'orbit hazard velvet cabin sudden meadow brick gesture lunar invest pledge saddle timber crisp wander echo faculty notable ripple garlic stamp dwarf enjoy h4rbor';
  static const _max = 24;

  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _paste = TextEditingController();
  final _words = [for (var i = 0; i < _max; i++) TextEditingController()];
  final _focus = [for (var i = 0; i < _max; i++) FocusNode()];
  late RestoreStep _step = widget.arg is RestoreStep ? widget.arg as RestoreStep : RestoreStep.words;
  int _length = 24;
  final Set<int> _invalid = {};
  bool _locking = false;
  String? _failure;

  @override
  void initState() {
    super.initState();
    switch (_step) {
      case RestoreStep.wordsFilled:
        _paste.text = _sample;
        _fromText(_sample);
      case RestoreStep.failed:
        _failure = 'The wallet files could not be written: permission denied in ~/.config/Epic Wallet.';
      case RestoreStep.words || RestoreStep.account || RestoreStep.restoring:
        break;
    }
  }

  @override
  void dispose() {
    for (final c in [_password, _confirm, _paste, ..._words]) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _accountOk => _password.text.length >= 8 && _password.text == _confirm.text;
  int get _filled => _words.where((c) => c.text.trim().isNotEmpty).length;
  int get _badCount => _invalid.where((i) => i < _length).length;
  bool get _complete =>
      _filled == _length && _words.take(_length).every((c) => c.text.trim().isNotEmpty) && _badCount == 0;

  List<String> _split(String text) => text
      .replaceAll(RegExp(r'\d+[.)]'), ' ')
      .split(RegExp(r'\s+'))
      .map((w) => w.trim().toLowerCase())
      .where((w) => w.isNotEmpty)
      .toList();

  /// Spreads the words of [text] over the boxes; a phrase of a valid length sets the length.
  void _fromText(String text) {
    final ws = _split(text);
    if (_lengths.contains(ws.length)) {
      _length = ws.length;
    } else if (ws.length > _length) {
      _length = _lengths.firstWhere((n) => n >= ws.length, orElse: () => _max);
    }
    for (var i = 0; i < _max; i++) {
      _words[i].text = i < ws.length ? ws[i] : '';
    }
    setState(_invalid.clear);
    for (var i = 0; i < _max && i < ws.length; i++) {
      _check(i);
    }
  }

  Future<void> _check(int i) async {
    final w = _words[i].text.trim();
    final ok = w.isEmpty || await ref.read(deskApiProvider).checkPhraseWord(w);
    if (!mounted) return;
    setState(() => ok ? _invalid.remove(i) : _invalid.add(i));
  }

  void _syncPaste() {
    final ws = [for (final c in _words) c.text.trim()];
    while (ws.isNotEmpty && ws.last.isEmpty) {
      ws.removeLast();
    }
    _paste.text = ws.join(' ');
  }

  void _onWord(int i, String v) {
    final ws = _split(v);
    if (ws.length > 1) {
      _fromText([for (var j = 0; j < i; j++) _words[j].text, v].join(' '));
      _syncPaste();
      return;
    }
    // Space moves on to the next box.
    if (v.endsWith(' ') && ws.length == 1) {
      _words[i].text = ws.first;
      if (i + 1 < _length) _focus[i + 1].requestFocus();
    }
    _check(i);
    _syncPaste();
    setState(() {});
  }

  void _clear() {
    _paste.clear();
    for (final c in _words) {
      c.clear();
    }
    setState(_invalid.clear);
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
        password: _password.text,
        phrase: [for (final c in _words.take(_length)) c.text.trim()],
      );
      if (!mounted) return;
      if (open) {
        setState(() => _locking = true);
        await ref.read(deskProvider.notifier).lock();
        if (!mounted) return;
      }
      final added = await addedWallet(api, before, 'Restored wallet');
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
        return ProgressView(
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
        );
      case RestoreStep.account:
        final (pe, ce) = accountErrors(_password.text, _confirm.text);
        return EOnbFrame(
          sideTitle: 'Restore wallet',
          steps: railOf(['Recovery phrase', 'Password'], 1),
          title: 'Choose a password',
          lead: 'The phrase checks out. Set the password that unlocks this wallet on this computer. The wallet opens when it is restored.',
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
              ),
            ],
          ),
        );
      case RestoreStep.words || RestoreStep.wordsFilled:
        return _wordsStep(context, nav);
    }
  }

  Widget _wordsStep(BuildContext context, DeskNav nav) {
    final ts = context.ts;
    final c = context.dc;
    final filled = _filled;
    final bad = _badCount;
    final tooMany = filled > _length;
    final firstBad = bad == 0 ? null : (_invalid.where((i) => i < _length).toList()..sort()).first;
    final hint = _complete
        ? null
        : filled == 0
        ? 'Paste the phrase to continue'
        : bad > 0
        ? 'Fix the marked words to continue'
        : '$filled of $_length words';
    return EOnbFrame(
      sideTitle: 'Restore wallet',
      steps: railOf(['Recovery phrase', 'Password'], 0),
      title: 'Recovery phrase',
      lead: 'Paste all the words at once, or type them with spaces in between. They appear below, numbered, to check against the paper.',
      actions: [
        backButton(() => nav.back()),
        EButton.ghost(label: 'Clear', icon: EIcons.trash, onPressed: filled == 0 ? null : _clear),
        if (hint != null) Flexible(child: Text(hint, style: ts.caption, textAlign: TextAlign.right)),
        EButton.primary(label: 'Continue', onPressed: _complete ? () => setState(() => _step = RestoreStep.account) : null),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (firstBad != null)
            ENotice(
              title: 'Word ${firstBad + 1}, "${_words[firstBad].text.trim()}", is not in the word list',
              text: 'Correct it in the numbered boxes below.',
              tone: ETone.risk,
            )
          else if (_complete)
            ENotice(
              title: 'All $_length words are in the word list',
              text: 'Next, set a password for this computer.',
              tone: ETone.ok,
              icon: EIcons.check,
            ),
          if (firstBad != null || _complete) SizedBox(height: Sp.x5),
          EField(
            label: 'Recovery phrase',
            help: 'Line breaks, extra spaces and numbering like "1." are ignored. Pasting into any word box fills them all.',
            aside: Semantics(
              liveRegion: true,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$filled of $_length words',
                      style: ts.caption.copyWith(color: tooMany ? c.risk : (_complete ? c.ok : null)),
                    ),
                    if (bad > 0) TextSpan(text: ' · $bad not in the word list', style: ts.caption.copyWith(color: c.risk)),
                    if (tooMany)
                      TextSpan(text: ' · a phrase has 12, 15, 18, 21 or 24 words', style: ts.caption.copyWith(color: c.risk)),
                  ],
                ),
              ),
            ),
            child: EInput(
              controller: _paste,
              mono: true,
              maxLines: 4,
              invalid: bad > 0,
              hint: 'word1 word2 word3 …',
              semanticLabel: 'Recovery phrase',
              onChanged: _fromText,
            ),
          ),
          SizedBox(height: Sp.x4),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 200.u,
              child: EField(
                label: 'Length',
                child: ESelect<int>(
                  semanticLabel: 'Phrase length',
                  value: _length,
                  onChanged: (v) => setState(() => _length = v),
                  items: [for (final n in _lengths) ESelectItem(n, '$n words')],
                ),
              ),
            ),
          ),
          SizedBox(height: Sp.x5),
          if (filled == 0)
            Container(
              padding: EdgeInsets.all(Sp.x6),
              decoration: BoxDecoration(
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(Rad.sm),
              ),
              child: Row(
                children: [
                  Icon(EIcons.paste, size: Ctl.iconLg, color: c.faint),
                  SizedBox(width: Sp.x3),
                  Expanded(child: Text('The words appear here, numbered, once they are pasted or typed.', style: ts.bodyDim)),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Semantics(header: true, child: Text('Check the words', style: ts.label)),
                SizedBox(width: Sp.x2),
                Flexible(child: Text('Click a word to correct it', style: ts.caption)),
              ],
            ),
            SizedBox(height: Sp.x3),
            LayoutBuilder(
              builder: (context, box) {
                final cols = box.maxWidth < 440.u ? 2 : 3;
                final w = (box.maxWidth - (cols - 1) * Sp.x3) / cols;
                return Wrap(
                  spacing: Sp.x3,
                  runSpacing: Sp.x2,
                  children: [
                    for (var i = 0; i < _length; i++)
                      SizedBox(
                        width: w,
                        child: Row(
                          children: [
                            SizedBox(width: 24.u, child: Text('${i + 1}', style: ts.caption, textAlign: TextAlign.right)),
                            SizedBox(width: Sp.x2),
                            Expanded(
                              child: EInput(
                                controller: _words[i],
                                focusNode: _focus[i],
                                mono: true,
                                invalid: _invalid.contains(i),
                                semanticLabel: 'Word ${i + 1}',
                                onChanged: (v) => _onWord(i, v),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: Sp.x4),
            Row(
              children: [
                Icon(EIcons.info, size: Ctl.iconSm, color: c.faint),
                SizedBox(width: Sp.x2),
                Flexible(child: Text('The phrase never leaves this computer.', style: ts.small)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
