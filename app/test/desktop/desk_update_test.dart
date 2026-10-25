// The desktop's own updates (data/desk_update.dart, data/desk_update_apply.dart): the release
// file in the signed manifest, the old clients' view of it, the download with its checks, the
// timed checks, Restart to update, and the Windows and Linux appliers.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;
import 'package:epic_wallet/src/btlabs_public.dart';
import 'package:epic_wallet/src/desktop/data/desk_update.dart';
import 'package:epic_wallet/src/desktop/data/desk_update_apply.dart';
import 'package:epic_wallet/src/desktop/data/state.dart' show deskQuitProvider;
import 'package:epic_wallet/src/desktop/desk_l10n.dart' show deskStrings;
import 'package:epic_wallet/src/updater.dart' show updateKeyringProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/signed_update.dart';

/// Newer than any version this app will carry.
const _next = '99.1.0';
const _linuxName = 'EpicCashDesktop-$_next-x86_64.AppImage';
const _winName = 'epic-cash-desktop-$_next-windows-x64-setup.exe';

/// A release file's bytes: big enough for several chunks.
final _bytes = List<int>.generate(300000, (i) => (i * 31 + 7) & 0xff);
final _sha = sha256.convert(_bytes).toString();

Map<String, Object?> _entry(String name, {String? sha, int? size, String version = _next}) => {
  'version': version,
  'url': '$walletDesktopDownloads$name',
  'sha256': sha ?? _sha,
  'size': size ?? _bytes.length,
};

/// The desktop block the release lead writes (tool/desktop_update_entry.sh).
Map<String, Object?> _desktop({String? sha, int? size, String version = _next}) => {
  'windows': _entry(_winName, sha: sha, size: size, version: version),
  'linux': _entry(_linuxName, sha: sha, size: size, version: version),
};

/// Serves one file on the loopback: whole, from a Range, or cut part way.
class _Server {
  _Server(this.body);

  List<int> body;

  /// Bytes sent before the connection is dropped, once.
  int? cutAt;

  /// A 206 that starts somewhere else than asked.
  bool wrongRange = false;
  final ranges = <String?>[];
  late final HttpServer _server;

  Uri get uri => Uri.parse('http://127.0.0.1:${_server.port}/file');

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) async {
      final range = req.headers.value(HttpHeaders.rangeHeader);
      ranges.add(range);
      final res = req.response;
      final from = range == null ? 0 : int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)![1]!);
      if (from > 0) {
        res.statusCode = HttpStatus.partialContent;
        final start = wrongRange ? from + 1 : from;
        res.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-${body.length - 1}/${body.length}');
      }
      res.contentLength = body.length - from;
      final cut = cutAt;
      if (cut != null) {
        cutAt = null;
        final socket = await res.detachSocket();
        socket.add(body.sublist(from, cut));
        await socket.flush();
        socket.destroy();
        return;
      }
      res.add(body.sublist(from));
      await res.close();
    });
  }

  Future<void> close() => _server.close(force: true);
}

class _FakeApplier implements DeskUpdateApplier {
  _FakeApplier({this.suffix = '.AppImage', this.can = true, this.fails = false});

  @override
  final String suffix;
  final bool can;
  final bool fails;
  final applied = <File>[];

  @override
  Future<bool> canApply() async => can;

  @override
  Future<void> apply(File file) async {
    if (fails) throw const FileSystemException('no');
    applied.add(file);
  }
}

