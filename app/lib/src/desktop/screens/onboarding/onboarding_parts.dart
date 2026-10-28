// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import '../../../app_info.dart';
import '../../../l10n.dart' show appLanguages;
import '../../../ui/language_flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shell.dart' show deskVersion;
import '../../data/api.dart' show DeskWalletApi;
import '../../../wallet_registry.dart' show WalletRegistry;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../wallet/tx_label.dart' show TxLabelField, TxPen, txLabelEditingProvider;

/// The version line under the full-window screens.
class AuthFoot extends StatelessWidget {
  const AuthFoot({super.key});

  @override
  Widget build(BuildContext context) => Text('$appName $deskVersion');
}

/// Password and confirmation: the first step of create and restore. Enter in Password goes to
/// Confirm; Enter in Confirm runs [onSubmit] (null while the two are not valid).
class AccountForm extends StatelessWidget {
  const AccountForm({
    super.key,
    required this.password,
    required this.confirm,
    required this.onChanged,
    this.onSubmit,
    this.passwordError,
    this.confirmError,
  });

  final TextEditingController password, confirm;
  final VoidCallback onChanged;

  /// The step's main button; null while the form is not valid.
  final VoidCallback? onSubmit;
  final String? passwordError;
  final String? confirmError;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EForm(
    onSubmit: onSubmit,
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EField(
        label: l.deskOnbStepPassword,
        error: passwordError,
        reserveError: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PasswordBox(
              controller: password,
              invalid: passwordError != null,
              semanticLabel: l.deskOnbStepPassword,
              textInputAction: TextInputAction.next,
              onChanged: (_) => onChanged(),
            ),
            SizedBox(height: Sp.x2),
            // Its info icon is not a Tab stop (keyboard.dart); the hint text is on screen.
            ExcludeFocusTraversal(child: PasswordHint(controller: password)),
          ],
        ),
      ),
      // The reserved error line above is part of the gap: no second full gap.
      SizedBox(height: Sp.x2),
      EField(
        label: l.deskSetupConfirmPassword,
        error: confirmError,
        child: PasswordBox(
          controller: confirm,
          invalid: confirmError != null,
          semanticLabel: l.deskSetupConfirmPassword,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onChanged(),
        ),
      ),
    ],
  ),
  );
  }
}

/// Validation of [AccountForm]; null when fine.
(String?, String?) accountErrors(AppLocalizations l, String password, String confirm) {
  String? p;
  String? c;
  if (password.isNotEmpty && !passwordLongEnough(password)) p = l.deskSetupPasswordShort;
  if (confirm.isNotEmpty && confirm != password) c = l.deskSetupPasswordsDiffer;
  return (p, c);
}

/// A numbered grid of words, as the phrase is written on paper.
List<ERailStep> railOf(List<String> labels, int current) => [
  for (var i = 0; i < labels.length; i++) ERailStep(labels[i], done: i < current, current: i == current),
];

/// Back button used in the foot of the first-run frames. Not a Tab stop: Alt+Left and the
/// mouse Back button do the same (keyboard.dart).
Widget backButton(VoidCallback onTap, {String? label}) => Builder(
  builder: (context) => EButton.ghost(label: label ?? context.l10n.deskSetupBack, icon: EIcons.arrowLeft, tabStop: false, onPressed: onTap),
);

/// The value of [deskLanguageItems]' first option: follow the computer's language
/// (`DeskSettings.language` null).
const deskSystemLanguage = '';

/// The language options of a select (Setup › Preferences, Settings › Appearance): the system's
/// language first, then each of `appLanguages` by its flag and its own name. A value is a
/// language code, or [deskSystemLanguage].
List<ESelectItem<String>> deskLanguageItems(AppLocalizations l) => [
  ESelectItem(deskSystemLanguage, l.languageSystem, leading: Icon(EIcons.themeSystem, size: 14)),
  for (final a in appLanguages) ESelectItem(a.code, a.name, leading: LanguageFlag(a.code, height: 14)),
];

/// The name the language pickers show for the setting [code] (null: the system's).
String deskLanguageName(AppLocalizations l, String? code) =>
    appLanguages.where((a) => a.code == code).firstOrNull?.name ?? l.languageSystem;

