/// The details of a payment another linked device made ("Sent from Desktop"): what that device
/// told this one (recipient, message, fee) with the chain's view (status, block), and, while its
/// coins are held here, Release.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/device_ending.dart';
import '../../devices/device_providers.dart';
import '../../devices/phone_devices.dart';
import '../../l10n.dart';
import '../../wallet_service.dart';
import '../common.dart';
import '../pairing/pairing_parts.dart';
import '../theme/tokens.dart';
import 'device_parts.dart';

class DeviceTxDetails extends ConsumerWidget {
  const DeviceTxDetails({super.key, required this.tx});

  final TxEntry tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final name = tx.deviceName ?? '';
    final tip = tipHeight(ref);
    final display = amountDisplay(ref);
    final view = ref.watch(phoneDevices.view);
    final hold = view?.book.holds.where((h) => h.state.holds && h.slateId == tx.slateId && h.commitments.any(tx.spentCommits.contains)).firstOrNull;
    final message = tx.messages.firstOrNull?.text;
    final fee = tx.fee;
    final height = tx.blockHeight;
    Widget row(String label, String value) => ListTile(
      dense: true,
      title: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
      subtitle: Text(value, style: theme.textTheme.bodyMedium),
    );
    return SlotScaffold(
      appBar: AppBar(title: Text(l.txDetailsTitle)),
      body: ScreenBody(
        children: [
          Text(l.txSentFromDevice(name), style: theme.textTheme.titleLarge?.copyWith(fontFamily: t.headFamily)),
          const SizedBox(height: 8),
          Text(
            display.hidden ? hiddenAmount : '−${epicExact(l, tx.amountDebited - tx.amountCredited)}',
            style: theme.textTheme.headlineSmall?.copyWith(color: t.txSent),
          ),
          const SizedBox(height: 8),
          Row(children: [TxStatusChip(tx: tx, tip: tip)]),
          if (tx.deviceEnding case final ending?)
            if (deviceEndingLine(l, ending, name, tx.deviceWhy) case final line?) ...[const SizedBox(height: 8), PairSmallPrint(line)],
          const SizedBox(height: 16),
          PairCard(
            children: [
              if (tx.counterparty case final to?) row(l.txDetailsSentTo, to),
              if (message != null) row(l.txDetailsMessageFromSender, message),
              if (fee != null && !display.hidden) row(l.txDetailsFee, epicExact(l, fee)),
              row(l.txDetailsDate, formatDateTime(l, DateTime.fromMillisecondsSinceEpoch(tx.timeUnix * 1000))),
            ],
          ),
          if (height != null && tx.confirmed) ...[const SizedBox(height: 12), PairSmallPrint(l.txDetailsCompletedInBlock(height.toString()))],
          const SizedBox(height: 12),
          PairSmallPrint(l.txDeviceMadeOn(name)),
          if (hold != null) ...[
            const SizedBox(height: 8),
            PairSmallPrint(l.txDeviceHeld),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton(
                onPressed: () async {
                  final yes = await confirmDeviceAction(
                    context,
                    title: l.devicesReleaseTitle,
                    body: l.devicesReleaseBody(name),
                    action: l.devicesRelease,
                    risky: true,
                  );
                  if (!yes || !context.mounted) return;
                  await ref.read(deviceServiceProvider)?.releaseByHandOf(hold.deviceId, hold.slateId);
                  ref.read(noticeProvider.notifier).show(l.devicesReleased, level: NoticeLevel.success);
                },
                child: Text(l.devicesRelease),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The device a held coin's payment belongs to, for Outputs: "Held by Desktop's payment".
String? heldByLine(AppLocalizations l, DeviceView? view, String commitment) {
  if (view == null) return null;
  final h = holdOf(view.book, commitment);
  return h == null ? null : l.devicesHeldBy(view.nameOf(h.deviceId));
}
