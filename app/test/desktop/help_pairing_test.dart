// Help › Pairing: the section with its six topics, before trouble, the deep link and search.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/help_pairing.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_help.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/help/help_content.dart' show HelpPlatform, pairingHelpTopics;
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/experimental.dart';

Future<void> _pump(WidgetTester tester, {Object? arg, double width = 1280}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))]);
  addTearDown(container.dispose);
  await tester.runAsync(() async {
    await container.read(deskProvider.notifier).refresh();
    await deskExperimentalOn(container);
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: SettingsHelpScreen(key: ValueKey(arg), arg: arg))),
    ),
  );
  await tester.pumpAndSettle();
}

const _topics = ['What pairing is', 'Three ways to pair', 'Why verify', 'Spoken invites', 'Invoices from paired contacts', 'What a restore does'];

void main() {
  testWidgets('the pairing section shows its six topics, before trouble', (tester) async {
    await _pump(tester);
    expect(find.text('Pairing'), findsWidgets);
    expect(find.byType(PairingHelpMark), findsOneWidget);
    for (final t in _topics) {
      expect(find.text(t, findRichText: true), findsOneWidget, reason: t);
    }
    final last = tester.getTopLeft(find.text('What a restore does', findRichText: true)).dy;
    final trouble = tester.getTopLeft(find.text('When something goes wrong').last).dy;
    expect(last, lessThan(trouble));
    expect(find.text('Why a separate invoice address', findRichText: true), findsNothing);
  });

  testWidgets('HelpAt opens the first pairing topic', (tester) async {
    await _pump(tester, arg: const HelpAt('pairing'));
    expect(find.textContaining('Pairing links two wallets once', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('900 px wide: the section lays out without an exception', (tester) async {
    await _pump(tester, arg: const HelpAt('pairing', topic: 4), width: 900);
    expect(find.textContaining('Allow invoices', findRichText: true), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('the desktop pays with the wallet password: no PIN in its pairing topics, the phone keeps it', () {
    String all(HelpPlatform p) => [
      for (final topic in pairingHelpTopics(englishStrings, platform: p)) ...[topic.title, topic.short, for (final b in topic.body) b.text],
    ].join(' ');
    expect(all(HelpPlatform.desktop), isNot(contains('PIN')));
    expect(englishStrings.helpPairInvShortDesktop, contains('wallet password'));
    expect(all(HelpPlatform.phone), contains('PIN'));
  });

  test('search finds the pairing topics', () {
    final hits = searchTopics(pairingHelpTopics(englishStrings), queryWords('spoken invites'));
    expect(hits.first.topic.title, 'Spoken invites');
  });
}
