import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import 'onboarding_parts.dart';

enum CreateStep { account, creating, failed, phrase, confirm, locking }

/// New wallet: name and password, the wallet is made, its phrase, a check of three words, then
/// Unlock with the new wallet. [arg] is a [CreateStep] to start on.
class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

const _createStages = [Stage('create', 'Creating the wallet and its recovery phrase'), Stage('save', 'Saving the account')];

class _CreateScreenState extends ConsumerState<CreateScreen> {
  static const _asked = [3, 11, 19];

  final _name = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _answers = [for (final _ in _asked) TextEditingController()];
  late CreateStep _step = widget.arg is CreateStep ? widget.arg as CreateStep : CreateStep.account;
  List<String>? _phrase;
  String _stage = 'create';
  String? _failure;
  bool _revealed = false;
  bool _written = false;
  bool _qr = false;
  bool _busy = false;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    switch (_step) {
      case CreateStep.phrase || CreateStep.confirm:
        _revealed = _step == CreateStep.phrase;
        _written = _step == CreateStep.phrase;
        ref.read(deskApiProvider).newPhrase().then((p) => mounted ? setState(() => _phrase = p) : null);
      case CreateStep.failed:
        _stage = 'save';
        _failure = 'The account could not be saved: the disk is full.';
      case CreateStep.creating || CreateStep.locking || CreateStep.account:
        break;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _password, _confirm, ..._answers]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _accountOk {
    final (p, c) = accountErrors(_password.text, _confirm.text);
    return _password.text.length >= 8 && _confirm.text == _password.text && p == null && c == null;
  }

  void _to(CreateStep s) => setState(() {
    _step = s;
    _wrong = false;
  });

