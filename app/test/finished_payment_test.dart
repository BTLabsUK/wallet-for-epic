// SPDX-License-Identifier: Apache-2.0
// A finished payment read and posted by the app itself (finished_payment.dart): the slate's
// amount, fee and kernel; push_transaction to the node in use with fluff; a transaction the
// node already has counts as posted; Kill switch refuses before anything is sent, Node only
// lets the node through.
import 'dart:convert';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/finished_payment.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/wallet_service.dart' show FakeWalletSession;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final text = FakeWalletSession.fakeFinishedText(7);
  final was = NetGate.nodeInUse;
  tearDown(() {
    NetGate.nodeInUse = was;
    NetGate.set(NetworkMode.standard);
  });

  test('reads the amount, fee and kernel; an unsigned or foreign text is refused', () {
    final f = readFinishedPayment(text);
    expect(f.payment, FinishedPayment(slateId: 'fake-finished-7', amount: BigInt.from(1000000000), fee: BigInt.from(8000000), kernelExcess: '08ab'));
    expect(f.tx['body'], isA<Map<Object?, Object?>>());
    final unsigned = (jsonDecode(text) as Map<String, Object?>)..['tx'] = {
      'body': {
        'kernels': [
          {'excess': '000000', 'excess_sig': '0000'},
        ],
      },
    };
    for (final bad in [jsonEncode(unsigned), '{}', 'not json', '[]']) {
      expect(() => readFinishedPayment(bad), throwsA(isA<WalletError>().having((e) => e.kind, 'kind', WalletErrorKind.invalidSlate)), reason: bad);
    }
  });

  test('posts push_transaction with fluff to the node\'s foreign API, the secret as basic auth', () async {
    Uri? to;
    Map<String, Object?>? sent;
    Map<String, String>? headers;
    final f = await pushFinishedPayment(text, nodeUrl: 'https://node.example:3413/', nodeApiSecret: 's3cret', post: (u, b, h) async {
      to = u;
      sent = jsonDecode(utf8.decode(b)) as Map<String, Object?>;
      headers = h;
      return HttpReply(200, jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': {'Ok': null}}));
    });
    expect(to.toString(), 'https://node.example:3413/v2/foreign');
    expect(sent?['method'], 'push_transaction');
    expect((sent?['params'] as List).last, isTrue);
    expect(headers?['Authorization'], 'Basic ${base64.encode(utf8.encode('epic:s3cret'))}');
    expect(f.slateId, 'fake-finished-7');
    // The node's form of the kernel (as LEPIC posts it), not the slate's V3 one.
    final kernel = (((sent?['params'] as List).first as Map)['body'] as Map)['kernels'][0] as Map;
    expect(kernel['features'], isA<Map>());
    expect(kernel.containsKey('fee'), isFalse);
    expect(kernel.containsKey('lock_height'), isFalse);
  });

  test('the node form of a V3 kernel: Plain with its fee, HeightLocked with a lock height', () {
    Map k(Map kernel) => (nodeWireTx({'offset': '00', 'body': {'inputs': [], 'outputs': [], 'kernels': [kernel]}})['body'] as Map)['kernels'][0] as Map;
    expect(k({'features': 'Plain', 'fee': '800000', 'lock_height': '0', 'excess': 'aa', 'excess_sig': 'bb'}),
        {'features': {'Plain': {'fee': 800000}}, 'excess': 'aa', 'excess_sig': 'bb'});
    expect(k({'features': 'HeightLocked', 'fee': 7, 'lock_height': 9, 'excess': 'aa', 'excess_sig': 'bb'})['features'],
        {'HeightLocked': {'fee': 7, 'lock_height': 9}});
    expect(k({'features': {'Plain': {'fee': 5}}, 'excess': 'aa', 'excess_sig': 'bb'})['features'], {'Plain': {'fee': 5}});
  });

  test('already in the pool or on chain is posted; another refusal and no answer are errors', () async {
    Future<HttpReply> Function(Uri, List<int>, Map<String, String>) answer(int status, Object body) =>
        (_, _, _) async => HttpReply(status, jsonEncode(body));
    await pushFinishedPayment(text, nodeUrl: 'https://n', post: answer(200, {'result': {'Err': {'Internal': 'Duplicate commitment'}}}));
    await expectLater(
      pushFinishedPayment(text, nodeUrl: 'https://n', post: answer(200, {'result': {'Err': {'Internal': 'invalid kernel'}}})),
      throwsA(isA<WalletError>().having((e) => e.kind, 'kind', WalletErrorKind.transportFailed)),
    );
    await expectLater(
      pushFinishedPayment(text, nodeUrl: 'https://n', post: answer(502, {})),
      throwsA(isA<WalletError>().having((e) => e.kind, 'kind', WalletErrorKind.nodeUnreachable)),
    );
    await expectLater(
      pushFinishedPayment(text, nodeUrl: 'https://n', post: (_, _, _) async => throw const NetError('down')),
      throwsA(isA<WalletError>().having((e) => e.kind, 'kind', WalletErrorKind.nodeUnreachable)),
    );
  });

  test('Kill switch refuses before anything is sent; Node only posts to the node in use, no other host', () async {
    var posts = 0;
    Future<HttpReply> ok(Uri u, List<int> b, Map<String, String> h) async {
      posts++;
      return HttpReply(200, jsonEncode({'result': {'Ok': null}}));
    }

    NetGate.set(NetworkMode.killSwitch);
    await expectLater(pushFinishedPayment(text, nodeUrl: 'https://n', post: ok), throwsA(isA<NetBlocked>()));
    expect(posts, 0);
    NetGate.nodeInUse = () => 'https://node.example';
    NetGate.set(NetworkMode.nodeOnly);
    await pushFinishedPayment(text, nodeUrl: 'https://node.example', post: ok);
    expect(posts, 1);
    // Through the app's real HTTP another host is refused by the gate before a connection.
    await expectLater(
      pushFinishedPayment(text, nodeUrl: 'https://other.example.invalid'),
      throwsA(isA<WalletError>().having((e) => e.message, 'message', contains(netModeError))),
    );
  });
}
