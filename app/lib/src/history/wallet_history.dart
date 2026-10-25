/// Notes, contacts, imported records and history files of one open wallet, over the archive in
/// `meta_store.dart`. The core-neutral half of the old core's `Session` history calls: the
/// session hands in the live rows and does the sealing.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../contact_store.dart';
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

Contact _contact(ContactRec c) => Contact(
  id: c.id,
  name: c.name,
  epicbox: c.epicbox,
  http: c.http,
  tor: c.tor,
  note: c.note,
);

Contact _fromShared(ContactFields c) => Contact(
  id: c.id,
  name: c.name,
  epicbox: c.epicbox,
  http: c.http,
  tor: c.tor,
  note: c.note,
);

ContactRec _recOf(ContactFields c) => ContactRec(
  id: c.id,
  name: c.name,
  epicbox: c.epicbox,
  http: c.http,
  tor: c.tor,
  note: c.note,
);

String? _trimmed(String? s) {
  final t = s?.trim();
  return t == null || t.isEmpty ? null : t;
}

class WalletHistory {
  /// With [contacts], the address book is that store, shared by every wallet on the device
  /// (`contact_store.dart`), and this wallet's archive no longer holds it; without, the
  /// archive's own list (tests, and what older builds wrote).
  WalletHistory(this._store, {required this.chain, ContactStore? contacts})
    : _shared = contacts;

  /// History kept in memory only, for a session with no data directory (tests).
  WalletHistory.memory({this.chain = Chain.mainnet, ContactStore? contacts})
    : _store = MetaStore.memory(),
      _shared = contacts;

  /// Opens the archive in [dataDir].
  static Future<WalletHistory> open(String dataDir, Chain chain, {ContactStore? contacts}) async =>
      WalletHistory(await MetaStore.open(dataDir), chain: chain, contacts: contacts);

  final ContactStore? _shared;

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

  /// The keys [key]'s data may sit under: the key and every alias of its row no other row
  /// carries.
  List<String> _ownAliases(List<MergedTx> rows, String key) {
    final shared = sharedAliases(rows);
    return [
      for (final a
          in rows.where((m) => m.key == key).firstOrNull?.aliases ?? [key])
        if (a == key || !shared.contains(a)) a,
    ];
  }

  /// Takes [key]'s manual record out of [m], from under the key or an alias, so a change
  /// stores it under the key alone. A new one when there is none.
  static ManualRec _takeManual(Meta m, List<String> aliases) {
    ManualRec? found;
    for (final a in aliases) {
      final r = m.manual.remove(a);
      found ??= r;
    }
    return found ?? ManualRec();
  }

  static void _putManual(Meta m, String key, ManualRec rec) {
    if (!rec.isEmpty) m.manual[key] = rec;
  }

  int _nowUnix(DateTime? now) =>
      (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;

  /// Sets or removes (null or blank) the label of the transaction with [key]. At most
  /// [txLabelMaxLength] characters are kept.
  Future<void> setLabel(
    List<TxEntry> live,
    String key,
    String? label, {
    DateTime? now,
  }) {
    var text = label?.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text != null && text.runes.length > txLabelMaxLength) {
      text = String.fromCharCodes(text.runes.take(txLabelMaxLength));
    }
    final aliases = _ownAliases(merged(live), key);
    return _store.update((m) {
      final rec = _takeManual(m, aliases);
      final value = text == null || text.isEmpty ? null : text;
      if (rec.label != value) rec.editedAtUnix = _nowUnix(now);
      rec.label = value;
      _putManual(m, key, rec);
    });
  }

  /// Sets who paid, how and the note of the restored row [key]; each null or blank clears
  /// its field. Refused for any other row: what the wallet recorded is never overwritten.
  Future<void> setDetails(
    List<TxEntry> live,
    String key, {
    String? counterparty,
    String? transport,
    String? note,
    DateTime? now,
  }) {
    final rows = merged(live);
    final row = rows.where((m) => m.key == key).firstOrNull;
    if (row == null || row.source != TxSource.restored) {
      throw _invalid('only a payment found by a scan takes details');
    }
    String? some(String? s) {
      final t = s?.trim();
      return t == null || t.isEmpty ? null : t;
    }

    final via = some(transport);
    if (via != null && !txTransports.contains(via)) {
      throw _invalid('unknown method $via');
    }
    final from = some(counterparty), text = some(note);
    final aliases = _ownAliases(rows, key);
    return _store.update((m) {
      final rec = _takeManual(m, aliases);
      final notes = [for (final a in aliases) m.notes.remove(a)];
      final before = (rec.counterparty, rec.transport, notes.nonNulls.firstOrNull);
      rec
        ..counterparty = from
        ..transport = via;
      if (before != (from, via, text)) rec.editedAtUnix = _nowUnix(now);
      if (text != null) m.notes[key] = text;
      _putManual(m, key, rec);
    });
  }

