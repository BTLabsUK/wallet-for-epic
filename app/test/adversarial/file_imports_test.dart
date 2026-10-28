// SPDX-License-Identifier: Apache-2.0
// Files from outside: transaction files another app hands over, contacts files and history
// backups. A file's name and contents are the sender's to choose; reading one must never write
// outside the app's folders, crash, or quietly change who the user pays.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/contact_store.dart' show ContactFields;
import 'package:epic_wallet/src/contacts_file.dart';
import 'package:epic_wallet/src/history/export.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/legacy/gui_contacts.dart';
import 'package:epic_wallet/src/recipient.dart' show RecipientKind;
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

const _key = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK';
const _anna = '$_key@epicbox.epiccash.com';

final _checks = AddressChecks(epicbox: fakeEpicboxAddress, onion: onionAddressFormat);

/// Names a sending app could give a transaction file.
const _hostileNames = [
  '../../shared_prefs/x',
  '..',
  '../x.tx',
  '/etc/passwd',
  r'..\..\x.tx',
  r'C:\Users\x\x.tx',
  r'\\server\share\x.tx',
  'C:x.tx',
  'x.tx\u0000.png',
  'a/b/c.tx',
];

bool _plainName(String name) =>
    name.isNotEmpty &&
    !name.contains('/') &&
    !name.contains(r'\') &&
    !name.contains('\u0000') &&
    !name.contains(':') &&
    name != '.' &&
    name != '..';

void main() {
  group('transaction file names', () {
    for (final loaded in _hostileNames) {
      test('the_answer_to_a_file_named_${loaded.codeUnits.join('_')}_is_a_plain_file_name', () {
        final name = replyFileName('0123456789abcdef', loaded: loaded);
        expect(_plainName(name), isTrue, reason: name);
        expect(name, endsWith('.response'));
      });
    }

    test('a_shared_file_is_written_only_inside_the_share_folder', () async {
      final tmp = Directory.systemTemp.createTempSync('wfe-share-');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final shared = Directory('${tmp.path}${Platform.pathSeparator}shared');
      final written = <String>[];
      for (final name in _hostileNames.where((n) => !n.contains('\u0000'))) {
        await shareBytes(
          name: name,
          bytes: Uint8List.fromList([1]),
          tempDir: tmp,
          share: (p) async {
            written.add(File(p.files!.single.path).absolute.path);
            return const ShareResult('x', ShareResultStatus.success);
          },
        ).catchError((Object _) => false);
      }
      for (final path in written) {
        expect(File(path).parent.absolute.path, shared.absolute.path, reason: path);
      }
    });

    test('a_file_that_is_no_slate_is_refused_before_it_is_read_as_one', () {
      for (final bytes in <List<int>>[
        List.filled(maxSlateFileBytes + 1, 0x7b),
        [0xc0, 0xaf, 0x7b], // overlong UTF-8
        [0xef, 0xbb, 0xbf, ...utf8.encode('<html>')],
        utf8.encode('#!/bin/sh\nrm -rf ~'),
        utf8.encode('PK\u0003\u0004'),
        [],
      ]) {
        expect(() => decodeSlateFile(bytes), throwsFormatException);
      }
    });
  });

  group('contacts files', () {
    String file(List<Map<String, Object?>> rows) =>
        jsonEncode({'format': contactsFileFormat, 'version': 1, 'network': 'mainnet', 'contacts': rows});

    ContactsImportPlan plan(String json, List<ContactFields> saved) => planContactsFile(
      readContactsFile(utf8.encode(json)),
      saved,
      _checks,
      network: 'mainnet',
      otherChain: (_) => false,
    );

    test('hostile_json_is_refused_without_a_crash', () {
      for (final json in [
        '[' * 200000,
        '{"format":"epic-cash-contacts","version":1e400,"contacts":[]}',
        '{"format":"epic-cash-contacts","version":-1,"contacts":{}}',
        '{"format":"epic-cash-contacts","version":1,"contacts":[1]}',
        '{"format":"epic-cash-contacts","version":1,"contacts":[{"name":7}]}',
        '{"version":1,"contacts":"x"}',
        '{"format":"epic-cash-contacts","format":"x","version":1,"contacts":[]}',
      ]) {
        expect(() => readContactsFile(utf8.encode(json)), throwsA(isA<ContactsFileError>()), reason: json.substring(0, json.length.clamp(0, 60)));
      }
      expect(() => readContactsFile(List.filled(maxContactsFileBytes + 1, 0x20)), throwsA(isA<ContactsFileError>()));
    });

    test('names_and_notes_from_a_file_carry_no_direction_or_invisible_characters', () {
      final p = plan(file([
        {'name': 'Anna\u202Egnp.exe\u200B', 'epicbox': _anna, 'note': 'pay \u2066here\u2069 now'},
      ]), const []);
      final c = p.add.single;
      expect(c.name, isNot(contains(RegExp('[\u200B\u202A-\u202E\u2066-\u2069]'))));
      expect(c.note, isNot(contains(RegExp('[\u200B\u202A-\u202E\u2066-\u2069]'))));
    });

    test('a_contacts_file_never_renames_or_readdresses_a_saved_contact', () {
      const saved = ContactFields(id: 'c1', name: 'Anna', epicbox: _anna);
      final p = plan(file([
        {'name': 'Mallory', 'epicbox': _anna},
        {'name': 'Anna', 'epicbox': 'esZxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com'},
      ]), [saved]);
      for (final c in p.update) {
        expect(c.name, 'Anna');
        expect(c.epicbox, _anna);
      }
      // A second "Anna" with another address comes in as its own contact, never into the saved one.
      expect(p.update.where((c) => c.id == 'c1' && c.epicbox != _anna), isEmpty);
    });

    test('a_contacts_file_that_adds_a_payment_address_to_a_saved_contact_names_every_one', () {
      // Anna's Epicbox address is public: a file can name it to reach her saved contact. The
      // import may still add the kinds she lacks, but the confirm lists each address it adds,
      // and Send shows her pairing's badge only on the Epicbox address the pairing proves
      // (sendPairingFor), never on these.
      const saved = ContactFields(id: 'c1', name: 'Anna', epicbox: _anna);
      final tor = '${'a' * 55}d.onion';
      final p = plan(file([
        {'name': 'Anna', 'epicbox': _anna, 'http': 'https://pay.example.com', 'tor': tor},
      ]), [saved]);
      final added = {for (final a in p.addedToSaved) a.kind: (a.name, a.address)};
      expect(added.keys.toSet(), {RecipientKind.http, RecipientKind.tor});
      expect(added[RecipientKind.http], ('Anna', 'https://pay.example.com'));
      expect(added[RecipientKind.tor]!.$2, contains(tor.substring(0, 20)));
      // A new contact's own addresses are not "added to a saved one".
      final fresh = plan(file([
        {'name': 'Bob', 'http': 'https://bob.example.com'},
      ]), [saved]);
      expect(fresh.addedToSaved, isEmpty);
    });
  });

  group('history backups', () {
    Map<String, Object?> valid() => jsonDecode(utf8.decode(HistoryPayload(
      chain: 'Mainnet',
      walletFp: '00',
      exportedAtUnix: 1,
      appVersion: 't',
      txs: [
        Record(
          slateId: 's',
          kind: 'Sent',
          status: 'Confirmed',
          amountDebited: BigInt.from(5),
          fee: BigInt.one,
          blockHeight: BigInt.from(9),
          counterparty: 'x',
          outputCommits: ['08ab'],
          userFields: ['note'],
          slateMessages: [SlateMessageRec(role: 'sender', text: 'hi')],
        ),
      ],
      contacts: [ContactRec(id: 'c', name: 'n', epicbox: _anna)],
      favourites: ['c'],
      walletName: 'w',
    ).encode())) as Map<String, Object?>;

    const swaps = <Object?>[null, 1, -1, 1.5, 1e300, 'x', '', true, <Object?>[], <String, Object?>{}, 9223372036854775807];

    test('every_field_of_a_backup_with_the_wrong_type_is_an_error_never_a_crash', () {
      final base = valid();
      var cases = 0;
      void probe(Map<String, Object?> json, String where) {
        cases++;
        try {
          HistoryPayload.decode(utf8.encode(jsonEncode(json)));
        } on WalletError {
          // Refused with the old sentences: fine.
        } catch (e) {
          fail('$where: ${e.runtimeType}: $e');
        }
      }

      for (final k in base.keys) {
        for (final v in swaps) {
          probe({...base, k: v}, '$k=$v');
        }
      }
      final tx = (base['txs'] as List).single as Map<String, Object?>;
      for (final k in {...tx.keys, 'messages', 'payment_proof', 'num_inputs', 'user_edited_at_unix', 'pairing_id'}) {
        for (final v in swaps) {
          probe({...base, 'txs': [{...tx, k: v}]}, 'txs.$k=$v');
        }
      }
      final contact = (base['contacts'] as List).single as Map<String, Object?>;
      for (final k in contact.keys) {
        for (final v in swaps) {
          probe({...base, 'contacts': [{...contact, k: v}]}, 'contacts.$k=$v');
        }
      }
      expect(cases, greaterThan(300));
    });
  });
}
