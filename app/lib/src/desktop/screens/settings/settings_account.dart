// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n.dart' show autoLockLabel;
import '../../../settings.dart' show autoLockChoices;
import '../../../ui/devices/device_parts.dart' show devicesStateLine;
import '../../desk_l10n.dart';
import '../../data/devices_state.dart' show deskDeviceBookProvider, deskLinkedDevicesOnProvider;
import '../../data/files.dart' show deskOpenFolderProvider;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../widgets/kit.dart';
import '../onboarding/unlock_screen.dart' show rememberWho;
import 'backup.dart';
import 'dialogs.dart';
import 'prefs.dart';
import 'settings_frame.dart';

/// Where the app keeps its own files (mock).
const appFilesDir = '~/.config/epic-wallet';

/// Demo states of the page for the tour's shots.
enum AccountDemo { autoLockOpen }

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
    showEToast(context, l.deskSetAcctForgotten, text: l.deskSetAcctForgottenText, tone: ETone.ok);
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
              if (ref.watch(deskLinkedDevicesOnProvider)) const _DevicesRow(),
            ],
          ),
          BackupGroup(demo: widget.arg is BackupDemo ? widget.arg as BackupDemo : null),
          ESetGroup(
            title: l.deskSetAcctFiles,
            rows: [
              _FolderRow(title: l.deskSetAcctWalletFolder, path: a.folder),
              _FolderRow(title: l.deskSetAcctAppFiles, hint: l.deskSetAcctAppFilesHint, path: a.appFolder ?? appFilesDir),
              if (a.network != 'mainnet' && DeskFeatures.testNetworks)
                ESetRow(title: l.deskSetAcctNetwork, hint: l.deskSetAcctNetworkHint, control: EBadge(a.network, tone: ETone.warn)),
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
              _AutoLockRow(open: widget.arg == AccountDemo.autoLockOpen),
              if (_remembered)
                ESetRow(
                  title: l.deskSetAcctRemembered,
                  hint: l.deskSetAcctRememberedHint(rememberWho(l)),
                  control: ERowControl(child: EButton(label: l.deskSetAcctForget, icon: EIcons.lock, size: EBtnSize.sm, onPressed: _forget)),
                ),
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

/// The button that opens Linked devices from This wallet.
const settingsDevicesOpenKey = ValueKey('settings-devices-open');

/// Linked devices, a page of this wallet (as on the phone): the state line names the device seen
/// last; Open goes to the page.
class _DevicesRow extends ConsumerWidget {
  const _DevicesRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final devices = ref.watch(deskDeviceBookProvider)?.devices ?? const [];
    return ESetRow(
      title: l.expLinkedDevices,
      text: devicesStateLine(l, devices, DateTime.now()),
      badge: EBadge(l.advExperimental),
      hint: l.expLinkedDevicesHint,
      control: ERowControl(
        child: EButton(
          key: settingsDevicesOpenKey,
          label: l.commonOpen,
          icon: EIcons.devices,
          size: EBtnSize.sm,
          onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsDevices),
        ),
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
      showEToast(context, l.deskSetAcctFolderNotFound, text: path, tone: ETone.warn);
      return;
    }
    if (!await ref.read(deskOpenFolderProvider)(path) && context.mounted) showEToast(context, l.deskSetLnodeFolderNotOpened, text: path, tone: ETone.warn);
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

/// Auto-lock: after how many minutes without a key or the mouse (the phone's choices), or
/// Never (testers looked for an Off in the list; a separate switch was missed). Never keeps the
/// minutes, so choosing a time again needs no second step. Lock wallet works either way.
class _AutoLockRow extends ConsumerWidget {
  const _AutoLockRow({this.open = false});

  /// The list opens with the page (the tour's shot).
  final bool open;

  /// The list's value for Never; the minutes are all positive.
  static const _never = -1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(deskProvider.select((d) => d.settings));
    void save(DeskSettings next) => ref.read(deskProvider.notifier).saveSettings(next);
    return ESetRow(
      title: l.settingsAutoLock,
      hint: l.deskSetAcctAutoLockHint,
      control: ERowControl(
        child: ESelect<int>(
          key: const ValueKey('auto-lock-minutes'),
          size: EBtnSize.sm,
          semanticLabel: l.settingsAutoLock,
          value: s.autoLockOn ? s.autoLockMinutes : _never,
          openInitially: open,
          items: [
            for (final m in autoLockChoices) ESelectItem(m, autoLockLabel(l, m)),
            ESelectItem(_never, autoLockLabel(l, null)),
          ],
          onChanged: (m) => save(
            m == _never ? s.copyWith(autoLockOn: false) : s.copyWith(autoLockOn: true, autoLockMinutes: m),
          ),
        ),
      ),
    );
  }
}
