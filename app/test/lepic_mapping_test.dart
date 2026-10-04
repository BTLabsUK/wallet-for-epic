// The LEPIC adapter's pure parts: error mapping, history keys and rows. No native library is
// loaded.
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

/// Fails any native call, so a test proves the adapter refused before reaching LEPIC.
class _NoNativeWallet implements lepic.EpicWallet {
  @override
  bool get isDisposed => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('reached LEPIC: ${invocation.memberName}');
}

void main() {
  group('error mapping', () {
    lepic.WalletError error(lepic.WalletErrorKind kind) =>
        lepic.WalletError(kind: kind, code: 0, message: 'm');

    test('kinds both cores have keep their name and the message', () {
      final shared = {for (final k in WalletErrorKind.values) k.name: k};
      for (final kind in lepic.WalletErrorKind.values) {
        final mapped = mapLepicError(error(kind));
        expect(mapped.message, 'm');
        if (shared.containsKey(kind.name)) {
          expect(mapped.kind, shared[kind.name], reason: kind.name);
        }
      }
    });

    test('LEPIC-only kinds land on the nearest app kind', () {
      expect(
        mapLepicError(error(lepic.WalletErrorKind.foreignWallet)).kind,
        WalletErrorKind.invalidArgument,
      );
      expect(
        mapLepicError(error(lepic.WalletErrorKind.secretStore)).kind,
        WalletErrorKind.io,
      );
      for (final kind in [
        lepic.WalletErrorKind.onChain,
        lepic.WalletErrorKind.inPool,
        lepic.WalletErrorKind.notReleasable,
        lepic.WalletErrorKind.foreignAppData,
        lepic.WalletErrorKind.damagedAppData,
      ]) {
        expect(
          mapLepicError(error(kind)).kind,
          WalletErrorKind.invalidArgument,
          reason: kind.name,
        );
      }
      for (final kind in [
        lepic.WalletErrorKind.restoreScanRequired,
        lepic.WalletErrorKind.changedDuringCancel,
        lepic.WalletErrorKind.locked,
        lepic.WalletErrorKind.notPosted,
        lepic.WalletErrorKind.cancelled,
        lepic.WalletErrorKind.unsupported,
        lepic.WalletErrorKind.panic,
      ]) {
        expect(mapLepicError(error(kind)).kind, WalletErrorKind.other);
      }
    });
  });

  test('history keys carry the LEPIC transaction id', () {
    expect(lepicTxId('l:42'), 42);
    for (final key in ['s:slate-1', 'l:', 'l:x', '42']) {
      expect(
        () => lepicTxId(key),
        throwsA(
          isA<WalletError>().having(
            (e) => e.kind,
            'kind',
            WalletErrorKind.invalidArgument,
          ),
        ),
      );
    }
  });

  test('slate steps read as the old core tells them', () {
    SlateStage stage(lepic.SlateStage s) => lepicSlateInfo(
      lepic.SlateInfo(
        slateId: 'id',
        version: 3,
        stage: s,
        amount: BigInt.from(5),
        fee: BigInt.two,
        messages: const [],
      ),
    ).stage;
    expect(stage(lepic.SlateStage.s1), SlateStage.send);
    expect(stage(lepic.SlateStage.s2), SlateStage.response);
    expect(stage(lepic.SlateStage.s3), SlateStage.response);
    for (final s in [
      lepic.SlateStage.i1,
      lepic.SlateStage.i2,
      lepic.SlateStage.i3,
    ]) {
      expect(stage(s), SlateStage.invoice, reason: s.name);
    }
    final info = lepicSlateInfo(
      lepic.SlateInfo(
        slateId: 'abc',
        version: 2,
        stage: lepic.SlateStage.s1,
        amount: BigInt.from(7),
        fee: BigInt.one,
        messages: const [],
      ),
    );
    expect(
      info,
      SlateInfo(
        slateId: 'abc',
        amount: BigInt.from(7),
        fee: BigInt.one,
        stage: SlateStage.send,
      ),
    );
  });

  test('contacts and enrichment answer without reaching LEPIC', () async {
    final session = LepicWalletSession(_NoNativeWallet());
    expect(await session.contacts(), isEmpty);
    expect(await session.enrichHistory(), 0);
  });

  group('history rows', () {
    lepic.TransactionDetails details({
      lepic.TxDirection direction = lepic.TxDirection.outgoing,
      required lepic.TxStatus status,
      String? slateId = 'slate-1',
      int? confirmedAtMs,
      BigInt? confirmedHeight,
      bool releasable = false,
    }) => lepic.TransactionDetails(
      txId: 7,
      direction: direction,
      status: status,
      slateId: slateId,
      amountCredited: BigInt.from(3),
      amountDebited: BigInt.from(10),
      fee: BigInt.from(1),
      createdAtMs: 1790000000500,
      confirmedAtMs: confirmedAtMs,
      confirmedHeight: confirmedHeight,
      kernelExcess: 'ab',
      counterparty: 'key@relay',
      ttlCutoffHeight: BigInt.from(99),
      releasable: releasable,
    );

    test('a send waiting for its answer can be cancelled', () {
      final row = lepicTxEntry(details(status: lepic.TxStatus.sent));
      expect(row.key, 'l:7');
      expect(lepicTxId(row.key), 7);
      expect(row.kind, TxKind.sent);
      expect(row.status, TxStatus.awaitingRecipient);
      expect(row.cancellable, isTrue);
      expect(row.repostable, isFalse);
      expect(row.timeUnix, 1790000000);
      expect(row.counterparty, 'key@relay');
      expect(row.ttlCutoffHeight, BigInt.from(99));
    });

    test('a finalized send the node refused can be posted again', () {
      final row = lepicTxEntry(details(status: lepic.TxStatus.finalized));
      expect(row.status, TxStatus.awaitingConfirmation);
      expect(row.repostable, isTrue);
      expect(row.cancellable, isFalse);
      expect(row.releasable, isFalse);
    });

    test('a send LEPIC lets go of is releasable', () {
      final row = lepicTxEntry(
        details(status: lepic.TxStatus.posted, releasable: true),
      );
      expect(row.releasable, isTrue);
    });

    test('a confirmed send carries its block and the confirmation time', () {
      final row = lepicTxEntry(
        details(
          status: lepic.TxStatus.confirmed,
          confirmedAtMs: 1790000600000,
          confirmedHeight: BigInt.from(42),
        ),
      );
      expect(row.status, TxStatus.confirmed);
      expect(row.confirmed, isTrue);
      expect(row.blockHeight, BigInt.from(42));
      expect(row.timeUnix, 1790000600);
      expect(row.kernelExcess, 'ab');
    });

    test('an expired receive is a cancelled one, by expiry', () {
      final row = lepicTxEntry(
        details(
          direction: lepic.TxDirection.incoming,
          status: lepic.TxStatus.expired,
        ),
      );
      expect(row.kind, TxKind.receivedCancelled);
      expect(row.status, TxStatus.cancelled);
      expect(row.cancelReason, CancelReason.expiry);
    });

    test('an output a scan restored has no slate', () {
      final row = lepicTxEntry(
        details(
          direction: lepic.TxDirection.incoming,
          status: lepic.TxStatus.confirmed,
          slateId: null,
        ),
      );
      expect(row.kind, TxKind.received);
      expect(row.source, TxSource.restored);
    });
  });
}
