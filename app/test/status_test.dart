// SPDX-License-Identifier: Apache-2.0

import 'package:epic_wallet/src/providers.dart';
import 'package:flutter/material.dart';
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

    test('android-04: a refresh at the tip that has scanned nothing is not syncing', () {
      final atTip = walletStatus(
        tip: AsyncData(_tip),
        syncing: true,
        percent: 0,
        summary: _summary(height: 2499998),
        listener: _connected,
      );
      expect(atTip.node.state, NodeState.online);
      final behind = walletStatus(
        tip: AsyncData(_tip),
        syncing: true,
        percent: 0,
        summary: _summary(height: 2499990),
        listener: _connected,
      );
      expect(behind.node.state, NodeState.syncing);
      final scanning = walletStatus(
        tip: AsyncData(_tip),
        syncing: true,
        percent: 30,
        summary: _summary(height: 2499999),
        listener: _connected,
      );
      expect(scanning.node.state, NodeState.syncing);
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

    test('a node that does not answer is offline while a refresh retries it (26.10.26)', () {
      // A filtered network: the tip request fails and the refresh keeps retrying the node. As
      // "syncing 0 %" node failover never moved; offline lets it.
      final failed = AsyncError<NodeTip>(StateError('timed out'), StackTrace.empty);
      final s = walletStatus(tip: failed, syncing: true, percent: 0, listener: _connecting);
      expect(s.node.state, NodeState.offline);
      final again = walletStatus(
        // The 15 s tip check asking again keeps the error until an answer comes.
        // ignore: invalid_use_of_internal_member
        tip: const AsyncLoading<NodeTip>().copyWithPrevious(failed),
        syncing: true,
        percent: 0,
        listener: _connecting,
      );
      expect(again.node.state, NodeState.offline, reason: 'asking again, with no answer yet');
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

  testWidgets('a pulse breathes five times, then holds at full opacity', (tester) async {
    Widget pulse(bool active) => Directionality(
      textDirection: TextDirection.ltr,
      child: Pulse(active: active, child: const SizedBox.square(dimension: 10)),
    );
    double opacity() => tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value;
    await tester.pumpWidget(pulse(true));
    await tester.pump(const Duration(milliseconds: 800));
    expect(opacity(), lessThan(1));
    await tester.pump(const Duration(milliseconds: 1600) * pulseBreaths);
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacity(), 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
    // A new busy stretch breathes again.
    await tester.pumpWidget(pulse(false));
    await tester.pumpWidget(pulse(true));
    await tester.pump(const Duration(milliseconds: 800));
    expect(opacity(), lessThan(1));
  });
}
