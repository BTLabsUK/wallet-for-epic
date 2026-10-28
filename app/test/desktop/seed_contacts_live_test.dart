// SPDX-License-Identifier: Apache-2.0
// Live: the bundled BT Labs address passes the real LEPIC checksum and is on the default
// Epicbox server. Needs the Linux library:
//
//   WFE_DEMO_LEPIC_LIB=$PWD/third_party/lepic-flutter/native/x86_64-unknown-linux-gnu/liblepic_ffi.so \
//   flutter test test/desktop/seed_contacts_live_test.dart
//
// Without it it is skipped.
import 'dart:io';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart' show defaultEpicboxHost;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/seed_contacts.dart';
import 'package:flutter_test/flutter_test.dart';

final String? _lib = Platform.environment['WFE_DEMO_LEPIC_LIB'];

void main() {
  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
  });

  test('the BT Labs address passes the checksum; a changed character does not', () {
    final service = LepicWalletService(secrets: MemorySecretStore());
    expect(service.validateEpicboxAddress(address: btLabsContact.address), isTrue);
    expect(btLabsContact.address.split('@').last, defaultEpicboxHost);
    final broken = btLabsContact.address.replaceFirst('Wxbo', 'Wxbp');
    expect(service.validateEpicboxAddress(address: broken), isFalse);
  }, skip: _lib == null ? 'needs WFE_DEMO_LEPIC_LIB' : false);
}
