/// Switching the node or the epicbox relay of the open wallet without locking it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n.dart';
import 'log.dart';
import 'network.dart';
import 'providers.dart';
import 'server_list_store.dart' show rememberServers;
import 'wallet_service.dart';

/// Saves [nodeUrl] and [relay] as the servers of the current network and moves the open wallet
/// onto them: LEPIC reconnects the node, the listener moves to a new relay once the payment in
/// hand is answered, and the wallet stays unlocked. Payments under way finish first.
///
/// [nodeApiSecret] goes to the node for this session only; the phone keeps no node secret.
/// Returns false, after saving, when no wallet is open: the caller starts the app flow again.
/// A refused switch throws the [WalletError] and saves nothing, so the old servers stay.
Future<bool> switchServersLive(
  WidgetRef ref, {
  required String nodeUrl,
  String? nodeApiSecret,
  required EpicboxRelay relay,
}) async {
  // The screen that asked may close before the switch ends (it waits for a payment in hand):
  // the wallet's state is updated through the container, which outlives it.
  final container = ProviderScope.containerOf(ref.context, listen: false);
  final choice = await ref.read(networkChoiceProvider.future);
  final session = ref.read(sessionProvider);
  final opened = ref.read(walletConfigProvider);
  final notifier = ref.read(networkChoiceProvider.notifier);
  if (session == null || opened == null || opened.chain != choice.preset.chain) {
    await notifier.save(choice.preset, nodeUrl, relay: relay);
    return false;
  }
  final next = WalletConfig(
    dataDir: opened.dataDir,
    chain: opened.chain,
    nodeUrl: nodeUrl,
    nodeApiSecret: nodeApiSecret,
    epicboxDomain: relay.host,
    epicboxPort: relay.port,
    walletId: opened.walletId,
  );
  final relayChanged =
      next.epicboxDomain != opened.epicboxDomain ||
      next.epicboxPort != opened.epicboxPort;
  await session.setServers(config: next);
  await notifier.save(choice.preset, nodeUrl, relay: relay);
  // Connected: both servers are in the pickers' lists, even one the user had removed.
  if (ref.context.mounted) {
    await rememberServers(ref, choice.preset, nodeUrl: nodeUrl, relay: relay);
  }
  logInfo(
    'network',
    'switched live: node ${Uri.tryParse(nodeUrl)?.host ?? '?'}, relay ${relay.label}',
  );
  // The session may have been locked while the switch ran; then the next open reads the save.
  if (container.read(sessionProvider) != session) return true;
  // Own addresses carry the relay (addressProvider and invoiceAddressProvider read again), and
  // push follows it.
  container.read(walletConfigProvider.notifier).select(next);
  if (relayChanged) {
    // LEPIC moves a running listener itself; one that had stopped starts on the new relay.
    final listener = container.read(listenerProvider);
    if (listener.stopped || listener.lost) {
      await container.read(listenerProvider.notifier).restart();
    }
  }
  container.invalidate(nodeTipProvider);
  container.invalidate(homeProvider);
  return true;
}

/// Asks before the relay changes from [from] to [to], saying the epicbox address changes to
/// the new domain. True to go on; always true when the relay stays.
Future<bool> confirmRelaySwitch(
  BuildContext context, {
  required EpicboxRelay from,
  required EpicboxRelay to,
}) async {
  if (from == to) return true;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l = context.l10n;
      return AlertDialog(
        title: Text(l.serverSwitchRelayTitle),
        content: Text(l.serverSwitchRelayBody(to.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.serverSwitchRelayConfirm),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

/// Moves the open wallet onto [nodeUrl] for this session only (node failover,
/// `node_failover_phone.dart`): nothing is saved and the lists stay as they are, so the next
/// start opens on the chosen node. The relay stays. False when no wallet is open or it was
/// locked meanwhile; a refused switch throws the [WalletError] and the old node stays.
Future<bool> switchNodeForSession(Ref ref, String nodeUrl) async {
  final session = ref.read(sessionProvider);
  final opened = ref.read(walletConfigProvider);
  if (session == null || opened == null) return false;
  final next = WalletConfig(
    dataDir: opened.dataDir,
    chain: opened.chain,
    nodeUrl: nodeUrl,
    epicboxDomain: opened.epicboxDomain,
    epicboxPort: opened.epicboxPort,
    walletId: opened.walletId,
  );
  await session.setServers(config: next);
  if (!ref.mounted || ref.read(sessionProvider) != session) return false;
  logInfo('network', 'node failover: ${Uri.tryParse(nodeUrl)?.host ?? '?'} for this session');
  ref.read(walletConfigProvider.notifier).select(next);
  ref.invalidate(nodeTipProvider);
  ref.invalidate(homeProvider);
  return true;
}
