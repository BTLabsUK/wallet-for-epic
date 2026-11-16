// SPDX-License-Identifier: Apache-2.0
// Live: how fast a pairing finishes on both sides over a real Epicbox relay that offers mux/1,
// through the app's own wiring of the contacts check (contact_check.dart, epicbox_mux.dart),
// as the desktop shell and the phone's notices make it. Each run prints one JSON line with the
// milliseconds from the invite to each step; the last line holds min, median and max.
//
//  - `bot`: the scanned side is a wallet as the Epic Tip Bot runs one (reads every 3 s, sends
//    its hello as soon as it is paired); the wallet under test answers its invite.
//  - `wallet`: two wallets on the app's wiring; each sends a message once it is paired.
//
// Needs LEPIC's mock build of the Linux library and a relay, as lepic_mux_live_test.dart:
//
//   WFE_LEPIC_MOCK_LIB=<liblepic_ffi.so> WFE_MUX_RELAY=127.0.0.1:<port> \
//     [WFE_PAIR_RUNS=10] [WFE_PAIR_KIND=bot|wallet] flutter test test/pairing_attach_live_test.dart
//
// Without the variables it is skipped.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/boosts.dart';
import 'package:epic_wallet/src/contact_check.dart';
import 'package:epic_wallet/src/epicbox_mux.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart' show appConfig;
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;
import 'package:lepic/testing.dart' as lepic_testing;

final String? _lib = Platform.environment['WFE_LEPIC_MOCK_LIB'];
final String? _relayAddr = Platform.environment['WFE_MUX_RELAY'];
final int _runs = int.tryParse(Platform.environment['WFE_PAIR_RUNS'] ?? '') ?? 1;
final Set<String> _kinds = {...(Platform.environment['WFE_PAIR_KIND'] ?? 'bot,wallet').split(',')};
/// The pairing screens' boost: 10 s on the desktop, 5 s on the phone.
final Duration _screenBoost = Duration(seconds: int.tryParse(Platform.environment['WFE_PAIR_BOOST'] ?? '') ?? 10);
const _password = 'test-pass-1234';
const _policy = MuxPolicy(enabled: true, waitingEveryS: 300);

/// The longest a run may take: past the app's slowest wait, so a slow run is measured, not failed.
const _runLimit = Duration(seconds: 120);

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

