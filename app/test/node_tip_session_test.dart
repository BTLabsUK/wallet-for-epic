// The phone asks the node only through the open wallet (WalletSession.nodeTipFor), so the
// request follows the wallet's Tor; never the direct WalletService.nodeTip, and nothing while
// locked.
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeWalletService service;
  late ProviderContainer container;
  const config = WalletConfig(
    dataDir: '/wallets/main',
    chain: Chain.mainnet,
    nodeUrl: 'https://node.example',
    epicboxDomain: 'epicbox.example',
    epicboxPort: 443,
  );

  setUp(() {
    service = FakeWalletService()..nodeTipFails = StateError('the node was asked directly');
    container = ProviderContainer(
      overrides: [walletServiceProvider.overrideWithValue(service)],
      retry: (_, _) => null,
    );
    container.read(walletConfigProvider.notifier).select(config);
  });

  tearDown(() => container.dispose());

  test('the header tip and the send check go through the open wallet', () async {
    container.read(sessionProvider.notifier).unlocked(service.session);
    final sub = container.listen(nodeTipProvider, (_, _) {});
    final check = container.listen(sendNodeCheckProvider, (_, _) {});
    expect((await container.read(nodeTipProvider.future)).height, service.nodeTipValue.height);
    expect((await container.read(sendNodeCheckProvider.future)).height, service.nodeTipValue.height);
    expect(service.session.nodeTipsFor.map((c) => c.nodeUrl), [config.nodeUrl, config.nodeUrl]);
    expect(service.nodeTipCalls, 0);
    sub.close();
    check.close();
  });

  test('locked: the node is not asked', () async {
    final sub = container.listen(nodeTipProvider, (_, _) {});
    await expectLater(container.read(nodeTipProvider.future), throwsStateError);
    expect(service.nodeTipCalls, 0);
    expect(service.session.nodeTipsFor, isEmpty);
    sub.close();
  });

  test('a node typed in is tested through the open wallet, directly with none open', () async {
    expect(service.nodeTipCalls, 0);
    service.nodeTipFails = null;
    await askNodeTip(service, null, config);
    expect(service.nodeTipCalls, 1, reason: 'first run: no wallet, no Tor switch yet');
    await askNodeTip(service, service.session, config);
    expect(service.nodeTipCalls, 1);
    expect(service.session.nodeTipsFor, hasLength(1));
  });
}
