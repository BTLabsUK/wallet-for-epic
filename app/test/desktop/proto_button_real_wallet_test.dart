// SPDX-License-Identifier: Apache-2.0
// The shell's Stack holds the page and the Demo button. With a real wallet the button shows nothing,
// and it must not size the Stack to nothing: the page keeps the window (a build shipped with every
// page body blank because the button was a plain Stack child).
import 'package:epic_wallet/src/desktop/data/api.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/invoices/proto_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Real extends Fake implements DeskWalletApi {}

void main() {
  Future<Size> pageSize(WidgetTester tester, DeskWalletApi api) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [deskApiProvider.overrideWithValue(api)],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            // Loose constraints, as the shell's Stack gets them under the title bar.
            child: Stack(children: [Positioned.fill(child: SizedBox(key: key)), const ProtoButton()]),
          ),
        ),
      ),
    );
    return tester.getSize(find.byKey(key));
  }

  testWidgets('a real wallet: the Demo button leaves the page its size', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final real = await pageSize(tester, _Real());
    // A Stack of positioned children only is as big as its parent allows; a stray plain child of
    // size zero would make it 0 x 0.
    expect(real, isNot(Size.zero));
  });
}