Future<bool> _until(bool Function() ready, {Duration within = _runLimit}) async {
  final end = DateTime.now().add(within);
  while (!ready()) {
    if (DateTime.now().isAfter(end)) return false;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return true;
}

void _print(String line) => print(line); // ignore: avoid_print

/// The steps of one run, in milliseconds from the invite.
class _Marks {
  final clock = Stopwatch();
  final at = <String, int>{};
  late final DateTime started;

  void start() {
    started = DateTime.now().toUtc();
    clock.start();
  }

  void mark(String step) => at.putIfAbsent(step, () => clock.elapsedMilliseconds);
  bool has(String step) => at.containsKey(step);

  /// With WFE_PAIR_TRACE: one line per thing the wiring did, for reading a slow run.
  void note(String what) {
    if (Platform.environment['WFE_PAIR_TRACE'] != null) _print('  ${clock.elapsedMilliseconds} $what');
  }
}

/// A wallet on the app's wiring: the push sessions, the contacts check and its live switch, the
/// pairing events, as `shell.dart` makes them.
class _AppSide {
  _AppSide(this.name, this.s, this.marks);

  final String name;
  final LepicWalletSession s;
  final _Marks marks;
  late final EpicboxMux mux;
  late final MuxLive live;
  late final ContactCheck check;
  StreamSubscription<ListenerEvent>? _listener;
  StreamSubscription<PairingEvent>? _events;
  Timer? _watch;
  List<PairingRecord> pairings = const [];
  void Function()? _endHelloBoost;

  /// After [stop] nothing more is read: the wallet is disposed next.
  bool _stopped = false;

  /// Called once this side is paired (the other side's hello, a wallet's first message).
  Future<void> Function()? onPaired;

  Future<void> start() async {
    mux = EpicboxMux.of(s, _policy)!;
    _listener = mux.startListener().listen((_) {});
    await mux.startContacts();
    live = MuxLive(relays: () => muxRelaysOf(pairings));
    check = ContactCheck(
      boosts: s.boosts,
      collect: (trigger, {only}) async {
        marks.note('$name collect ${trigger.name} only=$only live=${live.live}');
        final n = await collectCounting(s.pairing, trigger, only: only);
        marks.note('$name collect ${trigger.name} done: $n');
        return n;
      },
      // The name service's read: the payloads LEPIC took.
      sync: (_) async {
        if ((await s.pairing.payloads()).isNotEmpty) marks.mark('$name.hello_read');
      },
      inFlight: () => contactsInFlight(pairings),
      idleChecks: appConfig.contactsIdleChecks,
      inFlightEvery: appConfig.contactsInFlightCheck,
      live: () => live.live,
      paused: () => _stopped,
    );
    live
      ..check = check
      ..bind(mux);
    check.start();
    _events = s.pairing.events().listen((e) {
      marks.note('$name event ${e.kind.name} live=${live.live} base=${check.nextFull.difference(DateTime.now()).inMilliseconds}');
      // The shell: a pairing moved, then the lists read again.
      check.pairingEvent();
      unawaited(_refresh());
    });
    // What LEPIC holds, read often: when this side became paired and when a payload came.
    _watch = Timer.periodic(const Duration(milliseconds: 20), (_) => unawaited(_look()));
  }

  bool _looking = false;
  Future<void> _look() async {
    if (_looking || _stopped) return;
    _looking = true;
    try {
      final records = await s.pairing.pairings();
      // The pairings provider: the shell's live switch reads the relays of these.
      if (records.length != pairings.length || records.any((r) => !pairings.any((p) => p.id == r.id && p.state == r.state))) {
        pairings = records;
        live.relaysChanged();
        check.inFlightChanged();
      }
      if (records.any((r) => r.state == PairingState.paired || r.state == PairingState.verified)) {
        if (!marks.has('$name.paired')) {
          marks.mark('$name.paired');
          // The words screen's hello wait boosts the relays to 10 s for its 30 s.
          _endHelloBoost = boostRelays(s.boosts, const Duration(seconds: 10), window: const Duration(seconds: 30));
          unawaited(onPaired?.call());
        }
      }
      if ((await s.pairing.payloads()).isNotEmpty) marks.mark('$name.hello_stored');
    } on Object {
      // A read during a collect may fail; the next look reads again.
    } finally {
      _looking = false;
    }
  }

  Future<void> _refresh() async {
    if (_stopped) return;
    pairings = await s.pairing.pairings();
    live
      ..bind(mux)
      ..relaysChanged();
    check.inFlightChanged();
  }

  Future<void> stop() async {
    _stopped = true;
    _watch?.cancel();
    _endHelloBoost?.call();
    await _events?.cancel();
    check.stop();
    live.dispose();
    await mux.stopContacts();
    await s.stopListener();
    unawaited(_listener?.cancel());
    mux.close();
  }
}

/// A wallet as the Tip Bot runs one: reads every 3 s, sends its hello once paired.
class _BotSide {
  _BotSide(this.s, this.marks);

  final LepicWalletSession s;
  final _Marks marks;
  Timer? _timer;
  bool _busy = false;
  String? id;

  void start() => _timer = Timer.periodic(const Duration(seconds: 3), (_) => unawaited(_tick()));

  Future<void> _tick() async {
    if (_busy) return;
    _busy = true;
    try {
      await s.pairing.collect(trigger: PairingCollectTrigger.foreground);
      final r = id == null ? null : await s.pairing.pairing(id!);
      if (r != null && (r.state == PairingState.paired || r.state == PairingState.verified) && !marks.has('bot.paired')) {
        marks.mark('bot.paired');
        await s.pairing.postPayload(id: id!, bytes: utf8.encode('hello'));
        marks.mark('bot.hello_posted');
      }
    } on Object {
      // The next tick tries again.
    } finally {
      _busy = false;
    }
  }

  void stop() => _timer?.cancel();
}

Map<String, Object> _stats(List<int> values) {
  final v = [...values]..sort();
  return {'n': v.length, 'min': v.first, 'median': v[v.length ~/ 2], 'max': v.last};
}

void main() {
  late Directory root;
  late lepic_testing.MockChain chain;
  late lepic.LepicRuntime runtime;
  final open = <LepicWalletSession>[];
  var made = 0;

  setUpAll(() async {
    if (_skip == null) await initLepic(libraryPath: _lib);
  });

  setUp(() {
    root = Directory.systemTemp.createTempSync('wfe-pair-attach-');
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

  Future<LepicWalletSession> wallet() async {
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
    final s = LepicWalletSession(w);
    open.add(s);
    return s;
  }

  /// One pairing: [inviter] makes the code, the wallet under test answers it.
  Future<Map<String, int>> run(String kind) async {
    final marks = _Marks();
    final wallet0 = await wallet();
    final other = await wallet();
    final me = _AppSide('wallet', wallet0, marks);
    _AppSide? peer;
    _BotSide? bot;
    await me.start();
    if (kind == 'bot') {
      bot = _BotSide(other, marks);
    } else {
      peer = _AppSide('peer', other, marks);
      await peer.start();
      peer.onPaired = () async {
        final id = peer!.pairings.firstOrNull?.id ?? (await other.pairing.pairings()).first.id;
        await other.pairing.postPayload(id: id, bytes: utf8.encode('hi'));
        marks.mark('peer.hello_posted');
      };
      me.onPaired = () async {
        final id = (await wallet0.pairing.pairings()).first.id;
        await wallet0.pairing.postPayload(id: id, bytes: utf8.encode('hi'));
        marks.mark('wallet.hello_posted');
      };
    }
    final invite = await other.pairing.standingCode(name: kind == 'bot' ? 'Bot' : 'Anna');
    bot?.id = invite.id;
    bot?.start();
    // The pairing screens on both app sides boost the relays while they are open.
    // WFE_PAIR_BOOST=0: no screen open (the pairing finished in the background).
    final unboost = [
      if (_screenBoost > Duration.zero) boostRelays(wallet0.boosts, _screenBoost),
      if (peer != null && _screenBoost > Duration.zero) boostRelays(other.boosts, _screenBoost),
    ];
    marks.start();
    final preview = await wallet0.pairing.openInvite(invite.inviteLink!);
    await wallet0.pairing.acceptInvite(token: preview.token, name: 'Ben');
    marks.mark('wallet.answer_posted');
    final done = kind == 'bot'
        ? () => marks.has('wallet.hello_read')
        : () => marks.has('wallet.hello_stored') && marks.has('peer.hello_stored');
    final ok = await _until(done);
    marks.mark(ok ? 'done' : 'gave_up');
    for (final u in unboost) {
      u();
    }
    bot?.stop();
    await me.stop();
    await peer?.stop();
    _print('PAIR_TIMING ${jsonEncode({'kind': kind, 'started': marks.started.toIso8601String(), ...marks.at})}');
    return marks.at;
  }

  for (final kind in ['bot', 'wallet']) {
    test('pairing with a $kind finishes on both sides', () async {
      final all = <Map<String, int>>[];
      for (var i = 0; i < _runs; i++) {
        all.add(await run(kind));
      }
      final steps = {for (final m in all) ...m.keys};
      _print(
        'PAIR_STATS ${jsonEncode({
          'kind': kind,
          for (final step in steps)
            if (all.every((m) => m.containsKey(step))) step: _stats([for (final m in all) m[step]!]),
        })}',
      );
      expect(all.every((m) => m.containsKey('done')), isTrue, reason: 'every run finished within ${_runLimit.inSeconds} s');
    }, skip: _skip ?? (_kinds.contains(kind) ? null : 'WFE_PAIR_KIND leaves it out'), timeout: Timeout(_runLimit * (_runs + 1)));
  }
}
