// SPDX-License-Identifier: Apache-2.0
// Settings › Donate on the phone (item 4): the address with Copy and QR, and BT Labs' contact
// only while Contacts hold it; opening the screen asks nothing on the network.
import 'dart:io';

import 'package:epic_wallet/src/contacts.dart';
import 'package:epic_wallet/src/donate.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/donate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

const _address = 'esZb3vExampleDonationAddressq8Kx@epicbox.example.org';

/// Counts every HttpClient the app makes: none may be made while Donate is open.
class _CountClients extends HttpOverrides {
  int made = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    made++;
    return super.createHttpClient(context);
  }
}

class _Pushes extends NavigatorObserver {
  final List<Route<dynamic>> routes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => routes.add(route);
}

Future<({List<String> copied, _CountClients net, _Pushes nav})> _pump(
  WidgetTester tester,
  DonateLink link, {
  List<Contact> contacts = const [],
  double width = 360,
}) async {
  final copied = <String>[];
  // Phone width; tall enough that the whole page, the QR open, is built.
  tester.view.physicalSize = Size(width * 3, 4800);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final net = _CountClients();
  final before = HttpOverrides.current;
  HttpOverrides.global = net;
  addTearDown(() => HttpOverrides.global = before);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  final book = MemoryContactBook();
  for (final c in contacts) {
    await book.save(c);
  }
  final nav = _Pushes();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        donateLinkProvider.overrideWithValue(link),
        contactBookProvider.overrideWithValue(book),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: [nav],
        home: const DonateScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (copied: copied, net: net, nav: nav);
}

void main() {
  testWidgets('the address with Copy and QR, no notice, nothing asked on the network', (tester) async {
    final r = await _pump(tester, const DonateLink(address: _address));
    expect(find.text(_l.settingsDonate), findsOneWidget);
    expect(find.text(_l.donateLead), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsNothing, reason: 'no notice of any kind');
    expect(r.net.made, 0);
    await tester.tap(find.byKey(donateCopyKey));
    await tester.pump();
    expect(r.copied, [_address]);
    // The QR only when asked.
    expect(find.bySemanticsLabel(_l.donateQrLabel), findsNothing);
    await tester.tap(find.byKey(donateQrKey));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(_l.donateQrLabel), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 dp');
    expect(r.net.made, 0);
  });

  testWidgets("BT Labs' contact in Contacts: its link opens it", (tester) async {
    final r = await _pump(
      tester,
      const DonateLink(address: _address),
      contacts: [
        Contact(id: '', name: 'Someone', epicbox: 'esOther@epicbox.example.org'),
        Contact(id: '', name: 'BT Labs', epicbox: _address),
      ],
    );
    final link = find.byKey(donateContactKey);
    expect(link, findsOneWidget);
    expect(find.descendant(of: link, matching: find.text('BT Labs')), findsOneWidget);
    expect(find.text(_l.donateInContacts), findsOneWidget);
    final pushed = r.nav.routes.length;
    await tester.tap(link);
    await tester.pump();
    expect(r.nav.routes.length, pushed + 1, reason: 'the contact page opens');
    expect(r.net.made, 0);
  });

  testWidgets("BT Labs' contact deleted: the address alone, no link", (tester) async {
    await _pump(tester, const DonateLink(address: _address), contacts: [Contact(id: '', name: 'Someone', epicbox: 'esOther@epicbox.example.org')]);
    expect(find.byKey(donateCopyKey), findsOneWidget);
    expect(find.byKey(donateContactKey), findsNothing);
    expect(find.text(_l.donateInContacts), findsNothing);
  });

  testWidgets('a long address wraps at 360 dp', (tester) async {
    const long = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.a-very-long-relay-name.example.org';
    await _pump(tester, const DonateLink(address: long));
    expect(tester.takeException(), isNull);
    expect(find.byKey(donateCopyKey), findsOneWidget);
  });

  testWidgets('no address: the lead alone, nothing broken', (tester) async {
    await _pump(tester, const DonateLink());
    expect(find.text(_l.donateLead), findsOneWidget);
    expect(find.byKey(donateCopyKey), findsNothing);
    expect(find.byKey(donateContactKey), findsNothing);
  });
}
