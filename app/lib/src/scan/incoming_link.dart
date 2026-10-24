import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';

/// Longest link accepted; anything longer is dropped before it is looked at.
const int maxLinkChars = 4096;

/// How long a link may wait for the wallet to unlock before [IncomingLinkNotifier.take]
/// treats it as stale.
const Duration linkMaxAge = Duration(minutes: 5);

/// A payment link (epic: or epiccash:) another app opened, and when it arrived.
class IncomingLink {
  const IncomingLink({required this.text, required this.at});
  final String text;
  final DateTime at;
}

/// The clock the link checks use; tests replace it.
final linkClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Set by the UI while a PIN prompt or a send is in progress: a link arriving then is dropped
/// so it cannot change what the user is confirming.
final linkBusyProvider = NotifierProvider<LinkBusyNotifier, bool>(
  LinkBusyNotifier.new,
);

class LinkBusyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool busy) => state = busy;
}

/// Counts links dropped because the UI was busy, so it can show a snackbar for each.
final linkDroppedBusyProvider = NotifierProvider<LinkDroppedBusyNotifier, int>(
  LinkDroppedBusyNotifier.new,
);

class LinkDroppedBusyNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// True when [now] is too soon after the links handled at [handled] (oldest first), or [text]
/// repeats the last one: at most one per 2 s, 3 per 30 s, and the same text not within 10 s.
@visibleForTesting
bool linkRateLimited({
  required String text,
  required DateTime now,
  required List<({String text, DateTime at})> handled,
}) {
  if (handled.isNotEmpty && now.difference(handled.last.at).inMilliseconds < 2000) {
    return true;
  }
  for (final h in handled) {
    if (h.text == text && now.difference(h.at) < const Duration(seconds: 10)) {
      return true;
    }
  }
  final inWindow = handled
      .where((h) => now.difference(h.at) < const Duration(seconds: 30))
      .length;
  return inWindow >= 3;
}

/// The payment link another app opened (Android VIEW intent), waiting until the wallet is
/// unlocked to be routed. One link is held, in memory only; a newer one replaces it.
final incomingLinkProvider =
    NotifierProvider<IncomingLinkNotifier, IncomingLink?>(
      IncomingLinkNotifier.new,
    );

class IncomingLinkNotifier extends Notifier<IncomingLink?> {
  static const MethodChannel _channel = MethodChannel(
    'epic_wallet/incoming_link',
  );

  final List<({String text, DateTime at})> _handled = [];

  @override
  IncomingLink? build() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'link') throw MissingPluginException();
      final text = call.arguments;
      if (text is String) deliver(text);
    });
    ref.onDispose(() => _channel.setMethodCallHandler(null));
    _channel.invokeMethod<Object?>('takePending').then((text) {
      if (text is String) deliver(text);
    }).catchError((Object error) {
      // No native side (desktop, tests): nothing can have been opened.
      if (error is! MissingPluginException) {
        logWarn('links', 'no pending link: $error');
      }
    });
    return null;
  }

  /// Runs every check a link must pass, then holds it. The channel and the tests use this;
  /// a link that fails a check is dropped without a trace, except the busy counter.
  void deliver(String raw) {
    if (raw.length > maxLinkChars) return;
    final text = raw.trim();
    if (text.isEmpty) return;
    final now = ref.read(linkClockProvider)();
    _handled.removeWhere((h) => now.difference(h.at) >= const Duration(seconds: 30));
    // Rate-limited first, so a flood while busy says "finish the payment" once, not per link.
    if (linkRateLimited(text: text, now: now, handled: _handled)) return;
    _handled.add((text: text, at: now));
    if (ref.read(linkBusyProvider)) {
      ref.read(linkDroppedBusyProvider.notifier).bump();
      return;
    }
    state = IncomingLink(text: text, at: now);
  }

  /// Hands the waiting link over and forgets it; null when none, or when it is older than
  /// [linkMaxAge].
  IncomingLink? take() {
    final link = state;
    state = null;
    if (link == null) return null;
    final age = ref.read(linkClockProvider)().difference(link.at);
    return age > linkMaxAge ? null : link;
  }
}
