// linux-06: the payer probe of Issue invoice must not leak LEPIC's "Not accepted" for an
// address it cannot use; the screen stays usable and nothing reaches the zone's error handler.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/desktop/data/invoice_state.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/invoices/issue_invoice_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';

class _Rejecting extends MockDeskWallet {
  int asked = 0;

  @override
  Future<PeerCapability> peerCapability(String address) async {
    asked++;
    throw StateError('Not accepted: not an epicbox address with a relay on this network');
  }
}

void main() {
  testWidgets('a payer address LEPIC rejects does not throw out of the probe', (tester) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final wallet = _Rejecting();
    final c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
    addTearDown(c.dispose);
    await tester.runAsync(() => c.read(deskProvider.notifier).refresh());
    c.read(deskInvoicesProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: const Scaffold(
            body: IssueInvoiceScreen(arg: 'esQr7mZ2kLp9xTn4vBc8dWf3hJy6gAs1eUo5iRtKqNxw@epicbox.example.org'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(wallet.asked, 1, reason: 'the probe ran');
    expect(tester.takeException(), isNull);
  });
}
