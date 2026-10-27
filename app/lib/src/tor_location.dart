/// Where the desktop app finds the bundled tor (the Tor Expert Bundle, `tools/fetch-tor.sh`).
library;

import 'dart:io';

import 'package:flutter/services.dart';

import 'tor_build.dart';

const _channel = MethodChannel('epic_wallet/tor');

/// The tor binary and the folder of its libraries, as `WalletSession.startTor` takes them.
class TorBundle {
  const TorBundle({required this.binary, this.libDir});

  final String binary;

  /// On the library path for tor (Linux, macOS); null on Windows.
  final String? libDir;
}

/// `bin/tor-bundle/tor` beside the executable on Linux, `bin\tor-bundle\tor.exe` on Windows,
/// `Contents/Resources/bin/tor-bundle/tor` on macOS, as the built-in node's `bin/epic`. Null
/// when this build has no tor there. On Android it is `libtor.so` in the app's native library
/// folder (the Tor Project's tor, extracted at install), asked of `MainActivity`; null on iOS.
/// Always null in the build without Tor ([torBuilt]).
Future<TorBundle?> findTorBundle() async {
  if (!torBuilt) return null;
  if (Platform.isAndroid) {
    try {
      final path = await _channel.invokeMethod<String>('binary');
      return path == null ? null : TorBundle(binary: path);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
  if (!(Platform.isLinux || Platform.isWindows || Platform.isMacOS)) return null;
  final sep = Platform.pathSeparator;
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  final base = Platform.isMacOS ? '${Directory(exeDir).parent.path}${sep}Resources' : exeDir;
  final dir = '$base${sep}bin${sep}tor-bundle';
  final binary = '$dir$sep${Platform.isWindows ? 'tor.exe' : 'tor'}';
  if (!await File(binary).exists()) return null;
  return TorBundle(binary: binary, libDir: Platform.isWindows ? null : dir);
}
