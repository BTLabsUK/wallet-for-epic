// SPDX-License-Identifier: Apache-2.0
// The phone's QR scanner starts its camera after the first frame: the start holds auto-lock,
// a provider, which a build must not change (a debug build threw there, and the camera never
// opened).
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the scanner starts its camera after the first frame, without a build error', (tester) async {
    final asked = <String>[];
    // No camera here: the start ends in the scanner's own error view.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/camera'), (call) async {
      asked.add(call.method);
      return call.method == 'availableCameras' ? <Object?>[] : null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/camera'), null));
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ScanScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(asked, contains('availableCameras'));
  });
}
