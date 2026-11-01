// SPDX-License-Identifier: Apache-2.0
// Every WalletService and WalletSession member through a loopback channel, against
// FakeWalletService: arguments arrive, results return, errors keep their kind.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:epic_wallet/src/remote/channel.dart';
import 'package:epic_wallet/src/remote/client.dart';
import 'package:epic_wallet/src/remote/dispatcher.dart';
import 'package:epic_wallet/src/remote/protocol.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Member names of every request the client sent, over the whole file.
final Set<String> sentMembers = {};

/// Records what the client sends and passes it on.
class RecordingChannel implements RpcChannel {
  RecordingChannel(this._inner);

  final RpcChannel _inner;
  final List<Map<String, Object?>> frames = [];

  @override
  Stream<String> get incoming => _inner.incoming;

  @override
  void send(String frame) {
    final json = jsonDecode(frame) as Map<String, Object?>;
    frames.add(json);
    if (json['m'] case final String m) sentMembers.add(m);
    _inner.send(frame);
  }

  @override
  Future<void> close() => _inner.close();
}

/// The fake, plus the arguments it does not keep itself.
class ArgsSession extends FakeWalletSession {
  final Map<String, Object?> args = {};

  @override
  Stream<ScanProgress> scan({BigInt? startHeight, bool deleteUnconfirmed = false}) {
    args['scan.startHeight'] = startHeight;
    return super.scan(startHeight: startHeight);
  }

  @override
  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  }) {
    args['summary'] = (refresh, minimumConfirmations);
    return super.summary(
      refresh: refresh,
      minimumConfirmations: minimumConfirmations,
    );
  }

  @override
  Stream<RefreshProgress> refresh({required BigInt minimumConfirmations}) {
    args['refresh'] = minimumConfirmations;
    return super.refresh(minimumConfirmations: minimumConfirmations);
  }

  @override
  Future<List<TxEntry>> transactions({required bool refresh}) {
    args['transactions'] = refresh;
    return super.transactions(refresh: refresh);
  }

  @override
  Future<FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
    SendOptions? options,
  }) {
    args['estimateFee'] = (amount, minimumConfirmations);
    return super.estimateFee(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      options: options,
    );
  }

  @override
  Future<FeeEstimate> estimateMax({required BigInt minimumConfirmations}) {
    args['estimateMax'] = minimumConfirmations;
    return super.estimateMax(minimumConfirmations: minimumConfirmations);
  }

  @override
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
    SendOptions? options,
  }) {
    args['sendEpicbox'] = minimumConfirmations;
    return super.sendEpicbox(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      address: address,
      message: message,
      options: options,
    );
  }
}

const config = WalletConfig(
  dataDir: '/wallets/a',
  chain: Chain.floonet,
  nodeUrl: 'https://floo-node.example',
  nodeApiSecret: 'node-secret',
  epicboxDomain: 'flooepicbox.example',
  epicboxPort: 443,
);

final String serviceAddress = 'es${'S' * 50}@epicbox.example';
final String payerAddress = 'es${'P' * 50}@epicbox.example';
final DateTime now = DateTime(2026, 10, 6, 12);

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Matcher throwsKind(WalletErrorKind kind) =>
    throwsA(isA<WalletError>().having((e) => e.kind, 'kind', kind));

