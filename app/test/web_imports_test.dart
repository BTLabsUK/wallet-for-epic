// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The libraries of this package that the web build compiles: everything reachable from
/// `lib/main.dart`, taking the `if (dart.library.js_interop)` side of every conditional import
/// and export.
Map<String, Set<String>> _webGraph() {
  final directive = RegExp(
    r'''^\s*(?:import|export)\s+'([^']+)'((?:\s+if\s*\([^)]*\)\s*'[^']+')*)''',
    multiLine: true,
  );
  final webBranch = RegExp(
    r"""if\s*\(\s*dart\.library\.js_interop\s*\)\s*'([^']+)'""",
  );
  final graph = <String, Set<String>>{};
  final todo = ['lib/main.dart'];
  while (todo.isNotEmpty) {
    final path = todo.removeLast();
    if (graph.containsKey(path)) continue;
    final uris = graph[path] = <String>{};
    final source = File(path).readAsStringSync();
    for (final m in directive.allMatches(source)) {
      final uri = webBranch.firstMatch(m.group(2)!)?.group(1) ?? m.group(1)!;
      uris.add(uri);
      String? local;
      if (uri.startsWith('package:epic_wallet/')) {
        local = 'lib/${uri.substring('package:epic_wallet/'.length)}';
      } else if (!uri.contains(':')) {
        local = File(path).parent.uri.resolve(uri).path;
      }
      if (local != null) todo.add(local);
    }
  }
  return graph;
}

void main() {
  test('the web build reaches no dart:ffi, LEPIC, or path_provider outside the updater', () {
    final graph = _webGraph();
    expect(graph.keys, contains('lib/src/wallet_backend_web.dart'));
    expect(graph.keys, isNot(contains('lib/src/lepic_wallet_service.dart')));
    final banned = [
      for (final MapEntry(key: file, value: uris) in graph.entries)
        for (final uri in uris)
          if (uri == 'dart:ffi' ||
              uri.startsWith('package:lepic/') ||
              // The updater runs on Android only; the web build's claim.
              (uri.startsWith('package:path_provider/') &&
                  file != 'lib/src/updater.dart'))
            '$file: $uri',
    ];
    expect(banned, isEmpty);
  });

  test('dart:io on the web only where it is never called there', () {
    // These compile on the web and are never called there: the legacy file cleanup is
    // replaced by wallet_backend_web.dart, the history file store runs only inside
    // LepicWalletService, and the updater and the feedback screen are hidden in demo mode.
    // the web build's claim, asks whether to split them.
    const allowed = {
      'lib/src/vault.dart',
      'lib/src/history/meta_store.dart',
      // The shared address book's file, opened only by LepicWalletService like the store above.
      'lib/src/contact_store.dart',
      'lib/src/updater.dart',
      'lib/src/ui/feedback_screen.dart',
      // gzip for the sealed report, sent only from the feedback screen above.
      'lib/src/support_report.dart',
      // The bundled tor's path; the phone's Tor controller asks for it off the web only.
      'lib/src/tor_location.dart',
      // How the dart:io clients go with the Tor switch; on the web only the updater above
      // reaches them, and it never runs there (http.dart takes http_web.dart).
      'lib/src/net/tor_net.dart',
      'lib/src/net/socks.dart',
      // Platform.isAndroid behind !kIsWeb: the web keeps the bundled Thai fallback.
      'lib/src/ui/theme/fonts.dart',
      // The phone's LAN listener reads its interfaces behind kIsWeb; the web has no listener.
      'lib/src/phone_http.dart',
    };
    final withIo = {
      for (final MapEntry(key: file, value: uris) in _webGraph().entries)
        if (uris.contains('dart:io')) file,
    };
    expect(withIo.difference(allowed), isEmpty);
  });
}
