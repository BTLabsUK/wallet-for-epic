// SPDX-License-Identifier: Apache-2.0
// Live: the directory vectors (docs/design/directory-vectors.json) through the real LEPIC
// signature check, `verifyAddressSignatureAt`, instead of the unit test's oracle. Needs the
// shipped Linux library (no mock build is needed):
//
//   WFE_LEPIC_LIB=<folder>/liblepic_ffi.so flutter test test/directory_wire_live_test.dart
//
// Without it it is skipped.
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/directory/directory.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

import 'directory_vectors_support.dart';

final String? _lib = Platform.environment['WFE_LEPIC_LIB'];

Future<bool> _real(String keyText, String domain, Uint8List message, Uint8List der) async =>
    lepic.verifyAddressSignatureAt(publicKey: keyText, domain: domain, message: message, signature: toHex(der));

void main() {
  final skip = _lib == null ? 'set WFE_LEPIC_LIB to the shipped liblepic_ffi.so' : null;
  final v = loadVectors();

  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
  });

  test('the signature vectors', () {
    for (final e in vectorList(v['k3']! as Map<String, Object?>, 'verify')) {
      final ok = lepic.verifyAddressSignatureAt(
        publicKey: e['key_text']! as String,
        domain: e['domain']! as String,
        message: fromHex(e['message']! as String),
        signature: e['der']! as String,
      );
      expect(ok, e['valid'], reason: '${e['key_text']} ${e['domain']}');
    }
  }, skip: skip);

  group('good', () {
    for (final (kind, group) in [('card', 'cards'), ('payreq', 'payreqs'), ('payload', 'payloads')]) {
      for (final e in vectorList(v, group)) {
        test('$kind ${e['id']}', () async {
          await runEntry(kind, fromHex(e['hex']! as String), null, e['ctx']! as Map<String, Object?>, _real);
        }, skip: skip);
      }
    }
  });

  group('bad', () {
    for (final e in vectorList(v, 'bad')) {
      final error = e['error'] as String?;
      test('${e['id']}: ${error ?? 'accepted'}', () async {
        final raw = e.containsKey('input_hex') ? fromHex(e['input_hex']! as String) : null;
        final run = runEntry(e['kind']! as String, raw, e['input_text'] as String?, e['ctx']! as Map<String, Object?>, _real);
        if (error == null) {
          await run;
        } else {
          await expectLater(run, throwsA(isA<DirectoryException>().having((x) => x.error.wireName, 'error', error)));
        }
      }, skip: skip);
    }
  });
}
