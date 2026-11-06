// SPDX-License-Identifier: Apache-2.0
// A payment the contacts' collect finalized and posted reads posted on the desktop (LNX3-4):
// the listener's "finalized" comes before the post, so the list read then shows it not on the
// network; the collect's paymentFinalized reads it again. And a payment through a pairing
// names its contact and goes by Epicbox at every state (LNX3-5). LepicDeskWallet over the real
// LepicWalletSession on a stand-in `EpicWallet`; no native library is loaded.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

const _password = 'test-pass-1234';
const _pairing = '0123456789abcdef0123456789abcdef';
const _slate = 'c13b7bff-0000-4000-8000-000000000001';

/// LEPIC's wallet in memory: one send through a pairing's mailbox, in [status]; the events the
/// test raises. Fails any other call.
class _Wallet implements lepic.EpicWallet {
  final events$ = StreamController<lepic.WalletEvent>.broadcast();
  lepic.TxStatus status = lepic.TxStatus.sent;

  @override
  Future<bool> restoreScanRequired() async => false;
  @override
  bool get isDisposed => false;
  @override
  void lock() {}
  @override
  void dispose() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('reached LEPIC: ${invocation.memberName}');

  @override
  Stream<lepic.WalletEvent> events() => events$.stream;

  @override
  void setEpicboxOverTor({required bool enabled}) {}

  @override
  void setOnionRoutes({required List<lepic.OnionRoute> routes}) {}

  @override
  void expectTor() {}

  @override
  Future<lepic.WalletSummary> summary({required bool refresh}) async => lepic.WalletSummary(
    lastConfirmedHeight: BigInt.from(100),
    minimumConfirmations: BigInt.from(3),
    total: BigInt.from(1000),
    spendable: BigInt.from(1000),
    awaitingConfirmation: BigInt.zero,
    awaitingFinalization: BigInt.zero,
    immature: BigInt.zero,
    locked: BigInt.zero,
    validatedWithNode: false,
  );

  @override
  Future<List<lepic.TransactionDetails>> transactions() async => [
    lepic.TransactionDetails(
      txId: 7,
      direction: lepic.TxDirection.outgoing,
      status: status,
      slateId: _slate,
      // A mailbox send is kept as a file export, with no counterparty; once its answer is in,
      // as an Epicbox one, still with none.
      transport: status == lepic.TxStatus.sent ? 'file' : 'epicbox',
      amountCredited: BigInt.zero,
      amountDebited: BigInt.from(3007000),
      fee: BigInt.from(7000),
      createdAtMs: 1792920000000,
      kernelExcess: status == lepic.TxStatus.sent ? null : '08aa',
      releasable: false,
      undelivered: false,
      messages: const [],
      flow: lepic.TxFlow.payment,
      origin: lepic.TxOrigin.wallet,
      outputCommits: const [],
      spentCommits: const [],
      unverified: false,
    ),
  ];

  @override
  Future<String?> contactOfTransaction({required int txId}) async => txId == 7 ? _pairing : null;

  @override
  Stream<lepic.RefreshProgress> refresh() async* {
    yield lepic.RefreshProgress(percent: 100, message: 'done', summary: await summary(refresh: false));
  }

  @override
  Future<String> epicboxAddress() async => 'esOwnPaymentsKey@epicbox.example';

  @override
  Future<List<lepic.ContactView>> contacts() async => [
    lepic.ContactView(
      peerProfile: 0,
      contactId: _pairing,
      label: '',
      claimedName: 'Floo C',
      state: lepic.PairingState.verified,
      status: lepic.PairingStatus.verified,
      peerFeatures: 0,
      sas: const [],
      allowInvoices: false,
      seal: lepic.SealState.on_,
      importedFromBackup: false,
      lapsed: false,
      removedByPeer: false,
      createdAtMs: 1792910000000,
    ),
  ];

  @override
  Future<lepic.ContactView> contact({required String contactId}) async => (await contacts()).single;

  @override
  Future<List<lepic.PendingPairingView>> pairingsPending() async => const [];

