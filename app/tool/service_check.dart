// SPDX-License-Identifier: Apache-2.0
// Checks service files; see docs/services.md. Run through tools/service-check.
//   service_check.dart <file.json>...              check the files
//   service_check.dart --try <address> <file>...   also say what an address gets from them
import 'dart:io';

import 'package:epic_wallet/src/services/service_check.dart';
import 'package:epic_wallet/src/services/service_rules.dart';

void main(List<String> args) {
  final at = args.indexOf('--try');
  final address = at < 0 ? null : args[at + 1];
  final paths = at < 0 ? args : [...args.take(at), ...args.skip(at + 2)];
  if (paths.isEmpty) {
    stderr.writeln('usage: tools/service-check [--try <address>] <file.json>...');
    exit(2);
  }
  final taken = <String>{};
  final passed = <ServiceFile>[];
  var failed = false;
  for (final path in paths) {
    final text = File(path).readAsStringSync();
    final problems = checkServiceFile(path.split(Platform.pathSeparator).last, text, taken: taken);
    if (problems.isEmpty) {
      passed.add(parseServiceFile(text));
      stdout.writeln('ok   $path');
    } else {
      failed = true;
      stdout.writeln('FAIL $path');
      for (final problem in problems) {
        stdout.writeln('     $problem');
      }
    }
  }
  if (address != null) {
    final guidance = matchService(address, ServiceRules.from(passed));
    stdout.writeln(guidance == null ? 'no hint for $address' : 'hint for $address: ${guidance.hints.map((h) => h.id).join(', ')}');
  }
  exit(failed ? 1 : 0);
}
