// SPDX-License-Identifier: Apache-2.0
// The phone's biometric store (PlatformBiometricStore) over a scripted flutter_secure_storage
// channel. flutter_secure_storage 11.2.0 never answers a prompt dismissed with "Use PIN": the
// call ends as dismissed a few seconds after the app is back in front, not after the 90 s limit,
// so turning biometrics on or unlocking never hangs (e648723df). A read after a write in the
// same process that showed no prompt is not used (the plugin could keep the key unlocked).
import 'dart:async';

import 'package:epic_wallet/src/secret_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void main() {
  /// The plugin's answers: each call waits for [answer] (never completed: a dismissed prompt).
  /// The mocked channel replies outside the fake clock, so an answer is let through with
  /// `tester.runAsync`.
  late Completer<Object?> answer;
  late List<String> calls;

  setUp(() {
    answer = Completer<Object?>();
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) {
      calls.add(call.method);
      return answer.future;
    });
  });

  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, null));

  /// The system prompt covers the app, then goes away.
  void prompt(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  testWidgets('a prompt dismissed with Use PIN ends as dismissed once the app is back, not at the 90 s limit', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    Object? error;
    var ended = false;
    unawaited(PlatformBiometricStore().read('k').then((_) {}, onError: (Object e) {
      error = e;
    }).whenComplete(() => ended = true));
    await tester.pump();
    expect(calls, ['read']);
    prompt(tester);
    await tester.pump(PlatformBiometricStore.answerGrace - const Duration(milliseconds: 100));
    expect(ended, isFalse, reason: 'a confirmed prompt still has time to answer');
    await tester.pump(const Duration(milliseconds: 200));
    expect(ended, isTrue, reason: 'ended within moments, not at ${PlatformBiometricStore.promptLimit}');
    expect(error, isA<BiometricCancelled>().having((e) => e.message, 'message', 'dismissed'));
  });

  testWidgets('a write dismissed with Use PIN ends the same way', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    Object? error;
    unawaited(PlatformBiometricStore().write('k', 'v').then((_) {}, onError: (Object e) {
      error = e;
    }));
    await tester.pump();
    prompt(tester);
    await tester.pump(PlatformBiometricStore.answerGrace + const Duration(milliseconds: 100));
    expect(error, isA<BiometricCancelled>());
  });

  testWidgets('a confirmed prompt answers with the value', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    String? value;
    unawaited(PlatformBiometricStore().read('k').then((v) => value = v));
    await tester.pump();
    prompt(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() async {
      answer.complete('sealed');
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(value, 'sealed');
    await tester.pump(PlatformBiometricStore.answerGrace);
    expect(value, 'sealed');
  });

  testWidgets('a read after a write in the same run that showed no prompt is not used', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    answer.complete(null);
    final store = PlatformBiometricStore();
    var written = false;
    unawaited(store.write('k', 'v').then((_) => written = true));
    await tester.pump();
    prompt(tester);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(written, isTrue);
    Object? error;
    unawaited(store.read('k').then((_) {}, onError: (Object e) {
      error = e;
    }));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(error, isA<BiometricCancelled>().having((e) => e.message, 'message', 'no prompt'));
  });
}
