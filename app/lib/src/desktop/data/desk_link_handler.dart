// SPDX-License-Identifier: Apache-2.0
/// Linux: the entry that lets a browser hand `epic:` and `epiccash:` links to the AppImage. The
/// desktop file inside an AppImage counts only once something installs it, so the app writes one
/// of its own at each start, for the path it runs from: an update keeps the path, and a moved
/// AppImage is written again at its next start. Never set as the default: where the user or
/// another app chose a handler, that choice stays. A failure costs the links only.
library;

import 'dart:async';
import 'dart:io';

import '../../app_info.dart';
import '../../app_log.dart';

/// The entry's file name, apart from the name an integrator gives the AppImage's own.
const String linkEntryName = 'uk.btlabs.btwallet.links.desktop';

/// The entry for [appImage].
String linkEntry(String appImage) => '''
[Desktop Entry]
Type=Application
Name=$appName
Exec=${_execQuoted(appImage)} %u
NoDisplay=true
Terminal=false
MimeType=x-scheme-handler/epic;x-scheme-handler/epiccash;
''';

/// [path] as one Exec argument: bare when it can be, since xdg-open's fallback on desktops it does
/// not know takes the first word as it stands. Else its quoting first, then the escape every value
/// gets, then `%`, which would read as a field code.
String _execQuoted(String path) {
  if (RegExp(r'^[\w./+,:@=-]+$').hasMatch(path)) return path;
  final quoted = path.replaceAllMapped(RegExp(r'["`$\\]'), (m) => '\\${m[0]}');
  return '"${quoted.replaceAll(r'\', r'\\').replaceAll('%', '%%')}"';
}

/// The folder the user's entries live in, or null when [environment] names none.
String? linkEntryFolder(Map<String, String> environment) {
  final data = environment['XDG_DATA_HOME'];
  if (data != null && data.startsWith('/')) return '$data/applications';
  final home = environment['HOME'];
  return home == null || home.isEmpty ? null : '$home/.local/share/applications';
}

/// Writes the entry when this app runs from an AppImage and the entry is not there yet.
Future<void> registerAppImageLinks({Map<String, String>? environment}) async {
  final env = environment ?? Platform.environment;
  final folder = linkEntryFolder(env);
  final path = env['APPIMAGE'];
  if (folder == null || path == null || path.isEmpty || path.contains('\n')) return;
  try {
    final entry = linkEntry(File(path).resolveSymbolicLinksSync());
    final file = File('$folder/$linkEntryName');
    if (file.existsSync() && file.readAsStringSync() == entry) return;
    final next = File('${file.path}.tmp');
    next.parent.createSync(recursive: true);
    next.writeAsStringSync(entry);
    next.renameSync(file.path);
    // Only some desktops read this cache; the others read the entry itself.
    await Process.run('update-desktop-database', [folder]).timeout(const Duration(seconds: 10));
    logInfo('app', 'links entry written');
  } on FileSystemException catch (e) {
    logInfo('app', 'links entry not written: ${e.osError?.message ?? e.message}');
  } on ProcessException {
    logInfo('app', 'links entry written, update-desktop-database not found');
  } on TimeoutException {
    logInfo('app', 'links entry written, update-desktop-database did not answer');
  }
}
