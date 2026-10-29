// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/support_clean.dart';
import 'package:flutter_test/flutter_test.dart';

const _phrase =
    'abandon ability able about above absent absorb abstract absurd abuse access accident';
const _address = 'esWn9r2zQj5eKkVh3sT4YpX7cBdF8gHmNaLuRvS6tE1iPo2wZxC9';
const _onion = 'pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd';

void main() {
  test('a log loses phrases, passwords, addresses, onions, IPs and home folders', () {
    const log = '''
INFO restore: words $_phrase
INFO unlock: password=hunter2hunter2 accepted
INFO cli: epic-wallet --pass "s3cret pass" listen
WARN send: to $_address@box.epic.invalid failed
WARN send: to esWn9r…@box.epic.invalid again
INFO tor: listening on http://$_onion.onion/v2/foreign
INFO node: connected to 203.0.113.7:3413 and http://10.0.1.24:3413, local 127.0.0.1:3415
INFO node: tried http://mynode.example.org:3413 and https://node.epic.invalid
INFO files: /home/alice/.local/share/wallet and C:\\Users\\Alice Smith\\AppData
INFO user alice on alice-laptop: done
INFO kernel 08a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f9a
INFO tx 6c2e5a8f-1b2d-4c3e-9f8a-7b6c5d4e3f2a amount 1.5 at height 2500000
INFO slate {"id":"x","participant_data":[{"part_sig":"abc"}]}
INFO next line survives
INFO mail me@example.com, PIN 123456
''';
    final out = cleanForReport(log, context: const CleanContext(home: '/home/alice', username: 'alice', hostname: 'alice-laptop'));
    for (final secret in [
      'abandon', 'hunter2', 's3cret', _address, 'esWn9r', _onion, '203.0.113.7', '10.0.1.24',
      'mynode.example.org', 'alice', 'Alice Smith', '08a1b2c3', 'part_sig', 'me@example.com', '123456',
    ]) {
      expect(out, isNot(contains(secret)), reason: secret);
    }
    expect(out, contains('[recovery phrase removed]'));
    expect(out, contains('<address-1>@box.epic.invalid failed'));
    expect(out, contains('<onion-1>.onion'));
    expect(out, contains('<ip-1>:3413'));
    expect(out, contains('127.0.0.1:3415'));
    expect(out, contains('https://node.epic.invalid'));
    expect(out, contains('~/.local/share/wallet'));
    expect(out, contains('[slate removed]'));
    expect(out, contains('INFO next line survives'));
    // Kept on purpose: amounts, heights, ports.
    expect(out, contains('amount 1.5 at height 2500000'));
  });

  test('the same value gets the same name across the texts of one report', () {
    final ids = CleanIds();
    final a = cleanForReport('from 203.0.113.7 and 198.51.100.2', ids: ids);
    final b = cleanForReport('again 198.51.100.2', ids: ids);
    expect(a, 'from <ip-1> and <ip-2>');
    expect(b, 'again <ip-2>');
  });

  test('finds a phrase in any case and with numbering, one typo allowed', () {
    expect(looksLikePhrase('1. Abandon 2. ABILITY 3. able 4. about 5. above 6. absent 7. absorb 8. abstract'), isTrue);
    expect(looksLikePhrase('abandon ability able abuot above absent absorb abstract absurd'), isTrue);
    expect(looksLikePhrase('The balance looks wrong after the restore'), isFalse);
  });

  test('cleaning twice changes nothing more', () {
    const text = 'to $_address@box.epic.invalid from 203.0.113.7, password: x1y2z3';
    final once = cleanForReport(text);
    expect(cleanForReport(once), once);
  });
}
