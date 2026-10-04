/// Notes, contacts, imported records and history files of one open wallet, over the archive in
/// `meta_store.dart`. The core-neutral half of the old core's `Session` history calls: the
/// session hands in the live rows and does the sealing.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../wallet_service.dart';
import 'export.dart';
import 'merge.dart';
import 'meta_store.dart';

/// Public fingerprint of a wallet's seed, as the old core writes it in a history file: SHA-256
/// of the text of its Epicbox key (the part of [epicboxAddress] before `@`), first 16 bytes.
String walletFingerprint(String epicboxAddress) {
  final key = epicboxAddress.split('@').first;
  final digest = sha256.convert(utf8.encode(key)).bytes;
  return [for (final b in digest.take(16)) b.toRadixString(16).padLeft(2, '0')]
      .join();
}

String _randomHex(int bytes) {
  final r = Random.secure();
  return [
    for (var i = 0; i < bytes; i++)
      r.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}

WalletError _invalid(String message) =>
    WalletError(kind: WalletErrorKind.invalidArgument, message: message);

Contact _contact(ContactRec c) =>
    Contact(id: c.id, name: c.name, address: c.address, note: c.note);

class WalletHistory {
  WalletHistory(this._store, {required this.chain});

  /// History kept in memory only, for a session with no data directory (tests).
  WalletHistory.memory({this.chain = Chain.mainnet})
    : _store = MetaStore.memory();

  /// Opens the archive in [dataDir].
  static Future<WalletHistory> open(String dataDir, Chain chain) async =>
      WalletHistory(await MetaStore.open(dataDir), chain: chain);

  final MetaStore _store;

  /// The wallet's chain, named in exports and checked on import.
  final Chain chain;

  Meta get meta => _store.snapshot;

  void close() => _store.close();

  /// [live] merged with the archive, newest first.
  List<MergedTx> merged(List<TxEntry> live) => mergeHistory(live, meta);

  List<TxEntry> transactions(List<TxEntry> live) => [
    for (final m in merged(live)) m.tx,
  ];

  /// Sets or clears the note of the transaction with [key]. The note replaces any note the
  /// transaction had under another of its keys, but never one the other side of a self-send
  /// carries.
  Future<void> setNote(List<TxEntry> live, String key, String? note) {
    final text = note?.trim();
    final rows = merged(live);
    final shared = sharedAliases(rows);
    final aliases = [
      for (final a
          in rows.where((m) => m.key == key).firstOrNull?.aliases ?? [key])
        if (a == key || !shared.contains(a)) a,
    ];
    return _store.update((m) {
      aliases.forEach(m.notes.remove);
      if (text != null && text.isNotEmpty) m.notes[key] = text;
    });
  }

  /// Address book, sorted by name.
  List<Contact> contacts() =>
      [for (final c in meta.contacts) _contact(c)]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  /// Adds (empty `id`) or replaces a contact.
  Future<Contact> saveContact(Contact contact) async {
    final name = contact.name.trim();
    final address = contact.address.trim();
    if (name.isEmpty) throw _invalid('the contact needs a name');
    if (address.isEmpty) throw _invalid('the contact needs an address');
    // The wallet pays over epicbox and by file only (OD-2); the screen says so in words.
    final lower = address.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      throw _invalid(
        'a contact address must be an epicbox address, not a wallet URL',
      );
    }
    final isNew = contact.id.trim().isEmpty;
    final note = contact.note?.trim();
    final rec = ContactRec(
      id: isNew ? _randomHex(16) : contact.id.trim(),
      name: name,
      address: address,
      note: note == null || note.isEmpty ? null : note,
    );
    await _store.update((m) {
      final i = m.contacts.indexWhere((c) => c.id == rec.id);
      if (i >= 0) {
        m.contacts[i] = rec;
      } else if (isNew) {
        m.contacts.add(rec);
      } else {
        throw _invalid('no contact with id ${rec.id}');
      }
    });
    return _contact(rec);
  }

  Future<void> deleteContact(String id) =>
      _store.update((m) => m.contacts.removeWhere((c) => c.id == id));

  /// [addresses], the wallet's trusted invoice services, with the labels kept here. An address
  /// with no label here (the file was lost) comes back with none.
  List<TrustedService> trustedServices(List<String> addresses) => [
    for (final a in addresses)
      TrustedService(address: a, label: meta.serviceLabels[a.trim()]),
  ];

  /// Stores [label] for the service at [address]. A blank label is refused.
  Future<void> setServiceLabel(String address, String label) async {
    final text = label.trim();
    if (text.isEmpty) throw _invalid('the service needs a label');
    await _store.update((m) => m.serviceLabels[address.trim()] = text);
  }

  Future<void> removeServiceLabel(String address) =>
      _store.update((m) => m.serviceLabels.remove(address.trim()));

  /// The index of the current invoice address; 1 until the first rotation.
  int get invoiceIndex => meta.invoiceIndex ?? 1;

  /// Records a rotation to [index], which must be above the current one: an abandoned
  /// invoice address is never used again.
  Future<void> setInvoiceIndex(int index) async {
    if (index <= invoiceIndex) {
      throw _invalid('the invoice index only moves forward');
    }
    await _store.update((m) => m.invoiceIndex = index);
  }

  /// What an export of this wallet carries. A row a scan rebuilt with nothing added by the
  /// user comes back by itself after a restore, so it is left out.
  HistoryPayload exportPayload(
    List<TxEntry> live, {
    required String walletFp,
    required String appVersion,
    BigInt? lastConfirmedHeight,
    DateTime? now,
  }) => HistoryPayload(
    chain: chainName(chain),
    walletFp: walletFp,
    exportedAtUnix: (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000,
    appVersion: appVersion,
    lastConfirmedHeight: lastConfirmedHeight,
    txs: [
      for (final m in merged(live))
        if (!(m.source == TxSource.restored && m.note == null)) toRecord(m),
    ],
    contacts: [for (final c in meta.contacts) ContactRec.fromJson(c.toJson())],
    serviceLabels: {...meta.serviceLabels},
    invoiceIndex: meta.invoiceIndex,
  );

  /// Merges an opened history file of this wallet into the archive. A record known from an
  /// earlier import takes only what this file adds, so a second import changes nothing.
  Future<ImportReport> importPayload(
    HistoryPayload payload,
    List<TxEntry> live, {
    required String walletFp,
  }) {
    if (payload.chain != chainName(chain)) {
      throw _invalid(historyOtherChain(payload.chain, chainName(chain)));
    }
    if (payload.walletFp != walletFp) throw _invalid(historyOtherWallet);
    final shown = merged(live);
    return _store.update((m) {
      var merged = 0, added = 0, skipped = 0, contactsAdded = 0;
      for (final r in payload.txs) {
        final identified =
            r.slateId != null ||
            r.kernelExcess != null ||
            r.outputCommits.isNotEmpty;
        if (!identified) {
          skipped++;
          continue;
        }
        r.exportedAtUnix = payload.exportedAtUnix;
        final existing = m.records.where((e) => e.sameTx(r)).firstOrNull;
        if (existing != null) {
          // Known from an earlier import: take what this file adds.
          if (existing.mergeFrom(r)) {
            merged++;
          } else {
            skipped++;
          }
          continue;
        }
        final isLive = shown.any((t) => t.id != null && recordMatches(r, t));
        if (isLive) {
          merged++;
        } else {
          added++;
        }
        m.records.add(r.copy());
      }
      // A label set here wins over the file's; the index only moves forward, so an older
      // file never brings back an abandoned invoice address.
      payload.serviceLabels.forEach((a, l) {
        final address = a.trim(), label = l.trim();
        if (address.isNotEmpty && label.isNotEmpty) {
          m.serviceLabels.putIfAbsent(address, () => label);
        }
      });
      final index = payload.invoiceIndex;
      if (index != null && index > (m.invoiceIndex ?? 1)) {
        m.invoiceIndex = index;
      }
      for (final c in payload.contacts) {
        if (m.contacts.any((e) => e.address.trim() == c.address.trim())) {
          continue;
        }
        final id = c.id.isEmpty || m.contacts.any((e) => e.id == c.id)
            ? _randomHex(16)
            : c.id;
        m.contacts.add(
          ContactRec(id: id, name: c.name, address: c.address, note: c.note),
        );
        contactsAdded++;
      }
      return ImportReport(
        merged: merged,
        added: added,
        skipped: skipped,
        contactsAdded: contactsAdded,
      );
    });
  }

  /// The transaction list as CSV, with [tip] the wallet's last confirmed height.
  String csv(List<TxEntry> live, BigInt? tip) =>
      historyCsv(transactions(live), tip);
}
