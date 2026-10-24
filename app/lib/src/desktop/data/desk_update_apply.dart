/// Desktop updates, the part that touches files and processes: the download of the release file
/// the signed manifest names for this system (btlabs-public FORMAT.md §6), checked for size and
/// SHA-256 as the phone checks its APK (`updater.dart`), and putting it in place at "Restart to
/// update":
///  - Windows: the Inno Setup installer, run with `/SILENT /UPDATEFROMAPP=1`; it waits for this
///    app to close (its single-instance mutex), installs, and opens the app again
///    (`windows/installer/epic_wallet.iss`).
///  - Linux: the AppImage this app runs from (`$APPIMAGE`), replaced in its folder by an atomic
///    rename and started again once this process has exited, so the single-instance lock is
///    free by then.
/// Anything else has no applier: the desktop opens the download page instead.
library;

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../app_log.dart';
import '../../btlabs_public.dart' show WalletDesktopFile;
import '../../net/tor_net.dart';

/// Why a download stopped.
enum DeskDownloadFail {
  /// The server could not be reached.
  unreachable,

  /// The connection dropped part way; what arrived is kept for the next try.
  interrupted,

  /// The server answered with another HTTP status ([DeskDownloadError.status]).
  status,

  /// The file is not the one the signed manifest names (size or SHA-256).
  damaged,
}

class DeskDownloadError implements Exception {
  const DeskDownloadError(this.kind, {this.status});

  final DeskDownloadFail kind;
  final int? status;

  @override
  String toString() => 'DeskDownloadError(${kind.name}${status == null ? '' : ' $status'})';
}

/// The name the release file goes under: the last part of its URL, a plain file name
/// (FORMAT.md §6).
String deskUpdateFileName(WalletDesktopFile f) => f.url.pathSegments.last;

/// Downloads [f] into [dir] and returns it, checked against the manifest's size and SHA-256.
///
/// A file already there that matches is returned as it is. What arrives goes to
/// `<name>.<sha12>.part` first; after an interruption the next call asks only for the rest (an
/// HTTP Range request; the downloads host answers 206) and a server that ignores the range
/// sends the whole file again. A continued file that does not match is downloaded once more
/// from the start. Anything else in [dir] (an older release) is removed. [from] replaces the
/// manifest's URL (tests).
Future<File> deskDownloadUpdate(
  HttpClient client,
  WalletDesktopFile f,
  Directory dir, {
  Uri? from,
  void Function(int received)? onProgress,
}) async {
  await dir.create(recursive: true);
  final sep = Platform.pathSeparator;
  final name = deskUpdateFileName(f);
  final target = File('${dir.path}$sep$name');
  final partial = File('${dir.path}$sep$name.${f.sha256.substring(0, 12)}.part');
  await for (final e in dir.list(followLinks: false)) {
    if (e.path != target.path && e.path != partial.path) await e.delete(recursive: true);
  }
  if (await deskFileMatches(target, f)) {
    logInfo('update', 'desktop: the download kept from before is the release, verified');
    return target;
  }
  var kept = await partial.exists() ? await partial.length() : 0;
  if (kept > f.size) {
    await partial.delete();
    kept = 0;
  }
  if (kept == f.size) {
    if (await deskFileMatches(partial, f)) return partial.rename(target.path);
    await partial.delete();
    kept = 0;
  }
  try {
    await _fetchInto(client, from ?? f.url, f, partial, kept, onProgress);
  } on DeskDownloadError catch (e) {
    // Pieced together from two downloads and wrong: once more from the start.
    if (kept == 0 || e.kind != DeskDownloadFail.damaged) rethrow;
    logInfo('update', 'desktop: the continued download does not match; downloading from the start');
    await _fetchInto(client, from ?? f.url, f, partial, 0, onProgress);
  }
  return partial.rename(target.path);
}

