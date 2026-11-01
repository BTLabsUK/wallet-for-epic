// SPDX-License-Identifier: Apache-2.0
// A send whose post may still be under way reads "Posting…" on the desktop at every level, with
// the Posted step the one under way; "Not posted" waits for a post that really failed. The core
// side (when a row is posting) is test/early_not_posted_test.dart.
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart' show ETone;
import 'package:epic_wallet/src/desktop/widgets/pay_steps.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/levels/level_features.dart' show LevelWording, TimelineStyle;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

/// A send LEPIC finalized: [posting] while its post may run, [repostable] once it failed.
core.TxEntry _finalized({bool posting = false, bool repostable = false}) => core.TxEntry(
  key: 'l:7',
  id: 7,
  slateId: 'f0e1d2c3-b4a5-4697-8879-9f3a7c21a0b1',
  kind: core.TxKind.sent,
  status: core.TxStatus.awaitingConfirmation,
  source: core.TxSource.wallet,
  createdAtUnix: 1700000000,
  timeUnix: 1700000000,
  confirmed: false,
  amountCredited: BigInt.zero,
  amountDebited: BigInt.from(1000000000),
  fee: BigInt.from(800000),
  numInputs: 1,
  numOutputs: 2,
  kernelExcess: '08abc',
  outputCommits: const [],
  counterparty: 'bob@epicbox.example',
  transport: 'epicbox',
  cancellable: false,
  repostable: repostable,
  posting: posting,
  releasable: false,
);

void main() {
  final l = englishStrings;
  Tx desk(core.TxEntry e) => deskTx(e, tip: 100, minConf: 3, fallbackId: -1, contactName: 'Bob');

  test('posting: no Not posted, at every level, and the Posted step is under way', () {
    final t = desk(_finalized(posting: true));
    expect(t.notPosted, isFalse);
    expect(t.posting, isTrue);
    expect(statusOf(l, t), (l.postFinishedPosting, ETone.info));
    for (final w in LevelWording.values) {
      expect(levelStatusWithMailbox(l, t, w, null).$1, l.postFinishedPosting, reason: '$w');
    }
    for (final style in TimelineStyle.values) {
      final steps = payStepList(l, t, style, name: 'Bob');
      expect(steps.where((s) => s.state == PayStepState.now), hasLength(1), reason: '$style');
      expect(steps.indexWhere((s) => s.state == PayStepState.now), 2, reason: '$style: Posted is the step under way');
      expect(steps.every((s) => s.sub != l.deskTxStatusNotPosted), isTrue);
    }
  });

  test('a first post that fails and a retry that succeeds: posting, then posted, never Not posted', () {
    final words = [
      for (final e in [_finalized(posting: true), _finalized()]) statusOf(l, desk(e)).$1,
    ];
    expect(words, isNot(contains(l.deskTxStatusNotPosted)));
    expect(words.last, l.deskTxStatusWaitingBlock);
  });

  test('a post that really failed still reads Not posted', () {
    final t = desk(_finalized(repostable: true));
    expect(t.notPosted, isTrue);
    expect(statusOf(l, t), (l.deskTxStatusNotPosted, ETone.warn));
  });
}
