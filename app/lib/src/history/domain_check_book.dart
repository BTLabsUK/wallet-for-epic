// SPDX-License-Identifier: Apache-2.0
/// What this wallet keeps of its contacts' domain checks (`domain_check.dart`), apart from the
/// rules so the meta file reads it without Flutter.
library;

/// Where a contact's domain claim stands. A host's state: the core only says proven or refused.
enum DomainStatus {
  /// The contact claims a domain; the file it serves has not proven it (not fetched yet, not
  /// reachable, or an answer that is no verdict).
  claimed,

  /// The file the domain serves lists a key that signed the claim.
  proven,

  /// The file was read and does not prove the claim.
  refused,
}

/// One contact's last domain check: [status], when it ran ([checkedAt], Unix ms), why it did not
/// prove ([reason], a short code or error name) and short hashes of the claim's domain and
/// attestation it was made for ([attestation]), so a changed claim is checked again.
class DomainCheckRec {
  const DomainCheckRec({required this.status, required this.checkedAt, this.reason, this.attestation});

  factory DomainCheckRec.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('domain check');
    final status = json['status'], checkedAt = json['checked_at'], reason = json['reason'], att = json['att'];
    final known = DomainStatus.values.where((s) => s.name == status).firstOrNull;
    if (known == null || checkedAt is! int || (reason != null && reason is! String) || (att != null && att is! String)) {
      throw const FormatException('domain check');
    }
    return DomainCheckRec(status: known, checkedAt: checkedAt, reason: reason as String?, attestation: att as String?);
  }

  final DomainStatus status;
  final int checkedAt;
  final String? reason;
  final String? attestation;

  Map<String, Object?> toJson() => {
    'status': status.name,
    'checked_at': checkedAt,
    if (reason != null) 'reason': reason,
    if (attestation != null) 'att': attestation,
  };

  @override
  bool operator ==(Object other) =>
      other is DomainCheckRec && other.status == status && other.checkedAt == checkedAt && other.reason == reason && other.attestation == attestation;

  @override
  int get hashCode => Object.hash(status, checkedAt, reason, attestation);
}

/// The last check of each contact, by pairing id, and the pairings a domain proof ended
/// Verified. The meta file holds it under one key, `domain_checks`, with its version; a file
/// without the key has nothing recorded. Written only when not empty, and not part of a history
/// file.
class DomainCheckBook {
  DomainCheckBook({Map<String, DomainCheckRec>? checks, Map<String, int>? verified}) : checks = {...?checks}, verified = {...?verified};

  /// The version [toJson] writes. A later one is read as far as it goes.
  static const int version = 1;

  factory DomainCheckBook.fromJson(Object? json) {
    if (json == null) return DomainCheckBook();
    if (json is! Map) throw const FormatException('domain_checks');
    final list = switch (json['checks']) {
      null => const <String, Object?>{},
      final Map<Object?, Object?> m => m,
      _ => throw const FormatException('domain_checks checks'),
    };
    final verified = switch (json['verified']) {
      null => const <String, Object?>{},
      final Map<Object?, Object?> m => m,
      _ => throw const FormatException('domain_checks verified'),
    };
    return DomainCheckBook(
      checks: {
        for (final e in list.entries) e.key is String ? e.key as String : throw const FormatException('domain_checks id'): DomainCheckRec.fromJson(e.value),
      },
      verified: {
        for (final e in verified.entries)
          (e.key is String ? e.key as String : throw const FormatException('domain_checks verified')): e.value is int ? e.value as int : throw const FormatException('domain_checks verified'),
      },
    );
  }

  /// The last check, by pairing id.
  final Map<String, DomainCheckRec> checks;

  /// The pairings this wallet ended Verified by the contact's domain proof instead of the
  /// words, by pairing id: when (Unix ms). Words checked later take a pairing out.
  final Map<String, int> verified;

  bool get isEmpty => checks.isEmpty && verified.isEmpty;

  Map<String, Object?> toJson() => {
    'v': version,
    if (checks.isNotEmpty) 'checks': {for (final e in checks.entries) e.key: e.value.toJson()},
    if (verified.isNotEmpty) 'verified': {...verified},
  };

  /// Adds what [other] holds and this lacks.
  void addAll(DomainCheckBook other) {
    for (final e in other.checks.entries) {
      checks.putIfAbsent(e.key, () => e.value);
    }
    for (final e in other.verified.entries) {
      verified.putIfAbsent(e.key, () => e.value);
    }
  }
}

/// Where the checks are kept. `MetaDomainCheckLog` (`wallet_history.dart`) holds them in the
/// wallet's meta file; [MemoryDomainCheckLog] stands in for tests and the fake.
abstract class DomainCheckLog {
  DomainCheckBook get book;

  /// Keeps [rec] as contact [id]'s last check.
  Future<void> record(String id, DomainCheckRec rec);

  /// Keeps that a domain proof ended [id]'s pairing Verified at [at] (Unix ms); null forgets it.
  Future<void> markVerified(String id, int? at);
}

class MemoryDomainCheckLog implements DomainCheckLog {
  MemoryDomainCheckLog([DomainCheckBook? book]) : book = book ?? DomainCheckBook();

  @override
  final DomainCheckBook book;

  @override
  Future<void> record(String id, DomainCheckRec rec) async => book.checks[id] = rec;

  @override
  Future<void> markVerified(String id, int? at) async => at == null ? book.verified.remove(id) : book.verified[id] = at;
}
