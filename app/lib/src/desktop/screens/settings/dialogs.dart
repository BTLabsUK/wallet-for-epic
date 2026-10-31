// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../widgets/kit.dart';
import '../onboarding/onboarding_parts.dart' show accountErrors;
import '../onboarding/unlock_screen.dart' show UnlockPick;

// ---- Existing blockchain data --------------------------------------------------------------

/// The built-in node picked and older chain data found: use it (true), download fresh
/// (false), or back (null). [inUse]: another Epic program holds the folder.
Future<bool?> showChainOfferDialog(BuildContext context, {bool inUse = false}) =>
    showEDialog<bool>(context, builder: (_) => ChainOfferDialog(inUse: inUse));

class ChainOfferDialog extends StatelessWidget {
  const ChainOfferDialog({super.key, this.inUse = false});

  final bool inUse;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final nav = Navigator.of(context);
    return EDialog(
      title: l.deskSetDlgChainTitle,
      description: l.deskSetDlgChainDesc,
      icon: EIcons.node,
      tone: ETone.gold,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EFacts([
            (l.deskSetDlgChainFolder, Text('~/.epic/main/chain_data', style: ts.mono(size: Fs.sm, color: c.text))),
            (l.deskSetDlgChainSize, Text('4.2 GB', style: ts.mono(size: Fs.sm, color: c.text))), // l10n-ok: size
            (l.deskSetDlgChainUpdated, Text(l.deskSetDlgChainUpdatedValue, style: ts.small.copyWith(color: c.text))),
          ], labelWidth: 110.u),
          SizedBox(height: Sp.x3),
          Text(l.deskSetDlgChainOthers, style: ts.small),
          SizedBox(height: Sp.x3),
          Text(
            inUse ? l.deskSetDlgChainInUse : l.deskSetDlgChainUseIt,
            style: ts.body.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: Sp.x2),
          Text(l.deskSetDlgChainOlderWallet, style: ts.caption),
        ],
      ),
      actions: [
        EButton(label: l.deskSetDlgChainFresh, size: EBtnSize.sm, kind: EBtnKind.ghost, onPressed: () => nav.pop(false)),
        if (inUse) EButton.ghost(label: l.commonClose, size: EBtnSize.sm, onPressed: () => nav.pop()),
        EButton.primary(label: l.deskSetDlgChainUse, icon: EIcons.check, size: EBtnSize.sm, onPressed: inUse ? null : () => nav.pop(true)),
      ],
    );
  }
}

// ---- Change password -----------------------------------------------------------------------

