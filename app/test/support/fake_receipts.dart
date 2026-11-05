// SPDX-License-Identifier: Apache-2.0
// A name service that can be told, for the receipt tests: it records what was posted.
import 'dart:typed_data';

import 'package:epic_wallet/src/name_service/receipts.dart';

class FakeReceipts implements NameServiceReceipts {
  FakeReceipts({this.tell = true, this.accept = true, this.label});

  bool tell;
  bool accept;
  String? label;
  final posts = <(String, Uint8List)>[];

  @override
  bool canTell(String serviceKeyHex) => tell;

  @override
  String? labelFor(String serviceKeyHex) => label;

  @override
  Future<bool> post(String serviceKeyHex, Uint8List payload) async {
    posts.add((serviceKeyHex, payload));
    return accept;
  }
}
