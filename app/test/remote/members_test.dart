// SPDX-License-Identifier: Apache-2.0
// Every interface member is served: a member added to WalletService or WalletSession fails
// here until the protocol's member lists name it. The client then fails to compile until it
// implements the member, and the dispatcher's exhaustive switch until it serves it.

import 'dart:io';

import 'package:epic_wallet/src/remote/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

/// Member names declared in `abstract interface class <name>` of wallet_service.dart.
Set<String> interfaceMembers(String source, String name) {
  final start = source.indexOf('abstract interface class $name {');
  expect(start, isNot(-1), reason: 'interface $name not found');
  final end = source.indexOf('\n}', start);
  final body = source.substring(start, end);
  // Members start at two spaces; their wrapped parameters are indented further.
  final method = RegExp(r'^  [^ /].*?(\w+)\(', multiLine: true);
  final getter = RegExp(r'^  [^ /].* get (\w+);', multiLine: true);
  return {
    for (final m in method.allMatches(body)) m.group(1)!,
    for (final m in getter.allMatches(body)) m.group(1)!,
  };
}

void main() {
  final source = File('lib/src/wallet_service.dart').readAsStringSync();

  test('WalletService members are all served or answered locally', () {
    final members = interfaceMembers(source, 'WalletService');
    expect(members, contains('createWithPin'));
    expect(members, {
      for (final m in ServiceMember.values) m.name,
      ...localServiceMembers,
    });
  });

  test('WalletSession members are all served or answered locally', () {
    final members = interfaceMembers(source, 'WalletSession');
    expect(
      members,
      containsAll(['dispose', 'supportsInvoices', 'pairing']),
    );
    expect(members, {
      for (final m in SessionMember.values)
        if (!m.name.startsWith('pairing')) m.name,
      ...localSessionMembers,
      // Served as its pairing* members, below.
      'pairing',
    });
  });

  test('PairingApi members are all served, one pairing* member each', () {
    final pairing = File('lib/src/pairing_api.dart').readAsStringSync();
    // supported crosses with the session handle.
    final members = interfaceMembers(pairing, 'PairingApi')
      ..remove('supported')
      ..removeAll(localPairingMembers);
    expect(members, containsAll(['makeInvite', 'checkWords', 'events']));
    final served = [for (final m in SessionMember.values) if (m.name.startsWith('pairing')) m.name];
    expect(served, hasLength(members.length));
  });
}
