// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../restore_scan.dart';
import 'common.dart';
import 'restore_screen.dart' show ScanProgressView;
import 'settings_history.dart' show importHistoryBackup;
import 'theme/protocol.dart' show EdgeCard;
import 'theme/tokens.dart';

/// Home's card for a restore that has not finished ([restoreScanProvider]): the scan from
/// block 0 running, waiting for the network, or failed with Try again. After a rebuilt
/// database it also offers the history backup ([historyImportOfferProvider]). Nothing when
/// neither applies.
class RestoreCard extends ConsumerWidget {
  const RestoreCard({super.key});

  /// Try again, for tests.
  static const Key retryKey = ValueKey('restore-card-retry');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restore = ref.watch(restoreScanProvider);
    final offer = ref.watch(historyImportOfferProvider);
    if (!restore.required && !offer) return const SizedBox.shrink();
    final scan = ref.watch(scanProvider);
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final error = restore.error;
    return EdgeCard(
      edge: restore.required ? t.warn : t.accent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (restore.required) ...[
              Semantics(
                header: true,
                child: Text(l.restoreUnfinishedTitle, style: theme.textTheme.titleSmall),
              ),
              const SizedBox(height: 4),
              if (scan.running) ...[
                Text(l.restoreUnfinishedRunning),
                const SizedBox(height: 8),
                ScanProgressView(scan: scan),
              ] else if (restore.waitingNetwork)
                Text(l.restoreUnfinishedOffline)
              else if (error != null) ...[
                Text(l.restoreUnfinishedFailed),
                ErrorText(describeError(l, error)),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    key: retryKey,
                    onPressed: () => ref.read(restoreScanProvider.notifier).retry(),
                    child: Text(l.launchTryAgain),
                  ),
                ),
              ] else
                Text(l.restoreUnfinishedRunning),
            ],
            if (offer) ...[
              if (restore.required) const Divider(height: 24),
              Text(l.restoreRebuiltImportText),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => ref.read(historyImportOfferProvider.notifier).set(false),
                    child: Text(l.restoreImportNotNow),
                  ),
                  TextButton(
                    onPressed: () async {
                      final imported = await importHistoryBackup(context, ref);
                      if (imported) ref.read(historyImportOfferProvider.notifier).set(false);
                    },
                    child: Text(l.restoreImportButton),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
