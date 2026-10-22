import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/btlabs_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the bundled keyring holds the two BT Labs keys, ranks 1 and 2', () {
    expect(btlabsKeyring.keys.map((k) => (k.keyid, k.rank)), [('3eb30c1e66220525', 1), ('f261b50cdc4dae34', 2)]);
  });

  // Only on a machine with the btlabs-public checkout: the bundled copy must equal its keyring.
  final source = File('${Platform.environment['HOME']}/code/btlabs-public/keys/btlabs-keyring.json');
  test(
    'the bundled keyring equals btlabs-public keys/btlabs-keyring.json',
    () => expect(jsonDecode(btlabsKeyringJson), jsonDecode(source.readAsStringSync())),
    skip: source.existsSync() ? false : 'no ~/code/btlabs-public checkout',
  );
}
