// SPDX-License-Identifier: Apache-2.0
/// Switching the node or the epicbox relay of the open wallet without locking it.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'log.dart';
import 'network.dart';
import 'node_failover_phone.dart' show nodeFailoverWatchProvider;
import 'providers.dart';
import 'server_list.dart' show ServerKind, sameServer;
import 'wallet_service.dart';

/// Runs the open wallet's server switches one at a time. A switch the user asks for while one
/// runs waits; a later one asked meanwhile takes its place, so only the latest waiting target
/// runs. A failover switch runs only if the user asked for none since it was asked.
class ServerSwitcher {
  Future<void> _tail = Future<void>.value();

  /// Bumped by each switch the user asks for.
  int _userAsks = 0;

  /// User switches asked for and not finished.
  int _userOpen = 0;

  /// A switch the user asked for. Runs after the one running; true without running when a
  /// later one replaced it while it waited.
  Future<bool> user(Future<bool> Function() job) {
    final mine = ++_userAsks;
    _userOpen++;
    return _queue(() => mine == _userAsks ? job() : Future<bool>.value(true)).whenComplete(() => _userOpen--);
  }

  /// A failover switch: false without running when the user asked for a switch since, or one
  /// of theirs is still waiting or running.
  Future<bool> failover(Future<bool> Function() job) {
    if (_userOpen > 0) return Future<bool>.value(false);
    final seen = _userAsks;
    return _queue(() => seen == _userAsks ? job() : Future<bool>.value(false));
  }

  Future<bool> _queue(Future<bool> Function() job) {
    final done = Completer<bool>();
    _tail = _tail.then((_) async {
      try {
        done.complete(await job());
      } catch (e, s) {
        done.completeError(e, s);
      }
    });
    return done.future;
  }
}

/// The switcher of the open wallet: a new one with each session.
final serverSwitcherProvider = Provider<ServerSwitcher>((ref) {
  ref.watch(sessionProvider);
  return ServerSwitcher();
});

/// Saves [nodeUrl] and [relay] as the servers of the current network and moves the open wallet
/// onto them: LEPIC reconnects the node, the listener moves to a new relay once the payment in
/// hand is answered, and the wallet stays unlocked. Payments under way finish first.
///
/// [nodeApiSecret] goes to the node for this session only; the phone keeps no node secret.
/// Returns false, after saving, when no wallet is open: the caller starts the app flow again.
/// A refused switch throws the [WalletError] and saves nothing, so the old servers stay.
///
/// Switches run one at a time ([ServerSwitcher]); one replaced by a later pick while it waited
/// returns true and changes nothing. A new node is a pick: node failover drops what it was doing.
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
  if (!sameServer(ServerKind.node, nodeUrl, opened.nodeUrl) && container.exists(nodeFailoverWatchProvider)) {
    container.read(nodeFailoverWatchProvider.notifier).userPicked();
  }
  return container.read(serverSwitcherProvider).user(() async {
    // Read when it runs: a switch before it may have changed the wallet's servers.
    final opened = container.read(walletConfigProvider);
    if (container.read(sessionProvider) != session || opened == null) return false;
    return _switchLive(container, session, choice.preset, opened, nodeUrl, nodeApiSecret, relay);
  });
}

Future<bool> _switchLive(
  ProviderContainer container,
  WalletSession session,
  NetworkPreset preset,
  WalletConfig opened,
  String nodeUrl,
  String? nodeApiSecret,
  EpicboxRelay relay,
) async {
  final notifier = container.read(networkChoiceProvider.notifier);
  final next = WalletConfig(
    dataDir: opened.dataDir,
    chain: opened.chain,
    nodeUrl: nodeUrl,
    nodeApiSecret: nodeApiSecret,
    epicboxDomain: relay.host,
    epicboxPort: relay.port,
    walletId: opened.walletId,
    offline: opened.offline,
  );
  final relayChanged =
      next.epicboxDomain != opened.epicboxDomain ||
      next.epicboxPort != opened.epicboxPort;
  // A scan running goes on after the switch, which cancels it.
  await container.read(scanProvider.notifier).duringSwitch(() => session.setServers(config: next));
  // Both servers move to the top of their lists: the first entry is the one in use.
  await notifier.save(preset, nodeUrl, relay: relay);
  logInfo(
    'network',
    'switched live: node ${Uri.tryParse(nodeUrl)?.host ?? '?'}, relay ${relay.label}',
  );
  // The session may have been locked while the switch ran; then the next open reads the save.
  if (container.read(sessionProvider) != session) return true;
  // The own address carries the relay (addressProvider reads it again), and
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

/// Moves the open wallet onto [nodeUrl] for this session only (node failover,
/// `node_failover_phone.dart`): nothing is saved and the lists stay as they are, so the next
/// start opens on the chosen node. The relay stays. False when no wallet is open or it was
/// locked meanwhile, or when the user picked a server since ([ServerSwitcher.failover]); a
/// refused switch throws the [WalletError] and the old node stays.
Future<bool> switchNodeForSession(Ref ref, String nodeUrl) async {
  final session = ref.read(sessionProvider);
  if (session == null) return false;
  return ref.read(serverSwitcherProvider).failover(() async {
    if (!ref.mounted || ref.read(sessionProvider) != session) return false;
    final opened = ref.read(walletConfigProvider);
    if (opened == null) return false;
    return _switchForSession(ref, session, opened, nodeUrl);
  });
}

Future<bool> _switchForSession(Ref ref, WalletSession session, WalletConfig opened, String nodeUrl) async {
  final next = WalletConfig(
    dataDir: opened.dataDir,
    chain: opened.chain,
    nodeUrl: nodeUrl,
    epicboxDomain: opened.epicboxDomain,
    epicboxPort: opened.epicboxPort,
    walletId: opened.walletId,
    offline: opened.offline,
  );
  await ref.read(scanProvider.notifier).duringSwitch(() => session.setServers(config: next));
  if (!ref.mounted || ref.read(sessionProvider) != session) return false;
  logInfo('network', 'node failover: ${Uri.tryParse(nodeUrl)?.host ?? '?'} for this session');
  ref.read(walletConfigProvider.notifier).select(next);
  ref.invalidate(nodeTipProvider);
  ref.invalidate(homeProvider);
  return true;
}
