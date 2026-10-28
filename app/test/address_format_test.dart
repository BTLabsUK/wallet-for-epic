// The list form of an address: first six and last six of the checked part, the
// kind kept; compact drops the kind part. Plus the rail's host line.

import 'package:epic_wallet/src/address_format.dart';
import 'package:flutter_test/flutter_test.dart';

const _epicbox = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com';
const _tor = 'wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid.onion';

void main() {
  void row(String full, String short, String compact) {
    test(full, () {
      expect(shortAddress(full), short);
      expect(shortAddress(full, compact: true), compact);
    });
  }

  group('shortAddress', () {
    row(_epicbox, 'esWxbo…3jUcNK@epicbox.epiccash.com', 'esWxbo…3jUcNK');
    row('esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK', 'esWxbo…3jUcNK', 'esWxbo…3jUcNK');
    row(_tor, 'wfe7q3…abcdid.onion', 'wfe7q3…abcdid');
    row('http://10.0.1.24:3415', 'http://10.0.1.24:3415', '10.0.1.24:3415');
    row('https://pay.example.org/v2/foreign', 'https://pay.example.org/…', 'pay.example.org/…');
    row('https://pay.example.org/', 'https://pay.example.org', 'pay.example.org');
    row(
      'https://pay.example-merchant-with-a-long-hostname.co.uk:8443/v2/foreign',
      'https://pay.ex….co.uk:8443/…',
      'pay.ex….co.uk:8443/…',
    );
    row('http://$_tor', 'http://wfe7q3…abcdid.onion', 'wfe7q3…abcdid.onion');
    row('localhost:3415', 'localhost:3415', 'localhost:3415');
    row('abc@x.y', 'abc@x.y', 'abc');
    row('abcdefghijklmn', 'abcdefghijklmn', 'abcdefghijklmn');
    row('abcdefghijklmno', 'abcdef…jklmno', 'abcdef…jklmno');

    test('a short form is not shortened again', () {
      for (final s in [
        'esWxbo…3jUcNK@epicbox.epiccash.com',
        'wfe7q3…abcdid.onion',
        'https://pay.example.org/…',
      ]) {
        expect(shortAddress(s), s);
      }
    });

    test('only cuts: upper case is kept', () {
      expect(shortAddress(_tor.toUpperCase()), 'WFE7Q3…ABCDID.ONION'.replaceAll('.ONION', '.onion'));
    });

    test('surrounding whitespace is ignored', () {
      expect(shortAddress('  $_tor\n'), 'wfe7q3…abcdid.onion');
    });
  });

  group('railHost', () {
    test('drops the label the row name already says', () {
      expect(railHost('Epicbox', 'epicbox.stackwallet.com'), 'stackwallet.com');
      expect(railHost('Node', 'node.btlabs.uk'), 'btlabs.uk');
      expect(railHost('node', 'Node.btlabs.uk'), 'btlabs.uk');
    });
    test('keeps hosts that do not match or are short', () {
      expect(railHost('Node', 'localhost'), 'localhost');
      expect(railHost('Node', 'epicnet.us'), 'epicnet.us');
      expect(railHost('Node', 'node.us'), 'node.us');
      expect(railHost('Epicbox', 'node.btlabs.uk'), 'node.btlabs.uk');
    });
  });

  test('shortHost drops the scheme, the port and the first label', () {
    expect(shortHost('https://node.btlabs.uk'), 'btlabs.uk');
    expect(shortHost('https://node.epicnet.us:3413'), 'epicnet.us');
    expect(shortHost('epicbox.epiccash.com'), 'epiccash.com');
    expect(shortHost('epicbox.stackwallet.com:443'), 'stackwallet.com');
    expect(shortHost('epic-node.iniaku.my.id'), 'iniaku.my.id');
    expect(shortHost('stackwallet.com'), 'stackwallet.com');
    expect(shortHost('http://127.0.0.1:3413'), '127.0.0.1');
    expect(shortHost('localhost'), 'localhost');
  });
}
