// Live checks against mainnet through LEPIC, for a real Mac (`-d macos`, an iOS Simulator) and
// Linux: a new wallet on a public node, its sync to the node's tip, a restore from its phrase,
// and its Epicbox listener online. Needs the internet; a check whose servers do not answer is
// skipped with a LIVE-CHECK line saying so, a real error fails. Tor is in tor_apple_test.dart.
//
// Prints one `LIVE-CHECK <what>: <result>` line per check. Never print the phrase or PIN;
// compare them only.
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart' show scanFailedPrefix;
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// In the order the check tries them; the first that answers is used.
const _nodes = [
  'https://node.btlabs.uk',
  'https://node.epicnet.us:3413',
  'https://node.epiccash.com:3413',
];

/// In the order the Epicbox check tries them; the first that connects passes.
const _relays = [
  EpicboxRelay(host: 'epicbox.stackwallet.com'),
  EpicboxRelay(host: 'epicbox.epicnet.us'),
  EpicboxRelay(host: 'epicbox.epiccash.com'),
];

const _pin = '123456';
final _minConfirmations = BigInt.from(10);

/// A mainnet tip is past this height.
final _mainnetFloor = BigInt.from(3700000);

void _report(String what, String result) {
  // ignore: avoid_print
  print('LIVE-CHECK $what: $result');
}

Future<Directory> _tempDir(String name) async {
  final base = await getTemporaryDirectory();
  // macOS without the sandbox: path_provider names ~/Library/Caches/<bundle id> but does not
  // create it.
  await base.create(recursive: true);
  return base.createTemp('wfe-it-$name-');
}

/// Runs a scan to its `finished` event; a "Scan failed:" end throws.
Future<ScanResult?> _scan(WalletSession session, String what) async {
  final started = DateTime.now();
  var last = -1;
  ScanProgress? end;
  await for (final p in session.scan().timeout(const Duration(minutes: 5))) {
    final percent = p.percent ?? last;
    if (percent >= last + 25 || p.finished) {
      // ignore: avoid_print
      print('  $what scan ${p.percent ?? '-'} % ${p.message}');
      last = percent;
    }
    if (p.finished) end = p;
  }
  if (end == null) fail('$what scan ended without a finished event');
  if (end.message.startsWith(scanFailedPrefix)) fail('$what: ${end.message}');
  // ignore: avoid_print
  print('  $what scan took ${DateTime.now().difference(started).inSeconds} s');
  return end.result;
}

