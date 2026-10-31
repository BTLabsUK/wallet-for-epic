// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../devices/device_store.dart' show DeviceStore;
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../restore_scan.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'launch_screen.dart';

/// Deletes leftover copies of shared files; uisend's `clearSharedFiles`. Tests replace it.
final sharedFilesCleanupProvider = Provider<Future<void> Function()>(
  (ref) => clearSharedFiles,
);

/// Removes [config]'s wallet from this phone with everything the app keeps for it: the open
/// session, the wallet's files and PIN, the history backup note and shared-file copies. Settings › Delete,
/// Forgot PIN and Restore from a phrase all go through it. Throws what the core's delete
/// throws; the session is closed by then, so the caller leaves to the launch screen
/// ([leaveAfterFailedDelete]). With [stopScan] a running scan is stopped first (the user chose
/// to replace the wallet); else only the automatic restore scan is ([RestoreScanNotifier.scanning]).
Future<void> deleteWalletEverywhere(WidgetRef ref, WalletConfig config, {bool stopScan = false}) async {
  final restoreScan = ref.read(restoreScanProvider.notifier);
  // Held until the wallet is gone, so the stopped restore scan does not start again.
  restoreScan.hold();
  try {
    if (stopScan || restoreScan.scanning) await _stopRunningScan(ref);
    await _delete(ref, config);
  } finally {
    restoreScan.release();
  }
}

/// Stops a running scan and waits (at most 30 s) until it has ended; the core's delete waits for
/// its calls to end in any case.
Future<void> _stopRunningScan(WidgetRef ref) async {
  if (!ref.read(scanProvider).running) return;
  final ended = Completer<void>();
  final watch = ref.listenManual(scanProvider.select((s) => s.running), (_, running) {
    if (!running && !ended.isCompleted) ended.complete();
  });
  ref.read(scanProvider.notifier).stop();
  try {
    await ended.future.timeout(const Duration(seconds: 30));
  } on TimeoutException {
    logWarn('delete', 'the scan did not stop in 30 s');
  } finally {
    watch.close();
  }
}

Future<void> _delete(WidgetRef ref, WalletConfig config) async {
  ref.read(sessionProvider.notifier).lock();
  // The core waits until every call on this wallet has ended before it removes the files.
  await ref.read(walletServiceProvider).deleteWallet(config: config);
  await ref.read(vaultProvider).forget(config.chain);
  await ref.read(appSettingsProvider.notifier).forgetHistoryBackup(config.chain);
  try {
    // Its linked devices, keyed as phone_devices.dart keys them.
    await DeviceStore(ref.read(secretStoreProvider), chain: config.chain, walletId: config.walletId).clear();
  } catch (error) {
    logWarn('delete', 'forgetting linked devices failed: ${error.runtimeType}');
  }
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
