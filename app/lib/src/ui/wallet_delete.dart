// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../devices/device_store.dart' show DeviceStore;
import '../devices/phone_devices.dart' show deviceServiceProvider;
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../restore_scan.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../wallet_service.dart';
import 'app_dialog.dart';
import 'common.dart';
import 'launch_screen.dart';
import 'work_status.dart';

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
/// [onStep] hears each step as it starts, for the line under the wait ([deleteStepText]).
Future<void> deleteWalletEverywhere(
  WidgetRef ref,
  WalletConfig config, {
  bool stopScan = false,
  void Function(DeleteStep step)? onStep,
}) async {
  final restoreScan = ref.read(restoreScanProvider.notifier);
  // Held until the wallet is gone, so the stopped restore scan does not start again.
  restoreScan.hold();
  try {
    if ((stopScan || restoreScan.scanning) && ref.read(scanProvider).running) {
      onStep?.call(DeleteStep.scan);
      await _stopRunningScan(ref);
    }
    await _delete(ref, config, onStep ?? (_) {});
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

/// The steps of a delete, in order.
enum DeleteStep { scan, devices, files, keys }

/// The line under a delete's wait for [step].
String deleteStepText(AppLocalizations l, DeleteStep step) => switch (step) {
  DeleteStep.scan => l.workStoppingRecheck,
  DeleteStep.devices => l.workTellingDevices,
  DeleteStep.files => l.workRemovingFiles,
  DeleteStep.keys => l.workClearingKeys,
};

/// A delete under way, for Settings › Delete: the bar and the step, until the next screen
/// replaces it. Closed only by that screen.
class DeleteProgressDialog extends StatelessWidget {
  const DeleteProgressDialog({super.key, required this.step});

  final ValueListenable<DeleteStep?> step;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopScope(
      canPop: false,
      child: AppDialog(
        icon: Icons.delete_outline,
        tone: DialogTone.risk,
        title: l.settingsDeleteTitle,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 10),
            ValueListenableBuilder<DeleteStep?>(
              valueListenable: step,
              builder: (context, value, _) => WorkStatus(
                text: deleteStepText(l, value ?? DeleteStep.files),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The most a clean-up after the core's delete may take: a platform call that never answers
/// cannot hold the screen. The core's own store calls are bounded in `pin_wrap.dart`.
const Duration deleteStepLimit = Duration(seconds: 20);

Future<void> _delete(WidgetRef ref, WalletConfig config, void Function(DeleteStep step) onStep) async {
  // The linked device is told first, best effort: its records go with the database, and
  // nothing else would tell it.
  final devices = ref.read(deviceServiceProvider);
  if (devices != null && (!devices.loaded || devices.book.devices.isNotEmpty)) {
    onStep(DeleteStep.devices);
  }
  await devices?.unlinkAll();
  ref.read(sessionProvider.notifier).lock();
  onStep(DeleteStep.files);
  // The core waits until every call on this wallet has ended before it removes the files.
  await ref.read(walletServiceProvider).deleteWallet(config: config);
  onStep(DeleteStep.keys);
  // Past the limit the delete fails, so the launch screen says so: a sealed PIN left behind
  // would keep a new wallet off this chain.
  await ref.read(vaultProvider).forget(config.chain).timeout(deleteStepLimit);
  await ref.read(appSettingsProvider.notifier).forgetHistoryBackup(config.chain).timeout(deleteStepLimit);
  try {
    // Its linked devices, keyed as phone_devices.dart keys them.
    await DeviceStore(ref.read(secretStoreProvider), chain: config.chain, walletId: config.walletId)
        .clear()
        .timeout(deleteStepLimit);
  } catch (error) {
    logWarn('delete', 'forgetting linked devices failed: ${error.runtimeType}');
  }
  try {
    await ref.read(sharedFilesCleanupProvider)().timeout(deleteStepLimit);
  } catch (error) {
    // Leftover copies in the cache are harmless next to a deleted wallet; keep going.
    logWarn('delete', 'clearing shared files failed: $error');
  }
  logInfo('delete', 'clean-up done');
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
