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
    try {
      await ref.read(deskApiProvider).forgetRemembered(_walletId);
    } on Object catch (e) {
      if (mounted) showEToast(context, 'Not forgotten', text: deskErrorText(e), tone: ETone.risk);
      return;
    }
    if (!mounted) return;
    setState(() => _remembered = false);
    showEToast(context, 'Forgotten on this computer', text: 'The next start asks the password.');
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = _label.text.trim();
    final id = ref.read(deskProvider).account?.id;
    if (t.isEmpty) {
      showEToast(context, 'Label not saved', text: 'Enter a label');
      return;
    }
    if (id != null) {
      try {
        await ref.read(deskProvider.notifier).renameWallet(id, t);
      } on Object catch (e) {
        if (mounted) showEToast(context, 'Label not saved', text: deskErrorText(e));
        return;
      }
    }
    if (!mounted) return;
    // The wallet's own name wins; the old app-wide label stays empty.
    final p = ref.read(settingsPrefsProvider.notifier);
    p.set(ref.read(settingsPrefsProvider).copyWith(walletLabel: id == null ? t : ''));
    showEToast(context, 'Label saved', text: t);
  }

  @override
  Widget build(BuildContext context) {
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
            title: 'This wallet',
            rows: [
              ESetRow(
                title: 'Label',
                hint: 'Only shown in this app.',
                control: ERowControl(
                  child: EInput(
                    size: EBtnSize.sm,
                    controller: _label,
                    hint: a.name,
                    semanticLabel: 'Label',
                    inputFormatters: [LengthLimitingTextInputFormatter(32)],
                    onSubmitted: (_) => _save(),
                    trailing: EIconButton(icon: EIcons.check, label: 'Save label', size: EBtnSize.inline, onPressed: _save),
                  ),
                ),
              ),
              ESetRow(
                title: 'Recovery phrase',
                hint: 'The words that restore this wallet. Keep them private.',
                control: ERowControl(child: EButton(label: 'Show phrase…', icon: EIcons.key, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.settingsPhrase))),
              ),
              ESetRow(
                title: 'Recheck balance',
                hint: 'Reads the chain again when the balance looks wrong.',
                control: ERowControl(child: EButton(label: 'Recheck…', icon: EIcons.scan, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.settingsRescan))),
              ),
            ],
          ),
          BackupGroup(demo: widget.arg is BackupDemo ? widget.arg as BackupDemo : null),
          ESetGroup(
            title: 'Files',
            rows: [
              _FolderRow(title: 'Wallet folder', path: a.folder),
              _FolderRow(title: 'App files', hint: 'Settings and the log.', path: a.appFolder ?? appFilesDir),
              if (a.network != 'mainnet')
                ESetRow(title: 'Network', hint: 'Set when the wallet was created.', control: ETag(a.network, tone: ETone.warn)),
              ESetRow(
                title: 'Setup assistant',
                hint: 'Walk through node and receiving again. Nothing is lost.',
                control: ERowControl(child: EButton(label: 'Run setup…', size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.setup))),
              ),
            ],
          ),
          ESetGroup(
            title: 'Security',
            rows: [
              if (_remembered)
                ESetRow(
                  title: 'Remembered on this computer',
                  hint: 'Opens at start without the password, for 30 days from when it was set. Sends still ask the password. ${rememberWho(context.l10n)}',
                  control: ERowControl(child: EButton(label: 'Forget this computer', icon: EIcons.lock, size: EBtnSize.sm, onPressed: _forget)),
                ),
              if (DeskFeatures.changePassword)
                ESetRow(
                  title: 'Password',
                  hint: 'Unlocks this wallet.',
                  control: ERowControl(child: EButton(label: 'Change password…', size: EBtnSize.sm, icon: EIcons.lock, onPressed: () => showChangePasswordDialog(context))),
                ),
              ESetRow(
                  title: 'Delete wallet',
                  hint: 'Deletes its keys and database.',
                  control: ERowControl(child: EButton(label: 'Delete…', size: EBtnSize.sm, icon: EIcons.trash, kind: EBtnKind.danger, onPressed: () => showDeleteWalletDialog(context))),
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
    if (!Directory(path).existsSync()) {
      showEToast(context, 'Folder not found', text: path);
      return;
    }
    if (!await ref.read(deskOpenFolderProvider)(path) && context.mounted) showEToast(context, 'Folder not opened', text: path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    return ESetRow(
      title: title,
      hint: hint,
      control: ERowControl(child: EButton(label: 'Open folder', icon: EIcons.folderOpen, size: EBtnSize.sm, onPressed: () => _open(context, ref))),
      below: Row(
        children: [
          Flexible(
            child: Tooltip(message: path, child: Text(path, style: ts.mono(size: Fs.sm, color: c.dim), overflow: TextOverflow.ellipsis)),
          ),
          SizedBox(width: Sp.x1),
          ECopyButton(text: path, label: 'Copy path: $title'),
        ],
      ),
    );
  }
}
