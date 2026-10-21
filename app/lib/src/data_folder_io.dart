/// `data_folder.dart` off the web.
library;

import 'dart:io';

/// The Linux application ID (`linux/CMakeLists.txt`, APPLICATION_ID).
const String linuxAppId = 'com.blacktyger.epicwallet';

/// On Linux, creates `<XDG data home>/<app ID>` when it is missing. path_provider_linux uses
/// that folder only when it exists; otherwise it falls back to an existing folder named after
/// the executable (`epic_wallet`), which another program may own. Call before anything reads
/// the application support directory (logs, wallets). Other platforms: nothing.
Future<void> settleDataFolder({Map<String, String>? environment}) async {
  if (!Platform.isLinux) return;
  final dir = linuxDataFolder(environment ?? Platform.environment);
  if (dir == null) return;
  try {
    await Directory(dir).create(recursive: true);
  } on FileSystemException {
    // path_provider picks a folder as before.
  }
}

/// `${XDG_DATA_HOME:-$HOME/.local/share}/<app ID>`, as xdg_directories reads it; null
/// without either variable.
String? linuxDataFolder(Map<String, String> environment) {
  final xdg = environment['XDG_DATA_HOME'];
  final home = environment['HOME'];
  final base = xdg != null && xdg.isNotEmpty ? xdg : (home == null || home.isEmpty ? null : '$home/.local/share');
  return base == null ? null : '$base/$linuxAppId';
}
