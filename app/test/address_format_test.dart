// SPDX-License-Identifier: Apache-2.0
// The list form of an address: first six and last six of the checked part, the
// kind kept; compact drops the kind part. Plus the rail's host line, the parts and
// tones every address is drawn in, the case it is shown in and host:port.

import 'package:epic_wallet/src/address_format.dart';
import 'package:epic_wallet/src/recipient.dart';
import 'package:flutter/painting.dart';
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

  group('addressParts', () {
    String shape(String a) => addressParts(a).join(' ');

    test('Epicbox: the key\'s first and last six marked, a line only before "@"', () {
      expect(
        shape(_epicbox),
        'mark(esWxbo) plain(BPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb) mark(3jUcNK) quiet|!(@epicbox.epiccash.com)',
      );
      expect(addressParts(_epicbox).map((p) => p.text).join(), _epicbox);
    });

    test('Epicbox: the server in lower case, the key as it is', () {
      expect(addressParts('esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@EPICBOX.Example.ORG:443').last.text, '@epicbox.example.org:443');
      expect(addressParts('esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@x.y').first.text, 'esWxbo');
    });

    test('a Link URL marks host:port as one token: an IP is never split', () {
      expect(shape('http://10.100.10.20:3415'), 'quiet!(http://) mark!(10.100.10.20:3415)');
      expect(shape('https://pay.example.org:8443/v2/foreign'), 'quiet!(https://) mark!(pay.example.org:8443) quiet|(/v2/foreign)');
      expect(shape('http://[::1]:3415/'), 'quiet!(http://) mark!([::1]:3415) quiet!(/)');
    });

    test('a Link URL: scheme and host lower case, the path as it is', () {
      expect(shape('HTTPS://Pay.Example.ORG/V2'), 'quiet!(https://) mark!(pay.example.org) quiet|(/V2)');
    });

    test('an onion name is a key: its ends marked, .onion quiet; any case comes out lower', () {
      const ends = 'mark(wfe7q3) plain(k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxz) mark(abcdid) quiet!(.onion)';
      expect(shape(_tor), ends);
      expect(shape(_tor.toUpperCase()), ends);
      expect(shape('http://${_tor.toUpperCase()}/'), 'quiet!(http://) $ends quiet!(/)');
    });

    test('a bare host:port is one marked token; a short key is marked whole', () {
      expect(shape('LocalHost:3415'), 'mark!(localhost:3415)');
      expect(shape('abcdef'), 'mark(abcdef)');
      expect(shape('  '), '');
    });

    test('lines: an Epicbox server and a link path start their own', () {
      expect(addressLines(addressParts(_epicbox)).map((l) => l.map((p) => p.text).join()).toList(), [_epicbox.split('@').first, '@epicbox.epiccash.com']);
      expect(addressLines(addressParts('http://1.2.3.4:3415/pay')).length, 2);
      expect(addressLines(addressParts('http://1.2.3.4:3415/')).length, 1);
      expect(addressLines(addressParts(_tor)).length, 1);
    });
  });

  group('addressPartsSpan', () {
    const mark = TextStyle(fontWeight: FontWeight.w600);
    const quiet = TextStyle(fontWeight: FontWeight.w300);

    test('without joined, the text is exactly the address shown (safe to select)', () {
      final span = addressSpan(_epicbox, mark: mark, quiet: quiet);
      expect(span.toPlainText(), _epicbox);
    });

    test('joined: no break inside a whole part, a break only before a line start', () {
      final span = addressSpan('esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@a.io', mark: mark, quiet: quiet, joined: true);
      final text = span.toPlainText();
      expect(text.replaceAll(wordJoiner, '').replaceAll(zeroWidthSpace, ''), 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@a.io');
      expect(text.endsWith('$zeroWidthSpace${unbroken('@a.io')}'), isTrue);
      expect(unbroken('a.io'), 'a$wordJoiner.${wordJoiner}i${wordJoiner}o');
      expect(zeroWidthSpace.allMatches(text).length, 1);
    });

    test('the marked parts get the mark style, the server the quiet one', () {
      final children = addressSpan(_epicbox, mark: mark, quiet: quiet).children!.cast<TextSpan>();
      expect([for (final c in children) c.style], [mark, null, mark, quiet]);
    });
  });

  group('displayCase', () {
    test('a link: scheme and host lower case, user part and path kept, length kept', () {
      for (final (typed, shown) in [
        ('HTTP://WFE7Q3K2MZ5XR4TBV6LD5YHNPJC7SGO2A3UE6IWQ4FK7TR3MXZABCDID.ONION/', 'http://$_tor/'),
        ('Https://Pay.Example.ORG:8443/V2/Foreign', 'https://pay.example.org:8443/V2/Foreign'),
        ('http://User:Pass@Host.IO/x', 'http://User:Pass@host.io/x'),
        ('  HTTP://1.2.3.4:3415', '  http://1.2.3.4:3415'),
      ]) {
        expect(displayCase(typed), shown);
        expect(displayCase(typed).length, typed.length);
      }
    });

    test('a bare onion in lower case; an Epicbox key and other text unchanged', () {
      expect(displayCase(_tor.toUpperCase()), _tor);
      expect(displayCase('${_tor.toUpperCase()}:80/'), '$_tor:80/');
      expect(displayCase(_epicbox), _epicbox);
      expect(displayCase('esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@EPICBOX.X'), 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@EPICBOX.X');
      expect(displayCase('Alice'), 'Alice');
    });

    test('display only: what parseRecipient reads stays the same', () {
      for (final typed in [
        'HTTP://WFE7Q3K2MZ5XR4TBV6LD5YHNPJC7SGO2A3UE6IWQ4FK7TR3MXZABCDID.ONION/',
        _tor.toUpperCase(),
        'http://Pay.Example.org:3415/V2',
        _epicbox,
      ]) {
        final shown = displayCase(typed);
        final a = parseRecipient(typed), b = parseRecipient(shown);
        expect(b.kind, a.kind, reason: typed);
        // An onion is lower case either way; a link's host compares without case, the path exact.
        if (a.kind == RecipientKind.http) {
          expect(Uri.parse(b.address).host, Uri.parse(a.address).host);
          expect(Uri.parse(b.address).path, Uri.parse(a.address).path);
        } else {
          expect(b.address, a.address, reason: typed);
        }
      }
    });
  });

  group('hostPort', () {
    test('host:port without scheme, path, user part or a default port; lower case', () {
      expect(hostPort('https://Node.Example.org:3413/'), 'node.example.org:3413');
      expect(hostPort('https://node.example.org'), 'node.example.org');
      expect(hostPort('https://node.example.org:443'), 'node.example.org');
      expect(hostPort('http://node.example.org:80/v2'), 'node.example.org');
      expect(hostPort('http://127.0.0.1:3413'), '127.0.0.1:3413');
      expect(hostPort('node.example.org:3413'), 'node.example.org:3413');
      expect(hostPort('epicbox.example.org:443'), 'epicbox.example.org:443');
      expect(hostPort('http://[::1]:3413'), '[::1]:3413');
      expect(hostPort('http://user@host.io:1/x'), 'host.io:1');
      expect(hostPort('http://$_tor/'), _tor);
    });

    test('text that is no address comes back trimmed', () {
      expect(hostPort('  Local node '), 'Local node');
      expect(hostPort(''), '');
    });
  });

  test('shortHost drops the scheme, the port and the first label', () {
    expect(shortHost('https://node.btlabs.uk'), 'btlabs.uk');
    expect(shortHost('https://node.epicnet.us:3413'), 'epicnet.us');
    expect(shortHost('epicbox.epiccash.com'), 'epiccash.com');
    expect(shortHost('epicbox.stackwallet.com:443'), 'stackwallet.com');
    expect(shortHost('node.pool.example.org'), 'pool.example.org');
    expect(shortHost('stackwallet.com'), 'stackwallet.com');
    expect(shortHost('http://127.0.0.1:3413'), '127.0.0.1');
    expect(shortHost('localhost'), 'localhost');
  });
}
