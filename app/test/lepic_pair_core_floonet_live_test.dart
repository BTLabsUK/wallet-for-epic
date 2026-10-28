// SPDX-License-Identifier: Apache-2.0
// Live on floonet (26.10.18 pairing fixes): two wallets in data folders of their own, each a
// LepicWalletSession over the real LEPIC library, the real node and the real relay. Skipped
// unless WFE_LEPIC_LIB (the Linux library built at the pins) and WFE_LIVE_DIR (a folder kept
// between steps) are set. WFE_LIVE_STEP picks one step:
//
//   setup     makes A and B (B's phrase kept in the folder, mode 600), prints A's address
//   relay     an invite whose home relay cannot be reached: the invite says so, it does not end
//   late      a words invite answered by B while A does not collect; A collects after the
//             invite's deadline and the pairing still completes on both sides (item 5)
//   restore   B restored from its phrase pairs again; the key check brings the old keys back,
//             a second re-pair that day goes to keys changed, Use new removes the dead one, and
//             removing the pairing tells A (item 11)
//   mailbox   A pays B through B's mailbox; B hears that A posted it (item 12a); A needs funds
//   fund      drains A's payments mailbox and prints its balance (after qa-funder/fund.sh)
//
// Nothing prints a phrase or a password. Lines starting with "LIVE" are the results.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

final _env = Platform.environment;
final String? _lib = _env['WFE_LEPIC_LIB'];
final String? _dir = _env['WFE_LIVE_DIR'];
final String _step = _env['WFE_LIVE_STEP'] ?? '';

const _node = 'https://floo-node.btlabs.uk';
const _relay = 'flooepicbox.btlabs.uk';
const _password = 'live-pair-core-2610';

// ignore: avoid_print
void _say(String line) => print('LIVE ${DateTime.now().toUtc().toIso8601String().substring(11, 19)} $line');

