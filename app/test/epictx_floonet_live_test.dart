// SPDX-License-Identifier: Apache-2.0
// Live on floonet (EPICTX native slates): the app's service layer and the Dart binding over the
// real LEPIC library, the real node and the real relay. Wallets A, B and C live in data folders
// of their own. Skipped unless WFE_LEPIC_LIB (the Linux library built at the pins) and
// WFE_LIVE_DIR (a folder kept between steps) are set. WFE_LIVE_STEP picks one step:
//
//   setup      makes A, B and C and prints their Epicbox addresses
//   fund       drains A's payments mailbox until it has WFE_FUND_TARGET atoms spendable
//              (after qa-funder/fund.sh; the miner must run for the confirmations)
//   off        native slates off, as shipped: settings, Epicbox, Tor, pairing and mailbox
//   on         native slates on for A and B (C stays off): contacts, mailbox, Tor, pins, mixed
//   inperson   in-person codes (TTL rule, both round trips) and epictxOpen on their answers
//   epic1      epic1 links: make, read, pay, answer, retire
//   downgrade  B turns native off again while A holds its pin
//
// WFE_TOR_BIN names the tor binary (its folder is the library path). Nothing prints a phrase or
// a password. Lines starting with "LIVE" are the results; "LIVE FAIL" marks a check that did
// not hold, and the step ends with the first failed expectation.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart' show appConfig;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

final _env = Platform.environment;
final String? _lib = _env['WFE_LEPIC_LIB'];
final String? _dir = _env['WFE_LIVE_DIR'];
final String _step = _env['WFE_LIVE_STEP'] ?? '';
final String _torBin = _env['WFE_TOR_BIN'] ?? '${_env['HOME']}/.cache/wfe-linux-build/work/tor-bundle/tor';

const _node = 'https://floo-node.btlabs.uk';
const _relay = 'epicbox.btlabs.uk';
const _password = 'live-epictx-2611';
final _pay = BigInt.from(2000000);

/// Prints a result line and appends it to `live-STEP.log` in the live folder, which can be read
/// while the run is going (tools/t shows the test output only at the end).
void _say(String line) {
  final text = 'LIVE ${DateTime.now().toUtc().toIso8601String().substring(11, 19)} $line';
  // ignore: avoid_print
  print(text);
  File('$_dir/live-$_step.log').writeAsStringSync('$text\n', mode: FileMode.append);
}

/// A check: says PASS or FAIL with [what] and the [detail], then fails the step on a miss.
void _check(String what, bool ok, [String detail = '']) {
  _say('${ok ? 'PASS' : 'FAIL'} $what${detail.isEmpty ? '' : ' | $detail'}');
  expect(ok, isTrue, reason: what);
}

/// Secrets in a JSON file next to the wallet, so a later step opens it again.
class _FileStore implements lepic.SecretStore {
  _FileStore(this.file);

  final File file;

  Map<String, String> _all() => file.existsSync() ? Map<String, String>.from(jsonDecode(file.readAsStringSync()) as Map) : {};

  void _put(Map<String, String> all) {
    file.writeAsStringSync(jsonEncode(all));
    Process.runSync('chmod', ['600', file.path]);
  }

  @override
  Future<String?> read(String key) async => _all()[key];

  @override
  Future<void> write(String key, String value) async => _put(_all()..[key] = value);

  @override
  Future<void> delete(String key) async => _put(_all()..remove(key));
}

late lepic.LepicRuntime _runtime;

lepic.WalletConfig _config(String name) => lepic.WalletConfig(policy: LepicWalletService.hostPolicyOf(appConfig), torWanted: false, hostFeatures: 0, profile: 0,
  dataDir: (Directory('$_dir/$name')..createSync(recursive: true)).path,
  chain: lepic.Chain.floonet,
  nodeUrl: _node,
  epicboxDomain: _relay,
  epicboxPort: 443,
  onionRoutes: const [], tuning: LepicWalletService.netTuningOf(appConfig), offline: false,
);

lepic.AppSecretStore _store(String name) => lepic.lepicSecretStore(_FileStore(File('$_dir/$name.secrets.json')));

typedef _W = (LepicWalletSession, lepic.EpicWallet);

/// The wallet [name], made on first use, as a session.
Future<_W> _wallet(String name) async {
  final exists = File('$_dir/$name.secrets.json').existsSync();
  final w = exists
      ? await lepic.EpicWallet.open(runtime: _runtime, config: _config(name), store: _store(name), password: _password)
      : await lepic.EpicWallet.create(runtime: _runtime, config: _config(name), store: _store(name), password: _password);
  return (LepicWalletSession(w), w);
}

/// [w] closed and opened again, as the app does to apply the native slates setting.
Future<_W> _reopen(String name, _W w) async {
  w.$1.dispose();
  await Future<void>.delayed(const Duration(seconds: 2));
  return _wallet(name);
}

/// One Epicbox drain and one contacts collect of each wallet.
Future<void> _pump(List<_W> ws) async {
  for (final (s, w) in ws) {
    try {
      await w.drainEpicbox();
    } on lepic.WalletError catch (e) {
      _say('drain: ${e.kind.name}');
    }
    try {
      await s.pairing.collect(trigger: PairingCollectTrigger.pull);
    } on WalletError catch (e) {
      _say('collect: ${e.kind.name}');
    }
  }
}