Future<void> showChangePasswordDialog(BuildContext context) =>
    showEDialog(context, builder: (_) => const ChangePasswordDialog());

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;
  bool _wrong = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  // The same rules and words as Create's password (onboarding_parts.dart).
  bool get _valid => _current.text.isNotEmpty && passwordLongEnough(_next.text) && _repeat.text == _next.text;

  Future<void> _save() async {
    if (!_valid || _busy) return;
    final l = context.l10n;
    setState(() {
      _busy = true;
      _wrong = false;
      _error = null;
    });
    try {
      await ref.read(deskApiProvider).changePassword(_current.text, _next.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      showEToast(context, l.deskSetDlgPwChanged, tone: ETone.ok);
    } on Object catch (e) {
      if (!mounted) return;
      final wrong = e is DeskError && e.wrongPassword;
      setState(() {
        _busy = false;
        _wrong = wrong;
        _error = wrong ? null : deskErrorText(e, l);
      });
    }
  }

  void _edited() => setState(() => _error = null);

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final (nextError, repeatError) = accountErrors(context.l10n, _next.text, _repeat.text);
    return PopScope(
      canPop: !_busy,
      child: EDialog(
      title: l.deskSetDlgPwTitle,
      dismissible: !_busy,
      description: l.deskSetDlgPwDesc,
      icon: EIcons.lock,
      // Enter: Current → New → Repeat, then Change password once all three are valid.
      body: EForm(
        onSubmit: _busy || !_valid ? null : _save,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EField(
            label: l.deskSetDlgPwCurrent,
            error: _wrong ? l.deskSetDlgPwWrong : null,
            child: EPasswordInput(
              controller: _current,
              autofocus: true,
              invalid: _wrong,
              semanticLabel: l.deskSetDlgPwCurrent,
              onChanged: (_) => setState(() {
                _wrong = false;
                _error = null;
              }),
            ),
          ),
          SizedBox(height: Sp.x4),
          EField(
            label: l.deskSetDlgPwNew,
            error: nextError,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EPasswordInput(controller: _next, invalid: nextError != null, semanticLabel: l.deskSetDlgPwNew, onChanged: (_) => _edited()),
                SizedBox(height: Sp.x2),
                // Informs only; its info icon is not a Tab stop.
                ExcludeFocusTraversal(child: PasswordHint(controller: _next)),
              ],
            ),
          ),
          SizedBox(height: Sp.x4),
          EField(
            label: l.deskSetDlgPwRepeat,
            error: repeatError,
            child: EPasswordInput(controller: _repeat, invalid: repeatError != null, semanticLabel: l.deskSetDlgPwRepeat, onChanged: (_) => _edited()),
          ),
          if (_error != null) ...[
            SizedBox(height: Sp.x3),
            Semantics(liveRegion: true, child: Text(_error!, style: ts.small.copyWith(color: c.risk))),
          ],
        ],
      ),
      ),
      actions: [
        EButton(label: l.commonCancel, size: EBtnSize.sm, tabStop: false, onPressed: _busy ? null : () => Navigator.of(context).pop()),
        EButton.primary(label: l.deskSetDlgPwTitle, size: EBtnSize.sm, busy: _busy, onPressed: _valid ? _save : null),
      ],
    ),
    );
  }
}

// ---- Remove wallet -------------------------------------------------------------------------

/// What to remove of a wallet. [app] and [everything] both delete the wallet (the app keeps no
/// files of its own for a wallet): its keys and database. `wallet_data` stays.
enum RemoveMode { list, app, everything }

/// Remove [wallet] from this computer: from the list only, or delete it (typed name and a
/// tick). The open wallet is locked first.
Future<void> showRemoveWalletDialog(BuildContext context, WalletEntry wallet, {RemoveMode? mode}) =>
    showEDialog(context, builder: (_) => RemoveWalletDialog(wallet: wallet, initialMode: mode));

class RemoveWalletDialog extends ConsumerStatefulWidget {
  const RemoveWalletDialog({super.key, required this.wallet, this.initialMode});

  final WalletEntry wallet;
  final RemoveMode? initialMode;

  @override
  ConsumerState<RemoveWalletDialog> createState() => _RemoveWalletDialogState();
}

class _RemoveWalletDialogState extends ConsumerState<RemoveWalletDialog> {
  final _typed = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _ack = false;
  String? _error;
  // Deleting asks for the wallet's password, so only the open wallet can be deleted here.
  late final bool _isOpen = ref.read(deskProvider).account?.id == widget.wallet.id;
  late WalletRemoval? _mode = switch (widget.initialMode) {
    null => _isOpen ? null : WalletRemoval.list,
    RemoveMode.list => WalletRemoval.list,
    RemoveMode.app || RemoveMode.everything => _isOpen ? WalletRemoval.delete : WalletRemoval.list,
  };

