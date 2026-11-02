// SPDX-License-Identifier: Apache-2.0
// Settings › Donate (item 4): Open checks the page, then opens it; a page that does not answer
// shows the address with Copy and QR and the contact page; Node only and Kill switch ask
// nothing and show the address.
import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/desktop/data/files.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_donate.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/donate.dart';
import 'package:epic_wallet/src/network_gate.dart' show NetGate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => NetGate.set(null));

  Future<(List<String>, List<DonateLink>)> pump(WidgetTester tester, DonateCheck answer) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opened = <String>[];
    final asked = <DonateLink>[];
    final container = ProviderContainer(overrides: [
      deskOpenUrlProvider.overrideWithValue((url) async {
        opened.add(url);
        return true;
      }),
      donateCheckProvider.overrideWithValue((link) async {
        asked.add(link);
        return answer;
      }),
    ]);
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: SettingsDonateScreen())),
    ));
    await tester.pumpAndSettle();
    return (opened, asked);
  }

  testWidgets('Open asks the page, then opens it in the browser', (tester) async {
    final (opened, asked) = await pump(tester, DonateCheck.answers);
    expect(find.text('Donations fund development of this wallet.'), findsOneWidget);
    expect(find.text('Donation page'), findsOneWidget);
    expect(find.text('donate.lab.invalid'), findsOneWidget, reason: 'the host from settings.toml');
    expect(find.byKey(const ValueKey('donate-fallback')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('donate-open')));
    await tester.pumpAndSettle();
    expect(asked, hasLength(1));
    expect(opened, ['https://donate.lab.invalid/']);
    expect(find.text('Epic Cash address'), findsOneWidget);
  });

  testWidgets('a page that does not answer: the notice, the contact page and the address', (tester) async {
    final (opened, _) = await pump(tester, DonateCheck.noAnswer);
    await tester.tap(find.byKey(const ValueKey('donate-open')));
    await tester.pumpAndSettle();
    expect(opened, isEmpty);
    expect(find.text('The donation page does not answer.'), findsOneWidget);
    expect(find.byKey(const ValueKey('donate-open')), findsNothing);
    expect(find.byKey(const ValueKey('donate-address')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('donate-contact')));
    await tester.pumpAndSettle();
    expect(opened, ['https://contact.lab.invalid/']);
  });

  for (final mode in [NetworkMode.nodeOnly, NetworkMode.killSwitch]) {
    testWidgets('${mode.name}: nothing asked, the address shows, no browser', (tester) async {
      NetGate.set(mode);
      final (opened, asked) = await pump(tester, DonateCheck.answers);
      expect(find.byKey(const ValueKey('donate-open')), findsNothing);
      expect(find.byKey(const ValueKey('donate-contact')), findsNothing);
      expect(find.byKey(const ValueKey('donate-fallback')), findsOneWidget);
      expect(find.byKey(const ValueKey('donate-address')), findsOneWidget);
      expect(asked, isEmpty);
      expect(opened, isEmpty);
    });
  }
}
