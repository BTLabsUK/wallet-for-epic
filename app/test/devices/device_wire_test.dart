// The linked devices' envelope: size before parsing, the envelope's fields, newer versions and
// unknown types kept for their order, the body checks per type.
import 'dart:convert';

import 'package:epic_wallet/src/devices/device_link_code.dart';
import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/devices/device_wire.dart';
import 'package:flutter_test/flutter_test.dart';

final _dev = 'a' * 32;
final _id = 'b' * 32;

List<int> _bytes(Map<String, Object?> m) => utf8.encode(jsonEncode(m));

Map<String, Object?> _env({Object? v = 1, Object? type = 'rename', Object? seq = 1, Map<String, Object?>? body}) => {
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

  test('a newer version and an unknown type decode but are not readable', () {
    final newer = decodeNotice(_bytes(_env(v: 2))).notice!;
    expect(newer.readable, isFalse);
    expect(newer.seq, 1);
    final unknown = decodeNotice(_bytes(_env(type: 'labels'))).notice!;
    expect(unknown.readable, isFalse);
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
      noticeBodyValid(NoticeType.hello, {'deviceId': _dev, 'name': 'Phone', 'walletAddress': 'es1', 'servers': ['epicbox.epiccash.com']}),
      isTrue,
    );
    expect(noticeBodyValid(NoticeType.pair2ok, {'server': 's', 'sas': ['a', 'b', 'c']}), isFalse);
  });

  test('a device link text carries the invite and is not a contact link', () {
    const invite = 'epiccash://pair/1/eyJ0IjoidC0xIn0';
    final text = deviceLinkText(invite);
    expect(text, startsWith(deviceLinkPrefix));
    expect(isDeviceLinkText('Link: $text\n'), isTrue);
    expect(deviceInviteIn('  $text  '), invite);
    expect(deviceInviteIn(invite), isNull);
    expect(isDeviceLinkText(invite), isFalse);
  });

  test('ids are 128 random bits in hex', () {
    final a = randomHexId();
    expect(isHexId(a), isTrue);
    expect(randomHexId(), isNot(a));
  });
}
