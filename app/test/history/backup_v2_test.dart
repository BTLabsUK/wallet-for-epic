// SPDX-License-Identifier: Apache-2.0
// Version 2 of the history file: invoices both ways, the pairing and slate messages of each
// payment, the wallet's name and the app's settings; the shared address book as a whole; and
// version 1 files, which still open. Sealing is LEPIC's and runs in
// integration_test/history_test.dart.
import 'dart:convert';

import 'package:epic_wallet/src/contact_store.dart';
import 'package:epic_wallet/src/history/export.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _bob = 'esWNvLomAJ2SHT6CU1F4ok2URGQnmUmCAp9XNwEP4N8JS4Ve8qcx@epicbox.example.com';
const _eve = 'esYx3bAVZBNQkV2aZbPRgqQrPkmLuRtAnoG6SLkNmLrFqbu2wWMS@epicbox.example.com';

/// A request this wallet issued to the paired contact `p1`, paid.
TxEntry _request() => fakeTx(
  key: 's:inv1',
  id: 4,
  slateId: 'inv1',
  kind: TxKind.received,
  status: TxStatus.confirmed,
  blockHeight: BigInt.from(30),
  amountCredited: BigInt.from(250000000),
  outputCommits: const ['req-out'],
  flow: TxFlow.invoice,
  pairingId: 'p1',
  messages: const [SlateMessage(role: SlateRole.receiver, text: 'March hosting')],
);

/// An invoice this wallet paid.
TxEntry _paid() => fakeTx(
  key: 's:inv2',
  id: 5,
  slateId: 'inv2',
  kind: TxKind.sent,
  status: TxStatus.confirmed,
  blockHeight: BigInt.from(31),
  amountDebited: BigInt.from(500000000),
  amountCredited: BigInt.from(100000000),
  fee: BigInt.from(700000),
  flow: TxFlow.invoice,
  counterparty: _eve,
  transport: 'epicbox',
  messages: const [SlateMessage(role: SlateRole.receiver, text: 'Order 17')],
);

/// A request still open when the backup was made.
TxEntry _open() => fakeTx(
  key: 's:inv3',
  id: 6,
  slateId: 'inv3',
  kind: TxKind.received,
  status: TxStatus.awaitingConfirmation,
  amountCredited: BigInt.from(10000000),
  flow: TxFlow.invoice,
  counterparty: _bob,
);

