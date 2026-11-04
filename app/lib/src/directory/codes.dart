// SPDX-License-Identifier: Apache-2.0
/// The directory code and the listing code: four `emoji-v1` indexes, the first four bytes of a
/// SHA-256, shown with the table of `sas_table.dart`.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;

import '../models.dart' show SasWord;
import '../sas_table.dart';

List<int> _indexes(String label, List<int> key) =>
    sha256.convert([...utf8.encode(label), ...key]).bytes.sublist(0, 4);

/// The four indexes of a directory's code: `SHA256("epic-dir/1" ‖ dkey)`, [dkey] 33 bytes.
List<int> directoryCodeIndexes(Uint8List dkey) => _indexes('epic-dir/1', dkey);

/// The four indexes of a listing's code: `SHA256("epic-listing/1 code" ‖ key)`, [key] 33 bytes.
List<int> listingCodeIndexes(Uint8List key) => _indexes('epic-listing/1 code', key);

/// The table entries of [indexes].
List<SasWord> codeWords(List<int> indexes) => [for (final i in indexes) sasTable[i]];

/// The emoji of [indexes], joined.
String codeEmoji(List<int> indexes) => codeWords(indexes).map((w) => w.emoji).join();
