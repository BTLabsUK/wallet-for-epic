// SPDX-License-Identifier: Apache-2.0
// Live on floonet (linked devices, chain check, Connection servers): two installs of ONE wallet
// (A shows the link, B is restored from A's phrase), each a LepicWalletSession over the real
// LEPIC library, driven by a DeviceService on the real node and real relays, plus a receiver R
// of another phrase that answers A's payments. Skipped unless WFE_LEPIC_LIB (the Linux library
// built at the pins) and WFE_LIVE_DIR (a folder kept between steps) are set. WFE_LIVE_STEP picks
// one step; run them in this order:
//
//   setup     makes A, B (A's phrase) and R, scans each from block 0, prints the addresses
//   probe     which Epicbox servers take a floonet private pairing and a floonet payments box
//   fund      pays A from /opt/epic/qa-funder, A receives it; once mined B's refresh shows it as
//             "Received by another wallet"
//   link      A shows the link on WFE_LINK_SERVERS (two, comma separated), B reads it; both
//             reach the four pictures, both match, both hellos; then the second server's
//             pairing (pair2), and a notice that arrives over both servers
//   hold      A sends to R (R does not answer): B holds the coins (held outputs, estimate,
//             "Sent from A" row); A cancels: B releases, row Cancelled on A
//   post      A sends to R, R answers, A posts: B holds, hears posted, and once mined its own
//             refresh confirms one "Sent from A" row
//   chain     A pauses its channel and sends: B was not told; once mined its refresh shows
//             "Sent from another wallet"; A resumes and B still shows the spend once
//   words     two different MAINNET wallets X and Y pair by words on a Connection servers set
//             of their own (WFE_MEETING, default epicbox.epicnet.us); Y on another set does
//             not find them
//
// Floonet blocks need the miner (`pm2 start /opt/epic/floo-miner/ecosystem.config.cjs`) for fund,
// post and chain. Nothing prints a phrase or a password. Lines starting with "LIVE" are the
// results.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/devices/device_history.dart';
import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/devices/device_service.dart';
import 'package:epic_wallet/src/devices/device_store.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/log.dart';
import 'package:epic_wallet/src/secret_store_api.dart' as app;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

final _env = Platform.environment;
final String? _lib = _env['WFE_LEPIC_LIB'];
final String? _dir = _env['WFE_LIVE_DIR'];
final String _step = _env['WFE_LIVE_STEP'] ?? '';
final List<String> _linkServers = (_env['WFE_LINK_SERVERS'] ?? 'epicbox.stackwallet.com,epicbox.epicnet.us').split(',');
final List<String> _meeting = (_env['WFE_MEETING'] ?? 'epicbox.epicnet.us').split(',');

const _node = 'https://floo-node.btlabs.uk';
const _mainnetNode = 'https://node.btlabs.uk';
const _relay = 'flooepicbox.btlabs.uk';
const _password = 'live-device-link-2610';
final _oneConf = BigInt.one;
final _epic = BigInt.from(100000000);

// ignore: avoid_print
void _say(String line) => print('LIVE ${DateTime.now().toUtc().toIso8601String().substring(11, 19)} $line');

String _amount(BigInt v) => (v / _epic).toStringAsFixed(4);

String _short(String? s) => s == null ? '-' : (s.length <= 12 ? s : '${s.substring(0, 12)}…');

/// Secrets in a JSON file next to the wallet, so a later step opens it again.
class _FileStore implements lepic.SecretStore, app.SecretStore {
  _FileStore(this.file);

  final File file;

  Map<String, String> _all() => file.existsSync() ? Map<String, String>.from(jsonDecode(file.readAsStringSync()) as Map) : {};

  @override
  Future<String?> read(String key) async => _all()[key];

  @override
  Future<void> write(String key, String value) async {
    final all = _all()..[key] = value;
    file.writeAsStringSync(jsonEncode(all));
  }

  @override
  Future<void> delete(String key) async {
    final all = _all()..remove(key);
    file.writeAsStringSync(jsonEncode(all));
  }
}

late lepic.LepicRuntime _runtime;

class _EchoSink extends MemoryLogSink {
  @override
  void record(LogLevel level, String target, String message) {
    // ignore: avoid_print
    if (logPasses(level, target)) print('APP ${level.name} $target $message');
    super.record(level, target, message);
  }
}

