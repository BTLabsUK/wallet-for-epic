// The `epic:` payment URI and the scan router (spec docs/feedback/designs/epic-uri/spec.md):
// the vectors of §2.5, the routing table of §3.1, build → parse round trips, the Send
// address rule, and the strings Stack Wallet and Epic Pay write.

import 'package:epic_wallet/src/recipient.dart';
import 'package:epic_wallet/src/scan/scan_checks.dart';
import 'package:epic_wallet/src/scan/scan_router.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _key = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK';

/// A valid Epicbox address (E of §2.5).
const _e = '$_key@epicbox.epiccash.com';

/// A valid Epicbox address of the other chain, as the stub tells it.
const _floonet =
    'fsWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com';

/// A Direct HTTP address (D).
const _d = 'http://1.2.3.4:3415';

const _onion = 'wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid';

/// A Direct Tor address (O).
const _o = 'http://$_onion.onion';

/// The address checks, the way Send runs them, with [_floonet] on the other chain.
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

UnknownCode _unknown(
  String text, [
  UnknownReason reason = UnknownReason.notEpic,
]) {
  final code = _scan(text);
  expect(code, isA<UnknownCode>(), reason: text);
  final unknown = code as UnknownCode;
  expect(unknown.reason, reason, reason: text);
  return unknown;
}

BigInt _atomic(int epic, [int fraction = 0]) =>
    BigInt.from(epic) * BigInt.from(100000000) + BigInt.from(fraction);

