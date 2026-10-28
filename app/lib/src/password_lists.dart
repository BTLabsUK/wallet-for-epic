// SPDX-License-Identifier: Apache-2.0
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'password_estimate.dart';
import 'password_gunzip.dart';

/// The word lists in assets/passwords: common passwords and diceware, then the app's
/// languages. All are loaded: a German speaker can still pick an English word.
const List<String> passwordListAssets = [
  'assets/passwords/common.txt.gz',
  'assets/passwords/en.txt.gz',
  'assets/passwords/de.txt.gz',
  'assets/passwords/pl.txt.gz',
  'assets/passwords/ru.txt.gz',
  'assets/passwords/zh.txt.gz',
];

/// Loads the lists and ranks them in a background isolate, off the UI thread. When a list
/// cannot be read the estimate still runs, on the lists that loaded or on patterns alone.
Future<PasswordEstimator> loadPasswordEstimator({AssetBundle? bundle}) async {
  final files = <Uint8List>[];
  for (final asset in passwordListAssets) {
    try {
      final data = await (bundle ?? rootBundle).load(asset);
      files.add(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } catch (_) {}
  }
  try {
    return await Isolate.run(() => PasswordEstimator({for (final f in files) ...parseWordLists(utf8.decode(gunzip(f)))}));
  } catch (_) {
    return PasswordEstimator(const {});
  }
}

/// Adds the word lists' notices to [LicenseRegistry], next to the packages'.
void registerPasswordListLicences() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['zxcvbn-ts word lists'], await rootBundle.loadString('assets/passwords/NOTICE.txt'));
  });
}