/// Unlock's argument after a flow added a wallet: [id] is chosen and "{name} added." shows.
class UnlockAdded {
  const UnlockAdded(this.name, {this.id, this.notice});

  final String name;
  final String? id;

  /// Unlock's notice: "Wallet restored." / "Wallet imported." (no name); null for the default,
  /// "New wallet added." in the window's language.
  final String? notice;
}

/// The wallet a flow added: the entry the list has now and did not have in [before] (ids), as
/// Unlock's argument. [fallback] names it when the list cannot say.
Future<UnlockAdded> addedWallet(DeskWalletApi api, Set<String> before, String fallback, {String? notice}) async {
  try {
    final added = (await api.wallets()).where((w) => !before.contains(w.id)).lastOrNull;
    if (added != null) return UnlockAdded(added.name, id: added.id, notice: notice);
  } on Object {
    // Unlock offers the wallet opened last.
  }
  return UnlockAdded(fallback, notice: notice);
}

/// The "Wallet N" an unnamed wallet gets: N is the first number no listed wallet has (the list
/// the app holds; none on a first run), as the list names it.
String defaultWalletName(WidgetRef ref) {
  final names = {for (final w in ref.read(deskProvider).wallets ?? const <WalletEntry>[]) w.name};
  var n = 1;
  while (names.contains('Wallet $n')) { // l10n-ok: the stored default name
    n++;
  }
  return 'Wallet $n'; // l10n-ok: the stored default name
}

/// The wallet's name as the step's title, with a pen: [fallback] ("Wallet N") until one is
/// typed. Edited in place like a transaction's label, with the same field: Enter, blur and a
/// tap outside save, Esc keeps the title, an empty field goes back to the default. Not a step
/// and never required: the name lands with the wallet ([DeskWalletApi.createWallet]'s name).
class WalletNameTitle extends ConsumerStatefulWidget {
  const WalletNameTitle({super.key, required this.place, required this.name, required this.fallback, required this.onChanged});

  /// Which flow edits it (`create`, `restore`): the inline-field site.
  final String place;

  /// The typed name, or null for [fallback].
  final String? name;
  final String fallback;
  final ValueChanged<String?> onChanged;

  @override
  ConsumerState<WalletNameTitle> createState() => _WalletNameTitleState();
}

class _WalletNameTitleState extends ConsumerState<WalletNameTitle> {
  final FocusNode _pen = FocusNode();

  @override
  void dispose() {
    _pen.dispose();
    super.dispose();
  }

  ({String key, String place}) get _site => (key: 'wallet-name', place: widget.place);

