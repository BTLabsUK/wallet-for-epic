import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/network.dart' show defaultEpicboxHost;
import 'package:epic_wallet/src/seed_contacts.dart';
import 'package:flutter_test/flutter_test.dart';

bool _epicbox(String a) => RegExp(r'^es[0-9A-Za-z]{50}@[\w.-]+$').hasMatch(a);

void main() {
  test('the bundled BT Labs contact is an Epicbox address on the default server', () {
    expect(bundledSeedContacts, [btLabsContact]);
    expect(_epicbox(btLabsContact.address), isTrue);
    expect(btLabsContact.address.split('@').last, defaultEpicboxHost);
  });

  test('the website file reads into contacts', () {
    final body = jsonEncode({
      'version': 1,
      'contacts': [
        {'id': 'btlabs', 'name': ' BT Labs ', 'address': btLabsContact.address, 'note': btLabsContact.note},
      ],
    });
    expect(parseSeedContacts(body, validAddress: _epicbox), [btLabsContact]);
  });

  test('entries with a bad address, a missing field or a repeated id are left out', () {
    final body = jsonEncode({
      'version': 1,
      'contacts': [
        {'id': 'btlabs', 'name': 'BT Labs', 'address': btLabsContact.address, 'note': ''},
        {'id': 'btlabs', 'name': 'Again', 'address': btLabsContact.address, 'note': ''},
        {'id': 'bad', 'name': 'Bad', 'address': 'not an address', 'note': ''},
        {'id': 'nonote', 'name': 'No note', 'address': btLabsContact.address},
        'text',
      ],
    });
    final got = parseSeedContacts(body, validAddress: _epicbox)!;
    expect(got.map((c) => c.id), ['btlabs']);
    expect(got.single.name, 'BT Labs');
  });

  test('a file that is not version 1 JSON changes nothing (null)', () {
    for (final body in ['', '<html>404</html>', '[]', '{"version":2,"contacts":[]}', '{"version":1}']) {
      expect(parseSeedContacts(body, validAddress: _epicbox), isNull, reason: body);
    }
  });

  test('the site file prepared for GitHub Pages matches the bundled list', () {
    final f = File('${Platform.environment['HOME']}/btlabs-epic-pages/contacts.json');
    if (!f.existsSync()) return; // Only on the machine that prepares the site.
    expect(parseSeedContacts(f.readAsStringSync(), validAddress: _epicbox), bundledSeedContacts);
  });
}
