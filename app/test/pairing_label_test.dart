// SPDX-License-Identifier: Apache-2.0
// The short label of an unnamed wallet: the first characters of its address, after the prefix
// every address shares, so a user can match it by eye with a link or address they copied.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/wallet_service.dart' show PairingRecord, PairingState, PairingWay;
import 'package:epic_wallet/src/pairing_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

// A mainnet Epicbox key: `es` then base58.
const _key = 'esA7F3xyQpLmN2vR8tUwZ4cB6dEfGhJkMnPqRsTuVwXyZ';

void main() {
  group('walletTag', () {
    test('the first 6 characters after the shared es prefix, case kept, relay ignored', () {
      expect(walletTag(_key), 'A7F3xy');
      expect(walletTag('$_key@epicbox.epiccash.com'), 'A7F3xy');
      expect(walletTag('  $_key@relay.example.org:443 '), 'A7F3xy');
    });

    test('an epic1 address drops its epic1 prefix', () {
      expect(walletTag('epic1qq3w8v2k9s0zp'), 'qq3w8v');
      expect(walletTag('EPIC1QQ3W8V2K9S0ZP'), 'QQ3W8V');
    });

    test('a key that is not an es key shows its own start', () {
      expect(walletTag('xyz123abcdef'), 'xyz123');
    });

    test('nothing, or too little to tell wallets apart: null', () {
      expect(walletTag(null), isNull);
      expect(walletTag(''), isNull);
      expect(walletTag('@relay.example.org'), isNull);
      expect(walletTag('es123'), isNull);
      expect(walletTag('epic1abc'), isNull);
    });
  });

  group('the label', () {
    test('unnamedPeerLabel: Wallet and the tag; Unnamed wallet while the address is unknown', () {
      expect(unnamedPeerLabel(_l, '$_key@epicbox.epiccash.com'), 'Wallet A7F3xy');
      expect(unnamedPeerLabel(_l, null), _l.pairUnnamed);
    });

    PairingRecord record({String? name, String? label, String? paymentsAddress, String? expectAddress}) => PairingRecord(
      id: 'p',
      state: PairingState.waiting,
      way: PairingWay.link,
      inviter: false,
      createdAt: DateTime(2026, 11, 14),
      name: name,
      label: label,
      paymentsAddress: paymentsAddress,
      expectAddress: expectAddress,
    );

    test('peerLabel: the user\'s label, then the claimed name, then the address label', () {
      const address = '$_key@epicbox.epiccash.com';
      expect(peerLabel(_l, record(name: unnamedPeerName, paymentsAddress: address)), 'Wallet A7F3xy');
      expect(peerLabel(_l, record(name: 'Anna', paymentsAddress: address)), 'Anna');
      expect(peerLabel(_l, record(name: unnamedPeerName, label: 'Mum', paymentsAddress: address)), 'Mum');
      expect(peerLabel(_l, record(name: unnamedPeerName)), _l.pairUnnamed, reason: 'no address known yet');
    });

    test('pairingPeerAddress: the proven address, else the one a request used', () {
      const proven = '$_key@epicbox.epiccash.com';
      expect(pairingPeerAddress(record(paymentsAddress: proven, expectAddress: 'esOther@x')), proven);
      expect(pairingPeerAddress(record(expectAddress: proven)), proven);
      expect(pairingPeerAddress(record()), isNull);
      expect(peerLabel(_l, record(name: unnamedPeerName, expectAddress: proven)), 'Wallet A7F3xy');
    });
  });
}
