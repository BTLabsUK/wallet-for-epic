// Desktop amount fields read amounts in the window's language: "1.000" in German, where the app
// shows a thousand so, is refused as unclear instead of sending 1 EPIC; "1,5" is 1.5.
import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show LocalizedFormatException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final de = lookupAppLocalizations(const Locale('de'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('German: a lone dot before three digits is unclear, a comma is the decimal', () {
    expect(() => parseEpicIn(de, '1.000'), throwsA(isA<LocalizedFormatException>()));
    expect(parseEpicIn(de, '1,5'), 150000000);
    expect(parseEpicIn(de, '1.000,5'), 100050000000);
    expect(parseEpicIn(de, '12.5'), 1250000000);
    expect(parseEpicIn(de, '1,123456789'), epicTooLong);
  });

  test('English reads amounts as before', () {
    expect(parseEpicIn(en, '1.000'), nanoPerEpic);
    expect(parseEpicIn(en, '12.5'), 1250000000);
    expect(parseEpicIn(en, '1,5'), 150000000);
    expect(parseEpicIn(en, ''), isNull);
    expect(parseEpicIn(en, 'abc'), isNull);
    expect(parseEpicIn(en, '0.123456789'), epicTooLong);
  });

  Future<void> pumpSend(WidgetTester tester, String lang, String amount) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))]);
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: Locale(lang),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildDeskTheme(Brightness.dark),
          home: Scaffold(
            body: SendScreen(
              arg: SendArgs(step: SendStep.errors, recipient: 'esXyz1234567890abcdefghijk@epicbox.epiccash.com', amount: amount, epicboxHealth: ServiceHealth.ok),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('German Send asks about 1.000 instead of reading 1', (tester) async {
    await pumpSend(tester, 'de', '1.000');
    expect(find.text(de.sendAmountAmbiguous('1000', '1,000')), findsOneWidget);
  });

  testWidgets('English Send takes 1.000 as one EPIC', (tester) async {
    await pumpSend(tester, 'en', '1.000');
    expect(find.text(en.sendAmountAmbiguous('1000', '1.000')), findsNothing);
    expect(find.text(en.deskSendErrAmountEnter), findsNothing);
  });
}
