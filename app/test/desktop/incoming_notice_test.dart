// SPDX-License-Identifier: Apache-2.0
// A payment arrives: the desktop shows the phone's notice, kept until closed, with View to the
// payment; with the window behind others the system's notification shows too, and a click on
// it opens the same payment.
import 'package:epic_wallet/src/desktop/app/desk_window.dart';
import 'package:epic_wallet/src/desktop/app/shell.dart';
import 'package:epic_wallet/src/desktop/app/system_notice.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart' show formatEpicL;
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _l = englishStrings;

class _Notifier extends DeskSystemNotifier {
  final shown = <({String title, String body, String payload})>[];
  void Function(String? payload)? tap;

  @override
  Future<bool> show({required String title, required String body, required String payload, String openLabel = 'Open'}) async {
    shown.add((title: title, body: body, payload: payload));
    return true;
  }

  @override
  set onTap(void Function(String? payload)? run) => tap = run;
}

class _Behind extends DeskWindow {
  @override
  ValueListenable<DeskWindowState> get state => ValueNotifier(const DeskWindowState(focused: false));
}

void main() {
  setUpAll(initializeDateFormatting);

  Future<(ProviderContainer, MockDeskWallet, _Notifier)> open(WidgetTester tester, {required bool inFront}) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = MockDeskWallet(delay: Duration.zero);
    final notifier = _Notifier();
    final c = ProviderContainer(overrides: [
      deskApiProvider.overrideWithValue(api),
      deskSystemNotifierProvider.overrideWithValue(notifier),
      if (!inFront) deskWindowProvider.overrideWithValue(_Behind()),
    ]);
    addTearDown(c.dispose);
    await tester.runAsync(() => c.read(deskProvider.notifier).refresh());
    c.read(deskNavProvider.notifier).reset(DeskRoute.settingsAbout);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: Consumer(builder: (_, ref, _) => DeskShell(at: ref.watch(deskNavProvider))),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    return (c, api, notifier);
  }

  // Activity loads from the mock: let its waits finish.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<String> arrive(WidgetTester tester, MockDeskWallet api) async {
    await tester.runAsync(() async {
      await api.simulateIncoming();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    final tx = (await tester.runAsync(api.transactions))!.first;
    await tester.pump(const Duration(milliseconds: 500));
    return _l.homeNoticeReceivedAmountFrom(formatEpicL(_l, tx.amount), tx.contactName!);
  }

  testWidgets('a payment arrives with the window in front: the notice stays and View opens the payment', (tester) async {
    final (c, api, notifier) = await open(tester, inFront: true);
    final text = await arrive(tester, api);
    expect(find.text(text), findsOneWidget);
    // Kept: no clock closes it.
    await tester.pump(const Duration(minutes: 5));
    expect(find.text(text), findsOneWidget);
    expect(notifier.shown, isEmpty);

    await tester.tap(find.widgetWithText(EButton, _l.homeNoticeView));
    await settle(tester);
    expect(c.read(deskNavProvider).route, DeskRoute.activity);
    expect(find.text(text), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a payment arrives with the window behind others: the system notification shows and its click opens the payment', (tester) async {
    final (c, api, notifier) = await open(tester, inFront: false);
    final text = await arrive(tester, api);
    expect(notifier.shown, hasLength(1));
    expect(notifier.shown.single.title, _l.deskSysNoticeTitle);
    expect(notifier.shown.single.body, text);

    notifier.tap!(notifier.shown.single.payload);
    await settle(tester);
    expect(c.read(deskNavProvider).route, DeskRoute.activity);

    // Off in Settings: no system notification.
    final s = c.read(deskProvider).settings;
    await tester.runAsync(() => c.read(deskProvider.notifier).saveSettings(s.copyWith(systemNotices: false)));
    await arrive(tester, api);
    expect(notifier.shown, hasLength(1));
    await settle(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