  void _close({required bool byKey}) {
    ref.read(txLabelEditingProvider.notifier).close(_site.key, _site.place);
    if (byKey) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _pen.requestFocus() : null);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final style = context.ts.h1;
    if (ref.watch(txLabelEditingProvider) == _site) {
      return TxLabelField(
        key: const ValueKey('wallet-name-field'),
        site: _site,
        initial: widget.name ?? '',
        style: style,
        hint: widget.fallback,
        semanticsLabel: l.deskOnbWalletNameField,
        maxLength: WalletRegistry.maxLabelLength,
        onSave: (text) => widget.onChanged(text.trim().isEmpty ? null : text.trim()),
        onClose: _close,
      );
    }
    final name = widget.name ?? widget.fallback;
    return Row(
      children: [
        Flexible(
          child: Semantics(
            header: true,
            label: l.deskOnbWalletNameIs(name),
            excludeSemantics: true,
            child: Text(name, key: const ValueKey('wallet-name-title'), style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        SizedBox(width: Sp.x2),
        TxPen(key: const ValueKey('wallet-name-pen'), label: l.deskOnbWalletNameEdit, focusNode: _pen, onPressed: () => ref.read(txLabelEditingProvider.notifier).open(_site.key, _site.place)),
      ],
    );
  }
}

/// Remembers that wallet [id] still has its first-run setup to do (null: the list could not
/// name it, then Unlock offers the wallet opened last and the setup is skipped).
Future<void> markSetupPending(DeskWalletApi api, String? id, {bool restored = false}) async {
  if (id == null) return;
  try {
    await api.setSetupPending(id, true);
    // A setup resumed after a restart says how the wallet came (WIN-2).
    if (restored) await api.setSetupRestored(id);
  } on Object {
    // The setup still runs now; only a quit halfway would skip it.
  }
}

/// What Welcome chose for the flows after it: the network (Welcome › Advanced) and the app
/// data folder. Mock state, kept for the session.
class OnbFlow {
  const OnbFlow({this.network = 'mainnet', this.dataFolder});

  final String network;

  /// Null: the default folder.
  final String? dataFolder;

  bool get testNet => network != 'mainnet';
}

class OnbFlowNotifier extends Notifier<OnbFlow> {
  @override
  OnbFlow build() => OnbFlow(network: ref.read(deskApiProvider).network);

  /// The wallet layer moves too, so Create and Restore make a wallet of [n] (LNX-6).
  void setNetwork(String n) {
    state = OnbFlow(network: n, dataFolder: state.dataFolder);
    unawaited(ref.read(deskApiProvider).useNetwork(n));
  }

  void setFolder(String? f) => state = OnbFlow(network: state.network, dataFolder: f);
}

final onbFlowProvider = NotifierProvider<OnbFlowNotifier, OnbFlow>(OnbFlowNotifier.new);

String networkName(String n) => switch (n) {
  'floonet' => 'Floonet', // l10n-ok: network names
  'usernet' => 'Usernet', // l10n-ok
  _ => 'Mainnet', // l10n-ok
};

/// A warn tag with the test network's name and a line after it.
class NetNote extends StatelessWidget {
  const NetNote(this.network, this.text, {super.key, this.center = false});

  final String network;
  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: center ? WrapAlignment.center : WrapAlignment.start,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: Sp.x2,
    runSpacing: Sp.x1,
    children: [
      EBadge(networkName(network), tone: ETone.warn),
      Text(text, style: context.ts.small),
    ],
  );
}

/// "Caps Lock is on" while it is and [focus] has the focus.
class CapsLockNote extends StatefulWidget {
  const CapsLockNote({super.key, required this.focus});

  final FocusNode focus;

  @override
  State<CapsLockNote> createState() => _CapsLockNoteState();
}

class _CapsLockNoteState extends State<CapsLockNote> {
  bool _on = false;

  bool _read() => HardwareKeyboard.instance.lockModesEnabled.contains(KeyboardLockMode.capsLock);

  bool _onKey(KeyEvent _) {
    _sync();
    return false;
  }

  void _sync() {
    final on = _read() && widget.focus.hasFocus;
    if (on != _on && mounted) setState(() => _on = on);
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    widget.focus.addListener(_sync);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    widget.focus.removeListener(_sync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_on) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: Sp.x2),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(EIcons.keyboard, size: Ctl.iconSm, color: context.dc.warn),
            SizedBox(width: Sp.x2),
            Flexible(child: Text(context.l10n.deskSetupCapsLock, style: context.ts.small)),
          ],
        ),
      ),
    );
  }
}

/// A password field with the Caps Lock note under it.
class PasswordBox extends StatefulWidget {
  const PasswordBox({
    super.key,
    required this.controller,
    this.invalid = false,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.focusNode,
    this.semanticLabel,
    this.textInputAction,
  });

  final TextEditingController controller;
  final bool invalid;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? semanticLabel;
  final TextInputAction? textInputAction;

  @override
  State<PasswordBox> createState() => _PasswordBoxState();
}

class _PasswordBoxState extends State<PasswordBox> {
  FocusNode? _own;

  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      EPasswordInput(
        controller: widget.controller,
        invalid: widget.invalid,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        autofocus: widget.autofocus,
        focusNode: _focus,
        semanticLabel: widget.semanticLabel,
        textInputAction: widget.textInputAction,
      ),
      CapsLockNote(focus: _focus),
    ],
  );
}

/// One step of a long action: open, create or restore a wallet.
class Stage {
  const Stage(this.key, this.label);

  final String key;
  final String label;
}

/// The steps of a long action: done, running now, failed, still to come. [current] is the key
/// running now (those before it are done), [failed] the key that failed, '' for neither.
class StageList extends StatelessWidget {
  const StageList({super.key, required this.stages, this.current = '', this.failed = '', this.complete = false});

  final List<Stage> stages;
  final String current;
  final String failed;
  final bool complete;

