// SPDX-License-Identifier: Apache-2.0
/// Payment links for the Send tests: the real link texts of the name service vectors, a verifier
/// that answers from the signatures the vector file lists, and a membership to set.
library;

import 'dart:typed_data';

import 'package:epic_wallet/src/name_service/name_service.dart';
import 'package:epic_wallet/src/wallet_service.dart';

import '../name_service_vectors_support.dart';

/// Now for the vector requests: the unix second the vectors were made for.
final DateTime linkNow = DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000);

/// Past the expiry of the vector requests (`expires` + 121 s).
final DateTime linkAfterExpiry = DateTime.fromMillisecondsSinceEpoch(1800086521 * 1000);

class LinkVectors {
  LinkVectors() : v = loadVectors() {
    listed = listedValidCalls(v);
  }

  final Map<String, Object?> v;
  late final Set<String> listed;

  Map<String, Object?> _good(String id) => vectorList(v, 'payreqs').firstWhere((e) => e['id'] == id);

  /// The `epiccash://pay/1/…` text of a good request.
  String scheme(String id) => (_good(id)['text']! as Map<String, Object?>)['scheme']! as String;

  /// The `https://<host>/p#1/…` text of a good request, with a host of the test's choice.
  String https(String id, {String host = 'pay.other.invalid'}) =>
      ((_good(id)['text']! as Map<String, Object?>)['https']! as String).replaceFirst('links.example', host);

  /// The text of a bad vector.
  String bad(String id) => vectorList(v, 'bad').firstWhere((e) => e['id'] == id)['input_text']! as String;

  Payreq request(String id) => Payreq.fromText(scheme(id));

  /// The Epicbox key text of a listing key of the vectors, on mainnet.
  String listingKeyText(String hex) => epicboxKeyText(fromHex(hex), netMainnet);
}

/// The wallet service whose verifier knows the signatures the vector file lists.
class VectorWalletService extends FakeWalletService {
  VectorWalletService(this.listed);

  final Set<String> listed;

  @override
  Future<bool> verifyListingSignature(String publicKeyText, String domain, Uint8List message, Uint8List der) async =>
      listed.contains(callKey(publicKeyText, domain, message, der));
}

class FakeMembership implements NameServiceMembership {
  FakeMembership({this.labels = const {}, this.listingKeys = const {}});

  final Map<String, String> labels;
  final Map<String, String> listingKeys;

  @override
  String? labelFor(String serviceKeyHex) => labels[serviceKeyHex];

  @override
  String? listingKeyFor(String serviceKeyHex) => listingKeys[serviceKeyHex];
}

/// The name service of the vector requests (their `serviceKey`).
const String vectorServiceKey = '027bc02d1c66a7b3a887de49f7770b16e846a6b7de832c309aa9c1dbaa125f4816';