void main() {
  late ArgsSession session;
  late FakeWalletService fake;
  late RecordingChannel channel;
  late RemoteWalletService client;
  late WalletDispatcher dispatcher;

  setUp(() {
    session = ArgsSession()
      ..summaryValue = WalletSummary(
        lastConfirmedHeight: BigInt.from(100),
        minimumConfirmations: BigInt.one,
        total: BigInt.from(100000000000),
        spendable: BigInt.from(100000000000),
        awaitingConfirmation: BigInt.zero,
        awaitingFinalization: BigInt.zero,
        immature: BigInt.zero,
        locked: BigInt.zero,
        validatedWithNode: true,
      )
      ..clock = () => now;
    fake = FakeWalletService(session: session);
    final (a, b) = loopbackPair();
    channel = RecordingChannel(a);
    client = RemoteWalletService(channel);
    dispatcher = WalletDispatcher(fake, b);
  });

  tearDown(() => client.close());

  Future<RemoteWalletSession> openSession() async {
    final w = await client.createWithPin(config: config, pin: '123456');
    return w.session as RemoteWalletSession;
  }

  group('WalletService', () {
    test(
      'validateMnemonic and validateEpicboxAddress answer locally',
      () async {
        final phrase = '${List.filled(11, 'abandon').join(' ')} about';
        expect(client.validateMnemonic(phrase: phrase), true);
        expect(client.validateMnemonic(phrase: fake.phrase), false);
        expect(client.validateEpicboxAddress(address: serviceAddress), true);
        expect(client.validateEpicboxAddress(address: 'nope'), false);
        await settle();
        expect(channel.frames, isEmpty);
      },
    );

    test('inspectSlate', () async {
      final info = SlateInfo(
        slateId: 'sl',
        amount: BigInt.from(5),
        fee: BigInt.one,
        stage: SlateStage.send,
        messages: const [SlateMessage(role: SlateRole.sender, text: 'x')],
      );
      fake.slateInfos['{"x":1}'] = info;
      expect(await client.inspectSlate(json: '{"x":1}'), info);
      await expectLater(
        client.inspectSlate(json: 'junk'),
        throwsKind(WalletErrorKind.invalidSlate),
      );
    });

    test('walletExists, nodeTip, pinFailures', () async {
      expect(await client.walletExists(config: config), false);
      fake.existingWallets.add(config.dataDir);
      expect(await client.walletExists(config: config), true);
      expect(
        await client.nodeTip(config: config),
        NodeTip(height: BigInt.from(2500000), nodeVersion: '3.6.0'),
      );
      fake.pinFailureCount = 2;
      expect(await client.pinFailures(config: config), 2);
    });

    test('create and open', () async {
      final s = await client.create(
        config: config,
        mnemonic: 'some words',
        password: 'pw',
      );
      expect(s, isA<RemoteWalletSession>());
      expect(fake.createdConfig, config);
      expect(fake.createdMnemonic, 'some words');
      expect(fake.password, 'pw');
      await expectLater(
        client.create(config: config, password: 'pw'),
        throwsKind(WalletErrorKind.walletAlreadyExists),
      );
      await expectLater(
        client.open(config: config, password: 'bad'),
        throwsKind(WalletErrorKind.wrongPassword),
      );
      final opened = await client.open(config: config, password: 'pw');
      expect(opened, isA<RemoteWalletSession>());
      expect(
        (opened as RemoteWalletSession).handle,
        isNot((s as RemoteWalletSession).handle),
      );
    });

    test('createWithPin, openWithPin', () async {
      final w = await client.createWithPin(
        config: config,
        mnemonic: 'm',
        pin: '123456',
      );
      expect(w.sealedPassword, fakeSealedPassword('123456'));
      expect(fake.createdPin, '123456');
      expect(fake.createdMnemonic, 'm');
      expect(w.session.supportsInvoices, true);
      await expectLater(
        client.openWithPin(
          config: config,
          pin: '000000',
          sealedPassword: w.sealedPassword,
        ),
        throwsKind(WalletErrorKind.wrongPassword),
      );
      expect(await client.pinFailures(config: config), 1);
      final s = await client.openWithPin(
        config: config,
        pin: '123456',
        sealedPassword: w.sealedPassword,
      );
      expect(s, isA<RemoteWalletSession>());
      expect(await client.pinFailures(config: config), 0);
    });

    test('resetPassword', () async {
      fake.existingWallets.add(config.dataDir);
      await client.resetPassword(config: config, mnemonic: fake.phrase, newPassword: 'brand-new-pass');
      expect(fake.passwordResets, [config.dataDir]);
      await expectLater(
        client.resetPassword(config: config, mnemonic: 'not a phrase', newPassword: 'brand-new-pass'),
        throwsKind(WalletErrorKind.invalidMnemonic),
      );
    });

    test('deleteWallet', () async {
      fake.existingWallets.add(config.dataDir);
      await client.deleteWallet(config: config);
      expect(fake.deletedWallets, [config.dataDir]);
      await expectLater(
        client.openWithPin(config: config, pin: '1', sealedPassword: 'x'),
        throwsKind(WalletErrorKind.walletNotFound),
      );
    });
  });

  group('WalletSession', () {
    test('supportsInvoices arrives with the handle', () async {
      session.invoicesSupported = false;
      final s = await openSession();
      expect(s.supportsInvoices, false);
      await expectLater(
        s.collectInvoices(),
        throwsA(
          isA<WalletError>().having(
            (e) => e.message,
            'message',
            invoicesUnsupported('collectInvoices').message,
          ),
        ),
      );
    });

    test(
      'dispose is sent without an answer, then the handle is gone',
      () async {
        final s = await openSession();
        s.dispose();
        await settle();
        expect(session.disposeCalls, 1);
        expect(channel.frames.last['m'], 'dispose');
        await expectLater(
          s.epicboxAddress(),
          throwsA(
            isA<WalletError>()
                .having((e) => e.kind, 'kind', unknownSession.kind)
                .having((e) => e.message, 'message', unknownSession.message),
          ),
        );
      },
    );

    test('phrase and PIN members', () async {
      final s = await openSession();
      expect(await s.mnemonic(password: 'x'), session.phrase);
      final sealed = fakeSealedPassword('123456');
      expect(
        await s.mnemonicWithPin(pin: '123456', sealedPassword: sealed),
        session.phrase,
      );
      await expectLater(
        s.mnemonicWithPin(pin: '1', sealedPassword: sealed),
        throwsKind(WalletErrorKind.wrongPassword),
      );
      await s.checkPin(pin: '123456', sealedPassword: sealed);
      await expectLater(
        s.checkPin(pin: '1', sealedPassword: sealed),
        throwsKind(WalletErrorKind.wrongPassword),
      );
      expect(
        await s.changePin(
          sealedPassword: sealed,
          oldPin: '123456',
          newPin: '654321',
        ),
        fakeSealedPassword('654321'),
      );
      await expectLater(
        s.changePin(sealedPassword: sealed, oldPin: '123456', newPin: '1'),
        throwsKind(WalletErrorKind.invalidArgument),
      );
      await s.confirmPinChange(sealedPassword: 'new-sealed');
      expect(fake.confirmedPinChanges, ['new-sealed']);
      await expectLater(
        s.changePassword(currentPassword: 'not it', newPassword: 'new password'),
        throwsKind(WalletErrorKind.wrongPassword),
      );
      await s.changePassword(
        currentPassword: fake.password,
        newPassword: 'new password',
      );
      expect(fake.password, 'new password');
    });

    test('cancel, repost, release', () async {
      final s = await openSession();
      session.transactionsValue = [
        fakeTx(slateId: 'r', repostable: true),
        fakeTx(slateId: 'x', releasable: true),
      ];
      await s.cancelTransaction(txId: 7);
      expect(session.cancelledTxIds, [7]);
      await s.repostTransaction(key: 's:r');
      expect(session.repostedKeys, ['s:r']);
      await expectLater(
        s.repostTransaction(key: 's:x'),
        throwsKind(WalletErrorKind.invalidArgument),
      );
      session.transactionsValue.add(fakeTx(id: 8, slateId: 'u', undelivered: true));
      await s.resendEpicbox(key: 's:u');
      expect(session.resentEpicboxKeys, ['s:u']);
      await expectLater(
        s.resendEpicbox(key: 's:x'),
        throwsKind(WalletErrorKind.invalidArgument),
      );
      await s.releaseStuckSend(key: 's:x');
      expect(session.releasedKeys, ['s:x']);
      await expectLater(
        s.releaseStuckSend(key: 's:r'),
        throwsKind(WalletErrorKind.invalidArgument),
      );
    });

    test('outputs, send options, split and consolidate', () async {
      final s = await openSession();
      WalletOutput out(String c, int value) => WalletOutput(
        commitment: c,
        value: BigInt.from(value),
        status: WalletOutputStatus.unspent,
        category: OutputCategory.spendable,
        isCoinbase: false,
        height: BigInt.from(90),
        lockHeight: BigInt.zero,
        mmrIndex: BigInt.from(7),
        confirmations: BigInt.from(11),
        txId: 3,
      );
      session.outputsValue = [out('c1', 5000000000), out('c2', 300000000)];
      final ten = BigInt.from(10);
      expect(await s.outputs(), session.outputsValue);

      const options = SendOptions(
        strategy: SelectionStrategy.all,
        changeOutputs: 3,
      );
      final e = await s.estimateFee(
        amount: BigInt.from(100000000),
        minimumConfirmations: ten,
        options: options,
      );
      expect(session.estimateOptions.last, options);
      expect(e.inputCount, 2);
      expect(e.locked, BigInt.from(5300000000));
      expect(e.changeOutputs, 3);
      expect(e.change, e.locked - e.amount - e.fee);

      await s.createSendSlate(
        amount: BigInt.from(100000000),
        minimumConfirmations: ten,
        options: options,
      );
      await s.sendEpicbox(
        amount: BigInt.from(100000000),
        minimumConfirmations: ten,
        address: session.address,
      );
      expect(session.sentOptions, [options, null]);

      final split = await s.estimateSplit(outputs: 4, minimumConfirmations: ten);
      expect(split.inputCount, 2);
      await expectLater(
        s.estimateSplit(outputs: 11, minimumConfirmations: ten),
        throwsKind(WalletErrorKind.invalidArgument),
      );
      final consolidate = await s.estimateConsolidate(minimumConfirmations: ten);
      expect(consolidate.changeOutputs, 0);
      final sent = await s.splitOutputs(outputs: 4, minimumConfirmations: ten);
      expect(sent.outputCount, 4);
      expect(session.splits, [4]);
      // The split's own outputs are unconfirmed: nothing is left to consolidate.
      await expectLater(
        s.consolidateOutputs(minimumConfirmations: ten),
        throwsKind(WalletErrorKind.notEnoughFunds),
      );
      session.outputsValue = [out('c3', 200000000), out('c4', 300000000)];
      final merged = await s.consolidateOutputs(minimumConfirmations: ten);
      expect(merged.inputCount, 2);
      expect(session.consolidations, 1);
      // A cancelled payment's coins, spent to the wallet itself by name.
      session.outputsValue = [out('c5', 200000000)];
      await s.spendOutputsToSelf(commitments: ['c5'], minimumConfirmations: ten, outputs: 3);
      expect(session.spentToSelf, [
        ['c5'],
      ]);
      expect(session.spentToSelfOutputs, [3], reason: 'the output count crosses the wire');
    });

    test('a server switch reaches the open wallet with the new relay', () async {
      final s = await openSession();
      const moved = WalletConfig(
        dataDir: '/wallets/a',
        chain: Chain.floonet,
        nodeUrl: 'https://node.example.org',
        epicboxDomain: 'relay.example.org',
        epicboxPort: 443,
      );
      await s.setServers(config: moved);
      expect(session.serverSwitches, [moved]);
      expect(await s.epicboxAddress(), endsWith('@relay.example.org'));
    });

    test('a node tip asked through the open wallet', () async {
      final s = await openSession();
      const other = WalletConfig(
        dataDir: '/wallets/a',
        chain: Chain.floonet,
        nodeUrl: 'https://node.example.org',
        epicboxDomain: 'relay.example.org',
        epicboxPort: 443,
      );
      final tip = await s.nodeTipFor(config: other);
      expect(tip.height, BigInt.from(2500000));
      expect(session.nodeTipsFor.map((c) => c.nodeUrl), ['https://node.example.org']);
    });

    test('slates, fees and sends', () async {
      final s = await openSession();
      final amount = BigInt.from(1000000000);
      final ten = BigInt.from(10);
      expect(
        await s.createSendSlate(
          amount: amount,
          minimumConfirmations: ten,
          message: 'for you',
        ),
        session.sendSlate,
      );
      expect(session.sentAmounts, [amount]);
      expect(session.sentMessages, ['for you']);
      expect(await s.epicboxAddress(), session.address);
      session.restoreScanPending = true;
      expect(await s.restoreScanRequired(), isTrue);
      session.fingerprintValue = '0a1b2c3d';
      expect(await s.fingerprint(), '0a1b2c3d');
      // Minimum confirmations: the stored count both ways, the core's refusal as its kind.
      expect(await s.minimumConfirmations(), session.summaryValue.minimumConfirmations.toInt());
      await s.setMinimumConfirmations(12);
      expect(session.minimumConfirmationsSets, [12]);
      expect(await s.minimumConfirmations(), 12);
      await expectLater(s.setMinimumConfirmations(31), throwsKind(WalletErrorKind.invalidArgument));
      expect(await s.minimumConfirmations(), 12);
      expect(
        await s.estimateFee(amount: amount, minimumConfirmations: ten),
        FeeEstimate(amount: amount, fee: session.fee),
      );
      expect(session.args['estimateFee'], (amount, ten));
      await expectLater(
        s.estimateFee(amount: big, minimumConfirmations: ten),
        throwsKind(WalletErrorKind.notEnoughFunds),
      );
      expect(
        await s.estimateMax(minimumConfirmations: BigInt.one),
        FeeEstimate(
          amount: session.summaryValue.spendable - session.fee,
          fee: session.fee,
          locked: session.summaryValue.spendable,
          inputCount: 1,
        ),
      );
      expect(session.args['estimateMax'], BigInt.one);

      final posted = await s.finalizeAndPost(
        slateJson: session.responseSlate.json,
      );
      expect(posted.slateId, session.responseSlate.slateId);
      expect(posted.amountDebited, amount + session.fee);
      expect(posted.status, TxStatus.awaitingConfirmation);
      expect(session.finalizedSlates, [session.responseSlate.json]);
      await expectLater(
        s.finalizeAndPost(slateJson: '{}'),
        throwsKind(WalletErrorKind.invalidSlate),
      );

      final sent = await s.sendEpicbox(
        amount: amount,
        minimumConfirmations: ten,
        address: payerAddress,
        message: 'hi',
      );
      expect(sent.counterparty, payerAddress);
      expect(sent.messages, const [
        SlateMessage(role: SlateRole.sender, text: 'hi'),
      ]);
      expect(session.epicboxSends.single.to, payerAddress);
      expect(session.args['sendEpicbox'], ten);
      session.sendError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'relay down',
      );
      await expectLater(
        s.sendEpicbox(
          amount: amount,
          minimumConfirmations: ten,
          address: payerAddress,
        ),
        throwsA(
          const WalletError(
            kind: WalletErrorKind.transportFailed,
            message: 'relay down',
          ),
        ),
      );

      final first = await s.receiveSlate(slateJson: '{"in":1}');
      expect(first.repeated, false);
      expect(first.json, session.responseSlate.json);
      expect((await s.receiveSlate(slateJson: '{"in":1}')).repeated, true);
      expect(session.receivedSlates, ['{"in":1}', '{"in":1}']);
    });

    test('summary, transactions, enrichHistory', () async {
      final s = await openSession();
      expect(
        await s.summary(refresh: true, minimumConfirmations: BigInt.two),
        session.summaryValue,
      );
      expect(session.args['summary'], (true, BigInt.two));
      session.transactionsValue = [
        fakeTx(slateId: 'a', amountCredited: BigInt.from(5)),
      ];
      session.notes['s:a'] = 'note';
      final txs = await s.transactions(refresh: false);
      expect(txs.single.note, 'note');
      expect(txs.single.amountCredited, BigInt.from(5));
      expect(session.args['transactions'], false);
      session.enrichChanges = 3;
      expect(await s.enrichHistory(), 3);
    });

    test('notes and contacts', () async {
      final s = await openSession();
      await s.setTxNote(key: 's:a', note: 'rent');
      expect(session.notes, {'s:a': 'rent'});
      await s.setTxNote(key: 's:a');
      expect(session.notes, isEmpty);
      await s.setTxLabel(key: 's:a', label: 'Rent');
      expect(session.labels, {'s:a': 'Rent'});
      session.transactionsValue = [
        fakeTx(key: 'c:o', source: TxSource.restored),
      ];
      await s.setTxDetails(key: 'c:o', transport: 'tor', note: 'n');
      expect(session.details['c:o'], (
        counterparty: null,
        transport: 'tor',
        note: 'n',
      ));
      final labelled = (await s.transactions(refresh: false)).single;
      expect(labelled.manualFields, {ManualField.transport, ManualField.note});
      final saved = await s.saveContact(
        contact: Contact(id: '', name: 'Bob', address: payerAddress, note: 'n'),
      );
      expect(saved.id, isNotEmpty);
      expect(await s.contacts(), [saved]);
      await expectLater(
        s.saveContact(
          contact: Contact(id: '', name: '', address: ''),
        ),
        throwsKind(WalletErrorKind.invalidArgument),
      );
      await s.setFavouriteContact(id: saved.id, favourite: true);
      expect(await s.favouriteContacts(), [saved.id]);
      await s.setFavouriteContact(id: saved.id, favourite: false);
      expect(await s.favouriteContacts(), isEmpty);
      await s.deleteContact(id: saved.id);
      expect(await s.contacts(), isEmpty);
    });

    test('history files', () async {
      final s = await openSession();
      session.notes['s:a'] = 'rent';
      final file = await s.exportHistory();
      expect(file, await session.exportHistory());
      session.notes.clear();
      final report = await s.importHistory(data: file);
      expect(
        report,
        const ImportReport(merged: 0, added: 1, skipped: 0, contactsAdded: 0),
      );
      expect(session.notes, {'s:a': 'rent'});
      final conflict = ImportConflict(
        key: 's:a',
        field: ManualField.label,
        mine: 'Mine',
        theirs: 'Theirs',
        timeUnix: 5,
        amount: BigInt.from(-7),
      );
      session.importConflicts = [conflict];
      final asked = await s.importHistory(data: file);
      expect(asked.applied, isFalse);
      expect(asked.conflicts, [conflict]);
      final chosen = await s.importHistory(
        data: file,
        useBackup: {conflict.id: true},
      );
      expect((chosen.applied, chosen.replaced), (true, 1));
      expect(session.lastUseBackup, {conflict.id: true});
      await expectLater(
        s.importHistory(data: Uint8List.fromList([1, 2, 3])),
        throwsKind(WalletErrorKind.invalidArgument),
      );
      session.transactionsValue = [fakeTx(slateId: 'a')];
      expect(await s.exportHistoryCsv(), await session.exportHistoryCsv());
    });

    test('invoices the wallet pays', () async {
      final s = await openSession();
      // Invoices park only from a verified paired contact with Allow invoices on.
      final shop = session.pairing.seedPaired(name: 'Shop', allowInvoices: true, paymentsAddress: serviceAddress);
      expect((await s.pairing.pairingForContact('none')), isNull);
      expect([for (final p in await s.pairing.pairings()) p.id], [shop.id]);

      final events = <InvoiceEvent>[];
      final sub = s.invoiceEvents().listen(events.add);
      await settle();
      session.relayInvoice(
        from: serviceAddress,
        slateId: 'inv1',
        amount: BigInt.from(1000),
        message: 'order 7',
      );
      session.relayInvoice(
        from: serviceAddress,
        slateId: 'inv2',
        amount: BigInt.from(2000),
      );
      expect(await s.collectInvoices(), const InvoiceCollectReport(parked: 2));
      final pending = await s.pendingInvoices();
      expect(
        pending.first,
        PendingInvoice(
          slateId: 'inv1',
          senderAddress: serviceAddress,
          amount: BigInt.from(1000),
          message: 'order 7',
          receivedAt: now,
          expiresAt: now.add(const Duration(hours: 24)),
          pairingId: shop.id,
        ),
      );
      await expectLater(
        s.payInvoice(slateId: 'inv1', amount: BigInt.one),
        throwsKind(WalletErrorKind.amountMismatch),
      );
      session.replyError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'x',
      );
      final paid = await s.payInvoice(
        slateId: 'inv1',
        amount: BigInt.from(1000),
      );
      expect(paid.status, InvoiceStatus.replyFailed);
      await expectLater(
        s.resendInvoiceReply(slateId: 'inv1'),
        throwsKind(WalletErrorKind.transportFailed),
      );
      session.replyError = null;
      expect(
        (await s.resendInvoiceReply(slateId: 'inv1')).status,
        InvoiceStatus.replied,
      );
      expect(session.deliveredReplies, ['inv1']);
      expect((await s.paidInvoice(slateId: 'inv1'))?.txId, paid.txId);
      expect(await s.paidInvoice(slateId: 'none'), isNull);
      await s.declineInvoice(slateId: 'inv2');
      expect(session.declinedInvoices, ['inv2']);
      // A request read from a file: paid for its own amount only; the answer comes back.
      final file = await session.pairing.requestFile(amount: BigInt.from(300));
      await expectLater(
        s.payRequestFile(slateJson: file.json, amount: BigInt.one),
        throwsKind(WalletErrorKind.amountMismatch),
      );
      final answer = await s.payRequestFile(slateJson: file.json, amount: BigInt.from(300));
      expect(answer, session.paidRequestFiles[file.slateId]);
      await settle();
      expect(events.map((e) => (e.kind, e.slateId)), [
        (InvoiceEventKind.received, 'inv1'),
        (InvoiceEventKind.received, 'inv2'),
        (InvoiceEventKind.declined, 'inv2'),
      ]);
      await sub.cancel();

      expect(await s.pairing.setAllowInvoices(shop.id, false), 0);
      expect((await s.pairing.pairing(shop.id))!.allowInvoices, isFalse);
    });

    test('pairing crosses the wire, events too', () async {
      final s = await openSession();
      expect(s.pairing.supported, isTrue);
      final events = <PairingEvent>[];
      final sub = s.pairing.events().listen(events.add);
      await settle();
      final invite = await s.pairing.makeInvite(name: 'Alex', expiry: const Duration(hours: 24), label: 'Anna');
      expect(invite.state, PairingState.pendingInvite);
      expect(invite.inviteLink, isNotNull);
      session.pairing.answerInvite(invite.id, name: 'Anna');
      await settle();
      expect(events.map((e) => e.kind), contains(PairingEventKind.replied));
      final paired = (await s.pairing.pairing(invite.id))!;
      expect(paired.state, PairingState.paired);
      expect(paired.sas, hasLength(sasWordCount));
      final verified = await s.pairing.checkWords(invite.id, PairingCheck.match);
      expect(verified!.state, PairingState.verified);
      expect((await s.pairing.setSeal(invite.id, false)).seal, SealMode.off);
      expect(await s.pairing.setAllowInvoices(invite.id, true), 0);
      await expectLater(
        s.pairing.makeInvite(name: '', expiry: const Duration(hours: 1)),
        throwsKind(WalletErrorKind.invalidArgument),
      );
      await s.pairing.removePairing(invite.id);
      expect(await s.pairing.pairings(), isEmpty);
      await sub.cancel();
    });

    test('every pairing call crosses, errors as the engine gave them', () async {
      final s = await openSession();
      final p = s.pairing;
      // A refusal from the engine still crossed the channel; only its kind matters here.
      Future<void> crossed(Future<Object?> Function() call) async {
        try {
          await call();
        } on WalletError catch (_) {}
      }

      final anna = session.pairing.seedPaired(name: 'Anna', paymentsAddress: serviceAddress, contactId: 'c1');
      await crossed(p.strays);
      await crossed(() => p.removeStray('none'));
      final invite = await p.makeInvite(name: 'Alex', expiry: const Duration(hours: 1));
      await crossed(() => p.cancelInvite(invite.id));
      await crossed(() => p.openReply('epiccash://pair-reply/1/x'));
      await crossed(() => p.confirmLink(anna.id));
      final preview = await p.openInvite(session.pairing.inviteLinkFrom(name: 'Tom'));
      expect(preview.name, 'Tom');
      await crossed(() => p.openWords(const ['a', 'b', 'c', 'd', 'e']));
      final answered = await p.acceptInvite(token: preview.token, name: 'Alex');
      await crossed(() => p.replyLink(answered.id));
      await crossed(() => p.openConfirm('epiccash://pair-confirm/1/x'));
      final card = await p.showCard(name: 'Alex');
      await crossed(() => p.scanCard(cardId: card.id, text: session.pairing.cardLinkFrom('Ola')));
      expect(await p.collect(), 0);
      expect((await p.attach(anna.id, 'c2')).contactId, 'c2');
      final changed = session.pairing.changeKeys(anna.id);
      expect((await p.resolveKeysChanged(changed.id, KeysChoice.keepOld)).id, anna.id);
      await crossed(() => p.requestPayment(id: anna.id, amount: BigInt.from(5)));
      await crossed(() => p.requestFile(amount: BigInt.from(5)));
      final sealed = await p.sealSlate(id: anna.id, slateJson: '{"id":"s1"}');
      expect((await p.openSlate(sealed)).slateJson, '{"id":"s1"}');
      await crossed(() => p.receiveSealed(sealed));
      await crossed(() => p.finalizeSealed(sealed));
      await crossed(() => p.paySealedRequest(sealed, amount: BigInt.from(5)));
      await crossed(() => p.sendViaMailbox(id: anna.id, amount: BigInt.from(5), minimumConfirmations: BigInt.from(10)));
      await crossed(() => p.plainSlate('none'));
      expect(await p.useImportedPairings(), 0);
      expect(await p.slateOf('none'), isNull);
    });

    test('invoices the wallet issues', () async {
      final s = await openSession();
      final events = <IssuerEvent>[];
      final sub = s.issuerEvents().listen(events.add);
      await settle();
      // A request goes to a paired contact; the issued invoice is the wallet's either way.
      final payer = session.pairing.seedPaired(name: 'Payer', paymentsAddress: payerAddress);
      final issued = await s.pairing.requestPayment(id: payer.id, amount: BigInt.from(500), message: 'lunch');
      expect(issued.state, IssuedInvoiceState.waiting);
      expect(issued.message, 'lunch');
      expect(issued.issuedAt, now);
      expect(session.issuedRequests.single.to, payerAddress);
      await expectLater(
        s.pairing.requestPayment(id: payer.id, amount: BigInt.zero),
        throwsKind(WalletErrorKind.invalidArgument),
      );
      expect(await s.issuedInvoices(), [issued]);
      expect(await s.issuedInvoice(slateId: issued.slateId), issued);
      expect(await s.issuedInvoice(slateId: 'none'), isNull);
      final withdrawn = await s.withdrawInvoice(slateId: issued.slateId);
      expect(withdrawn.state, IssuedInvoiceState.withdrawn);
      await expectLater(
        s.withdrawInvoice(slateId: issued.slateId),
        throwsKind(WalletErrorKind.invalidArgument),
      );
      expect(await s.drainPayments(), const PaymentsDrainReport());
      expect(session.drainPaymentCalls, 1);
      await settle();
      expect(events, [
        IssuerEvent(
          kind: IssuerEventKind.withdrawn,
          slateId: issued.slateId,
          payerAddress: payerAddress,
        ),
      ]);
      await sub.cancel();
    });
  });

  group('streams', () {
    test('cancelScan ends the scan stream here and stops the scan on the server', () async {
      final s = await openSession();
      final scan = StreamController<ScanProgress>();
      session.scanStream = scan.stream;
      final got = <ScanProgress>[];
      final done = s.scan().listen(got.add).asFuture<void>();
      scan.add(const ScanProgress(percent: 10, message: 'Scanning', finished: false));
      await settle();
      expect(got.map((e) => e.finished), [false]);
      s.cancelScan();
      await done;
      await settle();
      expect(session.scanCancels, 1);
      expect(got.map((e) => e.finished), [false]);
      // No scan running: nothing to stop.
      s.cancelScan();
      expect(session.scanCancels, 1);
      // A scan that ran to its end stops nothing on the server.
      session.scanStream = null;
      await s.scan().drain<void>();
      await settle();
      expect(session.scanCancels, 1);
      await scan.close();
    });

    test('deliver and end', () async {
      final s = await openSession();
      expect(
        await s.scan(startHeight: BigInt.from(77)).toList(),
        session.scanEvents,
      );
      expect(session.args['scan.startHeight'], BigInt.from(77));
      await s.scan().drain<void>();
      expect(session.args['scan.startHeight'], isNull);

      final events = await s.refresh(minimumConfirmations: BigInt.one).toList();
      expect(events.map((e) => e.percent), [5, 15, 60, 100]);
      expect(events.last.summary, session.summaryValue);
      expect(session.args['refresh'], BigInt.one);
      expect(channel.frames.where((f) => f['cancel'] == true), isEmpty);
    });

    test('fail with the kind kept, after the items before it', () async {
      final s = await openSession();
      session.refreshError = const WalletError(
        kind: WalletErrorKind.nodeUnreachable,
        message: 'node down',
      );
      final seen = <int>[];
      final error = Completer<Object>();
      s
          .refresh(minimumConfirmations: BigInt.one)
          .listen((e) => seen.add(e.percent), onError: error.complete);
      expect(
        await error.future,
        const WalletError(
          kind: WalletErrorKind.nodeUnreachable,
          message: 'node down',
        ),
      );
      expect(seen, [5, 15, 60]);

      session.invoicesSupported = false;
      await expectLater(
        s.invoiceEvents().toList(),
        throwsKind(WalletErrorKind.other),
      );
    });

    test('cancel reaches the server', () async {
      final s = await openSession();
      final got = <ListenerEvent>[];
      final sub = s.startListener().listen(got.add);
      await settle();
      expect(session.listenerStarts, 1);
      expect(session.listenerEvents.hasListener, true);
      const event = ListenerEvent(
        kind: ListenerEventKind.received,
        slateId: 'x',
        txId: 3,
        message: 'got it',
      );
      session.listenerEvents.add(event);
      await settle();
      expect(got, [event]);
      await sub.cancel();
      await settle();
      expect(channel.frames.last['cancel'], true);
      expect(session.listenerEvents.hasListener, false);
      await s.stopListener();
      expect(session.listenerStops, 1);
    });

    test(
      'an item that does not decode fails the stream and cancels it',
      () async {
        final (a, b) = loopbackPair();
        final c = RemoteWalletService(a);
        final server = <Map<String, Object?>>[];
        b.incoming.listen((t) {
          final f = jsonDecode(t) as Map<String, Object?>;
          server.add(f);
          if (f['m'] == 'openWithPin') {
            b.send(
              jsonEncode({
                'id': f['id'],
                'r': {'s': 'h', 'invoices': true},
              }),
            );
          } else if (f['m'] == 'scan') {
            b.send(
              jsonEncode({
                'id': f['id'],
                'ev': {'percent': 'x'},
              }),
            );
          }
        });
        final s = await c.openWithPin(
          config: config,
          pin: '1',
          sealedPassword: 'x',
        );
        await expectLater(s.scan().toList(), throwsKind(WalletErrorKind.other));
        await settle();
        expect(server.last['cancel'], true);
        await c.close();
      },
    );
  });

  group('a closed channel', () {
    test('fails pending calls and streams, and every later call', () async {
      final s = await openSession();
      fake.createGate = Completer<void>();
      final pending = client.create(
        config: const WalletConfig(
          dataDir: '/other',
          chain: Chain.floonet,
          nodeUrl: 'n',
          epicboxDomain: 'e',
          epicboxPort: 1,
        ),
        password: 'p',
      );
      final listener = s.startListener().toList();
      await settle();
      await channel.close();
      await expectLater(pending, throwsA(connectionClosed));
      await expectLater(listener, throwsA(connectionClosed));
      expect(client.closed, true);
      await expectLater(s.epicboxAddress(), throwsA(connectionClosed));
      await expectLater(s.scan().toList(), throwsA(connectionClosed));
      await expectLater(
        client.walletExists(config: config),
        throwsA(connectionClosed),
      );
      s.dispose();
      await dispatcher.done;
      // The server disposed the session it held for this socket.
      expect(session.disposeCalls, 1);
      // The wallet that opened after the socket went is disposed at once.
      fake.createGate!.complete();
      await settle();
      expect(session.disposeCalls, 2);
    });
  });

  test('every remote member went through the channel', () {
    final members = {
      for (final m in ServiceMember.values) m.name,
      for (final m in SessionMember.values) m.name,
    };
    expect(members.difference(sentMembers), isEmpty);
  });
}

final BigInt big = BigInt.parse('1000000000000000000000');
