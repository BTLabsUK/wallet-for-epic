// SPDX-License-Identifier: Apache-2.0
// The Epicbox server offer on the desktop (wallet levels): at Shallow, once the server in use
// has not answered for two minutes and another of the list is listed healthy, a docked notice
// names it by its address; Not now hides it; Switch asks once, moves the wallet through
// useEpicbox and holds the new address for Receive. Deep end never offers.
import 'package:epic_wallet/src/desktop/app/relay_offer.dart';
import 'package:epic_wallet/src/desktop/data/clock.dart';
import 'package:epic_wallet/src/desktop/data/desk_levels.dart';
import 'package:epic_wallet/src/desktop/data/mock_hosts.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<String> used = [];

  @override
  Future<void> useEpicbox(String domain) {
    used.add(domain);
    return super.useEpicbox(domain);
  }
}

typedef _Rig = ({_Wallet wallet, ProviderContainer container, void Function(Duration) advance});

Future<_Rig> _pump(WidgetTester tester, WalletLevel level) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  var now = DateTime(2026, 10, 31, 9);
  // The server in use does not answer.
  final wallet = _Wallet()..epicboxBlocked = true;
  final container = ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(wallet),
      deskLevelProvider.overrideWithValue(level),
      deskClockProvider.overrideWithValue(() => now),
    ],
  );
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: const Scaffold(body: Padding(padding: EdgeInsets.all(24), child: DeskRelayNotice())),
      ),
    ),
  );
  // The first status read (a zero delay) runs before the clock moves.
  await tester.pump(const Duration(milliseconds: 1));
  return (wallet: wallet, container: container, advance: (d) => now = now.add(d));
}

/// Two minutes pass on the clock and on the timers.
Future<void> _twoMinutes(WidgetTester tester, _Rig rig) async {
  rig.advance(const Duration(minutes: 2, seconds: 1));
  await tester.pump(const Duration(minutes: 2, seconds: 1));
  await tester.pump();
  await tester.pump();
}

Future<void> _end(WidgetTester tester, _Rig rig) async {
  await tester.pumpWidget(const SizedBox());
  rig.container.dispose();
}

void main() {
  testWidgets('Deep end: no offer, however long the server is down', (tester) async {
    final rig = await _pump(tester, WalletLevel.everything);
    await _twoMinutes(tester, rig);
    await _twoMinutes(tester, rig);
    expect(rig.container.read(deskRelayOfferProvider), isNull);
    expect(find.byKey(const ValueKey('relay-offer')), findsNothing);
    await _end(tester, rig);
  });

  testWidgets('Shallow: after 2 min the notice names the healthy server by its address; Not now hides it', (tester) async {
    final rig = await _pump(tester, WalletLevel.justSendReceive);
    expect(find.byKey(const ValueKey('relay-offer')), findsNothing, reason: 'not before two minutes');
    await _twoMinutes(tester, rig);
    final offer = rig.container.read(deskRelayOfferProvider);
    expect(offer, isNotNull);
    expect(offer!.name, mockBoxAt(1));
    expect(offer.name, isNot(mockBox));
    expect(find.text('Epicbox server not reachable'), findsOneWidget);
    expect(find.widgetWithText(EButton, 'Switch to ${mockBoxAt(1)}'), findsOneWidget);
    expect(find.textContaining(mockBoxOp(1)), findsNothing, reason: 'never the operator name');
    await tester.tap(find.byKey(const ValueKey('relay-offer-later')));
    await tester.pump();
    expect(rig.container.read(deskRelayOfferProvider), isNull);
    expect(find.byKey(const ValueKey('relay-offer')), findsNothing);
    // Not now holds while the server stays down.
    await _twoMinutes(tester, rig);
    expect(rig.container.read(deskRelayOfferProvider), isNull);
    await _end(tester, rig);
  });

  testWidgets('Shallow: Switch asks once, moves through useEpicbox and holds the new address', (tester) async {
    final rig = await _pump(tester, WalletLevel.justSendReceive);
    await _twoMinutes(tester, rig);
    final name = rig.container.read(deskRelayOfferProvider)!.name;
    await tester.tap(find.byKey(const ValueKey('relay-offer-switch')));
    // The notice's button spins while the dialog asks: fixed pumps, not settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Switch to $name?'), findsOneWidget);
    expect(rig.wallet.used, isEmpty, reason: 'nothing moves before the confirm');
    await tester.tap(find.byKey(const ValueKey('relay-dialog-switch')));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(rig.wallet.used, [name]);
    final moved = rig.container.read(deskRelayMovedProvider);
    expect(moved, isNotNull);
    expect(moved!.name, name);
    expect(moved.from.host, mockBox);
    expect(moved.address, endsWith('@$name'));
    expect(rig.container.read(deskRelayOfferProvider), isNull);
    expect(find.text('Now on $name'), findsOneWidget);
    expect(find.widgetWithText(EButton, 'Show new address'), findsOneWidget);
    // OK closes the notice; the move stays for Receive.
    await tester.tap(find.byKey(const ValueKey('relay-switched-ok')));
    await tester.pump();
    expect(find.byKey(const ValueKey('relay-switched')), findsNothing);
    expect(rig.container.read(deskRelayMovedProvider), isNotNull);
    expect(rig.container.read(deskRelayNoticeShownProvider), isFalse);
    await _end(tester, rig);
  });
}