lepic.WalletConfig _config(String name, {String relay = _relay, bool mainnet = false}) => lepic.WalletConfig(
  dataDir: (Directory('$_dir/$name')..createSync(recursive: true)).path,
  chain: mainnet ? lepic.Chain.mainnet : lepic.Chain.floonet,
  nodeUrl: mainnet ? _mainnetNode : _node,
  epicboxDomain: relay,
  epicboxPort: 443,
);

/// One install: the session, its LEPIC wallet and, for A and B, its linked devices.
class _Install {
  _Install(this.name, this.session, this.wallet);

  final String name;
  final LepicWalletSession session;
  final lepic.EpicWallet wallet;
  DeviceService? _service;

  /// The DeviceService the apps give this wallet, its book in a file of its own.
  DeviceService get service => _service ??= DeviceService(
    host: SessionDeviceHost(session, minimumConfirmations: _oneConf),
    store: DeviceStore(_FileStore(File('$_dir/$name.app.json')), chain: Chain.floonet, walletId: name),
    defaultName: name == 'A' ? 'Desktop' : 'Phone',
  );

  PairingApi get pairing => session.pairing;

  Future<void> sync() => service.sync(DeviceSyncTrigger.tick);

  Future<WalletSummary> refresh() async {
    WalletSummary? last;
    await for (final p in session.refresh(minimumConfirmations: _oneConf)) {
      last = p.summary ?? last;
    }
    return last ?? await session.summary(refresh: false, minimumConfirmations: _oneConf);
  }

  Future<List<TxEntry>> rows() => session.transactions(refresh: false);

  /// This wallet's history as the screens show it, the linked devices' payments merged in.
  Future<List<TxEntry>> shown() async => mergeDeviceHistory(await rows(), service.book);

  void dispose() {
    _service?.dispose();
    session.dispose();
  }
}

/// The wallet [name], made on first use (from [mnemonic] when given).
Future<_Install> _wallet(String name, {String? mnemonic, String relay = _relay, bool mainnet = false}) async {
  final store = lepic.lepicSecretStore(_FileStore(File('$_dir/$name.secrets.json')));
  final exists = File('$_dir/$name.secrets.json').existsSync();
  final config = _config(name, relay: relay, mainnet: mainnet);
  final w = exists
      ? await lepic.EpicWallet.open(runtime: _runtime, config: config, store: store, password: _password)
      : await lepic.EpicWallet.create(runtime: _runtime, config: config, store: store, mnemonic: mnemonic, password: _password);
  final s = LepicWalletSession(w)..nodeUrl = config.nodeUrl;
  return _Install(name, s, w);
}

/// Repeats [step] every [every] until [done] or [tries] times.
Future<bool> _until(Future<bool> Function() done, {Future<void> Function()? step, int tries = 40, Duration every = const Duration(seconds: 3)}) async {
  for (var i = 0; i < tries; i++) {
    if (step != null) await step();
    if (await done()) return true;
    await Future<void>.delayed(every);
  }
  return false;
}

String _row(TxEntry r) =>
    '${r.origin.name}/${r.kind.name}/${r.status.name} ${_amount(r.amountDebited - r.amountCredited)} EPIC'
    '${r.deviceName != null ? ' from "${r.deviceName}"' : ''}${r.deviceEnding != null ? ' ending ${r.deviceEnding!.name}' : ''}'
    ' confirmed ${r.confirmed} height ${r.blockHeight} slate ${_short(r.slateId)} kernel ${_short(r.kernelExcess)} spent ${r.spentCommits.map(_short).join(',')}';

String _hold(HeldPayment h) => '${h.state.name} slate ${_short(h.slateId)} ${_amount(h.amount)} EPIC coins ${h.commitments.map(_short).join(',')}';

/// A pays R [epic] EPIC over Epicbox; R does not answer yet.
Future<TxEntry> _send(_Install a, _Install r, int epic, String message) async {
  final to = await r.session.epicboxAddress();
  final tx = await a.session.sendEpicbox(amount: _epic * BigInt.from(epic), minimumConfirmations: _oneConf, address: to, message: message);
  _say('${a.name} sent ${_amount(_epic * BigInt.from(epic))} EPIC to R: tx ${tx.id} slate ${tx.slateId}');
  return tx;
}

/// R answers what waits for it, then A finalizes and posts; true once A's send reads posted.
Future<bool> _answerAndPost(_Install a, _Install r, String slateId) async {
  final rr = await r.wallet.drainEpicbox();
  _say('R drained: received ${rr.received} held ${rr.held} rejected ${rr.rejected}');
  return _until(() async {
    final mine = (await a.rows()).where((t) => t.slateId == slateId).firstOrNull;
    return mine != null && (mine.status == TxStatus.awaitingConfirmation || mine.confirmed);
  }, step: () async {
    final ar = await a.wallet.drainEpicbox();
    if (ar.received + ar.held + ar.rejected > 0) _say('${a.name} drained: received ${ar.received} held ${ar.held} rejected ${ar.rejected}');
  }, tries: 30, every: const Duration(seconds: 5));
}

