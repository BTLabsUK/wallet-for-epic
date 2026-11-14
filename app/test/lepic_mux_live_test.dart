// SPDX-License-Identifier: Apache-2.0
// Live: push sessions (mux/1) through the app's LEPIC adapter and its mux policy
// (epicbox_mux.dart) on the real library, with LEPIC's mock chain and a real Epicbox relay that
// offers mux/1. Two wallets name that relay; one pays the other, then they pair and pay through
// the contact's mailbox, which the receiver collects when the relay says mail was queued. Each
// part prints one JSON line: the time from the send to the receive, and the receiver's session
// counters.
//
// Needs LEPIC's mock build of the Linux library (the shipped one has no mock chain;
// MockChain::new refuses), made from the pinned clone into a folder of your own:
//
//   (cd third_party/lepic && CARGO_TARGET_DIR=$PWD/target/mock \
//     cargo xtask mobile --package --mock --out "$OUT" --target x86_64-unknown-linux-gnu)
//   WFE_LEPIC_MOCK_LIB="$OUT/x86_64-unknown-linux-gnu/liblepic_ffi.so" \
//   WFE_MUX_RELAY=<host:port> [WFE_MUX_RELAY_TLS=1] \
//     flutter test test/lepic_mux_live_test.dart
//
// WFE_MUX_RELAY is the relay's `host:port`. LEPIC reaches a loopback host over a plain websocket
// and any other over TLS (wss); WFE_MUX_RELAY_TLS=1 says the relay is the second kind and fails
// the run when the host is loopback. The runtime is `chain.runtime(...)`, not a mock relay: the
// wallets connect to the relay named here. Without the variables it is skipped.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/epicbox_mux.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart' show appConfig;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;
import 'package:lepic/testing.dart' as lepic_testing;

final String? _lib = Platform.environment['WFE_LEPIC_MOCK_LIB'];
final String? _relayAddr = Platform.environment['WFE_MUX_RELAY'];
final bool _tls = Platform.environment['WFE_MUX_RELAY_TLS'] == '1';
const _password = 'test-pass-1234';
final _epic = BigInt.from(100000000);
const _policy = MuxPolicy(enabled: true, waitingEveryS: 300);

String? get _skip => _lib == null || _relayAddr == null ? 'needs WFE_LEPIC_MOCK_LIB and WFE_MUX_RELAY' : null;

class _MemoryStore implements lepic.SecretStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

({String host, int port}) get _relay {
  final addr = _relayAddr!;
  final at = addr.lastIndexOf(':');
  return (host: addr.substring(0, at), port: int.parse(addr.substring(at + 1)));
}

bool _loopback(String host) => host == 'localhost' || host.startsWith('127.');

