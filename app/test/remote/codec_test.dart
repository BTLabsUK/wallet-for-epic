import 'dart:convert';
import 'dart:typed_data';

import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/remote/codec.dart';
import 'package:epic_wallet/src/remote/local_checks.dart';
import 'package:flutter_test/flutter_test.dart';

/// [value] through real JSON text and back. Compares the re-encoded form always, and the value
/// itself where the type's `==` is by value.
T roundTrip<T>(WireCodec<T> codec, T value, {bool byValue = true}) {
  final text = jsonEncode(codec.encode(value));
  final back = codec.decode(jsonDecode(text));
  expect(jsonEncode(codec.encode(back)), text, reason: codec.type);
  if (byValue) expect(back, value, reason: codec.type);
  return back;
}

Matcher throwsWire = throwsA(
  isA<WalletError>().having((e) => e.kind, 'kind', WalletErrorKind.other),
);

final BigInt big = BigInt.parse('123456789012345678901234567890');
final DateTime t1 = DateTime(2026, 10, 6, 9, 30, 15, 123);
final DateTime t2 = DateTime(2026, 10, 7, 9, 30, 15, 123);

WalletSummary summary() => WalletSummary(
  lastConfirmedHeight: BigInt.from(2500000),
  minimumConfirmations: BigInt.one,
  total: big,
  spendable: BigInt.from(5),
  awaitingConfirmation: BigInt.from(6),
  awaitingFinalization: BigInt.from(7),
  immature: BigInt.from(8),
  locked: BigInt.from(9),
  validatedWithNode: false,
);

TxEntry fullTx() => TxEntry(
  key: 's:abc',
  id: 4,
  slateId: 'abc',
  kind: TxKind.sentCancelled,
  status: TxStatus.cancelled,
  source: TxSource.imported,
  createdAtUnix: 1790000000,
  timeUnix: 1790000100,
  confirmed: false,
  blockHeight: BigInt.from(123),
  blockTimeUnix: 1790000200,
  amountCredited: BigInt.from(1),
  amountDebited: big,
  fee: BigInt.from(800000),
  numInputs: 2,
  numOutputs: 3,
  kernelExcess: '08ab',
  outputCommits: const ['09aa', '08bb'],
  counterparty: 'peer@relay',
  note: 'rent',
  messages: const [SlateMessage(role: SlateRole.receiver, text: 'hi ✓')],
  ttlCutoffHeight: BigInt.from(1440),
  cancellable: true,
  repostable: true,
  statusDetail: 'detail',
  releasable: true,
  finalizedAtUnix: 1790000300,
  cancelReason: CancelReason.lateAnswer,
  flow: TxFlow.invoice,
);

TxEntry bareTx() => TxEntry(
  key: 'l:1',
  kind: TxKind.coinbase,
  status: TxStatus.confirmed,
  source: TxSource.wallet,
  createdAtUnix: 1,
  timeUnix: 1,
  confirmed: true,
  amountCredited: BigInt.zero,
  amountDebited: BigInt.zero,
  numInputs: 0,
  numOutputs: 1,
  outputCommits: const [],
  cancellable: false,
  repostable: false,
  releasable: false,
);

