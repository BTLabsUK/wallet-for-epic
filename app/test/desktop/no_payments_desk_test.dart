// SPDX-License-Identifier: Apache-2.0
// A contact that takes no payments, on the desktop: its details show one line in place of Send,
// and Send stops at its address, typed or chosen, with Review off.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/directory/payment_refusals.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/models.dart' show epicboxKey;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

const _box = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@box.epic.invalid';

class _Refuses implements PaymentRefusals {
  @override
  bool refusesPayments({String? pairingId, String? address}) => address != null && epicboxKey(address) == epicboxKey(_box);
}

Future<ProviderContainer> _container(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)),
      paymentRefusalsProvider.overrideWithValue(_Refuses()),
    ],
    retry: (_, _) => null,
  );
  addTearDown(container.dispose);
  await tester.runAsync(() async {
    final n = container.read(deskProvider.notifier);
    await n.refresh();
    await n.saveSettings(container.read(deskProvider).settings.copyWith(tourSeen: true));
    await n.saveContact(Contact(id: '', name: 'BT Labs', epicbox: _box));
  });
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets('the contact details show the line in place of Send; others keep Send', (tester) async {
    final container = await _container(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ContactsScreen()),
        ),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('Anna Kowalska').first);
    await _settle(tester);
    expect(find.byKey(const ValueKey('contact-send')), findsOneWidget);
    expect(find.byKey(const ValueKey('contact-no-payments')), findsNothing);
    await tester.tap(find.text('BT Labs').first);
    await _settle(tester);
    expect(find.byKey(const ValueKey('contact-send')), findsNothing);
    expect(find.byKey(const ValueKey('contact-no-payments')), findsOneWidget);
    expect(find.text(_l.contactTakesNoPayments), findsOneWidget);
  });

  testWidgets('Send stops at the address typed or pasted: the error shows', (tester) async {
    final container = await _container(tester);
    container.read(deskNavProvider.notifier).reset(DeskRoute.send, null);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
    await _settle(tester);
    await tester.enterText(find.byType(EditableText).first, _box);
    await _settle(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await _settle(tester);
    expect(find.text(_l.sendContactTakesNoPayments), findsOneWidget);
  });
}
