// SPDX-License-Identifier: Apache-2.0
// A directory that can be told, for the receipt tests: it records what was posted.
import 'dart:typed_data';

import 'package:epic_wallet/src/directory/receipts.dart';

class FakeReceipts implements DirectoryReceipts {
  FakeReceipts({this.tell = true, this.accept = true, this.label});

  bool tell;
  bool accept;
  String? label;
  final posts = <(String, Uint8List)>[];

  @override
  bool canTell(String dkeyHex) => tell;

  @override
  String? labelFor(String dkeyHex) => label;

  @override
  Future<bool> post(String dkeyHex, Uint8List payload) async {
    posts.add((dkeyHex, payload));
    return accept;
  }
}
