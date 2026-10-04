/// Checks the review sheet runs beside the fee estimate before an epicbox send: the node
/// answers, our listener is connected, and the recipient's relay is healthy at the monitor.
///
/// Only the node check blocks: without a node the send cannot be built or posted. The epicbox
/// checks warn, because the relay keeps the message until the other side picks it up.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network.dart';
import 'providers.dart';
import 'relay_directory.dart';
import 'wallet_service.dart';

/// How long the node may take to give its tip before the check fails.
const Duration nodeCheckTimeout = Duration(seconds: 8);

enum SendCheck { node, listener, relay }

enum CheckOutcome { running, passed, failed }

/// The checks of one review. A check that cannot be made (a relay the monitor does not list,
/// or no monitor answer) is left out.
class SendPreflight {
  const SendPreflight({
    required this.node,
    required this.listener,
    this.relay,
    this.relayOutcome,
  });

  final CheckOutcome node;
  final CheckOutcome listener;

  /// The recipient's relay, and how the monitor sees it; both null when skipped.
  final EpicboxRelay? relay;
  final CheckOutcome? relayOutcome;

  /// Confirm is allowed only once the node has answered.
  bool get canSend => node == CheckOutcome.passed;

  /// An epicbox check failed: the send is allowed, with a warning.
  bool get warns =>
      listener == CheckOutcome.failed || relayOutcome == CheckOutcome.failed;
}

/// The relay of an `<key>@<relay>[:port]` address, or null when it has none.
EpicboxRelay? recipientRelay(String address) {
  final at = address.lastIndexOf('@');
  return at < 0 ? null : EpicboxRelay.parse(address.substring(at + 1));
}

/// The [SendPreflight] from the node's answer, the listener and the monitor's relay list.
SendPreflight sendPreflight({
  required AsyncValue<NodeTip> node,
  required ListenerState listener,
  required AsyncValue<List<RelayStatus>> relays,
  required EpicboxRelay? relay,
}) {
  final nodeOutcome = node.isLoading
      ? CheckOutcome.running
      : node.hasValue && !node.hasError
      ? CheckOutcome.passed
      : CheckOutcome.failed;
  CheckOutcome? relayOutcome;
  if (relay != null) {
    if (relays.isLoading) {
      relayOutcome = CheckOutcome.running;
    } else if (relays.hasValue && !relays.hasError) {
      final listed = relays.requireValue.where((r) => r.relay == relay);
      if (listed.isNotEmpty) {
        relayOutcome = listed.first.healthy
            ? CheckOutcome.passed
            : CheckOutcome.failed;
      }
    }
  }
  return SendPreflight(
    node: nodeOutcome,
    listener: listener.connected ? CheckOutcome.passed : CheckOutcome.failed,
    relay: relayOutcome == null ? null : relay,
    relayOutcome: relayOutcome,
  );
}

/// A fresh tip from the open wallet's node, at most [nodeCheckTimeout] late. Not the header's
/// `nodeTipProvider`, which may hold an answer from minutes ago.
final sendNodeCheckProvider = FutureProvider.autoDispose<NodeTip>((ref) {
  final config = ref.watch(walletConfigProvider);
  if (config == null) throw StateError('No network selected');
  return ref
      .watch(walletServiceProvider)
      .nodeTip(config: config)
      .timeout(nodeCheckTimeout);
});

/// The review's checks for a send to an address on [relay]. Listen to it from the tap on
/// Review until the sheet closes, so the checks run beside the fee estimate and each review
/// asks the node again.
final sendPreflightProvider = Provider.autoDispose
    .family<SendPreflight, EpicboxRelay?>((ref, relay) {
      final config = ref.watch(walletConfigProvider);
      final preset = config == null
          ? null
          : networkPresets.where((p) => p.chain == config.chain).firstOrNull;
      return sendPreflight(
        node: ref.watch(sendNodeCheckProvider),
        listener: ref.watch(listenerProvider),
        relays: preset == null
            ? const AsyncData(<RelayStatus>[])
            : ref.watch(relayStatusProvider(preset)),
        relay: relay,
      );
    });
