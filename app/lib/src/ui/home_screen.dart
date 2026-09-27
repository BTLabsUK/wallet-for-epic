import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../errors.dart';
import '../network.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'receive_screen.dart';
import 'restore_screen.dart' show ScanProgressView;
import 'send_screen.dart';

/// The amount a transaction moved, excluding the fee, and whether it left the wallet.
({BigInt amount, bool outgoing}) txAmount(TxEntry tx) {
  final net = tx.amountCredited - tx.amountDebited;
  if (!net.isNegative) return (amount: net, outgoing: false);
  final sent = -net - (tx.fee ?? BigInt.zero);
  return (amount: sent.isNegative ? BigInt.zero : sent, outgoing: true);
}

String txKindLabel(TxKind kind) => switch (kind) {
  TxKind.coinbase => 'Mining reward',
  TxKind.received => 'Received',
  TxKind.sent => 'Sent',
  TxKind.receivedCancelled => 'Receive cancelled',
  TxKind.sentCancelled => 'Send cancelled',
};

/// Local `yyyy-MM-dd HH:mm`.
String formatTimestamp(int unixSeconds) {
  final t = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

enum _MenuAction { rescan, lock }

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refresh() async {
    ref.invalidate(nodeTipProvider);
    try {
      await ref.read(homeProvider.notifier).reload();
    } catch (_) {
      // The balance card shows the error.
    }
  }

  Future<void> _rescan() async {
    final confirmed = await _confirm(
      title: 'Full rescan',
      body:
          'Scan the whole chain for this wallet\'s outputs? This can take a '
          'long time.',
      action: 'Rescan',
    );
    if (!confirmed) return;
    final ok = await ref
        .read(scanProvider.notifier)
        .run(startHeight: BigInt.one);
    if (ok && mounted) await _refresh();
  }

  Future<void> _cancelTx(TxEntry tx) async {
    final confirmed = await _confirm(
      title: 'Cancel transaction',
      body:
          'Cancel this unconfirmed send and unlock its funds? Only do this if '
          'the recipient will not finalize it.',
      action: 'Cancel transaction',
    );
    if (!confirmed) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    try {
      await session.cancelTransaction(txId: tx.id);
      if (!mounted) return;
      _showMessage('Transaction cancelled');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(describeError(error));
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(walletConfigProvider);
    final home = ref.watch(homeProvider);
    final scan = ref.watch(scanProvider);
    final data = home.value;
    final title = config == null ? 'Wallet' : chainLabel(config.chain);

    return Scaffold(
      appBar: AppBar(
        title: Text('Epic Cash · $title'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: home.isLoading || scan.running ? null : _refresh,
          ),
          PopupMenuButton<_MenuAction>(
            tooltip: 'More',
            onSelected: (action) => switch (action) {
              _MenuAction.rescan => _rescan(),
              _MenuAction.lock => lockWallet(context, ref),
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _MenuAction.rescan,
                enabled: !scan.running,
                child: const Text('Full rescan'),
              ),
              const PopupMenuItem(
                value: _MenuAction.lock,
                child: Text('Lock wallet'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (home.isLoading) const LinearProgressIndicator(),
                  if (scan.running || scan.error != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ScanProgressView(scan: scan),
                      ),
                    ),
                  if (home.hasError && !home.isLoading)
                    ErrorText(describeError(home.error!)),
                  if (data != null) BalanceCard(summary: data.summary),
                  const _NodeTipLine(),
                  const SizedBox(height: 8),
                  const _AddressCard(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: const Icon(Icons.north_east),
                          label: const Text('Send'),
                          onPressed: () => _open(const SendScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: const Icon(Icons.south_west),
                          label: const Text('Receive'),
                          onPressed: () => _open(const ReceiveScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Transactions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (data != null && data.transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No transactions yet.'),
                    ),
                  if (data != null)
                    for (final tx in data.transactions)
                      TxTile(
                        tx: tx,
                        onCancel: tx.kind == TxKind.sent && !tx.confirmed
                            ? () => _cancelTx(tx)
                            : null,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Spendable balance with the other buckets underneath.
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.summary});

  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(String label, BigInt value) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(epicText(value)),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Spendable', style: theme.textTheme.labelLarge),
            Text(
              epicText(summary.spendable),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            row('Awaiting confirmation', summary.awaitingConfirmation),
            row('Locked', summary.locked),
            row('Immature', summary.immature),
            if (!summary.validatedWithNode)
              const ErrorText(
                'Not validated with node. These numbers come from the local '
                'database and may be out of date.',
              ),
          ],
        ),
      ),
    );
  }
}

class _NodeTipLine extends ConsumerWidget {
  const _NodeTipLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tip = ref.watch(nodeTipProvider);
    final text = switch (tip) {
      AsyncData(:final value) => 'Node tip height: ${value.height}',
      AsyncError(:final error) => describeError(error),
      _ => 'Contacting node…',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _AddressCard extends ConsumerWidget {
  const _AddressCard();

  void _showQr(BuildContext context, String address) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Epicbox address'),
        content: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Semantics(
                  label: 'QR code of the epicbox address',
                  image: true,
                  child: SizedBox.square(
                    dimension: 236,
                    child: PrettyQrView.data(data: address),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(address, textAlign: TextAlign.center),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(addressProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Epicbox address',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  switch (address) {
                    AsyncData(:final value) => SelectableText(value),
                    AsyncError(:final error) => ErrorText(describeError(error)),
                    _ => const Text('Loading…'),
                  },
                ],
              ),
            ),
            if (address case AsyncData(:final value)) ...[
              IconButton(
                tooltip: 'Copy address',
                icon: const Icon(Icons.copy),
                onPressed: () => copyText(context, value, 'Address'),
              ),
              IconButton(
                tooltip: 'Show QR code',
                icon: const Icon(Icons.qr_code),
                onPressed: () => _showQr(context, value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One transaction log entry.
class TxTile extends StatelessWidget {
  const TxTile({super.key, required this.tx, this.onCancel});

  final TxEntry tx;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final (:amount, :outgoing) = txAmount(tx);
    final cancelled =
        tx.kind == TxKind.sentCancelled || tx.kind == TxKind.receivedCancelled;
    final status = cancelled
        ? 'Cancelled'
        : tx.confirmed
        ? 'Confirmed'
        : 'Pending';
    final fee = tx.fee;
    final details = [
      status,
      formatTimestamp(tx.createdAtUnix.toInt()),
      if (fee != null && outgoing) 'Fee ${epicText(fee)}',
    ].join(' · ');
    final icon = switch (tx.kind) {
      TxKind.coinbase => Icons.bolt,
      TxKind.received => Icons.south_west,
      TxKind.sent => Icons.north_east,
      TxKind.receivedCancelled || TxKind.sentCancelled => Icons.block,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(
        '${txKindLabel(tx.kind)}  ${outgoing ? '-' : '+'}${epicText(amount)}',
      ),
      subtitle: Text(details),
      trailing: onCancel == null
          ? null
          : IconButton(
              tooltip: 'Cancel transaction',
              icon: const Icon(Icons.cancel_outlined),
              onPressed: onCancel,
            ),
    );
  }
}
