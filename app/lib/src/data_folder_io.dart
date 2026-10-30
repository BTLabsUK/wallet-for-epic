// SPDX-License-Identifier: Apache-2.0
/// `data_folder.dart` off the web.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'log.dart' show logInfo;
import 'net/lan_node_relay.dart' show lanNodesFile;
import 'owner_only_windows.dart';

/// The folder Epic Cash Desktop keeps in the user's home folder on every desktop system, as
/// the old GUI wallet keeps `.epic-gui`.
const String desktopDataFolderName = '.epic_cash_desktop';

/// Where the app keeps its data (wallets, logs, built-in node, settings): the one place every
/// caller asks. On the desktop `<home>/.epic_cash_desktop` (Linux and macOS `$HOME`, Windows
/// `%USERPROFILE%`), whatever the app ID or the vendor names in the binary say; on the phone
/// the app's own private folder.
Future<Directory> appDataDirectory({Map<String, String>? environment}) async {
  if (dataFolderOverride case final dir?) return Directory(dir);
  if (_isDesktop) {
    final dir = desktopDataFolder(environment ?? Platform.environment, windows: Platform.isWindows);
    if (dir != null) return Directory(dir);
  }
  return getApplicationSupportDirectory();
}

/// Set by integration tests that run the real app (the Windows fixes check's isolation helper)
/// before anything asks for a folder: the data and cache folders then live under it.
String? dataFolderOverride;

/// Files the app may lose (update downloads, their marks): `cache` in the data folder on the
/// desktop, so nothing lands in a folder named after the vendor or the app ID; on the phone the
/// app's own cache folder.
Future<Directory> appCacheDirectory({Map<String, String>? environment}) async {
  if (dataFolderOverride case final dir?) return Directory('$dir${Platform.pathSeparator}cache');
  if (_isDesktop) {
    final dir = desktopDataFolder(environment ?? Platform.environment, windows: Platform.isWindows);
    if (dir != null) return Directory('$dir${Platform.pathSeparator}cache');
  }
  return getApplicationCacheDirectory();
}

/// Creates the desktop data folder at start, so it exists before anything reads it, and keeps
/// it to its owner ([ownerOnly]). The phone: nothing, its folder is the app's own.
Future<void> settleDataFolder({Map<String, String>? environment}) async {
  lanNodesFile = () async => File('${(await appDataDirectory()).path}${Platform.pathSeparator}lan_nodes.json');
  if (!_isDesktop && dataFolderOverride == null) return;
  try {
    final dir = await appDataDirectory(environment: environment);
    await dir.create(recursive: true);
    await ownerOnly(dir.path);
  } on FileSystemException {
    // The first write reports it.
  }
}

/// On Linux and macOS, sets [path] to 0700, so the wallets, logs, remembered passwords, contacts
/// and cache below it are out of other accounts' reach whatever mode the umask gave each file.
/// Run on every start, so a folder an older version created with the umask's mode is closed
/// too. Windows: an access list of the user and `SYSTEM` only, in place of the profile's, which
/// also lets `Administrators` in (`owner_only_windows.dart`).
Future<void> ownerOnly(String path) async {
  if (Platform.isWindows) {
    final env = Platform.environment;
    final result = await restrictFolderToOwner(path, profile: env['USERPROFILE'], systemRoot: env['SystemRoot'] ?? r'C:\Windows');
    if (result == OwnerOnlyResult.restricted || result == OwnerOnlyResult.partial) logInfo('data', 'data folder access list: ${result.name}');
    return;
  }
  if (!(Platform.isLinux || Platform.isMacOS)) return;
  try {
    await Process.run('chmod', ['700', path]);
  } on ProcessException {
    // No chmod on the PATH: the folder keeps the mode it has.
  }
}

bool get _isDesktop => Platform.isLinux || Platform.isWindows || Platform.isMacOS;

/// `<home>/.epic_cash_desktop`: `%USERPROFILE%` on Windows, `$HOME` elsewhere; null without one.
String? desktopDataFolder(Map<String, String> environment, {required bool windows}) {
  final home = windows ? environment['USERPROFILE'] : environment['HOME'];
  if (home == null || home.isEmpty) return null;
  final sep = windows ? r'\' : '/';
  final base = home.endsWith(sep) ? home.substring(0, home.length - 1) : home;
  return '$base$sep$desktopDataFolderName';
}