Future<void> _fetchInto(
  HttpClient client,
  Uri url,
  WalletDesktopFile f,
  File partial,
  int kept,
  void Function(int received)? onProgress,
) async {
  final digest = _DigestSink();
  final hasher = sha256.startChunkedConversion(digest);
  var received = 0;
  try {
    final request = await client.getUrl(url);
    if (kept > 0) request.headers.set(HttpHeaders.rangeHeader, 'bytes=$kept-');
    final response = await request.close();
    final code = response.statusCode;
    final resumes = kept > 0 && code == HttpStatus.partialContent && _rangeStarts(response, kept, f.size);
    if (code != HttpStatus.ok && !resumes) {
      await response.drain<void>();
      if (code == HttpStatus.requestedRangeNotSatisfiable) await _drop(partial);
      throw DeskDownloadError(DeskDownloadFail.status, status: code);
    }
    if (resumes) {
      logInfo('update', 'desktop: download continues at $kept of ${f.size} bytes');
      await for (final chunk in partial.openRead()) {
        hasher.add(chunk);
      }
      received = kept;
      onProgress?.call(received);
    } else {
      logInfo('update', 'desktop: download starts: ${f.size} bytes');
    }
    final out = partial.openWrite(mode: resumes ? FileMode.append : FileMode.write);
    try {
      // A stalled connection counts as a dropped one.
      await for (final chunk in response.timeout(const Duration(seconds: 60))) {
        received += chunk.length;
        if (received > f.size) break;
        hasher.add(chunk);
        out.add(chunk);
        onProgress?.call(received);
      }
    } finally {
      await out.close();
    }
    hasher.close();
    if (received > f.size) {
      await _drop(partial);
      throw const DeskDownloadError(DeskDownloadFail.damaged);
    }
    if (received != f.size) throw HttpException('the file ended at $received of ${f.size} bytes'); // l10n-ok: log only
    if (digest.value.toString() != f.sha256) {
      await _drop(partial);
      throw const DeskDownloadError(DeskDownloadFail.damaged);
    }
    logInfo('update', 'desktop: download complete and verified: sha256 ${f.sha256.substring(0, 12)}');
  } on SocketException catch (e) {
    throw _stopped(received, f, e, received > kept ? DeskDownloadFail.interrupted : DeskDownloadFail.unreachable);
  } on HttpException catch (e) {
    throw _stopped(received, f, e, DeskDownloadFail.interrupted);
  } on TlsException catch (e) {
    throw _stopped(received, f, e, DeskDownloadFail.interrupted);
  } on TimeoutException catch (e) {
    throw _stopped(received, f, e, DeskDownloadFail.interrupted);
  }
}

DeskDownloadError _stopped(int received, WalletDesktopFile f, Object error, DeskDownloadFail kind) {
  logInfo('update', 'desktop: download stopped at $received of ${f.size} bytes, kept for the next try: $error');
  return DeskDownloadError(kind);
}

Future<void> _drop(File file) async {
  if (await file.exists()) await file.delete();
}

/// Whether a 206 answer starts at [kept] of the [size]-byte file.
bool _rangeStarts(HttpClientResponse response, int kept, int size) {
  final range = response.headers.value(HttpHeaders.contentRangeHeader);
  final match = RegExp(r'^bytes (\d+)-(\d+)/(\d+)$').firstMatch(range ?? '');
  return match != null && int.parse(match[1]!) == kept && int.parse(match[3]!) == size;
}

/// Whether [file] is [f]: present, the announced size, the announced SHA-256.
Future<bool> deskFileMatches(File file, WalletDesktopFile f) async {
  if (!await file.exists() || await file.length() != f.size) return false;
  final digest = _DigestSink();
  final hasher = sha256.startChunkedConversion(digest);
  await for (final chunk in file.openRead()) {
    hasher.add(chunk);
  }
  hasher.close();
  return digest.value.toString() == f.sha256;
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}

/// Starts [exe] on its own, outliving this process.
typedef DeskStart = Future<void> Function(String exe, List<String> args, {String? workingDirectory, Map<String, String>? environment});

Future<void> _startDetached(String exe, List<String> args, {String? workingDirectory, Map<String, String>? environment}) async {
  await Process.start(
    exe,
    args,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: environment == null,
    mode: ProcessStartMode.detached,
  );
}

/// Puts a downloaded release in place.
abstract interface class DeskUpdateApplier {
  /// What this system's release file name ends with.
  String get suffix;

  /// Whether this copy of the app can put a release in place by itself.
  Future<bool> canApply();

  /// Puts [file] in place and starts what opens the new version once this process has exited.
  /// The app quits right after. Throws when nothing was started; then nothing was changed
  /// either, except on Linux after the swap (the new AppImage is in place, the old one gone).
  Future<void> apply(File file);
}

/// Windows: the Inno Setup installer installs over this app and opens it again.
class WindowsSetupApplier implements DeskUpdateApplier {
  const WindowsSetupApplier({this.start = _startDetached});

  final DeskStart start;

  /// Setup's arguments: the progress page only, no restart of Windows, and the app's own run
  /// (`FromApp` in epic_wallet.iss: wait for the app to close, open it again after).
  static const args = ['/SILENT', '/NORESTART', '/UPDATEFROMAPP=1'];

  @override
  String get suffix => '.exe';

