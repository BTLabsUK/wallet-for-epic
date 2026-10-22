/// Where the desktop app finds the bundled tor (the Tor Expert Bundle, `tools/fetch-tor.sh`).
library;

import 'dart:io';

/// The tor binary and the folder of its libraries, as `WalletSession.startTor` takes them.
class TorBundle {
  const TorBundle({required this.binary, this.libDir});

  final String binary;

  /// On the library path for tor (Linux, macOS); null on Windows.
  final String? libDir;
}

/// `bin/tor-bundle/tor` beside the executable on Linux, `bin\tor-bundle\tor.exe` on Windows,
/// `Contents/Resources/bin/tor-bundle/tor` on macOS, as the built-in node's `bin/epic`. Null
/// when this build has no tor there, and on phones.
Future<TorBundle?> findTorBundle() async {
  if (!(Platform.isLinux || Platform.isWindows || Platform.isMacOS)) return null;
  final sep = Platform.pathSeparator;
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  final base = Platform.isMacOS ? '${Directory(exeDir).parent.path}${sep}Resources' : exeDir;
  final dir = '$base${sep}bin${sep}tor-bundle';
  final binary = '$dir$sep${Platform.isWindows ? 'tor.exe' : 'tor'}';
  if (!await File(binary).exists()) return null;
  return TorBundle(binary: binary, libDir: Platform.isWindows ? null : dir);
}
