// SPDX-License-Identifier: Apache-2.0
/// A finished payment (a final slate, S3 or I3, in the legacy JSON `epic-wallet post -i` reads)
/// read and posted by the app itself, so Kill switch payments can be posted from any device
/// that is online: [readFinishedPayment] takes its amount, fee, kernel and transaction from the
/// text, [pushFinishedPayment] hands the transaction to the node in use (foreign API
/// `push_transaction`, fluffed) through the app's own HTTP, which the network mode's gate
/// checks (`NetGate.dial`: Node only lets the node through, Kill switch nothing).
library;

import 'dart:convert';

import 'models.dart';
import 'net/http.dart';
import 'network_gate.dart';

/// [FinishedPayment] with the transaction the node takes.
class FinishedPaymentText {
  const FinishedPaymentText(this.payment, this.tx);

  final FinishedPayment payment;

  /// The slate's `tx` as the node's `push_transaction` takes it ([nodeWireTx]).
  final Map<String, Object?> tx;
}

/// A slate's `tx` (V3: a kernel's `features` a name, `fee` and `lock_height` beside it, numbers
/// as text) as the node's API takes a transaction: the kernel's features `{"Plain":{"fee":n}}`,
/// `{"HeightLocked":{"fee":n,"lock_height":n}}` or `"Coinbase"`, plain numbers (as LEPIC's own
/// `push_transaction` writes it). Inputs, outputs and the offset as they are.
Map<String, Object?> nodeWireTx(Map tx) {
  final body = tx['body'];
  if (body is! Map) throw _notFinished;
  int n(Object? v) => _amount(v ?? 0).toInt();
  Object features(Map k) {
    final f = k['features'];
    if (f is Map) return f; // already the node's form
    return switch (f) {
      'Coinbase' => 'Coinbase',
      'HeightLocked' => {'HeightLocked': {'fee': n(k['fee']), 'lock_height': n(k['lock_height'])}},
      'Plain' when n(k['lock_height']) > 0 => {'HeightLocked': {'fee': n(k['fee']), 'lock_height': n(k['lock_height'])}},
      'Plain' => {'Plain': {'fee': n(k['fee'])}},
      _ => throw _notFinished,
    };
  }

  final kernels = body['kernels'];
  if (kernels is! List) throw _notFinished;
  return {
    'offset': tx['offset'],
    'body': {
      'inputs': body['inputs'] ?? const [],
      'outputs': body['outputs'] ?? const [],
      'kernels': [
        for (final k in kernels)
          if (k is Map) {'features': features(k), 'excess': k['excess'], 'excess_sig': k['excess_sig']} else throw _notFinished,
      ],
    },
  };
}

const _notFinished = WalletError(kind: WalletErrorKind.invalidSlate, message: 'not a finished payment');

BigInt _amount(Object? v) => switch (v) {
  int i => BigInt.from(i),
  String s => BigInt.tryParse(s.trim()) ?? (throw _notFinished),
  _ => throw _notFinished,
};

/// Reads a finished payment from [text]: a slate whose transaction carries a signed kernel.
/// Throws [WalletError] (`invalidSlate`) for anything else, an unsigned slate included.
FinishedPaymentText readFinishedPayment(String text) {
  final Object? j;
  try {
    j = jsonDecode(text.trim());
  } on FormatException {
    throw _notFinished;
  }
  if (j is! Map) throw _notFinished;
  final id = j['id'];
  final tx = j['tx'];
  if (id is! String || tx is! Map) throw _notFinished;
  final body = tx['body'];
  final kernels = body is Map ? body['kernels'] : null;
  if (kernels is! List || kernels.isEmpty) throw _notFinished;
  final kernel = kernels.first;
  final excess = kernel is Map ? kernel['excess'] : null;
  final sig = kernel is Map ? kernel['excess_sig'] : null;
  // An unsigned kernel (S1, S2) has an all-zero excess and signature: not finished yet.
  bool zero(Object? v) => v is! String || v.isEmpty || RegExp(r'^0+$').hasMatch(v);
  if (zero(excess) || zero(sig)) throw _notFinished;
  return FinishedPaymentText(
    FinishedPayment(slateId: id, amount: _amount(j['amount']), fee: _amount(j['fee']), kernelExcess: excess as String),
    nodeWireTx(tx),
  );
}

/// Whether a node's refusal says the transaction is already there: in its pool or on chain.
bool alreadyPosted(String error) {
  final e = error.toLowerCase();
  return e.contains('duplicate') || e.contains('already') || e.contains('dup ');
}

/// Posts the finished payment [text] to the node at [nodeUrl] (`<node>/v2/foreign`,
/// `push_transaction` with fluff). One the node already has (pool or chain) counts as posted.
/// Throws [NetBlocked] in Kill switch, [WalletError] (`invalidSlate`) for a text that is not a
/// finished payment, `nodeUnreachable` when the node does not answer and `transportFailed`
/// when it refuses the transaction. [post] stands in for [httpPost] in tests.
Future<FinishedPayment> pushFinishedPayment(
  String text, {
  required String nodeUrl,
  String? nodeApiSecret,
  Future<HttpReply> Function(Uri url, List<int> body, Map<String, String> headers)? post,
}) async {
  NetGate.checkNode('post finished');
  final f = readFinishedPayment(text);
  final base = Uri.parse(nodeUrl.trim());
  final path = base.path.endsWith('/') ? base.path.substring(0, base.path.length - 1) : base.path;
  final to = base.replace(path: '$path/v2/foreign', query: null, fragment: null);
  final body = utf8.encode(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'push_transaction', 'params': [f.tx, true]}));
  final headers = {
    if (nodeApiSecret != null && nodeApiSecret.isNotEmpty) 'Authorization': 'Basic ${base64.encode(utf8.encode('epic:$nodeApiSecret'))}',
  };
  final HttpReply reply;
  try {
    reply = await (post ?? (u, b, h) => httpPost(u, body: b, contentType: 'application/json', headers: h))(to, body, headers);
  } on NetError catch (e) {
    throw WalletError(kind: WalletErrorKind.nodeUnreachable, message: 'post finished: ${e.message}');
  }
  if (reply.status != 200) {
    throw WalletError(kind: WalletErrorKind.nodeUnreachable, message: 'post finished: node answered ${reply.status}');
  }
  final Object? json;
  try {
    json = jsonDecode(reply.body);
  } on FormatException {
    throw const WalletError(kind: WalletErrorKind.nodeUnreachable, message: 'post finished: no JSON-RPC answer');
  }
  final result = json is Map ? json['result'] : null;
  final error = json is Map ? json['error'] : null;
  final err = result is Map && result.containsKey('Err') ? result['Err'] : error;
  if (err != null) {
    final why = err is String ? err : jsonEncode(err);
    if (alreadyPosted(why)) return f.payment;
    throw WalletError(kind: WalletErrorKind.transportFailed, message: 'post finished: node refused it ($why)');
  }
  return f.payment;
}
