// SPDX-License-Identifier: Apache-2.0
// Live (a report: the computer showed the link, the phone listed it, the
// computer did not list the phone): two installs of one mainnet phrase over the real LEPIC
// library and real relays link with the computer showing the code on two servers; both list each
// other, also after the computer's wallet locks while its devices run (a switch to its other
// wallet) and opens again. Nothing is sent, so the wallets need no coins. Skipped unless
// WFE_LEPIC_LIB and WFE_LIVE_DIR are set; WFE_LIVE_DIR keeps the throwaway wallets.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/devices/device_service.dart';
import 'package:epic_wallet/src/devices/device_store.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/log.dart';
import 'package:epic_wallet/src/secret_store_api.dart' as app;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart' show appConfig;
import 'package:lepic/lepic.dart' as lepic;

final _env = Platform.environment;
final String? _lib = _env['WFE_LEPIC_LIB'];
final String? _dir = _env['WFE_LIVE_DIR'];
const _password = 'link-test-2610';
const _servers = ['epicbox.stackwallet.com', 'epicbox.epiccash.com'];

// ignore: avoid_print
void _say(String line) => print('LIVE ${DateTime.now().toUtc().toIso8601String().substring(11, 19)} $line');

class _FileStore implements lepic.SecretStore, app.SecretStore {
  _FileStore(this.file);
  final File file;
  Map<String, String> _all() => file.existsSync() ? Map<String, String>.from(jsonDecode(file.readAsStringSync()) as Map) : {};
  @override
  Future<String?> read(String key) async => _all()[key];
  @override
  Future<void> write(String key, String value) async => file.writeAsStringSync(jsonEncode(_all()..[key] = value));
  @override
  Future<void> delete(String key) async => file.writeAsStringSync(jsonEncode(_all()..remove(key)));
}

class _EchoSink extends MemoryLogSink {
  @override
  void record(LogLevel level, String target, String message) {
    // ignore: avoid_print
    if (target == 'devices') print('APP ${level.name} $target $message');
    super.record(level, target, message);
  }
}

late lepic.LepicRuntime _runtime;

Future<LepicWalletSession> _open(String name, {String? mnemonic}) async {
  final config = lepic.WalletConfig(torWanted: false, hostFeatures: 0, 
    dataDir: (Directory('$_dir/$name')..createSync(recursive: true)).path,
    chain: lepic.Chain.mainnet,
    nodeUrl: 'https://node.btlabs.uk',
    epicboxDomain: 'epicbox.stackwallet.com',
    epicboxPort: 443,
    onionRoutes: const [], tuning: LepicWalletService.netTuningOf(appConfig), offline: false,
  );
  final secrets = File('$_dir/$name.secrets.json');
  final exists = secrets.existsSync();
  final store = lepic.lepicSecretStore(_FileStore(secrets));
  final w = exists
      ? await lepic.EpicWallet.open(runtime: _runtime, config: config, store: store, password: _password)
      : await lepic.EpicWallet.create(runtime: _runtime, config: config, store: store, mnemonic: mnemonic, password: _password);
  return LepicWalletSession(w);
}

DeviceService _service(String name, LepicWalletSession s) => DeviceService(
  host: SessionDeviceHost(s),
  store: DeviceStore(_FileStore(File('$_dir/$name.app.json')), chain: Chain.mainnet, walletId: name),
  defaultName: name,
);

String _book(DeviceService s) => '${s.book.devices.map((d) => '"${d.name}" ${d.pairings.keys.join('+')} pending ${d.pending.length}')}';

Future<bool> _until(Future<bool> Function() done, Future<void> Function() step, {int tries = 40}) async {
  for (var i = 0; i < tries; i++) {
    await step();
    if (await done()) return true;
    await Future<void>.delayed(const Duration(seconds: 3));
  }
  return false;
}

void main() {
  final skip = _lib == null || _dir == null ? 'needs WFE_LEPIC_LIB and WFE_LIVE_DIR' : null;

  setUpAll(() async {
    if (skip != null) return;
    await initLepic(libraryPath: _lib);
    _runtime = lepic.LepicRuntime(logLevel: lepic.LogLevel.warn);
    AppLog.use(_EchoSink());
  });

  test('desktop shows, phone scans, desktop wallet locks and opens again', timeout: const Timeout(Duration(minutes: 20)), skip: skip, () async {
    var d = await _open('D');
    final phraseFile = File('$_dir/D.phrase');
    if (!phraseFile.existsSync()) phraseFile.writeAsStringSync(await d.mnemonic(password: _password));
    final p = await _open('P', mnemonic: phraseFile.readAsStringSync());
    var ds = _service('D', d);
    final ps = _service('P', p);
    await ds.load();
    await ps.load();
    Future<void> settle() async {
      await ds.sync(DeviceSyncTrigger.tick);
      await ps.sync(DeviceSyncTrigger.tick);
    }

    await ds.startShowing(_servers);
    _say('D shows: ${ds.link?.phase.name}');
    await ps.startScanned(ds.link!.code!);
    _say('P scanned: ${ps.link?.phase.name}');
    // Paired, each side posts its hello by itself: nothing to tap.
    final done = await _until(() async => ds.link?.phase == LinkPhase.done && ps.link?.phase == LinkPhase.done, settle);
    _say('both done: $done; D link ${ds.link?.phase.name}/${ds.link?.failure?.name}, P link ${ps.link?.phase.name}/${ps.link?.failure?.name}');
    _say('D book: ${_book(ds)}; P book: ${_book(ps)}');
    await _until(() async => ds.book.devices.firstOrNull?.pairings.length == 2 && ps.book.devices.firstOrNull?.pairings.length == 2, settle, tries: 30);
    _say('after the second server: D book: ${_book(ds)}; P book: ${_book(ps)}');
    for (var i = 0; i < 5; i++) {
      await settle();
    }
    _say('after 5 more rounds: D book: ${_book(ds)}; P book: ${_book(ps)}');

    // The desktop switches to its other wallet: the session locks before the service goes.
    d.dispose();
    for (var i = 0; i < 3; i++) {
      await ds.sync(DeviceSyncTrigger.tick);
    }
    _say('D locked, its service ran on: D book ${_book(ds)}');
    ds.dispose();
    d = await _open('D');
    ds = _service('D', d);
    await ds.load();
    _say('D opened again: D book ${_book(ds)}');
    for (var i = 0; i < 5; i++) {
      await settle();
    }
    _say('after 5 rounds: D book: ${_book(ds)}; P book: ${_book(ps)}');
    ds.dispose();
    ps.dispose();
    d.dispose();
    p.dispose();
  });
}
