// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/devices/device_parts.dart' show devicesStateLine;
import '../../desk_l10n.dart';
import '../../data/desk_levels.dart' show deskLevelUiProvider;
import '../../data/devices_state.dart' show deskDeviceBookProvider, deskLinkedDevicesOnProvider;
import '../../data/files.dart' show deskOpenFolderProvider;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../widgets/kit.dart';
import 'backup.dart';
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
    final ui = ref.watch(deskLevelUiProvider);
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
                  // A name field, not a select (UD-032): the pencil says it is editable, and
                  // becomes the check only while the name differs from the saved one.
                  child: EInput(
                    size: EBtnSize.sm,
                    controller: _label,
                    focusNode: _labelFocus,
                    hint: a.name,
                    semanticLabel: l.deskSetAcctLabel,
                    inputFormatters: [LengthLimitingTextInputFormatter(32)],
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _save(),
                    trailing: _label.text.trim() != a.name && _label.text.trim().isNotEmpty
                        ? EIconButton(icon: EIcons.check, label: l.deskSetAcctSaveLabel, size: EBtnSize.inline, onPressed: _save)
                        : EIconButton(icon: EIcons.pencil, label: l.deskSetAcctLabel, size: EBtnSize.inline, onPressed: _labelFocus.requestFocus),
                  ),
                ),
              ),
              if (ref.watch(deskLinkedDevicesOnProvider)) const _DevicesRow(),
            ],
          ),
          BackupGroup(demo: widget.arg is BackupDemo ? widget.arg as BackupDemo : null),
          // Shallow: Recheck balance is a row here, not in the side list.
          if (!ui.recheckInSideList)
            ESetGroup(
              rows: [
                ESetRow(
                  key: const ValueKey('account-recheck'),
                  title: l.deskSetFrameRescan,
                  hint: l.deskLvShellRecheckHint,
                  control: ERowControl(child: EButton(label: l.commonOpen, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.settingsRescan))),
                ),
              ],
            ),
          // The folders and Set up again: not at Shallow, which has no Set up.
          if (ui.setupWizard)
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
            child: ETip.value(path, mono: true, child: Text(path, style: ts.mono(size: Fs.sm, color: c.dim), overflow: TextOverflow.ellipsis)),
          ),
          SizedBox(width: Sp.x1),
          ECopyButton(text: path, label: l.deskSetAcctCopyPath(title)),
        ],
      ),
    );
  }
}