void main() {
  test('a version 2 payload round trips its new fields', () {
    final payload = HistoryPayload(
      chain: 'Mainnet',
      walletFp: 'fp',
      exportedAtUnix: 9,
      appVersion: 't',
      txs: [
        Record(
          slateId: 's',
          kind: 'Received',
          status: 'Confirmed',
          flow: 'invoice',
          pairingId: 'p1',
          slateMessages: [SlateMessageRec(role: 'receiver', text: 'hi')],
        ),
      ],
      issuedInvoices: {'s': IssuedInvoiceRec(state: IssuedInvoiceState.paid)},
      paidInvoices: {'t': PaidInvoiceRec(status: InvoiceStatus.posted, kernelExcess: '08')},
      walletName: 'Savings',
      settings: {'v': 1, 'theme': 'dark'},
    );
    final json = jsonDecode(utf8.decode(payload.encode())) as Map<String, dynamic>;
    expect(json['version'], 2);
    expect(json['wallet'], {'name': 'Savings'});
    expect((json['txs'] as List).single['flow'], 'invoice');
    final back = HistoryPayload.decode(payload.encode());
    expect(back.txs.single.pairingId, 'p1');
    expect(back.txs.single.slateMessages.single.text, 'hi');
    expect(back.issuedInvoices['s']!.state, IssuedInvoiceState.paid);
    expect(back.paidInvoices['t']!.kernelExcess, '08');
    expect(back.walletName, 'Savings');
    expect(back.settings, {'v': 1, 'theme': 'dark'});
    // Nothing secret or seed-derived has a field to land in.
    for (final k in ['seed', 'phrase', 'mnemonic', 'password', 'pin', 'epicbox_address', 'onion']) {
      expect(json.containsKey(k), isFalse, reason: k);
    }
  });

  test('a version 1 file (26.10.x) still opens and imports', () async {
    // As 26.10.x wrote it: version 1, no invoices, no settings.
    final v1 = utf8.encode(
      '{"format":"wfe-history","version":1,"chain":"Mainnet","wallet_fp":"fp",'
      '"exported_at_unix":5,"app_version":"26.10.16","last_confirmed_height":40,'
      '"txs":[{"slate_id":"a","kind":"Sent","status":"Confirmed","confirmed":true,'
      '"created_at_unix":1790000000,"amount_credited":0,"amount_debited":300,'
      '"num_inputs":1,"num_outputs":1,"output_commits":[],"note":"rent","label":"Flat"}],'
      '"contacts":[{"id":"c1","name":"Bob","address":"$_bob"}],"favourites":["c1"]}',
    );
    final p = HistoryPayload.decode(v1);
    expect((p.version, p.settings, p.walletName, p.issuedInvoices.length), (1, null, null, 0));
    final h = WalletHistory.memory();
    final r = await h.importPayload(p, const [], walletFp: 'fp');
    expect((r.added, r.contactsAdded, r.starsAdded, r.notesAdded, r.labelsAdded), (1, 1, 1, 1, 1));
    final row = h.transactions(const []).single;
    expect((row.note, row.label, row.flow), ('rent', 'Flat', TxFlow.payment));
  });

  group('invoices', () {
    test('come back after a restore with their message, contact and end', () async {
      final before = WalletHistory.memory();
      await before.putIssuedInvoice('inv1');
      await before.settleIssuedInvoice('inv1', IssuedInvoiceState.paid);
      await before.putIssuedInvoice('inv3');
      await before.putPaidInvoice('inv2', InvoiceStatus.posted, kernelExcess: 'k2');
      final live = [_request(), _paid(), _open()];
      await before.setNote(live, 's:inv2', 'Shop order');
      final file = HistoryPayload.decode(before.exportPayload(live, walletFp: 'fp', appVersion: 't').encode());

      // Restored from the phrase: the scan found the request's output only.
      final scan = [
        fakeTx(
          key: 'c:req-out',
          id: 1,
          source: TxSource.restored,
          status: TxStatus.confirmed,
          blockHeight: BigInt.from(30),
          amountCredited: BigInt.from(250000000),
          outputCommits: const ['req-out'],
        ),
      ];
      final after = WalletHistory.memory();
      final report = await after.importPayload(file, scan, walletFp: 'fp');
      expect(report.invoicesAdded, 3);
      // The note travels inside the paid invoice's record, and the summary counts it.
      expect(report.notesAdded, 1);
      final rows = after.transactions(scan);
      final req = rows.firstWhere((t) => t.slateId == 'inv1');
      expect((req.flow, req.pairingId, req.isRequest), (TxFlow.invoice, 'p1', true));
      expect(messageBy(req.messages, SlateRole.receiver), 'March hosting');
      final paid = rows.firstWhere((t) => t.slateId == 'inv2');
      expect((paid.flow, paid.counterparty, paid.transport, paid.note), (TxFlow.invoice, _eve, 'epicbox', 'Shop order'));
      // The request's output was found by the scan: its row has the scan's id, yet it is the
      // backup's request, never one LEPIC could act on.
      expect((req.id, req.source), (1, TxSource.imported));
      expect(paidInvoiceOf(paid, status: after.paidInvoiceRecord('inv2')!.status)!.txId, isNull);
      expect(after.paidInvoiceRecord('inv2')!.status, InvoiceStatus.posted);

      // The Invoices list shows the ended request, never as something to withdraw; the one
      // still open at export is left to its history row.
      final listed = requestsOf(rows, after.issuedInvoiceState);
      expect(listed.map((i) => (i.slateId, i.state, i.withdrawable)), [('inv1', IssuedInvoiceState.paid, false)]);
      expect((listed.single.pairingId, listed.single.txId), ('p1', null));

      // A second import changes nothing.
      final again = await after.importPayload(file, scan, walletFp: 'fp');
      expect((again.invoicesAdded, again.added), (0, 0));
    });

    test('a request paid by file, still recorded as waiting, is listed as paid', () async {
      final before = WalletHistory.memory();
      await before.putIssuedInvoice('inv1');
      final file = HistoryPayload.decode(before.exportPayload([_request()], walletFp: 'fp', appVersion: 't').encode());
      final after = WalletHistory.memory();
      await after.importPayload(file, const [], walletFp: 'fp');
      final listed = requestsOf(after.transactions(const []), after.issuedInvoiceState);
      expect(listed.map((i) => (i.slateId, i.state, i.txId)), [('inv1', IssuedInvoiceState.paid, null)]);
    });

    test('what this install recorded wins over the file', () async {
      final h = WalletHistory.memory();
      await h.putIssuedInvoice('inv1');
      await h.settleIssuedInvoice('inv1', IssuedInvoiceState.withdrawn);
      final file = HistoryPayload(
        chain: 'Mainnet',
        walletFp: 'fp',
        exportedAtUnix: 1,
        appVersion: 't',
        issuedInvoices: {'inv1': IssuedInvoiceRec(state: IssuedInvoiceState.paid)},
      );
      expect((await h.importPayload(file, const [], walletFp: 'fp')).invoicesAdded, 0);
      expect(h.issuedInvoiceState('inv1'), IssuedInvoiceState.withdrawn);
    });
  });

  test('a file of another wallet is refused before anything is written', () async {
    final h = WalletHistory.memory();
    final file = HistoryPayload(chain: 'Mainnet', walletFp: 'other', exportedAtUnix: 1, appVersion: 't',
        contacts: [ContactRec(id: 'c', name: 'X', address: _bob)]);
    await expectLater(h.importPayload(file, const [], walletFp: 'fp'), throwsA(isA<WalletError>()));
    expect(h.contacts(), isEmpty);
  });

  test('the whole shared address book travels and merges back by address', () async {
    final book = ContactStore.memory();
    // Contacts no payment of this wallet names: the book is the device's, all of it goes.
    final bob = await book.save(const ContactFields(name: 'Bob', epicbox: _bob));
    await book.save(const ContactFields(name: 'Eve', epicbox: _eve, note: 'shop'));
    final h = WalletHistory.memory(contacts: book);
    await h.setFavourite(bob.id, true);
    final file = HistoryPayload.decode(h.exportPayload(const [], walletFp: 'fp', appVersion: 't').encode());
    expect(file.contacts.map((c) => c.name), ['Bob', 'Eve']);
    expect(file.favourites, [bob.id]);

    // Another device: Bob is there already under another name, with no note.
    final other = ContactStore.memory();
    await other.save(const ContactFields(name: 'Robert', epicbox: _bob));
    final restored = WalletHistory.memory(contacts: other);
    final r = await restored.importPayload(file, const [], walletFp: 'fp');
    expect(r.contactsAdded, 1);
    expect(other.list().map((c) => (c.name, c.note)), [('Eve', 'shop'), ('Robert', null)]);
    // The star finds Bob by his address.
    final robert = other.list().firstWhere((c) => c.name == 'Robert');
    expect(restored.favourites(), {robert.id});
    expect(r.starsAdded, 1);
  });
}
