// SPDX-License-Identifier: Apache-2.0
// The name service wire codec (docs/design/name-service-wire.md) against the shared vectors
// (docs/design/name-service-vectors.json): every good vector parses to its listed fields and
// encodes back to the same bytes; every bad one gives its listed error under its context.
import 'dart:typed_data';

import 'package:epic_wallet/src/name_service/name_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'name_service_vectors_support.dart';

/// The signature oracle. It is sound because the vector file lists every signature a real signer
/// made, as (key, domain, message, DER) tuples: asking whether a tuple is listed is asking
/// whether the signer signed those bytes. So:
/// - an entry that must fail before the signature check must never reach the verifier;
/// - an entry that must fail the signature check is answered from the listed tuples, so a
///   tampered or re-signed message is not listed and fails;
/// - an entry that passes the check (accepted, or failing a later step) was signed fresh for
///   its case and is not listed, so the check is answered true;
/// - a good entry may only ask for tuples it lists itself.
/// The live test (name_service_wire_live_test.dart) runs the same vectors through the real
/// verifier, which takes the oracle out of the argument.
class _Oracle {
  _Oracle(this.listed, this.mode, [this.own]);

  final Set<String> listed;
  final String mode; // never | listed | yes | own
  final Set<String>? own;
  int calls = 0;

  Future<bool> call(String keyText, String domain, Uint8List message, Uint8List der) async {
    calls++;
    final key = callKey(keyText, domain, message, der);
    switch (mode) {
      case 'never':
        throw StateError('the verifier was called');
      case 'listed':
        return listed.contains(key);
      case 'own':
        expect(own, contains(key), reason: 'a call the entry does not list');
        return true;
      default:
        return true;
    }
  }
}