  @override
  Future<bool> canApply() async => true;

  @override
  Future<void> apply(File file) async {
    logInfo('update', 'desktop: starting the installer');
    await start(file.path, args, workingDirectory: file.parent.path);
  }
}

/// Linux: the AppImage at `$APPIMAGE` is replaced and started again. Not an AppImage, or a
/// folder this user may not write: no applier (the download page instead).
class AppImageApplier implements DeskUpdateApplier {
  AppImageApplier({required this.environment, required this.pid, this.start = _startDetached});

  final Map<String, String> environment;

  /// This process: the new copy starts once it is gone.
  final int pid;
  final DeskStart start;

  /// What the AppImage runtime sets for the copy it starts; the new copy gets its own.
  static const runtimeVars = {'APPIMAGE', 'APPDIR', 'ARGV0', 'OWD', 'APPIMAGE_UUID'};

  /// Waits up to 60 s for the old process to exit (its single-instance lock goes with it), then
  /// becomes the new AppImage. `$1` is the pid, `$2` the AppImage.
  static const relaunch =
      r'i=0; while kill -0 "$1" 2>/dev/null && [ "$i" -lt 300 ]; do sleep 0.2; i=$((i+1)); done; exec "$2"'; // l10n-ok: a shell script

  /// The AppImage this app runs from, links resolved; null when it is not one.
  String? get _target {
    final path = environment['APPIMAGE'];
    if (path == null || path.isEmpty) return null;
    try {
      return File(path).resolveSymbolicLinksSync();
    } on FileSystemException {
      return null;
    }
  }

  @override
  String get suffix => '.AppImage';

  @override
  Future<bool> canApply() async {
    final target = _target;
    if (target == null || !await File(target).exists()) return false;
    // Writable for this user: a file can be made beside it (and the rename needs no more).
    final probe = File('${File(target).parent.path}/.epic-cash-desktop-check-$pid');
    try {
      await probe.writeAsString('');
      await probe.delete();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  @override
  Future<void> apply(File file) async {
    final target = _target;
    if (target == null) throw const FileSystemException('not an AppImage'); // l10n-ok: log only
    final dir = File(target).parent.path;
    // The new file goes beside the old one first, so the rename stays in one folder (atomic);
    // the running copy keeps its open file until it exits.
    final next = File('$dir/.${target.split('/').last}.new-$pid');
    try {
      await file.copy(next.path);
      final mode = await Process.run('chmod', ['755', next.path]);
      if (mode.exitCode != 0) throw FileSystemException('chmod failed: ${mode.stderr}', next.path); // l10n-ok: log only
      await next.rename(target);
    } on Object {
      if (await next.exists()) await next.delete();
      rethrow;
    }
    logInfo('update', 'desktop: the AppImage is replaced; it starts again once this app has closed');
    final env = Map.of(environment)..removeWhere((k, _) => runtimeVars.contains(k));
    await start('/bin/sh', ['-c', relaunch, 'epic-cash-desktop-update', '$pid', target], workingDirectory: dir, environment: env);
  }
}

/// This system's applier; null where the desktop only opens the download page.
final deskUpdateApplierProvider = Provider<DeskUpdateApplier?>((ref) {
  if (kIsWeb) return null;
  if (Platform.isWindows) return const WindowsSetupApplier();
  if (Platform.isLinux) return AppImageApplier(environment: Platform.environment, pid: pid);
  return null;
});

/// Where downloads go: the app's cache folder (never the wallet's data folder).
final deskUpdateDirProvider = Provider<Future<Directory> Function()>(
  (ref) => () async => Directory('${(await getApplicationCacheDirectory()).path}${Platform.pathSeparator}updates'),
);

/// Downloads a release file and returns it verified; tests replace it.
typedef DeskDownloader = Future<File> Function(WalletDesktopFile f, void Function(int received) onProgress);

/// Over Tor while the Tor switch covers the app's requests (`TorNet`, the same way as the
/// manifest itself): the downloads host at BT Labs' onion. No User-Agent.
final deskUpdateDownloaderProvider = Provider<DeskDownloader>(
  (ref) => (f, onProgress) async {
    await TorNet.untilConnected();
    final client = HttpClient()
      ..connectionTimeout = TorNet.mode == TorNetMode.tor ? const Duration(seconds: 90) : const Duration(seconds: 20)
      ..userAgent = null;
    try {
      TorNet.configure(client);
      final dir = await ref.read(deskUpdateDirProvider)();
      return await deskDownloadUpdate(client, f, dir, onProgress: onProgress);
    } finally {
      client.close(force: true);
    }
  },
);
