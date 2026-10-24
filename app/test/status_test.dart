
import 'package:epic_wallet/src/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epic_wallet/src/ui/status.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

WalletSummary _summary({bool validated = true, int height = 2499990}) =>
    WalletSummary(
      lastConfirmedHeight: BigInt.from(height),
      minimumConfirmations: BigInt.from(3),
      total: BigInt.from(100),
      spendable: BigInt.from(100),
      awaitingConfirmation: BigInt.zero,
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: BigInt.zero,
      validatedWithNode: validated,
    );

final NodeTip _tip = NodeTip(
  height: BigInt.from(2500000),
  nodeVersion: '3.6.0',
);

const ListenerState _connected = ListenerState(connected: true);
const ListenerState _lost = ListenerState(lost: true);
const ListenerState _connecting = ListenerState();
const ListenerState _stopped = ListenerState(stopped: true);

void main() {
  group('walletStatus', () {
    test('android-09: a connection lost while Tor starts is connecting, not offline', () {
      final s = walletStatus(
        tip: AsyncData(_tip),
        syncing: false,
        summary: _summary(),
        listener: _lost,
        waitingForTor: true,
      );
      expect(s.epicbox, EpicboxState.connecting);
      expect(
        walletStatus(tip: AsyncData(_tip), syncing: false, summary: _summary(), listener: _lost).epicbox,
        EpicboxState.offline,
      );
    });

    test('a running refresh is syncing, with its percent', () {
      final s = walletStatus(
        tip: AsyncData(_tip),
        syncing: true,
        percent: 40,
        summary: _summary(),
        listener: _connected,
      );
      expect(s.node.state, NodeState.syncing);
      expect(s.node.percent, 40);
      expect(s.epicbox, EpicboxState.online);
    });

    test('a failed tip is offline, even with checked balances', () {
      final s = walletStatus(
        tip: AsyncError(StateError('down'), StackTrace.empty),
        syncing: false,
        summary: _summary(),
        listener: _connecting,
      );
      expect(s.node.state, NodeState.offline);
      expect(s.node.validated, isTrue);
      expect(s.epicbox, EpicboxState.connecting);
    });

    test('balances the node did not check are offline, not validated', () {
      final s = walletStatus(
        tip: AsyncData(_tip),
        syncing: false,
        summary: _summary(validated: false),
        listener: _lost,
      );
      expect(s.node.state, NodeState.offline);
      expect(s.node.validated, isFalse);
      expect(s.epicbox, EpicboxState.offline);
    });

    test('a tip is online; the height is the checked one, else the tip', () {
      final checked = walletStatus(
        tip: AsyncData(_tip),
        syncing: false,
        summary: _summary(),
        listener: _connected,
      );
      expect(checked.node.state, NodeState.online);
      expect(checked.node.height, BigInt.from(2499990));
      final fresh = walletStatus(
        tip: AsyncData(_tip),
        syncing: false,
        summary: _summary(height: 0),
        listener: _connected,
      );
      expect(fresh.node.height, BigInt.from(2500000));
    });

    test('no answer yet is connecting; a stopped listener has no status', () {
      final s = walletStatus(
        tip: const AsyncLoading(),
        syncing: false,
        listener: _stopped,
      );
      expect(s.node.state, NodeState.connecting);
      expect(s.epicbox, isNull);
    });
  });
}
