// The install permission trip never costs the download: the permission is asked before any
// download, the downloaded file is kept and checked against the manifest, and on return with
// the permission the update installs from that file. Leaving the app mid-download (Android 15+
// cuts a background app's network) keeps what arrived: the return carries on from there.
import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/net/tor_net.dart';
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

  /// The Range header of each request, null when it had none.
  late List<String?> ranges;

  /// Bytes served in all, over every request.
  late int served;

  /// When set, the next answer stops after this many bytes of its body, as Android's network
  /// cut stops it.
  int? cutAfter;

  /// Whether the server answers a Range request with the rest (206) or the whole file (200).
  late bool honoursRange;
  late _Platform platform;
  late ProviderContainer container;
  final bytes = List<int>.generate(70000, (i) => (i * 7 + 3) & 0xff);
  final l = lookupAppLocalizations(const Locale('en'));
  late AvailableUpdate update;

  File cached() => File(
    '${tmp.path}/updates/epic_wallet-26100100-${sha256.convert(bytes).toString().substring(0, 12)}.apk',
  );
  File part() => File('${cached().path}.part');

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('wfe-update-');
    hits = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    ranges = [];
    served = 0;
    cutAfter = null;
    honoursRange = true;
    server.listen((request) async {
      hits++;
      final range = request.headers.value(HttpHeaders.rangeHeader);
      ranges.add(range);
      final from = honoursRange && range != null
          ? int.parse(RegExp(r'^bytes=(\d+)-$').firstMatch(range)![1]!)
          : 0;
      final body = bytes.sublist(from);
      final response = request.response
        ..statusCode = from > 0 ? HttpStatus.partialContent : HttpStatus.ok
        ..contentLength = body.length;
      if (from > 0) {
        response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $from-${bytes.length - 1}/${bytes.length}',
        );
      }
      final cut = cutAfter;
      cutAfter = null;
      if (cut == null) {
        served += body.length;
        response.add(body);
        await response.close();
        return;
      }
      // Part of the body, then the connection drops.
      served += cut;
      final socket = await response.detachSocket();
      socket.add(body.sublist(0, cut));
      await socket.flush();
      socket.destroy();
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
        updateManifestUrlProvider.overrideWithValue(
          Uri.parse('http://127.0.0.1:${server.port}/update.json'),
        ),
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

  group('leaving the app mid-download (Android 15+ cuts its network)', () {
    setUp(() => platform.canInstall = true);

    test('the return carries on from what arrived, never from the start', () async {
      cutAfter = 30000;
      notifier().paused();
      await notifier().install();
      expect(platform.installs, isEmpty);
      expect(state().phase, UpdatePhase.available, reason: 'no failure while away');
      expect(await part().length(), 30000);
      // The return: the download carries on by itself, asking only for the rest.
      final back = notifier().resumed();
      expect(state().phase, UpdatePhase.downloading, reason: 'busy before the check on return');
      await back;
      expect(ranges, [null, 'bytes=30000-']);
      expect(served, bytes.length, reason: 'nothing downloaded twice');
      expect(platform.installs, [cached().path]);
      expect(await cached().readAsBytes(), bytes);
      expect(await part().exists(), isFalse);
      expect(state().phase, UpdatePhase.installing);
    });

    test('the check on return does not take the update over', () async {
      cutAfter = 30000;
      notifier().paused();
      await notifier().install();
      await Future.wait([notifier().resumed(), notifier().checkOnOpening()]);
      expect(ranges.first, isNull);
      expect(ranges, contains('bytes=30000-'));
      expect(platform.installs, [cached().path]);
    });

    test('a stop in front says so; Update carries on from what arrived', () async {
      cutAfter = 50000;
      await notifier().install();
      expect(state().phase, UpdatePhase.failed);
      expect(state().text!(l), 'The download was interrupted.');
      await notifier().resumed();
      expect(hits, 1, reason: 'a return after a failure in front does not download by itself');
      await notifier().install();
      expect(ranges, [null, 'bytes=50000-']);
      expect(served, bytes.length);
      expect(platform.installs, [cached().path]);
    });

    test('a server that ignores the range sends it all again, and it still installs', () async {
      honoursRange = false;
      cutAfter = 30000;
      await notifier().install();
      await notifier().install();
      expect(ranges, [null, 'bytes=30000-']);
      expect(served, 30000 + bytes.length);
      expect(await cached().readAsBytes(), bytes);
      expect(platform.installs, [cached().path]);
    });

    test('a kept part that does not fit the rest is downloaded again from the start, once', () async {
      await part().create(recursive: true);
      await part().writeAsBytes(List.filled(30000, 1));
      await notifier().install();
      expect(ranges, ['bytes=30000-', null]);
      expect(await cached().readAsBytes(), bytes);
      expect(platform.installs, [cached().path]);
    });

    test('a part from another build is not continued', () async {
      final other = File('${tmp.path}/updates/epic_wallet-26100100-000000000000.apk.part');
      await other.create(recursive: true);
      await other.writeAsBytes(bytes.sublist(0, 30000));
      await notifier().install();
      expect(ranges, [null]);
      expect(await other.exists(), isFalse);
      expect(platform.installs, [cached().path]);
    });
  });

  group('with Tor on, an APK on examples.btlabs.uk (android-16)', () {
    late ServerSocket socks;
    final connects = <String>[];

    /// A SOCKS5 proxy that records each CONNECT's name and port, then drops the connection.
    setUp(() async {
      connects.clear();
      socks = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      socks.listen((client) {
        final buf = <int>[];
        var stage = 0;
        client.listen((data) {
          buf.addAll(data);
          if (stage == 0 && buf.length >= 3) {
            buf.clear();
            stage = 1;
            client.add([5, 2]);
          } else if (stage == 1 && buf.length >= 3 && buf.length >= 3 + buf[1] + buf[2 + buf[1]]) {
            buf.clear();
            stage = 2;
            client.add([1, 0]);
          } else if (stage == 2 && buf.length >= 5 && buf.length >= 7 + buf[4]) {
            connects.add('${String.fromCharCodes(buf.sublist(5, 5 + buf[4]))}:${buf[5 + buf[4]] << 8 | buf[6 + buf[4]]}');
            stage = 3;
            client.destroy();
          }
        }, onError: (_) {});
      });
      TorNet.useTor(SocksProxy('127.0.0.1', socks.port));
      (container.read(updateProvider.notifier) as _Updates).offer(
        AvailableUpdate(
          versionName: update.versionName,
          notes: '',
          apk: ReleaseApk(
            abi: 'arm64-v8a',
            versionCode: 26100100,
            url: Uri.parse('https://examples.btlabs.uk/epic-cash-wallets/downloads/app.apk'),
            sha256: update.apk.sha256,
            size: update.apk.size,
          ),
        ),
      );
      platform.canInstall = true;
    });
    tearDown(() async {
      TorNet.useDirect();
      TorNet.onions = null;
      await socks.close();
    });

    test('the download goes to the built-in onion as a name, never to the host itself', () async {
      await notifier().install();
      expect(connects, [
        'lnuvd4uk5ks7bsrt4mxddjahup2dfl5dadiywocbhxfdqwimsahijzid.onion:443',
      ]);
      expect(torBuiltInOnion('examples.btlabs.uk', 443)?.tls, isTrue);
      expect(hits, 0);
      expect(state().phase, UpdatePhase.failed, reason: 'the fake proxy drops the connection');
      expect(platform.installs, isEmpty);
    });

    test('the signed btlabs.json list is asked first', () async {
      TorNet.onions = (host, port) => host == 'examples.btlabs.uk'
          ? (onion: 'listedlistedlistedlistedlistedlistedlistedlistedlistedlist.onion', port: 443, tls: true)
          : null;
      await notifier().install();
      expect(connects, ['listedlistedlistedlistedlistedlistedlistedlistedlistedlist.onion:443']);
    });

    test('a list that does not know the host leaves the built-in onion in use', () async {
      TorNet.onions = (host, port) => torBuiltInOnion(host, port);
      await notifier().install();
      expect(connects.single, endsWith('.onion:443'));
      expect(connects.single, startsWith('lnuvd4uk'));
    });
  });

  group('with Tor on, an APK on a BT Labs server without an onion (android-16)', () {
    setUp(() {
      TorNet.useTor(const SocksProxy('127.0.0.1', 9));
      (container.read(updateProvider.notifier) as _Updates).offer(
        AvailableUpdate(
          versionName: update.versionName,
          notes: '',
          apk: ReleaseApk(
            abi: 'arm64-v8a',
            versionCode: 26100100,
            url: Uri.parse('https://other.btlabs.uk/epic-cash-wallets/downloads/app.apk'),
            sha256: update.apk.sha256,
            size: update.apk.size,
          ),
        ),
      );
    });
    tearDown(TorNet.useDirect);

    const overTor =
        "The update can't be downloaded over Tor yet. Turn Tor off to download it, or get it "
        'from the download page.';

    test('the download fails with a message that says why and what to do', () async {
      platform.canInstall = true;
      await notifier().install();
      expect(state().phase, UpdatePhase.failed);
      expect(state().text!(l), overTor);
      expect(platform.installs, isEmpty);
    });

    test('on return from the permission screen the failure stays, the check beside it does not '
        'hide it', () async {
      await notifier().install();
      expect(state().phase, UpdatePhase.needsPermission);
      platform.canInstall = true;
      // A resume: the update carries on, and the app looks for an update as on every opening.
      final resumed = notifier().resumed();
      final checked = notifier().checkOnOpening();
      await Future.wait([resumed, checked]);
      expect(state().phase, UpdatePhase.failed);
      expect(state().text!(l), overTor);
    });
  });
}
