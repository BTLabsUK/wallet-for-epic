// SPDX-License-Identifier: Apache-2.0
// Overview: the Invoices card sits above Recent activity while something waits and below it when
// nothing does; an in-person send reads "Sending in person"; a request made in person or by
// file never reads with an empty payer name.
import 'package:epic_wallet/src/desktop/data/invoices.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/invoices/issue_tab.dart' show requestStateText;
import 'package:epic_wallet/src/desktop/screens/wallet/overview_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/models.dart' show Epic1Via;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

class _Wallet extends MockDeskWallet {
  _Wallet({this.txList}) : super(delay: Duration.zero);

  final List<Tx>? txList;

  @override
  Future<List<Tx>> transactions() async => txList ?? await super.transactions();
}

Future<void> _pump(WidgetTester tester, _Wallet api) async {
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)]);
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1400, 2400);
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

IssuedRequest _request({bool byFile = false, bool inPerson = false, RequestState state = RequestState.waiting}) => IssuedRequest(
  slateId: 's',
  txId: 1,
  payerAddress: '',
  amount: 44000000000,
  issuedAt: DateTime(2026, 11, 11),
  expiresAt: DateTime(2026, 11, 12),
  state: state,
  byFile: byFile,
  inPerson: inPerson,
);

void main() {
  testWidgets('with an invoice waiting, the Invoices card is above Recent activity', (tester) async {
    await _pump(tester, _Wallet());
    final card = tester.getTopLeft(find.text(_l.deskInvActOverviewTitle)).dy;
    final recent = tester.getTopLeft(find.text(_l.deskOvRecent)).dy;
    expect(card, lessThan(recent));
  });

  testWidgets('an in-person send under way reads "Sending in person"', (tester) async {
    await _pump(
      tester,
      _Wallet(
        txList: [
          Tx(
            id: 1,
            slateId: 's1',
            direction: TxDirection.sent,
            state: TxState.waitingRecipient,
            method: TxMethod.file,
            amount: 1000000,
            fee: 8000,
            created: DateTime(2026, 10, 27, 12),
            epic1Via: Epic1Via.inPerson,
          ),
        ],
      ),
    );
    expect(find.text('Sending in person'), findsOneWidget);
    expect(find.textContaining('Sending to'), findsNothing);
  });

  test('a request made in person or by file names no empty payer', () {
    for (final r in [_request(inPerson: true, byFile: true), _request(byFile: true)]) {
      for (final s in RequestState.values) {
        final text = requestStateText(_l, _request(byFile: r.byFile, inPerson: r.inPerson, state: s)).$1;
        expect(text, isNot(contains('  ')), reason: '$s');
        expect(text, isNot(contains('until  ')), reason: '$s');
      }
    }
    expect(requestStateText(_l, _request(byFile: true)).$1, _l.reqFileLead);
    expect(requestStateText(_l, _request(inPerson: true, byFile: true)).$1, _l.deskInvIssuerWaitingInPerson);
  });
}
