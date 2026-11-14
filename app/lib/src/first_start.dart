// SPDX-License-Identifier: Apache-2.0
/// The first-start step of a fresh install: Welcome's Create or Restore and, in Tor builds,
/// "Undercover from the start" (Network mode › Tor only from the first connection). Until it is
/// answered the app opens no connection at all: no node, Epicbox, Tor, status site, signed
/// btlabs.json, price, update check. The gate does that ([NetGate.holdFirstStart],
/// network_gate.dart), not the screens: every connection of the app's own code asks it, and no
/// wallet (so nothing of LEPIC's) exists before the step.
///
/// Platform-neutral: the phone calls [holdUntilFirstStart] in `main.dart`, the desktop through
/// `desk_first_start.dart` with its own markers and store.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'advanced.dart';
import 'first_run_servers.dart';
import 'first_run_servers_phone.dart';
import 'log.dart';
import 'network_gate.dart';
import 'providers.dart' show secretStoreProvider;
import 'secret_store_api.dart';
import 'settings.dart' show appSettingsProvider;
import 'tor_build.dart';

/// The preference that tells a fresh install still to answer the first-start step from one past
/// it. The key and the past value are the ones earlier builds stored, so an install keeps its
/// answer across an update and a downgrade.
const String firstStartKey = 'app.level';

/// Stored while the first-start step waits for its answer.
const String firstStartPending = 'ask';

/// Stored once the step is answered, or for an install that ran before the step existed.
const String firstStartDone = '3';

/// The keys only an install that ran before the first-start step can hold: the network choice,
/// the settings migration marker every launch writes, a sealed wallet PIN on any chain, the
/// tour mark. Any one present means "existing install".
const List<String> existingInstallMarkers = [
  'app.network',
  'app.qr_method_seen',
  'app.advanced_prefs',
  'app.phone_tour_seen',
  'wallet.mainnet.pinSealed',
  'wallet.floonet.pinSealed',
  'wallet.usernet.pinSealed',
];

/// Whether [raw], as [firstStartKey] holds it, is an answer: any value but none and
/// [firstStartPending].
bool firstStartAnswered(String? raw) {
  final t = raw?.trim();
  return t != null && t.isNotEmpty && t != firstStartPending;
}

/// Whether the first-start step still waits, read from [read] and settled once through
/// [write]: a stored value as it is; with none, an existing install ([markers] has a value) is
/// stored as answered and a fresh one as pending. Written at once, so a fresh install killed on
/// the first screen still waits next launch, and an existing one is never asked even after its
/// marker keys are written by the new build.
Future<bool> settleFirstStart({
  required Future<String?> Function(String key) read,
  required Future<void> Function(String key, String value) write,
  List<String> markers = existingInstallMarkers,
}) async {
  final stored = (await read(firstStartKey))?.trim();
  if (stored != null && stored.isNotEmpty) return stored == firstStartPending;
  var existing = false;
  for (final k in markers) {
    if ((await read(k)) != null) {
      existing = true;
      break;
    }
  }
  await write(firstStartKey, existing ? firstStartDone : firstStartPending);
  return !existing;
}

/// At launch, before any request: settles the step ([settleFirstStart]) and, for a fresh
/// install still to answer it, holds every connection. Returns whether it held. A store that
/// can't be read holds nothing: an existing install must never lose its network to a step it
/// will not be shown. [markers]: the phone's by default; the desktop passes its own.
Future<bool> holdUntilFirstStart(SecretStore store, {List<String> markers = existingInstallMarkers}) async {
  try {
    if (!await settleFirstStart(read: store.read, write: store.write, markers: markers)) return false;
  } on Object catch (e) {
    logWarn('first-start', 'not read: ${e.runtimeType}');
    return false;
  }
  NetGate.holdFirstStart();
  logInfo('first-start', 'no connection until the first step is answered');
  return true;
}

/// Whether the first-start step is still to answer (the UI shows it before anything else), and
/// [FirstStartNotifier.complete] for its Create / Restore.
final firstStartProvider = NotifierProvider<FirstStartNotifier, bool>(FirstStartNotifier.new);

class FirstStartNotifier extends Notifier<bool> {
  @override
  bool build() => NetGate.firstStartHold;

  /// The step answered: Tor only stored when [undercover] (Tor builds only; ignored in a no-Tor
  /// build), the answer stored, and only then the gate opens, so the first connection is
  /// already made in the chosen mode. Harmless when nothing is held.
  Future<void> complete({bool undercover = false}) => completeWith(
    undercover: undercover,
    torOnly: () async {
      final settings = await ref.read(appSettingsProvider.future);
      await ref.read(appSettingsProvider.notifier).setAdvanced(settings.advanced.withMode(NetworkMode.torOnly));
    },
    pickServers: () => phoneFirstRunServers(ref),
  );

  /// [complete] for an app that keeps its settings elsewhere (the desktop): [torOnly] stores
  /// Network mode › Tor only. [pickServers], once the gate opens, moves the fresh install off a
  /// node or Epicbox server that does not answer from here (`first_run_servers.dart`); wallet
  /// creation waits for it. Not in Tor only: Tor reaches the servers, whatever this network's
  /// name lookups refuse.
  Future<void> completeWith({
    required bool undercover,
    required Future<void> Function() torOnly,
    Future<void> Function()? pickServers,
  }) async {
    final tor = undercover && torBuilt;
    if (tor) await torOnly();
    await ref.read(secretStoreProvider).write(firstStartKey, firstStartDone);
    final held = NetGate.firstStartHold;
    NetGate.releaseFirstStart();
    if (held && !tor && pickServers != null) startFirstRunServers(pickServers);
    if (ref.mounted) state = false;
    logInfo('first-start', 'answered${tor ? ', Tor only' : ''}');
  }
}

/// Runs [action] once the first-start hold ends (now, when nothing holds): the launch tasks a
/// held start skipped, such as the signed btlabs.json refresh.
void afterFirstStart(void Function() action) {
  if (!NetGate.firstStartHold) {
    action();
    return;
  }
  NetGate.changes.firstWhere((_) => !NetGate.firstStartHold).then((_) => action());
}
