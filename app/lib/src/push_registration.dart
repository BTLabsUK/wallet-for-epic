/// The wallet's side of `services/push/PROTOCOL.md`: registering this phone's push token for
/// the wallet's Epicbox address, and taking it back.
///
/// The request is signed by LEPIC with the address key ([WalletSession.pushSignature]) and goes
/// straight to the relay on the clearnet, never over Tor and never while Tor is on. Nothing here
/// logs the token, the signature or the address, only what happened.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'push_http_io.dart' if (dart.library.js_interop) 'push_http_stub.dart';
import 'wallet_service.dart';

/// POSTs [body] (JSON) to [url] and answers the status code. Throws when the relay cannot be
/// reached or [timeout] passes.
typedef PushPost = Future<int> Function(Uri url, String body, Duration timeout);

/// The relay's push API; tests answer instead.
final pushPostProvider = Provider<PushPost>((ref) => directPost);

/// What a registration call came to.
enum PushOutcome {
  /// The relay accepted it (204).
  sent,

  /// Nothing was sent: the wallet's address is on another relay, or Tor is on.
  skipped,

  /// The relay refused it or could not be reached.
  failed,
}

class PushRegistration {
  PushRegistration({
    required this.post,
    required this.now,
    required this.clearnet,
  });

  /// The one relay with a push API; a wallet on another relay is not registered.
  static const String relayHost = 'flooepicbox.btlabs.uk';
  static final Uri base = Uri.https(relayHost, '/push/v1');

  final PushPost post;

  /// The time of the signature, unix seconds are taken from it.
  final DateTime Function() now;

  /// Whether the clearnet route is open right now (Tor off). Asked right before each request.
  final bool Function() clearnet;

  /// Whether [address] (`<key>`, `<key>@host` or `<key>@host:port`) is on the push relay.
  static bool onRelay(String address) {
    final at = address.indexOf('@');
    if (at < 0) return false;
    final host = address.substring(at + 1).split(':').first.toLowerCase();
    return host == relayHost;
  }

  Future<PushOutcome> register(
    WalletSession session,
    String token, {
    Duration timeout = const Duration(seconds: 10),
  }) => _send('register', session, token, timeout);

  Future<PushOutcome> unregister(
    WalletSession session,
    String token, {
    Duration timeout = const Duration(seconds: 10),
  }) => _send('unregister', session, token, timeout);

  Future<PushOutcome> _send(
    String action,
    WalletSession session,
    String token,
    Duration timeout,
  ) async {
    var where = 'on $relayHost';
    try {
      // A wallet moved off the BT Labs relay may still be registered there: an unregister
      // goes anyway, naming the bare key (the service accepts it), a register does not.
      final address = await session.epicboxAddress();
      final onPushRelay = onRelay(address);
      // The first 8 characters of the key, as the push service logs them, and the relay.
      where = '${address.length > 8 ? address.substring(0, 8) : address} on $relayHost';
      if (!onPushRelay && action == 'register') {
        logInfo('push', '$action skipped, the wallet is not on the push relay');
        return PushOutcome.skipped;
      }
      if (!clearnet()) {
        logInfo('push', '$action skipped, Tor is on');
        return PushOutcome.skipped;
      }
      final stamp = now().millisecondsSinceEpoch ~/ 1000;
      final signed = await session.pushSignature(
        action: action,
        token: token,
        timestamp: stamp,
      );
      // Signing takes a moment on the wallet's thread: Tor may have been switched on meanwhile.
      if (!clearnet()) {
        logInfo('push', '$action skipped, Tor came on');
        return PushOutcome.skipped;
      }
      final status = await post(
        base.replace(path: '${base.path}/$action'),
        _json(signed, token, stamp, bareKey: !onPushRelay),
        timeout,
      );
      if (status == 204) {
        logInfo('push', '$action done, HTTP 204, $where');
        return PushOutcome.sent;
      }
      logWarn('push', '$action refused, HTTP $status, $where');
    } on TimeoutException {
      logWarn('push', '$action timed out, $where');
    } catch (e) {
      // The type only: a message could carry the address.
      logWarn(
        'push',
        '$action failed, ${e is WalletError ? e.kind.name : e.runtimeType}, $where',
      );
    }
    return PushOutcome.failed;
  }

  static String _json(
    PushSignature signed,
    String token,
    int stamp, {
    bool bareKey = false,
  }) => jsonEncode({
    'address': bareKey ? signed.address.split('@').first : signed.address,
    'token': token,
    'timestamp': stamp,
    'signature': signed.signature,
  });
}
