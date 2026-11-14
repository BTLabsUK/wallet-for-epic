// SPDX-License-Identifier: Apache-2.0
// The icon a desktop server tile draws: the server's own, else its operator's, else none.
import 'package:flutter_test/flutter_test.dart';

import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/data/server_look.dart';
import 'package:epic_wallet/src/relay_directory.dart';

ServerIcon icon(String hash) => ServerIcon(hash: hash, urls: {64: Uri.parse('https://status.example/$hash.png')});

void main() {
  final epic = icon('epic');
  final btl = icon('btl');
  final nodes = [
    NodeServer(url: 'https://a.example', label: 'a', operator: 'Epic Cash', listedAs: 'Epic Cash', icon: epic),
    const NodeServer(url: 'https://b.example', label: 'b', operator: 'Epic Cash', listedAs: 'Epic Cash'),
    const NodeServer(url: 'http://192.168.1.24:3413', label: 'Home node', own: true),
  ];
  final boxes = [
    EpicboxServer(domain: 'relay.btl.example', operator: 'BT Labs', listedAs: 'BT Labs', icon: btl),
    const EpicboxServer(domain: 'two.btl.example', port: 8443, operator: 'BT Labs', listedAs: 'bt-labs'),
  ];

  test('a listed node keeps its own icon', () {
    expect(nodeLook(nodes[0], nodes, boxes).icon, same(epic));
  });

  test('a node without an icon takes its operator\'s from another server', () {
    final look = nodeLook(nodes[1], nodes, boxes);
    expect(look.icon, same(epic));
    expect(look.operator, 'Epic Cash');
  });

  test('a user-added or own node has no icon: initials', () {
    final look = nodeLook(nodes[2], nodes, boxes);
    expect(look.icon, isNull);
    expect(look.operator, isNull);
  });

  test('a node the status carries bare is looked up by its url in the list', () {
    final look = nodeLook(const NodeServer(url: 'https://a.example', label: 'a'), nodes, boxes);
    expect(look.icon, same(epic));
  });

  test('operators match across nodes and relays, spaces, dots and case aside', () {
    expect(relayLook(boxes[1], nodes, boxes).icon, same(btl));
  });

  test('a relay written as text is found by host and port', () {
    expect(relayLookOf('relay.btl.example', nodes, boxes).icon, same(btl));
    expect(relayLookOf('two.btl.example:8443', nodes, boxes).icon, same(btl));
    expect(relayLookOf('unknown.example', nodes, boxes).icon, isNull);
  });

  test('no server at all: nothing', () {
    expect(nodeLook(null, nodes, boxes).icon, isNull);
    expect(relayLook(null, const [], const []).icon, isNull);
  });
}
