// SPDX-License-Identifier: Apache-2.0
/// Send's quiet reach check: once a Link address is complete, its wallet is asked once, in the
/// background, which slate versions it takes (`check_version` at `/v2/foreign`, as LEPIC's own
/// send asks first). Only a failure is shown, and Continue stays on; Review opens only once the
/// wallet has answered (waited for, a failure sends back to To). Nothing is asked in Node only or Kill switch, for an onion while the app's own
/// requests do not go over Tor, or on the web (the browser's CORS check would fail every one).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;

import 'advanced.dart' show NetworkMode;
import 'net/http.dart';
import 'net/tor_switch.dart' show TorSwitch;
import 'send_route.dart';

/// What the check found.
enum ReachResult {
  /// Not asked (the mode, an onion without Tor, the web), or no answer yet.
  unknown,

  /// A wallet answered.
  answers,

  /// Nothing answered (refused, timed out, no route).
  noAnswer,

  /// Something answered, but not as an Epic wallet.
  notWallet,
}

/// How long the check waits; an onion gets longer.
const Duration reachTimeout = Duration(seconds: 10);
const Duration reachOnionTimeout = Duration(seconds: 45);

/// Whether Send asks [to] at all in [mode].
bool reachCheckApplies(RecipientInput to, {required NetworkMode mode}) {
  if (kIsWeb || !to.isLink) return false;
  if (mode == NetworkMode.killSwitch || mode == NetworkMode.nodeOnly) return false;
  if (to.kind == RecipientInputKind.onion) return TorSwitch.carried;
  return true;
}

/// Tests answer the check here instead of asking a network; null asks it.
@visibleForTesting
Future<ReachResult> Function(RecipientInput to)? reachCheckForTest;

/// Asks the wallet at [to] once. Never throws.
Future<ReachResult> checkWalletAnswers(RecipientInput to, {required NetworkMode mode}) async {
  if (!reachCheckApplies(to, mode: mode)) return ReachResult.unknown;
  final test = reachCheckForTest;
  if (test != null) return test(to);
  final Uri url;
  if (to.kind == RecipientInputKind.onion) {
    url = Uri.parse('http://${to.host}/v2/foreign');
  } else {
    final scheme = to.kind == RecipientInputKind.https ? 'https' : 'http';
    url = Uri.parse('$scheme://${to.hostShown}${to.portShown}${to.path}/v2/foreign');
  }
  try {
    final reply = await httpPost(
      url,
      body: utf8.encode('{"jsonrpc":"2.0","method":"check_version","id":1,"params":[]}'),
      contentType: 'application/json',
      timeout: to.kind == RecipientInputKind.onion ? reachOnionTimeout : reachTimeout,
      maxBytes: 64 * 1024,
      // Plain http to the local network goes direct while Tor is on, as the send does.
      direct: plainHttpGoesDirect(to.address),
    );
    return _isWallet(reply) ? ReachResult.answers : ReachResult.notWallet;
  } on NetTooLarge {
    return ReachResult.notWallet;
  } on Object {
    return ReachResult.noAnswer;
  }
}

/// Whether [reachFallback] is asked after [result]: nothing answered, or something that is not
/// a wallet answered at an address typed without a port (a website on 443, the wallet on 3415).
bool reachFallbackApplies(ReachResult result, RecipientInput to) =>
    result == ReachResult.noAnswer || (result == ReachResult.notWallet && to.notes.contains(RecipientNote.defaultPort));

/// When no wallet answers at [to] as typed, the other addresses Send asks once each, in order
/// ([checkWalletAnswers]): with no port given, the same address on the listener's port
/// ([listenPort]); for a name typed without a scheme (it got `https://`), plain `http://` on the
/// port given or the listener's, unless plain http is held now (Tor on, Tor only). The first
/// that answers, else null. Send then shows it in To; a plain one's review says it is not
/// encrypted.
Future<RecipientInput?> reachFallback(RecipientInput to, {required NetworkMode mode, required int listenPort}) async {
  if (!to.isUrl) return null;
  final noPort = to.notes.contains(RecipientNote.defaultPort);
  final host = to.unicodeHost ?? to.hostShown;
  final scheme = to.kind == RecipientInputKind.https ? 'https' : 'http';
  final tries = [
    if (noPort && to.port != listenPort) '$scheme://$host:$listenPort${to.path}',
    if (to.kind == RecipientInputKind.https && to.notes.contains(RecipientNote.httpsAdded))
      'http://$host:${noPort ? listenPort : to.port}${to.path}',
  ];
  for (final t in tries) {
    final next = readRecipient(t, defaultRelay: '', listenPort: listenPort);
    if (!next.isUrl || (next.kind == RecipientInputKind.http && plainHttpHeldNow(next.address))) continue;
    if (await checkWalletAnswers(next, mode: mode) == ReachResult.answers) return next;
  }
  return null;
}

/// A foreign API's answer: `{"result": {"Ok": {"foreign_api_version": …}}}`.
bool _isWallet(HttpReply reply) {
  if (!reply.ok) return false;
  try {
    final body = jsonDecode(reply.body);
    if (body is! Map) return false;
    final result = body['result'];
    final ok = result is Map ? (result['Ok'] ?? result['ok']) : null;
    return ok is Map && ok.containsKey('foreign_api_version');
  } on FormatException {
    return false;
  }
}
