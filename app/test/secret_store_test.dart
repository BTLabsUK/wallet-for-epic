import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // PlatformSecretStore sets a macOS keychain accessibility level. Entries written before at
  // the default level stay readable only with flutter_secure_storage_darwin 0.4.3 or later,
  // which looks items up across every level.
  test(
    'the darwin keychain plugin finds items across accessibility levels',
    () {
      final lock = File('pubspec.lock').readAsStringSync();
      final match = RegExp(
        r'flutter_secure_storage_darwin:\n(?:    .*\n)*?    version: "(\d+)\.(\d+)\.(\d+)"',
      ).firstMatch(lock);
      expect(
        match,
        isNotNull,
        reason: 'flutter_secure_storage_darwin is locked',
      );
      final version = [
        for (var i = 1; i <= 3; i++) int.parse(match!.group(i)!),
      ];
      final atLeast =
          version[0] > 0 ||
          version[1] > 4 ||
          (version[1] == 4 && version[2] >= 3);
      expect(
        atLeast,
        isTrue,
        reason: 'locked ${version.join('.')}, needs 0.4.3+',
      );
    },
  );
}
