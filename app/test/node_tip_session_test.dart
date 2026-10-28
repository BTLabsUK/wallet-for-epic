// SPDX-License-Identifier: Apache-2.0
// The phone asks the node only through the open wallet (WalletSession.nodeTipFor), so the
// request follows the wallet's Tor; never the direct WalletService.nodeTip, and nothing while
// locked.
import 'dart:async';

import 'package:epic_wallet/src/net/tor_switch.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A node whose tip arrives [after]: a slow Tor circuit, or a slow node.
class _SlowNode extends FakeWalletService {
  _SlowNode(this.after);

  final Duration after;

  @override
  Future<NodeTip> nodeAnswer(WalletConfig config) =>
      Future.delayed(after, () => nodeTipValue);
}

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

  group('the send check waits for a slow node', () {
    tearDown(() => TorSwitch.on = false);

    test('8 s directly, 90 s while the Tor switch is on', () {
      TorSwitch.on = false;
      expect(nodeCheckTimeoutNow(), nodeCheckTimeout);
      expect(nodeCheckTimeout, const Duration(seconds: 8));
      TorSwitch.on = true;
      expect(nodeCheckTimeoutNow(), nodeTorCheckTimeout);
      expect(nodeTorCheckTimeout, const Duration(seconds: 90));
    });

    /// The check's answer for a tip that takes 20 s, with the switch [tor].
    Object? outcome({required bool tor}) {
      Object? result;
      fakeAsync((async) {
        TorSwitch.on = tor;
        final slow = _SlowNode(const Duration(seconds: 20));
        final c = ProviderContainer(
          overrides: [walletServiceProvider.overrideWithValue(slow)],
          retry: (_, _) => null,
        );
        c.read(walletConfigProvider.notifier).select(config);
        c.read(sessionProvider.notifier).unlocked(slow.session);
        final sub = c.listen(sendNodeCheckProvider, (_, _) {});
        c.read(sendNodeCheckProvider.future).then<void>(
          (tip) {
            result = tip;
          },
          onError: (Object e) {
            result = e;
          },
        );
        async.elapse(const Duration(seconds: 25));
        sub.close();
        c.dispose();
      });
      return result;
    }

    test('directly, a tip 20 s late fails the check: the node does not answer', () {
      expect(outcome(tor: false), isA<TimeoutException>());
    });

    test('over Tor the same tip passes: a slow circuit is not a node that is down', () {
      expect(outcome(tor: true), isA<NodeTip>());
    });
  });
}
