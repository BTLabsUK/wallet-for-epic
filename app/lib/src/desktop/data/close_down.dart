// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:io' show Platform, ProcessSignal;

import '../../last_session.dart';
import '../../log.dart';

/// Closing the app (the window's close button, Quit): the wallet locks, then the built-in node
/// stops. Each step gets [walletLimit] or [nodeLimit]; one that fails or hangs is logged and
/// skipped, so the app always closes, in every state (Setup, a switch half done, a node
/// starting). A payment under way already has its own wait inside the wallet's lock.
Future<void> deskCloseDown({
  required Future<void> Function() disposeWallet,
  required Future<void> Function() stopNodes,
  Duration walletLimit = const Duration(seconds: 40),
  Duration nodeLimit = const Duration(seconds: 25),
}) async {
  Future<void> step(String what, Future<void> Function() run, Duration limit) async {
    try {
      await Future.sync(run).timeout(limit);
    } on TimeoutException {
      logWarn('desk', 'closing: $what still busy after ${limit.inSeconds} s; closing anyway');
    } on Object catch (e) {
      logWarn('desk', 'closing: $what failed (${e.runtimeType}); closing anyway');
    }
  }

  final watch = Stopwatch()..start();
  logInfo('desk', 'closing'); // l10n-ok: log text
  await step('wallet', disposeWallet, walletLimit); // l10n-ok: log text
  await step('local node', stopNodes, nodeLimit); // l10n-ok: log text
  logInfo('desk', 'closed after ${watch.elapsedMilliseconds} ms'); // l10n-ok: log text
  // A clean end: the next start offers no report of this session.
  lastSession?.clean();
}

/// Ends the app cleanly on SIGTERM or SIGINT (a logout, `kill`, Ctrl+C in a terminal) as Quit
/// does: [close] runs once, however many signals come. Without it the process died at once,
/// and the next start said the app closed unexpectedly. Windows has no SIGTERM to watch: none
/// is watched there. [signals] stands in for the process's signals in tests.
StreamSubscription<ProcessSignal>? deskCloseOnSignals(Future<void> Function() close, {Stream<ProcessSignal>? signals}) {
  final Stream<ProcessSignal> source;
  if (signals != null) {
    source = signals;
  } else {
    if (Platform.isWindows) return null;
    final both = StreamController<ProcessSignal>();
    for (final s in [ProcessSignal.sigterm, ProcessSignal.sigint]) {
      s.watch().listen(both.add);
    }
    source = both.stream;
  }
  var closing = false;
  return source.listen((signal) {
    if (closing) return;
    closing = true;
    logInfo('desk', 'closing on $signal'); // l10n-ok: log text
    unawaited(close());
  });
}
