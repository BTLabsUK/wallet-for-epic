/// Checks the review runs beside the fee estimate before an epicbox send: the node answers,
/// our listener is connected, and the recipient's relay answers: healthy at the monitor, or,
/// for a relay the monitor does not list or when it cannot be reached, a WebSocket handshake
/// to the relay itself.
///
/// Only the node check blocks: without a node the send cannot be built or posted. A relay that
/// does not answer offers a payment file instead; the listener only warns.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'net/ws_probe.dart';
import 'network.dart';
import 'providers.dart';
import 'relay_directory.dart';
import 'wallet_service.dart';

/// How long the node may take to give its tip before the check fails.
const Duration nodeCheckTimeout = Duration(seconds: 8);

enum SendCheck { node, listener, relay }

enum CheckOutcome { running, passed, failed }

/// The checks of one review. The relay check is left out only for an address without a relay,
/// or when no probe is given.
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

  /// [canSend], and the recipient's relay has been checked: their relay is known before
  /// anything is sent.
  bool get ready => canSend && relayOutcome != CheckOutcome.running;

  /// An epicbox check failed: the send is allowed, with a warning.
  bool get warns =>
      listener == CheckOutcome.failed || relayOutcome == CheckOutcome.failed;
}

/// The relay of an `<key>@<relay>[:port]` address, or null when it has none.
EpicboxRelay? recipientRelay(String address) {
  final at = address.lastIndexOf('@');
  return at < 0 ? null : EpicboxRelay.parse(address.substring(at + 1));
}

/// The [SendPreflight] from the node's answer, the listener and the monitor's relay list. The
/// monitor's word on a relay it lists stands; for one it does not list, or when it gave no
/// answer, [probe] (the relay's own handshake, when asked) decides.
SendPreflight sendPreflight({
  required AsyncValue<NodeTip> node,
  required ListenerState listener,
  required AsyncValue<List<RelayStatus>> relays,
  required EpicboxRelay? relay,
  AsyncValue<bool>? probe,
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
    if (relayOutcome == null && !relays.isLoading && probe != null) {
      relayOutcome = probe.isLoading
          ? CheckOutcome.running
          : probe.value == true
          ? CheckOutcome.passed
          : CheckOutcome.failed;
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
  final session = ref.watch(sessionProvider);
  if (session == null) throw StateError('Wallet is locked');
  final config = ref.watch(walletConfigProvider);
  if (config == null) throw StateError('No network selected');
  // Through the wallet, so it follows the wallet's Tor.
  return session.nodeTipFor(config: config).timeout(nodeCheckTimeout);
});

/// Says whether a relay answers a WebSocket handshake. Tests replace it.
abstract interface class RelayProbe {
  Future<bool> reachable(EpicboxRelay relay);
}

/// `wss://<host>:<port>`, within [probeTimeout].
class WebSocketRelayProbe implements RelayProbe {
  const WebSocketRelayProbe();

  @override
  Future<bool> reachable(EpicboxRelay relay) =>
      probeWebSocket(relayProbeUri(relay), timeout: probeTimeout);
}

/// The URL the probe opens for [relay]: plain `ws` on a loopback host, where LEPIC talks to
/// the relay without TLS too (a local test relay), `wss` everywhere else.
Uri relayProbeUri(EpicboxRelay relay) => Uri(
  scheme: _loopback(relay.host) ? 'ws' : 'wss',
  host: relay.host,
  port: relay.port,
);

bool _loopback(String host) {
  final h = host.toLowerCase();
  if (h == 'localhost' || h == '::1' || h == '[::1]') return true;
  final ip = RegExp(r'^127\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$').firstMatch(h);
  return ip != null && [1, 2, 3].every((i) => int.parse(ip.group(i)!) <= 255);
}

/// A probe that answers [answer] at once, for tests.
class FakeRelayProbe implements RelayProbe {
  FakeRelayProbe({this.answer = true});

  bool answer;

  /// Relays probed, in order.
  final List<EpicboxRelay> probed = [];

  @override
  Future<bool> reachable(EpicboxRelay relay) async {
    probed.add(relay);
    return answer;
  }
}

final relayProbeProvider = Provider<RelayProbe>(
  (ref) => const WebSocketRelayProbe(),
);

/// One handshake with [relay], asked again by each review (it is disposed when the review is
/// left).
final relayProbeCheckProvider = FutureProvider.autoDispose
    .family<bool, EpicboxRelay>(
      (ref, relay) => ref.watch(relayProbeProvider).reachable(relay),
    );

/// The review's checks for a send to an address on [relay]. Listen to it from the tap on
/// Review until the sheet closes, so the checks run beside the fee estimate and each review
/// asks the node again.
final sendPreflightProvider = Provider.autoDispose
    .family<SendPreflight, EpicboxRelay?>((ref, relay) {
      final config = ref.watch(walletConfigProvider);
      final preset = config == null
          ? null
          : networkPresets.where((p) => p.chain == config.chain).firstOrNull;
      final relays = preset == null
          ? const AsyncData(<RelayStatus>[])
          : ref.watch(relayStatusProvider(preset));
      // Probed only when the monitor has nothing to say about it.
      final listed =
          relays.hasValue &&
          !relays.hasError &&
          relays.requireValue.any((r) => r.relay == relay);
      return sendPreflight(
        node: ref.watch(sendNodeCheckProvider),
        listener: ref.watch(listenerProvider),
        relays: relays,
        relay: relay,
        probe: relay == null || relays.isLoading || listed
            ? null
            : ref.watch(relayProbeCheckProvider(relay)),
      );
    });
