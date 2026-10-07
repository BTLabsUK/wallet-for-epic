import 'package:epic_wallet/src/ui/phone_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [PhoneFrame] in a window of [window] logical pixels and returns the size its child
/// sees through `MediaQuery`.
Future<Size> _childSize(
  WidgetTester tester,
  Size window, {
  bool enabled = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = window;
  addTearDown(tester.view.reset);
  late Size seen;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => PhoneFrame(enabled: enabled, child: child!),
      home: Builder(
        builder: (context) {
          seen = MediaQuery.sizeOf(context);
          return const Scaffold(body: Text('screen'));
        },
      ),
    ),
  );
  return seen;
}

void main() {
  testWidgets('a desktop window shows the app as a phone in the middle', (
    tester,
  ) async {
    final seen = await _childSize(tester, const Size(1440, 1000));
    expect(seen, phoneFrameSize);
    final frame = tester.getRect(find.byKey(const ValueKey('phone-frame')));
    expect(frame.size, phoneFrameSize);
    expect(frame.center, const Offset(720, 500));
    // The screen's own widgets stay inside the frame.
    expect(frame.contains(tester.getCenter(find.text('screen'))), isTrue);
  });

  testWidgets('a laptop window keeps a margin and shortens the phone', (
    tester,
  ) async {
    final seen = await _childSize(tester, const Size(1280, 720));
    expect(seen, Size(phoneFrameSize.width, 720 - 2 * phoneFrameMargin));
  });

  testWidgets('a very short window gives the phone its full height', (
    tester,
  ) async {
    final seen = await _childSize(tester, const Size(1280, 580));
    expect(seen, Size(phoneFrameSize.width, 580));
  });

  testWidgets('a phone-wide window gets the whole screen', (tester) async {
    final seen = await _childSize(tester, const Size(412, 915));
    expect(seen, const Size(412, 915));
    expect(find.byKey(const ValueKey('phone-frame')), findsNothing);
  });

  testWidgets('native builds never frame the app', (tester) async {
    final seen = await _childSize(
      tester,
      const Size(1440, 1000),
      enabled: false,
    );
    expect(seen, const Size(1440, 1000));
    expect(find.byKey(const ValueKey('phone-frame')), findsNothing);
  });

  testWidgets('a dialog opens inside the phone', (tester) async {
    await _childSize(tester, const Size(1440, 1000));
    final context = tester.element(find.text('screen'));
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(content: Text('dialog')),
    );
    await tester.pumpAndSettle();
    final frame = tester.getRect(find.byKey(const ValueKey('phone-frame')));
    final dialog = tester.getRect(find.byType(AlertDialog));
    expect(
      frame.contains(dialog.topLeft) && frame.contains(dialog.bottomRight),
      isTrue,
    );
  });
}
