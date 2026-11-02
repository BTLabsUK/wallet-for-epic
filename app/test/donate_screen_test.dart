// SPDX-License-Identifier: Apache-2.0
// Settings › Donate on the phone (item 4): the donation page from settings.toml, and when it
// does not answer (or none is set) the address with Copy and QR and the contact page.
import 'package:epic_wallet/src/donate.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/donate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

const _address = 'esZb3vExampleDonationAddressq8Kx@epicbox.example.org';

Future<List<String>> _pump(WidgetTester tester, DonateLink link, {DonateCheck check = DonateCheck.noAnswer}) async {
  final copied = <String>[];
  // Tall enough that the whole page, the QR open, is built.
  tester.view.physicalSize = const Size(1080, 4800);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        donateLinkProvider.overrideWithValue(link),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DonateScreen(check: (_) async => check),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return copied;
}

void main() {
  testWidgets('a page that does not answer: the notice, the address with Copy and QR, the contact page', (tester) async {
    final copied = await _pump(
      tester,
      DonateLink(page: Uri.parse('https://donate.example.org/'), address: _address, contact: Uri.parse('https://example.org/contact')),
    );
    expect(find.text(_l.settingsDonate), findsOneWidget);
    expect(find.text(_l.donateLead), findsOneWidget);
    expect(find.byKey(donatePageDownKey), findsOneWidget);
    expect(find.byKey(donatePageKey), findsNothing);
    expect(find.byKey(donateContactKey), findsOneWidget);
    await tester.tap(find.byKey(donateCopyKey));
    await tester.pump();
    expect(copied, [_address]);
    // The QR only when asked.
    expect(find.bySemanticsLabel(_l.donateQrLabel), findsNothing);
    await tester.tap(find.byKey(donateQrKey));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(_l.donateQrLabel), findsOneWidget);
    await tester.tap(find.byKey(donateContactKey));
    await tester.pump();
    expect(copied.last, 'https://example.org/contact');
  });

  testWidgets('a page that answers, or one not asked in Node only: its link, no notice', (tester) async {
    for (final check in [DonateCheck.answers, DonateCheck.skipped]) {
      final copied = await _pump(tester, DonateLink(page: Uri.parse('https://donate.example.org/'), address: _address), check: check);
      expect(find.byKey(donatePageDownKey), findsNothing, reason: '$check');
      await tester.tap(find.byKey(donatePageKey));
      await tester.pump();
      expect(copied, ['https://donate.example.org/'], reason: '$check');
    }
  });

  testWidgets('no page set: the address, no notice', (tester) async {
    await _pump(tester, const DonateLink(address: _address));
    expect(find.byKey(donatePageDownKey), findsNothing);
    expect(find.byKey(donatePageKey), findsNothing);
    expect(find.byKey(donateCopyKey), findsOneWidget);
  });

  testWidgets('nothing set: says so', (tester) async {
    await _pump(tester, const DonateLink());
    expect(find.text(_l.donateNothing), findsOneWidget);
    expect(find.byKey(donateCopyKey), findsNothing);
  });
}