  /// Address book, sorted by name.
  List<Contact> contacts() {
    final shared = _shared;
    if (shared != null) return [for (final c in shared.list()) _fromShared(c)];
    return [for (final c in meta.contacts) _contact(c)]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Adds (empty `id`) or replaces a contact. It needs a name and at least one address; each
  /// address is kept in its kind's field ([Contact.epicbox], [Contact.http], [Contact.tor]).
  Future<Contact> saveContact(Contact contact) async {
    final name = contact.name.trim();
    final epicbox = _trimmed(contact.epicbox);
    final http = _trimmed(contact.http);
    final tor = _trimmed(contact.tor);
    if (name.isEmpty) throw _invalid('the contact needs a name');
    // No address: a contact a pairing pays (RFC 0002, the mailbox is never an address).
    // Whether an address is valid is each screen's check, with the core's validators. Nothing
    // here reaches out.
    final isNew = contact.id.trim().isEmpty;
    final shared = _shared;
    if (shared != null) {
      return _fromShared(
        await shared.save(
          ContactFields(
            id: contact.id.trim(),
            name: name,
            epicbox: epicbox,
            http: http,
            tor: tor,
            note: _trimmed(contact.note),
          ),
        ),
      );
    }
    final rec = ContactRec(
      id: isNew ? _randomHex(16) : contact.id.trim(),
      name: name,
      epicbox: epicbox,
      http: http,
      tor: tor,
      note: _trimmed(contact.note),
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
      _shared?.delete(id) ??
      _store.update((m) => m.contacts.removeWhere((c) => c.id == id));

  /// What this install recorded of the invoice it approved under [slateId], or null.
  PaidInvoiceRec? paidInvoiceRecord(String slateId) =>
      meta.paidInvoices[slateId];

  /// Records how the reply of the invoice [slateId] went, replacing what was kept.
  Future<void> putPaidInvoice(
    String slateId,
    InvoiceStatus status, {
    String? kernelExcess,
  }) => _store.update(
    (m) => m.paidInvoices[slateId] = PaidInvoiceRec(
      status: status,
      kernelExcess: kernelExcess,
    ),
  );

  /// Moves the paid invoice [slateId] to [status], keeping [kernelExcess] once known. Returns
  /// false when this install paid no invoice under that id.
  Future<bool> setPaidInvoiceStatus(
    String slateId,
    InvoiceStatus status, {
    String? kernelExcess,
  }) => _store.update((m) {
    final r = m.paidInvoices[slateId];
    if (r == null) return false;
    r.status = status;
    r.kernelExcess = kernelExcess ?? r.kernelExcess;
    return true;
  });

  /// The state recorded for the invoice this wallet issued under [slateId], or null when
  /// none was: LEPIC's transaction then says what it can.
  IssuedInvoiceState? issuedInvoiceState(String? slateId) =>
      slateId == null ? null : meta.issuedInvoices[slateId]?.state;

  /// Records a newly issued invoice as waiting.
  Future<void> putIssuedInvoice(String slateId) => _store.update(
    (m) => m.issuedInvoices[slateId] = IssuedInvoiceRec(
      state: IssuedInvoiceState.waiting,
    ),
  );

  /// Moves the issued invoice [slateId] from waiting, or from no record, to [state]. Every
  /// other state is final, so a late event never turns a paid invoice into an expired one
  /// and a repeated one changes nothing. Returns whether it moved.
  Future<bool> settleIssuedInvoice(String slateId, IssuedInvoiceState state) =>
      _store.update((m) {
        final r = m.issuedInvoices[slateId];
        if (state == IssuedInvoiceState.waiting ||
            (r != null && r.state != IssuedInvoiceState.waiting)) {
          return false;
        }
        m.issuedInvoices[slateId] = IssuedInvoiceRec(state: state);
        return true;
      });

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
        if (!(m.source == TxSource.restored &&
            m.note == null &&
            m.manualFields.isEmpty))
          toRecord(m),
    ],
    contacts: switch (_shared) {
      final shared? => [for (final c in shared.list()) _recOf(c)],
      null => [for (final c in meta.contacts) ContactRec.fromJson(c.toJson())],
    },
  );

  /// Merges an opened history file of this wallet into the archive. A record known from an
  /// earlier import takes only what this file adds, so a second import changes nothing.
  ///
  /// What the user entered here (labels, notes, a restored row's sender and method) wins per
  /// field: the file fills only empty ones. Where it has another value, the field is a
  /// conflict. With [useBackup] null and any conflict, nothing is written and the report says
  /// `applied: false`; with [useBackup] (by [ImportConflict.id]) true takes the file's value,
  /// anything else keeps the user's and remembers the file's, so it never asks again.
  Future<ImportReport> importPayload(
    HistoryPayload payload,
    List<TxEntry> live, {
    required String walletFp,
    Map<String, bool>? useBackup,
    DateTime? now,
  }) async {
    if (payload.chain != chainName(chain)) {
      throw _invalid(historyOtherChain(payload.chain, chainName(chain)));
    }
    if (payload.walletFp != walletFp) throw _invalid(historyOtherWallet);
    final shown = merged(live);
    final at = _nowUnix(now);
    if (useBackup == null) {
      final trial = _importInto(meta.copy(), payload, live, shown, null, at);
      if (trial.conflicts.isNotEmpty) return trial;
    }
    final report = await _store.update(
      (m) => _importInto(m, payload, live, shown, useBackup ?? const {}, at),
    );
    final shared = _shared;
    if (shared == null || !report.applied) return report;
    // The file's contacts go to the shared address book, by the same rule.
    final added = await shared.update((list) {
      var n = 0;
      for (final c in payload.contacts) {
        final theirs = {
          for (final a in [c.epicbox, c.http, c.tor]) ?_trimmed(a),
        };
        if (c.name.trim().isEmpty) continue;
        // Without an address, the contact of a pairing: its id is what the pairing names.
        if (theirs.isEmpty && (c.id.isEmpty || list.any((e) => e.id == c.id))) continue;
        if (list.any((e) => e.addresses.any((a) => theirs.contains(a.trim())))) continue;
        final id = c.id.isEmpty || list.any((e) => e.id == c.id) ? _randomHex(16) : c.id;
        list.add(
          ContactFields(
            id: id,
            name: c.name.trim(),
            epicbox: _trimmed(c.epicbox),
            http: _trimmed(c.http),
            tor: _trimmed(c.tor),
            note: _trimmed(c.note),
          ),
        );
        n++;
      }
      return n;
    });
    return ImportReport(
      merged: report.merged,
      added: report.added,
      skipped: report.skipped,
      contactsAdded: added,
      conflicts: report.conflicts,
      applied: report.applied,
      replaced: report.replaced,
      pairingsAdded: report.pairingsAdded,
      pairingsOtherDevice: report.pairingsOtherDevice,
    );
  }

  /// The import itself, on [m]. With [useBackup] null it only finds conflicts: the report
  /// has them, `applied: false`, and [m] is a copy to throw away.
  ImportReport _importInto(
    Meta m,
    HistoryPayload payload,
    List<TxEntry> live,
    List<MergedTx> shown,
    Map<String, bool>? useBackup,
    int now,
  ) {
    var merged = 0, added = 0, skipped = 0, contactsAdded = 0;
    // Records whose user fields are applied once the rows are merged with the new records,
    // with the key of the row a record not kept in the archive goes to.
    final userData = <(Record, String?, {bool userOnly})>[];
    for (final r in payload.txs) {
      final identified =
          r.slateId != null ||
          r.kernelExcess != null ||
          r.outputCommits.isNotEmpty;
      if (!identified) {
        // A row a scan rebuilt, from a file with no commitments: it goes to the one scan row
        // of the same kind, block and amounts.
        userData.add((r, _scanRowFor(r, shown), userOnly: true));
        continue;
      }
      // A row a scan rebuilt, found again here by its commitments: only what the user added
      // travels; a record would turn the row into history from a backup.
      if (r.slateId == null && r.kernelExcess == null) {
        final row = shown
            .where(
              (t) =>
                  t.source == TxSource.restored &&
                  t.outputCommits.any(r.outputCommits.contains),
            )
            .firstOrNull;
        if (row != null) {
          userData.add((r, row.key, userOnly: true));
          continue;
        }
      }
      r.exportedAtUnix = payload.exportedAtUnix;
      userData.add((r, null, userOnly: false));
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
      m.records.add(r.withoutUserFields());
    }

    // The rows as they will show, so a record's user data lands on the row it now describes.
    final rows = mergeHistory(live, m);
    final shared = sharedAliases(rows);
    final conflicts = <ImportConflict>[];
    var replaced = 0;
    for (final (r, key, :userOnly) in userData) {
      final row = !userOnly
          ? _rowOf(r, rows)
          : key == null
          ? null
          : rows.where((t) => t.key == key || t.aliases.contains(key)).firstOrNull;
      if (row == null) {
        if (userOnly) skipped++;
        continue;
      }
      final aliases = [
        for (final a in row.aliases)
          if (a == row.key || !shared.contains(a)) a,
      ];
      final rec = _takeManual(m, aliases);
      final userNote = [for (final a in aliases) m.notes[a]].nonNulls.firstOrNull;
      final theirsManual = {
        for (final f in r.userFields) ?userFieldFrom(f),
        // A label is the user's by definition.
        ManualField.label,
      };
      final restored = row.source == TxSource.restored;
      var filled = false;

      String? clean(String? s) {
        final t = s?.trim();
        return t == null || t.isEmpty ? null : t;
      }

      final hash = declinedHash;

      /// One field: fill when empty, else a conflict unless equal or declined before.
      void field(
        ManualField f,
        String? mine,
        String? theirs,
        void Function(String value) write,
      ) {
        if (theirs == null || mine == theirs) return;
        if (mine == null) {
          write(theirs);
          filled = true;
          return;
        }
        if (rec.declined[f.name] == hash(theirs)) return;
        final c = ImportConflict(
          key: row.key,
          field: f,
          mine: mine,
          theirs: theirs,
          timeUnix: row.timeUnix,
          amount: netAmount(row.tx),
        );
        if (useBackup == null) {
          conflicts.add(c);
        } else if (useBackup[c.id] == true) {
          write(theirs);
          rec.declined.remove(f.name);
          replaced++;
        } else {
          rec.declined[f.name] = hash(theirs);
        }
      }

      final editedAt = r.userEditedAtUnix ?? now;
      field(ManualField.label, clean(rec.label), clean(r.label), (v) {
        rec.label = v;
        rec.editedAtUnix = editedAt;
      });
      if (restored && theirsManual.contains(ManualField.counterparty)) {
        field(
          ManualField.counterparty,
          clean(rec.counterparty),
          clean(r.counterparty),
          (v) {
            rec.counterparty = v;
            rec.editedAtUnix = editedAt;
          },
        );
      }
      if (restored && theirsManual.contains(ManualField.transport)) {
        final via = clean(r.transport);
        field(
          ManualField.transport,
          clean(rec.transport),
          via != null && txTransports.contains(via) ? via : null,
          (v) {
            rec.transport = v;
            rec.editedAtUnix = editedAt;
          },
        );
      }
      // A note the user typed here against the file's; with none here, the record's note
      // shows by itself, unless no record is kept for the row.
      final theirNote = clean(r.note);
      if (userNote != null || userOnly) {
        field(ManualField.note, userNote, theirNote, (v) {
          for (final a in aliases) {
            m.notes.remove(a);
          }
          m.notes[row.key] = v;
        });
      }
      _putManual(m, row.key, rec);
      if (userOnly) {
        if (filled) {
          merged++;
        } else {
          skipped++;
        }
      }
    }

    // A contact comes in unless one here already holds one of its addresses; with the shared
    // address book, [importPayload] adds them there.
    for (final c in _shared == null ? payload.contacts : const <ContactRec>[]) {
      final theirs = {
        for (final a in [c.epicbox, c.http, c.tor]) ?_trimmed(a),
      };
      if (m.contacts.any(
        (e) => [e.epicbox, e.http, e.tor].any(
          (a) => a != null && theirs.contains(a.trim()),
        ),
      )) {
        continue;
      }
      // Without an address, the contact of a pairing: its id is what the pairing names.
      if (theirs.isEmpty && (c.id.isEmpty || m.contacts.any((e) => e.id == c.id))) continue;
      final id = c.id.isEmpty || m.contacts.any((e) => e.id == c.id)
          ? _randomHex(16)
          : c.id;
      m.contacts.add(
        ContactRec(
          id: id,
          name: c.name,
          epicbox: c.epicbox,
          http: c.http,
          tor: c.tor,
          note: c.note,
                ),
      );
      contactsAdded++;
    }
    return ImportReport(
      merged: merged,
      added: added,
      skipped: skipped,
      contactsAdded: contactsAdded,
      conflicts: useBackup == null ? conflicts : const [],
      applied: useBackup != null || conflicts.isEmpty,
      replaced: replaced,
    );
  }

  /// Fields where the old wallet's history, now imported, records another sender or method
  /// than the user typed for the payment while it was a scan-found one. The recorded value
  /// shows until the user chooses; [ImportConflict.theirs] is the old wallet's. Labels and
  /// notes never conflict: the old wallet has none.
  List<ImportConflict> legacyConflicts(List<TxEntry> live) {
    final rows = merged(live);
    final shared = sharedAliases(rows);
    final bare = meta.copy()..manual.clear();
    final recorded = {for (final t in mergeHistory(live, bare)) t.key: t};
    final out = <ImportConflict>[];
    String? clean(String? s) {
      final t = s?.trim();
      return t == null || t.isEmpty ? null : t;
    }

    for (final row in rows) {
      final rec = manualOf(meta, row, shared);
      final own = recorded[row.key];
      if (rec == null || own == null || row.source == TxSource.restored) {
        continue;
      }
      void field(ManualField f, String? mine, String? theirs) {
        if (mine == null || theirs == null || mine == theirs) return;
        if (rec.declined[f.name] == declinedHash(theirs)) return;
        out.add(
          ImportConflict(
            key: row.key,
            field: f,
            mine: mine,
            theirs: theirs,
            timeUnix: row.timeUnix,
            amount: netAmount(row.tx),
          ),
        );
      }

      field(
        ManualField.counterparty,
        clean(rec.counterparty),
        clean(own.counterparty),
      );
      field(ManualField.transport, clean(rec.transport), clean(own.transport));
    }
    return out;
  }

  /// Applies the user's choices for [legacyConflicts] ([ImportConflict.id]; true takes the old
  /// wallet's value and drops the typed one, anything else keeps the typed one over exactly
  /// that value). Returns how many fields took the old wallet's value.
  Future<int> resolveLegacyConflicts(
    List<TxEntry> live,
    Map<String, bool> useOldWallet,
  ) async {
    final conflicts = legacyConflicts(live);
    if (conflicts.isEmpty) return 0;
    final rows = merged(live);
    final shared = sharedAliases(rows);
    var replaced = 0;
    await _store.update((m) {
      for (final c in conflicts) {
        final row = rows.firstWhere((t) => t.key == c.key);
        final aliases = [
          for (final a in row.aliases)
            if (a == row.key || !shared.contains(a)) a,
        ];
        final rec = _takeManual(m, aliases);
        if (useOldWallet[c.id] == true) {
          switch (c.field) {
            case ManualField.counterparty:
              rec.counterparty = null;
            case ManualField.transport:
              rec.transport = null;
            case ManualField.label || ManualField.note:
              break;
          }
          rec.declined.remove(c.field.name);
          replaced++;
        } else {
          rec.declined[c.field.name] = declinedHash(c.theirs);
        }
        _putManual(m, row.key, rec);
      }
    });
    return replaced;
  }

  /// The row [r] describes once merged: by slate id, kernel or commitment, of its own kind
  /// when both sides of a self-send match.
  MergedTx? _rowOf(Record r, List<MergedTx> rows) {
    final hits = [for (final t in rows) if (recordMatches(r, t)) t];
    final kind = kindFrom(r.kind);
    return hits.where((t) => t.kind == kind).firstOrNull ?? hits.firstOrNull;
  }

  /// The key of the only scan-rebuilt row [r] describes, by kind, block and amounts; null when
  /// there is none or more than one.
  String? _scanRowFor(Record r, List<MergedTx> shown) {
    final height = r.blockHeight;
    if (height == null) return null;
    final rows = [
      for (final t in shown)
        if (t.source == TxSource.restored &&
            t.kind == kindFrom(r.kind) &&
            t.blockHeight == height &&
            t.amountCredited == r.amountCredited &&
            t.amountDebited == r.amountDebited)
          t,
    ];
    return rows.length == 1 ? rows.single.key : null;
  }

  /// The transaction list as CSV, with [tip] the wallet's last confirmed height.
  String csv(List<TxEntry> live, BigInt? tip) =>
      historyCsv(transactions(live), tip);
}
