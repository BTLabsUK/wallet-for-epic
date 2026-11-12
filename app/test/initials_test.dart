// SPDX-License-Identifier: Apache-2.0
// Avatar letters on the phone and the desktop: letters and digits only (LNX-5).
import 'package:epic_wallet/src/desktop/widgets/data.dart' show EAvatar;
import 'package:epic_wallet/src/initials.dart';
import 'package:epic_wallet/src/ui/contact_page.dart' show contactInitials;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('brackets, punctuation and emoji never show', () {
    expect(nameInitials('Wallet (epic program)'), 'WE');
    expect(nameInitials('(Anna)'), 'AN');
    expect(nameInitials('🙂 Bob'), 'BO');
    expect(nameInitials('anna_kowalska'), 'AK');
    expect(nameInitials('Łukasz Żak'), 'ŁŻ');
    expect(nameInitials('Wallet 2'), 'W2');
    expect(nameInitials('(Anna)', count: 1), 'A');
    expect(nameInitials('🙂 !!'), '');
  });

  test('the phone rule: one word is its first and last letter', () {
    expect(nameInitials('Tom', phone: true), 'TM');
    expect(nameInitials('Bob', phone: true), 'BO');
    expect(nameInitials('Anna', phone: true), 'AN');
    expect(nameInitials('Mira Novak', phone: true), 'MN');
    expect(nameInitials('Northwind Exchange', phone: true), 'NE');
    expect(nameInitials('X', phone: true), 'X');
    expect(nameInitials('🙂 !!', phone: true), '');
    expect(nameInitials('Tom'), 'TO');
    expect(contactInitials('Tom'), 'TM');
  });

  test('the desktop avatar and the phone contact tile use them', () {
    expect(EAvatar.initials('Wallet (epic program)'), 'WE');
    expect(EAvatar.initials('Anna Kowalska'), 'AK');
    expect(EAvatar.initials('🙂'), '·');
    expect(contactInitials('Wallet (epic program)'), 'WE');
    expect(contactInitials('🙂'), '?');
  });
}
