/// `data_folder.dart` off the web.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

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

/// Set by integration tests that run the real app (integration_test/fixes_01/isolation.dart)
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

/// Creates the desktop data folder at start, so it exists before anything reads it. The phone:
/// nothing.
Future<void> settleDataFolder({Map<String, String>? environment}) async {
  if (!_isDesktop && dataFolderOverride == null) return;
  try {
    await (await appDataDirectory(environment: environment)).create(recursive: true);
  } on FileSystemException {
    // The first write reports it.
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
