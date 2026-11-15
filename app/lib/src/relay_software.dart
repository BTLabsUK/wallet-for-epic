// SPDX-License-Identifier: Apache-2.0
/// Which software an Epicbox relay runs: Epicmail (BT Labs' relay, also the official Epic Cash
/// one) or anything else.
///
/// The relay says so itself. Epicmail serves `/.well-known/epicbox.json` with
/// `"software":"epicmail"`; the old epicbox software serves no such file. There is no list of
/// host names: a relay that answers otherwise, or not at all, is shown as Epicbox, as before.
///
/// The one GET goes through [httpGet], so the network mode, the Epicbox switch and Tor apply as
/// to every request of the app's own. It follows no redirect, reads at most [relayInfoMaxBytes]
/// and sends no header beyond the defaults. Answers are kept in memory ([RelaySoftwareBook]):
/// a relay's answer for [relaySoftwareFresh], a failed request only for [relaySoftwareRetry].
/// No timers run.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'known_relays.dart';
import 'network.dart';
import 'network_gate.dart';
import 'net/http.dart';
import 'providers.dart' show walletConfigProvider;

/// What a relay is known to run.
enum RelaySoftware {
  /// Its info file names Epicmail.
  epicmail,

  /// It answered, and the answer does not name Epicmail (or there is no such file).
  other,

  /// No answer (offline, blocked by the mode, timeout). Shown as Epicbox.
  unknown,
}

/// The relay's info file.
const String relayInfoPath = '/.well-known/epicbox.json';

/// The most the app reads of it; the file is a few hundred bytes.
const int relayInfoMaxBytes = 8192;

/// How long the one request gets.
const Duration relayInfoTimeout = Duration(seconds: 12);

/// How long an answer stands.
const Duration relaySoftwareFresh = Duration(hours: 6);

/// How long a request that got no answer stands, so the next screen asks again soon.
const Duration relaySoftwareRetry = Duration(seconds: 45);

/// The GET ([httpGetBytes] is the app's).
typedef RelayInfoFetch = Future<HttpBytes> Function(Uri url, {required Duration timeout, required int maxBytes, required bool followRedirects});

/// The info file's URL of [relay].
Uri relayInfoUrl(EpicboxRelay relay) => Uri(scheme: 'https', host: relay.host, port: relay.port == 443 ? null : relay.port, path: relayInfoPath);

/// What an answer of [status] with [body] says: Epicmail when the file is a JSON object whose
/// `software` is `epicmail`, otherwise other.
RelaySoftware relaySoftwareFromReply(int status, List<int> body) {
  if (status != 200) return RelaySoftware.other;
  try {
    final json = jsonDecode(utf8.decode(body, allowMalformed: true));
    final software = json is Map ? json['software'] : null;
    return software is String && software.trim().toLowerCase() == 'epicmail' ? RelaySoftware.epicmail : RelaySoftware.other;
  } on FormatException {
    return RelaySoftware.other;
  }
}

/// The answers so far and the one request per relay at a time.
class RelaySoftwareBook {
  RelaySoftwareBook({RelayInfoFetch? fetch, DateTime Function()? now}) : _fetch = fetch ?? httpGetBytes, _now = now ?? DateTime.now;

  final RelayInfoFetch _fetch;
  final DateTime Function() _now;
  final Map<EpicboxRelay, ({RelaySoftware software, DateTime at})> _seen = {};
  final Map<EpicboxRelay, Future<RelaySoftware>> _running = {};

  /// What [relay] is known to run, without a request: unknown when it was never asked or the
  /// answer is stale.
  RelaySoftware known(EpicboxRelay relay) {
    final s = _seen[relay];
    if (s == null) return RelaySoftware.unknown;
    final limit = s.software == RelaySoftware.unknown ? relaySoftwareRetry : relaySoftwareFresh;
    return _now().difference(s.at) < limit ? s.software : RelaySoftware.unknown;
  }

  /// [known], or the relay's own answer. Never throws.
  Future<RelaySoftware> lookup(EpicboxRelay relay) {
    final s = _seen[relay];
    if (s != null) {
      final limit = s.software == RelaySoftware.unknown ? relaySoftwareRetry : relaySoftwareFresh;
      if (_now().difference(s.at) < limit) return Future.value(s.software);
    }
    return _running[relay] ??= _ask(relay).whenComplete(() {
      _running.remove(relay);
    });
  }

  Future<RelaySoftware> _ask(EpicboxRelay relay) async {
    RelaySoftware answer;
    try {
      final reply = await _fetch(relayInfoUrl(relay), timeout: relayInfoTimeout, maxBytes: relayInfoMaxBytes, followRedirects: false);
      answer = relaySoftwareFromReply(reply.status, reply.bytes);
    } on NetTooLarge {
      answer = RelaySoftware.other;
    } on Object {
      answer = RelaySoftware.unknown;
    }
    _seen[relay] = (software: answer, at: _now());
    return answer;
  }
}

final relaySoftwareBookProvider = Provider<RelaySoftwareBook>((ref) => RelaySoftwareBook());

/// What [relay] runs. Unknown, without a request, while the Epicbox switch or the network mode
/// holds the connection (nothing of the app's own reaches a relay then).
final relaySoftwareProvider = FutureProvider.autoDispose.family<RelaySoftware, EpicboxRelay>((ref, relay) {
  try {
    NetGate.checkEpicbox('relay software');
  } on NetBlocked {
    return RelaySoftware.unknown;
  }
  return ref.watch(relaySoftwareBookProvider).lookup(relay);
});

/// [relay] runs Epicmail, as far as it has said. False while the answer is on its way.
bool relayIsEpicmail(WidgetRef ref, EpicboxRelay relay) => ref.watch(relaySoftwareProvider(relay)).value == RelaySoftware.epicmail;

/// The open wallet's own relay.
EpicboxRelay? ownRelay(WidgetRef ref) => ref.watch(
  walletConfigProvider.select((c) => c == null ? null : EpicboxRelay(host: c.epicboxDomain.toLowerCase(), port: c.epicboxPort)),
);

/// The open wallet's own relay runs Epicmail, as far as it has said.
bool ownRelayIsEpicmail(WidgetRef ref) {
  final relay = ownRelay(ref);
  return relay != null && relayIsEpicmail(ref, relay);
}

/// The relay of a payment's counterparty [address] when it runs Epicmail. Only relays the app
/// lists are asked (the wallet's own, the settings' and the monitor's): opening a payment from
/// a stranger's address never makes the app connect to the host the address names.
bool addressRelayIsEpicmail(WidgetRef ref, String? address, {Iterable<EpicboxRelay> extra = const []}) {
  final relay = address == null ? null : recipientRelay(address);
  if (relay == null || !isKnownRelay(relay, extra: extra)) return false;
  return relayIsEpicmail(ref, relay);
}