/// A and B read their channel [rounds] times.
Future<void> _settle(_Install a, _Install b, {int rounds = 2}) async {
  for (var i = 0; i < rounds; i++) {
    await a.sync();
    await b.sync();
  }
}

void main() {
  final skip = _lib == null || _dir == null ? 'needs WFE_LEPIC_LIB and WFE_LIVE_DIR' : null;

  setUpAll(() async {
    if (skip != null) return;
    await initLepic(libraryPath: _lib);
    _runtime = lepic.LepicRuntime(logLevel: lepic.LogLevel.info);
    // The app's and LEPIC's lines go to the test output, for the evidence.
    AppLog.use(_EchoSink());
    _runtime.logs().listen((e) {
      if (e.level == lepic.LogLevel.warn || e.level == lepic.LogLevel.error || e.target.contains('contact') || e.target.contains('pairing')) {
        // ignore: avoid_print
        print('LEPIC ${e.level.name} ${e.target} ${e.message} ${e.fields.map((f) => '${f.name}=${f.value}').join(' ')}');
      }
    }, onError: (_) {});
  });

  test('device link live step: $_step', timeout: const Timeout(Duration(minutes: 60)), skip: skip, () async {
    switch (_step) {
      case 'setup':
        final a = await _wallet('A');
        final phrase = File('$_dir/A.phrase');
        if (!phrase.existsSync()) {
          phrase.writeAsStringSync(await a.wallet.mnemonic(password: _password));
          await Process.run('chmod', ['600', phrase.path]);
        }
        final b = await _wallet('B', mnemonic: phrase.readAsStringSync());
        final r = await _wallet('R');
        for (final w in [a, b, r]) {
          await w.session.scan(startHeight: BigInt.zero).drain<void>();
          final s = await w.refresh();
          _say('${w.name} address ${await w.session.epicboxAddress()} total ${_amount(s.total)} height ${s.lastConfirmedHeight}');
        }
        expect(await a.session.epicboxAddress(), await b.session.epicboxAddress());
        _say('built-in pairing relays: floonet ${lepic.builtInPairingRelays(chain: lepic.Chain.floonet)} mainnet ${lepic.builtInPairingRelays(chain: lepic.Chain.mainnet)}');
        for (final w in [a, b, r]) {
          w.dispose();
        }

      case 'probe':
        final a = await _wallet('A');
        final b = await _wallet('B');
        for (final relay in ['epicbox.stackwallet.com', 'epicbox.epicnet.us', 'epicbox.epiccash.com', _relay]) {
          // A private pairing whose mailboxes live on [relay], and one payload over it.
          var pairing = 'no';
          var stage = 'invite';
          try {
            final invite = await a.pairing.makePrivateInvite(name: 'Desktop', homeRelay: relay);
            stage = 'accept';
            final answer = await b.pairing.acceptPrivateInvite(link: invite.inviteLink!, name: 'Phone');
            stage = 'collect';
            final paired = await _until(() async {
              final x = (await a.pairing.privatePairings()).where((p) => p.id == invite.id).firstOrNull;
              final y = (await b.pairing.privatePairings()).where((p) => p.id == answer.id).firstOrNull;
              return (x?.state.isPaired ?? false) && (y?.state.isPaired ?? false);
            }, step: () async {
              await a.pairing.collectPrivate(only: [invite.id]);
              await b.pairing.collectPrivate(only: [answer.id]);
            }, tries: 15);
            if (paired) {
              // Unverified, the payload is refused ("the contact is not verified").
              stage = 'payload unverified';
              try {
                await a.pairing.postPayload(id: invite.id, bytes: utf8.encode('too early'));
                _say('relay $relay: a payload before the check was taken (unexpected)');
              } on WalletError catch (e) {
                _say('relay $relay: payload before the check refused: ${e.kind.name} ${e.message}');
              }
              stage = 'check';
              await a.pairing.checkWords(invite.id, PairingCheck.match);
              await b.pairing.checkWords(answer.id, PairingCheck.match);
              stage = 'payload';
              await a.pairing.postPayload(id: invite.id, bytes: utf8.encode('probe $relay'));
              final got = await _until(() async => (await b.pairing.payloads()).any((p) => p.pairingId == answer.id), step: () => b.pairing.collectPrivate(only: [answer.id]), tries: 10);
              final ids = [for (final p in await b.pairing.payloads()) if (p.pairingId == answer.id) p.id];
              if (ids.isNotEmpty) await b.pairing.ackPayloads(ids);
              pairing = got ? 'paired + payload' : 'paired, no payload';
            } else {
              pairing = 'not paired in 45 s';
            }
            await a.pairing.removePairing(invite.id);
            await b.pairing.removePairing(answer.id);
          } on Object catch (e) {
            pairing = 'error at $stage: ${e is WalletError ? '${e.kind.name} ${e.message}' : e}';
          }
          // A floonet wallet whose payments box is on [relay].
          var box = 'ok';
          final t = await _wallet('T-$relay', relay: relay);
          try {
            final rep = await t.wallet.drainEpicbox();
            box = 'drain ok (received ${rep.received})';
          } on lepic.WalletError catch (e) {
            box = 'drain refused: ${e.kind.name} ${e.message}';
          } on Object catch (e) {
            box = 'drain failed: $e';
          }
          t.dispose();
          _say('relay $relay: private pairing $pairing; floonet payments box $box');
        }
        a.dispose();
        b.dispose();

      case 'fund':
        final a = await _wallet('A');
        final b = await _wallet('B');
        final before = (await b.rows()).length;
        final addr = await a.session.epicboxAddress();
        final fund = await Process.start('${_env['HOME']}/epic/qa-funder/fund.sh', [addr, _env['WFE_FUND'] ?? '20']);
        fund.stdout.transform(utf8.decoder).listen((_) {});
        fund.stderr.transform(utf8.decoder).listen((_) {});
        final got = await _until(() async {
          final rep = await a.wallet.drainEpicbox();
          if (rep.received > 0) _say('A received the funder\'s payment');
          return (await a.rows()).any((t) => t.kind == TxKind.received);
        }, tries: 40, every: const Duration(seconds: 5));
        _say('fund.sh exit ${await fund.exitCode}; A has a receive: $got');
        expect(got, isTrue);
        final mined = await _until(() async {
          final s = await a.refresh();
          return s.spendable > BigInt.zero;
        }, tries: 60, every: const Duration(seconds: 15));
        final sa = await a.session.summary(refresh: false, minimumConfirmations: _oneConf);
        _say('A spendable ${_amount(sa.spendable)} at height ${sa.lastConfirmedHeight} (mined: $mined)');
        // B was not told: its own refresh and update scan find the coins.
        final seen = await _until(() async {
          await b.refresh();
          return (await b.rows()).any((t) => t.origin == TxOrigin.otherWallet && t.kind == TxKind.received);
        }, tries: 20, every: const Duration(seconds: 10));
        for (final t in (await b.rows()).take((await b.rows()).length - before)) {
          _say('B row: ${_row(t)}');
        }
        final sb = await b.session.summary(refresh: false, minimumConfirmations: _oneConf);
        _say('B "Received by another wallet": $seen; B total ${_amount(sb.total)} spendable ${_amount(sb.spendable)}');
        expect(seen, isTrue);
        a.dispose();
        b.dispose();

      case 'link':
        final a = await _wallet('A');
        final b = await _wallet('B');
        await a.service.load();
        await b.service.load();
        _say('A device ${a.service.book.deviceId} "${a.service.book.deviceName}", B device ${b.service.book.deviceId} "${b.service.book.deviceName}"');
        await a.service.startShowing(_linkServers);
        final code = a.service.link!.code;
        _say('A shows the link on ${_linkServers.join(' + ')}: phase ${a.service.link!.phase.name}, ${code?.substring(0, 34)}… (${code?.length} chars)');
        expect(code, startsWith('epiccash://device-link/1/'));
        File('$_dir/link.txt').writeAsStringSync(code!);
        await b.service.startScanned(code);
        _say('B read it: phase ${b.service.link!.phase.name}, other "${b.service.link!.otherName}", server ${b.service.link!.servers}');
        final checking = await _until(
          () async => a.service.link?.phase == LinkPhase.checking && b.service.link?.phase == LinkPhase.checking,
          step: () => _settle(a, b, rounds: 1),
        );
        final sasA = a.service.link!.sas.map((w) => w.name).join(' ');
        final sasB = b.service.link!.sas.map((w) => w.name).join(' ');
        _say('both at the pictures: $checking; A "$sasA" B "$sasB"');
        expect(checking, isTrue);
        expect(sasA, sasB);
        await a.service.answerCheck(true);
        _say('A matched: phase ${a.service.link!.phase.name}');
        await _settle(a, b);
        _say('before B matched: A ${a.service.link!.phase.name}, devices on A ${a.service.book.devices.length}');
        expect(a.service.book.devices, isEmpty, reason: 'nothing is linked until both matched');
        await b.service.answerCheck(true);
        final done = await _until(
          () async => a.service.link?.phase == LinkPhase.done && b.service.link?.phase == LinkPhase.done,
          step: () => _settle(a, b, rounds: 1),
        );
        _say('both linked: $done; A sees ${a.service.book.devices.map((d) => '"${d.name}" ${d.pairings}')}; B sees ${b.service.book.devices.map((d) => '"${d.name}" ${d.pairings}')}');
        expect(done, isTrue);
        // The second server: A invites over the first channel, B answers, pictures over it.
        final both = await _until(
          () async => a.service.book.devices.single.pairings.length == 2 && b.service.book.devices.single.pairings.length == 2,
          step: () => _settle(a, b, rounds: 1),
          tries: 40,
        );
        _say('second server: $both; A ${a.service.book.devices.single.pairings}; B ${b.service.book.devices.single.pairings}; servers A ${a.service.book.servers} B ${b.service.book.servers}');
        expect(both, isTrue);
        // A notice goes over every pairing of the device: B finds a copy on each server.
        await a.service.renameThis('Desktop live');
        final bPairings = b.service.book.devices.single.pairings;
        final copies = <String>{};
        await _until(() async => copies.length == bPairings.length, step: () async {
          await b.pairing.collectPrivate(only: bPairings.values.toList());
          for (final p in await b.pairing.payloads()) {
            for (final e in bPairings.entries) {
              if (e.value == p.pairingId) copies.add(e.key);
            }
          }
        }, tries: 20);
        await _settle(a, b);
        _say('rename arrived over ${copies.join(' + ')}; B calls A "${b.service.book.devices.single.name}"');
        expect(copies.length, 2);
        expect(b.service.book.devices.single.name, 'Desktop live');
        a.dispose();
        b.dispose();

      case 'hold':
        final a = await _wallet('A');
        final b = await _wallet('B');
        final r = await _wallet('R');
        await a.service.load();
        await b.service.load();
        await a.refresh();
        await b.refresh();
        final freeBefore = await b.session.estimateMax(minimumConfirmations: _oneConf);
        _say('B can send ${_amount(freeBefore.amount)} EPIC before');
        final tx = await _send(a, r, 1, 'device-link hold');
        await a.service.announceNow();
        final aInputs = [for (final o in await a.session.outputs()) if (o.status == WalletOutputStatus.locked && o.txId == tx.id) o.commitment];
        _say('A locked ${aInputs.map(_short).join(',')}; outbox ${a.service.book.outbox.length}');
        final held = await _until(() async => b.service.book.holds.any((h) => h.slateId == tx.slateId && h.state.holds), step: b.sync);
        final h = b.service.book.holds.firstWhere((h) => h.slateId == tx.slateId);
        _say('B holds: $held; ${_hold(h)}; B session heldOutputs ${b.session.heldOutputs.map(_short).join(',')}');
        expect(held, isTrue);
        expect(b.session.heldOutputs, containsAll(aInputs));
        try {
          final freeHeld = await b.session.estimateMax(minimumConfirmations: _oneConf);
          _say('B can send ${_amount(freeHeld.amount)} EPIC while held');
          expect(freeHeld.amount < freeBefore.amount, isTrue);
        } on WalletError catch (e) {
          _say('B estimate while held refused: ${e.kind.name}');
        }
        final pending = (await b.shown()).where((t) => t.slateId == tx.slateId).toList();
        _say('B rows for it: ${pending.map(_row).join(' | ')}');
        expect(pending.single.origin, TxOrigin.linkedDevice);
        expect(pending.single.deviceName, 'Desktop live');
        // A cancels before R answers.
        await a.session.cancelTransaction(txId: tx.id!);
        await a.service.announceNow();
        _say('A cancelled tx ${tx.id}; A row ${_row((await a.rows()).firstWhere((t) => t.slateId == tx.slateId))}');
        final freed = await _until(() async => !b.service.book.holds.any((x) => x.slateId == tx.slateId && x.state.holds), step: b.sync);
        final ended = (await b.shown()).where((t) => t.slateId == tx.slateId).toList();
        _say('B released: $freed; ${_hold(b.service.book.holds.firstWhere((x) => x.slateId == tx.slateId))}; heldOutputs ${b.session.heldOutputs.length}; rows ${ended.map(_row).join(' | ')}');
        expect(freed, isTrue);
        expect(b.session.heldOutputs, isEmpty);
        expect(ended.single.kind, TxKind.sentCancelled);
        expect(ended.single.deviceEnding, DeviceEnding.cancelled);
        final freeAfter = await b.session.estimateMax(minimumConfirmations: _oneConf);
        _say('B can send ${_amount(freeAfter.amount)} EPIC after');
        // R's copy of the cancelled payment stays unanswered: R drains only in the next steps,
        // and A refuses an answer to a cancelled send.
        a.dispose();
        b.dispose();
        r.dispose();

      case 'post':
        final a = await _wallet('A');
        final b = await _wallet('B');
        final r = await _wallet('R');
        await a.service.load();
        await b.service.load();
        await a.refresh();
        await b.refresh();
        final tx = await _send(a, r, 2, 'device-link post');
        await a.service.announceNow();
        final held = await _until(() async => b.service.book.holds.any((h) => h.slateId == tx.slateId && h.state.holds), step: b.sync);
        _say('B holds: $held');
        expect(held, isTrue);
        final posted = await _answerAndPost(a, r, tx.slateId!);
        final aRow = (await a.rows()).firstWhere((t) => t.slateId == tx.slateId);
        _say('A posted: $posted; ${_row(aRow)}');
        expect(posted, isTrue);
        await a.service.announceNow();
        final heard = await _until(() async => b.service.book.holds.any((h) => h.slateId == tx.slateId && h.state == HoldState.posted), step: b.sync);
        _say('B heard posted: $heard; ${_hold(b.service.book.holds.firstWhere((h) => h.slateId == tx.slateId))}');
        // The chain decides: B's own refresh sees the coins spent and merges the rows.
        final confirmed = await _until(() async {
          await b.refresh();
          await b.sync();
          final mine = (await b.shown()).where((t) => t.slateId == tx.slateId).toList();
          return mine.length == 1 && mine.single.confirmed;
        }, tries: 60, every: const Duration(seconds: 15));
        final rows = await b.shown();
        final mine = rows.where((t) => t.slateId == tx.slateId).toList();
        final loose = rows.where((t) => t.origin == TxOrigin.otherWallet && t.kind != TxKind.received && t.spentCommits.any(b.service.book.holds.firstWhere((h) => h.slateId == tx.slateId).commitments.contains)).toList();
        _say('B confirmed it: $confirmed; rows ${mine.map(_row).join(' | ')}; unmerged other-wallet rows ${loose.length}; hold ${_hold(b.service.book.holds.firstWhere((h) => h.slateId == tx.slateId))}');
        // The send the hold step cancelled took the same coin: it stays Cancelled.
        final coins = b.service.book.holds.firstWhere((h) => h.slateId == tx.slateId).commitments;
        final earlier = [
          for (final h in b.service.book.holds)
            if (h.slateId != tx.slateId && h.commitments.any(coins.contains)) h,
        ];
        for (final h in earlier) {
          _say('B earlier payment on the same coin: ${_hold(h)}; row ${rows.where((t) => t.slateId == h.slateId).map(_row).join(' | ')}');
        }
        expect(confirmed, isTrue);
        expect(mine.single.deviceName, 'Desktop live');
        expect(loose, isEmpty);
        for (final h in earlier) {
          expect(rows.singleWhere((t) => t.slateId == h.slateId).confirmed, isFalse);
        }
        await a.refresh();
        _say('A row ${_row((await a.rows()).firstWhere((t) => t.slateId == tx.slateId))}');
        a.dispose();
        b.dispose();
        r.dispose();

      case 'chain':
        final a = await _wallet('A');
        final b = await _wallet('B');
        final r = await _wallet('R');
        await a.service.load();
        await b.service.load();
        await a.refresh();
        await b.refresh();
        await a.service.setPaused(true);
        final tx = await _send(a, r, 1, 'device-link unseen');
        await a.service.announceNow();
        await _settle(a, b);
        _say('A paused: outbox ${a.service.book.outbox.length}; B holds for it ${b.service.book.holds.where((h) => h.slateId == tx.slateId).length}');
        expect(b.service.book.holds.where((h) => h.slateId == tx.slateId), isEmpty);
        final posted = await _answerAndPost(a, r, tx.slateId!);
        _say('A posted: $posted');
        expect(posted, isTrue);
        final aRow = (await a.rows()).firstWhere((t) => t.slateId == tx.slateId);
        final before = {for (final t in await b.rows()) t.key};
        final seen = await _until(() async {
          await b.refresh();
          return (await b.rows()).any((t) => t.origin == TxOrigin.otherWallet && t.kind != TxKind.received && !before.contains(t.key));
        }, tries: 60, every: const Duration(seconds: 15));
        final fresh = (await b.rows()).where((t) => !before.contains(t.key) && t.origin == TxOrigin.otherWallet && t.kind != TxKind.received).toList();
        _say('B "Sent from another wallet": $seen; new rows ${fresh.map(_row).join(' | ')}; A sent ${_amount(aRow.amountDebited - aRow.amountCredited)} incl. fee ${_amount(aRow.fee ?? BigInt.zero)}');
        expect(seen, isTrue);
        expect(fresh.single.spentCommits, containsAll(aRow.spentCommits));
        // A resumes: whatever it tells now changes nothing, the spend shows once.
        await a.service.setPaused(false);
        await a.refresh();
        await _settle(a, b, rounds: 3);
        final after = (await b.shown()).where((t) => t.kind != TxKind.received && t.spentCommits.any(aRow.spentCommits.contains)).toList();
        _say('after A resumed: B rows for that coin ${after.map(_row).join(' | ')}; B holds ${b.service.book.holds.where((h) => h.state.holds).length}');
        expect(after.length, 1);
        expect(after.single.origin, TxOrigin.otherWallet);
        a.dispose();
        b.dispose();
        r.dispose();

      case 'words':
        // Two different wallets on mainnet: no coins move, only the pairing.
        final x = await _wallet('X', mainnet: true, relay: 'epicbox.stackwallet.com');
        final y = await _wallet('Y', mainnet: true, relay: 'epicbox.stackwallet.com');
        x.pairing.setConnectionServers(_meeting);
        y.pairing.setConnectionServers(_meeting);
        final invite = await x.pairing.makeInvite(name: 'Xena', expiry: const Duration(minutes: 10), words: true);
        final words = [for (final w in invite.inviteWords) w.name];
        _say('X words invite on meeting set $_meeting, home ${invite.homeRelay}: ${words.length} words');
        // Y on a set without X's servers does not find them.
        final other = (_env['WFE_MEETING_OTHER'] ?? 'epicbox.epiccash.com').split(',');
        y.pairing.setConnectionServers(other);
        try {
          await y.pairing.openWords(words);
          _say('Y on $other found them (unexpected)');
          fail('words found on a set without their servers');
        } on Object catch (e) {
          _say('Y on $other: not found (${e is WalletError ? e.kind.name : e})');
        }
        y.pairing.setConnectionServers(_meeting);
        final preview = await y.pairing.openWords(words);
        final answer = await y.pairing.acceptInvite(token: preview.token, name: 'Yuri');
        final paired = await _until(() async {
          final xr = await x.pairing.pairing(invite.id);
          final yr = await y.pairing.pairing(answer.id);
          return (xr?.state.isPaired ?? false) && (yr?.state.isPaired ?? false);
        }, step: () async {
          await x.pairing.collect(trigger: PairingCollectTrigger.pull);
          await y.pairing.collect(trigger: PairingCollectTrigger.pull);
        }, tries: 30);
        final xr = (await x.pairing.pairing(invite.id))!;
        final yr = (await y.pairing.pairing(answer.id))!;
        _say('Y on $_meeting found and answered; paired $paired; X "${xr.sas.map((w) => w.name).join(' ')}" Y "${yr.sas.map((w) => w.name).join(' ')}"; homes ${xr.homeRelay} / ${yr.homeRelay}');
        expect(paired, isTrue);
        expect(xr.sas.map((w) => w.name).join(' '), yr.sas.map((w) => w.name).join(' '));
        await x.pairing.removePairing(invite.id);
        await y.pairing.removePairing(answer.id);
        x.dispose();
        y.dispose();

      case 'paybox':
        // A floonet payment to a wallet whose payments box is on a public relay (WFE_PAY_RELAY).
        final relay = _env['WFE_PAY_RELAY'] ?? 'epicbox.stackwallet.com';
        final a = await _wallet('A');
        final r2 = await _wallet('R2-$relay', relay: relay);
        await r2.session.scan(startHeight: BigInt.zero).drain<void>();
        await a.refresh();
        final to = await r2.session.epicboxAddress();
        _say('R2 address on ${to.split('@').last}');
        try {
          final tx = await a.session.sendEpicbox(amount: _epic ~/ BigInt.two, minimumConfirmations: _oneConf, address: to, message: 'device-link paybox');
          final rr = await _until(() async => (await r2.wallet.drainEpicbox()).received > 0, tries: 10, every: const Duration(seconds: 5));
          final posted = rr && await _answerAndPost(a, r2, tx.slateId!);
          _say('floonet payment over $relay: R2 received $rr, A posted $posted (slate ${tx.slateId})');
          if (!posted) await a.session.cancelTransaction(txId: tx.id!);
        } on Object catch (e) {
          _say('floonet payment over $relay refused: ${e is WalletError ? '${e.kind.name} ${e.message}' : e}');
        }
        a.dispose();
        r2.dispose();

      case 'direction':
        // One private pairing on WFE_DIR_RELAY: a payload each way, the inviter's first.
        final relay = _env['WFE_DIR_RELAY'] ?? _relay;
        final a = await _wallet('A');
        final b = await _wallet('B');
        final invite = await a.pairing.makePrivateInvite(name: 'Desktop', homeRelay: relay);
        final answer = await b.pairing.acceptPrivateInvite(link: invite.inviteLink!, name: 'Phone');
        final paired = await _until(() async {
          final x = (await a.pairing.privatePairings()).where((p) => p.id == invite.id).firstOrNull;
          final y = (await b.pairing.privatePairings()).where((p) => p.id == answer.id).firstOrNull;
          return (x?.state.isPaired ?? false) && (y?.state.isPaired ?? false);
        }, step: () async {
          await a.pairing.collectPrivate(only: [invite.id]);
          await b.pairing.collectPrivate(only: [answer.id]);
        }, tries: 15);
        await a.pairing.checkWords(invite.id, PairingCheck.match);
        await b.pairing.checkWords(answer.id, PairingCheck.match);
        _say('paired on $relay: $paired (A ${invite.id}, B ${answer.id})');
        Future<bool> deliver(_Install from, String fromId, _Install to, String toId) async {
          await from.pairing.postPayload(id: fromId, bytes: utf8.encode('from ${from.name}'));
          final got = await _until(() async => (await to.pairing.payloads()).any((p) => p.pairingId == toId), step: () async {
            await from.pairing.collectPrivate(only: [fromId]);
            await to.pairing.collectPrivate(only: [toId]);
          }, tries: 15);
          final ids = [for (final p in await to.pairing.payloads()) if (p.pairingId == toId) p.id];
          if (ids.isNotEmpty) await to.pairing.ackPayloads(ids);
          return got;
        }
        final ab = await deliver(a, invite.id, b, answer.id);
        _say('inviter A → joiner B: $ab');
        final ba = await deliver(b, answer.id, a, invite.id);
        _say('joiner B → inviter A: $ba');
        await a.pairing.removePairing(invite.id);
        await b.pairing.removePairing(answer.id);
        final left = [for (final c in await a.wallet.privatePairings()) if (c.contactId == invite.id) c.state.name];
        _say('after removePairing A still lists it: $left');
        expect(ab && ba, isTrue);
        a.dispose();
        b.dispose();

      case 'inspect':
        for (final name in ['A', 'B']) {
          final w = await _wallet(name);
          for (final c in await w.wallet.privatePairings()) {
            _say('$name private ${c.contactId} ${c.state.name} claimed "${c.claimedName}" relay ${c.homeRelay} removed ${c.removedByPeer}');
          }
          await w.pairing.collectPrivate();
          for (final p in await w.pairing.payloads()) {
            _say('$name payload ${p.id} on ${p.pairingId} ${p.bytes.length} bytes at ${p.receivedAt.toUtc()}');
          }
          _say('$name restore scan required ${await w.session.restoreScanRequired()}');
          for (final o in await w.session.outputs()) {
            _say('$name output ${_short(o.commitment)} ${_amount(o.value)} ${o.status.name} height ${o.height} tx ${o.txId}');
          }
          for (final t in await w.rows()) {
            _say('$name row id ${t.id} ${_row(t)}');
          }
          _say('$name book ${jsonEncode((await DeviceStore(_FileStore(File('$_dir/$name.app.json')), chain: Chain.floonet, walletId: name).load(defaultName: name)).toJson())}');
          w.dispose();
        }

      default:
        fail('WFE_LIVE_STEP: setup, probe, fund, link, hold, post, chain, words or inspect');
    }
  });
}
