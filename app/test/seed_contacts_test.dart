// SPDX-License-Identifier: Apache-2.0
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/btlabs_keys.dart';
import 'package:epic_wallet/src/btlabs_public.dart';
import 'package:epic_wallet/src/network.dart' show defaultEpicboxHost;
import 'package:epic_wallet/src/seed_contacts.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/btlabs_public_file.dart';

bool _epicbox(String a) => RegExp(r'^es[0-9A-Za-z]{50}@[\w.-]+$').hasMatch(a);

void main() {
  test('the bundled BT Labs contact is an Epicbox address on the default server', () {
    expect(bundledSeedContacts, [btLabsContact]);
    expect(_epicbox(btLabsContact.address), isTrue);
    expect(btLabsContact.address.split('@').last, defaultEpicboxHost);
  });

  test('the signed file reads into the bundled contact, keeping its name and note', () async {
    final file = await verified(await signedPublicFile([donation('btlabs', btLabsContact.address, name: 'Other', note: 'Send me money')]));
    expect(seedContactsFrom(file, validAddress: _epicbox), [btLabsContact]);
  });

  group('a donation that does not qualify is left out', () {
    final cases = <String, Map<String, Object?>>{
      'a bad address': donation('btlabs', 'notanaddress'),
      'another coin': donation('btlabs', btLabsContact.address, coin: 'btc'),
      'another network': donation('btlabs', btLabsContact.address, network: 'floonet'),
      'another method': donation('btlabs', btLabsContact.address, method: 'other'),
    };
    for (final e in cases.entries) {
      test(e.key, () async {
        final file = await verified(await signedPublicFile([e.value]));
        expect(seedContactsFrom(file, validAddress: _epicbox), isEmpty);
      });
    }
  });

  test('an id the app does not ship is ignored, even with a valid address', () async {
    final file = await verified(
      await signedPublicFile([donation('someone', btLabsContact.address), donation('btlabs', btLabsContact.address)]),
    );
    expect(seedContactsFrom(file, validAddress: _epicbox), [btLabsContact]);
  });

  test('the address is checked with the validator it is given', () async {
    final file = await verified(await signedPublicFile([donation('btlabs', btLabsContact.address)]));
    expect(seedContactsFrom(file, validAddress: (_) => false), isEmpty);
  });

  test('the bundled keyring parses and holds the keys of rank 1 and 2', () {
    expect(btlabsKeyring.keys.map((k) => k.rank).toList()..sort(), [1, 2]);
    expect(jsonDecode(btlabsKeyringJson)['keys'], hasLength(2));
  });

  test('the prepared site file verifies against the bundled keyring and yields the bundled list', () async {
    final f = File('${Platform.environment['HOME']}/code/btlabs-public/site/btlabs.json');
    if (!f.existsSync()) return markTestSkipped('btlabs-public is not on this machine');
    final r = await verifyBtlabsPublic(f.readAsStringSync(), keyring: btlabsKeyring, now: DateTime.now().toUtc());
    expect(r, isA<Accepted<BtlabsPublic>>());
    expect(seedContactsFrom((r as Accepted<BtlabsPublic>).manifest, validAddress: _epicbox), bundledSeedContacts);
  });
}
