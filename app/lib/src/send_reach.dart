// SPDX-License-Identifier: Apache-2.0
/// Send's quiet reach check: once a Link address is complete, its wallet is asked once, in the
/// background, which slate versions it takes (`check_version` at `/v2/foreign`, as LEPIC's own
/// send asks first). Only a failure is shown, and Continue stays on: their wallet may be opened
/// before Send. Nothing is asked in Node only or Kill switch, for an onion while the app's own
/// requests do not go over Tor, or on the web (the browser's CORS check would fail every one).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;

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

/// Asks the wallet at [to] once. Never throws.
Future<ReachResult> checkWalletAnswers(RecipientInput to, {required NetworkMode mode}) async {
  if (!reachCheckApplies(to, mode: mode)) return ReachResult.unknown;
  final Uri url;
  if (to.kind == RecipientInputKind.onion) {
    url = Uri.parse('http://${to.host}/v2/foreign');
  } else {
    final scheme = to.kind == RecipientInputKind.https ? 'https' : 'http';
    url = Uri.parse('$scheme://${to.hostShown}:${to.port}${to.path}/v2/foreign');
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
