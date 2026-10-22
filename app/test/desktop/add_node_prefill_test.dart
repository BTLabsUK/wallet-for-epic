// Settings › Node: "Add to my nodes" with an address typed in the picker's field opens the
// dialog on that address (scheme added as a pick would), with the label field focused; Cancel
// puts the typed text back in the field. Nothing typed: the dialog opens empty as before.
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/dialogs.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_node.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  final search = find.descendant(
    of: find.byWidgetPredicate((w) => w is EInput && w.semanticLabel == 'Find or type a node address'),
    matching: find.byType(EditableText),
  );

  setUp(() {
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)), deskNodeProvider.overrideWithValue(MockDeskNode())]);
  });

  tearDown(() => container.dispose());

  /// Settings › Node with the picker open.
  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: SettingsNodeScreen(arg: NodeDemo.comboOpen))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> end(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 31));
  }


  Finder field(String label) => find.descendant(of: find.widgetWithText(EField, label), matching: find.byType(EditableText)).first;

  Future<void> type(WidgetTester tester, String t) async {
    await tester.enterText(search, t);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('the typed row\'s star prefills the dialog, focuses the label, and Cancel keeps the text', (tester) async {
    await show(tester);
    await type(tester, 'node.example.org:3413');
    await tester.tap(find.bySemanticsLabel('Add to my nodes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MyNodeDialog), findsOneWidget);
    expect(tester.widget<EditableText>(field('Node address')).controller.text, 'https://node.example.org:3413');
    expect(tester.widget<EditableText>(field('Label')).focusNode.hasFocus, isTrue, reason: 'the label is next');
    await tester.tap(find.widgetWithText(EButton, 'Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MyNodeDialog), findsNothing);
    expect(tester.widget<EditableText>(search).controller.text, 'node.example.org:3413', reason: 'the typed text stays');
    await end(tester);
  });

  testWidgets('the footer item prefills a LAN address with http, and an empty field opens the dialog empty', (tester) async {
    await show(tester);
    await type(tester, '10.0.1.24:3413');
    await tester.tap(find.text('Add to my nodes…'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MyNodeDialog), findsOneWidget);
    expect(tester.widget<EditableText>(field('Node address')).controller.text, 'http://10.0.1.24:3413');
    expect(tester.widget<EditableText>(field('Label')).focusNode.hasFocus, isTrue);
    await tester.tap(find.widgetWithText(EButton, 'Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<EditableText>(search).controller.text, '10.0.1.24:3413');

    await tester.enterText(search, '');
    await tester.pump();
    // The whole list shows again; the footer is below its fold.
    await tester.scrollUntilVisible(find.text('Add to my nodes…'), 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Add to my nodes…'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MyNodeDialog), findsOneWidget);
    expect(tester.widget<EditableText>(field('Node address')).controller.text, isEmpty);
    expect(tester.widget<EditableText>(field('Node address')).focusNode.hasFocus, isTrue, reason: 'empty: the address is first, as before');
    await tester.tap(find.widgetWithText(EButton, 'Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await end(tester);
  });
}
