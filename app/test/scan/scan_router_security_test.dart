// Security of the scan router (spec docs/feedback/designs/epic-uri/spec.md §7.2, §7.3,
// §7.5, §7.6 items 1–10): what a hostile or odd text can and cannot make of a scan. Decisions:
// note cap 264 code points, whole text 4096, raw value 3168, any non-ASCII host refused,
// invalid parameter names ignored like unknown ones, no NFC step.

import 'dart:io';
import 'dart:math';

import 'package:epic_wallet/src/recipient.dart';
import 'package:epic_wallet/src/scan/scan_router.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _key = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK';
const _e = '$_key@epicbox.epiccash.com';
const _floonet =
    'fsWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com';
const _d = 'http://1.2.3.4:3415';
const _onion = 'wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid';
const _o = 'http://$_onion.onion';

AddressVerdict _check(Recipient to) => switch (to.kind) {
  RecipientKind.epicbox when to.address == _floonet =>
    AddressVerdict.otherChain,
  RecipientKind.epicbox =>
    fakeEpicboxAddress(to.address)
        ? AddressVerdict.valid
        : AddressVerdict.invalid,
  RecipientKind.tor =>
    onionAddressFormat(to.address)
        ? AddressVerdict.valid
        : AddressVerdict.invalid,
  RecipientKind.http =>
    httpAddressComplete(to.address)
        ? AddressVerdict.valid
        : AddressVerdict.invalid,
};

ScannedCode _scan(String text) => classifyScan(text, check: _check);

PaymentRequest _pay(String text) {
  final code = _scan(text);
  expect(code, isA<PaymentRequest>(), reason: text);
  return code as PaymentRequest;
}

void _refused(String text, [UnknownReason? reason]) {
  final code = _scan(text);
  expect(code, isA<UnknownCode>(), reason: text);
  if (reason != null) {
    expect((code as UnknownCode).reason, reason, reason: text);
  }
}

/// One character by code point, so no invisible character sits in this file.
String _c(int codePoint) => String.fromCharCode(codePoint);

final BigInt _epic = BigInt.from(100000000);

