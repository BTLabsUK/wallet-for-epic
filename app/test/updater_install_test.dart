// The install permission trip never costs the download: the permission is asked before any
// download, the downloaded file is kept and checked against the manifest, and on return with
// the permission the update installs from that file.
import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Platform implements UpdatePlatform {
  bool canInstall = false;

  /// What [install] answers next; `started` by default.
  String answer = 'started';

  final List<String> installs = [];
  int permissionRequests = 0;
  final _events = StreamController<({String status, String? message})>.broadcast();

  @override
  Future<InstalledApp> installedApp() async => InstalledApp(
    packageName: 'com.blacktyger.epiccashmobile',
    versionCode: 26100000,
    versionName: '26.10.0',
    abis: const ['arm64-v8a'],
    canInstall: canInstall,
  );

  @override
  Future<String> install(File apk) async {
    installs.add(apk.path);
    return answer;
  }

  @override
  Future<void> requestInstallPermission() async => permissionRequests++;

  @override
  Stream<({String status, String? message})> get installEvents => _events.stream;
}

/// The notifier with an update on offer, as a check would leave it.
class _Updates extends UpdateNotifier {
  void offer(AvailableUpdate update) =>
      state = UpdateState(UpdatePhase.available, update: update);
}

void main() {
  late Directory tmp;
  late HttpServer server;
  late int hits;
  late _Platform platform;
  late ProviderContainer container;
  final bytes = List<int>.generate(70000, (i) => (i * 7 + 3) & 0xff);
  final l = lookupAppLocalizations(const Locale('en'));
  late AvailableUpdate update;

  File cached() => File('${tmp.path}/updates/epic_wallet-26100100.apk');

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('wfe-update-');
    hits = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      hits++;
      request.response
        ..statusCode = HttpStatus.ok
        ..contentLength = bytes.length
        ..add(bytes);
      request.response.close();
    });
    update = AvailableUpdate(
      versionName: '26.10.1',
      notes: '',
      apk: ReleaseApk(
        abi: 'arm64-v8a',
        versionCode: 26100100,
        url: Uri.parse('http://127.0.0.1:${server.port}/app.apk'),
        sha256: sha256.convert(bytes).toString(),
        size: bytes.length,
      ),
    );
    platform = _Platform();
    container = ProviderContainer(
      overrides: [
        updatePlatformProvider.overrideWithValue(platform),
        updateTempDirProvider.overrideWithValue(() async => tmp),
        updateProvider.overrideWith(_Updates.new),
      ],
      retry: (_, _) => null,
    );
    container.listen(updateProvider, (_, _) {});
    (container.read(updateProvider.notifier) as _Updates).offer(update);
  });

  tearDown(() async {
    container.dispose();
    await server.close(force: true);
    await tmp.delete(recursive: true);
  });

  UpdateNotifier notifier() => container.read(updateProvider.notifier);
  UpdateState state() => container.read(updateProvider);

  test('without the permission nothing downloads: the screen opens, the row says so', () async {
    await notifier().install();
    expect(platform.permissionRequests, 1);
    expect(hits, 0, reason: 'no download before the permission');
    expect(platform.installs, isEmpty);
    expect(state().phase, UpdatePhase.needsPermission);
    expect(state().text!(l), 'Allow installs from Epic Cash Mobile, then return.');
    expect(state().update, update);
  });

  test('with the permission: download, then install', () async {
    platform.canInstall = true;
    await notifier().install();
    expect(platform.permissionRequests, 0);
    expect(hits, 1);
    expect(platform.installs, [cached().path]);
    expect(state().phase, UpdatePhase.installing);
  });

  test('on return with the permission the kept download installs, not downloaded again', () async {
    // The file from an earlier try (the permission trip came after the download, as before).
    await cached().create(recursive: true);
    await cached().writeAsBytes(bytes);
    await notifier().install();
    expect(state().phase, UpdatePhase.needsPermission);
    expect(hits, 0);
    // A return without the permission changes nothing.
    await notifier().resumed();
    expect(state().phase, UpdatePhase.needsPermission);
    expect(platform.installs, isEmpty);
    // The user allowed it and came back.
    platform.canInstall = true;
    await notifier().resumed();
    expect(hits, 0, reason: 'the kept file matched the manifest');
    expect(platform.installs, [cached().path]);
    expect(state().phase, UpdatePhase.installing);
    expect(await cached().readAsBytes(), bytes);
  });

  test('a kept file that is missing or does not match is downloaded again', () async {
    await cached().create(recursive: true);
    await cached().writeAsBytes([...bytes.sublist(1), 0]);
    await notifier().install();
    platform.canInstall = true;
    await notifier().resumed();
    expect(hits, 1, reason: 'the kept file was damaged');
    expect(platform.installs, [cached().path]);
    expect(await cached().readAsBytes(), bytes);
    expect(await apkMatches(cached(), update.apk), isTrue);
  });

  test('the permission lost at install time keeps the file for the return', () async {
    platform
      ..canInstall = true
      ..answer = 'needsPermission';
    await notifier().install();
    expect(hits, 1);
    expect(state().phase, UpdatePhase.needsPermission);
    expect(await cached().exists(), isTrue);
    platform.answer = 'started';
    await notifier().resumed();
    expect(hits, 1, reason: 'installed from the kept file');
    expect(platform.installs, hasLength(2));
    expect(state().phase, UpdatePhase.installing);
  });

  test('a return while nothing waits for the permission does nothing', () async {
    platform.canInstall = true;
    await notifier().resumed();
    expect(hits, 0);
    expect(platform.installs, isEmpty);
    expect(state().phase, UpdatePhase.available);
  });
}