  @override
  void dispose() {
    _typed.dispose();
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  WalletEntry get w => widget.wallet;

  bool get _nameOk => _typed.text.trim() == w.name;

  bool get _ready => !_busy && _mode != null && (_mode != WalletRemoval.delete || (_nameOk && _ack && _password.text.isNotEmpty));

  /// Locks the open wallet and opens Unlock with this one selected, landing on Settings › This
  /// wallet, where Delete wallet is.
  Future<void> _unlockThis() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      if (ref.read(deskProvider).account != null) await ref.read(deskProvider.notifier).lock();
      await ref.read(deskApiProvider).selectWallet(w.id);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = deskErrorText(e, l);
        });
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ref.read(deskNavProvider.notifier).reset(DeskRoute.unlock, UnlockPick(w.id, then: DeskRoute.settingsAccount));
  }

  Future<void> _remove() async {
    final mode = _mode;
    if (mode == null || !_ready) return;
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(deskProvider.notifier).removeWallet(
        w.id,
        mode,
        password: mode == WalletRemoval.delete ? _password.text : null,
      );
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = deskErrorText(e, l);
        });
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showEToast(context, switch (mode) {
      WalletRemoval.list => l.deskSetDlgRemoveToastList(w.name),
      WalletRemoval.delete => l.deskSetDlgRemoveToastDeleted(w.name),
    }, text: mode == WalletRemoval.list ? l.deskSetDlgRemoveFilesKept : null, tone: ETone.ok);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    Widget choice(WalletRemoval m, String title, String hint) => Padding(
      padding: EdgeInsets.only(bottom: Sp.x2),
      child: IgnorePointer(
        ignoring: _busy,
        child: EChoiceCard(
          title: title,
          description: hint,
          selected: _mode == m,
          onTap: () => setState(() {
            _mode = m;
            _error = null;
          }),
        ),
      ),
    );
    return PopScope(
      canPop: !_busy,
      child: EDialog(
        title: l.deskSetDlgRemoveTitle(w.name),
        icon: EIcons.trash,
        tone: ETone.risk,
        dismissible: !_busy,
        // Enter: Wallet name → Password, then the danger button once everything is filled.
        body: EForm(
          onSubmit: _ready ? _remove : null,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label: l.deskSetDlgRemoveWhat,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  choice(WalletRemoval.list, l.deskSetDlgRemoveFromList, l.deskSetDlgRemoveFromListHint(w.folder)),
                  if (_isOpen)
                    choice(
                      WalletRemoval.delete,
                      l.deskSetDlgDeleteWallet,
                      l.deskSetDlgRemoveDeleteHint(w.folder),
                    ),
                ],
              ),
            ),
            if (!_isOpen) ...[
              SizedBox(height: Sp.x1),
              Text(
                l.deskSetDlgRemoveUnlockHint,
                style: ts.small,
              ),
              SizedBox(height: Sp.x1),
              Align(
                alignment: Alignment.centerLeft,
                child: ELink(label: l.deskSetDlgRemoveUnlock, onPressed: _busy ? null : _unlockThis),
              ),
            ],
            if (_mode == WalletRemoval.delete) ...[
              SizedBox(height: Sp.x2),
              ENotice(
                title: l.deskSetDlgRemoveIrreversible,
                text: l.deskSetDlgRemoveIrreversibleBody,
                tone: ETone.risk,
              ),
              SizedBox(height: Sp.x4),
              EField(
                label: l.deskSetDlgRemoveName,
                help: l.deskSetDlgRemoveTypeName(w.name),
                error: _typed.text.isNotEmpty && !_nameOk ? l.deskSetDlgRemoveNameMismatch : null,
                child: EInput(
                  controller: _typed,
                  enabled: !_busy,
                  invalid: _typed.text.isNotEmpty && !_nameOk,
                  semanticLabel: l.deskSetDlgRemoveName,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(height: Sp.x3),
              EField(
                label: l.deskSetDlgPassword,
                child: EPasswordInput(controller: _password, onChanged: (_) => setState(() => _error = null)),
              ),
              SizedBox(height: Sp.x3),
              ECheckbox(value: _ack, onChanged: (v) => setState(() => _ack = v), label: l.deskSetDlgPhraseWritten),
            ],
            if (_error != null) ...[
              SizedBox(height: Sp.x3),
              Semantics(liveRegion: true, child: Text(_error!, style: ts.small.copyWith(color: c.risk))),
            ],
            if (_busy) ...[
              SizedBox(height: Sp.x2),
              Text(l.deskSetDlgRemoving, style: ts.small.copyWith(color: c.dim)),
            ],
          ],
        ),
        ),
        actions: [
          EButton(label: l.commonCancel, size: EBtnSize.sm, kind: EBtnKind.ghost, tabStop: false, onPressed: _busy ? null : () => Navigator.of(context).pop()),
          EButton(
            label: _mode == WalletRemoval.delete ? l.deskSetDlgDeleteWallet : l.deskSetDlgRemoveFromList,
            icon: EIcons.trash,
            size: EBtnSize.sm,
            kind: EBtnKind.danger,
            busy: _busy,
            onPressed: _ready ? _remove : null,
          ),
        ],
      ),
    );
  }
}

