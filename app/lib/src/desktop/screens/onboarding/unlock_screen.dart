import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/mock_wallet.dart' show MockDeskWallet;
import '../../data/remember.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import '../settings/prefs.dart' show settingsPrefsProvider;
import '../settings/dialogs.dart' show RemoveMode, showRemoveWalletDialog;
import 'kill_process_dialog.dart';
import 'onboarding_parts.dart';
import 'setup_screen.dart' show SetupFirstRun, setupSkippedThisSession;

/// What [UnlockScreen] starts on, for the screenshot tour.
enum UnlockShow { wrongPassword, progress, failed, missing }

/// Unlock with the wallet [id] selected, then [then] instead of Overview: Settings › This
/// wallet when "Unlock this wallet" was chosen in the remove dialog of another wallet.
class UnlockPick {
  const UnlockPick(this.id, {this.then});

  final String id;
  final DeskRoute? then;
}

/// Opens the app. [arg] is an [UnlockShow], an [UnlockAdded] or an [UnlockPick].
///
/// Mock passwords: `wrong` is refused, `busy` finds old processes (the kill-process dialog),
/// `fail` stops at the wallet service.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

/// Who else can open a remembered wallet: the truth, in the checkbox's tooltip.
String rememberWho(AppLocalizations l) => !kIsWeb && Platform.isWindows ? l.deskOnbUnlockWhoWindows : l.deskOnbUnlockWho;

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  List<WalletEntry>? _wallets;
  String? _id;
  String? _error;
  bool _missing = false;

  /// Remember on this computer: off unless the selected wallet is remembered already.
  bool _remember = false;

  /// Whether the user ticked the box on this screen (rather than it showing a wallet already
  /// remembered): kept when a wrong password forgets the remembered one.
  bool _rememberChosen = false;

  /// The stage running now; null while the form shows.
  String? _stage;
  bool _closingStage = false;

  /// The message of a failure before the password step.
  String? _failure;
  String _failedStage = '';

  @override
  void initState() {
    super.initState();
    switch (widget.arg) {
      case UnlockShow.wrongPassword:
        // Worded after the first frame: initState has no l10n.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _error = context.l10n.deskOnbUnlockWrong);
        });
        _password.text = 'secret';
      case UnlockShow.progress:
        _stage = 'wallet';
      case UnlockShow.failed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _failure = context.l10n.deskOnbUnlockPortInUse);
        });
        _failedStage = 'wallet';
      case UnlockShow.missing:
        _missing = true;
      // The wallet closed by itself (a server change could not reopen it).
      case final String reason:
        _error = reason;
    }
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    // At start only: Unlock after a Lock, after adding a wallet, or a second load of this
    // screen (a wallet removed from the list) always asks.
    final tryRemembered = !rememberAutoTried && widget.arg == null;
    rememberAutoTried = true;
    final List<WalletEntry> w;
    try {
      w = await ref.read(deskApiProvider).wallets();
    } on Object catch (e) {
      if (mounted) setState(() => _error = deskErrorText(e, context.l10n));
      return;
    }
    if (!mounted) return;
    if (w.isEmpty) {
      ref.read(deskNavProvider.notifier).reset(DeskRoute.welcome);
      return;
    }
    final added = switch (widget.arg) {
      UnlockAdded(:final id) => id,
      UnlockPick(:final id) => id,
      _ => null,
    };
    final pick = w.where((e) => e.id == added).firstOrNull ?? w.where((e) => e.current).firstOrNull ?? w.first;
    if (pick.id == added) {
      try {
        await ref.read(deskApiProvider).selectWallet(pick.id);
      } on Object catch (e) {
        if (mounted) setState(() => _error = deskErrorText(e, context.l10n));
      }
    }
    if (await _toSetup(pick, w.length > 1)) return;
    final remembered = await _isRemembered(pick.id);
    if (!mounted) return;
    setState(() {
      _wallets = w;
      _id = pick.id;
      _remember = remembered;
      if (pick.missing) _missing = true;
    });
    if (tryRemembered && remembered && !pick.missing) await _unlock(remembered: true);
  }

  /// A wallet whose first-run setup was not saved (the app was closed halfway) goes to the
  /// setup before it opens. True when it went there.
  Future<bool> _toSetup(WalletEntry pick, bool second) async {
    if (pick.missing || widget.arg is UnlockShow || setupSkippedThisSession.contains(pick.id)) return false;
    final bool pending;
    try {
      pending = await ref.read(deskApiProvider).setupPending(pick.id);
    } on Object {
      return false;
    }
    if (!pending || !mounted) return false;
    ref.read(deskNavProvider.notifier).reset(DeskRoute.setup, SetupFirstRun(UnlockAdded(pick.name, id: pick.id), second: second, resumed: true));
    return true;
  }

  Future<bool> _isRemembered(String id) async {
    try {
      return await ref.read(deskApiProvider).isRemembered(id);
    } on Object {
      return false;
    }
  }

  Future<void> _select(String? id) async {
    if (id == null) return;
    setState(() {
      _id = id;
      _missing = _selected?.missing ?? false;
      _error = null;
    });
    try {
      await ref.read(deskApiProvider).selectWallet(id);
    } on Object catch (e) {
      if (mounted) setState(() => _error = deskErrorText(e, context.l10n));
    }
    final entry = _selected;
    if (entry != null && await _toSetup(entry, (_wallets?.length ?? 0) > 1)) return;
    final remembered = await _isRemembered(id);
    if (mounted && _id == id) {
      setState(() {
        _remember = remembered;
        _rememberChosen = false;
      });
    }
  }

  Future<void> _removeMissing(WalletEntry w) async {
    await showRemoveWalletDialog(context, w, mode: RemoveMode.list);
    if (!mounted) return;
    setState(() => _missing = false);
    await _loadWallets();
  }

  @override
  void dispose() {
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  WalletEntry? get _selected => _wallets?.where((w) => w.id == _id).firstOrNull;

  List<Stage> _stages(AppLocalizations l) => [
    Stage('check', l.deskOnbUnlockStageCheck),
    if (DeskFeatures.walletProcesses) Stage('processes', l.deskOnbUnlockStageProcesses),
    if (_closingStage) Stage('closing', l.deskOnbUnlockStageClosing),
    Stage('wallet', l.deskOnbUnlockStageWallet),
    Stage('unlock', l.deskOnbUnlockStageUnlock),
  ];

  /// Shows [stage] running; false when the screen went away.
  Future<bool> _run(String stage) async {
    setState(() => _stage = stage);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return mounted;
  }

  void _backToForm({String? error}) {
    setState(() {
      _stage = null;
      _failure = null;
      _error = error;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _passwordFocus.requestFocus();
      if (error != null) _password.selection = TextSelection(baseOffset: 0, extentOffset: _password.text.length);
    });
  }

  /// Opens the wallet with the typed password, or with the one remembered on this computer.
  Future<void> _unlock({bool remembered = false}) async {
    if (_stage != null) return;
    final password = _password.text;
    if (password.isEmpty && !remembered) {
      setState(() => _error = context.l10n.deskOnbUnlockEnter);
      return;
    }
    setState(() {
      _error = null;
      _failure = null;
      _closingStage = false;
    });
    if (!await _run('check') || (DeskFeatures.walletProcesses && !await _run('processes'))) return;
    final mock = ref.read(deskApiProvider) is MockDeskWallet;
    if (DeskFeatures.walletProcesses && mock && !remembered && password == 'busy' && mounted) {
      final closed = await showKillProcessDialog(context);
      if (!mounted) return;
      if (!closed) {
        _backToForm(error: context.l10n.deskOnbUnlockCloseOthers);
        return;
      }
      setState(() => _closingStage = true);
      if (!await _run('closing')) return;
    }
    if (!await _run('wallet')) return;
    if (mock && !remembered && password == 'fail') {
      setState(() {
        _failure = context.l10n.deskOnbUnlockPortInUse;
        _failedStage = 'wallet';
        _stage = null;
      });
      return;
    }
    setState(() => _stage = 'unlock');
    final bool ok;
    try {
      final api = ref.read(deskApiProvider);
      if (_id != null) await api.selectWallet(_id!);
      ok = remembered ? await api.unlockRemembered() : await api.unlock(password, remember: _remember);
    } on RememberUnavailable {
      // The OS store did not answer: the password stays remembered for the next start.
      if (mounted) _backToForm(error: context.l10n.deskOnbUnlockRememberedUnavailable);
      return;
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _failure = deskErrorText(e, context.l10n);
        _failedStage = 'unlock';
        _stage = null;
      });
      return;
    }
    if (!mounted) return;
    if (!ok) {
      if (remembered) {
        setState(() => _remember = false);
        _backToForm(error: context.l10n.deskOnbUnlockRememberedForgotten);
      } else {
        _backToForm(error: context.l10n.deskOnbUnlockWrong);
        // The wrong password that forgot a remembered one (the last allowed try) unticks the
        // box, so the next right password does not remember it again unasked.
        final id = _id;
        if (_remember && id != null && !await _isRemembered(id) && mounted && _id == id) {
          setState(() => _remember = _rememberChosen);
        }
      }
      return;
    }
    final notRemembered = !remembered && _remember && ref.read(deskApiProvider).notRemembered;
    final desk = ref.read(deskProvider.notifier);
    await desk.refresh();
    final prefs = ref.read(settingsPrefsProvider);
    await desk.startLive(listen: prefs.epicboxOnStart);
    if (!mounted) return;
    _password.clear();
    final then = widget.arg is UnlockPick ? (widget.arg as UnlockPick).then : null;
    ref.read(deskNavProvider.notifier).reset(then ?? DeskRoute.overview);
    // After the move: a toast closes when its screen goes.
    if (notRemembered) showEToast(context, context.l10n.deskOnbUnlockNotRemembered, text: context.l10n.deskOnbUnlockKeyStore, tone: ETone.risk);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = _selected?.name ?? l.deskOnbUnlockThisWallet;
    if (_failure != null) {
      return ProgressView(
        title: l.deskOnbUnlockFailed,
        lead: l.deskOnbUnlockFailedLead,
        failureTitle: l.deskOnbUnlockFailedBox,
        stages: _stages(l),
        failed: _failedStage,
        failure: _failure,
        onBack: _backToForm,
        onRetry: _unlock,
      );
    }
    if (_stage != null) {
      return ProgressView(
        title: l.deskOnbUnlockUnlocking(name),
        lead: l.deskOnbUnlockStepsLead,
        stages: _stages(l),
        current: _stage!,
        note: l.deskOnbUnlockNote,
      );
    }
    return _form(context);
  }

  Widget _form(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final ts = context.ts;
    final l = context.l10n;
    final wallets = _wallets;
    final selected = _selected;
    final added = widget.arg is UnlockAdded ? (widget.arg as UnlockAdded).notice ?? context.l10n.deskSetupNewWalletAdded : null;
    return EHeroScreen(
      footer: const AuthFoot(),
      child: EAuthCard(
        title: l.deskOnbUnlockTitle,
        lead: l.deskOnbUnlockLead,
        alternatives: [
          if (DeskFeatures.multiWallet) ELink(label: l.deskOnbWelcomeAdd, dim: true, onPressed: () => nav.go(DeskRoute.welcome, 'add')),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (added != null) ...[
              Semantics(
                liveRegion: true,
                child: ENotice(title: added, tone: ETone.ok, icon: EIcons.check),
              ),
              SizedBox(height: Sp.x5),
            ],
            if (DeskFeatures.multiWallet && wallets != null && wallets.length > 1) ...[
              EField(
                label: l.deskOnbSameWallet,
                child: ESelect<String>(
                  semanticLabel: l.deskOnbSameWallet,
                  value: _id ?? wallets.first.id,
                  onChanged: _select,
                  items: [
                    for (final w in wallets)
                      ESelectItem(
                        w.id,
                        w.name,
                        subtitle: w.folder,
                        trailing: w.network == 'mainnet' ? null : EBadge(networkName(w.network), tone: ETone.warn),
                      ),
                  ],
                ),
              ),
              SizedBox(height: Sp.x5),
            ] else if (wallets != null && selected != null) ...[
              Row(
                children: [
                  Icon(EIcons.wallet, size: Ctl.iconSm, color: context.dc.dim),
                  SizedBox(width: Sp.x2),
                  Flexible(child: Text(selected.name, style: ts.strong, overflow: TextOverflow.ellipsis)),
                  if (selected.network != 'mainnet') ...[
                    SizedBox(width: Sp.x2),
                    EBadge(networkName(selected.network), tone: ETone.warn),
                  ],
                ],
              ),
              SizedBox(height: Sp.x5),
            ] else if (wallets == null)
              Padding(
                padding: EdgeInsets.only(bottom: Sp.x5),
                child: Align(alignment: Alignment.centerLeft, child: ESpinner(size: Ctl.iconSm)),
              ),
            EField(
              label: l.deskOnbStepPassword,
              error: _error,
              child: PasswordBox(
                controller: _password,
                focusNode: _passwordFocus,
                autofocus: true,
                invalid: _error != null,
                semanticLabel: l.deskOnbStepPassword,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _unlock(),
              ),
            ),
            SizedBox(height: Sp.x4),
            Tooltip(
              message: rememberWho(l),
              child: ECheckbox(
                value: _remember,
                label: l.deskOnbUnlockRemember,
                onChanged: (v) => setState(() => _remember = _rememberChosen = v),
              ),
            ),
            if (_remember) ...[
              SizedBox(height: Sp.x1),
              Padding(
                padding: EdgeInsets.only(left: Sp.x8),
                child: Text(l.deskOnbUnlockRememberFor(rememberWho(l)), style: ts.caption),
              ),
            ],
            if (DeskFeatures.multiWallet && _missing) ...[
              SizedBox(height: Sp.x5),
              ENotice(
                title: l.deskOnbUnlockMissingTitle,
                text: l.deskOnbUnlockMissingText(selected?.folder ?? ''),
                tone: ETone.risk,
                icon: EIcons.alert,
              ),
              SizedBox(height: Sp.x3),
              Wrap(
                spacing: Sp.x2,
                runSpacing: Sp.x2,
                children: [
                  EButton(
                    label: l.deskOnbUnlockRemove,
                    icon: EIcons.trash,
                    kind: EBtnKind.danger,
                    size: EBtnSize.sm,
                    onPressed: selected == null ? null : () => _removeMissing(selected),
                  ),
                  EButton(
                    label: l.deskOnbUnlockTryAgain,
                    icon: EIcons.refresh,
                    size: EBtnSize.sm,
                    onPressed: () => setState(() => _missing = false),
                  ),
                ],
              ),
            ],
            SizedBox(height: Sp.x6),
            EButton.primary(label: l.deskOnbUnlockButton, icon: EIcons.lockOpen, expand: true, onPressed: _unlock),
          ],
        ),
      ),
    );
  }
}
