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

  test('the desktop avatar and the phone contact tile use them', () {
    expect(EAvatar.initials('Wallet (epic program)'), 'WE');
    expect(EAvatar.initials('Anna Kowalska'), 'AK');
    expect(EAvatar.initials('🙂'), '·');
    expect(contactInitials('Wallet (epic program)'), 'WE');
    expect(contactInitials('🙂'), '?');
  });
}
