// SPDX-License-Identifier: Apache-2.0
// A tester on 26.11.3 (desktop, Shallow): "When I sent a test transaction, during the
// confirmation process I went back to my wallet -- the amount was way off." A send locks its
// whole input coin until the change confirms, so a test send of 1 from one coin of 100 leaves
// nothing spendable for those blocks. Shallow's figure is the wallet's balance, so it keeps the
// 98.992 coming back while the send is posted and while its change confirms; the 0 spendable
// now is a line under it.
import 'package:epic_wallet/src/desktop/data/desk_levels.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/overview_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _epic = 100000000;
const _fee = 800000;

/// 1 EPIC to Alice from the wallet's one coin of 100: its change is 98.992.
const _change = 100 * _epic - _epic - _fee;

Tx _send(TxState state, {int? height, int confirmations = 0}) => Tx(
  id: 10,
  slateId: '4a3f87ec',
  direction: TxDirection.sent,
  state: state,
  method: TxMethod.epicbox,
  amount: _epic,
  fee: _fee,
  created: DateTime(2026, 11, 10, 18, 11),
  counterparty: 'esAliceAddress@epicbox.example.org',
  contactName: 'Alice',
  height: height,
  confirmations: confirmations,
  credited: _change,
);

class _Wallet extends MockDeskWallet {
  _Wallet(this.b, this.tx) : super(delay: Duration.zero);

  final Balance b;
  final Tx tx;

  @override
  Future<Balance> balance() async => b;

  @override
  Future<List<Tx>> transactions() async => [tx];
}

Future<void> _pump(WidgetTester tester, Balance b, Tx tx) async {
  final container = ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(_Wallet(b, tx)),
      deskLevelProvider.overrideWithValue(WalletLevel.justSendReceive),
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: OverviewScreen())),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Every word on screen, the rich texts' spans joined.
String _shown(WidgetTester tester) => [
  for (final t in tester.widgetList<w.RichText>(find.byType(w.RichText))) t.text.toPlainText(),
].join('\n');

/// Shallow's figure keeps the 98.992, with the 0 spendable now on a line under it.
void _expectBalanceKept(WidgetTester tester) {
  final l = englishStrings;
  final shown = _shown(tester);
  expect(shown, contains(l.deskOvBalance));
  expect(shown, contains('98.99'));
  expect(find.byKey(const ValueKey('overview-spendable-now')), findsOneWidget);
  expect(shown, contains('0.0\u00a0EPIC spendable now'));
}

void main() {
  testWidgets('posted, not mined: the figure keeps the 98.992 coming back', (tester) async {
    // LEPIC's figures: the input locked, the change not on chain yet (no part of total).
    await _pump(
      tester,
      const Balance(spendable: 0, awaitingConfirmation: 0, locked: 100 * _epic, awaitingFinalization: _change, reportedTotal: 100 * _epic),
      _send(TxState.posted),
    );
    _expectBalanceKept(tester);
  });

  testWidgets('mined, change confirming: the figure keeps the 98.992', (tester) async {
    await _pump(
      tester,
      const Balance(spendable: 0, awaitingConfirmation: _change, locked: 0, awaitingFinalization: 0, reportedTotal: _change),
      _send(TxState.confirming, height: 3792470, confirmations: 2),
    );
    _expectBalanceKept(tester);
  });

  testWidgets('nothing pending: one figure, no spendable-now line', (tester) async {
    await _pump(
      tester,
      const Balance(spendable: _change, awaitingConfirmation: 0, locked: 0, awaitingFinalization: 0, reportedTotal: _change),
      _send(TxState.confirmed, height: 3792470, confirmations: 10),
    );
    expect(_shown(tester), contains('98.99'));
    expect(find.byKey(const ValueKey('overview-spendable-now')), findsNothing);
  });
}
