import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'onboarding_parts.dart';

enum CreateStep { account, phrase, confirm }

/// New wallet: name and password, the phrase, a check of three words, then setup.
/// [arg] is a [CreateStep] to start on.
class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  static const _asked = [3, 11, 19];

  final _name = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _answers = [for (final _ in _asked) TextEditingController()];
  late CreateStep _step = widget.arg is CreateStep ? widget.arg as CreateStep : CreateStep.account;
  List<String>? _phrase;
  bool _revealed = false;
  bool _written = false;
  bool _busy = false;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    if (_step != CreateStep.account) {
      _revealed = _step == CreateStep.phrase;
      _written = _step == CreateStep.phrase;
      _loadPhrase();
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _password, _confirm, ..._answers]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPhrase() async {
    final p = await ref.read(deskApiProvider).newPhrase();
    if (mounted) setState(() => _phrase = p);
  }

  bool get _accountOk {
    final (p, c) = accountErrors(_password.text, _confirm.text);
    return _password.text.length >= 8 && _confirm.text == _password.text && p == null && c == null;
  }

  void _to(CreateStep s) => setState(() {
    _step = s;
    _wrong = false;
  });

  Future<void> _finish() async {
    final phrase = _phrase!;
    final given = [for (final c in _answers) c.text.trim().toLowerCase()];
    if ([for (final i in _asked) phrase[i]].indexed.any((e) => e.$2 != given[e.$1])) {
      setState(() => _wrong = true);
      return;
    }
    setState(() => _busy = true);
    await ref.read(deskApiProvider).createWallet(name: _name.text, password: _password.text, phrase: phrase);
    if (!mounted) return;
    ref.read(deskNavProvider.notifier).go(DeskRoute.setup);
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final index = _step.index;
    final rail = railOf(['Password', 'Recovery phrase', 'Check phrase'], index);
    switch (_step) {
      case CreateStep.account:
        final (pe, ce) = accountErrors(_password.text, _confirm.text);
        return EOnbFrame(
          sideTitle: 'New wallet',
          steps: rail,
          title: 'Create wallet',
          lead: 'The password unlocks this wallet on this computer. It cannot recover coins; the phrase on the next step does.',
          actions: [
            backButton(() => nav.back()),
            EButton.primary(
              label: 'Continue',
              onPressed: _accountOk
                  ? () {
                      _loadPhrase();
                      _to(CreateStep.phrase);
                    }
                  : null,
            ),
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
      case CreateStep.phrase:
        final phrase = _phrase;
        return EOnbFrame(
          sideTitle: 'New wallet',
          steps: rail,
          title: 'Recovery phrase',
          lead: 'These words are the only way to get the coins back if this computer breaks. Write them on paper, in order.',
          actions: [
            backButton(() => _to(CreateStep.account)),
            EButton.primary(label: 'Continue', onPressed: _revealed && _written ? () => _to(CreateStep.confirm) : null),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ENotice(
                title: 'Anyone with these words can take the coins',
                tone: ETone.warn,
                icon: EIcons.shield,
              ),
              const SizedBox(height: Sp.x5),
              if (phrase == null)
                const Padding(padding: EdgeInsets.all(Sp.x8), child: Center(child: ESpinner(size: 24)))
              else
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ESeedGrid(words: phrase, revealed: _revealed, columns: 4),
                    if (!_revealed)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          EButton.primary(label: 'Reveal phrase', icon: EIcons.eye, onPressed: () => setState(() => _revealed = true)),
                          const SizedBox(height: Sp.x2),
                          Text('Check that nobody can see the screen.', style: context.ts.small),
                        ],
                      ),
                  ],
                ),
              if (phrase != null && _revealed) ...[
                const SizedBox(height: Sp.x4),
                Row(
                  children: [
                    EButton.ghost(
                      label: 'Hide',
                      icon: EIcons.eyeOff,
                      onPressed: () => setState(() {
                        _revealed = false;
                        _written = false;
                      }),
                    ),
                    const SizedBox(width: Sp.x2),
                    EButton.ghost(
                      label: 'Copy',
                      icon: EIcons.copy,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: phrase.join(' ')));
                        showEToast(context, 'Copied. The clipboard is cleared in 60 s.');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: Sp.x4),
                ECheckbox(
                  value: _written,
                  onChanged: (v) => setState(() => _written = v),
                  label: 'Written down: all ${phrase.length} words on paper',
                ),
              ],
            ],
          ),
        );
      case CreateStep.confirm:
        return EOnbFrame(
          sideTitle: 'New wallet',
          steps: rail,
          title: 'Check the phrase',
          lead: 'Type the words at these positions to confirm the paper copy.',
          actions: [
            backButton(() => _to(CreateStep.phrase)),
            EButton.primary(
              label: 'Create wallet',
              busy: _busy,
              onPressed: _answers.every((c) => c.text.trim().isNotEmpty) ? _finish : null,
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_wrong) ...[
                const ENotice(title: 'A word does not match', text: 'Check the paper copy and try again.', tone: ETone.risk),
                const SizedBox(height: Sp.x5),
              ],
              for (var i = 0; i < _asked.length; i++) ...[
                EField(
                  label: 'Word ${_asked[i] + 1}',
                  child: EInput(
                    controller: _answers[i],
                    mono: true,
                    invalid: _wrong,
                    semanticLabel: 'Word ${_asked[i] + 1}',
                    onChanged: (_) => setState(() => _wrong = false),
                  ),
                ),
                const SizedBox(height: Sp.x4),
              ],
            ],
          ),
        );
    }
  }
}
