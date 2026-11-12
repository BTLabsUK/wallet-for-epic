// SPDX-License-Identifier: Apache-2.0
// The contact page's Pairing sheet, where a settled pairing sits ("…" › Pairing).

import 'package:epic_wallet/src/ui/contact_page.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the contact page's Pairing sheet from its "…" menu. Frames, not settle: the pairing
/// parts run timers.
Future<void> openContactPairing(WidgetTester tester) async {
  Future<void> frames() async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  await tester.tap(find.byKey(contactPageMoreKey));
  await frames();
  await tester.tap(find.byKey(contactPagePairingKey));
  await frames();
}
