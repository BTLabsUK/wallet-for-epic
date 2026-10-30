// SPDX-License-Identifier: Apache-2.0
// The Windows data folder access list (owner_only_windows.dart), with the programs faked: the
// order of the steps is what keeps the user from being locked out of their own wallets.

import 'dart:io';

import 'package:epic_wallet/src/owner_only_windows.dart';
import 'package:flutter_test/flutter_test.dart';

const _profile = r'C:\Users\rig';
const _folder = r'C:\Users\rig\.epic_cash_desktop';
const _sid = 'S-1-5-21-1004336348-1177238915-682003330-1001';

class _Fake {
  _Fake({this.listing = 'NT AUTHORITY\\SYSTEM:(I)(OI)(CI)(F)', this.failGrant = false, this.failCut = false, this.whoami = '"rig-pc\\rig","$_sid"\r\n'});

  final String listing;
  final bool failGrant;
  final bool failCut;
  final String whoami;
  final calls = <List<String>>[];

  Future<ProcessResult> call(String exe, List<String> args) async {
    calls.add([exe.split(r'\').last, ...args]);
    var code = 0;
    var out = '';
    if (exe.endsWith('whoami.exe')) out = whoami;
    if (exe.endsWith('icacls.exe') && args.length == 1) out = '$_folder $listing\r\n';
    if (args.contains('/grant:r') && failGrant) code = 5;
    if (args.contains('/inheritance:r') && failCut) code = 5;
    return ProcessResult(0, code, out, '');
  }
}

void main() {
  test('grants the user and SYSTEM by SID first, then drops the inherited entries', () async {
    final fake = _Fake();
    expect(await restrictFolderToOwner(_folder, profile: _profile, run: fake.call), OwnerOnlyResult.restricted);
    expect(fake.calls, [
      ['icacls.exe', _folder],
      ['whoami.exe', '/user', '/fo', 'csv', '/nh'],
      ['icacls.exe', _folder, '/grant:r', '*$_sid:(OI)(CI)F', '*S-1-5-18:(OI)(CI)F', '/q'],
      ['icacls.exe', _folder, '/inheritance:r', '/q'],
    ]);
  });

  test('a folder without inherited entries is left as it is', () async {
    final fake = _Fake(listing: 'rig-pc\\rig:(OI)(CI)(F)\r\n NT AUTHORITY\\SYSTEM:(OI)(CI)(F)');
    expect(await restrictFolderToOwner(_folder, profile: _profile, run: fake.call), OwnerOnlyResult.alreadyRestricted);
    expect(fake.calls, hasLength(1));
  });

  test('nothing is dropped when the grant or the SID fails', () async {
    for (final fake in [_Fake(failGrant: true), _Fake(whoami: 'garbage'), _Fake(whoami: '"a","S-1-5-21 /grant x"')]) {
      expect(await restrictFolderToOwner(_folder, profile: _profile, run: fake.call), OwnerOnlyResult.skipped);
      expect(fake.calls.where((c) => c.contains('/inheritance:r')), isEmpty);
    }
    expect(await restrictFolderToOwner(_folder, profile: _profile, run: _Fake(failCut: true).call), OwnerOnlyResult.partial);
  });

  test('a folder outside the profile is never touched', () async {
    for (final (path, profile) in [(r'D:\wallets', _profile), (r'C:\Users\rig2\.epic', _profile), (_folder, null), (_profile, _profile)]) {
      final fake = _Fake();
      expect(await restrictFolderToOwner(path, profile: profile, run: fake.call), OwnerOnlyResult.skipped);
      expect(fake.calls, isEmpty);
    }
    expect(await restrictFolderToOwner('c:/users/RIG/.epic_cash_desktop/', profile: r'C:\Users\rig\', run: _Fake().call), OwnerOnlyResult.restricted);
  });
}
