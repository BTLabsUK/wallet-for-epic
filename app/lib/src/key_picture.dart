// SPDX-License-Identifier: Apache-2.0
/// The key picture (docs/design/key-picture.md): a 5x5 identicon drawn from the inviter's
/// pairing key, so a person can see that the app opened the invite they tapped. It does not
/// prove who made the invite. [inviteKeyOf] reads the key (tag 08) from a pairing link, null
/// when the link's check or fields fail: no picture rather than a wrong one. [KeyPicture.of]
/// derives the picture; `ui/key_picture.dart` draws it. The test reads the spec's vectors.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Hashed before the key, so the picture is this feature's and no other use of the key's.
const String keyPictureLabel = 'BT Wallet key picture v1';

/// The tile behind the cells, the same in light and dark.
const int keyPictureTile = 0xFF141418;

/// The cell colours, each at least 4.5:1 on [keyPictureTile].
const List<int> keyPicturePalette = [
  0xFFff8a80, 0xFFffab5e, 0xFFffd54f, 0xFFc5e1a5, 0xFF69db7c, 0xFF4dd0c4, //
  0xFF4fc3f7, 0xFF82a8ff, 0xFFb39dff, 0xFFe59bff, 0xFFff8fc7, 0xFFd0d4dc,
];

/// A BT Labs service, known by its key: shown under [name] with the BT Labs badge.
class BtLabsKey {
  const BtLabsKey(this.keyHex, this.name, this.logo);

  /// Tag 08 of the service's invites, lower-case hex.
  final String keyHex;
  final String name;
  final String logo;
}

const List<BtLabsKey> btLabsKeys = [
  BtLabsKey('342ac7f0d377f6138e71a87eeb14af02279527a5be5ef95a43878babfbd62456', 'BT Labs Faucet', 'btlabs'),
];

/// The BT Labs service with [key], if it is one.
BtLabsKey? btLabsKeyOf(Uint8List key) {
  final hex = _hex(key);
  for (final k in btLabsKeys) {
    if (k.keyHex == hex) return k;
  }
  return null;
}

class KeyPicture {
  const KeyPicture._(this.seed, this.colour, this.cells);

  /// The picture of the 32-byte [key].
  factory KeyPicture.of(Uint8List key) {
    if (key.length != 32) throw ArgumentError.value(key.length, 'key', 'must be 32 bytes');
    final seed = Uint8List.fromList(sha256.convert([...utf8.encode(keyPictureLabel), ...key]).bytes);
    var cells = ((seed[1] << 8) | seed[2]) & 0x7fff;
    // No near-empty picture.
    if (_popcount(cells) < 4) cells = ~cells & 0x7fff;
    return KeyPicture._(seed, seed[0] % keyPicturePalette.length, cells);
  }

  final Uint8List seed;

  /// Index into [keyPicturePalette].
  final int colour;

  /// 15 bits: bit i fills column i ~/ 5, row i % 5, and the mirror column 4 - (i ~/ 5).
  final int cells;

  int get colourValue => keyPicturePalette[colour];

  /// Whether the cell at column [x], row [y] (0-4) is filled.
  bool filled(int x, int y) {
    final column = x > 2 ? 4 - x : x;
    return cells >> (column * 5 + y) & 1 == 1;
  }

  /// Five rows of `#` and `.`, as the vectors have them.
  List<String> get grid => [
    for (var y = 0; y < 5; y++) [for (var x = 0; x < 5; x++) filled(x, y) ? '#' : '.'].join(),
  ];
}

/// The pairing key (tag 08, 32 bytes) of [link], `epiccash://pair/1/<payload>` or
/// `https://<page>/pair#1/<payload>`. The payload is base64url of fields followed by the first
/// 4 bytes of SHA-256(SHA-256(fields)); fields are `tag[1] len[2] value` with tags strictly
/// increasing. Null when the check or parse fails, or there is no such tag.
Uint8List? inviteKeyOf(String link) {
  final rest = link.contains('pair/') ? link.split('pair/').last : link.split('pair#').last;
  if (!rest.startsWith('1/')) return null;
  final payload = rest.substring(2).replaceAll('=', '');
  final Uint8List raw;
  try {
    raw = base64Url.decode(base64Url.normalize(payload));
  } on FormatException {
    return null;
  }
  if (raw.length < 5) return null;
  final body = Uint8List.sublistView(raw, 0, raw.length - 4);
  final check = sha256.convert(sha256.convert(body).bytes).bytes;
  for (var i = 0; i < 4; i++) {
    if (check[i] != raw[raw.length - 4 + i]) return null;
  }
  var i = 0;
  var last = -1;
  Uint8List? key;
  while (i < body.length) {
    if (i + 3 > body.length) return null;
    final tag = body[i];
    final n = body[i + 1] << 8 | body[i + 2];
    i += 3;
    if (tag <= last || i + n > body.length) return null;
    last = tag;
    if (tag == 8) key = n == 32 ? Uint8List.fromList(body.sublist(i, i + n)) : null;
    i += n;
  }
  return key;
}

int _popcount(int v) {
  var n = 0;
  for (; v != 0; v &= v - 1) {
    n++;
  }
  return n;
}

String _hex(List<int> bytes) => [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
