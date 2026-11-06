// SPDX-License-Identifier: Apache-2.0
// Every test here reads the bundled service files from their folder and names none: it passes
// with any set of files, and with none.
import 'dart:io';

import 'package:epic_wallet/src/scan/scan_router.dart';
import 'package:epic_wallet/src/scan/scan_text.dart';
import 'package:epic_wallet/src/recipient.dart';
import 'package:epic_wallet/src/services/service_check.dart';
import 'package:epic_wallet/src/services/service_loader.dart';
import 'package:epic_wallet/src/services/service_rules.dart';
import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _key = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK';

List<File> _bundled() {
  final dir = Directory('assets/services');
  return dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()..sort((a, b) => a.path.compareTo(b.path));
}

String _name(File f) => f.uri.pathSegments.last;

/// A bundle with no service files, as a build that has none.
final class _NoServices extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => const StandardMessageCodec().encodeMessage(<String, Object>{})!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every bundled file passes the check', () {
    final taken = <String>{};
    for (final file in _bundled()) {
      expect(checkServiceFile(_name(file), file.readAsStringSync(), taken: taken), isEmpty, reason: file.path);
    }
  });

  test('every bundled file is in the build, and its relays match whole', () async {
    final rules = await loadServices([BundledServices(rootBundle)]);
    for (final file in _bundled()) {
      for (final rule in parseServiceFile(file.readAsStringSync()).rules) {
        final relay = rule.relay;
        expect(matchService('$_key@$relay', rules), isNotNull, reason: relay);
        expect(matchService('$_key@${relay.toUpperCase()}:443', rules), isNotNull, reason: relay);
        for (final near in ['$relay.evil.invalid', 'x$relay', 'x.$relay', '${relay}x', relay.substring(1)]) {
          expect(matchService('$_key@$near', rules), isNull, reason: near);
        }
      }
    }
  });

  test('only the service files name a service', () {
    final names = <String>{};
    for (final file in _bundled()) {
      final parsed = parseServiceFile(file.readAsStringSync());
      names
        ..add(parsed.id)
        ..addAll(parsed.rules.map((r) => r.relay));
    }
    const types = ['.dart', '.arb', '.toml', '.yaml', '.json'];
    final places = [Directory('lib'), Directory('test'), Directory('tool'), Directory('assets/config')];
    final files = [File('pubspec.yaml'), for (final dir in places) ...dir.listSync(recursive: true).whereType<File>()];
    for (final file in files.where((f) => types.any(f.path.endsWith))) {
      final text = file.readAsStringSync().toLowerCase();
      for (final name in names) {
        expect(text.contains(name), isFalse, reason: '${file.path} names a service');
      }
    }
  });

  group('with no service file at all', () {
    const deposit = 'epic:$_key@box.epic.invalid?message=4827193065148&require=message&min=0.1&label=Deposit';
    AddressVerdict check(Recipient to) => AddressVerdict.valid;
    final l = lookupAppLocalizations(const Locale('en'));

    test('the app starts with no rules', () async {
      serviceRules = await loadServices([BundledServices(_NoServices())]);
      addTearDown(() => serviceRules = ServiceRules.none);
      expect(matchService('$_key@box.epic.invalid', serviceRules), isNull);
    });

    test('a start with a broken bundle starts with no rules', () async {
      await startServices(bundle: _BrokenBundle());
      expect(matchService('$_key@box.epic.invalid', serviceRules), isNull);
      serviceRules = ServiceRules.none;
    });

    test('a deposit code scans whole', () {
      final code = classifyScan(deposit, check: check) as PaymentRequest;
      expect(code.recipient.address, '$_key@box.epic.invalid');
      expect(code.note, '4827193065148');
      expect(code.noteRequired, isTrue);
      expect(code.minimum, BigInt.from(10000000));
      expect(code.label, 'Deposit');
      expect(code.problems, isEmpty);
    });

    test("the code's own warning stands; a plain address gets none", () {
      expect(noteWarning(l, '$_key@box.epic.invalid', '', codeAsks: true), l.sendNoteMissingCode);
      expect(noteWarning(l, '$_key@box.epic.invalid', '', codeAsks: false), isNull);
    });
  });
}

final class _BrokenBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => throw const FormatException('no asset');
}
