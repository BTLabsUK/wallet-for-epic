import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'onboarding_parts.dart';

enum RestoreStep { account, words, wordsFilled }

/// Restore: name and password, then the phrase. [arg] is a [RestoreStep]; `wordsFilled`
/// starts with a pasted phrase that has one word out of the list.
class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  static const _sample =
      'orbit hazard velvet cabin sudden meadow brick gesture lunar invest pledge saddle timber crisp wander echo faculty notable ripple garlic stamp dwarf enjoy h4rbor';
  static const _count = 24;

  final _name = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _paste = TextEditingController();
  final _words = [for (var i = 0; i < _count; i++) TextEditingController()];
  late bool _onWords = widget.arg == RestoreStep.words || widget.arg == RestoreStep.wordsFilled;
  final Set<int> _invalid = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.arg == RestoreStep.wordsFilled) {
      _fill(_sample);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _password, _confirm, _paste, ..._words]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _accountOk => _password.text.length >= 8 && _password.text == _confirm.text;
  int get _filled => _words.where((c) => c.text.trim().isNotEmpty).length;
  bool get _complete => _filled == _count && _invalid.isEmpty;

  List<String> _split(String text) => text
      .replaceAll(RegExp(r'\d+[.)]'), ' ')
      .split(RegExp(r'\s+'))
      .map((w) => w.trim().toLowerCase())
      .where((w) => w.isNotEmpty)
      .toList();

  void _fill(String text) {
    final ws = _split(text);
    for (var i = 0; i < _count; i++) {
      _words[i].text = i < ws.length ? ws[i] : '';
    }
    _paste.clear();
    setState(_invalid.clear);
    for (var i = 0; i < _count && i < ws.length; i++) {
      _check(i);
    }
  }

  Future<void> _check(int i) async {
    final w = _words[i].text.trim();
    final ok = w.isEmpty || await ref.read(deskApiProvider).checkPhraseWord(w);
    if (!mounted) return;
    setState(() => ok ? _invalid.remove(i) : _invalid.add(i));
  }

  void _onWord(int i, String v) {
    final ws = _split(v);
    if (ws.length > 1) {
      _fill(v);
      return;
    }
    _check(i);
    setState(() {});
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    await ref.read(deskApiProvider).restoreWallet(
      name: _name.text,
      password: _password.text,
      phrase: [for (final c in _words) c.text.trim()],
    );
    if (!mounted) return;
    ref.read(deskNavProvider.notifier).go(DeskRoute.setup);
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final ts = context.ts;
    final rail = railOf(['Password', 'Recovery phrase'], _onWords ? 1 : 0);
    if (!_onWords) {
      final (pe, ce) = accountErrors(_password.text, _confirm.text);
      return EOnbFrame(
        sideTitle: 'Restore wallet',
        steps: rail,
        title: 'Restore wallet',
        lead: 'Set the password that unlocks the restored wallet on this computer.',
        actions: [
          backButton(() => nav.back()),
          EButton.primary(label: 'Continue', onPressed: _accountOk ? () => setState(() => _onWords = true) : null),
        ],
        child: AccountForm(
          name: _name,
          password: _password,
          confirm: _confirm,
          passwordError: pe,
          confirmError: ce,
          onChanged: () => setState(() {}),
        ),
      );
    }
    final firstBad = _invalid.isEmpty ? null : (_invalid.toList()..sort()).first;
    return EOnbFrame(
      sideTitle: 'Restore wallet',
      steps: rail,
      title: 'Recovery phrase',
      lead: 'Paste all the words at once, or type them in the boxes. The phrase stays on this computer.',
      actions: [
        backButton(() => setState(() => _onWords = false)),
        EButton.primary(label: 'Restore wallet', busy: _busy, onPressed: _complete ? _restore : null),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (firstBad != null)
            ENotice(
              title: 'Word ${firstBad + 1}, "${_words[firstBad].text.trim()}", is not in the word list',
              text: 'Correct it in the numbered box.',
              tone: ETone.risk,
            )
          else if (_complete)
            ENotice(title: 'All $_count words are in the word list', tone: ETone.ok, icon: EIcons.check),
          if (firstBad != null || _complete) const SizedBox(height: Sp.x5),
          EField(
            label: 'Paste phrase',
            help: 'Line breaks, extra spaces and numbering are ignored.',
            aside: Text('$_filled of $_count words', style: ts.caption),
            child: EInput(
              controller: _paste,
              mono: true,
              maxLines: 3,
              hint: 'word1 word2 word3 …',
              semanticLabel: 'Paste phrase',
              onChanged: (v) {
                if (_split(v).length > 1) _fill(v);
              },
            ),
          ),
          const SizedBox(height: Sp.x5),
          LayoutBuilder(
            builder: (context, box) {
              final cols = box.maxWidth < 440 ? 2 : 3;
              final w = (box.maxWidth - (cols - 1) * Sp.x3) / cols;
              return Wrap(
                spacing: Sp.x3,
                runSpacing: Sp.x2,
                children: [
                  for (var i = 0; i < _count; i++)
                    SizedBox(
                      width: w,
                      child: Row(
                        children: [
                          SizedBox(width: 24, child: Text('${i + 1}', style: ts.caption, textAlign: TextAlign.right)),
                          const SizedBox(width: Sp.x2),
                          Expanded(
                            child: EInput(
                              controller: _words[i],
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
        ],
      ),
    );
  }
}
