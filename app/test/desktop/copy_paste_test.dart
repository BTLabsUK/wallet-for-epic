// SPDX-License-Identifier: Apache-2.0
// Copy and paste on the desktop: every copy control sets the clipboard and says "Copied",
// Receive has one copy control for its address, and text fields paste with Ctrl+V and from the
// right-click menu (password fields: paste only).
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/create_screen.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/receive_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;

final _l = englishStrings;

/// The platform clipboard, as a map the test reads.
String? _clip;

void _fakeClipboard(WidgetTester tester) {
  _clip = null;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    switch (call.method) {
      case 'Clipboard.setData':
        _clip = (call.arguments as Map)['text'] as String?;
        return null;
      case 'Clipboard.getData':
        return _clip == null ? null : {'text': _clip};
      case 'Clipboard.hasStrings':
        return {'value': _clip?.isNotEmpty ?? false};
    }
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: child)),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  phraseCopyOnboarding();
  testWidgets('Receive: one copy icon in the address box; it copies and says so', (tester) async {
    _fakeClipboard(tester);
    await _pump(tester, const ReceiveScreen());
    final panel = find.byKey(const ValueKey('rx-panel-epicbox'));
    final copy = find.descendant(of: panel, matching: find.byType(ECopyButton));
    expect(copy, findsOneWidget);
    expect(find.descendant(of: find.byType(EAddress).first, matching: find.byType(ECopyButton)), findsOneWidget);
    await tester.tap(copy);
    await tester.pump();
    expect(_clip, isNotNull);
    expect(_clip, contains('@'));
    final copied = find.byWidgetPredicate((w) => w is EIconButton && w.label == 'Copied');
    expect(copied, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(copied, findsNothing);
  });

  testWidgets('a refused copy says "Not copied"', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') throw PlatformException(code: 'Clipboard error');
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await _pump(tester, const ECopyButton(text: 'x', label: 'Copy id', withLabel: true));
    await tester.tap(find.text('Copy id'));
    // One retry after 150 ms, then the refusal shows.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(_l.deskKitNotCopied), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
  });

  testWidgets('text fields paste with Ctrl+V and from the right-click menu', (tester) async {
    _fakeClipboard(tester);
    final ctl = TextEditingController();
    addTearDown(ctl.dispose);
    await _pump(tester, Center(child: SizedBox(width: 400, child: EInput(controller: ctl, mono: true))));
    _clip = 'esA@epicbox.epiccash.com';
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(ctl.text, 'esA@epicbox.epiccash.com');
    ctl.clear();
    _clip = 'http://203.0.113.5:3415';
    await tester.tap(find.byType(EditableText), buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();
    expect(ctl.text, 'http://203.0.113.5:3415');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('a password field offers paste but never copy or cut', (tester) async {
    _fakeClipboard(tester);
    final ctl = TextEditingController(text: 'secret-pass');
    addTearDown(ctl.dispose);
    await _pump(tester, Center(child: SizedBox(width: 400, child: EPasswordInput(controller: ctl))));
    _clip = 'pasted';
    await tester.tap(find.byType(EditableText), buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    expect(find.text('Paste'), findsOneWidget);
    expect(find.text('Copy'), findsNothing);
    expect(find.text('Cut'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}

/// The phrase copy on Create confirms on the first-run screens too (they have no shell).
void phraseCopyOnboarding() {
  testWidgets('Create: copying the phrase shows "Phrase copied"', (tester) async {
    _fakeClipboard(tester);
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(deskNavProvider.notifier).reset(DeskRoute.create, CreateStep.phrase);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(seconds: 1));
    // The words are hidden until Reveal; Copy shows with them.
    expect(find.text('Copy'), findsNothing);
    await tester.tap(find.text(_l.deskOnbCreateReveal));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(_l.commonCopy));
    await tester.pump(const Duration(milliseconds: 300));
    // The warning comes first; nothing is copied until it is confirmed.
    expect(find.text(_l.deskSetPhraseCopyTitle), findsOneWidget);
    expect(find.text('Anyone with these words can take the coins. Store the copy somewhere safe.'), findsOneWidget);
    expect(_clip, isNull);
    await tester.tap(find.descendant(of: find.byType(EDialog), matching: find.text('Cancel')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Copy the recovery phrase?'), findsNothing);
    expect(_clip, isNull);
    expect(find.text('Phrase copied'), findsNothing);
    await tester.tap(find.text('Copy'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.descendant(of: find.byType(EDialog), matching: find.text('Copy')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_clip, isNotNull);
    expect(find.text('Phrase copied'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Cleared after 60 s, not at 31.
    await tester.pump(const Duration(seconds: 31));
    expect(_clip, isNotEmpty);
    await tester.pump(const Duration(seconds: 30));
    expect(_clip, '');
  });
}
