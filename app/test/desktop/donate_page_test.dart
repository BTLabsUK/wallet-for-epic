// SPDX-License-Identifier: Apache-2.0
// Settings › Donate (item 4): the address with Copy and QR, and BT Labs' contact, opened in
// Contacts, only while Contacts hold it. Opening the page asks nothing on the network and
// shows no notice.
import 'dart:io';

import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_donate.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart' show ContactsArgs;
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart' show ENotice;
import 'package:epic_wallet/src/donate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts every HttpClient the app makes: none may be made while Donate is open.
class _CountClients extends HttpOverrides {
  int made = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    made++;
    return super.createHttpClient(context);
  }
}

void main() {
  Future<(ProviderContainer, _CountClients)> pump(WidgetTester tester, {bool deleteBtLabs = false}) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    if (deleteBtLabs) {
      final address = container.read(donateLinkProvider).address;
      final c = donateContactIn(container.read(deskProvider).contacts!, address, (c) => c.epicbox)!;
      await tester.runAsync(() => container.read(deskProvider.notifier).deleteContact(c.id));
    }
    final net = _CountClients();
    final before = HttpOverrides.current;
    HttpOverrides.global = net;
    addTearDown(() => HttpOverrides.global = before);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: SettingsDonateScreen())),
    ));
    await tester.pumpAndSettle();
    return (container, net);
  }

  testWidgets("the address and BT Labs' contact; Open shows it in Contacts; nothing asked, no notice", (tester) async {
    final (container, net) = await pump(tester);
    expect(find.text('Donations fund development of this wallet.'), findsOneWidget);
    expect(find.text('Epic Cash address'), findsOneWidget);
    expect(find.byKey(const ValueKey('donate-address')), findsOneWidget);
    expect(find.byType(ENotice), findsNothing);
    expect(find.text('BT Labs'), findsOneWidget);
    expect(find.text('In your contacts'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('donate-contact')));
    await tester.pumpAndSettle();
    final at = container.read(deskNavProvider);
    expect(at.route, DeskRoute.contacts);
    final id = donateContactIn(container.read(deskProvider).contacts!, container.read(donateLinkProvider).address, (c) => c.epicbox)!.id;
    expect((at.arg as ContactsArgs?)?.selectedId, id);
    expect(net.made, 0);
  });

  testWidgets("BT Labs' contact deleted: the address alone, no link", (tester) async {
    final (_, net) = await pump(tester, deleteBtLabs: true);
    expect(find.byKey(const ValueKey('donate-address')), findsOneWidget);
    expect(find.byKey(const ValueKey('donate-contact')), findsNothing);
    expect(find.text('In your contacts'), findsNothing);
    expect(find.byType(ENotice), findsNothing);
    expect(net.made, 0);
  });
}