/// Pumps [ws] until [done], [tries] cycles 5 s apart.
Future<bool> _until(List<_W> ws, Future<bool> Function() done, {int tries = 48}) async {
  for (var i = 0; i < tries; i++) {
    await _pump(ws);
    if (await done()) return true;
    await Future<void>.delayed(const Duration(seconds: 5));
  }
  return false;
}

Future<TxEntry?> _tx(LepicWalletSession s, String slateId) async =>
    (await s.transactions(refresh: false)).where((t) => t.slateId == slateId).firstOrNull;

/// A's transaction for [slateId] reached the chain (posted) on its side.
Future<bool> _posted(LepicWalletSession s, String slateId) async {
  final t = await _tx(s, slateId);
  return t != null && (t.status == TxStatus.awaitingConfirmation || t.status == TxStatus.confirmed);
}

/// The tor of one wallet and what its stream said.
class _Tor {
  _Tor(this.w);

  final lepic.EpicWallet w;
  final events = <lepic.TorEvent>[];
  StreamSubscription<lepic.TorEvent>? _sub;
  String? onion;

  Future<void> start({required bool publish}) async {
    // Epicbox and the node stay direct: the test is about the onion path.
    w.setEpicboxOverTor(enabled: false);
    w.setNodeOverTor(enabled: false);
    _sub = w.startTor(torBinary: _torBin, libDir: File(_torBin).parent.path, publishOnion: publish).listen((e) {
      events.add(e);
      if (e.onion != null) onion = e.onion;
    });
    final goal = publish ? lepic.TorEventKind.ready : lepic.TorEventKind.bootstrapped;
    final end = DateTime.now().add(const Duration(minutes: 8));
    while (!events.any((e) => e.kind == goal)) {
      final failed = events.where((e) => e.kind == lepic.TorEventKind.failed).firstOrNull;
      if (failed != null) fail('tor failed: ${failed.failure}');
      if (DateTime.now().isAfter(end)) fail('tor did not reach $goal: ${events.map((e) => e.kind.name).join(',')}');
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> stop() async {
    w.stopTor();
    await _sub?.asFuture<void>().timeout(const Duration(seconds: 45), onTimeout: () {});
  }
}


/// Change outputs of the sends before need their confirmations: waits until [w] has coins to
/// spend (twice the test amount), up to three minutes.
Future<void> _funds(lepic.EpicWallet w) async {
  for (var i = 0; i < 12; i++) {
    final summary = await w.summary(refresh: true);
    if (summary.spendable > _pay * BigInt.from(2)) return;
    _say('waiting for spendable coins: ${summary.spendable} spendable, ${summary.awaitingConfirmation} awaiting, height ${summary.lastConfirmedHeight}');
    await Future<void>.delayed(const Duration(seconds: 15));
  }
}

typedef _Sent = ({String slateId, lepic.SendDialect dialect, lepic.SlateWire? format, bool posted, bool retried});

/// A send to [onion] by the binding; one more try by resend when the onion was not reached yet
/// (a published onion is often reached at the second try).
Future<_Sent> _torSend(lepic.EpicWallet w, String onion, {bool? legacy, BigInt? amount, BigInt? minConf}) async {
  final conf = minConf ?? BigInt.from(10);
  final value = amount ?? _pay;
  await _funds(w);
  try {
    final t = legacy == null
        ? await w.sendTor(amount: value, minimumConfirmations: conf, onion: onion, message: 'epictx live')
        : await w.sendTorDialect(amount: value, minimumConfirmations: conf, onion: onion, message: 'epictx live', legacy: legacy);
    return (slateId: t.slateId, dialect: t.dialect, format: t.format, posted: t.posted, retried: false);
  } on lepic.WalletError catch (e) {
    _say('tor send error: kind ${e.kind.name} code ${e.code} tx ${e.txId} message ${e.message}');
    if (e.kind != lepic.WalletErrorKind.onionUnreachable || e.txId == null) rethrow;
    _say('onion not reached yet (tx ${e.txId}); one more try in 20 s');
    await Future<void>.delayed(const Duration(seconds: 20));
    final r = legacy == null
        ? await w.resendTor(txId: e.txId!, onion: onion)
        : await w.resendTorDialect(txId: e.txId!, onion: onion, legacy: legacy);
    return (slateId: r.slateId, dialect: r.dialect, format: null, posted: r.posted, retried: true);
  }
}

/// A and B paired by a standing invite; returns A's pairing id (the contact id on A) and B's.
Future<({String a, String b})> _pair(_W a, _W b) async {
  final invite = await a.$1.pairing.standingCode(name: 'Alex');
  final preview = await b.$1.pairing.openInvite(invite.inviteLink!);
  final answer = await b.$1.pairing.acceptInvite(token: preview.token, name: 'Bob');
  final ok = await _until([a, b], () async {
    final x = await a.$1.pairing.pairing(invite.id);
    final y = await b.$1.pairing.pairing(answer.id);
    return (x?.state.isPaired ?? false) && (y?.state.isPaired ?? false);
  });
  _check('paired A<->B', ok, 'A ${invite.id.substring(0, 8)} B ${answer.id.substring(0, 8)}');
  return (a: invite.id, b: answer.id);
}

Future<lepic.ContactView> _contact(lepic.EpicWallet w, String id) async => (await w.contacts()).firstWhere((c) => c.contactId == id);

String _short(String s) => s.length <= 12 ? s : '${s.substring(0, 12)}…';

Future<String> _summaryLine(String name, lepic.EpicWallet w) async {
  final s = await w.summary(refresh: true);
  return '$name total ${s.total} spendable ${s.spendable} awaiting ${s.awaitingConfirmation} height ${s.lastConfirmedHeight} minConf ${s.minimumConfirmations}';
}

void main() {
  final skip = _lib == null || _dir == null ? 'needs WFE_LEPIC_LIB and WFE_LIVE_DIR' : null;

  setUpAll(() async {
    if (skip != null) return;
    await initLepic(libraryPath: _lib);
    _runtime = lepic.LepicRuntime(logLevel: lepic.LogLevel.info);
  });

  test('epictx live step: $_step', timeout: const Timeout(Duration(minutes: 45)), skip: skip, () async {
    switch (_step) {
      case 'setup':
        for (final name in ['A', 'B', 'C']) {
          final (s, w) = await _wallet(name);
          _say('$name address ${await w.epicboxAddress()}');
          _say('$name nativeDirect ${w.nativeDirect()} inUse ${w.nativeDirectInUse()}');
          s.dispose();
        }

      case 'fund':
        final target = BigInt.parse(_env['WFE_FUND_TARGET'] ?? '1400000000');
        final (a, aw) = await _wallet('A');
        var ok = false;
        for (var i = 0; i < 200 && !ok; i++) {
          final report = await aw.drainEpicbox();
          final summary = await aw.summary(refresh: true);
          _say('A drained: received ${report.received} finalized ${report.finalized} held ${report.held}; total ${summary.total} spendable ${summary.spendable} awaiting ${summary.awaitingConfirmation} height ${summary.lastConfirmedHeight} minConf ${summary.minimumConfirmations}');
          ok = summary.spendable >= target;
          if (!ok) await Future<void>.delayed(const Duration(seconds: 10));
        }
        _check('A has $target spendable', ok);
        a.dispose();

      case 'off':
        final a = await _wallet('A');
        final b = await _wallet('B');
        final (sa, aw) = a;
        final (bs, bw) = b;
        _say(await _summaryLine('A', aw));
        final conf = (await aw.summary(refresh: false)).minimumConfirmations;
        _check('A and B: nativeDirect and nativeDirectInUse are false', !aw.nativeDirect() && !aw.nativeDirectInUse() && !bw.nativeDirect() && !bw.nativeDirectInUse(),
            'A ${aw.nativeDirect()}/${aw.nativeDirectInUse()} B ${bw.nativeDirect()}/${bw.nativeDirectInUse()}');

        // Epicbox by address.
        final bAddr = await bw.epicboxAddress();
        await _funds(aw);
        final e = await aw.sendEpicbox(amount: _pay, minimumConfirmations: conf, address: bAddr, message: 'epictx off epicbox');
        _say('A sendEpicbox ${_short(e.slateId)} format ${e.format.name}');
        _check('Epicbox send A->B format is legacy', e.format == lepic.SlateWire.legacy, e.format.name);
        final got = await _until([a, b], () async => await _tx(bs, e.slateId) != null && await _posted(sa, e.slateId));
        _check('Epicbox send: B has it, A finalized and posted', got, 'B ${(await _tx(bs, e.slateId))?.status.name} A ${(await _tx(sa, e.slateId))?.status.name}');

        // Tor: B publishes its onion, A only sends.
        final torB = _Tor(bw);
        final torA = _Tor(aw);
        await torB.start(publish: true);
        await torA.start(publish: false);
        _say('B onion ${_short(torB.onion!)} ready; A tor bootstrapped; native pins on A ${aw.peerPins().length}');
        final t = await _torSend(aw, torB.onion!, minConf: conf);
        _say('A sendTor ${_short(t.slateId)} dialect ${t.dialect.name} format ${t.format?.name} posted ${t.posted} retried ${t.retried}');
        _check('Tor send A->B dialect legacy', t.dialect == lepic.SendDialect.legacy, 'dialect ${t.dialect.name}');
        if (t.format != null) _check('Tor send A->B format legacy', t.format == lepic.SlateWire.legacy, t.format!.name);
        _check('Tor send A->B posted and B has it', t.posted && await _tx(bs, t.slateId) != null, 'B ${(await _tx(bs, t.slateId))?.status.name}');

        // The app's own Tor path (LepicWalletSession.sendTor, with its one retry).
        await _funds(aw);
        final h = await sa.sendTor(amount: _pay, minimumConfirmations: conf, onion: torB.onion!, message: 'epictx off session');
        final hRow = await _tx(sa, h.slateId);
        _say('A session.sendTor ${_short(h.slateId)} posted ${h.posted} status ${hRow?.status.name} transport ${hRow?.transport}');
        _check('session.sendTor A->B posted', h.posted);
        _check('off: peerPins empty after Tor sends', aw.peerPins().isEmpty, 'pins ${aw.peerPins().length}');

        // Pairing and a payment through B's mailbox.
        final ids = await _pair(a, b);
        await _funds(aw);
        final m = await aw.contactSend(contactId: ids.a, amount: _pay, minimumConfirmations: conf, message: 'epictx off mailbox', purpose: lepic.SlatePurpose.payment, relayMode: lepic.ContactRelayMode.online);
        _say('A contactSend ${_short(m.slateId)} format ${m.format.name}');
        _check('mailbox send format legacy', m.format == lepic.SlateWire.legacy, m.format.name);
        final done = await _until([a, b], () async => await _tx(bs, m.slateId) != null && await _posted(sa, m.slateId));
        _check('mailbox payment: B has it, A finalized and posted', done, 'B ${(await _tx(bs, m.slateId))?.status.name} A ${(await _tx(sa, m.slateId))?.status.name}');
        final cv = await _contact(aw, ids.a);
        _check('ContactView.nativeSlates false', !cv.nativeSlates);
        final compat = await aw.peerCompat(address: bAddr);
        _say('A peerCompat of B: lepic ${compat.lepic} claimed ${compat.claimed} nativeSlates ${compat.nativeSlates}');
        _check('PeerCompat.nativeSlates false', !compat.nativeSlates);
        _check('peerPins empty', aw.peerPins().isEmpty, 'pins ${aw.peerPins().length}');
        File('$_dir/off.pairing').writeAsStringSync('${ids.a} ${ids.b}');
        await torA.stop();
        await torB.stop();
        sa.dispose();
        bs.dispose();

      case 'on':
        var a = await _wallet('A');
        var b = await _wallet('B');
        var c = await _wallet('C');
        final wasOn = a.$2.nativeDirect();
        a.$2.setNativeDirect(enabled: true);
        b.$2.setNativeDirect(enabled: true);
        _say('after set, before reopen: A nativeDirect ${a.$2.nativeDirect()} inUse ${a.$2.nativeDirectInUse()}');
        if (!wasOn) _check('setNativeDirect takes effect at the next open', a.$2.nativeDirect() && !a.$2.nativeDirectInUse());
        a = await _reopen('A', a);
        b = await _reopen('B', b);
        c = await _reopen('C', c);
        final (sa, aw) = a;
        final (bs, bw) = b;
        final cw = c.$2;
        _check('nativeDirectInUse true on A and B, false on C', aw.nativeDirectInUse() && bw.nativeDirectInUse() && !cw.nativeDirectInUse(),
            'A ${aw.nativeDirectInUse()} B ${bw.nativeDirectInUse()} C ${cw.nativeDirectInUse()}');
        _say(await _summaryLine('A', aw));
        final conf = (await aw.summary(refresh: false)).minimumConfirmations;
        final bAddr = await bw.epicboxAddress();

        final ids = await _pair(a, b);
        var cv = await _contact(aw, ids.a);
        var compat = await aw.peerCompat(address: bAddr);
        _say('after pairing: A ContactView.nativeSlates ${cv.nativeSlates}; PeerCompat lepic ${compat.lepic} nativeSlates ${compat.nativeSlates}');
        var first = '';
        if (!cv.nativeSlates) {
          // The claim travels on a marked slate: one payment B answers carries it.
          await _funds(aw);
          final m0 = await aw.contactSend(contactId: ids.a, amount: _pay, minimumConfirmations: conf, message: 'epictx on claim', purpose: lepic.SlatePurpose.payment, relayMode: lepic.ContactRelayMode.online);
          first = m0.slateId;
          _say('A contactSend before the claim: ${_short(m0.slateId)} format ${m0.format.name}');
          final ok0 = await _until([a, b], () async => await _posted(sa, m0.slateId));
          _check('first mailbox payment completes', ok0);
          cv = await _contact(aw, ids.a);
          compat = await aw.peerCompat(address: bAddr);
          _say('after first payment: ContactView.nativeSlates ${cv.nativeSlates}; PeerCompat nativeSlates ${compat.nativeSlates}');
        }
        _check('A: contact for B shows nativeSlates true', cv.nativeSlates);
        _say('INFO PeerCompat.nativeSlates right after pairing: ${compat.nativeSlates} (the claim of the peer\'s latest marked slate by address; read again after the first payment)');
        final bContact = await _contact(bw, ids.b);
        _say('B: contact for A nativeSlates ${bContact.nativeSlates}');

        await _funds(aw);
        final m = await aw.contactSend(contactId: ids.a, amount: _pay, minimumConfirmations: conf, message: 'epictx on mailbox', purpose: lepic.SlatePurpose.payment, relayMode: lepic.ContactRelayMode.online);
        _say('A contactSend ${_short(m.slateId)} format ${m.format.name}');
        _check('mailbox send A->B format native', m.format == lepic.SlateWire.native, m.format.name);
        final done = await _until([a, b], () async => await _tx(bs, m.slateId) != null && await _posted(sa, m.slateId));
        _check('native mailbox payment: B has it, A finalized and posted', done, 'B ${(await _tx(bs, m.slateId))?.status.name} A ${(await _tx(sa, m.slateId))?.status.name}');
        if (first.isNotEmpty) File('$_dir/on.first').writeAsStringSync(first);
        // Pairing messages come from a key of the pairing, so peerCompat of B's own address
        // learns only from slates exchanged with that address: send one by address, then read.
        compat = await aw.peerCompat(address: bAddr);
        _say('after the native mailbox payment: PeerCompat(B address) lepic ${compat.lepic} nativeSlates ${compat.nativeSlates} (pairing traffic uses another key)');
        await _funds(aw);
        final e1 = await aw.sendEpicbox(amount: _pay, minimumConfirmations: conf, address: bAddr, message: 'epictx on epicbox 1');
        _say('A sendEpicbox 1 ${_short(e1.slateId)} format ${e1.format.name}');
        final e1ok = await _until([a, b], () async => await _tx(bs, e1.slateId) != null && await _posted(sa, e1.slateId));
        _check('Epicbox send by address completes with B native on', e1ok);
        compat = await aw.peerCompat(address: bAddr);
        _say('after the Epicbox exchange: PeerCompat(B address) lepic ${compat.lepic} claimed ${compat.claimed} nativeSlates ${compat.nativeSlates}');
        _check('A: PeerCompat(B address).nativeSlates true after B answered marked', compat.nativeSlates);
        await _funds(aw);
        final e2 = await aw.sendEpicbox(amount: _pay, minimumConfirmations: conf, address: bAddr, message: 'epictx on epicbox 2');
        _say('A sendEpicbox 2 ${_short(e2.slateId)} format ${e2.format.name}');
        _check('Epicbox send by address to a native peer is native', e2.format == lepic.SlateWire.native, e2.format.name);
        final e2ok = await _until([a, b], () async => await _tx(bs, e2.slateId) != null && await _posted(sa, e2.slateId));
        _check('native Epicbox send completes', e2ok);

        // Tor: B and C publish an onion, A sends.
        final torA = _Tor(aw);
        final torB = _Tor(bw);
        final torC = _Tor(cw);
        await torB.start(publish: true);
        await torC.start(publish: true);
        await torA.start(publish: false);
        _say('B onion ${_short(torB.onion!)}, C onion ${_short(torC.onion!)}; pins on A before ${aw.peerPins().length}');
        final t = await _torSend(aw, torB.onion!, minConf: conf);
        _say('A sendTor B ${_short(t.slateId)} dialect ${t.dialect.name} format ${t.format?.name} posted ${t.posted} retried ${t.retried}');
        _check('Tor send A->B dialect native', t.dialect == lepic.SendDialect.native, t.dialect.name);
        if (t.format != null) _check('Tor send A->B format native', t.format == lepic.SlateWire.native, t.format!.name);
        _check('Tor send A->B posted, B has it', t.posted && await _tx(bs, t.slateId) != null);
        final pins = aw.peerPins();
        for (final p in pins) {
          _say('pin origin ${_short(p.origin)} key ${_short(p.sealKey)} first ${p.firstSeenMs} last ${p.lastSeenMs}');
        }
        final bHost = torB.onion!.replaceAll('.onion', '');
        final pin = pins.where((p) => p.origin.contains(bHost)).firstOrNull;
        _check('peerPins lists B origin', pin != null, 'pins ${pins.length}');
        final forgot = aw.forgetPeerPin(origin: pin!.origin);
        _check('forgetPeerPin removed it', forgot && aw.peerPins().where((p) => p.origin == pin.origin).isEmpty, 'forgot $forgot left ${aw.peerPins().length}');
        _check('forgetPeerPin again returns false', !aw.forgetPeerPin(origin: pin.origin));

        // A native send after the pin was forgotten pins again.
        final t2 = await _torSend(aw, torB.onion!, minConf: conf);
        _say('A sendTor B again ${_short(t2.slateId)} dialect ${t2.dialect.name} format ${t2.format?.name} pins ${aw.peerPins().length}');
        _check('Tor send after forget: native and pinned again', t2.dialect == lepic.SendDialect.native && aw.peerPins().any((p) => p.origin == pin.origin));

        // legacy: true sends the old dialect whatever B advertises, reads and keeps no pin.
        final pinsBefore = aw.peerPins().length;
        final t3 = await _torSend(aw, torB.onion!, legacy: true, minConf: conf);
        _say('A sendTorDialect(legacy) B ${_short(t3.slateId)} dialect ${t3.dialect.name} format ${t3.format?.name} pins ${aw.peerPins().length}');
        _check('Tor send legacy:true to a native wallet is legacy, pins unchanged', t3.dialect == lepic.SendDialect.legacy && aw.peerPins().length == pinsBefore);

        // Mixed: A on, C off.
        final t4 = await _torSend(aw, torC.onion!, minConf: conf);
        _say('A sendTor C ${_short(t4.slateId)} dialect ${t4.dialect.name} format ${t4.format?.name} posted ${t4.posted} retried ${t4.retried}');
        _check('Tor send A(on)->C(off) falls back to legacy and completes', t4.dialect == lepic.SendDialect.legacy && t4.posted, '${t4.dialect.name} posted ${t4.posted}');
        _check('no pin for C', !aw.peerPins().any((p) => p.origin.contains(torC.onion!.replaceAll('.onion', ''))));
        final cs = c.$1;
        _check('C has the payment', await _tx(cs, t4.slateId) != null);

        // The app's Tor path to the native wallet.
        await _funds(aw);
        final h = await sa.sendTor(amount: _pay, minimumConfirmations: conf, onion: torB.onion!, message: 'epictx on session');
        _say('A session.sendTor B ${_short(h.slateId)} posted ${h.posted}');
        _check('session.sendTor A->B posted', h.posted);

        File('$_dir/on.pairing').writeAsStringSync('${ids.a} ${ids.b}');
        File('$_dir/on.onion').writeAsStringSync(torB.onion!);
        await torA.stop();
        await torB.stop();
        await torC.stop();
        sa.dispose();
        bs.dispose();
        cs.dispose();

      case 'downgrade':
        var a = await _wallet('A');
        var b = await _wallet('B');
        _check('A still native, B native', a.$2.nativeDirectInUse() && b.$2.nativeDirectInUse());
        final conf = (await a.$2.summary(refresh: false)).minimumConfirmations;
        b.$2.setNativeDirect(enabled: false);
        b = await _reopen('B', b);
        _check('B off after reopen', !b.$2.nativeDirectInUse() && !b.$2.nativeDirect());
        final torB = _Tor(b.$2);
        final torA = _Tor(a.$2);
        await torB.start(publish: true);
        await torA.start(publish: false);
        // A pinned B in the "on" step: the pin outlives it only if the file kept it.
        _say('A pins ${a.$2.peerPins().map((p) => _short(p.origin)).join(',')}');
        try {
          final t = await _torSend(a.$2, torB.onion!, minConf: conf);
          _say('A sendTor to downgraded B: ${t.dialect.name} posted ${t.posted}');
          _say('FINDING a pinned origin that stopped advertising was sent legacy without a refusal');
        } on lepic.WalletError catch (e) {
          final mapped = mapLepicError(e);
          _say('A sendTor to downgraded B refused: ${e.kind.name} origin ${e.origin == null ? null : _short(e.origin!)} tx ${e.txId}; mapLepicError ${mapped.kind.name}');
          _check('refusal names the origin', e.kind == lepic.WalletErrorKind.pinnedNoAdvert && e.origin != null);
          if (e.txId != null) await a.$2.cancelTransaction(txId: e.txId!);
          _check('forgetPeerPin for the shown origin', a.$2.forgetPeerPin(origin: e.origin!));
          final t = await _torSend(a.$2, torB.onion!, minConf: conf);
          _say('after forget: ${t.dialect.name} posted ${t.posted}');
          _check('after forget the send goes legacy', t.dialect == lepic.SendDialect.legacy && t.posted);
        }
        await torA.stop();
        await torB.stop();
        a.$1.dispose();
        b.$1.dispose();

      case 'inperson':
        final a = await _wallet('A');
        final b = await _wallet('B');
        final (sa, aw) = a;
        final (bs, bw) = b;
        final conf = (await aw.summary(refresh: false)).minimumConfirmations;
        _say(await _summaryLine('A', aw));
        final events = <lepic.WalletEventKind>[];
        final sub = aw.events().listen((e) => events.add(e.kind));
        final tip = (await aw.summary(refresh: true)).lastConfirmedHeight;

        // The TTL rule: the app chooses; 10 or fewer is refused.
        try {
          await bw.inPersonInvoice(amount: _pay, ttlBlocks: BigInt.from(10), relayMode: lepic.ContactRelayMode.online);
          _check('TTL 10 refused', false, 'no error');
        } on lepic.WalletError catch (e) {
          final mapped = mapLepicError(e);
          _say('inPersonInvoice ttl 10: ${e.kind.name}; mapLepicError ${mapped.kind.name}');
          _check('TTL 10 -> lepic invalidArgument, app invalidArgument', e.kind == lepic.WalletErrorKind.invalidArgument && mapped.kind == WalletErrorKind.invalidArgument);
        }
        final ttl30 = await bw.inPersonInvoice(amount: _pay, message: 'epictx in person', ttlBlocks: BigInt.from(30), relayMode: lepic.ContactRelayMode.online);
        _say('inPersonInvoice ttl 30: slate ${_short(ttl30.slateId)} bytes ${ttl30.bytes.length} cutoff ${ttl30.ttlCutoff} (tip then $tip) mailbox ${ttl30.mailbox}');
        _check('TTL 30 made; cutoff about tip+30', ttl30.ttlCutoff >= tip + BigInt.from(30) && ttl30.ttlCutoff <= tip + BigInt.from(40), 'cutoff ${ttl30.ttlCutoff} tip $tip');

        // Invoice round trip, answer carried back by hand: read -> pay -> take -> finalize.
        final read = await aw.inPersonRead(code: ttl30.bytes, minimumConfirmations: conf, relayMode: lepic.ContactRelayMode.online);
        _say('A inPersonRead: stage ${read.stage.name} amount ${read.amount} fee ${read.fee} message "${read.message}" cutoff ${read.ttlCutoff} mailbox ${read.mailbox?.host}:${read.mailbox?.port} inRelayList ${read.mailbox?.inRelayList}');
        _check('read shows the invoice amount', read.amount == _pay);
        await _funds(aw);
        final reply = await aw.inPersonPay(code: ttl30.bytes, amount: read.amount, minimumConfirmations: conf, message: 'epictx paid', relayMode: lepic.ContactRelayMode.online);
        _say('A inPersonPay: tx ${reply.txId} check code ${reply.checkCode} armored ${reply.armored.substring(0, 14)}… ${reply.armored.length} chars envelope ${reply.envelope.length} bytes');
        final view = await bw.epictxOpen(text: reply.armored);
        _say('B epictxOpen(answer): native ${view.native} contactId ${view.contactId} purpose ${view.purpose?.name} reference ${view.reference} expires ${view.expires} json ${view.slateJson.length} chars');
        _check('epictxOpen on the in-person answer opens it as native', view.native && view.slateJson.isNotEmpty);
        final taken = await bw.inPersonTake(answer: reply.envelope);
        _say('B inPersonTake: stage ${taken.stage.name} answer ${taken.answer} check ${taken.checkCode} duplicate ${taken.duplicate} sameCode ${taken.sameCode}');
        _check('check codes agree', taken.checkCode == reply.checkCode && !taken.duplicate);
        final again = await bw.inPersonTake(answer: utf8.encode(reply.armored));
        _check('same answer as text is a duplicate', again.duplicate, 'duplicate ${again.duplicate}');
        final cv = await bw.inPersonAnswers(slateId: ttl30.slateId);
        _say('B inPersonAnswers: ${cv.answers.length} answer(s), closed ${cv.closed}, finalized ${cv.finalized}');
        // Taking an answer closes the code: no more answers are taken (in_person.rs take, state.closed).
        _check('one answer taken, code closed to more, not finalized yet', cv.answers.length == 1 && cv.closed && cv.finalized == null);
        final fin = await bw.inPersonFinalize(slateId: ttl30.slateId, answer: taken.answer);
        _say('B inPersonFinalize: tx ${fin.txId} posted ${fin.posted}');
        _check('invoice finalized and posted', fin.posted);
        final after = await bw.inPersonAnswers(slateId: ttl30.slateId);
        _check('code closed after finalizing', after.closed && after.finalized == taken.answer, 'closed ${after.closed} finalized ${after.finalized}');

        // Send round trip, answer posted to the code's mailbox and collected.
        await _funds(aw);
        final send = await aw.inPersonSend(amount: _pay, minimumConfirmations: conf, message: 'epictx in person send', relayMode: lepic.ContactRelayMode.online);
        _say('A inPersonSend: slate ${_short(send.slateId)} cutoff ${send.ttlCutoff} mailbox ${send.mailbox}');
        final sRead = await bw.inPersonRead(code: send.bytes, minimumConfirmations: conf, relayMode: lepic.ContactRelayMode.online);
        _say('B inPersonRead: stage ${sRead.stage.name} amount ${sRead.amount} mailbox ${sRead.mailbox?.host}');
        final sReply = await bw.inPersonReceive(code: send.bytes, message: 'epictx got it', relayMode: lepic.ContactRelayMode.online);
        _say('B inPersonReceive: tx ${sReply.txId} check ${sReply.checkCode}');
        await bw.inPersonPost(slateId: send.slateId, relayOk: true, relayMode: lepic.ContactRelayMode.online);
        _say('B inPersonPost done');
        final collected = await _until([a], () async => (await aw.inPersonAnswers(slateId: send.slateId)).answers.isNotEmpty);
        _check('A collected the answer from the mailbox', collected);
        final sView = await aw.inPersonAnswers(slateId: send.slateId);
        final inPersonEvents = events.where((k) => k == lepic.WalletEventKind.inPersonAnswer).length;
        _say('A inPersonAnswers: ${sView.answers.length} answer(s) check ${sView.answers.first.checkCode}; InPersonAnswer events seen $inPersonEvents');
        _check('check codes agree (send)', sView.answers.first.checkCode == sReply.checkCode);
        _check('InPersonAnswer event raised', inPersonEvents >= 1, 'events $inPersonEvents');
        final sFin = await aw.inPersonFinalize(slateId: send.slateId, answer: sView.answers.first.number);
        _say('A inPersonFinalize: tx ${sFin.txId} posted ${sFin.posted}');
        _check('send finalized and posted', sFin.posted);

        // epictxOpen on texts that are not an answer.
        try {
          await bw.epictxOpen(text: 'BEGINEPICTX. not a slate. ENDEPICTX.');
          _check('epictxOpen of junk refused', false, 'no error');
        } on lepic.WalletError catch (e) {
          _say('epictxOpen(junk): ${e.kind.name}; mapLepicError ${mapLepicError(e).kind.name}');
        }
        unawaited(sub.cancel());
        sa.dispose();
        bs.dispose();
        _say('inperson step finished');

      case 'epic1':
        final a = await _wallet('A');
        final b = await _wallet('B');
        final (sa, aw) = a;
        final (bs, bw) = b;
        final conf = (await aw.summary(refresh: false)).minimumConfirmations;
        _say(await _summaryLine('A', aw));
        _say('B epic1Address ${_short(await bw.epic1Address())}');
        for (final (kind, proof, asked) in [
          (lepic.Epic1LinkKind.printed, false, true),
          (lepic.Epic1LinkKind.onScreen, true, false),
        ]) {
          final tag = '${kind.name}${proof ? '+proof' : ''}';
          final link = await bw.epic1LinkMake(amount: asked ? _pay : null, message: 'epictx $tag', kind: kind, relays: const [], relayMode: lepic.ContactRelayMode.online);
          _say('B epic1LinkMake $tag: n ${link.n} address ${_short(link.address)} link ${_short(link.link)} (${link.link.length} chars)');
          final links = await bw.epic1Links();
          _say('B epic1Links: ${links.map((l) => '${l.kind.name}#${l.n}').join(',')}');
          _check('link in use', links.any((l) => l.kind == kind && l.n == link.n));
          final read = await aw.epic1LinkRead(link: link.link, relayMode: lepic.ContactRelayMode.online);
          _say('A epic1LinkRead $tag: address ${_short(read.address)} amount ${read.amount} message "${read.message}" hosts ${read.hosts.map((h) => '${h.host}:${h.port}/${h.class_.name}').join(',')}');
          _check('read shows what the link asks', read.address == link.address && (asked ? read.amount == _pay : read.amount == null));
          try {
            await _funds(aw);
            await aw.epic1Pay(link: link.link, amount: asked ? null : _pay, minimumConfirmations: conf, proof: proof, hostsOk: false, relayMode: lepic.ContactRelayMode.online);
            _check('epic1Pay without hostsOk refused', false, 'no error');
          } on lepic.WalletError catch (e) {
            _check('epic1Pay hostsOk:false -> relayNotConfirmed', e.kind == lepic.WalletErrorKind.relayNotConfirmed, '${e.kind.name}; mapLepicError ${mapLepicError(e).kind.name}');
          }
          await _funds(aw);
          final paid = await aw.epic1Pay(link: link.link, amount: asked ? null : _pay, minimumConfirmations: conf, message: 'epictx pay $tag', proof: proof, hostsOk: true, relayMode: lepic.ContactRelayMode.online);
          _say('A epic1Pay $tag: tx ${paid.txId} slate ${_short(paid.slateId)} attempts ${paid.attempts.length} posted transport ${paid.posted}');
          _check('payment posted to a relay', paid.posted != null);
          // B takes it at the link mailbox, answers; A collects the answer and finalizes.
          final taken = await _until([b], () async => (await bw.epic1Answers(relayMode: lepic.ContactRelayMode.online)).any((x) => x.slateId == paid.slateId));
          final answers = await bw.epic1Answers(relayMode: lepic.ContactRelayMode.online);
          final mine = answers.where((x) => x.slateId == paid.slateId).firstOrNull;
          _say('B epic1Answers: ${answers.length}; for this payment ${mine != null} posted ${mine?.posted} mailbox ${mine?.mailbox}');
          _check('B took the payment', taken && mine != null);
          if (!(mine?.posted ?? false)) {
            await bw.epic1PostAnswer(slateId: paid.slateId, relayOk: true, relayMode: lepic.ContactRelayMode.online);
            _say('B epic1PostAnswer done');
          }
          final fin = await _until([a, b], () async => await _posted(sa, paid.slateId));
          _check('A finalized and posted (answer collected)', fin, 'A ${(await _tx(sa, paid.slateId))?.status.name} B ${(await _tx(bs, paid.slateId))?.status.name}');
          if (kind == lepic.Epic1LinkKind.printed) {
            await bw.epic1LinkRetire(n: link.n);
            final left = await bw.epic1Links();
            _check('epic1LinkRetire freed the printed link', !left.any((l) => l.kind == kind && l.n == link.n), 'left ${left.map((l) => '${l.kind.name}#${l.n}').join(',')}');
            try {
              await bw.epic1LinkRetire(n: link.n);
              _check('retiring again refused', false, 'no error');
            } on lepic.WalletError catch (e) {
              _check('retiring again -> epic1NotFound', e.kind == lepic.WalletErrorKind.epic1NotFound, e.kind.name);
            }
          }
        }
        try {
          await aw.epic1LinkRead(link: 'not a link', relayMode: lepic.ContactRelayMode.online);
          _check('junk link refused', false, 'no error');
        } on lepic.WalletError catch (e) {
          _check('junk link -> notAnEpic1Link', e.kind == lepic.WalletErrorKind.notAnEpic1Link, '${e.kind.name}; mapLepicError ${mapLepicError(e).kind.name}');
        }
        sa.dispose();
        bs.dispose();

      case 'inspect':
        for (final name in ['A', 'B', 'C']) {
          final (s, w) = await _wallet(name);
          _say(await _summaryLine(name, w));
          _say('$name native ${w.nativeDirect()}/${w.nativeDirectInUse()} pins ${w.peerPins().length}');
          for (final t in await s.transactions(refresh: false)) {
            _say('$name tx ${_short(t.slateId ?? '')} ${t.kind.name} ${t.status.name} ${t.transport}');
          }
          s.dispose();
        }

      default:
        fail('WFE_LIVE_STEP: setup, fund, off, on, downgrade, inperson, epic1 or inspect');
    }
  });
}