/// Refreshes against the node as the app does and returns the last summary.
Future<WalletSummary> _refresh(WalletSession session) async {
  WalletSummary? summary;
  await for (final step
      in session
          .refresh(minimumConfirmations: _minConfirmations)
          .timeout(const Duration(minutes: 3))) {
    summary = step.summary ?? summary;
  }
  if (summary == null) fail('refresh ended without balances');
  return summary;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final lepic = LepicWalletService(secrets: MemorySecretStore());
  // Shared by the checks, which run in order; null when an earlier one could not run.
  String? nodeUrl;
  NodeTip? tip;
  WalletConfig? config;
  WalletSession? first;
  // The first wallet's phrase, for the restore only; never printed.
  String? phrase;
  final cleanup = <Future<void> Function()>[];

  setUpAll(() async {
    await initLepic();
  });

  tearDownAll(() async {
    for (final step in cleanup.reversed) {
      try {
        await step();
      } catch (_) {}
    }
  });

  testWidgets('create: a new wallet on the first public node that answers', (
    tester,
  ) async {
    final dir = await _tempDir('live-a');
    cleanup.add(() => dir.delete(recursive: true));
    for (final url in _nodes) {
      final probe = mainnetPreset.config(dataDir: dir.path, nodeUrl: url);
      try {
        final answer = await lepic
            .nodeTip(config: probe)
            .timeout(const Duration(seconds: 30));
        nodeUrl = url;
        tip = answer;
        break;
      } on WalletError catch (e) {
        _report('node $url', 'no answer (${e.kind.name})');
      } on TimeoutException {
        _report('node $url', 'no answer (30 s timeout)');
      }
    }
    if (nodeUrl == null) {
      _report('create', 'skipped: no node answered');
      _report('sync', 'skipped: no node answered');
      _report('restore', 'skipped: no node answered');
      return;
    }
    _report('node', '$nodeUrl (version ${tip!.nodeVersion})');

    config = mainnetPreset.config(
      dataDir: dir.path,
      nodeUrl: nodeUrl!,
      relay: _relays.first,
    );
    final created = await lepic.createWithPin(config: config!, pin: _pin);
    first = created.session;
    cleanup.add(() async => first?.dispose());
    expect(await lepic.walletExists(config: config!), isTrue);
    final words = await first!.mnemonicWithPin(
      pin: _pin,
      sealedPassword: created.sealedPassword,
    );
    expect(words.split(' '), hasLength(24));
    expect(lepic.validateMnemonic(phrase: words), isTrue);
    phrase = words;
    _report(
      'create',
      'ok, wallet ${await first!.fingerprint()} on $nodeUrl, 24-word phrase',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('sync: node tip, then the wallet scans and refreshes to it', (
    tester,
  ) async {
    if (first == null) return;
    final session = first!;
    expect(
      tip!.height > _mainnetFloor,
      isTrue,
      reason: 'node tip ${tip!.height}',
    );
    _report('node tip', '${tip!.height} (> $_mainnetFloor)');

    final found = await _scan(session, 'new wallet');
    final summary = await _refresh(session);
    // The node's tip now, asked as the open wallet asks it.
    final now = (await session.nodeTipFor(config: config!)).height;
    _report(
      'sync',
      'scan finished (found ${found?.found ?? '-'}), refresh at height '
          '${summary.lastConfirmedHeight}, node at $now, validated '
          '${summary.validatedWithNode}, total ${summary.total}',
    );
    expect(summary.validatedWithNode, isTrue);
    expect(summary.lastConfirmedHeight >= tip!.height, isTrue);
    expect(summary.lastConfirmedHeight <= now, isTrue);
    expect(summary.total, BigInt.zero);
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('restore: a second wallet from the first one\'s phrase', (
    tester,
  ) async {
    if (first == null) return;
    final created = first!;
    final dir = await _tempDir('live-b');
    cleanup.add(() => dir.delete(recursive: true));
    final restoreConfig = mainnetPreset.config(
      dataDir: dir.path,
      nodeUrl: nodeUrl!,
      relay: _relays.first,
    );
    final restored = await lepic.createWithPin(
      config: restoreConfig,
      mnemonic: phrase,
      pin: _pin,
    );
    final session = restored.session;
    cleanup.add(() async => session.dispose());
    expect(await session.restoreScanRequired(), isTrue);
    final result = await _scan(session, 'restore');
    expect(await session.restoreScanRequired(), isFalse);
    final summary = await _refresh(session);

    final sameFingerprint =
        await session.fingerprint() == await created.fingerprint();
    final sameAddress =
        await session.epicboxAddress() == await created.epicboxAddress();
    final phraseFingerprint =
        lepic.walletFingerprint(mnemonic: phrase!, chain: Chain.mainnet) ==
        await created.fingerprint();
    _report(
      'restore',
      'scan from block 0 finished (found ${result?.found ?? '-'}), height '
          '${summary.lastConfirmedHeight}, total ${summary.total}; fingerprint '
          '${sameFingerprint ? 'matches' : 'DIFFERS'}, Epicbox address '
          '${sameAddress ? 'matches' : 'DIFFERS'}, phrase fingerprint '
          '${phraseFingerprint ? 'matches' : 'DIFFERS'}',
    );
    expect(sameFingerprint, isTrue);
    expect(sameAddress, isTrue);
    expect(phraseFingerprint, isTrue);
    expect(summary.total, BigInt.zero);
  }, timeout: const Timeout(Duration(minutes: 15)));

  testWidgets(
    'epicbox: the listener comes online on the first relay that connects',
    (tester) async {
      if (first == null) {
        // The listener needs a wallet; one on the preset node still connects to a relay.
        final dir = await _tempDir('live-c');
        cleanup.add(() => dir.delete(recursive: true));
        config = mainnetPreset.config(dataDir: dir.path, nodeUrl: _nodes.first);
        first = (await lepic.createWithPin(config: config!, pin: _pin)).session;
        cleanup.add(() async => first?.dispose());
      }
      final session = first!;
      for (final relay in _relays) {
        final relayConfig = mainnetPreset.config(
          dataDir: config!.dataDir,
          nodeUrl: config!.nodeUrl,
          relay: relay,
        );
        await session.setServers(config: relayConfig);
        final outcome = await _listen(session, relay);
        if (outcome == null) {
          final address = await session.epicboxAddress();
          expect(address.endsWith('@${relay.label}'), isTrue, reason: address);
          _report(
            'epicbox',
            'connected on ${relay.label}, listening as ${_short(address)}',
          );
          await session.stopListener();
          return;
        }
        _report('epicbox ${relay.label}', 'not connected ($outcome)');
      }
      _report('epicbox', 'skipped: no relay connected');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

/// Starts the listener and waits up to 45 s for `connected`. Null when it connected, else why
/// not. The listener is stopped again when it did not connect.
Future<String?> _listen(WalletSession session, EpicboxRelay relay) async {
  final connected = Completer<String?>();
  final stopped = Completer<void>();
  String? lastReason;
  final sub = session.startListener().listen(
    (e) {
      switch (e.kind) {
        case ListenerEventKind.connected:
          if (!connected.isCompleted) connected.complete(null);
        case ListenerEventKind.disconnected:
          lastReason = e.reason ?? e.message;
        case ListenerEventKind.stopped:
          if (!stopped.isCompleted) stopped.complete();
        default:
          break;
      }
    },
    onError: (Object error) {
      if (!connected.isCompleted) connected.complete('stream failed: $error');
    },
    onDone: () {
      if (!connected.isCompleted) connected.complete('stream ended');
      if (!stopped.isCompleted) stopped.complete();
    },
  );
  final outcome = await connected.future.timeout(
    const Duration(seconds: 45),
    onTimeout: () =>
        'no connected event in 45 s, last: ${lastReason ?? 'none'}',
  );
  if (outcome != null) {
    await session.stopListener();
    // The core starts a second listener only once the first has stopped.
    await stopped.future.timeout(const Duration(seconds: 30), onTimeout: () {});
  }
  unawaited(stopped.future.then((_) => sub.cancel()));
  return outcome;
}

/// First 6 and last 6 characters of the address key, as lists show addresses.
String _short(String address) {
  final at = address.indexOf('@');
  final key = at < 0 ? address : address.substring(0, at);
  final rest = at < 0 ? '' : address.substring(at);
  return key.length <= 12
      ? address
      : '${key.substring(0, 6)}…${key.substring(key.length - 6)}$rest';
}
