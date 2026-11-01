// SPDX-License-Identifier: Apache-2.0
// The desktop's first unlock after the update that encrypts the wallet records: the copy step in
// Unlock's stage list (with the count for a large wallet), the wrong-key message in the password's
// error slot, the fallback notice on Overview, and a closed address book on Contacts.
import 'dart:async';

import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/models.dart' show StoreMigrationProgress;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final containers = <ProviderContainer>[];

  Future<void> pump(WidgetTester tester, MockDeskWallet api, {DeskRoute start = DeskRoute.unlock}) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [deskApiProvider.overrideWithValue(api), deskStartProvider.overrideWithValue(start)],
    );
    containers.add(container);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  }

  Future<void> run(WidgetTester tester, [int frames = 100]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    for (final c in containers) {
      c.dispose();
    }
    containers.clear();
    await tester.pump(const Duration(minutes: 5));
  }

  Future<void> typeAndUnlock(WidgetTester tester) async {
    await run(tester);
    await tester.enterText(find.byType(EditableText).first, 'secret-pass');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await run(tester);
  }

  testWidgets('a large wallet shows the copy step and its count, then Overview without a notice', (tester) async {
    final gate = Completer<void>();
    final api = MockDeskWallet()
      ..migrationSteps = const [StoreMigrationProgress(done: 4200, total: 10000), StoreMigrationProgress(done: 10000, total: 10000)]
      ..migrationGate = gate;
    await pump(tester, api);
    await typeAndUnlock(tester);
    expect(find.text('Encrypting wallet records…'), findsOneWidget);
    expect(find.text('4,200 of 10,000 records'), findsOneWidget);
    expect(find.text('Unlocking the wallet'), findsOneWidget, reason: 'still to come');
    gate.complete();
    await run(tester);
    expect(find.text('Encrypting wallet records…'), findsNothing);
    expect(find.byKey(const ValueKey('overview-records-plain')), findsNothing);
    await done(tester);
  });

  testWidgets('the wrong key is said under the password; Unlock stays', (tester) async {
    final api = MockDeskWallet()..wrongKey = true;
    await pump(tester, api);
    await typeAndUnlock(tester);
    await run(tester);
    expect(find.text("This wallet's records could not be opened with this phrase. Nothing was changed."), findsOneWidget);
    expect(find.text('Unlock wallet'), findsOneWidget);
    await done(tester);
  });

  testWidgets('a session on the plain records says so on Overview', (tester) async {
    final api = MockDeskWallet()..recordsPlain = true;
    await pump(tester, api);
    await typeAndUnlock(tester);
    await run(tester);
    expect(find.byKey(const ValueKey('overview-records-plain')), findsOneWidget);
    expect(find.text('Wallet records stay unencrypted for now. The app tries again next time.'), findsOneWidget);
    await done(tester);
  });

  testWidgets('a closed address book is shown closed on Contacts, not empty', (tester) async {
    final api = MockDeskWallet()..contactsClosed = true;
    await pump(tester, api);
    await typeAndUnlock(tester);
    await run(tester);
    final container = containers.last;
    container.read(deskNavProvider.notifier).go(DeskRoute.contacts);
    await run(tester);
    expect(find.byKey(const ValueKey('contacts-closed')), findsOneWidget);
    expect(find.text('Address book closed'), findsOneWidget);
    await done(tester);
  });
}
