import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../push_controller.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'launch_screen.dart';

/// Deletes leftover copies of shared files; uisend's `clearSharedFiles`. Tests replace it.
final sharedFilesCleanupProvider = Provider<Future<void> Function()>(
  (ref) => clearSharedFiles,
);

/// Removes [config]'s wallet from this phone with everything the app keeps for it: the push
/// registration (taken back first, while the wallet can still sign), the open session, the
/// wallet's files and PIN, the history backup note and shared-file copies. Settings › Delete,
/// Forgot PIN and Restore from a phrase all go through it. Throws what the core's delete
/// throws; the session is closed by then, so the caller leaves to the launch screen
/// ([leaveAfterFailedDelete]).
Future<void> deleteWalletEverywhere(WidgetRef ref, WalletConfig config) async {
  try {
    await ref.read(pushControllerProvider.notifier).beforeDelete();
  } catch (error) {
    logWarn('delete', 'push not taken back: ${error.runtimeType}');
  }
  ref.read(sessionProvider.notifier).lock();
  // The core waits until every call on this wallet has ended before it removes the files.
  await ref.read(walletServiceProvider).deleteWallet(config: config);
  await ref.read(vaultProvider).forget(config.chain);
  await ref.read(appSettingsProvider.notifier).forgetHistoryBackup(config.chain);
  try {
    await ref.read(sharedFilesCleanupProvider)();
  } catch (error) {
    // Leftover copies in the cache are harmless next to a deleted wallet; keep going.
    logWarn('delete', 'clearing shared files failed: $error');
  }
}

/// A delete that failed after the session closed: nothing on screen can work without it, so
/// the app starts over at the launch screen (the wallet's PIN screen, when it is still there)
/// and says what went wrong.
void leaveAfterFailedDelete(BuildContext context, WidgetRef ref, Object error) {
  logWarn('delete', 'failed: ${describeError(englishStrings, error)}');
  final l = context.l10n;
  ref
      .read(noticeProvider.notifier)
      .show(
        l.deleteFailedNotice(describeError(l, error)),
        level: NoticeLevel.error,
        persistent: true,
      );
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
    (_) => false,
  );
}
