// SPDX-License-Identifier: Apache-2.0
// Release builds are signed with the release key only (android/app/build.gradle.kts). The
// behaviour itself is checked by tool/android_signing_check.sh, which runs Gradle; this keeps the
// gate from passing a build file that falls back to the debug key.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();
  // Comments may name the debug key; only code counts.
  final code = gradle
      .split('\n')
      .where((l) => !l.trimLeft().startsWith('//'))
      .join('\n');

  test('the release build type is signed with the release config', () {
    final release = RegExp(r'buildTypes\s*\{\s*release\s*\{([^}]*)\}').firstMatch(code);
    expect(release, isNotNull, reason: 'no release build type');
    expect(release!.group(1), contains('signingConfigs.getByName("release")'));
  });

  test('nothing signs with the debug config', () {
    expect(code, isNot(contains('getByName("debug")')));
    expect(code, isNot(contains('signingConfigs.debug')));
  });

  test('a release build stops without a usable release key', () {
    expect(code, contains('val checkReleaseSigning by tasks.registering'));
    expect(code, contains('throw GradleException('));
    expect(
      code,
      contains('tasks.matching { it.name == "preReleaseBuild" }'
          '.configureEach { dependsOn(checkReleaseSigning) }'),
    );
  });

  test('the key is read from outside the repository', () {
    expect(code, contains('WFE_ANDROID_KEY_PROPERTIES'));
    expect(code, contains('.config/btlabs/android/key.properties'));
    expect(code, contains('the keystore is inside the repository'));
  });
}
