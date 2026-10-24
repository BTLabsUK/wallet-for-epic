/// Checks the review runs beside the fee estimate before an epicbox send: the node answers,
/// our listener is connected, and the recipient's relay answers: healthy at the monitor, or,
/// for a relay the monitor does not list or when it cannot be reached, a WebSocket handshake
/// to the relay itself.
///
/// Only the node check blocks: without a node the send cannot be built or posted. A relay that
/// does not answer offers a payment file instead; the listener only warns.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'known_relays.dart';

export 'known_relays.dart' show recipientRelay;
import 'log.dart';
import 'net/tor_switch.dart';
import 'net/ws_probe.dart';
import 'network.dart';
import 'providers.dart';
import 'relay_directory.dart';
import 'server_list_store.dart' show ServerKind, serverListProvider;
import 'wallet_service.dart';

/// How long the node may take to give its tip before the check fails.
const Duration nodeCheckTimeout = Duration(seconds: 8);

/// The same while the Tor switch is on: the tip comes through a circuit, which can take far
/// longer than a direct answer (LEPIC gives its node 90 s over Tor), and a slow circuit is not
/// a node that does not answer.
const Duration nodeTorCheckTimeout = Duration(seconds: 90);

/// How long the node check waits now.
Duration nodeCheckTimeoutNow() =>
    TorSwitch.on ? nodeTorCheckTimeout : nodeCheckTimeout;

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
    this.unknownRelay,
  });

  final CheckOutcome node;
  final CheckOutcome listener;

  /// The recipient's relay, and how the monitor sees it; both null when skipped.
  final EpicboxRelay? relay;
  final CheckOutcome? relayOutcome;

  /// The recipient's relay when the app does not know it ([isKnownRelay]): a warning that the
  /// address may be mistyped, never a block.
  final EpicboxRelay? unknownRelay;

  /// Confirm is allowed only once the node has answered.
  bool get canSend => node == CheckOutcome.passed;

  /// [canSend], and the recipient's relay has been checked: their relay is known before
  /// anything is sent.
  bool get ready => canSend && relayOutcome != CheckOutcome.running;

  /// An epicbox check failed: the send is allowed, with a warning.
  bool get warns =>
      listener == CheckOutcome.failed || relayOutcome == CheckOutcome.failed;
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
  Iterable<EpicboxRelay> known = const [],
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
    // A probe that could not run (Tor not connected) says nothing about the relay.
    if (relayOutcome == null &&
        !relays.isLoading &&
        probe != null &&
        probe.error is! ProbeNotRun) {
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
    // Not while the monitor's list is still coming: it may well list it.
    unknownRelay:
        relay == null || relays.isLoading || isKnownRelay(relay, extra: known)
        ? null
        : relay,
  );
}

/// A fresh tip from the open wallet's node, at most [nodeCheckTimeout] late, or
/// [nodeTorCheckTimeout] while the Tor switch is on. Not the header's `nodeTipProvider`, which
/// may hold an answer from minutes ago.
final sendNodeCheckProvider = FutureProvider.autoDispose<NodeTip>((ref) {
  final session = ref.watch(sessionProvider);
  if (session == null) throw StateError('Wallet is locked');
  final config = ref.watch(walletConfigProvider);
  if (config == null) throw StateError('No network selected');
  // Through the wallet, so it follows the wallet's Tor.
  return session.nodeTipFor(config: config).timeout(nodeCheckTimeoutNow());
});

/// Says whether a relay answers a WebSocket handshake. Tests replace it.
abstract interface class RelayProbe {
  Future<bool> reachable(EpicboxRelay relay);
}

/// `wss://<host>:<port>`, within [probeTimeout], or [torProbeTimeout] while the Tor switch is
/// on: then the handshake goes through tor as the wallet's Epicbox connection does (BT Labs'
/// relays at their onions, others through an exit, names resolved by tor), and a slow circuit
/// is not a relay that does not answer. A try over Tor that fails at once (a circuit that did
/// not build, an exit that refused) gets one more, on a new circuit; only silence for the
/// whole timeout, or two failures, say the relay does not answer. Tor not connected in time
/// throws [ProbeNotRun]: the relay was never asked.
class WebSocketRelayProbe implements RelayProbe {
  const WebSocketRelayProbe({this.uriFor = relayProbeUri});

  /// The URL opened for a relay; tests point it elsewhere.
  final Uri Function(EpicboxRelay relay) uriFor;

  @override
  Future<bool> reachable(EpicboxRelay relay) async {
    final url = uriFor(relay);
    final timeout = relayProbeTimeout();
    final watch = Stopwatch()..start();
    var ok = await probeWebSocket(url, timeout: timeout);
    var tries = 1;
    if (!ok && TorSwitch.on && watch.elapsed < timeout ~/ 2) {
      tries = 2;
      ok = await probeWebSocket(url, timeout: timeout);
    }
    logInfo(
      'send',
      'relay check ${relay.host}: ${ok ? 'answers' : 'no answer'}'
      '${TorSwitch.on ? ' over Tor' : ''}, $tries ${tries == 1 ? 'try' : 'tries'}, '
      '${watch.elapsed.inMilliseconds} ms',
    );
    return ok;
  }
}

/// How long the relay probe waits now.
Duration relayProbeTimeout() => TorSwitch.on ? torProbeTimeout : probeTimeout;

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
      final mine = config == null
          ? const <String>[]
          : ref.watch(serverListProvider((ServerKind.relay, config.chain))).value?.entries ?? const <String>[];
      return sendPreflight(
        known: [
          if (relays.hasValue && !relays.hasError)
            for (final r in relays.requireValue) r.relay,
          for (final label in mine) ?EpicboxRelay.parse(label),
          if (config != null)
            EpicboxRelay(host: config.epicboxDomain, port: config.epicboxPort),
        ],
        node: ref.watch(sendNodeCheckProvider),
        listener: ref.watch(listenerProvider),
        relays: relays,
        relay: relay,
        probe: relay == null || relays.isLoading || listed
            ? null
            : ref.watch(relayProbeCheckProvider(relay)),
      );
    });
