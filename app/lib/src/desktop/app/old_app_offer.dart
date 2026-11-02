// SPDX-License-Identifier: Apache-2.0
/// macOS only: the app from before the rename ("Epic Cash Desktop.app", another bundle id) left in
/// /Applications or ~/Applications next to this one after a DMG update. Once per run, when the
/// shell first shows after unlock, one dialog offers to move it to the Bin. Move to Bin asks the
/// runner to trash it (`epic_wallet/old_app`, AppDelegate.swift's `OldApp`, which checks again
/// and only ever trashes, never deletes); Keep is remembered and the dialog does not come back.
/// The data folder is shared and never touched.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../log.dart';
import '../../providers.dart' show secretStoreProvider;
import '../desk_l10n.dart';
import '../widgets/kit.dart';

/// The runner's side: `find` gives the old app's path or null, `trash` with that path gives
/// `ok`, `refused` (it no longer passes the checks) or `failed`.
const MethodChannel oldAppChannel = MethodChannel('epic_wallet/old_app');

/// Set to `kept` when the user chose Keep.
const String deskOldAppKeptKey = 'desk.old_app_kept';

bool _askedThisRun = false;

/// Lets a test ask again in the same run.
@visibleForTesting
void resetDeskOldAppOffer() => _askedThisRun = false;

/// Shows the dialog when an old app is found and Keep was never chosen. No-op off macOS.
Future<void> offerDeskOldAppRemoval(BuildContext context, WidgetRef ref) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS || _askedThisRun) return;
  _askedThisRun = true;
  final store = ref.read(secretStoreProvider);
  try {
    if (await store.read(deskOldAppKeptKey) != null) return;
  } on Object catch (e) {
    logWarn('old-app', 'kept flag not read: ${e.runtimeType}');
    return;
  }
  final String? path;
  try {
    path = await oldAppChannel.invokeMethod<String>('find');
  } on Object catch (e) {
    // An older runner without the channel, or the check failed: nothing to offer.
    logWarn('old-app', 'find failed: ${e.runtimeType}');
    return;
  }
  if (path == null || path.isEmpty || !context.mounted) return;
  final app = _appName(path);
  final trash = await showEDialog<bool>(
    context,
    builder: (_) => OldAppDialog(app: app, folder: _folder(path!)),
  );
  if (!context.mounted) return;
  final l = context.l10n;
  if (trash == false) {
    try {
      await store.write(deskOldAppKeptKey, 'kept');
    } on Object catch (e) {
      logWarn('old-app', 'kept flag not saved: ${e.runtimeType}');
    }
    return;
  }
  // Closed with Esc or outside the dialog: no answer, asked again next run.
  if (trash != true) return;
  String? outcome;
  try {
    outcome = await oldAppChannel.invokeMethod<String>('trash', path);
  } on Object catch (e) {
    logWarn('old-app', 'trash failed: ${e.runtimeType}');
  }
  logInfo('old-app', 'trash: ${outcome ?? 'error'}');
  if (!context.mounted) return;
  if (outcome == 'ok') {
    showEToast(context, l.deskOldAppTrashed(app), tone: ETone.ok);
  } else {
    showEToast(context, l.deskOldAppNotTrashed(app), tone: ETone.risk);
  }
}

/// "Epic Cash Desktop" from ".../Epic Cash Desktop.app".
String _appName(String path) {
  final base = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  final name = base.substring(base.lastIndexOf('/') + 1);
  return name.endsWith('.app') ? name.substring(0, name.length - 4) : name;
}

/// The folder the app is in: "/Applications" or the user's "~/Applications".
String _folder(String path) {
  final base = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  final cut = base.lastIndexOf('/');
  return cut <= 0 ? '/' : base.substring(0, cut);
}

/// Move to Bin (true) or Keep (false).
class OldAppDialog extends StatelessWidget {
  const OldAppDialog({super.key, required this.app, required this.folder});

  final String app;
  final String folder;

  @override
  Widget build(BuildContext context) {
    final nav = Navigator.of(context);
    final l = context.l10n;
    return EDialog(
      title: l.deskOldAppTitle,
      description: l.deskOldAppBody(app, folder),
      icon: EIcons.trash,
      actions: [
        EButton(label: l.deskOldAppKeep, onPressed: () => nav.pop(false)),
        EButton.primary(label: l.deskOldAppTrash, icon: EIcons.trash, onPressed: () => nav.pop(true)),
      ],
    );
  }
}
