// Contacts and settings on the desktop's LEPIC adapter: a contact's invoice address, the trusted
// list read by key, and the invoice expiry kept with the wallet. LepicDeskWallet over the real
// LepicWalletSession on a stand-in `EpicWallet`; no native library is loaded.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/desktop/data/invoices.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

const _password = 'test-pass-1234';
const _payments = 'esOwnPaymentsKey@epicbox.example';
const _shop = 'esShopKey@epicbox.example';
const _shopInvoice = 'esShopInvoiceKey@epicbox.example';

lepic.WalletError _lepicError(lepic.WalletErrorKind kind) => lepic.WalletError(kind: kind, code: 0, message: kind.name);

/// LEPIC's wallet in memory: the invoice half and a summary. Fails any other call.
class _Wallet implements lepic.EpicWallet {
  final List<lepic.InvoiceSender> senders = [];

  @override
  bool get isDisposed => false;
  @override
  void lock() {}
  @override
  void dispose() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('reached LEPIC: ${invocation.memberName}');

  @override
  Stream<lepic.WalletEvent> events() => const Stream.empty();

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
  Future<List<lepic.TransactionDetails>> transactions() async => const [];

  @override
  Stream<lepic.RefreshProgress> refresh() async* {
    yield lepic.RefreshProgress(percent: 100, message: 'done', summary: await summary(refresh: false));
  }

  @override
  Future<String> mnemonic({required String password}) async {
    if (password != _password) throw _lepicError(lepic.WalletErrorKind.wrongPassword);
    return 'words';
  }

  @override
  Future<String> epicboxAddress() async => _payments;
  @override
  Future<String> invoiceAddress() async => 'esOwnInvoiceKey@epicbox.example';
  @override
  Future<int> invoiceAddressIndex() async => 1;
  @override
  Future<List<lepic.InvoiceSender>> invoiceSenders() async => [...senders];

  @override
  Future<lepic.InvoiceSender> allowInvoiceSender({required String address, required String label}) async {
    final s = lepic.InvoiceSender(address: address, label: label, addedAtMs: 1790000000000);
    senders
      ..removeWhere((x) => x.address.split('@').first == address.split('@').first)
      ..add(s);
    return s;
  }

  @override
  Future<bool> removeInvoiceSender({required String address}) async {
    final before = senders.length;
    senders.removeWhere((x) => x.address.split('@').first == address.split('@').first);
    return senders.length < before;
  }

  @override
  Future<lepic.InvoiceReport> drainInvoices() async =>
      const lepic.InvoiceReport(parked: 0, finalized: 0, repeated: 0, rejected: 0, held: 0, dropped: 0, notices: 0, bounced: 0);

  @override
  Future<lepic.InboxReport> drainEpicbox() async =>
      const lepic.InboxReport(received: 0, finalized: 0, repeated: 0, rejected: 0, held: 0, notices: 0, bounced: 0, dropped: 0);

  @override
  Future<lepic.InvoiceSweep> sweepInvoices({BigInt? expirySecs}) async =>
      lepic.InvoiceSweep(deleted: const [], cancelled: Uint32List(0), cancellable: Uint32List(0));

  @override
  Future<List<lepic.IncomingInvoice>> pendingInvoices({BigInt? expirySecs}) async => const [];
}

/// Opens a [LepicWalletSession] on the stand-in for every unlock.
class _Service extends core.FakeWalletService {
  _Service(this.lepicWallet) : super(password: _password);

  final _Wallet lepicWallet;
  LepicWalletSession? opened;

  @override
  Future<core.WalletSession> open({required core.WalletConfig config, required String password}) async {
    await super.open(config: config, password: password);
    return opened = LepicWalletSession(lepicWallet, validateAddress: (_) => true);
  }
}


Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  late Directory support;
  late MemorySecretStore secrets;
  late _Wallet lepicWallet;
  late _Service service;
  LepicDeskWallet? wallet;

  LepicDeskWallet open() => LepicDeskWallet(
    service: service,
    walletDir: (chain) async {
      final dir = Directory('${support.path}/wallets/${chain.name}');
      await dir.create(recursive: true);
      return dir.path;
    },
    secrets: secrets,
    filesDir: () async => support,
    nodePoll: const Duration(hours: 1),
    invoicesEvery: const Duration(hours: 1),
    paymentsEvery: const Duration(hours: 1),
    invoiceFocus: false,
  );

  setUp(() async {
    support = await Directory.systemTemp.createTemp('desk-contacts-test-');
    secrets = MemorySecretStore();
    lepicWallet = _Wallet();
    service = _Service(lepicWallet);
    wallet = open();
    await wallet!.createWallet(name: 'Main', password: _password);
    expect(await wallet!.unlock(_password), isTrue);
    await _settle();
  });

  tearDown(() async {
    await wallet?.dispose();
    await support.delete(recursive: true);
  });

  test('a contact keeps its invoice address, and the trusted entry finds the contact by it', () async {
    lepicWallet.senders.add(lepic.InvoiceSender(address: _shopInvoice, label: 'Shop', addedAtMs: 1790000000000));
    final id = await wallet!.saveContact(Contact(id: '', name: 'Shop', address: _shop, invoiceAddress: _shopInvoice));
    final saved = (await wallet!.contacts()).firstWhere((c) => c.id == id);
    expect(saved.id, id);
    expect(saved.invoiceAddress, _shopInvoice);
    final book = await wallet!.invoices();
    expect(book.trusted.single.contactId, id, reason: 'matched by the invoice address, not the payments one');
    expect(book.trustedFor(_shopInvoice), isNotNull);
  });

  test('a contact without an invoice address reads as before, and is matched by its payments key', () async {
    lepicWallet.senders.add(lepic.InvoiceSender(address: _shop, label: 'Shop', addedAtMs: 1790000000000));
    final id = await wallet!.saveContact(Contact(id: '', name: 'Shop', address: _shop));
    expect((await wallet!.contacts()).firstWhere((c) => c.id == id).invoiceAddress, isNull);
    expect((await wallet!.invoices()).trusted.single.contactId, id);
  });

  test('trusting and untrusting go to LEPIC\'s list, read back by key', () async {
    await wallet!.trustSender(_shopInvoice, 'Shop');
    expect(lepicWallet.senders.single.address, _shopInvoice);
    expect((await wallet!.invoices()).trustedFor('esShopInvoiceKey@other.relay'), isNotNull);
    await wallet!.untrustSender(_shopInvoice);
    expect(lepicWallet.senders, isEmpty);
    expect((await wallet!.invoices()).trusted, isEmpty);
  });

  test('the invoice expiry is stored with the wallet and read back after a restart', () async {
    expect((await wallet!.invoices()).expiry, defaultInvoiceExpiry);
    await wallet!.setInvoiceExpiry(const Duration(hours: 6));
    expect((await wallet!.invoices()).expiry, const Duration(hours: 6));
    await wallet!.dispose();
    wallet = open();
    expect(await wallet!.unlock(_password), isTrue);
    await _settle();
    expect((await wallet!.invoices()).expiry, const Duration(hours: 6));
    await wallet!.setInvoiceExpiry(const Duration(days: 9));
    expect((await wallet!.invoices()).expiry, maxInvoiceExpiry, reason: 'capped at 48 hours');
  });
}