void main() {
  final v = loadVectors();
  final listed = listedValidCalls(v);

  test('the vector file is the one the codec was written for', () {
    expect((v['errors']! as List<Object?>).length, NameServiceError.values.length);
    for (final e in v['errors']! as List<Object?>) {
      expect(NameServiceError.values.map((x) => x.wireName), contains(e));
    }
  });

  group('key text', () {
    for (final k in vectorList(v, 'key_text')) {
      test('key ${k['n']} in both networks', () {
        final key = fromHex(k['pubkey']! as String);
        expect(epicboxKeyText(key, netMainnet), k['mainnet']);
        expect(epicboxKeyText(key, netFloonet), k['floonet']);
        final main = parseEpicboxKeyText(k['mainnet']! as String)!;
        expect((main.$1, toHex(main.$2)), (netMainnet, k['pubkey']));
        final flo = parseEpicboxKeyText(k['floonet']! as String)!;
        expect((flo.$1, toHex(flo.$2)), (netFloonet, k['pubkey']));
      });
    }

    test('a changed character or a short text is not a key', () {
      final text = (vectorList(v, 'key_text').first['mainnet']! as String);
      final other = text.substring(0, 5) + (text[5] == 'a' ? 'b' : 'a') + text.substring(6);
      expect(parseEpicboxKeyText(other), isNull);
      expect(parseEpicboxKeyText(text.substring(1)), isNull);
      expect(parseEpicboxKeyText(''), isNull);
    });
  });

  group('codes', () {
    test('service codes', () {
      for (final c in (v['codes']! as Map<String, Object?>)['directory']! as List<Object?>) {
        final m = c! as Map<String, Object?>;
        final indexes = nameServiceCodeIndexes(fromHex(m['dkey']! as String));
        expect(indexes, m['indexes']);
        expect(codeEmoji(indexes), m['emoji']);
        expect(codeWords(indexes).map((w) => w.name), m['names']);
      }
    });

    test('listing codes', () {
      for (final c in (v['codes']! as Map<String, Object?>)['listing']! as List<Object?>) {
        final m = c! as Map<String, Object?>;
        final indexes = listingCodeIndexes(fromHex(m['key']! as String));
        expect(indexes, m['indexes']);
        expect(codeEmoji(indexes), m['emoji']);
        expect(codeWords(indexes).map((w) => w.name), m['names']);
      }
    });
  });

  group('good cards', () {
    for (final e in vectorList(v, 'cards')) {
      test(e['id']! as String, () async {
        final raw = fromHex(e['hex']! as String);
        final card = ListingCard.decode(raw);
        expect(card.toFields(), e['fields']);
        expect(toHex(card.toBytes()), e['hex']);
        expect(toHex(card.listingKey), e['listing_key']);
        final code = e['listing_code']! as Map<String, Object?>;
        expect(listingCodeIndexes(card.listingKey), code['indexes']);
        final ctx = e['ctx']! as Map<String, Object?>;
        final oracle = _Oracle(listed, 'own', entryCalls(v, e));
        await runEntry('card', raw, null, ctx, oracle.call);
        expect(oracle.calls, 1);
      });
    }
  });

  group('encoders', () {
    // A card with an unknown tag keeps it for the signature; the encoder writes the known fields.
    for (final e in vectorList(v, 'cards').where((e) => (e['fields']! as Map<String, Object?>)['extra'] == null)) {
      test('card ${e['id']}', () {
        final card = ListingCard.decode(fromHex(e['hex']! as String));
        final unsigned = listingCardUnsigned(
          net: card.net,
          address: card.address,
          serviceKey: card.serviceKey,
          handle: card.handle,
          seq: card.seq,
          issued: card.issued.toInt(),
        );
        expect(toHex(unsigned), toHex(card.signedBytes));
        expect(toHex(withSignature(unsigned, card.signature!)), e['hex']);
      });
    }

    test('listing payload and unlist payload', () {
      for (final e in vectorList(v, 'payloads')) {
        final raw = fromHex(e['hex']! as String);
        final payload = NameServicePayload.decode(raw);
        switch (payload) {
          case ListingPayload():
            expect(toHex(listingPayloadBytes(payload.card.toBytes())), e['hex']);
          case UnlistPayload():
            final unsigned = unlistPayloadUnsigned(
              net: payload.net,
              address: payload.address,
              serviceKey: payload.serviceKey,
              handle: payload.handle,
              issued: payload.issued.toInt(),
            );
            expect(toHex(unsigned), toHex(payload.signedBytes));
            expect(toHex(withSignature(unsigned, payload.signature!)), e['hex']);
          default:
        }
      }
    });
  });

  group('good requests', () {
    for (final e in vectorList(v, 'payreqs')) {
      test(e['id']! as String, () async {
        final raw = fromHex(e['hex']! as String);
        final request = Payreq.decode(raw);
        expect(request.toFields(), e['fields']);
        expect(toHex(request.toBytes()), e['hex']);
        final text = e['text']! as Map<String, Object?>;
        expect(request.toText(), text['scheme']);
        expect(request.toText(host: 'links.example'), text['https']);
        expect(toHex(Payreq.fromText(text['scheme']! as String).toBytes()), e['hex']);
        expect(toHex(Payreq.fromText(text['https']! as String).toBytes()), e['hex']);
        final ctx = e['ctx']! as Map<String, Object?>;
        final oracle = _Oracle(listed, 'own', entryCalls(v, e));
        await runEntry('payreq', raw, null, ctx, oracle.call);
        expect(oracle.calls, 2);
      });
    }
  });

  group('good payloads', () {
    for (final e in vectorList(v, 'payloads')) {
      test(e['id']! as String, () async {
        final raw = fromHex(e['hex']! as String);
        final payload = NameServicePayload.decode(raw);
        expect(payload.type, e['type']);
        expect(payload.toFields(), e['fields']);
        expect(toHex(payload.toBytes()), e['hex']);
        final ctx = e['ctx']! as Map<String, Object?>;
        final oracle = _Oracle(listed, 'own', entryCalls(v, e));
        await runEntry('payload', raw, null, ctx, oracle.call);
      });
    }
  });

  group('hello', () {
    DirHello hello(String id) =>
        NameServicePayload.decode(fromHex(vectorList(v, 'payloads').firstWhere((e) => e['id'] == id)['hex']! as String)) as DirHello;

    test('the label is read, and the encoder writes it back into the signed bytes', () {
      final h = hello('hello-label');
      expect(h.label, '@alice_test');
      final unsigned = nsHelloUnsigned(
        net: h.net,
        serviceKey: h.serviceKey,
        handle: h.handle,
        bind: h.bind,
        issued: h.issued.toInt(),
        label: h.label,
      );
      expect(toHex(unsigned), toHex(h.signedBytes));
    });

    test('a label without @ is dropped and the hello still decodes', () {
      final bad = vectorList(v, 'bad').firstWhere((e) => e['id'] == 'hello-label-no-at');
      final h = NameServicePayload.decode(fromHex(bad['input_hex']! as String)) as DirHello;
      expect(h.label, isNull);
      expect(h.toFields(), bad['fields']);
    });

    test('field 07, the old flags, is malformed', () {
      final bad = vectorList(v, 'bad').firstWhere((e) => e['id'] == 'hello-field-07');
      expect(
        () => NameServicePayload.decode(fromHex(bad['input_hex']! as String)),
        throwsA(isA<NameServiceException>().having((x) => x.error.wireName, 'error', 'malformed')),
      );
    });
  });

  group('bad', () {
    for (final e in vectorList(v, 'bad')) {
      final error = e['error'] as String?;
      test('${e['id']}: ${error ?? 'accepted'}', () async {
        final kind = e['kind']! as String;
        final ctx = e['ctx']! as Map<String, Object?>;
        final mode = switch (error) {
          'checksum' || 'malformed' || 'network' => 'never',
          'signature' => 'listed',
          _ => 'yes',
        };
        final oracle = _Oracle(listed, mode);
        final raw = e.containsKey('input_hex') ? fromHex(e['input_hex']! as String) : null;
        final text = e['input_text'] as String?;
        if (error == null) {
          await runEntry(kind, raw, text, ctx, oracle.call);
          return;
        }
        await expectLater(
          runEntry(kind, raw, text, ctx, oracle.call),
          throwsA(isA<NameServiceException>().having((x) => x.error.wireName, 'error', error)),
        );
      });
    }
  });
}
