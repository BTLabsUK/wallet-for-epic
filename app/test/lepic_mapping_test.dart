// The LEPIC adapter's pure parts: error mapping, keys, the backend switch and the list of calls
// LEPIC cannot serve yet. No native library is loaded.
import 'dart:typed_data';

import 'package:epic_wallet/src/core_backend.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/secret_store.dart';
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

Matcher _unsupported(String call) => isA<WalletError>()
    .having((e) => e.kind, 'kind', WalletErrorKind.other)
    .having((e) => e.message, 'message', contains(call));

void main() {
  group('backend switch', () {
    test('parses the WFE_CORE values', () {
      expect(CoreBackend.parse('epicwallet'), CoreBackend.epicWallet);
      expect(CoreBackend.parse('lepic'), CoreBackend.lepic);
    });

    test('refuses an unknown value instead of falling back', () {
      expect(() => CoreBackend.parse('lepik'), throwsArgumentError);
    });

    test('a plain test build runs the epic-wallet core', () {
      expect(coreBackend, CoreBackend.epicWallet);
    });
  });

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

  test('every call in lepicMissing refuses without reaching LEPIC', () async {
    final service = LepicWalletService(secrets: MemorySecretStore());
    final session = LepicWalletSession(_NoNativeWallet());
    final one = BigInt.one;
    final calls = <String, Future<Object?> Function()>{
      'generateMnemonic': () async => service.generateMnemonic(wordCount: 24),
      'inspectSlate': () async => service.inspectSlate(json: '{}'),
      'releaseStuckSend': () => session.releaseStuckSend(key: 'l:1'),
      'estimateFee': () =>
          session.estimateFee(amount: one, minimumConfirmations: one),
      'estimateMax': () => session.estimateMax(minimumConfirmations: one),
      'sendHttp': () => session.sendHttp(
        amount: one,
        minimumConfirmations: one,
        url: 'http://127.0.0.1:9',
      ),
      'setTxNote': () => session.setTxNote(key: 'l:1', note: 'n'),
      'saveContact': () => session.saveContact(
        contact: const Contact(id: '', name: 'n', address: 'a'),
      ),
      'deleteContact': () => session.deleteContact(id: 'c'),
      'exportHistory': session.exportHistory,
      'exportHistoryCsv': session.exportHistoryCsv,
      'importHistory': () => session.importHistory(data: Uint8List(0)),
    };
    expect(calls.keys.toSet(), lepicMissing.keys.toSet());
    for (final MapEntry(key: name, value: call) in calls.entries) {
      await expectLater(call(), throwsA(_unsupported(name)), reason: name);
    }
  });

  test('the partial calls answer without reaching LEPIC', () async {
    final session = LepicWalletSession(_NoNativeWallet());
    expect(await session.transactions(refresh: false), isEmpty);
    expect(await session.contacts(), isEmpty);
    expect(await session.enrichHistory(), 0);
  });
}