  @override
  Future<lepic.ContactCollectReport> contactsCollect({
    required lepic.CollectTrigger trigger,
    required lepic.ContactRelayMode relayMode,
    List<String>? only,
  }) async => const lepic.ContactCollectReport(mailboxes: 0, messages: 0, paired: 0, unreachable: [], delivered: 0, failed: [], ended: []);

  @override
  Future<lepic.OutboxReport> contactsOutboxDeliver({required lepic.ContactRelayMode relayMode}) async =>
      const lepic.OutboxReport(delivered: 0, failed: 0, stuck: 0);

  @override
  Future<lepic.InboxReport> drainEpicbox() async =>
      const lepic.InboxReport(received: 0, finalized: 0, repeated: 0, rejected: 0, held: 0, notices: 0, bounced: 0, dropped: 0);

  @override
  Future<lepic.InvoiceSweep> sweepInvoices({BigInt? expirySecs}) async =>
      lepic.InvoiceSweep(deleted: const [], cancelled: Uint32List(0), cancellable: Uint32List(0));

  @override
  Future<List<lepic.ContactInvoiceView>> contactInvoices() async => const [];
}

/// Opens a [LepicWalletSession] on the stand-in for every unlock.
class _Service extends core.FakeWalletService {
  _Service(this.lepicWallet) : super(password: _password);

  final _Wallet lepicWallet;

  @override
  Future<core.WalletSession> open({required core.WalletConfig config, required String password}) async {
    await super.open(config: config, password: password);
    return LepicWalletSession(lepicWallet);
  }
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  late Directory support;
  late _Wallet lepicWallet;
  late LepicDeskWallet wallet;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('desk-collect-posted-test-');
    lepicWallet = _Wallet();
    wallet = LepicDeskWallet(
      service: _Service(lepicWallet),
      walletDir: (chain) async {
        final dir = Directory(WalletRegistry.firstWalletDir(support.path, chain));
        await dir.create(recursive: true);
        return dir.path;
      },
      secrets: MemorySecretStore(),
      filesDir: () async => support,
      nodePoll: const Duration(hours: 1),
      paymentsEvery: const Duration(hours: 1),
    );
    await wallet.createWallet(name: 'Main', password: _password);
    expect(await wallet.unlock(_password), isTrue);
    await _settle();
  });

  tearDown(() async {
    await wallet.dispose();
    await lepicWallet.events$.close();
    await support.delete(recursive: true);
  });

  Future<Tx> send() async => (await wallet.transactions()).single;

  test('a mailbox send names its contact and goes by Epicbox at every state (LNX3-5)', () async {
    var tx = await send();
    expect((tx.pairingId, tx.contactName, tx.method), (_pairing, 'Floo C', TxMethod.epicbox));
    lepicWallet.status = lepic.TxStatus.posted;
    lepicWallet.events$.add(const lepic.WalletEvent(kind: lepic.WalletEventKind.contactPaymentFinalized, txId: 7, slateId: _slate, contactId: _pairing));
    await _settle();
    tx = await send();
    expect((tx.contactName, tx.method, tx.notPosted), ('Floo C', TxMethod.epicbox, false));
  });

  test('a payment the collect posted reads posted, though the list was read while it finalized (LNX3-4)', () async {
    // Read between LEPIC's "finalized" and its post, as the listener's event makes it.
    lepicWallet.status = lepic.TxStatus.finalized;
    await wallet.syncNow().catchError((Object _) {});
    // Its post may still succeed: posting, not Not posted.
    final during = await send();
    expect((during.notPosted, during.posting), (false, true));
    // Posted; the collect says the payment is finalized.
    lepicWallet.status = lepic.TxStatus.posted;
    lepicWallet.events$.add(const lepic.WalletEvent(kind: lepic.WalletEventKind.contactPaymentFinalized, txId: 7, slateId: _slate, contactId: _pairing));
    await _settle();
    final tx = await send();
    expect(tx.notPosted, isFalse);
    expect(tx.state, TxState.posted);
  });
}
