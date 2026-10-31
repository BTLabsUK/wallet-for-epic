// SPDX-License-Identifier: Apache-2.0
/// The first-start step of a fresh install: the level and, in Tor builds, "Undercover from the
/// start" (Network mode › Tor only from the first connection). It comes before Welcome and the
/// PIN, and until it is answered the app opens no connection at all: no node, Epicbox, Tor,
/// status site, signed btlabs.json, price, update check. The gate does that
/// ([NetGate.holdFirstStart], network_gate.dart), not the screens: every connection of the
/// app's own code asks it, and no wallet (so nothing of LEPIC's) exists before the step.
///
/// Platform-neutral: the phone calls [holdUntilFirstStart] in `main.dart`; the desktop can call
/// it the same way with its own store.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../advanced.dart';
import '../log.dart';
import '../network_gate.dart';
import '../secret_store_api.dart';
import '../settings.dart' show appSettingsProvider;
import '../tor_build.dart';
import 'level_providers.dart' show walletLevelProvider;
import 'wallet_level.dart';

/// At launch, before any request: settles the stored level ([settleLevelChoice]) and, for a
/// fresh install still to answer the first-start step, holds every connection. Returns whether
/// it held. A store that can't be read holds nothing: an existing install must never lose its
/// network to a first-start step it will not be shown.
Future<bool> holdUntilFirstStart(SecretStore store) async {
  try {
    final choice = await settleLevelChoice(read: store.read, write: store.write);
    if (choice is! LevelPending) return false;
  } on Object catch (e) {
    logWarn('levels', 'level not read: ${e.runtimeType}');
    return false;
  }
  NetGate.holdFirstStart();
  logInfo('levels', 'first start: no connection until the level is chosen');
  return true;
}

/// Whether the first-start step is still to answer (the UI shows it before anything else), and
/// [FirstStartNotifier.complete] for its Continue / Create / Restore.
final firstStartProvider = NotifierProvider<FirstStartNotifier, bool>(FirstStartNotifier.new);

class FirstStartNotifier extends Notifier<bool> {
  @override
  bool build() => NetGate.firstStartHold;

  /// The step answered: [level] stored, Tor only stored when [undercover] (Tor builds only;
  /// ignored in a no-Tor build), and only then the gate opens, so the first connection is
  /// already made in the chosen mode. Harmless when nothing is held (the level is stored).
  Future<void> complete({required WalletLevel level, bool undercover = false}) async {
    final torOnly = undercover && torBuilt;
    if (torOnly) {
      final settings = await ref.read(appSettingsProvider.future);
      await ref.read(appSettingsProvider.notifier).setAdvanced(settings.advanced.withMode(NetworkMode.torOnly));
    }
    await ref.read(walletLevelProvider.notifier).setLevel(level);
    NetGate.releaseFirstStart();
    if (ref.mounted) state = false;
    logInfo('levels', 'first start answered: level ${level.number}${torOnly ? ', Tor only' : ''}');
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
