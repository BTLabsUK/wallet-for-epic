// linux-09: a long emoji message. LEPIC signs at most 256 UTF-8 bytes of a message and cuts the
// rest, but Send counted characters ("368 / 256" with no error) and Review took it; and the
// Check and send dialog grew past the window, so Send was off the screen.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))]);
  });

  tearDown(() => container.dispose());

  // The tester's window.
  Future<void> pump(WidgetTester tester, SendArgs args) async {
    tester.view.physicalSize = const Size(1280, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: SendScreen(arg: args))),
      ),
    );
    await tester.pumpAndSettle();
  }

  const anna = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';
  final message = find.descendant(of: find.widgetWithText(EField, 'Message'), matching: find.byType(TextField));

  testWidgets('the counter is in bytes and typing stops at 256', (tester) async {
    await pump(tester, const SendArgs(recipient: anna, amount: '25'));
    await tester.enterText(message, '😀' * 100);
    await tester.pump();
    // 64 emoji of 4 bytes each fill the 256.
    expect(tester.widget<TextField>(message).controller!.text, '😀' * 64);
    expect(find.text('256 / 256 bytes'), findsOneWidget);
  });

  testWidgets('a message over 256 bytes is marked and Review refuses it', (tester) async {
    await pump(tester, SendArgs(recipient: anna, amount: '25', message: '😀' * 92));
    expect(find.text('368 / 256 bytes'), findsOneWidget);
    expect(find.text('The message is longer than 256 bytes. Shorten it.'), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, 'Review'));
    await tester.pumpAndSettle();
    expect(find.text('Check and send'), findsNothing);
  });

  testWidgets('Check and send keeps Send on the screen with the tallest message', (tester) async {
    // 128 short lines: within the 256 bytes, and taller than any window.
    await pump(tester, SendArgs(recipient: anna, amount: '25', message: '${'a\n' * 127}a', step: SendStep.review));
    expect(find.text('Check and send'), findsOneWidget);
    final send = find.byWidgetPredicate((w) => w is EButton && w.label.startsWith('Send 25'));
    final rect = tester.getRect(send);
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(820));
  });
}
