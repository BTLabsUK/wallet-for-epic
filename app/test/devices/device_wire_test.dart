// SPDX-License-Identifier: Apache-2.0
// The linked devices' envelope: size before parsing, the envelope's fields, newer versions and
// unknown types kept for their order, the body checks per type.
import 'dart:convert';

import 'package:epic_wallet/src/devices/device_link_code.dart';
import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/devices/device_wire.dart';
import 'package:epic_wallet/src/wallet_service.dart' show fakeAddressSignature;
import 'package:flutter_test/flutter_test.dart';

final _dev = 'a' * 32;
final _id = 'b' * 32;

List<int> _bytes(Map<String, Object?> m) => utf8.encode(jsonEncode(m));

Map<String, Object?> _env({Object? v = deviceWireVersion, Object? type = 'rename', Object? seq = 1, Map<String, Object?>? body}) => {
  'v': v,
  'type': type,
  'id': _id,
  'seq': seq,
  'dev': _dev,
  'ts': 1,
  'body': body ?? {'name': 'Desktop'},
};

void main() {
  test('a notice round-trips', () {
    final n = Notice(type: NoticeType.rename, id: _id, seq: 3, dev: _dev, ts: 9, body: const {'name': 'Desk'});
    final back = decodeNotice(n.encode()).notice!;
    expect(back.type, NoticeType.rename);
    expect(back.seq, 3);
    expect(back.dev, _dev);
    expect(back.readable, isTrue);
    expect(back.body['name'], 'Desk');
  });

  test('an oversize payload is dropped before parsing', () {
    final big = List<int>.filled(deviceNoticeMaxBytes + 1, 0x20);
    expect(decodeNotice(big).drop, NoticeDrop.tooLarge);
  });

  test('a payload that is not an envelope is dropped', () {
    expect(decodeNotice(utf8.encode('not json')).drop, NoticeDrop.malformed);
    expect(decodeNotice(_bytes(_env(seq: 0))).drop, NoticeDrop.malformed);
    expect(decodeNotice(_bytes(_env()..['dev'] = 'short')).drop, NoticeDrop.malformed);
    expect(decodeNotice(_bytes(_env()..remove('id'))).drop, NoticeDrop.malformed);
    expect(decodeNotice(_bytes(_env()..['body'] = [])).drop, NoticeDrop.malformed);
  });

  test('another version and an unknown type decode but are not readable', () {
    expect(deviceWireVersion, 2);
    for (final v in [1, 3]) {
      final other = decodeNotice(_bytes(_env(v: v))).notice!;
      expect(other.readable, isFalse);
      expect(other.otherVersion, isTrue, reason: 'version $v names the device to update');
      expect(other.seq, 1);
    }
    final unknown = decodeNotice(_bytes(_env(type: 'labels'))).notice!;
    expect(unknown.readable, isFalse);
    expect(unknown.otherVersion, isFalse);
    expect(unknown.type, isNull);
    expect(unknown.typeName, 'labels');
  });

  test('bodies are checked per type', () {
    final commit = '08${'0' * 64}';
    expect(noticeBodyValid(NoticeType.send, {'slateId': 's', 'inputs': [commit], 'amount': '100'}), isTrue);
    expect(noticeBodyValid(NoticeType.send, {'slateId': 's', 'inputs': ['xyz'], 'amount': '100'}), isFalse);
    expect(noticeBodyValid(NoticeType.send, {'slateId': 's', 'inputs': [commit], 'amount': -1}), isFalse);
    expect(noticeBodyValid(NoticeType.send, {'slateId': 's', 'inputs': <String>[], 'amount': '1'}), isFalse);
    expect(noticeBodyValid(NoticeType.status, {'slateId': 's', 'state': 'cancelled'}), isTrue);
    expect(noticeBodyValid(NoticeType.status, {'slateId': 's', 'state': 'spend-it'}), isFalse);
    expect(noticeBodyValid(NoticeType.rename, {'name': 'x' * 49}), isFalse);
    expect(noticeBodyValid(NoticeType.servers, {'set': ['a', 'b', 'c'], 'version': 2}), isFalse);
    expect(
      noticeBodyValid(NoticeType.hello, {'deviceId': _dev, 'name': 'Phone', 'walletAddress': 'es1', 'servers': ['epicbox.epiccash.com'], 'proof': 'ab' * 36, 'kind': 'phone'}),
      isTrue,
    );
    expect(noticeBodyValid(NoticeType.pair2ok, {'server': 's', 'sas': ['a', 'b', 'c']}), isFalse);
    expect(noticeBodyValid(NoticeType.full, {'linked': 'Desktop'}), isTrue);
    expect(noticeBodyValid(NoticeType.full, {'linked': 'x' * 49}), isFalse);
    expect(noticeBodyValid(NoticeType.fwd, {'kind': 'posted', 'slateId': 's', 'kernel': '09${'0' * 64}'}), isTrue);
    expect(noticeBodyValid(NoticeType.fwd, {'kind': 'cancelled', 'slateId': 's'}), isTrue);
    expect(noticeBodyValid(NoticeType.fwd, {'kind': 'invoice', 'slateId': 's'}), isTrue);
    expect(noticeBodyValid(NoticeType.fwd, {'kind': 'pay-it', 'slateId': 's'}), isFalse);
    expect(noticeBodyValid(NoticeType.fwd, {'kind': 'posted'}), isFalse);
  });

  test("a hello's proof is an address signature in hex, and never absent", () {
    Map<String, Object?> hello(Object? proof) => {
      'deviceId': _dev,
      'name': 'Phone',
      'walletAddress': 'es1',
      'servers': ['epicbox.epiccash.com'],
      'proof': proof,
    };
    expect(noticeBodyValid(NoticeType.hello, hello('3044${'ab' * 68}')), isTrue);
    expect(noticeBodyValid(NoticeType.hello, hello(null)), isFalse);
    expect(noticeBodyValid(NoticeType.hello, hello('')), isFalse);
    expect(noticeBodyValid(NoticeType.hello, hello('3044ZZ${'ab' * 8}')), isFalse);
    expect(noticeBodyValid(NoticeType.hello, hello('ab' * 73)), isFalse);
    expect(noticeBodyValid(NoticeType.hello, hello(42)), isFalse);
  });

  test('a device link text carries the invite and is not a contact link', () {
    const invite = 'epiccash://pair/1/eyJ0IjoidC0xIn0';
    final fp = deviceLinkFingerprint('3045022100aa');
    final text = deviceLinkText(invite, fingerprint: fp);
    expect(text, startsWith(deviceLinkPrefix));
    expect(isDeviceLinkText('Link: $text\n'), isTrue);
    expect(deviceInviteIn('  $text  '), invite);
    expect(deviceLinkIn('  $text  '), (invite: invite, fingerprint: fp));
    expect(deviceInviteIn(invite), isNull);
    expect(isDeviceLinkText(invite), isFalse);
  });

  test('a device link of an app from before fingerprints still reads, without one', () {
    const invite = 'epiccash://pair/1/eyJ0IjoidC0xIn0';
    final old = deviceLinkText(invite, fingerprint: deviceLinkFingerprint('3045')).replaceFirst(RegExp(r'/[0-9a-f]{16}$'), '');
    expect(deviceLinkIn(old), (invite: invite, fingerprint: null));
  });

  test("the link fingerprint hashes the wallet's signature of the invite, never its key", () {
    const key = 'esWnT8kBf3yXqPZ2r9cLhVd7JmK4uA6gYsN1pQeRtC5vD8xHwF2b';
    const invite = 'epiccash://pair/1/eyJ0IjoidC0xIn0';
    final signature = fakeAddressSignature(key, deviceLinkFingerprintMessage(invite));
    final fp = deviceLinkFingerprint(signature);
    expect(fp, matches(RegExp(r'^[0-9a-f]{16}$')));
    expect(fp, deviceLinkFingerprint(fakeAddressSignature(key, deviceLinkFingerprintMessage(invite))));
    // Another wallet, or the same wallet's code for another invite, gives another one.
    expect(deviceLinkFingerprint(fakeAddressSignature('${key}x', deviceLinkFingerprintMessage(invite))), isNot(fp));
    expect(deviceLinkFingerprint(fakeAddressSignature(key, deviceLinkFingerprintMessage('${invite}x'))), isNot(fp));
    // The address alone does not give it.
    expect(deviceLinkFingerprint(key), isNot(fp));
    final text = deviceLinkText('epiccash://pair/1/eyJ0IjoidC0xIn0', fingerprint: fp);
    expect(text.contains(key), isFalse);
    expect(utf8.decode(base64Url.decode(base64Url.normalize(text.split('/')[4]))).contains(key), isFalse);
  });

  test('ids are 128 random bits in hex', () {
    final a = randomHexId();
    expect(isHexId(a), isTrue);
    expect(randomHexId(), isNot(a));
  });
}
