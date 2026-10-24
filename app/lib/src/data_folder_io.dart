/// `data_folder.dart` off the web.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// The folder Epic Cash Desktop keeps on Linux, under the home folder.
const String linuxDataFolderName = '.epic_cash_desktop';

/// Where the app keeps its data (wallets, logs, built-in node, settings): the one place every
/// caller asks. On Linux `$HOME/.epic_cash_desktop`, whatever the app ID; elsewhere the platform's
/// application support directory.
Future<Directory> appDataDirectory({Map<String, String>? environment}) async {
  if (Platform.isLinux) {
    final dir = linuxDataFolder(environment ?? Platform.environment);
    if (dir != null) return Directory(dir);
  }
  return getApplicationSupportDirectory();
}

/// Creates the Linux data folder at start, so it exists before anything reads it. Other
/// platforms: nothing.
Future<void> settleDataFolder({Map<String, String>? environment}) async {
  if (!Platform.isLinux) return;
  try {
    await (await appDataDirectory(environment: environment)).create(recursive: true);
  } on FileSystemException {
    // The first write reports it.
  }
}

/// `$HOME/.epic_cash_desktop`; null without HOME.
String? linuxDataFolder(Map<String, String> environment) {
  final home = environment['HOME'];
  return home == null || home.isEmpty ? null : '$home/$linuxDataFolderName';
}