void main() {
  group('1 schemes', () {
    for (final text in [
      'javascript:alert(1)',
      'javascript://%0Aalert(1)',
      'data:text/html,<script>alert(1)</script>',
      'data:text/plain;base64,ZXBpYzpF',
      'intent://scan/#Intent;scheme=epic;package=com.evil;end',
      'file:///etc/passwd',
      'content://com.android.contacts/contacts',
      'ftp://1.2.3.4/pay',
      'bitcoin:1abc?amount=1',
      'monero:4abc?tx_amount=1',
      'epic-cash:$_e',
      'epic :$_e',
      'epicc:$_e',
      'xepic:$_e',
      'epic%3A$_e',
      '%65pic:$_e',
      'mailto:anna@example.com',
      'tel:+441234',
      'sms:+441234?body=epic:$_e',
      '${_c(0xFF45)}pic:$_e', // full-width e
      'еpic:$_e', // Cyrillic е
    ]) {
      test(text, () {
        final code = _scan(text);
        expect(code, isNot(isA<PaymentRequest>()));
        expect(code, isA<UnknownCode>());
      });
    }

    test('mixed-case schemes are ours', () {
      for (final scheme in [
        'EPIC',
        'Epic',
        'ePiC',
        'EPICCASH',
        'EpicCash',
        'epicCASH',
      ]) {
        expect(_pay('$scheme:$_e?amount=1').amount, _epic, reason: scheme);
      }
    });
  });

  group('2 caps', () {
    String padded(int length) {
      final head = 'epic:$_e?amount=1&x=';
      return head + 'a' * (length - head.length);
    }

    test('the whole text: 4096 read, 4097 refused', () {
      expect(padded(maxScanLength).length, 4096);
      expect(_pay(padded(maxScanLength)).amount, _epic);
      _refused(padded(maxScanLength + 1));
    });

    test('a long second line does not count', () {
      expect(_pay('epic:$_e?amount=1\n${'a' * 100000}').amount, _epic);
    });

    test('the address: 255 read, 256 refused', () {
      String address(int length) {
        final head = '$_key@';
        final host = 'a' * (length - head.length - 4);
        return '$head$host.com';
      }

      expect(address(255).length, 255);
      expect(_pay('epic:${address(255)}').recipient.address, address(255));
      _refused('epic:${address(256)}', UnknownReason.badAddress);
      expect(_scan(address(255)), isA<ScannedAddress>());
      _refused(address(256));
    });

    test('parameters: 8 read, 9 refused', () {
      final eight = List.generate(
        7,
        (i) => 'x${String.fromCharCode(97 + i)}=1',
      ).join('&');
      expect(_pay('epic:$_e?$eight&amount=1').amount, _epic);
      _refused('epic:$_e?$eight&y=1&amount=1');
      // Empty pieces are no parameters.
      expect(
        _pay('epic:$_e?&&amount=1&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&')
            .amount,
        _epic,
      );
      expect(_pay('epic:$_e?${'&' * 2000}amount=1').amount, _epic);
    });

    test('a value: 3168 raw read, 3169 dropped as too long', () {
      final pizza = '%F0%9F%8D%95' * maxNoteLength;
      expect(pizza.length, maxUriValueLength);
      expect(maxUriValueLength, 3168);
      final p = _pay('epic:$_e?message=$pizza&amount=1');
      expect(p.note, '🍕' * maxNoteLength);
      expect(p.problems, isEmpty);
      final over = _pay('epic:$_e?message=${pizza}a&amount=1');
      expect(over.note, isNull);
      expect(over.amount, _epic);
      expect(over.problems, {RequestProblem.tooLong});
      final amount = _pay('epic:$_e?amount=${'1' * 3169}');
      expect(amount.amount, isNull);
      expect(amount.problems, {RequestProblem.tooLong});
    });

    test('names over 16 letters or not [a-z] are ignored', () {
      for (final name in [
        'abcdefghijklmnopq',
        'amount1',
        'amo_unt',
        '%61mount',
        'amöunt',
        'x-y',
        '',
      ]) {
        final p = _pay('epic:$_e?$name=5&message=ok');
        expect(p.amount, isNull, reason: name);
        expect(p.note, 'ok', reason: name);
        expect(p.problems, isEmpty, reason: name);
      }
      expect(_pay('epic:$_e?abcdefghijklmnop=5&amount=1').amount, _epic);
    });

    test('notes: 264 code points kept, 265 dropped; labels 64 and 65', () {
      final note = 'ก' * maxNoteLength;
      expect(_pay(EpicUri.build(_e, note: note)).note, note);
      final over = _pay(EpicUri.build(_e, note: '${note}x', amount: _epic));
      expect(over.note, isNull);
      expect(over.amount, _epic);
      expect(over.problems, {RequestProblem.tooLong});
      // Code points, not UTF-16 units: 264 emoji are 528 units and still fit.
      expect(
        _pay(EpicUri.build(_e, note: '😀' * maxNoteLength)).note,
        '😀' * maxNoteLength,
      );
      final label = 'L' * maxLabelLength;
      expect(_pay(EpicUri.build(_e, label: label)).label, label);
      final long = _pay(EpicUri.build(_e, label: '${label}x'));
      expect(long.label, isNull);
      expect(long.problems, {RequestProblem.tooLong});
    });

    test('the cap counts after cleaning', () {
      final note = 'a' * maxNoteLength + _c(0x200B) * 20;
      expect(_pay(EpicUri.build(_e, note: note)).note, 'a' * maxNoteLength);
    });
  });

  group('3 duplicates refuse the whole code', () {
    for (final query in [
      'amount=1&amount=2',
      'amount=1&amount=1',
      'Amount=1&amount=2',
      'AMOUNT=1&amount=2',
      'message=a&message=b',
      'label=a&LABEL=b',
      'method=direct&method=epicbox',
      'direct=$_d&direct=$_o',
      'foo=1&foo=2&amount=1',
      '=1&=2&amount=1',
      'amount&amount=1',
    ]) {
      test(query, () => _refused('epic:$_e?$query'));
    }

    test('after the fragment there is nothing to repeat', () {
      expect(_pay('epic:$_e?amount=1#&amount=2').amount, _epic);
    });
  });

  group('4 amount grammar', () {
    test('accepted, exact atomic units', () {
      for (final (text, atomic) in [
        ('1', _epic),
        ('0.00000001', BigInt.one),
        ('21000000000', BigInt.from(21000000000) * _epic),
        ('1.1', BigInt.from(110000000)),
        ('0.1', BigInt.from(10000000)),
        ('0.29', BigInt.from(29000000)),
        ('123.45678901', BigInt.parse('12345678901')),
        ('20999999999.99999999', BigInt.parse('2099999999999999999')),
      ]) {
        expect(parseUriAmount(text), (atomic, null), reason: text);
        expect(_pay('epic:$_e?amount=$text').amount, atomic, reason: text);
      }
    });

    test('invalid', () {
      for (final text in [
        '0',
        '0.0',
        '0.00000000',
        '00',
        '-1',
        '+1',
        '1e3',
        '1E3',
        'NaN',
        'Infinity',
        '0x10',
        '1.123456789',
        '01',
        '007',
        '1.',
        '.5',
        '1,5',
        '1 000',
        '1_000',
        '',
        ' ',
        '١',
        '٣.٥',
        _c(0xFF11),
        '1${_c(0x0660)}',
        _c(0x0967),
        '1.5.0',
        '1..5',
        '--1',
        '1-',
        '½',
        '1.5 EPIC',
        '1.5e0',
        '0b1',
        ' 1',
        '1 ',
      ]) {
        expect(parseUriAmount(text), (
          null,
          RequestProblem.amountInvalid,
        ), reason: text);
      }
    });

    test('too large', () {
      for (final text in [
        '21000000001',
        '21000000000.00000001',
        '99999999999',
        '9' * 40,
        '1${'0' * 70}',
        '99999999999999999999999.5',
      ]) {
        expect(parseUriAmount(text), (
          null,
          RequestProblem.amountTooLarge,
        ), reason: text);
      }
    });

    test('in a code: + is a space, %2B a plus, both refused', () {
      for (final raw in ['+1', '%2B1', '%2D1', '1%2C5', '%31%2E%35x']) {
        final p = _pay('epic:$_e?amount=$raw');
        expect(p.amount, isNull, reason: raw);
        expect(p.problems, {RequestProblem.amountInvalid}, reason: raw);
      }
      // An escaped digit is still a digit after the one decode.
      expect(_pay('epic:$_e?amount=%31%2E%35').amount, BigInt.from(150000000));
    });
  });

  group('5 decode exactly once', () {
    test('%2541 is %41, not A', () {
      expect(_pay('epic:$_e?message=%2541').note, '%41');
      expect(_pay('epic:$_e?message=%252B').note, '%2B');
    });

    test('bad UTF-8 or a broken escape drops the part, silently', () {
      for (final raw in [
        '%E0%A4',
        '%FF',
        '%C0%AF',
        '%ED%A0%80',
        '%',
        '%4',
        'ok%',
        '%G1',
        '%%41',
      ]) {
        final p = _pay('epic:$_e?message=$raw&amount=1');
        expect(p.note, isNull, reason: raw);
        expect(p.amount, _epic, reason: raw);
        expect(p.problems, isEmpty, reason: raw);
      }
    });

    test('+ is a space; lower-case hex is read', () {
      expect(_pay('epic:$_e?message=a+b++c').note, 'a b c');
      expect(_pay('epic:$_e?message=caf%c3%a9').note, 'café');
    });

    test('%00%0A is empty after cleaning, dropped', () {
      final p = _pay('epic:$_e?message=%00%0A&label=%00');
      expect(p.note, isNull);
      expect(p.label, isNull);
      expect(p.problems, isEmpty);
    });

    test(
      'characters left unescaped are read as typed, outside the BMP too',
      () {
        expect(_pay('epic:$_e?message=🍕+Pizza').note, '🍕 Pizza');
        expect(_pay('epic:$_e?message=ค่าอาหาร&label=Анна').note, 'ค่าอาหาร');
        expect(_pay('epic:$_e?label=Анна').label, 'Анна');
        expect(_pay('epic:$_e?message=a=b=c').note, 'a=b=c');
      },
    );

    test('a ? or # inside a value', () {
      // The address ends at the first ?, the code at the first #.
      expect(_pay('epic:$_e?message=why?&amount=1').note, 'why?');
      final p = _pay('epic:$_e?amount=1?message=x');
      expect(p.amount, isNull);
      expect(p.problems, {RequestProblem.amountInvalid});
      final hash = _pay('epic:$_e?message=no#1&amount=1');
      expect(hash.note, 'no');
      expect(hash.amount, isNull);
      expect(_pay('epic:$_e#?amount=1').amount, isNull);
      expect(_pay('epic:$_e?message=%231').note, '#1');
    });
  });

  group('6 cleaning', () {
    final forbidden = {
      'RLO': 0x202E,
      'LRO': 0x202D,
      'RLE': 0x202B,
      'PDF': 0x202C,
      'ZWSP': 0x200B,
      'ZWNJ': 0x200C,
      'ZWJ': 0x200D,
      'LRM': 0x200E,
      'RLM': 0x200F,
      'LRI': 0x2066,
      'RLI': 0x2067,
      'FSI': 0x2068,
      'PDI': 0x2069,
      'ALM': 0x061C,
      'WJ': 0x2060,
      'BOM': 0xFEFF,
      'BEL': 0x0007,
      'ESC': 0x001B,
      'DEL': 0x007F,
      'NEL': 0x0085,
      'CSI': 0x009B,
    };
    for (final MapEntry(key: name, value: cp) in forbidden.entries) {
      test('$name is removed from notes and labels', () {
        final text = 'ev${_c(cp)}il';
        final uri = EpicUri.build(_e, note: text, label: text);
        final p = _pay(uri);
        expect(p.note, isNot(contains(_c(cp))));
        expect(p.label, isNot(contains(_c(cp))));
        expect(cleanUntrustedText(text), anyOf('evil', 'ev il'));
      });
    }

    test('line breaks and tabs become one space, never a joined word', () {
      for (final cp in [0x0A, 0x0D, 0x09, 0x0B, 0x0C, 0x85, 0x2028, 0x2029]) {
        expect(
          cleanUntrustedText('two${_c(cp)}words'),
          'two words',
          reason: '$cp',
        );
      }
      expect(cleanUntrustedText('a\r\n\r\nb'), 'a b');
      expect(
        _pay('epic:$_e?message=line%0Aone%0D%0Aline%20two').note,
        'line one line two',
      );
    });

    test('whitespace collapses, the ends are trimmed', () {
      expect(cleanUntrustedText('  a ${_c(0x3000)} ${_c(0xA0)} b  '), 'a b');
      expect(cleanUntrustedText('${_c(0x200B)}  ${_c(0x202E)}'), isNull);
    });

    test('a reversed label cannot reverse the display', () {
      final p = _pay(
        'epic:$_e?label=%E2%80%AEevil%E2%80%AC&message=%E2%81%A6x%E2%81%A9',
      );
      expect(p.label, 'evil');
      expect(p.note, 'x');
    });

    test('markup stays plain text', () {
      const html = '<b>Pay</b> <a href="https://evil">here</a>';
      expect(_pay(EpicUri.build(_e, note: html)).note, html);
    });
  });

  group('7 Direct addresses', () {
    test('a user part is refused', () {
      for (final address in [
        'http://a@evil.com',
        'http://trusted.com@evil.com',
        'https://user:pass@1.2.3.4:3415',
        'http://1.2.3.4:3415@evil.com',
        'http://@evil.com',
      ]) {
        _refused('epic:$address', UnknownReason.badAddress);
        _refused(address);
      }
    });

    test('plain http to another device is marked, onion and https are not', () {
      expect(
        plainHttpToOtherDevice(
          _pay('epic:http://8.8.8.8:3415').recipient.address,
        ),
        isTrue,
      );
      expect(
        plainHttpToOtherDevice(
          _pay('epic:https://8.8.8.8:3415').recipient.address,
        ),
        isFalse,
      );
      final onion = _pay('epic:$_o').recipient;
      expect(onion.kind, RecipientKind.tor);
      expect(plainHttpToOtherDevice(onion.address), isFalse);
    });

    test('LAN addresses pass the router; the mode gates are Send’s', () {
      // §7.3: the router adds no allowance and refuses none; network_gate.dart decides.
      final p = _pay('epic:http://10.0.1.5:3415');
      expect(p.recipient.address, 'http://10.0.1.5:3415');
      expect(plainHttpToOtherDevice(p.recipient.address), isTrue);
    });

    test('a host that is not plain ASCII is refused', () {
      for (final address in [
        'http://exаmple.com:3415', // Cyrillic а
        'https://paypal.соm',
        'http://xn--80ak6aa92e.com.ü:3415',
        '$_key@epicbоx.epiccash.com', // Cyrillic о
        '$_key@epicbox.epiccash.com${_c(0x200B)}',
      ]) {
        _refused('epic:$address', UnknownReason.badAddress);
        _refused(address);
      }
    });

    test('IPv6 hosts are refused, as Send refuses them', () {
      for (final address in [
        'http://[::1]:3415',
        'http://[2001:db8::1]:3415',
        'http://[::ffff:1.2.3.4]',
      ]) {
        _refused('epic:$address', UnknownReason.badAddress);
      }
    });

    test('ports from 1 to 65535', () {
      expect(
        _pay('epic:http://1.2.3.4:1').recipient.address,
        'http://1.2.3.4:1',
      );
      expect(
        _pay('epic:http://1.2.3.4:65535').recipient.address,
        'http://1.2.3.4:65535',
      );
      for (final port in [
        '0',
        '65536',
        '70000',
        '99999999999',
        '-1',
        'abc',
        '',
      ]) {
        expect(
          _scan('epic:http://1.2.3.4:$port'),
          isNot(isA<PaymentRequest>()),
          reason: port,
        );
      }
    });

    test('incomplete hosts are refused', () {
      for (final address in [
        'http://1.2.3',
        'http://1.2.3.',
        'http://example',
        'http://example.',
        'http://',
        'https://',
        'http:///x',
        r'http://evil.com\@trusted.com',
      ]) {
        expect(
          _scan('epic:$address'),
          isNot(isA<PaymentRequest>()),
          reason: address,
        );
      }
    });

    test('a bare URL with a query or fragment is no wallet address', () {
      _refused('https://example.com/pay?amount=1');
      _refused('http://1.2.3.4:3415/?x=1');
      _refused('http://1.2.3.4:3415#x');
      expect(_scan('http://1.2.3.4:3415/v2/foreign'), isA<ScannedAddress>());
    });

    test('a direct= with a query, user part or non-ASCII host is dropped', () {
      for (final bad in [
        'http://1.2.3.4:3415/?a=1',
        'http://a@evil.com',
        'http://exаmple.com',
      ]) {
        final p = _pay('epic:$_e?method=direct&direct=${encodeUriValue(bad)}');
        expect(p.direct, isNull, reason: bad);
      }
    });

    test('onion forms', () {
      for (final address in [
        _onion,
        '$_onion.onion',
        _o,
        '$_o/',
        '$_o:80',
        '$_o:80/v2/foreign',
        _onion.toUpperCase(),
        'HTTP://${_onion.toUpperCase()}.ONION',
      ]) {
        final p = _pay('epic:$address');
        expect(p.recipient.kind, RecipientKind.tor, reason: address);
        expect(p.recipient.address, '$_onion.onion', reason: address);
      }
      for (final bad in [
        _onion.substring(1), // 55 characters
        '${_onion.substring(0, 55)}a', // not a v3 key
        '${_onion}x.onion',
        'https://$_onion.onion',
      ]) {
        expect(_scan('epic:$bad'), isNot(isA<PaymentRequest>()), reason: bad);
      }
    });
  });

  group('whitespace and invisible characters', () {
    test('around the text: trimmed', () {
      for (final text in [
        '  epic:$_e  ',
        '\tepic:$_e\t',
        '\r\nepic:$_e\r\n',
        '\n\n  epic:$_e\nnext',
        '${_c(0xFEFF)}epic:$_e',
        '${_c(0x3000)}epic:$_e${_c(0xA0)}',
      ]) {
        expect(_pay(text).recipient.address, _e, reason: text);
      }
    });

    test('inside the address: refused, never mended', () {
      for (final text in [
        'epic: $_e',
        'epic:$_e ?amount=1',
        'epic:esWxbo BPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com',
        'epic:$_key @epicbox.epiccash.com',
        'epic:http://1.2.3.4: 3415',
      ]) {
        _refused(text, UnknownReason.badAddress);
      }
    });

    test('control characters inside refuse the code', () {
      for (final cp in [0x00, 0x07, 0x09, 0x0B, 0x0C, 0x1B, 0x7F, 0x85, 0x9B]) {
        _refused('epic:$_e?amount=1${_c(cp)}&message=x');
        _refused('epic:$_e${_c(cp)}x');
      }
    });

    test('zero-width and direction characters in the address refuse it', () {
      for (final cp in [
        0x200B,
        0x200D,
        0x202E,
        0x2066,
        0xFEFF,
        0x061C,
        0x2028,
      ]) {
        _refused(
          'epic:esWxbo${_c(cp)}BPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com',
        );
      }
      // A zero-width character before the scheme hides it: not an Epic code.
      _refused('${_c(0x200B)}epic:$_e');
    });

    test('a zero-width character in the amount makes it invalid', () {
      final p = _pay('epic:$_e?amount=1${_c(0x200B)}');
      expect(p.amount, isNull);
      expect(p.problems, {RequestProblem.amountInvalid});
    });
  });

  group('junk around addresses', () {
    test("Stack's wrappers come off a bare Epicbox address", () {
      for (final text in [
        'mailto:$_e',
        'MAILTO:$_e',
        'http://$_e',
        'https://$_e',
        'HTTPS://$_e',
        'https://$_e/',
        '$_e/',
        'mailto:$_e/',
        'epicbox://$_e',
        'EPICBOX://$_e',
      ]) {
        final code = _scan(text);
        expect(code, isA<ScannedAddress>(), reason: text);
        expect((code as ScannedAddress).recipient.address, _e, reason: text);
      }
    });

    test('wrappers that are not Stack’s stay junk', () {
      for (final text in [
        'mailto:mailto:$_e',
        'http://http://$_e',
        'ftp://$_e',
        '<$_e>',
        '"$_e"',
        '$_e,',
        'epic:mailto:$_e',
      ]) {
        expect(_scan(text), isNot(isA<PaymentRequest>()), reason: text);
        expect(_scan(text), isNot(isA<ScannedAddress>()), reason: text);
      }
    });

    test('an @ address behind http in a code is a bad address, not a URL', () {
      _refused('epic:http://$_e', UnknownReason.badAddress);
    });

    test('epicbox:// inside a code is the address', () {
      expect(_pay('epic:epicbox://$_e').recipient.address, _e);
    });

    test('a percent-encoded address is no address', () {
      _refused(
        'epic:esWxbo%42PMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com',
        UnknownReason.badAddress,
      );
      _refused('epic:$_key%40epicbox.epiccash.com', UnknownReason.badAddress);
      _refused('epic:http%3A%2F%2F1.2.3.4%3A3415', UnknownReason.badAddress);
    });

    test('odd places for # and ?', () {
      _refused('epic:#$_e');
      _refused('epic:?$_e');
      expect(_pay('epic:$_e#').recipient.address, _e);
      expect(_pay('epic:$_e?').problems, isEmpty);
      expect(_pay('epic:$_e??amount=1').amount, isNull);
      expect(_pay('epic:$_e?#amount=1').amount, isNull);
    });
  });

  group('very long input', () {
    test('a megabyte of anything is not an Epic code, and quick', () {
      final watch = Stopwatch()..start();
      _refused('a' * 1000000);
      _refused('epic:$_e?message=${'a' * 1000000}');
      _refused('epic:${'a' * 1000000}');
      _refused('%' * 1000000);
      _refused('ur:${'a' * 1000000}');
      expect(
        _scan('{"version_info": 1, ${'"x": 1, ' * 100000}}'),
        isA<SlateText>(),
      );
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    });
  });

  group('8 purity', () {
    test('scan_router.dart imports no I/O, network, Flutter or app state', () {
      final source = File('lib/src/scan/scan_router.dart').readAsStringSync();
      final imports = RegExp(
        r'''^(?:import|export)\s+['"]([^'"]+)['"]''',
        multiLine: true,
      ).allMatches(source).map((m) => m[1]!).toList();
      expect(imports, ['dart:convert', '../amount.dart', '../payment_method.dart', '../recipient.dart']);
      for (final banned in [
        'dart:io',
        'dart:ffi',
        'dart:isolate',
        'package:http',
        'package:flutter',
        'riverpod',
        'providers',
        'wallet_service',
        'lepic',
      ]) {
        expect(
          imports.where((i) => i.contains(banned)),
          isEmpty,
          reason: banned,
        );
      }
      // What it pulls in: recipient.dart takes only two pure helpers from wallet_service.dart.
      final recipient = File('lib/src/recipient.dart').readAsStringSync();
      expect(
        recipient,
        contains(
          "import 'wallet_service.dart' show onionAddressFormat, onionHost;",
        ),
      );
      // payment_method.dart (the MethodKind a link names) is pure Dart: it imports only recipient.dart.
      final method = File('lib/src/payment_method.dart').readAsStringSync();
      expect(
        RegExp(r'''^import\s+['"]([^'"]+)['"]''', multiLine: true).allMatches(method).map((m) => m[1]!).toList(),
        ['recipient.dart'],
      );
    });
  });

  group('9 fuzz', () {
    const seeds = [
      'epic:$_e',
      'epic:$_e?amount=1.5&message=Lunch%20with%20Anna&label=Anna&method=direct&direct=http%3A%2F%2F1.2.3.4%3A3415',
      'epiccash://$_e?amount=0.00000001',
      'epic:$_d?amount=21000000000',
      'epic:$_o?message=%F0%9F%8D%95',
      'EPIC:$_floonet?AMOUNT=3',
      'epiccash://pair/1/AbCdEf',
      'ur:epic-slate/1-3/lpadcfaxhd',
      _e,
      _o,
      'https://$_e/',
      'mailto:$_e',
      '{"version_info":{}}',
      'BEGINSLATEPACK. abc. ENDSLATEPACK.',
    ];
    final alphabet = [
      ...'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.split(
        '',
      ),
      ...':/?#&=+%@.-_~ []!*\'(),;\\"<>{}|^`'.split(''),
      ...[
        '\n',
        '\r',
        '\t',
        '%00',
        '%25',
        '%E2%80%AE',
        '%F0',
        '%C3%A9',
        'epic:',
        'epiccash:',
        '//',
        'amount=',
        'message=',
        'label=',
        'method=direct',
        'direct=',
        '.onion',
        'http://',
        '@',
      ],
      for (final cp in [
        0x00,
        0x1F,
        0x7F,
        0x85,
        0xA0,
        0x061C,
        0x200B,
        0x200D,
        0x202E,
        0x2028,
        0x2066,
        0xFEFF,
        0xFFFD,
        0xD800,
        0xDC00,
        0x0430,
        0x0E01,
        0x5348,
        0xFF11,
      ])
        _c(cp),
      '🍕',
    ];

    String randomText(Random r) {
      final out = StringBuffer();
      final n = r.nextInt(r.nextInt(10) == 0 ? 5000 : 200);
      for (var i = 0; i < n; i++) {
        out.write(alphabet[r.nextInt(alphabet.length)]);
      }
      return out.toString();
    }

    String mutate(Random r, String text) {
      var t = text;
      for (var k = r.nextInt(6) + 1; k > 0; k--) {
        final at = t.isEmpty ? 0 : r.nextInt(t.length + 1);
        switch (r.nextInt(8)) {
          case 0: // insert
            t =
                t.substring(0, at) +
                alphabet[r.nextInt(alphabet.length)] +
                t.substring(at);
          case 1: // delete
            if (at < t.length) t = t.substring(0, at) + t.substring(at + 1);
          case 2: // replace
            if (at < t.length) {
              t =
                  t.substring(0, at) +
                  alphabet[r.nextInt(alphabet.length)] +
                  t.substring(at + 1);
            }
          case 3: // duplicate a slice
            final end = at + r.nextInt(40);
            t =
                t.substring(0, at) +
                t.substring(at, min(end, t.length)) * 2 +
                t.substring(min(end, t.length));
          case 4: // flip case
            t = r.nextBool() ? t.toUpperCase() : t.toLowerCase();
          case 5: // splice two seeds
            t = t.substring(0, at) + seeds[r.nextInt(seeds.length)];
          case 6: // percent-encode a character
            if (at < t.length) {
              final hex = t.codeUnitAt(at).toRadixString(16).padLeft(2, '0');
              t = '${t.substring(0, at)}%${hex.length > 2 ? hex.substring(0, 2) : hex}${t.substring(at + 1)}';
            }
          case 7: // a parameter more
            t = '$t${t.contains('?') ? '&' : '?'}${['amount', 'message', 'label', 'method', 'direct', 'x'][r.nextInt(6)]}=${alphabet[r.nextInt(alphabet.length)]}';
        }
      }
      return t;
    }

    void holds(String text) {
      final ScannedCode code;
      try {
        code = classifyScan(text, check: _check);
      } on Object catch (e) {
        fail(
          'threw $e on ${text.length > 200 ? text.substring(0, 200) : text}',
        );
      }
      switch (code) {
        case PaymentRequest p:
          expect(_check(p.recipient), AddressVerdict.valid, reason: text);
          expect(
            RegExp(r'^[\x21-\x7e]+$').hasMatch(p.recipient.address),
            isTrue,
            reason: text,
          );
          final direct = p.direct;
          if (direct != null) {
            expect(_check(direct), AddressVerdict.valid, reason: text);
            expect(direct.kind, isNot(RecipientKind.epicbox), reason: text);
          }
          final amount = p.amount;
          if (amount != null) {
            expect(amount > BigInt.zero, isTrue, reason: text);
            expect(
              amount <= BigInt.from(maxUriAmountEpic) * _epic,
              isTrue,
              reason: text,
            );
          }
          for (final (value, cap) in [
            (p.note, maxNoteLength),
            (p.label, maxLabelLength),
          ]) {
            if (value == null) continue;
            expect(value.runes.length, inInclusiveRange(1, cap), reason: text);
            expect(
              untrustedTextForbidden.hasMatch(value),
              isFalse,
              reason: text,
            );
            expect(value, value.trim(), reason: text);
          }
        case ScannedAddress a:
          expect(_check(a.recipient), AddressVerdict.valid, reason: text);
        case WrongNetwork w:
          expect(_check(w.recipient), AddressVerdict.otherChain, reason: text);
        case UnknownCode u:
          expect(
            u.text.contains('\n') || u.text.contains('\r'),
            isFalse,
            reason: text,
          );
        case SlateFrames f:
          expect(f.text.toLowerCase(), startsWith('ur:epic-slate/'));
        case PairingLink l:
          expect(
            l.text.toLowerCase(),
            matches(
              RegExp(r'^epic(cash)?://(pair|pair-reply|pair-confirm|contact)/'),
            ),
          );
        case SlateText _:
          break;
      }
    }

    test(
      '10,000 random and 10,000 mutated texts: no throw, no unchecked address',
      () {
        final r = Random(20261024);
        var payments = 0;
        for (var i = 0; i < 10000; i++) {
          holds(randomText(r));
        }
        for (var i = 0; i < 10000; i++) {
          final text = mutate(r, seeds[r.nextInt(seeds.length)]);
          holds(text);
          if (_scan(text) is PaymentRequest) payments++;
        }
        // The mutations must reach the payment parser often, or the fuzz proves little.
        expect(payments, greaterThan(400));
      },
    );
  });

  group('10 dispatch only', () {
    test(
      'slate parts and pairing links come back untouched, no address checked',
      () {
        var checks = 0;
        AddressVerdict counting(Recipient to) {
          checks++;
          return _check(to);
        }

        final frame = 'ur:epic-slate/2-9/${'lpadcfaxhdbbnbdnryky' * 200}';
        final pair = 'epiccash://pair/1/${'AbC-_' * 800}';
        final odd = 'UR:EPIC-SLATE/1-7/${'X' * 100}%00%ZZ&amount=1';
        for (final (text, type) in [
          (frame, SlateFrames),
          (odd, SlateFrames),
          (pair, PairingLink),
          ('epiccash://contact/1/${'z' * 3000}', PairingLink),
          ('epic://pair-confirm/1/x?amount=1', PairingLink),
        ]) {
          final code = classifyScan(text, check: counting);
          expect(
            code.runtimeType,
            type,
            reason: text.substring(0, min(40, text.length)),
          );
          final out = switch (code) {
            SlateFrames f => f.text,
            PairingLink l => l.text,
            _ => null,
          };
          expect(out, text);
        }
        expect(checks, 0);
      },
    );

    test('a slate file is handed on whole, unchecked', () {
      var checks = 0;
      const slate =
          '{"version_info":{"version":3},"sta":"S1","amount":"100000000","id":"$_e"}';
      final code = classifyScan(
        slate,
        check: (to) {
          checks++;
          return AddressVerdict.valid;
        },
      );
      expect((code as SlateText).text, slate);
      expect(checks, 0);
    });
  });
}
