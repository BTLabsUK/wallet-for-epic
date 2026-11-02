// SPDX-License-Identifier: Apache-2.0
// Every outbound connection of the app's own code goes through the network mode's gate
// (`NetGate.dial`, network_gate.dart; docs/network-modes.md). This scan fails when a raw network
// API turns up in a file that is not on the list of gated files below, so a new connection
// cannot slip past Node only or Kill switch unseen.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Raw APIs that open a connection, look a name up or hand an address to the browser.
final _raw = <String, RegExp>{
  'HttpClient': RegExp(r'\bHttpClient\s*\('),
  'Socket.connect': RegExp(r'\b(Raw|Secure)?Socket\.(connect|startConnect)\b'),
  'WebSocket.connect': RegExp(r'\bWebSocket\.connect\b'),
  'DNS lookup': RegExp(r'\bInternetAddress\.lookup\b'),
  'UDP socket': RegExp(r'\bRawDatagramSocket\.bind\b'),
  'browser fetch': RegExp(r"@JS\('(fetch|XMLHttpRequest|WebSocket)'\)|window\.fetch\b"),
  'browser opener': RegExp(r"'xdg-open'|url\.dll|'rundll32'"),
  'network package': RegExp(r"package:(http|dio|web_socket_channel|url_launcher)/"),
};

/// The gated files: each asks `NetGate` (or its `dialOrFail` / `allows`) before it connects.
const _gated = {
  'lib/src/net/http_io.dart': 'every request: dialOrFail(NetDial.http) before the client opens',
  'lib/src/net/http_web.dart': 'every fetch: NetGate.dial(NetDial.http) first',
  'lib/src/net/ws_probe_io.dart': 'NetGate.allows(NetDial.webSocket), else ProbeNotRun',
  'lib/src/net/ws_probe_web.dart': 'NetGate.allows(NetDial.webSocket), else ProbeNotRun',
  'lib/src/net/socks.dart': 'NetGate.allows(NetDial.tor) for the SOCKS hop, NetDial.http for the host asked',
  'lib/src/net/lan_node_relay.dart': 'NetDial.lookup before a name lookup, NetDial.nodeRelay per forwarded request',
  'lib/src/node/node_api.dart': "NetGate.allows(NetDial.http) on the node's own host",
  'lib/src/builtin_node.dart': 'NetDial.builtInNode before start and the port probe, NetDial.http for its API',
  'lib/src/updater.dart': 'dialOrFail(NetDial.http) before the download',
  'lib/src/desktop/data/desk_update_apply.dart': 'dialOrFail(NetDial.http) before the download',
  'lib/src/desktop/data/files.dart': 'NetGate.allows(NetDial.browser) before the browser opens',
};

void main() {
  final files = Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  String rel(File f) => f.path.replaceAll(r'\', '/');

  test('no raw network API outside the gated files', () {
    final found = <String>[];
    for (final f in files) {
      final path = rel(f);
      if (_gated.containsKey(path)) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        for (final e in _raw.entries) {
          if (e.value.hasMatch(line)) found.add('$path:${i + 1}: ${e.key}');
        }
      }
    }
    expect(found, isEmpty, reason: 'gate these through NetGate.dial (network_gate.dart) and list the file here');
  });

  test('every gated file asks the gate', () {
    for (final path in _gated.keys) {
      final text = File(path).readAsStringSync();
      expect(RegExp(r'NetGate\.(dial|allows)|dialOrFail\(').hasMatch(text), isTrue, reason: path);
    }
  });

  test('the lists name files that exist', () {
    for (final path in _gated.keys) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
