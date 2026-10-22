// Debug only: the node service layer in a plain view, for developers.
//
//   WFE_NODE_BIN=<path to epic> flutter run -d linux -t lib/main_node_debug.dart
//
// It keeps its own node folder (`<app support>/node-debug`) and settings in memory, so it never
// touches the wallet's local node or its settings. Release builds use main_desktop.dart and never
// contain this; in a release-mode run of this file it shows nothing.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'src/builtin_node_provider.dart';
import 'src/desktop/screens/debug/node_debug.dart';
import 'src/providers.dart';
import 'src/secret_store_api.dart';

void main() {
  if (!kDebugMode) {
    runApp(const SizedBox.shrink());
    return;
  }
  runApp(
    ProviderScope(
      overrides: [
        secretStoreProvider.overrideWithValue(MemorySecretStore()),
        builtInNodeLocationProvider.overrideWith((ref) async {
          final support = await getApplicationSupportDirectory();
          final sep = Platform.pathSeparator;
          final binary = Platform.environment['WFE_NODE_BIN'] ??
              '${File(Platform.resolvedExecutable).parent.path}${sep}bin${sep}epic';
          return BuiltInNodeLocation(root: '${support.path}${sep}node-debug', binary: binary);
        }),
      ],
      child: MaterialApp(theme: ThemeData.dark(), home: const NodeDebugView()),
    ),
  );
}
