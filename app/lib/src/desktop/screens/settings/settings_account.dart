// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../trust_ids.dart';
import '../../desk_l10n.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../widgets/kit.dart';
import 'backup.dart';
import 'dialogs.dart' show showDeleteWalletDialog;
import 'prefs.dart';
import 'setting_ids.dart';
import 'settings_frame.dart';

/// Settings › Wallet: its name; Backup (export and import of its data, CSV); Balance (Recheck
/// balance, a sub-page); Remove (Delete wallet). The folders are under Files & logs, Set up
/// again under Help.

class SettingsAccountScreen extends ConsumerStatefulWidget {
  const SettingsAccountScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsAccountScreen> createState() => _SettingsAccountScreenState();
}

class _SettingsAccountScreenState extends ConsumerState<SettingsAccountScreen> {
  final _label = TextEditingController();
  final _labelFocus = FocusNode();
  bool _filled = false;

  @override
  void dispose() {
    _label.dispose();
    _labelFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final t = _label.text.trim();
    final id = ref.read(deskProvider).account?.id;
    if (t.isEmpty) {
      showEToast(context, l.deskSetAcctLabelNotSaved, text: l.deskSetAcctEnterLabel, tone: ETone.warn);
      return;
    }
    if (id != null) {
      try {
        await ref.read(deskProvider.notifier).renameWallet(id, t);
      } on Object catch (e) {
        if (mounted) showEToast(context, l.deskSetAcctLabelNotSaved, text: deskErrorText(e, l), tone: ETone.risk);
        return;
      }
    }
    if (!mounted) return;
    // The wallet's own name wins; the old app-wide label stays empty.
    final p = ref.read(settingsPrefsProvider.notifier);
    p.set(ref.read(settingsPrefsProvider).copyWith(walletLabel: id == null ? t : ''));
    showEToast(context, l.deskSetAcctLabelSaved, text: t, tone: ETone.ok);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = ref.watch(deskProvider.select((s) => s.account));
    final label = ref.watch(settingsPrefsProvider.select((p) => p.walletLabel));
    if (a == null) return const SettingsFrame(route: DeskRoute.settingsAccount, child: SettingsLoading());
    if (!_filled) {
      _filled = true;
      _label.text = label == null || label.isEmpty || a.id != null ? a.name : label;
    }
    final nav = ref.read(deskNavProvider.notifier);
    return SettingsFrame(
      route: DeskRoute.settingsAccount,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ESetGroup(
            rows: [
              ESetRow(
                anchor: SetId.name,
                title: l.deskSetAcctLabel,
                hint: l.deskSetAcctLabelHint,
                control: ERowControl(
                  // A name field, not a select (UD-032): the pencil says it is editable, and
                  // becomes the check only while the name differs from the saved one.
                  child: EInput(
                    size: EBtnSize.sm,
                    controller: _label,
                    focusNode: _labelFocus,
                    hint: a.name,
                    semanticLabel: l.deskSetAcctLabel,
                    semanticsId: TrustIds.walletLabelField,
                    inputFormatters: [LengthLimitingTextInputFormatter(32)],
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _save(),
                    trailing: _label.text.trim() != a.name && _label.text.trim().isNotEmpty
                        ? EIconButton(semanticsId: TrustIds.walletSaveLabel, icon: EIcons.check, label: l.deskSetAcctSaveLabel, size: EBtnSize.inline, onPressed: _save)
                        : EIconButton(icon: EIcons.pencil, label: l.deskSetAcctLabel, size: EBtnSize.inline, onPressed: _labelFocus.requestFocus),
                  ),
                ),
              ),
            ],
          ),
          BackupGroup(demo: widget.arg is BackupDemo ? widget.arg as BackupDemo : null),
          // Recheck balance: a sub-page of Wallet, at every view.
          ESetGroup(
            title: l.deskSetAcctBalance,
            rows: [
              ESetRow(
                key: const ValueKey('account-recheck'),
                anchor: SetId.recheckGo,
                title: l.deskSetFrameRescan,
                hint: l.deskLvShellRecheckHint,
                control: ERowControl(child: EButton(label: l.commonOpen, icon: EIcons.scan, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.settingsRescan))),
              ),
            ],
          ),
          // Apart from the rest: the one step that cannot be undone.
          ESetGroup(
            title: l.deskSetAcctRemove,
            rows: [
              ESetRow(
                anchor: SetId.deleteWallet,
                title: l.deskSetDlgDeleteWallet,
                hint: l.deskSetAcctDeleteHint,
                control: ERowControl(child: EButton(label: l.deskSetLnodeDelete, size: EBtnSize.sm, icon: EIcons.trash, kind: EBtnKind.danger, onPressed: () => showDeleteWalletDialog(context))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

