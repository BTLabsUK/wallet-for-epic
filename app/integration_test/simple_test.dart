import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/rust/api/wallet.dart';
import 'package:epic_wallet/src/rust/frb_generated.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());

  testWidgets('native core validates a phrase', (tester) async {
    expect(validateMnemonic(phrase: 'not a real phrase'), isFalse);
  });

  testWidgets('app starts on network setup', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WalletApp()));
    expect(find.text('Continue'), findsOneWidget);
  });
}
