// SPDX-License-Identifier: Apache-2.0
/// Whether the domain a paired contact claims is proven by the file the domain serves.
///
/// LEPIC's core only holds the claim (`ContactView.peerDomain`, its attestation) and judges a
/// file it is given (`contactDomainVerify`). Fetching is the app's: a GET of
/// `https://<domain>/.well-known/epic-wallet.json` through [httpGetBytes], so the network mode and
/// Tor apply, with no redirect followed and no more than [domainFileMaxBytes] read. Only a 200
/// answer is handed to the core; anything else leaves the claim [DomainStatus.claimed].
///
/// The last check of each contact is kept in the wallet's meta file ([DomainCheckBook]). A claim
/// is checked when it was never checked, when its attestation changed, and then once in
/// [domainRecheckEvery]; a check that sent no request (the network mode or Tor not ready) is not
/// counted and the next trigger tries again. `isDomainBacked` reads the status; no timers run.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'history/domain_check_book.dart';
import 'log.dart';
import 'models.dart' show PairingRecord;
import 'net/http.dart';

export 'history/domain_check_book.dart' show DomainStatus;

/// How long a check stands before the next one.
const Duration domainRecheckEvery = Duration(hours: 24);

/// The most the app reads of the file; the core refuses a longer one as well.
const int domainFileMaxBytes = 4096;

/// How long the one request gets.
const Duration domainFetchTimeout = Duration(seconds: 15);

/// The file's path on the claimed domain.
const String domainFilePath = '/.well-known/epic-wallet.json';

/// The reason kept when the file was longer than [domainFileMaxBytes]; the core's own reason
/// for a file it was given that long.
const String domainFileTooLarge = 'file_too_large';

/// The GET of the file ([httpGetBytes] is the app's).
typedef DomainFetch = Future<HttpBytes> Function(Uri url, {required Duration timeout, required int maxBytes, required bool followRedirects});

/// The core's judgment of [file] for contact [id] (`contactDomainVerify`): proven, or the
/// refused reason as the core names it.
typedef DomainVerify = Future<({bool proven, String? refused})> Function(String id, Uint8List file);

class DomainCheck {
  DomainCheck({required this.log, required this.verify, DomainFetch? fetch, DateTime Function()? now})
    : _fetch = fetch ?? httpGetBytes,
      _now = now ?? DateTime.now;

  final DomainCheckLog log;
  final DomainVerify verify;
  final DomainFetch _fetch;
  final DateTime Function() _now;

  final Set<String> _running = {};

  /// A short hash of the claim's [domain], then one of its [attestation]: a changed claim is
  /// checked again.
  static String claimKey(String domain, Uint8List? attestation) => _hash(domain.codeUnits) + _hash([...domain.codeUnits, 0, ...?attestation]);

  static String _hash(List<int> bytes) => sha256.convert(bytes).bytes.take(6).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Where [id]'s claim of [domain] stands: the last check of a claim of this domain, else
  /// claimed. Null for a contact that claims no domain.
  ///
  /// The peer signs its claim again with the time in each pairing message and contact update,
  /// so the attestation changes with every update. A new attestation of the same domain keeps
  /// the last status until its check ([due] at once) has run: the update that brings a relay
  /// move would otherwise find a proven contact merely claimed, and follow the move unasked.
  DomainStatus? statusOf(String id, String? domain) {
    if (domain == null) return null;
    final rec = log.book.checks[id];
    return rec != null && (rec.attestation?.startsWith(_hash(domain.codeUnits)) ?? false) ? rec.status : DomainStatus.claimed;
  }

  /// Why the last check of [id] did not prove the claim (a short code), null when it did or
  /// none ran.
  String? reasonOf(String id) => log.book.checks[id]?.reason;

  /// Whether [p]'s claim is due a check: never checked, the claim changed, or the last check
  /// is [domainRecheckEvery] old.
  bool due(PairingRecord p) {
    final domain = p.peerDomain;
    if (domain == null || p.ended) return false;
    final rec = log.book.checks[p.id];
    if (rec == null || rec.attestation != claimKey(domain, p.peerDomainAttestation)) return true;
    return _now().millisecondsSinceEpoch - rec.checkedAt >= domainRecheckEvery.inMilliseconds;
  }

  /// Fetches the file of [p]'s domain and has the core judge it. [DomainStatus.proven] or
  /// [DomainStatus.refused] when the core did (or the file was too long to read); else
  /// [DomainStatus.claimed], with the error kept ([reasonOf]). Never throws.
  Future<DomainStatus> run(PairingRecord p) async {
    final domain = p.peerDomain;
    if (domain == null) return DomainStatus.claimed;
    if (!_running.add(p.id)) return statusOf(p.id, domain) ?? DomainStatus.claimed;
    try {
      final key = claimKey(domain, p.peerDomainAttestation);
      final Uri url;
      try {
        url = Uri.https(domain, domainFilePath);
      } on FormatException {
        return await _save(p.id, key, DomainStatus.claimed, 'domain');
      }
      final HttpBytes reply;
      try {
        reply = await _fetch(url, timeout: domainFetchTimeout, maxBytes: domainFileMaxBytes, followRedirects: false);
      } on NetTooLarge {
        return await _save(p.id, key, DomainStatus.refused, domainFileTooLarge);
      } on NetError catch (error) {
        // No request was made: the network mode refused it, or Tor is not connected yet. Not a
        // check; the next trigger tries again.
        if (error.message == netModeError || error.message == 'Tor not connected') return DomainStatus.claimed;
        return await _save(p.id, key, DomainStatus.claimed, error.message);
      } on TimeoutException {
        return await _save(p.id, key, DomainStatus.claimed, 'timeout');
      }
      // A transport that does not cap the body: the core is not given a file this long.
      if (reply.bytes.length > domainFileMaxBytes) return await _save(p.id, key, DomainStatus.refused, domainFileTooLarge);
      // A redirect, a missing file and a server error say nothing of the claim.
      if (reply.status != 200) return await _save(p.id, key, DomainStatus.claimed, 'http ${reply.status}');
      try {
        final verdict = await verify(p.id, reply.bytes);
        return await _save(p.id, key, verdict.proven ? DomainStatus.proven : DomainStatus.refused, verdict.proven ? null : verdict.refused ?? 'refused');
      } on Object catch (error) {
        return await _save(p.id, key, DomainStatus.claimed, 'verify ${error.runtimeType}');
      }
    } finally {
      _running.remove(p.id);
    }
  }

  Future<DomainStatus> _save(String id, String key, DomainStatus status, String? reason) async {
    try {
      await log.record(id, DomainCheckRec(status: status, checkedAt: _now().millisecondsSinceEpoch, reason: reason, attestation: key));
    } on Object catch (error) {
      // A meta file this app may not write loses the status, never the contact.
      logWarn('domain', 'check not recorded: ${error.runtimeType}');
    }
    return status;
  }
}
