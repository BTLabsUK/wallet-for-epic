import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
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
                text: 'Only shown in this app.',
                control: SizedBox(
                  width: 240.u,
                  child: EInput(
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
                text: 'The words that restore this wallet. Keep them private.',
                control: EButton(label: 'Show phrase…', icon: EIcons.key, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.settingsPhrase)),
              ),
              ESetRow(
                title: 'Recheck balance',
                text: 'Scans the chain again when the balance looks wrong.',
                control: EButton(label: 'Recheck…', icon: EIcons.scan, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.settingsRescan)),
              ),
            ],
          ),
          ESetGroup(
            title: 'Files',
            rows: [
              _FolderRow(title: 'Wallet folder', path: a.folder),
              _FolderRow(title: 'App files', text: 'Settings and the log.', path: a.appFolder ?? appFilesDir),
              if (a.network != 'mainnet')
                ESetRow(title: 'Network', text: 'Set when the wallet was created.', control: ETag(a.network, tone: ETone.warn)),
              ESetRow(
                title: 'Setup assistant',
                text: 'Walk through node and receiving again. Nothing is lost.',
                control: EButton(label: 'Run setup…', size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.setup)),
              ),
            ],
          ),
          ESetGroup(
            title: 'Security',
            rows: [
              if (DeskFeatures.changePassword)
                ESetRow(
                  title: 'Password',
                  text: 'Unlocks this wallet.',
                  control: EButton(label: 'Change password…', size: EBtnSize.sm, icon: EIcons.lock, onPressed: () => showChangePasswordDialog(context)),
                ),
              ESetRow(
                  title: 'Delete wallet',
                  text: 'Deletes its keys and database.',
                  control: EButton(label: 'Delete…', size: EBtnSize.sm, icon: EIcons.trash, kind: EBtnKind.danger, onPressed: () => showDeleteWalletDialog(context)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A folder: its path in mono with a copy button, and Open folder.
class _FolderRow extends StatelessWidget {
  const _FolderRow({required this.title, required this.path, this.text});

  final String title;
  final String? text;
  final String path;

  /// Opens [path] in the system's file manager; a path that is not on disk (the mock) toasts.
  Future<void> _open(BuildContext context) async {
    if (!Directory(path).existsSync()) {
      showEToast(context, 'Folder not found', text: path);
      return;
    }
    final (cmd, args) = Platform.isWindows ? ('explorer', [path]) : Platform.isMacOS ? ('open', [path]) : ('xdg-open', [path]);
    try {
      await Process.start(cmd, args, mode: ProcessStartMode.detached);
    } on ProcessException {
      if (context.mounted) showEToast(context, 'Folder not opened', text: path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return ESetRow(
      title: title,
      text: text,
      control: EButton(label: 'Open folder', icon: EIcons.folderOpen, size: EBtnSize.sm, onPressed: () => _open(context)),
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