void main() {
  group('round trip', () {
    test('scalars', () {
      roundTrip(stringWire, 'zażółć 中文 😀');
      roundTrip(intWire, -42);
      roundTrip(boolWire, true);
      roundTrip(bigIntWire, big);
      roundTrip(bigIntWire, -big);
      roundTrip(bigIntWire, BigInt.zero);
      expect(bigIntWire.encode(big), '123456789012345678901234567890');
      roundTrip(optBigInt, null);
      roundTrip(optString, null);
      roundTrip(optInt, 7);
      final bytes = Uint8List.fromList([0, 1, 254, 255, 128]);
      expect(roundTrip(bytesWire, bytes, byValue: false), bytes);
      expect(bytesWire.encode(bytes), base64Encode(bytes));
      expect(roundTrip(timeWire, t1), t1);
      expect(timeWire.encode(t1), t1.toUtc().millisecondsSinceEpoch);
      // A UTC time arrives as the same moment in local time.
      final utc = DateTime.utc(2026, 1, 1, 12);
      expect(timeWire.decode(timeWire.encode(utc)).isAtSameMomentAs(utc), true);
      expect(timeWire.decode(timeWire.encode(utc)).isUtc, false);
      voidWire.decode(jsonDecode(jsonEncode(voidWire.encode(null))));
    });

    test('every value of every enum, by name', () {
      void all<T extends Enum>(WireCodec<T> codec, List<T> values) {
        for (final v in values) {
          expect(codec.encode(v), v.name);
          roundTrip(codec, v);
        }
      }

      all(chainWire, Chain.values);
      all(cancelReasonWire, CancelReason.values);
      all(listenerEventKindWire, ListenerEventKind.values);
      all(slateRoleWire, SlateRole.values);
      all(slateStageWire, SlateStage.values);
      all(txKindWire, TxKind.values);
      all(txFlowWire, TxFlow.values);
      all(txSourceWire, TxSource.values);
      all(txStatusWire, TxStatus.values);
      all(peerCapabilityWire, PeerCapability.values);
      all(invoiceStatusWire, InvoiceStatus.values);
      all(invoiceEventKindWire, InvoiceEventKind.values);
      all(issuedInvoiceStateWire, IssuedInvoiceState.values);
      all(issuerEventKindWire, IssuerEventKind.values);
    });

    test('every model, with optional fields set and unset', () {
      for (final kind in WalletErrorKind.values) {
        roundTrip(walletErrorWire, WalletError(kind: kind, message: 'm $kind'));
      }
      roundTrip(
        walletConfigWire,
        const WalletConfig(
          dataDir: '/d',
          chain: Chain.floonet,
          nodeUrl: 'https://n',
          nodeApiSecret: 's',
          epicboxDomain: 'relay',
          epicboxPort: 443,
        ),
      );
      roundTrip(
        walletConfigWire,
        const WalletConfig(
          dataDir: '/d',
          chain: Chain.usernet,
          nodeUrl: 'http://127.0.0.1:1',
          epicboxDomain: 'relay',
          epicboxPort: 1,
        ),
      );
      roundTrip(
        contactWire,
        const Contact(id: '1', name: 'Ann', address: 'a@b', note: 'n'),
      );
      roundTrip(contactWire, const Contact(id: '', name: 'Ann', address: 'a'));
      roundTrip(feeEstimateWire, FeeEstimate(amount: big, fee: BigInt.two));
      roundTrip(
        importReportWire,
        const ImportReport(merged: 1, added: 2, skipped: 3, contactsAdded: 4),
      );
      roundTrip(
        listenerEventWire,
        ListenerEvent(
          kind: ListenerEventKind.received,
          slateId: 's',
          txId: 3,
          message: 'm',
          amount: big,
        ),
      );
      roundTrip(
        listenerEventWire,
        const ListenerEvent(kind: ListenerEventKind.stopped, message: ''),
      );
      roundTrip(
        nodeTipWire,
        NodeTip(height: BigInt.from(99), nodeVersion: '3.6.0'),
      );
      roundTrip(walletSummaryWire, summary());
      roundTrip(
        refreshProgressWire,
        RefreshProgress(
          percent: 100,
          message: 'Up to date',
          summary: summary(),
        ),
      );
      roundTrip(
        refreshProgressWire,
        const RefreshProgress(percent: 5, message: 'Checking'),
      );
      roundTrip(
        scanProgressWire,
        const ScanProgress(percent: 50, message: 'm', finished: false),
      );
      roundTrip(
        scanProgressWire,
        const ScanProgress(message: 'm', finished: true),
      );
      roundTrip(slateWire, const Slate(slateId: 's', json: '{"a":"\\n"}'));
      roundTrip(
        receivedSlateWire,
        const ReceivedSlate(slateId: 's', json: '{}', repeated: true),
      );
      roundTrip(
        slateMessageWire,
        const SlateMessage(role: SlateRole.sender, text: 't'),
      );
      roundTrip(
        slateInfoWire,
        SlateInfo(
          slateId: 's',
          amount: big,
          fee: BigInt.one,
          stage: SlateStage.response,
          messages: const [
            SlateMessage(role: SlateRole.sender, text: 'a'),
            SlateMessage(role: SlateRole.receiver, text: 'b'),
          ],
        ),
      );
      roundTrip(
        slateInfoWire,
        SlateInfo(
          slateId: 's',
          amount: BigInt.one,
          fee: BigInt.one,
          stage: SlateStage.send,
        ),
      );
      // TxEntry compares outputCommits by identity, so a decoded copy is never `==`; the
      // fields are checked through the re-encoding and here.
      final tx = roundTrip(txEntryWire, fullTx(), byValue: false);
      expect(tx.outputCommits, ['09aa', '08bb']);
      expect(tx.messages, fullTx().messages);
      expect(tx.cancelReason, CancelReason.lateAnswer);
      expect(tx.amountDebited, big);
      final bare = roundTrip(txEntryWire, bareTx(), byValue: false);
      expect(bare.id, isNull);
      expect(bare.fee, isNull);
      expect(bare.flow, TxFlow.payment);
      roundTrip(listOf(txEntryWire), [fullTx(), bareTx()], byValue: false);
      roundTrip(
        trustedServiceWire,
        const TrustedService(address: 'a@b', label: 'Shop'),
      );
      roundTrip(trustedServiceWire, const TrustedService(address: 'a@b'));
      roundTrip(
        pendingInvoiceWire,
        PendingInvoice(
          slateId: 's',
          senderAddress: 'a@b',
          amount: big,
          message: 'pay',
          receivedAt: t1,
          expiresAt: t2,
        ),
      );
      roundTrip(
        pendingInvoiceWire,
        PendingInvoice(
          slateId: 's',
          senderAddress: 'a@b',
          amount: big,
          receivedAt: t1,
          expiresAt: t2,
        ),
      );
      roundTrip(
        paidInvoiceWire,
        PaidInvoice(
          slateId: 's',
          senderAddress: 'a',
          amount: big,
          message: 'm',
          status: InvoiceStatus.posted,
          txId: 5,
          kernelExcess: '08',
        ),
      );
      roundTrip(
        paidInvoiceWire,
        PaidInvoice(
          slateId: 's',
          senderAddress: 'a',
          amount: big,
          status: InvoiceStatus.replyFailed,
        ),
      );
      roundTrip(nullable(paidInvoiceWire), null);
      roundTrip(
        invoiceEventWire,
        const InvoiceEvent(
          kind: InvoiceEventKind.posted,
          slateId: 's',
          kernelExcess: '08',
        ),
      );
      roundTrip(
        invoiceEventWire,
        const InvoiceEvent(kind: InvoiceEventKind.expired, slateId: 's'),
      );
      roundTrip(
        invoiceDrainReportWire,
        const InvoiceDrainReport(
          parked: 1,
          finalized: 2,
          dropped: 3,
          notices: 4,
        ),
      );
      roundTrip(
        issuedInvoiceWire,
        IssuedInvoice(
          slateId: 's',
          txId: 9,
          payerAddress: 'p',
          amount: big,
          message: 'm',
          issuedAt: t1,
          expiresAt: t2,
          state: IssuedInvoiceState.bounced,
        ),
      );
      roundTrip(
        issuedInvoiceWire,
        IssuedInvoice(
          slateId: 's',
          txId: 9,
          payerAddress: '',
          amount: big,
          issuedAt: t1,
          expiresAt: t2,
          state: IssuedInvoiceState.waiting,
        ),
      );
      roundTrip(nullable(issuedInvoiceWire), null);
      roundTrip(
        issuerEventWire,
        const IssuerEvent(
          kind: IssuerEventKind.paid,
          slateId: 's',
          payerAddress: 'p',
        ),
      );
      roundTrip(
        issuerEventWire,
        const IssuerEvent(kind: IssuerEventKind.expired, slateId: 's'),
      );
      roundTrip(
        paymentsDrainReportWire,
        const PaymentsDrainReport(received: 1, finalized: 2, bounced: 3),
      );
      roundTrip(sessionRefWire, (handle: 'h', invoices: true));
      roundTrip(pinWalletRefWire, (
        session: (handle: 'h', invoices: false),
        sealedPassword: 'sealed',
      ));
    });
  });

  group('a value that does not decode is a WalletError', () {
    test('scalars', () {
      expect(() => stringWire.decode(1), throwsWire);
      expect(() => stringWire.decode(null), throwsWire);
      expect(() => intWire.decode('1'), throwsWire);
      expect(() => intWire.decode(1.5), throwsWire);
      expect(() => boolWire.decode(0), throwsWire);
      expect(() => bigIntWire.decode(12), throwsWire);
      expect(() => bigIntWire.decode('1.5'), throwsWire);
      expect(() => bigIntWire.decode('0x10'), throwsWire);
      expect(() => bigIntWire.decode(''), throwsWire);
      expect(() => bytesWire.decode('not base64!'), throwsWire);
      expect(() => bytesWire.decode(3), throwsWire);
      expect(() => timeWire.decode('2026-10-06'), throwsWire);
      expect(() => timeWire.decode(8640000000000001), throwsWire);
      expect(() => chainWire.decode('moonnet'), throwsWire);
      expect(() => chainWire.decode(0), throwsWire);
      expect(() => listOf(stringWire).decode('a'), throwsWire);
      expect(() => listOf(stringWire).decode([1]), throwsWire);
    });

    test('objects name the field', () {
      final wire = walletSummaryWire.encode(summary()) as Map<String, Object?>;
      expect(() => walletSummaryWire.decode([wire]), throwsWire);
      expect(
        () => walletSummaryWire.decode({...wire}..remove('total')),
        throwsA(
          isA<WalletError>().having(
            (e) => e.message,
            'message',
            contains('WalletSummary.total'),
          ),
        ),
      );
      final tx = txEntryWire.encode(fullTx()) as Map<String, Object?>;
      expect(() => txEntryWire.decode({...tx, 'kind': 'gift'}), throwsWire);
      expect(
        () => txEntryWire.decode({
          ...tx,
          'messages': [
            {'role': 'sender'},
          ],
        }),
        throwsWire,
      );
      expect(() => sessionRefWire.decode({'s': 1}), throwsWire);
    });

    test('an unknown error kind reads as other, with its message', () {
      expect(
        walletErrorWire.decode({'kind': 'fromTheFuture', 'message': 'x'}),
        const WalletError(kind: WalletErrorKind.other, message: 'x'),
      );
    });
  });

  group('local checks', () {
    test('mnemonic checksum, word count and words, as BIP-39', () {
      final abandon = List.filled(11, 'abandon');
      expect(validMnemonic([...abandon, 'about'].join(' ')), true);
      expect(
        validMnemonic('${List.filled(23, 'abandon').join(' ')} art'),
        true,
      );
      expect(validMnemonic('${List.filled(11, 'zoo').join(' ')} wrong'), true);
      expect(
        validMnemonic(
          '  Abandon\t${[...abandon.skip(1), 'ABOUT'].join('  ')} ',
        ),
        true,
      );
      expect(validMnemonic([...abandon, 'abandon'].join(' ')), false);
      expect(validMnemonic([...abandon, 'zzzz'].join(' ')), false);
      expect(validMnemonic(List.filled(23, 'abandon').join(' ')), false);
      expect(validMnemonic(List.filled(27, 'abandon').join(' ')), false);
      expect(validMnemonic(''), false);
    });

    test('epicbox address format with the relay required', () {
      final key = 'es${'A' * 50}';
      expect(epicboxAddressFormat('$key@epicbox.epiccash.com'), true);
      expect(epicboxAddressFormat('epicbox://$key@relay:443'), true);
      expect(epicboxAddressFormat('$key@relay:65535'), true);
      expect(epicboxAddressFormat('$key@relay:65536'), false);
      expect(epicboxAddressFormat(key), false);
      expect(epicboxAddressFormat('${key}0@relay'), false);
      expect(epicboxAddressFormat('${key.substring(1)}@relay'), false);
      expect(epicboxAddressFormat('es${'0' * 50}@relay'), false);
      expect(epicboxAddressFormat('$key@re-lay'), false);
      expect(epicboxAddressFormat('$key@'), false);
      expect(epicboxAddressFormat('https://wallet.example'), false);
    });
  });
}
