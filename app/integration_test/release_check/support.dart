// SPDX-License-Identifier: Apache-2.0
// Shared helpers of the release check: boots the real desktop wallet as main_desktop.dart does,
// finds things by their text, takes screenshots. Never print the phrase or password.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:epic_wallet/main_desktop.dart' show deskOverrides;
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/state.dart' show deskProvider;
import 'package:epic_wallet/src/wallet_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const node = String.fromEnvironment('WFE_CHECK_NODE', defaultValue: 'https://node.btlabs.uk');
const node2 = String.fromEnvironment('WFE_CHECK_NODE2', defaultValue: 'https://node.epicnet.us:3413');
/// A fresh install starts on this relay whatever relay the run picked for reachability.
const freshRelay = 'epicbox.epiccash.com';

final shotsDir = Platform.environment['RC_SHOTS'] ?? 'build/rc_shots';

/// One line per check; the table in the report is made from these.
void record(String step, bool pass, [String evidence = '']) {
  // ignore: avoid_print
  print('RC ${pass ? 'PASS' : 'FAIL'} | $step | $evidence');
}

String randomPassword() {
  final r = Random.secure();
  const chars = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return 'Aa1-${List.generate(14, (_) => chars[r.nextInt(chars.length)]).join()}';
}

final shotKey = GlobalKey();

Future<void> boot(WidgetTester tester, {Size size = const Size(1280, 860), List<Override> extra = const []}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final overrides = await tester.runAsync(() async {
    await initWalletBackend();
    return deskOverrides();
  });
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: overrides!,
      child: extra.isEmpty
          ? RepaintBoundary(key: shotKey, child: const DeskApp())
          // A nested scope so [extra] can replace what deskOverrides() already set.
          : ProviderScope(overrides: extra, child: RepaintBoundary(key: shotKey, child: const DeskApp())),
    ),
  );
  await settle(tester);
}

/// Lets real time pass (native calls, network) while pumping frames.
/// Uses the node at [url] the way Settings > Node's list does (DeskController.useNode); the
/// list's own taps are covered by its widget tests, and its layout changes often.
Future<void> pickNode(WidgetTester tester, String url) async {
  await tester.runAsync(() => containerOf(tester).read(deskProvider.notifier).useNode(url));
  await settle(tester, ms: 8000);
}

Future<void> settle(WidgetTester tester, {int ms = 400}) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> pumpUntil(WidgetTester tester, bool Function() done,
    {Duration timeout = const Duration(seconds: 90), String what = 'condition'}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) throw TestFailure('timeout waiting for $what; on screen: ${shownTexts()}');
    await settle(tester, ms: 250);
  }
}

Future<void> waitText(WidgetTester tester, Pattern p, {Duration timeout = const Duration(seconds: 90)}) =>
    pumpUntil(tester, () => hasText(p), timeout: timeout, what: 'text $p');

/// What is on screen, for a failure message or a dump: on a screen that shows a recovery
/// phrase (twelve or more single lower-case words) the words are left out, so no log keeps one.
String shownTexts([int take = 40]) {
  final all = texts();
  final word = RegExp(r'^[a-z]{3,8}$');
  final phrase = all.where(word.hasMatch).length >= 12;
  return all.where((t) => !(phrase && word.hasMatch(t))).take(take).map((t) => t.replaceAll('\n', ' ⏎ ')).join(' | ');
}

List<String> texts() {
  final out = <String>[];
  for (final e in find.byType(RichText, skipOffstage: false).evaluate()) {
    final t = (e.widget as RichText).text.toPlainText().trim();
    if (t.isNotEmpty) out.add(t);
  }
  return out;
}

bool hasText(Pattern p) => texts().any((t) => p is RegExp ? p.hasMatch(t) : t.contains(p as String));

Finder textF(Pattern p) => find.byWidgetPredicate(skipOffstage: false, (w) {
  if (w is! RichText) return false;
  final t = w.text.toPlainText();
  return p is RegExp ? p.hasMatch(t) : t.contains(p as String);
}, description: 'text $p');

Future<void> tapText(WidgetTester tester, Pattern p, {bool last = false}) async {
  final f = textF(p);
  expect(f, findsWidgets, reason: 'no "$p" on screen: ${shownTexts()}');
  await tester.ensureVisible(last ? f.last : f.first);
  await tester.tap(last ? f.last : f.first, warnIfMissed: false);
  await settle(tester);
}

/// Types into the n-th text field on screen.
Future<void> typeIn(WidgetTester tester, int n, String text) async {
  final f = find.byType(EditableText);
  expect(f.evaluate().length, greaterThan(n), reason: 'no text field $n: ${shownTexts(30)}');
  await tester.tap(f.at(n), warnIfMissed: false);
  await tester.pump();
  await tester.enterText(f.at(n), text);
  await tester.pump();
}

Future<void> key(WidgetTester tester, LogicalKeyboardKey k, {bool ctrl = false}) async {
  if (ctrl) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(k);
  if (ctrl) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await settle(tester);
}

Future<void> shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 300));
  final ro = shotKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (ro == null) return;
  await tester.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 1);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    await Directory(shotsDir).create(recursive: true);
    await File('$shotsDir/$name.png').writeAsBytes(data!.buffer.asUint8List());
  });
}

/// Flutter errors raised during the test (overflow and the like) are collected here.
final flutterErrors = <String>[];
void captureErrors() {
  final prev = FlutterError.onError;
  FlutterError.onError = (d) {
    flutterErrors.add(d.exceptionAsString().split('\n').first);
    prev?.call(d);
  };
}

/// One line of everything visible, for the log (never call it on a screen showing the phrase).
void dump(String label) =>
    // ignore: avoid_print
    print('DUMP $label: ${shownTexts(1 << 30)}');

ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(DeskApp)));
