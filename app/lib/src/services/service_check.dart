// SPDX-License-Identifier: Apache-2.0
/// The strict check of a service file, for files that ship: `tools/service-check` and
/// `test/services/service_files_test.dart`. The app itself is more forgiving
/// (`parseServiceFile`): it ignores what it does not know, this check names it.
library;

import 'dart:convert';

import 'service_rules.dart';

const Set<String> _fileFields = {'schema', 'id', 'rules'};
const Set<String> _ruleFields = {'kind', 'relay', 'hint'};

/// What is wrong with the file [name] holding [text]; empty when it passes. [taken] holds the
/// relays of the files checked before it: two files naming one relay is a mistake.
List<String> checkServiceFile(String name, String text, {Set<String>? taken}) {
  final problems = <String>[];
  if (utf8.encode(text).length > maxServiceFileBytes) problems.add('larger than $maxServiceFileBytes bytes');
  if (text.runes.any((c) => c > 0x7e)) problems.add('not plain ASCII');
  final ServiceFile file;
  try {
    file = parseServiceFile(text);
  } on ServiceFileRefused catch (e) {
    return [...problems, e.reason];
  }
  if (name != '${file.id}.json') problems.add('the file should be named ${file.id}.json');
  problems.addAll(file.skipped);
  final json = jsonDecode(text) as Map<String, Object?>;
  if (json['schema'] != serviceSchema) problems.add('schema is not $serviceSchema');
  problems.addAll(_unknown('file', json.keys, _fileFields));
  final rules = json['rules']! as List<Object?>;
  if (rules.isEmpty) problems.add('no rules');
  for (final (i, rule) in rules.indexed) {
    if (rule is! Map<String, Object?>) continue;
    if (rule['kind'] != relayNeedsNote) problems.add('rule ${i + 1}: unknown kind ${rule['kind']}');
    problems.addAll(_unknown('rule ${i + 1}', rule.keys, _ruleFields));
  }
  for (final rule in file.rules) {
    if (!(taken?.add(rule.relay) ?? true)) problems.add('${rule.relay} is already in another file');
  }
  return problems;
}

Iterable<String> _unknown(String where, Iterable<String> keys, Set<String> known) =>
    keys.where((k) => !known.contains(k)).map((k) => '$where: unknown field $k');