  /// Makes the wallet and its phrase (Electron does this before showing the phrase).
  Future<void> _create() async {
    final api = ref.read(deskApiProvider);
    setState(() {
      _step = CreateStep.creating;
      _stage = 'create';
      _failure = null;
    });
    try {
      final phrase = await api.createWallet(name: _name.text, password: _password.text);
      if (!mounted) return;
      setState(() => _stage = 'save');
      setState(() {
        _phrase = phrase;
        _step = CreateStep.phrase;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = CreateStep.failed;
          _failure = deskErrorText(e);
        });
      }
    }
  }

  /// The check passed: a wallet open now is locked, then Unlock with the new one.
  Future<void> _finish() async {
    final phrase = _phrase!;
    final given = [for (final c in _answers) c.text.trim().toLowerCase()];
    if ([for (final i in _asked) phrase[i]].indexed.any((e) => e.$2 != given[e.$1])) {
      setState(() => _wrong = true);
      return;
    }
    setState(() => _busy = true);
    if (ref.read(deskProvider).account != null) {
      _to(CreateStep.locking);
      await ref.read(deskProvider.notifier).lock();
      if (!mounted) return;
    }
    final name = _name.text.trim();
    ref.read(deskNavProvider.notifier).reset(DeskRoute.unlock, UnlockAdded(name.isEmpty ? 'New wallet' : name));
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final flow = ref.watch(onbFlowProvider);
    final rail = railOf(['Password', 'Recovery phrase', 'Check phrase'], switch (_step) {
      CreateStep.phrase => 1,
      CreateStep.confirm || CreateStep.locking => 2,
      _ => 0,
    });
    switch (_step) {
      case CreateStep.creating || CreateStep.failed:
        return ProgressView(
          title: _failure != null ? 'Wallet not created' : 'Creating the wallet',
          lead: flow.testNet ? 'A wallet on ${networkName(flow.network)}, a test network.' : null,
          failureTitle: 'The wallet could not be created',
          stages: _createStages,
          current: _stage,
          failed: _stage,
          failure: _failure,
          wait: 'This can take up to a minute. Keep the app open.',
          onBack: () => _to(CreateStep.account),
          onRetry: _create,
        );
      case CreateStep.locking:
        return const ProgressView(
          title: 'Locking the open wallet',
          stages: [Stage('lock', 'Locking the open wallet')],
          current: 'lock',
        );
      case CreateStep.account:
        final (pe, ce) = accountErrors(_password.text, _confirm.text);
        return EOnbFrame(
          sideTitle: 'New wallet',
          steps: rail,
          title: 'Create wallet',
          lead: 'The password unlocks this wallet on this computer. It cannot recover coins; the phrase on the next step does.',
          actions: [
            backButton(() => nav.back()),
            EButton.primary(label: 'Create wallet', onPressed: _accountOk ? _create : null),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (flow.testNet) ...[
                NetNote(flow.network, 'A wallet on a test network, not for real EPIC'),
                SizedBox(height: Sp.x5),
              ],
              AccountForm(
                name: _name,
                password: _password,
                confirm: _confirm,
                passwordError: pe,
                confirmError: ce,
                onChanged: () => setState(() {}),
              ),
            ],
          ),
        );
      case CreateStep.phrase:
        return _phraseStep(context, rail);
      case CreateStep.confirm:
        return EOnbFrame(
          sideTitle: 'New wallet',
          steps: rail,
          title: 'Check the phrase',
          lead: 'Type the words at these positions to confirm the paper copy.',
          actions: [
            backButton(() => _to(CreateStep.phrase)),
            EButton.primary(
              label: 'Continue',
              busy: _busy,
              onPressed: _answers.every((c) => c.text.trim().isNotEmpty) ? _finish : null,
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_wrong) ...[
                const ENotice(title: 'A word does not match', text: 'Check the paper copy and try again.', tone: ETone.risk),
                SizedBox(height: Sp.x5),
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
                SizedBox(height: Sp.x4),
              ],
            ],
          ),
        );
    }
  }

  Widget _phraseStep(BuildContext context, List<ERailStep> rail) {
    final phrase = _phrase;
    final ts = context.ts;
    return EOnbFrame(
      sideTitle: 'New wallet',
      steps: rail,
      title: 'Recovery phrase',
      lead: 'These words are the only way to get the coins back if this computer breaks. Write them on paper, in order.',
      actions: [
        if (!_revealed) Flexible(child: Text('Reveal the phrase first', style: ts.caption, textAlign: TextAlign.right)),
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
          SizedBox(height: Sp.x5),
          if (phrase == null)
            Padding(padding: EdgeInsets.all(Sp.x8), child: Center(child: ESpinner(size: 24.u)))
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
                      SizedBox(height: Sp.x2),
                      Text('Check that nobody can see the screen.', style: ts.small),
                    ],
                  ),
              ],
            ),
          if (phrase != null && _revealed) ...[
            SizedBox(height: Sp.x4),
            Wrap(
              spacing: Sp.x2,
              runSpacing: Sp.x2,
              children: [
                EButton.ghost(
                  label: 'Hide',
                  icon: EIcons.eyeOff,
                  onPressed: () => setState(() {
                    _revealed = false;
                    _written = false;
                    _qr = false;
                  }),
                ),
                EButton.ghost(
                  label: 'Copy',
                  icon: EIcons.copy,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: phrase.join(' ')));
                    showEToast(context, 'Copied. The clipboard is cleared in 60 s.');
                  },
                ),
                EButton.ghost(
                  label: _qr ? 'Hide QR code' : 'Show QR code',
                  icon: EIcons.qr,
                  onPressed: () => setState(() => _qr = !_qr),
                ),
              ],
            ),
            if (_qr) ...[
              SizedBox(height: Sp.x4),
              ENotice(
                title: 'Anyone who scans this code can take the coins',
                text: 'Scan it only into another wallet you trust.',
                tone: ETone.risk,
                icon: EIcons.alert,
              ),
              SizedBox(height: Sp.x4),
              Center(
                child: Semantics(
                  label: 'Recovery phrase as a QR code',
                  image: true,
                  child: EQr(phrase.join(' '), size: 216.u),
                ),
              ),
            ],
            SizedBox(height: Sp.x4),
            ECheckbox(
              value: _written,
              onChanged: (v) => setState(() => _written = v),
              label: 'Written down: all ${phrase.length} words on paper',
            ),
          ],
        ],
      ),
    );
  }
}
