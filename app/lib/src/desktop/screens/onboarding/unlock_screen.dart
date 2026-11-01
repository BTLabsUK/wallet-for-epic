// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/desk_levels.dart' show deskLevelUiProvider;
import '../../data/mock_wallet.dart' show MockDeskWallet;
import '../../data/remember.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../../models.dart' show StoreMigrationProgress, WalletError, WalletErrorKind;
import '../../widgets/kit.dart';
import '../settings/prefs.dart' show settingsPrefsProvider;
import '../settings/dialogs.dart' show RemoveMode, showRemoveWalletDialog;
import 'onboarding_parts.dart';
import '../../../settings_file/host_settings.dart' show appConfig;
import 'reset_password_screen.dart' show ResetPasswordArg;
import 'setup_screen.dart' show SetupFirstRun, setupSkippedThisSession;

/// What [UnlockScreen] starts on, for the screenshot tour.
enum UnlockShow { wrongPassword, progress, encrypting, failed, missing, listOpen }

/// Unlock with the wallet [id] selected, then [then] instead of Overview: Settings › This
/// wallet when "Unlock this wallet" was chosen in the remove dialog of another wallet.
class UnlockPick {
  const UnlockPick(this.id, {this.then, this.switched = false});

  final String id;
  final DeskRoute? then;

  /// Chosen in the wallet switch: a wallet remembered on this computer opens as at start,
  /// without asking (a tester, 26.10.20).
  final bool switched;
}