  int get _active => stages.indexWhere((s) => s.key == (failed.isNotEmpty ? failed : current));

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final a = _active;
    String stateOf(int i) {
      if (complete) return 'done';
      if (a < 0 || i > a) return 'todo';
      if (i < a) return 'done';
      return failed.isNotEmpty ? 'fail' : 'now';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < stages.length; i++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: Sp.x2),
            child: Row(
              children: [
                Container(
                  width: Ctl.iconLg,
                  height: Ctl.iconLg,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: switch (stateOf(i)) {
                      'done' => c.okSoft,
                      'fail' => c.riskSoft,
                      _ => c.s3,
                    },
                  ),
                  child: switch (stateOf(i)) {
                    'done' => Icon(EIcons.check, size: Ctl.iconSm, color: c.ok),
                    'fail' => Icon(EIcons.close, size: Ctl.iconSm, color: c.risk),
                    'now' => ESpinner(size: Ctl.iconSm),
                    _ => Text('${i + 1}', style: ts.caption),
                  },
                ),
                SizedBox(width: Sp.x3),
                Expanded(
                  child: Text(
                    stateOf(i) == 'now' ? '${stages[i].label}…' : stages[i].label,
                    style: switch (stateOf(i)) {
                      'todo' => ts.bodyDim,
                      'fail' => ts.strong.copyWith(color: c.risk),
                      _ => ts.strong,
                    },
                  ),
                ),
              ],
            ),
          ),
        if (a >= 0)
          Semantics(
            liveRegion: true,
            label: context.l10n.deskSetupStepSem(a + 1, stages.length, stages[a].label),
            child: const SizedBox.shrink(),
          ),
      ],
    );
  }
}

/// The full-window screen of a long action: tile, title, the stage list, then either the wait
/// line or the failure with Back and Try again.
class ProgressView extends StatelessWidget {
  const ProgressView({
    super.key,
    required this.title,
    this.lead,
    required this.stages,
    this.current = '',
    this.failed = '',
    this.failure,
    this.wait,
    this.note,
    this.onBack,
    this.onRetry,
  });

  final String title;
  final String? lead;
  final List<Stage> stages;
  final String current;
  final String failed;

  /// The message of a failure; null while running.
  final String? failure;

  /// The notice's heading; [title] when null.
  final String? wait;
  final String? note;
  final VoidCallback? onBack;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final failure = this.failure;
    // Back goes to [onBack] after a failure; while the action runs it is held.
    return DeskStepBack(
      onBack: (failure != null ? onBack : null) ?? () {},
      child: EHeroScreen(
      footer: const AuthFoot(),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480.u),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: EGlyphTile(size: 72.u, icon: failure != null ? EIcons.alert : null, risk: failure != null)),
            SizedBox(height: Sp.x5),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(title, style: ts.h1, textAlign: TextAlign.center),
            ),
            if (lead != null) ...[
              SizedBox(height: Sp.x2),
              Text(lead!, style: ts.bodyDim, textAlign: TextAlign.center),
            ],
            SizedBox(height: Sp.x6),
            EPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StageList(stages: stages, current: current, failed: failure != null ? failed : ''),
                  if (note != null && failure == null) ...[
                    SizedBox(height: Sp.x3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(EIcons.info, size: Ctl.iconSm, color: context.dc.faint),
                        SizedBox(width: Sp.x2),
                        Expanded(child: Text(note!, style: ts.small)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: Sp.x5),
            if (failure != null) ...[
              ENotice(title: failure, tone: ETone.risk, icon: EIcons.alert),
              SizedBox(height: Sp.x5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onBack != null) EButton(label: context.l10n.deskSetupBack, onPressed: onBack),
                  SizedBox(width: Sp.x3),
                  if (onRetry != null) EButton.primary(label: context.l10n.deskSetupTryAgain, icon: EIcons.refresh, onPressed: onRetry),
                ],
              ),
            ] else if (wait != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(EIcons.clock, size: Ctl.iconSm, color: context.dc.faint),
                  SizedBox(width: Sp.x2),
                  Flexible(child: Text(wait!, style: ts.small)),
                ],
              ),
          ],
        ),
      ),
    ),
    );
  }
}