void main() {
  final now = DateTime(2026, 10, 22, 12);
  late Directory tmp;
  late _Server server;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('desk_update_test');
    server = _Server(_bytes);
    await server.start();
  });
  tearDown(() async {
    await server.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Directory updates() => Directory('${tmp.path}/updates');

  Future<File> download(WalletDesktopFile f, {void Function(int)? onProgress}) async {
    final client = HttpClient();
    try {
      return await deskDownloadUpdate(client, f, updates(), from: server.uri, onProgress: onProgress);
    } finally {
      client.close(force: true);
    }
  }

  WalletDesktopFile file({String? sha, int? size}) => WalletDesktopFile(
    url: Uri.parse('$walletDesktopDownloads$_linuxName'),
    sha256: sha ?? _sha,
    size: size ?? _bytes.length,
  );

  group('manifest', () {
    test('a per-system entry carries its release file; the one-entry form takes none', () async {
      final r = await verifyWalletUpdate(
        await signedUpdate(testUpdatePayload(desktop: _desktop())),
        keyring: testUpdateKeyring,
        now: now.toUtc(),
      );
      final m = (r as Accepted<WalletUpdate>).manifest;
      final linux = m.desktop!.forSystem('linux')!.file!;
      expect(linux.url.toString(), '$walletDesktopDownloads$_linuxName');
      expect(linux.sha256, _sha);
      expect(linux.size, _bytes.length);
      expect(m.desktop!.forSystem('windows')!.file!.url.pathSegments.last, _winName);
      expect(m.desktop!.forSystem('macos'), isNull);

      final single = await verifyWalletUpdate(
        await signedUpdate(testUpdatePayload(desktop: _entry(_linuxName))),
        keyring: testUpdateKeyring,
        now: now.toUtc(),
      );
      expect((single as Rejected<WalletUpdate>).reason, RejectReason.malformed);
    });

    test('a 26.10.8 client, phone or desktop, reads the new manifest as before', () async {
      // The parser exactly as 26.10.8 shipped it, run on its own against a manifest with the
      // new fields: it must accept the file and see each system's version.
      final old = await Process.run('git', ['show', 'v26.10.8:app/lib/src/btlabs_public.dart']);
      if (old.exitCode != 0) {
        markTestSkipped('no v26.10.8 tag in this checkout: ${old.stderr}');
        return;
      }
      final dir = await tmp.createTemp('old');
      File('${dir.path}/old.dart').writeAsStringSync(old.stdout as String);
      File('${dir.path}/main.dart').writeAsStringSync(r'''
import 'dart:io';
import 'old.dart';

Future<void> main(List<String> a) async {
  final r = await verifyWalletUpdate(File(a[0]).readAsStringSync(),
      keyring: Keyring.parse(File(a[1]).readAsStringSync()), now: DateTime.parse(a[2]));
  if (r is Accepted<WalletUpdate>) {
    final d = r.manifest.desktop!;
    print('accepted ${r.manifest.versionName} ${d.forSystem('windows')!.version} ${d.forSystem('linux')!.version} ${d.forSystem('linux')!.page}');
  } else {
    print('rejected ${(r as Rejected).reason.code}');
  }
}
''');
      final env = File('${dir.path}/update.json')
        ..writeAsStringSync(await signedUpdate(testUpdatePayload(versionName: '26.10.9', desktop: _desktop())));
      final run = await Process.run('dart', [
        '--packages=${File('.dart_tool/package_config.json').absolute.path}',
        '${dir.path}/main.dart',
        env.path,
        File('test/fixtures/btlabs/test-keyring.json').absolute.path,
        now.toUtc().toIso8601String(),
      ]);
      expect(run.exitCode, 0, reason: '${run.stderr}');
      expect((run.stdout as String).trim(), 'accepted 26.10.9 $_next $_next null');
    });
  });

  group('download', () {
    test('the file arrives, matches the manifest, and nothing else stays', () async {
      await updates().create(recursive: true);
      File('${updates().path}/EpicCashDesktop-26.10.8-x86_64.AppImage').writeAsStringSync('an older one');
      final seen = <int>[];
      final f = await download(file(), onProgress: seen.add);
      expect(f.path, '${updates().path}/$_linuxName');
      expect(await f.readAsBytes(), _bytes);
      expect(seen.last, _bytes.length);
      expect(updates().listSync().map((e) => e.path), [f.path]);
      // Again: the kept file is used, nothing is fetched.
      await download(file());
      expect(server.ranges, hasLength(1));
    });

    test('a file with another SHA-256 is refused and deleted', () async {
      await expectLater(download(file(sha: 'b' * 64)), throwsA(isA<DeskDownloadError>().having((e) => e.kind, 'kind', DeskDownloadFail.damaged)));
      expect(updates().listSync(), isEmpty);
    });

    test('a file larger than announced is refused and deleted', () async {
      await expectLater(download(file(size: _bytes.length - 1)), throwsA(isA<DeskDownloadError>().having((e) => e.kind, 'kind', DeskDownloadFail.damaged)));
      expect(updates().listSync(), isEmpty);
    });

    test('a cut download is kept and carries on from where it stopped', () async {
      server.cutAt = 120000;
      await expectLater(download(file()), throwsA(isA<DeskDownloadError>().having((e) => e.kind, 'kind', DeskDownloadFail.interrupted)));
      final part = updates().listSync().single as File;
      expect(part.path, endsWith('.part'));
      expect(part.lengthSync(), 120000);
      final f = await download(file());
      expect(server.ranges, [null, 'bytes=120000-']);
      expect(await f.readAsBytes(), _bytes);
    });

    test('a 206 that starts elsewhere than asked: the partial goes, the next try starts over', () async {
      server.cutAt = 120000;
      await expectLater(download(file()), throwsA(isA<DeskDownloadError>()));
      final part = updates().listSync().whereType<File>().single;
      expect(part.lengthSync(), 120000);
      server.wrongRange = true;
      await expectLater(download(file()), throwsA(isA<DeskDownloadError>().having((e) => e.status, 'status', 206)));
      expect(updates().listSync(), isEmpty, reason: 'else every retry fails the same way');
      server.wrongRange = false;
      expect(await (await download(file())).readAsBytes(), _bytes);
    });

    test('a server that cannot be reached says so', () async {
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      await expectLater(
        deskDownloadUpdate(client, file(), updates(), from: server.uri.replace(port: 1)),
        throwsA(isA<DeskDownloadError>().having((e) => e.kind, 'kind', DeskDownloadFail.unreachable)),
      );
    });
  });

  group('controller', () {
    ProviderContainer make({
      Object? desktop,
      DeskUpdateApplier? applier,
      bool canQuit = true,
      (Duration, Duration)? schedule,
      void Function()? onFetch,
      DeskUpdateMarks? marks,
      int status = 200,
    }) {
      final fake = applier ?? _FakeApplier();
      final c = ProviderContainer(overrides: [
        deskManifestFetchProvider.overrideWithValue((_) async {
          onFetch?.call();
          if (status != 200) return (status, '');
          return (200, await signedUpdate(testUpdatePayload(desktop: desktop ?? _desktop())));
        }),
        deskUpdateClockProvider.overrideWithValue(() => now),
        updateKeyringProvider.overrideWithValue(testUpdateKeyring),
        deskUpdateApplierProvider.overrideWithValue(fake),
        deskQuitProvider.overrideWithValue(canQuit ? () async {} : null),
        deskUpdateDirProvider.overrideWithValue(() async => updates()),
        deskUpdateDownloaderProvider.overrideWithValue((f, onProgress) => download(f, onProgress: onProgress)),
        if (schedule != null) deskUpdateScheduleProvider.overrideWithValue(schedule),
        deskUpdateMarksProvider.overrideWithValue(marks == null ? null : () async => marks),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('offers the release file, downloads and checks it, then Restart to update applies it', () async {
      final applier = _FakeApplier();
      final c = make(applier: applier);
      final n = c.read(deskUpdateProvider.notifier);
      await n.check();
      var s = c.read(deskUpdateProvider);
      expect(s.phase, DeskUpdatePhase.available);
      expect(s.version, _next);
      expect(s.file?.url.pathSegments.last, _linuxName);
      final progress = <double>[];
      c.listen(deskUpdateProvider, (_, next) {
        if (next.phase == DeskUpdatePhase.downloading) progress.add(next.progress!);
      });
      await n.download();
      s = c.read(deskUpdateProvider);
      expect(s.phase, DeskUpdatePhase.ready);
      expect(await s.download!.readAsBytes(), _bytes);
      expect(progress.first, 0);
      expect(progress, orderedEquals([...progress]..sort()));
      expect(progress.length, lessThanOrEqualTo(101), reason: 'whole per cent steps only');
      // A check meanwhile changes nothing.
      await n.check();
      expect(c.read(deskUpdateProvider).phase, DeskUpdatePhase.ready);
      expect(await n.restart(), isTrue);
      expect(applier.applied.single.path, s.download!.path);
    });

    test('a download that does not match: Try again, nothing kept', () async {
      final c = make(desktop: _desktop(sha: 'c' * 64));
      final n = c.read(deskUpdateProvider.notifier);
      await n.check();
      await n.download();
      final s = c.read(deskUpdateProvider);
      expect(s.phase, DeskUpdatePhase.available);
      expect(s.problem, deskStrings.deskUpdErrDamaged);
      expect(s.file, isNotNull, reason: 'it can be tried again');
      expect(updates().listSync(), isEmpty);
    });

    test('a download of the wrong size: refused the same way', () async {
      final c = make(desktop: _desktop(size: 1000));
      final n = c.read(deskUpdateProvider.notifier);
      await n.check();
      await n.download();
      expect(c.read(deskUpdateProvider).problem, deskStrings.deskUpdErrDamaged);
    });

    test('Restart to update checks the file again: a changed one is offered again', () async {
      final applier = _FakeApplier();
      final c = make(applier: applier);
      final n = c.read(deskUpdateProvider.notifier);
      await n.check();
      await n.download();
      await c.read(deskUpdateProvider).download!.writeAsString('changed');
      expect(await n.restart(), isFalse);
      final s = c.read(deskUpdateProvider);
      expect(s.phase, DeskUpdatePhase.available);
      expect(s.problem, deskStrings.deskUpdErrDamaged);
      expect(applier.applied, isEmpty);
    });

    test('an update that cannot be put in place says so and keeps the page', () async {
      final c = make(applier: _FakeApplier(fails: true));
      final n = c.read(deskUpdateProvider.notifier);
      await n.check();
      await n.download();
      expect(await n.restart(), isFalse);
      final s = c.read(deskUpdateProvider);
      expect(s.phase, DeskUpdatePhase.ready);
      expect(s.problem, deskStrings.deskUpdErrInstall);
      expect(s.page, deskReleasesUrl);
    });

    test('a failed install: a check offers the download again, and Try again fetches it', () async {
      final c = make(applier: _FakeApplier(fails: true));
      final n = c.read(deskUpdateProvider.notifier);
      await n.check();
      await n.download();
      expect(await n.restart(), isFalse);
      expect(c.read(deskUpdateProvider).problem, deskStrings.deskUpdErrInstall);
      await n.check();
      var s = c.read(deskUpdateProvider);
      expect(s.phase, DeskUpdatePhase.available);
      expect(s.problem, isNull);
      expect(s.file, isNotNull);
      await n.download();
      expect(c.read(deskUpdateProvider).phase, DeskUpdatePhase.ready);
    });

    test('the page only, when this copy cannot install the update itself', () async {
      for (final c in [
        make(applier: _FakeApplier(can: false)),
        make(applier: _FakeApplier(suffix: '.exe')),
        make(canQuit: false),
        make(desktop: {'linux': {'version': _next}}),
      ]) {
        await c.read(deskUpdateProvider.notifier).check();
        final s = c.read(deskUpdateProvider);
        expect(s.phase, DeskUpdatePhase.available);
        expect(s.file, isNull);
        expect(s.page, deskReleasesUrl);
        await c.read(deskUpdateProvider.notifier).download();
        expect(c.read(deskUpdateProvider).phase, DeskUpdatePhase.available, reason: 'nothing to download');
      }
    });

    test('checks shortly after the wallet opens and then periodically, once scheduled', () async {
      var fetches = 0;
      final c = make(schedule: (const Duration(milliseconds: 40), const Duration(milliseconds: 150)), onFetch: () => fetches++);
      final n = c.read(deskUpdateProvider.notifier);
      n.schedule();
      n.schedule();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(fetches, 1, reason: 'the first check');
      expect(c.read(deskUpdateProvider).phase, DeskUpdatePhase.available);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(fetches, inInclusiveRange(3, 4), reason: 'every period after, one timer only');
      c.dispose();
      final stopped = fetches;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(fetches, stopped, reason: 'no checks after the app is gone');
    });

    group('an update that did not finish', () {
      test("Setup's mark or a recorded version newer than this one; nothing once it runs", () {
        const running = '26.10.11';
        expect(unfinishedUpdate(running), isNull, reason: 'no marks');
        expect(unfinishedUpdate(running, setup: running), running, reason: 'new code over old files');
        expect(unfinishedUpdate(running, setup: '26.10.12'), '26.10.12', reason: 'old code, killed before the code went in');
        expect(unfinishedUpdate(running, setup: '', target: '26.10.12'), '26.10.12', reason: 'a mark without a version');
        expect(unfinishedUpdate(running, setup: ''), running);
        expect(unfinishedUpdate(running, setup: '26.10.10'), isNull, reason: 'a left-over mark of an older Setup');
        expect(unfinishedUpdate(running, target: '26.10.12'), '26.10.12', reason: 'Setup stopped before any file');
        expect(unfinishedUpdate(running, target: running), isNull, reason: 'the update finished');
        expect(unfinishedUpdate(running, target: '26.10.10'), isNull);
        expect(unfinishedUpdate(running, setup: running, target: running), running, reason: "Setup's mark wins");
      });

      DeskUpdateMarks marksIn(Directory dir, {String? setup, String? target}) {
        final m = DeskUpdateMarks(setup: File('${dir.path}/app/$deskSetupMarkName'), target: File('${dir.path}/cache/update-target'));
        if (setup != null) (m.setup..parent.createSync(recursive: true)).writeAsStringSync(setup);
        if (target != null) (m.target..parent.createSync(recursive: true)).writeAsStringSync(target);
        return m;
      }

      test('found when the wallet opens; Try again checks, downloads and runs the update once more', () async {
        final applier = _FakeApplier();
        final marks = marksIn(tmp, target: _next);
        final c = make(applier: applier, marks: marks, schedule: (const Duration(hours: 1), const Duration(hours: 2)));
        final n = c.read(deskUpdateProvider.notifier);
        n.schedule();
        await n.detect();
        var s = c.read(deskUpdateProvider);
        expect(s.phase, DeskUpdatePhase.unfinished);
        expect(s.version, _next);
        expect(s.offered, isTrue);
        await n.check();
        expect(c.read(deskUpdateProvider).phase, DeskUpdatePhase.unfinished, reason: 'a timed check leaves it for Try again');
        expect(await n.retry(), isTrue);
        s = c.read(deskUpdateProvider);
        expect(s.phase, DeskUpdatePhase.ready);
        expect(applier.applied.single.path, s.download!.path);
        expect(marks.target.readAsStringSync(), _next, reason: 'recorded again before Setup started');
      });

      test('new code over old files: the same version is installed once more', () async {
        final applier = _FakeApplier();
        final marks = marksIn(tmp, setup: deskAppVersion);
        final c = make(applier: applier, marks: marks, desktop: _desktop(version: deskAppVersion));
        final n = c.read(deskUpdateProvider.notifier);
        await n.checkOnce();
        expect(c.read(deskUpdateProvider).phase, DeskUpdatePhase.unfinished);
        expect(c.read(deskUpdateProvider).version, deskAppVersion);
        expect(await n.retry(), isTrue);
        expect(applier.applied, hasLength(1));
        expect(marks.setup.existsSync(), isTrue, reason: 'Setup removes its own mark once its files are in');
      });

      test('without the marks the same version is the latest', () async {
        final c = make(desktop: _desktop(version: deskAppVersion), marks: marksIn(tmp));
        await c.read(deskUpdateProvider.notifier).checkOnce();
        expect(c.read(deskUpdateProvider).phase, DeskUpdatePhase.latest);
      });

      test('a finished update: its record goes, nothing is shown; an old mark goes too', () async {
        final marks = marksIn(tmp, setup: '0.1.0', target: deskAppVersion);
        final c = make(marks: marks);
        await c.read(deskUpdateProvider.notifier).detect();
        expect(c.read(deskUpdateProvider).phase, DeskUpdatePhase.idle);
        expect(marks.target.existsSync(), isFalse);
        expect(marks.setup.existsSync(), isFalse);
      });

      test('Try again with no answer: still unfinished, with the reason', () async {
        final c = make(marks: marksIn(tmp, target: _next), status: 503);
        final n = c.read(deskUpdateProvider.notifier);
        await n.detect();
        expect(await n.retry(), isFalse);
        final s = c.read(deskUpdateProvider);
        expect(s.phase, DeskUpdatePhase.unfinished);
        expect(s.version, _next);
        expect(s.problem, deskStrings.deskDataUpdStatus(503));
      });

      test('Restart to update records the version first; a Setup that does not start leaves no record', () async {
        final marks = marksIn(tmp);
        final c = make(marks: marks);
        final n = c.read(deskUpdateProvider.notifier);
        await n.check();
        await n.download();
        expect(await n.restart(), isTrue);
        expect(marks.target.readAsStringSync(), _next);

        marks.target.deleteSync();
        final failing = make(applier: _FakeApplier(fails: true), marks: marks);
        final f = failing.read(deskUpdateProvider.notifier);
        await f.check();
        await f.download();
        expect(await f.restart(), isFalse);
        expect(marks.target.existsSync(), isFalse);
      });

      test('no marks where nothing can be left half done (Linux)', () async {
        final c = make();
        await c.read(deskUpdateProvider.notifier).checkOnce();
        expect(c.read(deskUpdateProvider).phase, DeskUpdatePhase.available);
      });
    });
  });

  group('Windows', () {
    test('runs the installer quietly, told to wait for the app and open it again', () async {
      final started = <(String, List<String>)>[];
      final a = WindowsSetupApplier(start: (exe, args, {workingDirectory, environment}) async => started.add((exe, args)));
      expect(a.suffix, '.exe');
      await a.apply(File('${tmp.path}/$_winName'));
      expect(started.single.$1, '${tmp.path}/$_winName');
      expect(started.single.$2, ['/SILENT', '/NORESTART', '/UPDATEFROMAPP=1']);
    });

    test('only the installed copy updates itself', () async {
      const installed = r'C:\Users\tester\Apps\EpicWallet';
      WindowsSetupApplier at(String exe, {String? registry}) =>
          WindowsSetupApplier(exe: exe, home: r'C:\Users\tester', installedAt: () async => registry);
      expect(await at('$installed\\epic_wallet.exe').canApply(), isTrue, reason: 'the default folder');
      expect(await at(r'c:\users\tester\apps\epicwallet\epic_wallet.exe').canApply(), isTrue, reason: 'case does not matter');
      expect(await at(r'C:\Users\tester\code\build\runner\Release\epic_wallet.exe').canApply(), isFalse, reason: 'a build elsewhere');
      expect(await at(r'D:\Wallet\epic_wallet.exe', registry: r'D:\Wallet\').canApply(), isTrue, reason: 'the folder Setup was told');
      expect(await at('$installed\\epic_wallet.exe', registry: r'D:\Wallet').canApply(), isFalse);
    });

    test('the installer script waits for the app and opens it again for that run only', () {
      final iss = File('windows/installer/epic_wallet.iss').readAsStringSync();
      expect(iss, contains('#define AppMutexName "Local\\uk.btlabs.epiccash.desktop.single"'));
      expect(File('windows/runner/main.cpp').readAsStringSync(), contains('L"Local\\\\uk.btlabs.epiccash.desktop.single"'));
      expect(iss, contains("ExpandConstant('{param:UPDATEFROMAPP|0}') = '1'"));
      // A running 26.10.15 or older holds the mutex under the old id: Setup waits for it too (WIN-1).
      expect(iss, contains('#define OldAppMutexName "Local\\com.blacktyger.EpicWallet.single"'));
      expect(iss, contains('AppMutex={#AppMutexName},{#OldAppMutexName}'));
      expect(iss, contains("CheckForMutexes('{#AppMutexName},{#OldAppMutexName}')"));
      expect(iss, contains('Flags: nowait; Check: FromApp'));
      // An uninstall leaves no empty app folder and no window key; the data folder stays.
      expect(iss, contains('Type: dirifempty; Name: "{app}"'));
      expect(iss, contains(r'Root: HKCU; Subkey: "Software\BT Labs\Epic Cash Desktop"; Flags: uninsdeletekey'));
      expect(iss, isNot(contains('.epic_cash_desktop"; Flags')));
      expect(iss, contains('if FromApp and not InstallDone'), reason: 'a failed or cancelled install opens the app again');
    });

    test('the installer marks an install in progress and copies the code last, the exe after it', () {
      final iss = File('windows/installer/epic_wallet.iss').readAsStringSync();
      expect(iss, contains("MarkFile = '$deskSetupMarkName';"));
      final steps = iss.substring(iss.indexOf('procedure CurStepChanged'));
      expect(
        steps.indexOf('SaveStringToFile(Mark'),
        allOf(greaterThan(steps.indexOf('CurStep = ssInstall')), lessThan(steps.indexOf('CurStep = ssPostInstall'))),
      );
      expect(steps.indexOf('DeleteFile(Mark)'), greaterThan(steps.indexOf('CurStep = ssPostInstall')));
      expect(iss, contains('Type: files; Name: "{app}\\$deskSetupMarkName"'), reason: 'the uninstaller removes a mark left behind');
      final files = iss.split('\n').where((l) => l.startsWith('Source: "{#SourceDir}')).toList();
      expect(files, hasLength(4));
      expect(files[0], contains(r'Excludes: "*.lib,*.exp,*.pdb,*.ilk,\lepic_ffi.dll,\data\app.so,\epic_wallet.exe"'));
      expect(files.skip(1).map((l) => l.split('"')[1]), [r'{#SourceDir}\lepic_ffi.dll', r'{#SourceDir}\data\app.so', r'{#SourceDir}\epic_wallet.exe']);
    });
  });

  group('Linux AppImage', () {
    test('the relaunch script does not start the new copy while the old one still runs', () async {
      final dir = await Directory.systemTemp.createTemp('relaunch');
      addTearDown(() => dir.delete(recursive: true));
      final mark = File('${dir.path}/mark');
      final app = File('${dir.path}/app.sh')..writeAsStringSync('#!/bin/sh\necho started > "${mark.path}"\n');
      await Process.run('chmod', ['755', app.path]);
      // Same text, a short limit: the old process (this test's) is alive throughout.
      final script = AppImageApplier.relaunch.replaceAll('600', '3');
      expect(script, isNot(AppImageApplier.relaunch));
      final run = await Process.run('/bin/sh', ['-c', script, 'x', '$pid', app.path]);
      expect(run.exitCode, 1);
      expect(mark.existsSync(), isFalse);
    });

    late Directory apps;
    late File current, downloaded;
    late List<({String exe, List<String> args, String? dir, Map<String, String>? env})> started;

    setUp(() {
      apps = Directory('${tmp.path}/Applications')..createSync();
      current = File('${apps.path}/EpicCashDesktop-26.10.8-x86_64.AppImage')..writeAsStringSync('old');
      downloaded = File('${tmp.path}/$_linuxName')..writeAsStringSync('new');
      started = [];
    });

    AppImageApplier applier(Map<String, String> env) => AppImageApplier(
      environment: env,
      pid: 4242,
      start: (exe, args, {workingDirectory, environment}) async => started.add((exe: exe, args: args, dir: workingDirectory, env: environment)),
    );

    test('replaces the AppImage in place and starts it once this process has exited', () async {
      final a = applier({'APPIMAGE': current.path, 'APPDIR': '/tmp/.mount_EpicCa', 'ARGV0': 'x', 'OWD': '/home/u', 'HOME': '/home/u'});
      expect(a.suffix, '.AppImage');
      expect(await a.canApply(), isTrue);
      await a.apply(downloaded);
      expect(current.readAsStringSync(), 'new');
      expect(current.statSync().modeString(), 'rwxr-xr-x');
      expect(apps.listSync().map((e) => e.path), [current.path], reason: 'no temporary file left');
      final s = started.single;
      expect(s.exe, '/bin/sh');
      expect(s.args, ['-c', AppImageApplier.relaunch, 'epic-cash-desktop-update', '4242', current.path]);
      expect(s.dir, apps.path);
      expect(s.env, {'HOME': '/home/u'}, reason: "the runtime's variables are the new copy's own");
    });

    test('not an AppImage, gone, or a folder this user may not write: the page instead', () async {
      expect(await applier({}).canApply(), isFalse);
      expect(await applier({'APPIMAGE': '${apps.path}/gone.AppImage'}).canApply(), isFalse);
      await Process.run('chmod', ['555', apps.path]);
      addTearDown(() => Process.run('chmod', ['755', apps.path]));
      expect(await applier({'APPIMAGE': current.path}).canApply(), isFalse);
      await expectLater(applier({'APPIMAGE': current.path}).apply(downloaded), throwsA(isA<FileSystemException>()));
      expect(current.readAsStringSync(), 'old');
      expect(started, isEmpty);
    });

    test('the relaunch waits for the old process to exit, then runs the new AppImage', () async {
      final mark = File('${tmp.path}/started');
      final app = File('${apps.path}/app.AppImage')..writeAsStringSync('#!/bin/sh\necho "\$*" > "\$MARK"\n');
      await Process.run('chmod', ['755', app.path]);
      final old = await Process.start('sleep', ['1']);
      final clock = Stopwatch()..start();
      final run = await Process.run('/bin/sh', ['-c', AppImageApplier.relaunch, 'epic-cash-desktop-update', '${old.pid}', app.path], environment: {'MARK': mark.path});
      expect(run.exitCode, 0, reason: '${run.stderr}');
      expect(await old.exitCode, 0);
      expect(clock.elapsedMilliseconds, greaterThan(700), reason: 'it waited for the old process');
      expect(mark.existsSync(), isTrue);
    });
  });

  test('the release helper prints the block clients read', () async {
    final dir = await tmp.createTemp('release');
    File('${dir.path}/$_winName').writeAsBytesSync(_bytes);
    File('${dir.path}/$_linuxName').writeAsBytesSync(_bytes.sublist(1));
    final run = await Process.run('tool/desktop_update_entry.sh', [_next, dir.path]);
    expect(run.exitCode, 0, reason: '${run.stderr}');
    final block = jsonDecode(run.stdout as String) as Map<String, dynamic>;
    final r = await verifyWalletUpdate(
      await signedUpdate(testUpdatePayload(desktop: block['desktop'])),
      keyring: testUpdateKeyring,
      now: now.toUtc(),
    );
    final d = (r as Accepted<WalletUpdate>).manifest.desktop!;
    expect(d.forSystem('windows')!.file!.sha256, _sha);
    expect(d.forSystem('linux')!.file!.size, _bytes.length - 1);
    expect(d.forSystem('linux')!.file!.url.toString(), '$walletDesktopDownloads$_linuxName');
  });
}