void main() {
  test('the test addresses are what the checks say', () {
    expect(_key.length, 52);
    expect(_check(parseRecipient(_e)), AddressVerdict.valid);
    expect(_check(parseRecipient(_floonet)), AddressVerdict.otherChain);
    expect(_check(parseRecipient(_d)), AddressVerdict.valid);
    expect(_check(parseRecipient(_o)), AddressVerdict.valid);
  });

  group('§2.5 vectors', () {
    test('1 epic:E is an Epicbox payment with no amount', () {
      final p = _pay('epic:$_e');
      expect(p.recipient.kind, RecipientKind.epicbox);
      expect(p.recipient.address, _e);
      expect(p.amount, isNull);
      expect(p.note, isNull);
      expect(p.label, isNull);
      expect(p.method, isNull);
      expect(p.direct, isNull);
      expect(p.problems, isEmpty);
    });

    test('2 amount 1.5', () {
      expect(_pay('epic:$_e?amount=1.5').amount, _atomic(1, 50000000));
    });

    test('3 amount and a %20 note', () {
      final p = _pay('epic:$_e?amount=1.5&message=Lunch%20with%20Anna');
      expect(p.amount, _atomic(1, 50000000));
      expect(p.note, 'Lunch with Anna');
    });

    test("4 Stack's + is a space", () {
      final p = _pay('epic:$_e?amount=2&message=a+b');
      expect(p.amount, _atomic(2));
      expect(p.note, 'a b');
    });

    test('5 scheme and parameter names are case-insensitive', () {
      final p = _pay('EPIC:$_e?AMOUNT=3');
      expect(p.amount, _atomic(3));
      expect(p.recipient.address, _e, reason: 'the address keeps its case');
    });

    test('6 epiccash: reads the same', () {
      expect(_pay('epiccash:$_e?amount=3').amount, _atomic(3));
    });

    test('7 epic:// is tolerated', () {
      final p = _pay('epic://$_e?amount=3');
      expect(p.amount, _atomic(3));
      expect(p.recipient.address, _e);
    });

    test('8 Direct HTTP and Tor', () {
      final http = _pay('epic:$_d?amount=1');
      expect(http.recipient.kind, RecipientKind.http);
      expect(http.recipient.address, _d);
      expect(http.amount, _atomic(1));
      final tor = _pay('epic:$_o');
      expect(tor.recipient.kind, RecipientKind.tor);
      expect(tor.recipient.address, '$_onion.onion');
    });

    test('9 amount zero is invalid, the address kept', () {
      final p = _pay('epic:$_e?amount=0');
      expect(p.amount, isNull);
      expect(p.problems, {RequestProblem.amountInvalid});
      expect(p.recipient.address, _e);
    });

    test('10 nine decimals are invalid', () {
      final p = _pay('epic:$_e?amount=0.000000001');
      expect(p.amount, isNull);
      expect(p.problems, {RequestProblem.amountInvalid});
    });

    for (final bad in ['1,5', '-5', '1e3', '1_000', '.5', '5.', ' 5', '%205']) {
      test('11 amount "$bad" is invalid', () {
        final p = _pay('epic:$_e?amount=$bad');
        expect(p.amount, isNull);
        expect(p.problems, {RequestProblem.amountInvalid});
      });
    }

    test('12 an empty amount is invalid', () {
      final p = _pay('epic:$_e?amount=');
      expect(p.amount, isNull);
      expect(p.problems, {RequestProblem.amountInvalid});
      // No `=` at all is the same empty value.
      expect(_pay('epic:$_e?amount').problems, {RequestProblem.amountInvalid});
    });

    test('13 a repeated amount refuses the whole code', () {
      _unknown('epic:$_e?amount=1&amount=2');
    });

    test('14 an unknown parameter is ignored', () {
      final p = _pay('epic:$_e?foo=bar&amount=1');
      expect(p.amount, _atomic(1));
      expect(p.problems, isEmpty);
    });

    test('15 label, method hint and a second Direct address', () {
      final p = _pay('epic:$_e?label=Anna&method=direct&direct=$_d');
      expect(p.label, 'Anna');
      expect(p.method, MethodHint.direct);
      expect(p.direct?.kind, RecipientKind.http);
      expect(p.direct?.address, _d);
      expect(p.recipient.address, _e);
    });

    test('16 an unknown method is ignored', () {
      final p = _pay('epic:$_e?method=carrier-pigeon');
      expect(p.method, isNull);
      expect(p.problems, isEmpty);
    });

    test('17 %25 is a percent sign', () {
      expect(_pay('epic:$_e?message=100%25%20sure').note, '100% sure');
    });

    test('18 a bad escape drops the note only', () {
      final p = _pay('epic:$_e?message=%ZZ&amount=1');
      expect(p.note, isNull);
      expect(p.amount, _atomic(1));
      expect(p.problems, isEmpty);
    });

    test('19 no address is not an Epic code', () {
      _unknown('epic:');
      _unknown('epic:?amount=1');
      _unknown('epiccash://');
    });

    test('20 an address that is not one', () {
      _unknown('epic:notanaddress', UnknownReason.badAddress);
    });

    test('21 a huge amount is too large', () {
      final p = _pay('epic:$_e?amount=99999999999999999999999');
      expect(p.amount, isNull);
      expect(p.problems, {RequestProblem.amountTooLarge});
    });

    test('22 bare addresses are addresses, not payments', () {
      for (final (text, kind) in [
        (_e, RecipientKind.epicbox),
        (_d, RecipientKind.http),
        (_o, RecipientKind.tor),
      ]) {
        final code = _scan(text);
        expect(code, isA<ScannedAddress>(), reason: text);
        expect((code as ScannedAddress).recipient.kind, kind);
      }
    });

    test('23 other coins and web pages are not Epic codes', () {
      _unknown('bitcoin:1abc?amount=1');
      _unknown('https://example.com/pay?amount=1');
    });

    test('24 a pairing link is not a payment', () {
      final code = _scan('epiccash://pair/1/AbCdEf');
      expect(code, isA<PairingLink>());
      expect((code as PairingLink).kind, PairingKind.invite);
    });

    test('25 only the first line is read', () {
      expect(_pay('epic:$_e\nsecond line').recipient.address, _e);
      expect(_pay('epic:$_e?amount=1\r\nsecond').amount, _atomic(1));
      expect(_pay('epic:$_e?amount=1\rsecond').amount, _atomic(1));
    });

    test('26 the fragment is ignored', () {
      final p = _pay('epic:$_e?amount=1#frag');
      expect(p.amount, _atomic(1));
      expect(p.problems, isEmpty);
    });
  });

  group('§3.1 routing table', () {
    test('1 ur:epic-slate parts, in any case, untouched', () {
      for (final text in [
        'ur:epic-slate/1-7/lpadcfaxhd',
        'UR:EPIC-SLATE/1-7/LPADCFAXHD',
      ]) {
        final code = _scan(text);
        expect(code, isA<SlateFrames>(), reason: text);
        expect((code as SlateFrames).text, text);
      }
    });

    test('2 any other ur: type is not an Epic code', () {
      _unknown('ur:bytes/1-3/lpadcfaxhd');
      _unknown('UR:CRYPTO-PSBT/abc');
    });

    test('3 pairing links, epic or epiccash, any case', () {
      for (final (text, kind) in [
        ('epiccash://pair/1/AbC', PairingKind.invite),
        ('epiccash://pair-reply/1/AbC', PairingKind.reply),
        ('epiccash://pair-confirm/1/AbC', PairingKind.confirm),
        ('epic://pair/1/AbC', PairingKind.invite),
        ('EPICCASH://PAIR/1/AbC', PairingKind.invite),
      ]) {
        final code = _scan(text);
        expect(code, isA<PairingLink>(), reason: text);
        expect((code as PairingLink).kind, kind, reason: text);
        expect(code.text, text);
      }
    });

    test('4 contact cards', () {
      final code = _scan('epiccash://contact/1/AbC');
      expect(code, isA<PairingLink>());
      expect((code as PairingLink).kind, PairingKind.contact);
    });

    test('a pairing word without a payload is not a pairing link', () {
      _unknown('epiccash://pair', UnknownReason.badAddress);
      _unknown('epiccash://pairing/1/AbC', UnknownReason.badAddress);
    });

    test(
      '5 an epic: code with ur:epic-slate in it is a bad address, not slates',
      () {
        _unknown('epic:ur:epic-slate/1-3/lpadcfaxhd', UnknownReason.badAddress);
        _unknown(
          'epiccash:UR:EPIC-SLATE/1-3/LPADCFAXHD',
          UnknownReason.badAddress,
        );
        // In a note it is just text.
        expect(
          _pay('epic:$_e?message=ur:epic-slate/1-3/x').note,
          'ur:epic-slate/1-3/x',
        );
      },
    );

    test('6, 7 bare addresses', () {
      expect(_scan(_e), isA<ScannedAddress>());
      expect(_scan('$_onion.onion'), isA<ScannedAddress>());
      expect(_scan(_onion), isA<ScannedAddress>());
      expect(
        _scan('https://pay.example.org/v2/foreign'),
        isA<ScannedAddress>(),
      );
    });

    test('8 anything else is not an Epic code', () {
      for (final text in [
        '',
        '   ',
        'hello',
        'Anna',
        '12345',
        '@',
        'epic',
        'epicbox',
      ]) {
        _unknown(text);
      }
    });

    test('the Unknown text is the first line, trimmed, for Copy', () {
      expect(
        _unknown('  hello world \nsecret second line').text,
        'hello world',
      );
    });

    test('transaction files are SlateText, the whole text', () {
      const json = '{\n  "version_info": {"version": 3},\n  "id": "x"\n}';
      final code = _scan(json);
      expect(code, isA<SlateText>());
      expect((code as SlateText).text, json);
      expect(_scan('{"ver":"4:3","id":"x"}'), isA<SlateText>());
      expect(_scan('BEGINSLATEPACK. abc def. ENDSLATEPACK.'), isA<SlateText>());
      expect(_scan('BEGIN SLATEPACK. abc'), isA<SlateText>());
      // JSON that is no slate is nothing of ours.
      _unknown('{"hello": 1}');
    });

    test('the other chain is WrongNetwork, bare or in a code', () {
      for (final text in [_floonet, 'epic:$_floonet?amount=1']) {
        final code = _scan(text);
        expect(code, isA<WrongNetwork>(), reason: text);
        expect((code as WrongNetwork).recipient.address, _floonet);
      }
    });
  });

  group('build', () {
    test('the plain Receive code is just the address', () {
      expect(EpicUri.build(_e), 'epic:$_e');
      expect(
        EpicUri.build(_e, amount: BigInt.zero, note: '', label: ''),
        'epic:$_e',
      );
    });

    test('amounts in their shortest form', () {
      for (final (atomic, text) in [
        (_atomic(1), '1'),
        (_atomic(1, 50000000), '1.5'),
        (BigInt.one, '0.00000001'),
        (_atomic(10), '10'),
        (_atomic(21000000000), '21000000000'),
        (_atomic(0, 10000000), '0.1'),
        (_atomic(1, 1), '1.00000001'),
      ]) {
        expect(EpicUri.build(_e, amount: atomic), 'epic:$_e?amount=$text');
      }
    });

    test('parameters in the spec order, uppercase hex', () {
      expect(
        EpicUri.build(
          _e,
          amount: _atomic(1, 50000000),
          note: 'Lunch with Anna',
          label: 'Café',
          method: MethodHint.direct,
          direct: _d,
        ),
        'epic:$_e?amount=1.5&message=Lunch%20with%20Anna&label=Caf%C3%A9'
        '&method=direct&direct=http%3A%2F%2F1.2.3.4%3A3415',
      );
    });

    test('encodeUriValue keeps only the unreserved characters', () {
      expect(encodeUriValue('AZaz09-._~'), 'AZaz09-._~');
      expect(encodeUriValue(' %&=#?+/'), '%20%25%26%3D%23%3F%2B%2F');
      expect(encodeUriValue('é'), '%C3%A9');
      expect(encodeUriValue('🍕'), '%F0%9F%8D%95');
    });

    const texts = [
      'Lunch with Anna',
      'ค่าอาหารกลางวัน', // Thai
      '午饭钱', // Chinese
      'Обед с Анной', // Cyrillic
      'Pizza 🍕 and 👨‍👩‍👧 ❤️', // emoji, outside the BMP; ZWJ sequences lose their joiners
      'a+b & c=d #1 ?x %41 100%',
      "Zoë's café — naïve",
      'العربية', // Arabic, right to left
    ];
    for (final text in texts) {
      test('round trip: $text', () {
        final uri = EpicUri.build(
          _e,
          amount: _atomic(12, 34500000),
          note: text,
          label: String.fromCharCodes(text.runes.take(20)),
          method: MethodHint.epicbox,
        );
        final p = _pay(uri);
        expect(p.amount, _atomic(12, 34500000));
        expect(p.note, cleanUntrustedText(text));
        expect(
          p.label,
          cleanUntrustedText(String.fromCharCodes(text.runes.take(20))),
        );
        expect(p.method, MethodHint.epicbox);
        expect(p.problems, isEmpty);
      });
    }

    test('round trip: the note is cleaned on the way in', () {
      final p = _pay(EpicUri.build(_e, note: '  two\nlines\u202E  '));
      expect(p.note, 'two lines');
    });

    test('round trip: every amount from 1 atomic unit to the ceiling', () {
      for (final atomic in [
        BigInt.one,
        BigInt.from(99999999),
        _atomic(1),
        _atomic(1, 1),
        _atomic(123456789, 12345678),
        _atomic(21000000000),
      ]) {
        expect(_pay(EpicUri.build(_e, amount: atomic)).amount, atomic);
      }
    });

    test('round trip: Direct and Tor codes', () {
      final p = _pay(EpicUri.build(_e, method: MethodHint.direct, direct: _o));
      expect(p.direct?.kind, RecipientKind.tor);
      expect(p.direct?.address, '$_onion.onion');
      expect(_pay(EpicUri.build(_d, amount: _atomic(2))).recipient.address, _d);
      expect(_pay(EpicUri.build(_o)).recipient.kind, RecipientKind.tor);
    });

    test('a 264-character note in four-byte characters fits every cap', () {
      final note = '🍕' * maxNoteLength;
      final uri = EpicUri.build(_e, amount: _atomic(1), note: note);
      expect(uri.length, lessThanOrEqualTo(maxScanLength));
      final p = _pay(uri);
      expect(p.note, note);
      expect(p.problems, isEmpty);
    });
  });

  group('parseUriAmount', () {
    test('exact atomic units, no float error', () {
      expect(parseUriAmount('1.1'), (_atomic(1, 10000000), null));
      expect(parseUriAmount('0.3'), (BigInt.from(30000000), null));
      expect(parseUriAmount('0.00000001'), (BigInt.one, null));
      expect(parseUriAmount('1.10000000'), (_atomic(1, 10000000), null));
      expect(parseUriAmount('21000000000'), (_atomic(21000000000), null));
    });
  });

  group('recipientFor', () {
    test('Direct when the code asks and Send allows it', () {
      final p = _pay('epic:$_e?method=direct&direct=$_d');
      expect(p.recipientFor(directAllowed: true).address, _d);
      expect(p.recipientFor(directAllowed: false).address, _e);
    });

    test('the code’s own address without method=direct', () {
      expect(
        _pay('epic:$_e?direct=$_d').recipientFor(directAllowed: true).address,
        _e,
      );
      expect(
        _pay('epic:$_e?method=epicbox&direct=$_d')
            .recipientFor(directAllowed: true)
            .address,
        _e,
      );
      expect(
        _pay('epic:$_e?method=direct')
            .recipientFor(directAllowed: true)
            .address,
        _e,
      );
    });

    test('a Direct code keeps its own address', () {
      final p = PaymentRequest(
        recipient: parseRecipient(_d),
        method: MethodHint.direct,
        direct: parseRecipient(_o),
      );
      expect(p.recipientFor(directAllowed: true).address, _d);
    });

    test('a direct= that is no Direct address is dropped silently', () {
      for (final bad in [
        _e,
        'notanaddress',
        'http://a@evil.com',
        'ftp://1.2.3.4',
      ]) {
        final p = _pay('epic:$_e?method=direct&direct=${encodeUriValue(bad)}');
        expect(p.direct, isNull, reason: bad);
        expect(p.problems, isEmpty);
        expect(p.recipientFor(directAllowed: true).address, _e);
      }
    });

    test('an address-form hint loses to the address', () {
      // The router only reads the hint; the form decides which method Send uses.
      final p = _pay('epic:$_d?method=epicbox');
      expect(p.recipient.kind, RecipientKind.http);
      expect(p.recipientFor(directAllowed: true).address, _d);
    });
  });

  group('scanCheckFor on the fake wallet service', () {
    final service = FakeWalletService();

    test('reads codes with the service checks', () {
      expect(classifyFor(service, 'epic:$_e?amount=1'), isA<PaymentRequest>());
      expect(classifyFor(service, 'epic:$_o'), isA<PaymentRequest>());
      expect(classifyFor(service, _d), isA<ScannedAddress>());
      final bad = classifyFor(service, 'epic:${_key}0@epicbox.epiccash.com');
      expect((bad as UnknownCode).reason, UnknownReason.badAddress);
    });

    test('the verdicts', () {
      final check = scanCheckFor(service);
      expect(check(parseRecipient(_e)), AddressVerdict.valid);
      expect(
        check(parseRecipient('${_key}x@epicbox.epiccash.com')),
        AddressVerdict.invalid,
      );
      expect(check(parseRecipient(_o)), AddressVerdict.valid);
      expect(check(parseRecipient(_d)), AddressVerdict.valid);
      expect(
        check(const Recipient(RecipientKind.http, 'http://1.2.3')),
        AddressVerdict.invalid,
      );
    });
  });

  // Strings Stack Wallet (8897d01) and Epic Pay (41d4329) write, from their sources under
  // /opt/epic/reference. Stack: generate_receiving_uri_qr_code_view.dart:145-196 puts `amount`
  // (Decimal.toString) and `message` (the note) in a map; AddressUtils.buildUriString
  // (utilities/address_utils.dart:179-226) appends Uri(queryParameters:).toString(), which
  // writes a space as `+` and percent-encodes everything outside `A-Za-z0-9-._~` in
  // uppercase. Its receive screen and address cards write a bare `epic:<address>`
  // (receive_view.dart:847). Epic Pay writes only `epic:<address>`
  // (pages/receive_view/receive_view.dart:156). The strings below were produced by running
  // verbatim copies of those functions with `dart run`, outside this repo.
  group('Stack Wallet and Epic Pay codes', () {
    test("Stack's amount and note", () {
      final p = _pay('epic:$_e?amount=1.5&message=Lunch+with+Anna');
      expect(p.amount, _atomic(1, 50000000));
      expect(p.note, 'Lunch with Anna');
    });

    test("Stack's escapes", () {
      expect(_pay('epic:$_e?message=100%25+sure').note, '100% sure');
      expect(
        _pay('epic:$_e?message=a%2Bb+%26+c%3Dd+%231+%3Fx').note,
        'a+b & c=d #1 ?x',
      );
      expect(_pay('epic:$_e?message=~-._%21%2A%27%28%29').note, "~-._!*'()");
    });

    test("Stack's notes in other scripts", () {
      expect(
        _pay(
          'epic:$_e?message=%E0%B8%84%E0%B9%88%E0%B8%B2%E0%B8%AD%E0%B8%B2%E0%B8%AB%E0%B8%B2%E0%B8%A3'
          '+%E5%8D%88%E9%A5%AD+%D0%9E%D0%B1%D0%B5%D0%B4+%F0%9F%8D%95',
        ).note,
        'ค่าอาหาร 午饭 Обед 🍕',
      );
    });

    test(
      "Stack's label comes first; we keep it as the payee name, not the note",
      () {
        // Stack shows `label` as the note when `message` is missing (send_view.dart:165-169);
        // spec §2.3: we do not.
        final p = _pay('epic:$_e?label=Anna&message=x');
        expect(p.label, 'Anna');
        expect(p.note, 'x');
        final only = _pay('epic:$_e?label=Anna');
        expect(only.label, 'Anna');
        expect(only.note, isNull);
      },
    );

    test('the plain codes of both', () {
      expect(_pay('epic:$_e').recipient.address, _e);
      expect(_pay('epic:$_e?amount=2').amount, _atomic(2));
    });

    test("Stack's lenient amounts are strict here", () {
      // Stack's _normalizeAmount (address_utils.dart:123-133) keeps only digits and dots;
      // its own QR screen never writes these, but a hand-made code might.
      for (final bad in ['-5', '1,5', '1.123456789']) {
        expect(_pay('epic:$_e?amount=$bad').amount, isNull, reason: bad);
      }
    });

    // How they read OUR codes, from their parse code (and the same `dart run` copies):
    //
    // Stack (AddressUtils.parsePaymentUri → _parseUri, address_utils.dart:46-175;
    // send_view.dart:251-258 and :319-326 only take it when the scheme is exactly `epic`):
    // - address = Uri.parse(text).path: right for `epic:E`, `epic:http://1.2.3.4:3415`,
    //   `epic:<onion>.onion`. Not for `epic://E` (the address becomes the authority and the
    //   path is empty), which we never write.
    // - `amount`: our shortest form (`1`, `1.5`, `0.00000001`) is what Decimal.parse wants.
    // - Values are decoded twice: Uri.queryParameters, then Uri.decodeComponent. Our
    //   uppercase `%XX` and `%20` decode in the first pass, so ASCII notes and labels
    //   come out right. But Uri.decodeComponent throws on any character above U+007F and
    //   on a lone `%`, and Stack's catch then drops EVERY parameter, amount included: a code
    //   with a note in Thai, Chinese, Cyrillic, any accent or an emoji, or a note with a
    //   `%` in it, fills only the address in Stack. That holds for Stack's own codes too
    //   (`?amount=2&message=%D0%9E%D0%B1%D0%B5%D0%B4` reads as no amount, no note), so it
    //   is their bug, not our encoding. A note `%41` reads as `A` in Stack (second decode).
    // - `method` and `direct` are not in recognizedParams; they decode cleanly and are
    //   dropped, so a code with them works in Stack as a plain Epicbox code.
    // - `epiccash:` is not read by Stack (scheme check), so we write `epic:`.
    //
    // Epic Pay (utilities/address_utils.dart:46-58, send_view.dart:290-302): takes
    // Uri.parse(text).path when the scheme is `epic` and ignores every parameter, so any of
    // our codes fills the address and nothing else.
  });
}
