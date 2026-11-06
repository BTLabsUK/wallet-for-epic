// SPDX-License-Identifier: Apache-2.0
/// Service rules: small data files that let Send recognise a kind of address and remind the
/// user of something (docs/services.md). A rule is data, never code. Its whole output is a
/// [Guidance], which holds fixed hint ids: nothing in it can change an address or an amount,
/// stop a send, or put a file's text on screen.
///
/// No Flutter and no `dart:io` here: `tools/service-check` runs this file in a plain `dart`.
library;

import 'dart:convert';

/// The format this app reads. It goes up only for a change an older app must not misread: a
/// new field or a new rule kind does not need it, older apps ignore those.
const int serviceSchema = 1;

/// The most a service file may weigh; a longer one is skipped.
const int maxServiceFileBytes = 16 * 1024;

/// The most files one source may hold; the rest are skipped.
const int maxServiceFiles = 64;

/// The most rules one file may hold; the rest are skipped.
const int maxServiceRules = 32;

/// What a rule may say: an id in a file, a translated string in the app (`scan_text.dart`). A
/// new hint needs an id here, its strings and a release.
enum ServiceHint {
  /// The address looks like an exchange's and the message is empty.
  exchangeCheckNote('exchange_check_note');

  const ServiceHint(this.id);

  /// The id in a service file.
  final String id;

  static ServiceHint? byId(Object? id) => values.where((h) => h.id == id).firstOrNull;
}

/// All a rule can do. Read-only, and every hook only shows it: the user can always send.
final class Guidance {
  Guidance(Iterable<ServiceHint> hints) : hints = Set.unmodifiable(hints);
  final Set<ServiceHint> hints;
}

/// A rule of the kind `relay_needs_note`: addresses on [relay] need a message.
final class RelayRule {
  const RelayRule(this.relay, this.hint);
  final String relay;
  final ServiceHint hint;
}

/// A file refused whole.
final class ServiceFileRefused implements Exception {
  const ServiceFileRefused(this.reason);
  final String reason;

  @override
  String toString() => reason;
}

/// A file as read: its valid rules, and why any others were left out. A rule of a kind this app
/// does not know is neither: it is ignored without a word, so a newer file stays usable here.
final class ServiceFile {
  const ServiceFile({required this.id, required this.rules, this.skipped = const []});
  final String id;
  final List<RelayRule> rules;
  final List<String> skipped;
}

final RegExp _idPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
/// An Epicbox address takes letters, digits and dots in its relay: a host with a hyphen could
/// never match one.
final RegExp _hostPattern = RegExp(r'^[a-z0-9]+(\.[a-z0-9]+)+$');

/// A file's `id`: lowercase letters and digits, words joined by `-`.
bool validServiceId(Object? id) => id is String && id.length <= 32 && _idPattern.hasMatch(id);

/// An exact host: lowercase, ASCII, with a dot, no port, no wildcard, no scheme.
bool validRelayHost(Object? host) => host is String && host.length <= 253 && _hostPattern.hasMatch(host);

/// Reads a service file. Unknown fields and unknown rule kinds are ignored; a rule that fails
/// its check is left out and named in [ServiceFile.skipped]. Throws [ServiceFileRefused] for a
/// file that has no usable shape, or that is written to a newer [serviceSchema].
ServiceFile parseServiceFile(String text) {
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    throw const ServiceFileRefused('not JSON');
  }
  if (json is! Map<String, Object?>) throw const ServiceFileRefused('not a JSON object');
  final schema = json['schema'];
  if (schema is! int || schema < 1) throw const ServiceFileRefused('schema is not a number');
  if (schema > serviceSchema) throw ServiceFileRefused('schema $schema is newer than $serviceSchema');
  final id = json['id'];
  if (!validServiceId(id)) throw const ServiceFileRefused('id is not lowercase letters, digits and -');
  final list = json['rules'];
  if (list is! List<Object?>) throw const ServiceFileRefused('rules is not a list');
  final rules = <RelayRule>[];
  final skipped = <String>[];
  for (final (i, rule) in list.indexed) {
    if (i == maxServiceRules) {
      skipped.add('more than $maxServiceRules rules');
      break;
    }
    if (rule is! Map<String, Object?>) {
      skipped.add('rule ${i + 1}: not an object');
    } else if (rule['kind'] == relayNeedsNote) {
      final hint = ServiceHint.byId(rule['hint']);
      if (!validRelayHost(rule['relay'])) {
        skipped.add('rule ${i + 1}: relay is not an exact host');
      } else if (hint == null) {
        skipped.add('rule ${i + 1}: unknown hint');
      } else {
        rules.add(RelayRule(rule['relay']! as String, hint));
      }
    }
  }
  return ServiceFile(id: id! as String, rules: rules, skipped: skipped);
}

/// The first rule kind: an address on this relay needs a message.
const String relayNeedsNote = 'relay_needs_note';

/// The rules in use. Each host only ever gains hints: there is no rule that takes one away, so
/// no file can silence another.
final class ServiceRules {
  const ServiceRules._(this._hintsByRelay);

  factory ServiceRules.from(Iterable<ServiceFile> files) {
    final byRelay = <String, Set<ServiceHint>>{};
    for (final rule in files.expand((f) => f.rules)) {
      (byRelay[rule.relay] ??= {}).add(rule.hint);
    }
    return ServiceRules._(byRelay);
  }

  /// No files, no rules: Send shows no hints and everything else works as ever.
  static const ServiceRules none = ServiceRules._({});

  final Map<String, Set<ServiceHint>> _hintsByRelay;
}

/// The rules in use, set once at start (`startServices`).
ServiceRules serviceRules = ServiceRules.none;

/// What [rules] say about [recipient], or null. The host is the text after the last `@`,
/// without port or case, and matches a rule's relay whole: no suffix, no pattern. A relay proves
/// nothing about who holds the key, so a match says "looks like" and never names a service.
Guidance? matchService(String recipient, ServiceRules rules) {
  final at = recipient.lastIndexOf('@');
  if (at < 0) return null;
  final host = recipient.substring(at + 1).split(':').first.trim().toLowerCase();
  final hints = rules._hintsByRelay[host];
  return hints == null ? null : Guidance(hints);
}
