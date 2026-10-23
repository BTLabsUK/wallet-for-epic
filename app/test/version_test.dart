// The app's version has one source, pubspec.yaml (https://docs.btlabs.uk/developers/releases/); tools/version.sh check
// covers the build scripts, this covers the Dart side.
import 'dart:io';

import 'package:epic_wallet/src/app_version.dart';
import 'package:epic_wallet/src/desktop/data/desk_update.dart' show deskAppVersion;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final line = RegExp(r'^version: *(\S+)\+(\d+)$', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync())!;
  final name = line[1]!, code = int.parse(line[2]!);

  test('appVersion is pubspec.yaml\'s version (tools/version.sh set)', () {
    expect(appVersion, name);
    expect(deskAppVersion, name);
  });

  test('the build number is derived: YY*1000000 + MM*10000 + patch*100 + rebuild', () {
    final m = RegExp(r'^(\d{2})\.(\d{1,2})\.(\d{1,2})(-rc[1-9]\d*)?$').firstMatch(name);
    expect(m, isNotNull, reason: '$name is not YY.MM.patch[-rcN]');
    final mm = int.parse(m![2]!);
    expect(mm, inInclusiveRange(1, 12));
    final derived = int.parse(m[1]!) * 1000000 + mm * 10000 + int.parse(m[3]!) * 100;
    expect(code - derived, inInclusiveRange(0, 99), reason: '$name+$code: the build number must be $derived plus a rebuild');
  });

  test('the core version is SemVer, and LEPIC\'s when the clone is here', () {
    expect(coreVersion, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    final toml = File('third_party/lepic/Cargo.toml');
    if (!toml.existsSync()) return;
    final section = toml.readAsStringSync().split('[workspace.package]').elementAtOrNull(1);
    final v = section == null ? null : RegExp(r'^version *= *"([^"]+)"', multiLine: true).firstMatch(section)?[1];
    if (v != null) expect(coreVersion, v, reason: 'tools/version.sh core');
  });

  test('About shows both: 26.10.0 · core 0.1.0', () {
    expect(withCoreVersion('26.10.0'), '26.10.0 · core $coreVersion');
    expect(isTestVersion('26.10.0-rc1'), isTrue);
    expect(isTestVersion('26.10.0'), isFalse);
  });
}