// ---- Delete this wallet --------------------------------------------------------------------

/// Deletes the open wallet from this computer after its password. Then Unlock opens, or
/// Welcome when no wallet is left.
Future<void> showDeleteWalletDialog(BuildContext context) => showEDialog(context, builder: (_) => const DeleteWalletDialog());

class DeleteWalletDialog extends ConsumerStatefulWidget {
  const DeleteWalletDialog({super.key});

  @override
  ConsumerState<DeleteWalletDialog> createState() => _DeleteWalletDialogState();
}

class _DeleteWalletDialogState extends ConsumerState<DeleteWalletDialog> {
  final _password = TextEditingController();
  bool _ack = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  bool get _ready => !_busy && _ack && _password.text.isNotEmpty;

  Future<void> _delete() async {
    if (!_ready) return;
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    final desk = ref.read(deskProvider.notifier);
    final nav = ref.read(deskNavProvider.notifier);
    final id = ref.read(deskProvider).account?.id;
    try {
      if (id == null) throw DeskError.l10n((l) => l.deskSetDlgWalletLocked);
      await desk.removeWallet(id, WalletRemoval.delete, password: _password.text);
    } on Object catch (e) {
      if (!mounted) return;
      // A failed delete after the password still locks the wallet: the pages behind the dialog
      // have nothing left to show, so Unlock opens with the error instead.
      if (ref.read(deskProvider).account == null) {
        Navigator.of(context).pop();
        _leave(nav);
        showEToast(context, deskErrorText(e, l), tone: ETone.warn);
        return;
      }
      setState(() {
        _busy = false;
        _error = deskErrorText(e, l);
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    _leave(nav);
  }

  /// Unlock after the wallet is gone or locked, or Welcome when no wallet is left.
  void _leave(DeskNav nav) {
    final left = ref.read(deskProvider).wallets ?? const [];
    nav.reset(left.isEmpty ? DeskRoute.welcome : DeskRoute.unlock);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopScope(
    canPop: !_busy,
    child: EDialog(
      title: l.deskSetDlgDeleteTitle,
      description: l.deskSetDlgDeleteDesc,
      icon: EIcons.trash,
      tone: ETone.risk,
      dismissible: !_busy,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EField(
            label: l.deskSetDlgPassword,
            error: _error,
            child: EPasswordInput(
              controller: _password,
              autofocus: true,
              invalid: _error != null,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _delete(),
            ),
          ),
          SizedBox(height: Sp.x4),
          ECheckbox(value: _ack, onChanged: (v) => setState(() => _ack = v), label: l.deskSetDlgPhraseWritten),
        ],
      ),
      actions: [
        EButton(label: l.commonCancel, size: EBtnSize.sm, kind: EBtnKind.ghost, tabStop: false, onPressed: _busy ? null : () => Navigator.of(context).pop()),
        EButton(label: l.deskSetDlgDeleteWallet, icon: EIcons.trash, size: EBtnSize.sm, kind: EBtnKind.danger, busy: _busy, onPressed: _ready ? _delete : null),
      ],
    ),
  );
  }
}