/// Opens the app. [arg] is an [UnlockShow], an [UnlockAdded] or an [UnlockPick].
///
/// Mock passwords: `wrong` is refused, `fail` stops at the wallet service.
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

  /// The wallet list opens no further down than this button (UD-006).
  final _unlockKey = GlobalKey();
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

  /// The copy step of a first unlock after the update, while it runs; null otherwise.
  StoreMigrationProgress? _copy;

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
      // The first unlock after the update, a large wallet copying its records.
      case UnlockShow.encrypting:
        _stage = 'encrypt';
        _copied = true;
        _copy = const StoreMigrationProgress(done: 4200, total: 10000);
      case UnlockShow.failed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _failure = context.l10n.deskOnbUnlockPortInUse('${appConfig.httpListenPort}'));
        });
        _failedStage = 'wallet';
      case UnlockShow.missing:
        _missing = true;
      case UnlockShow.listOpen:
        break;
      // The wallet closed by itself (a server change could not reopen it).
      case final String reason:
        _error = reason;
    }
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    // At start, and for a wallet chosen in the wallet switch: Unlock after a Lock, after
    // adding a wallet, or a second load of this screen (a wallet removed from the list) asks.
    final arg = widget.arg;
    final tryRemembered = (!rememberAutoTried && arg == null) || (arg is UnlockPick && arg.switched);
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
    // How the wallet came, for Unlock's notice after the setup: restored, or new (WIN-2).
    final restored = await ref.read(deskApiProvider).setupRestored(pick.id).catchError((Object _) => false);
    if (!mounted) return false;
    final notice = restored ? context.l10n.deskOnbRestoreDone : null;
    ref.read(deskNavProvider.notifier).reset(DeskRoute.setup, SetupFirstRun(UnlockAdded(pick.name, id: pick.id, notice: notice), second: second, resumed: true));
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

  /// The copy step shows only on an unlock that copies the records ([_copied]).
  bool _copied = false;

  List<Stage> _stages(AppLocalizations l) => [
    Stage('check', l.deskOnbUnlockStageCheck),
    Stage('wallet', l.deskOnbUnlockStageWallet),
    // The label carries its own "…": the running stage adds none ([StageList]).
    if (_copied) Stage('encrypt', l.storeEncrypting.replaceAll('…', '')),
    Stage('unlock', l.deskOnbUnlockStageUnlock),
  ];

  /// A copy-step event of LEPIC's open: the stage runs while rows are copied, then the open goes
  /// on. Idempotent on LEPIC's side, so nothing here asks the user to wait or not to close.
  void _onCopy(StoreMigrationProgress p) {
    if (!mounted || _stage == null) return;
    setState(() {
      _copied = true;
      _copy = p.finished ? null : p;
      _stage = p.finished ? 'unlock' : 'encrypt';
    });
  }

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
    // Enter in the password field of a wallet whose folder is missing opens nothing.
    if (_stage != null || _missing) return;
    final password = _password.text;
    if (password.isEmpty && !remembered) {
      setState(() => _error = context.l10n.deskOnbUnlockEnter);
      return;
    }
    setState(() {
      _error = null;
      _failure = null;
    });
    if (!await _run('check')) return;
    final mock = ref.read(deskApiProvider) is MockDeskWallet;
    if (!await _run('wallet')) return;
    if (mock && !remembered && password == 'fail') {
      setState(() {
        _failure = context.l10n.deskOnbUnlockPortInUse('${appConfig.httpListenPort}');
        _failedStage = 'wallet';
        _stage = null;
      });
      return;
    }
    setState(() {
      _stage = 'unlock';
      _copied = false;
      _copy = null;
    });
    final bool ok;
    final api = ref.read(deskApiProvider);
    final copying = api.storeMigration.listen(_onCopy);
    try {
      if (_id != null) await api.selectWallet(_id!);
      ok = remembered ? await api.unlockRemembered() : await api.unlock(password, remember: _remember);
    } on RememberUnavailable {
      // The OS store did not answer: the password stays remembered for the next start.
      if (mounted) _backToForm(error: context.l10n.deskOnbUnlockRememberedUnavailable);
      return;
    } on Object catch (e) {
      if (!mounted) return;
      if (e is WalletError && e.kind == WalletErrorKind.wrongKey) {
        // Nothing was changed: the message sits under the password and Unlock stays ready.
        _backToForm(error: deskErrorText(e, context.l10n));
        return;
      }
      setState(() {
        _failure = deskErrorText(e, context.l10n);
        _failedStage = 'unlock';
        _stage = null;
      });
      return;
    } finally {
      // Not awaited: the open is through, and the screen moves on at once.
      unawaited(copying.cancel());
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
        stages: _stages(l),
        failed: _failedStage,
        failure: _failure,
        onBack: _backToForm,
        onRetry: _unlock,
        topAnchored: true,
      );
    }
    if (_stage != null) {
      final copy = _copy;
      // How far the copy is, while it runs (LEPIC counts pages, so no number is shown).
      final fraction = _stage == 'encrypt' ? copy?.fraction : null;
      return ProgressView(
        title: l.deskOnbUnlockUnlocking(name),
        stages: _stages(l),
        current: _stage!,
        note: l.deskOnbUnlockNote,
        progress: fraction,
        topAnchored: true,
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
    // Top-anchored: the tile stays put across the list, a missing folder, a wrong password
    // and the progress that follows; a form taller than the window scrolls.
    return EHeroScreen(
      footer: const AuthFoot(),
      topAnchored: true,
      child: EAuthCard(
        title: l.deskOnbUnlockTitle,
        alternatives: [
          // The wallet's phrase sets a new password.
          if (selected != null && !selected.missing)
            ELink(key: const ValueKey('unlock-forgot'), label: l.deskOnbForgotLink, dim: true, onPressed: () => nav.go(DeskRoute.resetPassword, ResetPasswordArg(selected.id))),
          // Shallow: one wallet, no Add a wallet.
          if (ref.watch(deskLevelUiProvider).addWallet) ELink(label: l.deskOnbWelcomeAdd, dim: true, onPressed: () => nav.go(DeskRoute.welcome, 'add')),
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
            if (wallets != null && wallets.length > 1) ...[
              EField(
                label: l.deskOnbSameWallet,
                child: ESelect<String>(
                  semanticLabel: l.deskOnbSameWallet,
                  value: _id ?? wallets.first.id,
                  onChanged: _select,
                  openInitially: widget.arg == UnlockShow.listOpen,
                  keepClear: _unlockKey,
                  items: [
                    for (final w in wallets)
                      ESelectItem(
                        w.id,
                        w.name,
                        subtitle: walletRowLine(l, w),
                        subtitleIsPath: !inWalletsFolder(w.folder) || w.lastOpened == null,
                        tooltip: w.folder,
                        trailing: w.network == 'mainnet' || !DeskFeatures.testNetworks ? null : EBadge(networkName(w.network), tone: ETone.warn),
                        action: ECopyButton(text: w.folder, label: l.deskSetAcctCopyPath(w.name)),
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
                  if (selected.network != 'mainnet' && DeskFeatures.testNetworks) ...[
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
              // The error line keeps its room: a wrong password moves nothing under it.
              reserveError: true,
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
            ECheckbox(
              value: _remember,
              label: l.deskOnbUnlockRemember,
              onChanged: (v) => setState(() => _remember = _rememberChosen = v),
            ),
            SizedBox(height: Sp.x1),
            // Who else can open it, under the ticked box; unticked, its room is kept, so Unlock
            // does not move under the pointer.
            Padding(
              padding: EdgeInsets.only(left: Sp.x8),
              child: ReservedSlot.like(
                alignment: AlignmentDirectional.topStart,
                model: Text(l.deskOnbUnlockRememberFor(rememberWho(l)), style: ts.caption),
                child: _remember ? Text(l.deskOnbUnlockRememberFor(rememberWho(l)), style: ts.caption) : null,
              ),
            ),
            if (_missing) ...[
              SizedBox(height: Sp.x4),
              Semantics(
                liveRegion: true,
                child: ENotice(
                  title: l.deskOnbUnlockMissingTitle,
                  text: l.deskOnbUnlockMissingText(selected?.folder ?? ''),
                  tone: ETone.risk,
                  icon: EIcons.alert,
                ),
              ),
            ],
            SizedBox(height: Sp.x6),
            if (_missing)
              // The folder is what is missing: Remove and Try again take Unlock's place (a
              // disabled Unlock beside them only said what could not be done), on its line.
              Row(
                key: _unlockKey,
                children: [
                  Expanded(
                    child: EButton(
                      label: l.deskOnbUnlockRemove,
                      icon: EIcons.trash,
                      kind: EBtnKind.danger,
                      expand: true,
                      onPressed: selected == null ? null : () => _removeMissing(selected),
                    ),
                  ),
                  SizedBox(width: Sp.x3),
                  Expanded(
                    child: EButton.primary(
                      label: l.deskOnbUnlockTryAgain,
                      icon: EIcons.refresh,
                      expand: true,
                      onPressed: () => setState(() => _missing = false),
                    ),
                  ),
                ],
              )
            else
              EButton.primary(key: _unlockKey, label: l.deskOnbUnlockButton, icon: EIcons.lockOpen, expand: true, onPressed: _unlock),
          ],
        ),
      ),
    );
  }
}

/// Whether [folder] is a wallet the app made in its own folder
/// (`…/.epic_cash_desktop/wallets/<id>/<chain>`): there the path tells wallets apart by an id only, so the list says when
/// each was opened instead.
bool inWalletsFolder(String folder) =>
    RegExp(r'[/\\]\.epic_cash_desktop[/\\]wallets[/\\][^/\\]+[/\\][^/\\]+[/\\]?$').hasMatch(folder);

/// [folder] with the home folder as `~`, the way the list shows it.
String shortFolder(String folder, {String? home}) {
  final h = home ?? Platform.environment[Platform.isWindows ? 'USERPROFILE' : 'HOME'];
  if (h == null || h.isEmpty) return folder;
  final base = h.endsWith('/') || h.endsWith(r'\') ? h.substring(0, h.length - 1) : h;
  final same = Platform.isWindows ? folder.toLowerCase().startsWith(base.toLowerCase()) : folder.startsWith(base);
  if (!same || (folder.length > base.length && !r'/\'.contains(folder[base.length]))) return folder;
  return '~${folder.substring(base.length)}';
}

/// The line under a wallet's name on Unlock: when it was last opened for a wallet in the
/// app's own folder, else its folder from `~`. The whole path shows on hover and copies.
String walletRowLine(AppLocalizations l, WalletEntry w, {DateTime? now, String? home}) {
  final t = w.lastOpened;
  if (!inWalletsFolder(w.folder) || t == null) return shortFolder(w.folder, home: home);
  final d = (now ?? DateTime.now()).difference(t);
  final when = d.inMinutes < 1
      ? l.deskSetFrameJustNow
      : d.inMinutes < 60
      ? l.deskSetFrameMinAgo(d.inMinutes)
      : d.inHours < 24
      ? l.deskSetFrameHoursAgo(d.inHours)
      : l.deskSetFrameDaysAgo(d.inDays);
  return l.deskOnbUnlockOpened(when);
}
