import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/files.dart' show deskOpenFolderProvider;
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import '../onboarding/unlock_screen.dart' show rememberWho;
import 'backup.dart';
import 'dialogs.dart';
import 'prefs.dart';
import 'settings_frame.dart';

/// Where the app keeps its own files (mock).
const appFilesDir = '~/.config/epic-wallet';

class SettingsAccountScreen extends ConsumerStatefulWidget {
  const SettingsAccountScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsAccountScreen> createState() => _SettingsAccountScreenState();
}

class _SettingsAccountScreenState extends ConsumerState<SettingsAccountScreen> {
  final _label = TextEditingController();
  bool _filled = false;

  /// Whether this wallet opens at start without its password (Unlock's Remember).
  bool _remembered = false;

  @override
  void initState() {
    super.initState();
    _readRemembered();
  }

  /// The open wallet's list id; empty in the mock, which answers for its selected wallet.
  String get _walletId => ref.read(deskProvider).account?.id ?? '';

  Future<void> _readRemembered() async {
    try {
      final r = await ref.read(deskApiProvider).isRemembered(_walletId);
      if (mounted) setState(() => _remembered = r);
    } on Object {
      // Unknown: the row stays hidden.
    }
  }

  Future<void> _forget() async {
    final l = context.l10n;
    try {
      await ref.read(deskApiProvider).forgetRemembered(_walletId);
    } on Object catch (e) {
      if (mounted) showEToast(context, l.deskSetAcctNotForgotten, text: deskErrorText(e, l), tone: ETone.risk);
      return;
    }
    if (!mounted) return;
    setState(() => _remembered = false);
    showEToast(context, l.deskSetAcctForgotten, text: l.deskSetAcctForgottenText);
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final t = _label.text.trim();
    final id = ref.read(deskProvider).account?.id;
    if (t.isEmpty) {
      showEToast(context, l.deskSetAcctLabelNotSaved, text: l.deskSetAcctEnterLabel);
      return;
    }
    if (id != null) {
      try {
        await ref.read(deskProvider.notifier).renameWallet(id, t);
      } on Object catch (e) {
        if (mounted) showEToast(context, l.deskSetAcctLabelNotSaved, text: deskErrorText(e, l));
        return;
      }
    }
    if (!mounted) return;
    // The wallet's own name wins; the old app-wide label stays empty.
    final p = ref.read(settingsPrefsProvider.notifier);
    p.set(ref.read(settingsPrefsProvider).copyWith(walletLabel: id == null ? t : ''));
    showEToast(context, l.deskSetAcctLabelSaved, text: t);
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
            title: l.deskSetFrameThisWallet,
            rows: [
              ESetRow(
                title: l.deskSetAcctLabel,
                hint: l.deskSetAcctLabelHint,
                control: ERowControl(
                  child: EInput(
                    size: EBtnSize.sm,
                    controller: _label,
                    hint: a.name,
                    semanticLabel: l.deskSetAcctLabel,
                    inputFormatters: [LengthLimitingTextInputFormatter(32)],
                    onSubmitted: (_) => _save(),
                    trailing: EIconButton(icon: EIcons.check, label: l.deskSetAcctSaveLabel, size: EBtnSize.inline, onPressed: _save),
                  ),
                ),
              ),
              ESetRow(
                title: l.deskSetFramePhrase,
                hint: l.deskSetAcctPhraseHint,
                control: ERowControl(child: EButton(label: l.deskSetAcctShowPhrase, icon: EIcons.key, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.settingsPhrase))),
              ),
              ESetRow(
                title: l.deskSetFrameRescan,
                hint: l.deskSetAcctRescanHint,
                control: ERowControl(child: EButton(label: l.deskSetAcctRecheck, icon: EIcons.scan, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.settingsRescan))),
              ),
            ],
          ),
          BackupGroup(demo: widget.arg is BackupDemo ? widget.arg as BackupDemo : null),
          ESetGroup(
            title: l.deskSetAcctFiles,
            rows: [
              _FolderRow(title: l.deskSetAcctWalletFolder, path: a.folder),
              _FolderRow(title: l.deskSetAcctAppFiles, hint: l.deskSetAcctAppFilesHint, path: a.appFolder ?? appFilesDir),
              if (a.network != 'mainnet')
                ESetRow(title: l.deskSetAcctNetwork, hint: l.deskSetAcctNetworkHint, control: ETag(a.network, tone: ETone.warn)),
              ESetRow(
                title: l.deskSetAcctSetup,
                hint: l.deskSetAcctSetupHint,
                control: ERowControl(child: EButton(label: l.deskSetAcctRunSetup, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.setup))),
              ),
            ],
          ),
          ESetGroup(
            title: l.deskSetAcctSecurity,
            rows: [
              if (_remembered)
                ESetRow(
                  title: l.deskSetAcctRemembered,
                  hint: l.deskSetAcctRememberedHint(rememberWho(l)),
                  control: ERowControl(child: EButton(label: l.deskSetAcctForget, icon: EIcons.lock, size: EBtnSize.sm, onPressed: _forget)),
                ),
              if (DeskFeatures.changePassword)
                ESetRow(
                  title: l.deskSetDlgPassword,
                  hint: l.deskSetAcctPasswordHint,
                  control: ERowControl(child: EButton(label: l.deskSetAcctChangePassword, size: EBtnSize.sm, icon: EIcons.lock, onPressed: () => showChangePasswordDialog(context))),
                ),
              ESetRow(
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

/// A folder: its path in mono with a copy button, and Open folder.
class _FolderRow extends ConsumerWidget {
  const _FolderRow({required this.title, required this.path, this.hint});

  final String title;
  final String? hint;
  final String path;

  /// Opens [path] in the system's file manager; a path that is not on disk (the mock) toasts.
  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    if (!Directory(path).existsSync()) {
      showEToast(context, l.deskSetAcctFolderNotFound, text: path);
      return;
    }
    if (!await ref.read(deskOpenFolderProvider)(path) && context.mounted) showEToast(context, l.deskSetLnodeFolderNotOpened, text: path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    return ESetRow(
      title: title,
      hint: hint,
      control: ERowControl(child: EButton(label: l.deskSetBackupOpenFolder, icon: EIcons.folderOpen, size: EBtnSize.sm, onPressed: () => _open(context, ref))),
      below: Row(
        children: [
          Flexible(
            child: Tooltip(message: path, child: Text(path, style: ts.mono(size: Fs.sm, color: c.dim), overflow: TextOverflow.ellipsis)),
          ),
          SizedBox(width: Sp.x1),
          ECopyButton(text: path, label: l.deskSetAcctCopyPath(title)),
        ],
      ),
    );
  }
}