/// Secrets in a JSON file next to the wallet, so a later step opens it again.
class _FileStore implements lepic.SecretStore {
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

lepic.WalletConfig _config(String name, {String relay = _relay}) => lepic.WalletConfig(
  dataDir: (Directory('$_dir/$name')..createSync(recursive: true)).path,
  chain: lepic.Chain.floonet,
  nodeUrl: _node,
  epicboxDomain: relay,
  epicboxPort: 443,
);

lepic.AppSecretStore _store(String name) => lepic.lepicSecretStore(_FileStore(File('$_dir/$name.secrets.json')));

/// The wallet [name], made on first use (from [mnemonic] when given), as a session.
Future<(LepicWalletSession, lepic.EpicWallet)> _wallet(String name, {String? mnemonic, String relay = _relay}) async {
  final exists = File('$_dir/$name.secrets.json').existsSync();
  final w = exists
      ? await lepic.EpicWallet.open(
          runtime: _runtime,
          config: _config(name, relay: relay),
          store: _store(name),
          password: _password,
        )
      : await lepic.EpicWallet.create(
          runtime: _runtime,
          config: _config(name, relay: relay),
          store: _store(name),
          mnemonic: mnemonic,
          password: _password,
        );
  return (LepicWalletSession(w), w);
}

Future<void> _collect(LepicWalletSession s) => s.pairing.collect(trigger: PairingCollectTrigger.pull);

/// Collects [s] until [done] or [tries] cycles 5 s apart.
Future<bool> _collectUntil(LepicWalletSession s, Future<bool> Function() done, {int tries = 24}) async {
  for (var i = 0; i < tries; i++) {
    await _collect(s);
    if (await done()) return true;
    await Future<void>.delayed(const Duration(seconds: 5));
  }
  return false;
}

String _words(List<SasWord> w) => w.map((e) => e.name).join(' ');

void main() {
  final skip = _lib == null || _dir == null ? 'needs WFE_LEPIC_LIB and WFE_LIVE_DIR' : null;

  setUpAll(() async {
    if (skip != null) return;
    await initLepic(libraryPath: _lib);
    _runtime = lepic.LepicRuntime(logLevel: lepic.LogLevel.info);
  });

  test('pair-core live step: $_step', timeout: const Timeout(Duration(minutes: 40)), skip: skip, () async {
    switch (_step) {
      case 'setup':
        final (a, aw) = await _wallet('A');
        final (b, bw) = await _wallet('B');
        final phrase = File('$_dir/B.phrase');
        if (!phrase.existsSync()) {
          phrase.writeAsStringSync(await bw.mnemonic(password: _password));
          await Process.run('chmod', ['600', phrase.path]);
        }
        _say('A address ${await aw.epicboxAddress()}');
        _say('B ready ${(await bw.epicboxAddress()).substring(0, 8)}…');
        a.dispose();
        b.dispose();

      case 'fund':
        final (a, aw) = await _wallet('A');
        final report = await aw.drainEpicbox();
        _say('A drained: received ${report.received} held ${report.held} rejected ${report.rejected}');
        await aw.refresh().toList();
        final summary = await aw.summary(refresh: true);
        _say(
          'A total ${summary.total} spendable ${summary.spendable} awaiting ${summary.awaitingConfirmation} height ${summary.lastConfirmedHeight}',
        );
        a.dispose();

      case 'relay':
        // A relay whose name resolves to nothing, as a DNS filter answers.
        final (c, _) = await _wallet('C', relay: 'epicbox.nowhere.invalid');
        final seen = <PairingEvent>[];
        final sub = c.pairing.events().listen(seen.add);
        final invite = await c.pairing.makeInvite(name: 'Cara', expiry: const Duration(hours: 1));
        _say('C invite on ${invite.homeRelay}, relayDown ${invite.relayDown}');
        await _collect(c);
        await Future<void>.delayed(const Duration(seconds: 1));
        final after = (await c.pairing.pairing(invite.id))!;
        _say(
          'C after a collect: state ${after.state.name}, relayDown ${after.relayDown}, homeRelay ${after.homeRelay}, events ${seen.map((e) => e.kind.name).join(',')}',
        );
        expect(after.state, PairingState.pendingInvite);
        expect(after.relayDown, isTrue);
        expect(seen.map((e) => e.kind), contains(PairingEventKind.homeRelayUnreachable));
        await c.pairing.cancelInvite(invite.id);
        await sub.cancel();
        c.dispose();

      case 'late':
        final (a, _) = await _wallet('A');
        final (b, _) = await _wallet('B');
        final aSeen = <PairingEvent>[];
        final bSeen = <PairingEvent>[];
        final subs = [a.pairing.events().listen(aSeen.add), b.pairing.events().listen(bSeen.add)];
        final invite = await a.pairing.makeInvite(name: 'Alex', expiry: const Duration(hours: 1), words: true);
        _say('A words invite on ${invite.homeRelay}, ${invite.inviteWords.length} words, expires ${invite.expiresAt?.toUtc()}');
        final preview = await b.pairing.openWords([for (final w in invite.inviteWords) w.name]);
        final answer = await b.pairing.acceptInvite(token: preview.token, name: 'Bob');
        _say('B answered: ${answer.state.name}, relayDown ${answer.relayDown}, waits until ${answer.expiresAt?.toUtc()}');
        // A does not collect, as an app in the background or a relay A cannot reach. Past the
        // invite's deadline (expiry and 10 minutes of skew) it collects once.
        final deadline = invite.expiresAt!.add(const Duration(minutes: 10, seconds: 30));
        while (DateTime.now().isBefore(deadline)) {
          await _collect(b);
          final mine = (await b.pairing.pairing(answer.id))!;
          if (mine.state != PairingState.pendingReply) fail('B left waiting before A collected: ${mine.state}');
          await Future<void>.delayed(const Duration(seconds: 60));
        }
        _say('past the deadline; B still ${(await b.pairing.pairing(answer.id))!.state.name}; A collects now');
        await _collect(a);
        await Future<void>.delayed(const Duration(seconds: 1));
        final aPairing = (await a.pairing.pairings()).where((r) => r.state.isPaired).toList();
        _say('A: events ${aSeen.map((e) => '${e.kind.name}/${e.failure?.name}').join(',')}; paired ${aPairing.length}');
        expect(aSeen.map((e) => e.kind), contains(PairingEventKind.replied));
        expect(aSeen.where((e) => e.kind == PairingEventKind.failed), isEmpty);
        final confirmed = await _collectUntil(b, () async => bSeen.any((e) => e.kind == PairingEventKind.confirmed));
        final bRecord = (await b.pairing.pairing(answer.id))!;
        _say('B: events ${bSeen.map((e) => e.kind.name).join(',')}; state ${bRecord.state.name}');
        expect(confirmed, isTrue);
        final aRecord = aPairing.single;
        _say('words A "${_words(aRecord.sas)}" B "${_words(bRecord.sas)}" same ${_words(aRecord.sas) == _words(bRecord.sas)}');
        expect(_words(aRecord.sas), _words(bRecord.sas));
        await a.pairing.checkWords(aRecord.id, PairingCheck.match);
        await b.pairing.checkWords(bRecord.id, PairingCheck.match);
        File('$_dir/late.ids').writeAsStringSync('${aRecord.id} ${bRecord.id}');
        for (final s in subs) {
          await s.cancel();
        }
        a.dispose();
        b.dispose();

      case 'restore':
        final (a, aw) = await _wallet('A');
        // The newest pairing with B on A.
        final withB = [for (final c in await aw.contacts()) if (c.claimedName == 'Bob') c]..sort((x, y) => x.createdAtMs.compareTo(y.createdAtMs));
        final ids = [withB.last.contactId];
        final aSeen = <PairingEvent>[];
        final sub = a.pairing.events().listen(aSeen.add);
        await a.pairing.attach(ids[0], 'book-bob');
        final phrase = File('$_dir/B.phrase').readAsStringSync();

        Future<({String aSide, String bSide, LepicWalletSession b})> rePair(String name) async {
          final (b, _) = await _wallet(name, mnemonic: phrase);
          final invite = await a.pairing.makeInvite(name: 'Alex', expiry: const Duration(hours: 1));
          final preview = await b.pairing.openInvite(invite.inviteLink!);
          final answer = await b.pairing.acceptInvite(token: preview.token, name: 'Bob');
          await _collectUntil(a, () async => (await a.pairing.pairing(invite.id))?.state.isPaired ?? false);
          await _collectUntil(b, () async => (await b.pairing.pairing(answer.id))?.state.isPaired ?? false);
          return (aSide: invite.id, bSide: answer.id, b: b);
        }

        // B restored from its phrase on a new install: its old pairing is gone there.
        final first = await rePair('B2');
        _say('restored B2 paired again with A; A attaches the new pairing to Bob');
        await a.pairing.attach(first.aSide, 'book-bob');
        final back = await _collectUntil(a, () async {
          await _collect(first.b);
          return aSeen.any((e) => e.kind == PairingEventKind.keysRestored || e.kind == PairingEventKind.keysChanged);
        });
        _say(
          'A after the key check: ${aSeen.map((e) => e.kind.name).join(',')}; bob uses ${(await a.pairing.pairingForContact('book-bob'))?.id == ids[0] ? 'the old pairing' : 'another'}',
        );
        expect(back, isTrue);
        expect(aSeen.map((e) => e.kind), contains(PairingEventKind.keysRestored));

        // Restored once more the same day: no check may run for that slot, so the new pairing
        // shows keys changed at once instead of the dead old one staying in use.
        aSeen.clear();
        final second = await rePair('B3');
        await a.pairing.attach(second.aSide, 'book-bob');
        await Future<void>.delayed(const Duration(seconds: 1));
        final changed = (await a.pairing.pairing(second.aSide))!;
        _say(
          'second re-pair: A events ${aSeen.map((e) => e.kind.name).join(',')}; new pairing ${changed.state.name}; contact uses ${(await a.pairing.pairingForContact('book-bob'))?.state.name}',
        );
        expect(changed.state, PairingState.keysChanged);
        expect(aSeen.map((e) => e.kind), isNot(contains(PairingEventKind.keyCheckRefused)));
        final kept = await a.pairing.resolveKeysChanged(second.aSide, KeysChoice.useNew);
        final onContact = [
          for (final r in await a.pairing.pairings())
            if (r.contactId == 'book-bob') r.id,
        ];
        _say(
          'Use new: A keeps ${kept.state.name}; pairings on Bob ${onContact.length} (${onContact.join(',') == second.aSide ? 'only the new one' : onContact.join(',')})',
        );
        expect(onContact, [second.aSide]);

        // B3 removes the pairing: A hears it and the pairing is marked, not used.
        aSeen.clear();
        await second.b.pairing.removePairing(second.bSide);
        final told = await _collectUntil(a, () async => aSeen.any((e) => e.kind == PairingEventKind.unpaired));
        final dead = (await a.pairing.pairing(second.aSide))!;
        _say(
          'B3 removed it: A events ${aSeen.map((e) => e.kind.name).join(',')}; removedByPeer ${dead.removedByPeer}; paysByMailbox ${dead.paysByMailbox}',
        );
        expect(told, isTrue);
        expect(dead.removedByPeer, isTrue);
        await sub.cancel();
        first.b.dispose();
        second.b.dispose();
        a.dispose();

      case 'mailbox':
        final (a, aw) = await _wallet('A');
        final (b, _) = await _wallet('B');
        final invite = await a.pairing.makeInvite(name: 'Alex', expiry: const Duration(hours: 1));
        final preview = await b.pairing.openInvite(invite.inviteLink!);
        final answer = await b.pairing.acceptInvite(token: preview.token, name: 'Bob');
        await _collectUntil(a, () async => (await a.pairing.pairing(invite.id))?.state.isPaired ?? false);
        await _collectUntil(b, () async => (await b.pairing.pairing(answer.id))?.state.isPaired ?? false);
        final posted = <InvoiceEvent>[];
        final sub = b.invoiceEvents().listen((e) {
          if (e.kind == InvoiceEventKind.paymentPosted) posted.add(e);
        });
        await aw.refresh().toList();
        final summary = await aw.summary(refresh: true);
        _say('A spendable ${summary.spendable}');
        final tx = await a.pairing.sendViaMailbox(
          id: invite.id,
          amount: BigInt.from(5000000),
          minimumConfirmations: summary.minimumConfirmations,
          message: 'pair-core 12a',
        );
        _say('A sent ${tx.slateId} through B\'s mailbox');
        // B answers, A finalizes and pushes it, then B hears that A posted it.
        await _collectUntil(b, () async => (await b.transactions(refresh: false)).any((t) => t.slateId == tx.slateId));
        final pushed = await _collectUntil(a, () async {
          final mine = (await a.transactions(refresh: false)).where((t) => t.slateId == tx.slateId).firstOrNull;
          return mine != null && mine.status == TxStatus.awaitingConfirmation;
        });
        _say('A finalized and posted: $pushed');
        final heard = await _collectUntil(b, () async => posted.isNotEmpty);
        final row = (await b.transactions(refresh: false)).where((t) => t.slateId == tx.slateId).firstOrNull;
        _say('B: paymentPosted ${posted.length}; senderReportedPostedAt ${row?.senderReportedPostedAtUnix}; status ${row?.status.name}');
        expect(heard, isTrue);
        expect(row?.senderReportedPostedAtUnix, isNotNull);
        // The receiver's Home and Activity show "Sender reports posted" by this rule.
        _say('B: transport ${row?.transport}; senderReportsPosted ${row == null ? null : senderReportsPosted(row, now: DateTime.now())}');
        expect(senderReportsPosted(row!, now: DateTime.now()), isTrue);
        await sub.cancel();
        a.dispose();
        b.dispose();

      case 'inspect':
        for (final name in ['A', 'B']) {
          final (s, w) = await _wallet(name);
          for (final c in await w.contacts()) {
            _say('$name contact ${c.contactId.substring(0, 8)} ${c.state.name} claimed ${c.claimedName} created ${DateTime.fromMillisecondsSinceEpoch(c.createdAtMs.toInt()).toUtc()} relay ${c.homeRelay} removed ${c.removedByPeer} words ${c.sas.map((e) => e.name).join(' ')}');
          }
          for (final p in await w.pairingsPending()) {
            _say('$name pending ${p.contactId.substring(0, 8)} inviter ${p.inviter} expires ${DateTime.fromMillisecondsSinceEpoch(p.expiresAtMs.toInt()).toUtc()}');
          }
          s.dispose();
        }

      default:
        fail('WFE_LIVE_STEP: setup, fund, relay, late, restore or mailbox');
    }
  });
}
