import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_wallet.dart' show MockDeskWallet;
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import '../settings/prefs.dart' show settingsPrefsProvider;
import '../settings/dialogs.dart' show RemoveMode, showRemoveWalletDialog;
import 'kill_process_dialog.dart';
import 'onboarding_parts.dart';

/// What [UnlockScreen] starts on, for the screenshot tour.
enum UnlockShow { wrongPassword, progress, failed, missing }

/// Opens the app. [arg] is an [UnlockShow] or an [UnlockAdded].
///
/// Mock passwords: `wrong` is refused, `busy` finds old processes (the kill-process dialog),
/// `fail` stops at the wallet service.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

const _wrongPassword = 'Wrong password. Check Caps Lock and the keyboard layout.';

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  List<WalletEntry>? _wallets;
  String? _id;
  String? _error;
  bool _missing = false;

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
        _error = _wrongPassword;
        _password.text = 'secret';
      case UnlockShow.progress:
        _stage = 'wallet';
      case UnlockShow.failed:
        _failure = 'The wallet service did not start: port 3415 is in use by another program.';
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
    final List<WalletEntry> w;
    try {
      w = await ref.read(deskApiProvider).wallets();
    } on Object catch (e) {
      if (mounted) setState(() => _error = deskErrorText(e));
      return;
    }
    if (!mounted) return;
    if (w.isEmpty) {
      ref.read(deskNavProvider.notifier).reset(DeskRoute.welcome);
      return;
    }
    final pick = w.where((e) => e.current).firstOrNull ?? w.first;
    setState(() {
      _wallets = w;
      _id = pick.id;
      if (pick.missing) _missing = true;
    });
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
      if (mounted) setState(() => _error = deskErrorText(e));
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

  List<Stage> get _stages => [
    const Stage('check', 'Checking wallet files'),
    if (DeskFeatures.walletProcesses) const Stage('processes', 'Looking for wallet processes still running'),
    if (_closingStage) const Stage('closing', 'Closing the old wallet processes'),
    const Stage('wallet', 'Starting the wallet service'),
    const Stage('unlock', 'Unlocking the wallet'),
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

  Future<void> _unlock() async {
    if (_stage != null) return;
    final password = _password.text;
    if (password.isEmpty) {
      setState(() => _error = 'Enter the password');
      return;
    }
    setState(() {
      _error = null;
      _failure = null;
      _closingStage = false;
    });
    if (!await _run('check') || (DeskFeatures.walletProcesses && !await _run('processes'))) return;
    final mock = ref.read(deskApiProvider) is MockDeskWallet;
    if (DeskFeatures.walletProcesses && mock && password == 'busy' && mounted) {
      final closed = await showKillProcessDialog(context);
      if (!mounted) return;
      if (!closed) {
        _backToForm(error: 'Close the other Epic processes, then unlock.');
        return;
      }
      setState(() => _closingStage = true);
      if (!await _run('closing')) return;
    }
    if (!await _run('wallet')) return;
    if (mock && password == 'fail') {
      setState(() {
        _failure = 'The wallet service did not start: port 3415 is in use by another program.';
        _failedStage = 'wallet';
        _stage = null;
      });
      return;
    }
    setState(() => _stage = 'unlock');
    final bool ok;
    try {
      if (_id != null) await ref.read(deskApiProvider).selectWallet(_id!);
      ok = await ref.read(deskApiProvider).unlock(password);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _failure = deskErrorText(e);
        _failedStage = 'unlock';
        _stage = null;
      });
      return;
    }
    if (!mounted) return;
    if (!ok) {
      _backToForm(error: _wrongPassword);
      return;
    }
    final desk = ref.read(deskProvider.notifier);
    await desk.refresh();
    final prefs = ref.read(settingsPrefsProvider);
    await desk.startLive(listen: prefs.epicboxOnStart);
    if (!mounted) return;
    _password.clear();
    ref.read(deskNavProvider.notifier).reset(DeskRoute.overview);
  }

  @override
  Widget build(BuildContext context) {
    final name = _selected?.name ?? 'this wallet';
    if (_failure != null) {
      return ProgressView(
        title: 'Unlock failed',
        lead: 'The wallet did not open. The reason is below.',
        failureTitle: 'The wallet did not open',
        stages: _stages,
        failed: _failedStage,
        failure: _failure,
        onBack: _backToForm,
        onRetry: _unlock,
      );
    }
    if (_stage != null) {
      return ProgressView(
        title: 'Unlocking $name',
        lead: 'Each step shows as it finishes.',
        stages: _stages,
        current: _stage!,
        note:
            'Then the overview opens and finishes in the background: connecting to the node, updating balances, starting the listener.',
      );
    }
    return _form(context);
  }

  Widget _form(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final ts = context.ts;
    final wallets = _wallets;
    final selected = _selected;
    final added = widget.arg is UnlockAdded ? (widget.arg as UnlockAdded).name : null;
    return EHeroScreen(
      footer: const AuthFoot(),
      child: EAuthCard(
        title: 'Unlock wallet',
        lead: 'Keys stay on this computer.',
        alternatives: [
          if (DeskFeatures.multiWallet) ELink(label: 'Add a wallet', dim: true, onPressed: () => nav.go(DeskRoute.welcome, 'add')),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (added != null) ...[
              Semantics(
                liveRegion: true,
                child: ENotice(title: '$added added.', tone: ETone.ok, icon: EIcons.check),
              ),
              SizedBox(height: Sp.x5),
            ],
            if (DeskFeatures.multiWallet && wallets != null && wallets.length > 1) ...[
              EField(
                label: 'Wallet',
                child: ESelect<String>(
                  semanticLabel: 'Wallet',
                  value: _id ?? wallets.first.id,
                  onChanged: _select,
                  items: [
                    for (final w in wallets)
                      ESelectItem(
                        w.id,
                        w.name,
                        subtitle: w.folder,
                        trailing: w.network == 'mainnet' ? null : ETag(networkName(w.network), tone: ETone.warn),
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
                    ETag(networkName(selected.network), tone: ETone.warn),
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
              label: 'Password',
              error: _error,
              child: PasswordBox(
                controller: _password,
                focusNode: _passwordFocus,
                autofocus: true,
                invalid: _error != null,
                semanticLabel: 'Password',
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _unlock(),
              ),
            ),
            if (DeskFeatures.multiWallet && _missing) ...[
              SizedBox(height: Sp.x5),
              ENotice(
                title: 'This wallet’s folder is missing',
                text: 'It was at ${selected?.folder ?? ''}',
                tone: ETone.risk,
                icon: EIcons.alert,
              ),
              SizedBox(height: Sp.x3),
              Wrap(
                spacing: Sp.x2,
                runSpacing: Sp.x2,
                children: [
                  EButton(
                    label: 'Remove',
                    icon: EIcons.trash,
                    kind: EBtnKind.danger,
                    size: EBtnSize.sm,
                    onPressed: selected == null ? null : () => _removeMissing(selected),
                  ),
                  EButton(
                    label: 'Try again',
                    icon: EIcons.refresh,
                    size: EBtnSize.sm,
                    onPressed: () => setState(() => _missing = false),
                  ),
                ],
              ),
            ],
            SizedBox(height: Sp.x6),
            EButton.primary(label: 'Unlock', icon: EIcons.lockOpen, expand: true, onPressed: _unlock),
          ],
        ),
      ),
    );
  }
}
