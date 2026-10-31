// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../../log.dart';
import '../../../secret_store_api.dart' show SecretProtectError;
import '../../widgets/kit.dart';
import '../settings/settings_phrase.dart' show copyPhrase;
import 'onboarding_parts.dart';
import 'setup_screen.dart' show SetupFirstRun;

enum CreateStep { account, creating, failed, phrase, locking }

/// New wallet: password, the wallet is made, its phrase, then
/// Unlock with the new wallet. [arg] is a [CreateStep] to start on.
class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

List<Stage> _createStages(AppLocalizations l) => [Stage('create', l.deskOnbCreateStageCreate), Stage('save', l.deskOnbCreateStageSave)];

class _CreateScreenState extends ConsumerState<CreateScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late CreateStep _step = widget.arg is CreateStep ? widget.arg as CreateStep : CreateStep.account;
  List<String>? _phrase;

  /// The name typed into the title; null keeps the default "Wallet N".
  String? _name;
  String _stage = 'create';
  String? _failure;

  /// The shots' failed step: the disk-full failure, worded in build (initState has no l10n).
  bool _diskFull = false;
  bool _revealed = false;
  bool _written = false;
  bool _qr = false;
  bool _busy = false;
  Set<String> _before = {};

  @override
  void initState() {
    super.initState();
    switch (_step) {
      case CreateStep.phrase:
        _revealed = true;
        _written = true;
        ref.read(deskApiProvider).newPhrase().then((p) => mounted ? setState(() => _phrase = p) : null);
      case CreateStep.failed:
        _stage = 'save';
        _diskFull = true;
      case CreateStep.creating || CreateStep.locking || CreateStep.account:
        break;
    }
  }

  @override
  void dispose() {
    for (final c in [_password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _accountOk {
    final (p, c) = accountErrors(context.l10n, _password.text, _confirm.text);
    return passwordLongEnough(_password.text) && _confirm.text == _password.text && p == null && c == null;
  }

  void _to(CreateStep s) => setState(() => _step = s);

  /// Makes the wallet and its phrase (Electron does this before showing the phrase).
  Future<void> _create() async {
    final api = ref.read(deskApiProvider);
    setState(() {
      _step = CreateStep.creating;
      _stage = 'create';
      _failure = null;
      _diskFull = false;
    });
    try {
      _before = {for (final w in await api.wallets()) w.id};
      final phrase = await api.createWallet(name: _name ?? '', password: _password.text);
      if (!mounted) return;
      setState(() => _stage = 'save');
      setState(() {
        _phrase = phrase;
        _step = CreateStep.phrase;
      });
    } catch (e) {
      // The type, and for a refused DPAPI its code; never the password or the phrase.
      logWarn('desk', 'wallet not created: ${e is SecretProtectError ? e : e.runtimeType}');
      if (mounted) {
        setState(() {
          _step = CreateStep.failed;
          _failure = deskErrorText(e, context.l10n);
        });
      }
    }
  }

  /// The phrase is written down: a wallet open now is locked, then Unlock with the new one.
  Future<void> _finish() async {
    setState(() => _busy = true);
    if (ref.read(deskProvider).account != null) {
      _to(CreateStep.locking);
      await ref.read(deskProvider.notifier).lock();
      if (!mounted) return;
    }
    final added = await addedWallet(ref.read(deskApiProvider), _before, _name ?? defaultWalletName(ref));
    if (!mounted) return;
    await markSetupPending(ref.read(deskApiProvider), added.id);
    if (!mounted) return;
    ref.read(deskNavProvider.notifier).reset(DeskRoute.setup, SetupFirstRun(added, second: _before.isNotEmpty));
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final flow = ref.watch(onbFlowProvider);
    final l = context.l10n;
    final rail = railOf([l.deskOnbStepPassword, l.deskOnbStepPhrase], switch (_step) {
      CreateStep.phrase || CreateStep.locking => 1,
      _ => 0,
    });
    switch (_step) {
      case CreateStep.creating || CreateStep.failed:
        return ProgressView(
          title: _failure != null || _diskFull ? l.deskOnbCreateNotCreated : l.deskOnbCreateCreating,
          lead: flow.testNet ? l.deskOnbCreateTestLead(networkName(flow.network)) : null,
          stages: _createStages(l),
          current: _stage,
          failed: _stage,
          failure: _diskFull ? l.deskOnbCreateDiskFull : _failure,
          wait: l.deskOnbCreateWait,
          onBack: () => _to(CreateStep.account),
          onRetry: _create,
        );
      case CreateStep.locking:
        return ProgressView(
          title: l.deskOnbCreateLocking,
          stages: [Stage('lock', l.deskOnbCreateLocking)],
          current: 'lock',
        );
      case CreateStep.account:
        final (pe, ce) = accountErrors(context.l10n, _password.text, _confirm.text);
        // Typed passwords hold Back (mouse, Alt+Left).
        return DeskStepBack(
          onBack: _password.text.isNotEmpty || _confirm.text.isNotEmpty ? () {} : null,
          child: EOnbFrame(
          sideTitle: l.deskOnbCreateSide,
          steps: rail,
          title: _name ?? defaultWalletName(ref),
          heading: WalletNameTitle(place: 'create', name: _name, fallback: defaultWalletName(ref), onChanged: (v) => setState(() => _name = v)),
          lead: l.deskOnbCreateLead,
          actions: [
            backButton(() => nav.back()),
            EButton.primary(label: l.deskOnbCreateTitle, onPressed: _accountOk ? _create : null),
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
                onSubmit: _accountOk ? _create : null,
              ),
            ],
          ),
          ),
        );
      case CreateStep.phrase:
        return _phraseStep(context, rail);
    }
  }

  Widget _phraseStep(BuildContext context, List<ERailStep> rail) {
    final phrase = _phrase;
    final ts = context.ts;
    final l = context.l10n;
    // The wallet exists now: Back (mouse, Alt+Left) must not leave its phrase unseen.
    return DeskStepBack(
      onBack: () {},
      child: EOnbFrame(
      sideTitle: l.deskOnbCreateSide,
      steps: rail,
      title: l.deskOnbStepPhrase,
      lead: l.deskOnbCreatePhraseLead,
      actions: [
        if (!_revealed) Flexible(child: Text(l.deskOnbCreateRevealFirst, style: ts.caption, textAlign: TextAlign.right)),
        EButton.primary(label: l.commonContinue, busy: _busy, onPressed: _revealed && _written ? _finish : null),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ENotice(
            title: l.deskOnbCreateWarn,
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
                // On a backdrop of its own: in a small window the caption sits over the word boxes.
                if (!_revealed)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
                    decoration: BoxDecoration(
                      color: context.dc.s1,
                      borderRadius: BorderRadius.circular(Rad.sm),
                      border: Border.all(color: context.dc.line),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EButton.primary(label: l.deskOnbCreateReveal, icon: EIcons.eye, onPressed: () => setState(() => _revealed = true)),
                        SizedBox(height: Sp.x2),
                        Text(l.deskOnbCreateCheckScreen, style: ts.small, textAlign: TextAlign.center),
                      ],
                    ),
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
                  label: l.deskOnbCreateHide,
                  icon: EIcons.eyeOff,
                  onPressed: () => setState(() {
                    _revealed = false;
                    _written = false;
                    _qr = false;
                  }),
                ),
                EButton.ghost(
                  label: l.commonCopy,
                  icon: EIcons.copy,
                  onPressed: () => copyPhrase(context, phrase.join(' ')),
                ),
                EButton.ghost(
                  label: _qr ? l.deskOnbCreateHideQr : l.deskOnbCreateShowQr,
                  icon: EIcons.qr,
                  onPressed: () => setState(() => _qr = !_qr),
                ),
              ],
            ),
            if (_qr) ...[
              SizedBox(height: Sp.x4),
              ENotice(
                title: l.deskOnbCreateQrWarn,
                text: l.deskOnbCreateQrWarnText,
                tone: ETone.risk,
                icon: EIcons.alert,
              ),
              SizedBox(height: Sp.x4),
              Center(
                child: Semantics(
                  label: l.deskOnbCreateQrLabel,
                  image: true,
                  child: EQr(phrase.join(' '), size: 216.u),
                ),
              ),
            ],
            SizedBox(height: Sp.x4),
            ECheckbox(
              value: _written,
              onChanged: (v) => setState(() => _written = v),
              label: l.deskOnbCreateWritten(phrase.length),
            ),
          ],
        ],
      ),
    ),
    );
  }
}