/// Waits up to [within] for [ready]; false when it did not come.
Future<bool> _until(bool Function() ready, {Duration within = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(within);
  while (!ready()) {
    if (DateTime.now().isAfter(end)) return false;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  return true;
}

void _line(Map<String, Object?> json) => print('MUX_LIVE ${jsonEncode(json)}'); // ignore: avoid_print

void main() {
  late Directory root;
  late lepic_testing.MockChain chain;
  late lepic.LepicRuntime runtime;
  final open = <LepicWalletSession>[];
  var made = 0;

  setUpAll(() async {
    if (_skip == null) {
      await initLepic(libraryPath: _lib);
      expect(_loopback(_relay.host), !_tls, reason: 'WFE_MUX_RELAY_TLS says wss; LEPIC picks ws for a loopback host');
    }
  });

  setUp(() {
    root = Directory.systemTemp.createTempSync('wfe-mux-live-');
    chain = lepic_testing.MockChain(height: BigInt.one);
    runtime = chain.runtime(logLevel: lepic.LogLevel.warn);
  });

  tearDown(() {
    for (final s in open) {
      s.dispose();
    }
    open.clear();
    root.deleteSync(recursive: true);
  });

  /// A wallet on the mock chain whose Epicbox is the relay of the variables; [funded] EPIC on it.
  Future<LepicWalletSession> wallet({int funded = 0}) async {
    made++;
    final w = await lepic.EpicWallet.create(
      runtime: runtime,
      config: lepic.WalletConfig(
        policy: LepicWalletService.hostPolicyOf(appConfig),
        torWanted: false,
        hostFeatures: 0,
        profile: 0,
        dataDir: (Directory('${root.path}/w$made')..createSync()).path,
        chain: lepic.Chain.floonet,
        nodeUrl: 'http://127.0.0.1:1',
        epicboxDomain: _relay.host,
        epicboxPort: _relay.port,
        onionRoutes: const [],
        tuning: LepicWalletService.netTuningOf(appConfig),
        offline: false,
      ),
      store: lepic.lepicSecretStore(_MemoryStore()),
      password: _password,
    );
    if (funded > 0) {
      chain.fund(
        mnemonic: await w.mnemonic(password: _password),
        chain: lepic.Chain.floonet,
        amount: BigInt.from(funded) * _epic,
        child: 0,
      );
      chain.setHeight(height: BigInt.from(20));
      final scan = await w.scan(deleteUnconfirmed: false).toList();
      expect(scan.last.finished, isTrue);
    }
    final s = LepicWalletSession(w);
    open.add(s);
    return s;
  }

  Map<String, Object?> counters(EpicboxMux mux) => {
    'sessions': [for (final s in mux.sessions()) s.toJson()],
  };

  test('a payment reaches a listener on a push session', () async {
    final a = await wallet(funded: 10);
    final b = await wallet();
    final mux = EpicboxMux.of(b, _policy)!;
    final heard = <ListenerEvent>[];
    final sub = mux.startListener().listen(heard.add);
    expect(await _until(() => heard.any((e) => e.kind == ListenerEventKind.connected)), isTrue, reason: 'B connected');
    expect(await _until(() => mux.sessions().any((s) => s.state == PushState.attached)), isTrue, reason: 'B attached');

    final started = Stopwatch()..start();
    await a.sendEpicbox(amount: _epic, minimumConfirmations: BigInt.one, address: await b.epicboxAddress());
    expect(await _until(() => heard.any((e) => e.kind == ListenerEventKind.received)), isTrue, reason: 'B received');
    final ms = started.elapsedMilliseconds;
    _line({'part': 'pay', 'send_to_receive_ms': ms, ...counters(mux)});
    expect(mux.sessions().single.mails, greaterThanOrEqualTo(1));
    // The app ends a listener with stopListener; cancelling the subscription alone waits for it.
    await b.stopListener();
    unawaited(sub.cancel());
    mux.close();
  }, skip: _skip);

  test('a payment through a contact\'s mailbox is collected when the relay says mail was queued', () async {
    final a = await wallet(funded: 10);
    final b = await wallet();
    final mux = EpicboxMux.of(b, _policy)!;
    final listener = mux.startListener().listen((_) {});

    // Pair: A invites, B answers, both collect.
    final invite = await a.pairing.standingCode(name: 'Anna');
    final preview = await b.pairing.openInvite(invite.inviteLink!);
    final answer = await b.pairing.acceptInvite(token: preview.token, name: 'Ben');
    await a.pairing.collect(trigger: PairingCollectTrigger.open);
    await b.pairing.collect(trigger: PairingCollectTrigger.pull);
    await a.pairing.collect(trigger: PairingCollectTrigger.open);
    expect((await a.pairing.pairing(invite.id))!.state, PairingState.paired);
    expect((await a.pairing.checkWords(invite.id, PairingCheck.match))!.state, PairingState.verified);
    expect((await b.pairing.checkWords(answer.id, PairingCheck.match))!.state, PairingState.verified);

    // B's contacts go through push sessions; a collect opens the session of its group.
    await mux.startContacts();
    var pushed = 0;
    final mail = mux.mail.listen((_) => pushed++);
    await b.pairing.collect(trigger: PairingCollectTrigger.open);
    final group = mux.contactsGroup!;
    final relays = muxRelaysOf(await b.pairing.pairings());
    expect(await _until(() => mux.liveFor(relays)), isTrue, reason: 'B\'s contacts attached on $relays in $group');

    final before = b.pairing.messagesCollected;
    final started = Stopwatch()..start();
    await a.pairing.sendViaMailbox(
      id: invite.id,
      amount: _epic,
      minimumConfirmations: BigInt.one,
      message: 'rent',
    );
    expect(await _until(() => pushed > 0), isTrue, reason: 'the relay said mail was queued');
    final queuedMs = started.elapsedMilliseconds;
    await b.pairing.collect(trigger: PairingCollectTrigger.push);
    expect(b.pairing.messagesCollected, greaterThan(before), reason: 'the push collect took the payment');
    final ms = started.elapsedMilliseconds;
    _line({'part': 'contact_mailbox', 'send_to_mail_queued_ms': queuedMs, 'send_to_collected_ms': ms, ...counters(mux)});
    await mail.cancel();
    await mux.stopContacts();
    await b.stopListener();
    unawaited(listener.cancel());
    mux.close();
  }, skip: _skip);
}
