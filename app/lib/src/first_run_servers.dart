// SPDX-License-Identifier: Apache-2.0
/// First run: a fresh install's wallet starts on servers that answer from here. When the
/// first-start step is answered (`levels/first_start.dart`), before any wallet exists and so
/// before any address is shown or shared, the node and the Epicbox server in use (the first of
/// each list of the settings file) are asked, together with the rest of each list, all at once
/// with a short timeout. One that does not answer gives way to the first of its list that does,
/// which becomes the one in use (moved to the top of the list, as Switch server does). Nothing
/// answering, or a probe that could not run, leaves the list as it is.
///
/// Only then: an install that already has a wallet never gets here, and after first run an
/// Epicbox server is only ever moved by the user (another server is another address). Node
/// failover stays automatic.
///
/// Pure Dart: the phone and the desktop pass their own probes and their way to save.
library;

import 'dart:async';

import 'log.dart';
import 'net/probe_not_run.dart';
import 'network.dart' show EpicboxRelay;
import 'server_list_file.dart' show useServerValues;
import 'settings_file/host_settings.dart';

/// How long the whole pick may take: each probe has its own shorter timeout.
const Duration firstRunPickLimit = Duration(seconds: 10);

/// The servers first run moved to, or null for each that stays.
typedef FirstRunPick = ({String? node, EpicboxRelay? relay});

/// Asks every node and Epicbox server of [settings]' lists at once ([nodeAnswers],
/// [relayAnswers]; each true when it answered, false or an error when not, [ProbeNotRun] when
/// it could not ask) and returns the first of each list that answered, unless the one in use
/// did or could not be asked.
Future<FirstRunPick> pickFirstRunServers(
  HostSettings settings, {
  required Future<bool> Function(String url) nodeAnswers,
  required Future<bool> Function(EpicboxRelay relay) relayAnswers,
}) async {
  final nodes = settings.nodeUrls;
  final relays = [for (final s in settings.epicboxServers) EpicboxRelay(host: s.host, port: s.port)];
  Future<bool?> ask<T>(Future<bool> Function(T) probe, T server) async {
    try {
      return await probe(server).timeout(firstRunPickLimit);
    } on ProbeNotRun {
      return null;
    } on Object {
      return false;
    }
  }

  final answers = await Future.wait([
    Future.wait([for (final n in nodes) ask(nodeAnswers, n)]),
    Future.wait([for (final r in relays) ask(relayAnswers, r)]),
  ]);
  T? first<T>(List<T> list, List<bool?> answered) {
    // The one in use answered, or could not be asked: it stays.
    if (list.isEmpty || answered.first != false) return null;
    for (var i = 1; i < list.length; i++) {
      if (answered[i] == true) return list[i];
    }
    return null;
  }

  return (node: first(nodes, answers[0]), relay: first(relays, answers[1]));
}

/// [pickFirstRunServers], then what it moved to saved through [save] (the settings file's
/// values, [useServerValues]). Returns the pick.
Future<FirstRunPick> moveToAnsweringServers(
  HostSettings settings, {
  required Future<bool> Function(String url) nodeAnswers,
  required Future<bool> Function(EpicboxRelay relay) relayAnswers,
  required Future<void> Function(Map<String, Object> values) save,
}) async {
  final pick = await pickFirstRunServers(settings, nodeAnswers: nodeAnswers, relayAnswers: relayAnswers);
  final node = pick.node;
  final relay = pick.relay;
  if (node == null && relay == null) {
    logInfo('network', 'first run: the servers in use answer');
    return pick;
  }
  final values = useServerValues(settings, node: node, relay: relay?.label);
  if (values.isNotEmpty) await save(values);
  logInfo(
    'network',
    'first run: ${[
      if (node != null) 'node ${Uri.tryParse(node)?.host ?? '?'}',
      if (relay != null) 'Epicbox ${relay.label}',
    ].join(', ')} in use, the first of the list that answers here',
  );
  return pick;
}

/// The pick under way, if first run started one: wallet creation waits for it
/// ([firstRunServersSettled]) so the new wallet's address is on the server picked.
Future<void>? _pending;

/// Runs [pick] as first run's server pick; [firstRunServersSettled] waits for it.
void startFirstRunServers(Future<void> Function() pick) {
  _pending = pick().catchError((Object e) {
    logWarn('network', 'first run: server check failed: ${e.runtimeType}');
  });
}

/// Waits for first run's server pick, at most [firstRunPickLimit] and a little; at once when
/// none runs.
Future<void> firstRunServersSettled() async {
  final pending = _pending;
  if (pending == null) return;
  await pending.timeout(firstRunPickLimit + const Duration(seconds: 2), onTimeout: () {});
}

/// For tests: forgets a pick.
void resetFirstRunServers() => _pending = null;
