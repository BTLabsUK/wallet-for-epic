// SPDX-License-Identifier: Apache-2.0
// The Peers tab: 14 fakes render 8 and "6 more"; Ban moves a row; a changed
// maximum shows the restart notice; First seen is the app's first poll, not anything from the
// node; the version column; ip:port validation.
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/node_view.dart' show hhmm;
import 'package:epic_wallet/src/desktop/screens/settings/local_node_peers.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockDeskNode node;
  late ProviderContainer container;

  setUp(() {
    node = MockDeskNode(state: mockLocalNode(LocalNodePhase.synced));
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)), deskNodeProvider.overrideWithValue(node)]);
  });

  tearDown(() => container.dispose());

  Future<void> show(WidgetTester tester, {bool restartNeeded = false, double width = 1280}) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(24), child: PeersTab(restartNeeded: restartNeeded, onRestart: () {})))),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> end(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  Finder rows() => find.byWidgetPredicate((w) => w is Text && w.data != null && RegExp(r'^\d+\.\d+\.\d+\.\d+:3414$').hasMatch(w.data!));

  testWidgets('14 peers: the summary, 8 rows and "6 more"; the fold shows the rest', (tester) async {
    await show(tester);
    expect(find.text('14 connected · 10 in · 4 out · 1 banned'), findsOneWidget);
    expect(find.text('6 more'), findsOneWidget);
    expect(rows().evaluate().where((e) => tester.getSize(find.byWidget(e.widget)).height > 0).length, lessThanOrEqualTo(9), reason: '8 connected + 1 banned visible');
    await tester.tap(find.text('6 more'));
    await tester.pumpAndSettle();
    expect(find.text('6 more'), findsNothing);
    expect(rows(), findsNWidgets(15), reason: '14 connected + 1 banned');
    expect(tester.takeException(), isNull);
    await end(tester);
  });

  testWidgets('columns: direction, the version from the user agent, the height, First seen from the first poll', (tester) async {
    await show(tester);
    final snap = await node.peers().first;
    final first = snap.connected.first;
    expect(find.text(hhmm(first.firstSeen!)), findsWidgets, reason: 'First seen is the app’s first poll time');
    expect(find.text('4.1.1'), findsWidgets);
    expect(find.text('in'), findsWidgets);
    expect(find.text('out'), findsWidgets);
    expect(find.text('3,764,975'), findsWidgets);
    expect(peerVersion('MW/Epic 4.1.1'), '4.1.1');
    expect(peerVersion('something else'), 'something else');
    await end(tester);
  });

  testWidgets('Ban on a hovered row moves it to Banned; Unban brings it back', (tester) async {
    await show(tester);
    final addr = (await node.peers().first).connected.first.peer.addr;
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text(addr)));
    await tester.pump();
    await tester.tap(find.widgetWithText(EButton, 'Ban').first);
    await tester.pump();
    await tester.pump();
    expect(node.calls, contains('ban $addr'));
    expect(find.text('14 connected · 10 in · 4 out · 1 banned'), findsNothing);
    expect(find.textContaining('2 banned'), findsOneWidget);
    expect(find.textContaining('manual ban'), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, 'Unban').last);
    await tester.pump();
    await tester.pump();
    expect(node.calls, contains('unban $addr'));
    expect(find.textContaining('1 banned'), findsOneWidget);
    await end(tester);
  });

  testWidgets('a changed Max incoming saves and the node asks for a restart; bad values are refused', (tester) async {
    await show(tester);
    expect(find.text('Settings changed.'), findsNothing);
    final maxIn = find.descendant(of: find.byWidgetPredicate((w) => w is EInput && w.semanticLabel == 'Max incoming peers'), matching: find.byType(EditableText));
    await tester.enterText(maxIn, '7');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('8 to 500.'), findsOneWidget);
    expect(node.calls.where((c) => c == 'options'), isEmpty);
    await tester.enterText(maxIn, '200');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump();
    expect(node.calls, contains('options'));
    expect((await node.options()).maxInbound, 200);
    expect(node.state.restartNeeded, isTrue, reason: 'the node is not restarted by itself');
    await end(tester);
  });

  testWidgets('Max outgoing also saves when the field loses focus', (tester) async {
    await show(tester);
    final maxOut = find.descendant(of: find.byWidgetPredicate((w) => w is EInput && w.semanticLabel == 'Max outgoing peers'), matching: find.byType(EditableText));
    await tester.enterText(maxOut, '40');
    await tester.pump();
    expect(node.calls.where((c) => c == 'options'), isEmpty);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.pump();
    expect((await node.options()).maxOutbound, 40);
    await end(tester);
  });

  testWidgets('Enter and then the focus loss save a maximum once', (tester) async {
    await show(tester);
    final maxIn = find.descendant(of: find.byWidgetPredicate((w) => w is EInput && w.semanticLabel == 'Max incoming peers'), matching: find.byType(EditableText));
    await tester.enterText(maxIn, '200');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.pump();
    expect(node.calls.where((c) => c == 'options'), hasLength(1));
    await end(tester);
  });

  testWidgets('preferred peers: ip:port only (the node keeps no host names), listed with a count', (tester) async {
    await show(tester);
    final field = find.descendant(of: find.widgetWithText(EInput, 'ip:port'), matching: find.byType(EditableText));
    const refused = 'Not an IP address and port, such as 203.0.113.5:3414.';
    await tester.enterText(field, 'nonsense');
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text(refused), findsOneWidget);
    await tester.enterText(field, 'peer.example.org:3414');
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text(refused), findsOneWidget, reason: 'a host name never reaches the toml');
    expect(node.calls.where((c) => c == 'options'), isEmpty);
    await tester.enterText(field, '95.216.14.77:3414');
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.pump();
    expect(find.text('1 preferred:'), findsOneWidget);
    expect(find.text('95.216.14.77:3414'), findsOneWidget);
    await end(tester);
  });

  testWidgets('the restart notice shows when settings changed', (tester) async {
    await show(tester, restartNeeded: true);
    expect(find.text('Settings changed.'), findsOneWidget);
    expect(find.text('Restart now'), findsNothing, reason: 'Restart is the page header\'s');
    await end(tester);
  });

  testWidgets('under 600 u the table scrolls sideways instead of squeezing', (tester) async {
    await show(tester, width: 560);
    expect(find.byWidgetPredicate((w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal), findsOneWidget);
    expect(tester.takeException(), isNull);
    await end(tester);
  });
}
