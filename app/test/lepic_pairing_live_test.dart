// SPDX-License-Identifier: Apache-2.0
// Live: pairing (RFC 0002) through the app's LEPIC adapter on the real library, with LEPIC's
// mock chain and mock relay: an invite answered and its words checked, in person by cards,
// a request to a verified contact paid and finalized, a payment through a contact's mailbox,
// a sealed payment file there and back,
// and the pairings carried by the history backup to a restored install. Needs LEPIC's mock
// build of the Linux library (the shipped one has no mock chain; MockChain::new refuses), made
// from the pinned clone into a folder of your own:
//
//   (cd third_party/lepic && CARGO_TARGET_DIR=$PWD/target/mock \
//     cargo xtask mobile --package --mock --out "$OUT" --target x86_64-unknown-linux-gnu)
//   WFE_LEPIC_MOCK_LIB="$OUT/x86_64-unknown-linux-gnu/liblepic_ffi.so" \
//     flutter test test/lepic_pairing_live_test.dart
//
// Without it it is skipped.
import 'dart:io';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart' show appConfig;
import 'package:lepic/lepic.dart' as lepic;
// Not exported by package:lepic/lepic.dart.
import 'package:lepic/src/rust/api/policy.dart' show HostPolicy;
import 'package:lepic/testing.dart' as lepic_testing;

final String? _lib = Platform.environment['WFE_LEPIC_MOCK_LIB'];

/// A built-in floonet relay, so pairing words are offered; the mock relay serves it.
const _relay = 'epicbox.btlabs.uk';
const _password = 'test-pass-1234';
final _epic = BigInt.from(100000000);

class _MemoryStore implements lepic.SecretStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Lets the wallets' events reach the sessions.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 200));

void main() {
  late Directory root;
  late lepic_testing.MockChain chain;
  late lepic.LepicRuntime runtime;
  final open = <LepicWalletSession>[];
  var made = 0;

  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
  });

  setUp(() {
    root = Directory.systemTemp.createTempSync('wfe-pairing-live-');
    chain = lepic_testing.MockChain(height: BigInt.one);
    runtime = chain.runtimeWithRelay(
      logLevel: lepic.LogLevel.warn,
      relay: lepic_testing.MockRelay(chain: lepic.Chain.floonet),
    );
  });

  tearDown(() {
    for (final s in open) {
      s.dispose();
    }
    open.clear();
    root.deleteSync(recursive: true);
  });

  /// A wallet on the mock chain, as a session; [funded] EPIC on it first.
  Future<(LepicWalletSession, lepic.EpicWallet)> wallet({int funded = 0, String? mnemonic}) async {
    made++;
    final w = await lepic.EpicWallet.create(
      runtime: runtime,
      config: lepic.WalletConfig(policy: const HostPolicy(), torWanted: false, hostFeatures: 0, 
        dataDir: (Directory('${root.path}/w$made')..createSync()).path,
        chain: lepic.Chain.floonet,
        nodeUrl: 'http://127.0.0.1:1',
        epicboxDomain: _relay,
        epicboxPort: 443,
        onionRoutes: const [], tuning: LepicWalletService.netTuningOf(appConfig), offline: false,
      ),
      store: lepic.lepicSecretStore(_MemoryStore()),
      mnemonic: mnemonic,
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
    }
    if (funded > 0 || mnemonic != null) {
      final scan = await w.scan(deleteUnconfirmed: false).toList();
      expect(scan.last.finished, isTrue);
    }
    final s = LepicWalletSession(w);
    open.add(s);
    return (s, w);
  }

  /// Pairs [a] (the inviter) and [b] by an invite through the relay and checks the words on
  /// both sides. Returns each side's id of the other.
  Future<({String aSide, String bSide})> pair(LepicWalletSession a, LepicWalletSession b) async {
    final invite = await a.pairing.standingCode(name: 'Anna');
    expect(invite.state, PairingState.pendingInvite);
    expect(invite.inviteLink, startsWith('epiccash://pair/1/'));
    final preview = await b.pairing.openInvite(invite.inviteLink!);
    expect(preview.name, 'Anna');
    final answer = await b.pairing.acceptInvite(token: preview.token, name: 'Ben');
    expect(answer.state, PairingState.pendingReply);
    await a.pairing.collect(trigger: PairingCollectTrigger.open);
    await b.pairing.collect(trigger: PairingCollectTrigger.pull);
    // Pairing v3: the inviter stays Waiting until it hears the invitee finished.
    await a.pairing.collect(trigger: PairingCollectTrigger.open);
    final aView = (await a.pairing.pairing(invite.id))!;
    final bView = (await b.pairing.pairing(answer.id))!;
    expect(aView.state, PairingState.paired);
    expect(aView.name, 'Ben');
    expect(aView.sas, hasLength(4));
    expect([for (final w in aView.sas) w.name], [for (final w in bView.sas) w.name]);
    expect((await a.pairing.checkWords(invite.id, PairingCheck.match))!.state, PairingState.verified);
    expect((await b.pairing.checkWords(answer.id, PairingCheck.match))!.state, PairingState.verified);
    return (aSide: invite.id, bSide: answer.id);
  }

  test('an invite is answered, its words match and both sides are verified', () async {
    final (anna, _) = await wallet();
    final (ben, _) = await wallet();
    final ids = await pair(anna, ben);
    final pairings = await anna.pairing.pairings();
    expect([for (final p in pairings) p.id], [ids.aSide]);
    // Pairing v3 proves the other wallet's own Epicbox address; the mailbox is never shown.
    expect(pairings.single.paymentsAddress, await ben.epicboxAddress());
    expect(pairings.single.seals, isTrue);
    await anna.pairing.removePairing(ids.aSide);
    expect(await anna.pairing.pairings(), isEmpty);
  }, skip: _lib == null ? 'needs WFE_LEPIC_MOCK_LIB (the mock build)' : false);

  test('a wallet opening its own invite is refused before the answer, also after a restart', () async {
    final (anna, w) = await wallet();
    final (carl, _) = await wallet();
    final invite = await anna.pairing.standingCode(name: 'Anna');
    Future<PairingFailure?> failureOf(Future<Object?> call) async {
      try {
        await call;
        return null;
      } catch (e) {
        return pairingFailureOf(e);
      }
    }

    expect(await failureOf(anna.pairing.openInvite(invite.inviteLink!)), PairingFailure.ownCard);
    // After a restart the run's links are gone; LEPIC's preview still knows the invite as
    // this wallet's (InvitePreview.own). Failed on LEPIC be49441, whose preview did not tell.
    final again = LepicWalletSession(w);
    expect(await failureOf(again.pairing.openInvite(invite.inviteLink!)), PairingFailure.ownCard);
    expect((await carl.pairing.openInvite(invite.inviteLink!)).name, 'Anna');
  }, skip: _lib == null ? 'needs WFE_LEPIC_MOCK_LIB (the mock build)' : false);

  test('a request to a verified contact that allows it is paid and finalized', () async {
    final (anna, _) = await wallet(funded: 10);
    final (ben, _) = await wallet();
    final ids = await pair(ben, anna);
    await anna.pairing.setAllowInvoices(ids.bSide, true);

    final asked = await ben.pairing.requestPayment(id: ids.aSide, amount: BigInt.from(3) * _epic, message: 'order 42');
    expect(asked.pairingId, ids.aSide);
    expect(asked.payerAddress, isEmpty);

    expect((await anna.collectInvoices()).parked, 1);
    final waiting = (await anna.pendingInvoices()).single;
    expect(waiting.slateId, asked.slateId);
    expect(waiting.pairingId, ids.bSide);
    expect(waiting.amount, BigInt.from(3) * _epic);

    await expectLater(
      anna.payInvoice(slateId: asked.slateId, amount: BigInt.from(2) * _epic),
      throwsA(isA<WalletError>().having((e) => e.kind, 'kind', WalletErrorKind.amountMismatch)),
    );
    final paid = await anna.payInvoice(slateId: asked.slateId, amount: BigInt.from(3) * _epic);
    expect(paid.pairingId, ids.bSide);
    expect(await anna.pendingInvoices(), isEmpty);
    expect((await anna.paidInvoice(slateId: asked.slateId))?.pairingId, ids.bSide);

    final told = <IssuerEvent>[];
    final sub = ben.issuerEvents().listen(told.add);
    await ben.collectInvoices();
    expect(chain.pushedCount(), 1);
    final issued = (await ben.issuedInvoice(slateId: asked.slateId))!;
    expect(issued.state, IssuedInvoiceState.paid);
    expect(issued.pairingId, ids.aSide);
    // Told once, by LEPIC's event or by the catch-up, whichever came first.
    for (var i = 0; i < 25 && told.isEmpty; i++) {
      await _settle();
    }
    await sub.cancel();
    expect(told.map((e) => (e.kind, e.pairingId)), [(IssuerEventKind.paid, ids.aSide)]);
  }, skip: _lib == null ? 'needs WFE_LEPIC_MOCK_LIB (the mock build)' : false);

  test('a sealed payment file goes there and back', () async {
    final (anna, _) = await wallet(funded: 10);
    final (ben, _) = await wallet();
    final ids = await pair(anna, ben);

    final slate = await anna.createSendSlate(amount: _epic, minimumConfirmations: BigInt.one);
    final sealed = await anna.pairing.sealSlate(id: ids.aSide, slateJson: slate.json);
    expect(isSealedLepicText(sealed), isTrue);
    expect(sealed, isNot(contains(slate.slateId)));

    final opened = await ben.pairing.openSlate(sealed);
    expect(opened.sealed, isTrue);
    expect(opened.pairingId, ids.bSide);
    expect(opened.amount, _epic);
    expect(opened.purpose, SlatePurpose.payment);

    final reply = await ben.pairing.receiveSealed(sealed);
    expect(reply.sealed, isTrue);
    expect(isSealedLepicText(reply.answer), isTrue);
    final tx = await anna.pairing.finalizeSealed(reply.answer);
    expect(tx.slateId, slate.slateId);
    expect(chain.pushedCount(), 1);
    expect((await anna.pairing.slateOf(slate.slateId))?.pairingId, ids.aSide);
  }, skip: _lib == null ? 'needs WFE_LEPIC_MOCK_LIB (the mock build)' : false);

  test('a payment through a paired contact\'s mailbox needs no address, is answered and posted', () async {
    final (anna, _) = await wallet(funded: 10);
    final (ben, _) = await wallet();
    final ids = await pair(anna, ben);
    final told = <PairingEvent>[];
    final sub = anna.pairing.events().listen(told.add);

    final tx = await anna.pairing.sendViaMailbox(id: ids.aSide, amount: BigInt.from(2) * _epic, minimumConfirmations: BigInt.one, message: 'rent');
    expect(tx.kind, TxKind.sent);
    expect(tx.status, TxStatus.awaitingRecipient);
    // The mailbox is never an address.
    expect(tx.counterparty, isNull);
    expect((await anna.pairing.slateOf(tx.slateId!))?.pairingId, ids.aSide);

    for (var i = 0; i < 3 && chain.pushedCount() == 0; i++) {
      await ben.pairing.collect(trigger: PairingCollectTrigger.pull);
      await anna.pairing.collect(trigger: PairingCollectTrigger.foreground);
      await _settle();
    }
    expect(chain.pushedCount(), 1);
    for (var i = 0; i < 25 && !told.any((e) => e.kind == PairingEventKind.paymentFinalized); i++) {
      await _settle();
    }
    await sub.cancel();
    expect({for (final e in told) if (e.kind == PairingEventKind.paymentFinalized) (e.pairingId, e.slateId)}, {(ids.aSide, tx.slateId)});
    final after = (await anna.transactions(refresh: false)).firstWhere((t) => t.slateId == tx.slateId);
    expect(after.status, TxStatus.awaitingConfirmation);
    // Posted by the collect: never "not on the network" (LNX3-4).
    expect(after.repostable, isFalse);
    // Both sides name the contact by the pairing at every state (LNX3-5).
    expect(after.pairingId, ids.aSide);
    final received = (await ben.transactions(refresh: false)).firstWhere((t) => t.slateId == tx.slateId);
    expect(received.pairingId, ids.bSide);
    // Ben opened Anna's sealed payment: the pairing says when it last heard from her, the
    // pairing a contact uses is picked by it.
    final heard = (await ben.pairing.pairing(ids.bSide))!;
    expect(heard.lastSealedIn!.isAfter(heard.createdAt), isTrue);
  }, skip: _lib == null ? 'needs WFE_LEPIC_MOCK_LIB (the mock build)' : false);

  test('a mailbox payment to a pairing that is gone is refused before anything is held', () async {
    final (anna, _) = await wallet(funded: 10);
    final (ben, _) = await wallet();
    final ids = await pair(anna, ben);
    await anna.pairing.removePairing(ids.aSide);
    final before = (await anna.summary(refresh: false, minimumConfirmations: BigInt.one)).spendable;
    await expectLater(
      anna.pairing.sendViaMailbox(id: ids.aSide, amount: _epic, minimumConfirmations: BigInt.one),
      throwsA(isA<WalletError>()),
    );
    expect((await anna.summary(refresh: false, minimumConfirmations: BigInt.one)).spendable, before);
    expect((await anna.transactions(refresh: false)).where((t) => t.kind == TxKind.sent), isEmpty);
  }, skip: _lib == null ? 'needs WFE_LEPIC_MOCK_LIB (the mock build)' : false);

  test('the history backup brings the pairings back on a restored install', () async {
    final (anna, annaWallet) = await wallet();
    final (ben, _) = await wallet();
    final ids = await pair(anna, ben);
    final backup = await anna.exportHistory();

    final (restored, _) = await wallet(mnemonic: await annaWallet.mnemonic(password: _password));
    final report = await restored.importHistory(data: backup);
    expect(report.applied, isTrue);
    final back = (await restored.pairing.pairing(ids.aSide))!;
    expect(back.otherDevice, isTrue);
    expect([for (final w in back.sas) w.name], [for (final w in (await anna.pairing.pairing(ids.aSide))!.sas) w.name]);
  }, skip: _lib == null ? 'needs WFE_LEPIC_MOCK_LIB (the mock build)' : false);

  test('a re-pair after a restore folds into the old pairing: one per contact, requests reach it', () async {
    final (fred, _) = await wallet();
    final (sara, saraW) = await wallet();
    final first = await pair(fred, sara);
    await fred.pairing.attach(first.aSide, 'marta');
    // Sara's wallet restored from its phrase, without the backup, pairs with Fred again.
    final (rob, _) = await wallet(mnemonic: await saraW.mnemonic(password: _password));
    final told = <PairingEvent>[];
    final sub = fred.pairing.events().listen(told.add);
    final second = await pair(fred, rob);
    await fred.pairing.attach(second.aSide, 'marta');

    /// Fred's pairing for Marta as the contact pages pick it: the first paired one.
    Future<String?> martas() async =>
        (await fred.pairing.pairings()).where((r) => r.contactId == 'marta' && r.state.isPaired).firstOrNull?.id;

    // While the check runs, Marta's pairing stays the old one, whatever the check finds.
    expect(await martas(), first.aSide);
    expect((await fred.pairing.pairingForContact('marta'))?.id, first.aSide);

    await rob.pairing.collect(trigger: PairingCollectTrigger.pull);
    await fred.pairing.collect(trigger: PairingCollectTrigger.pull);
    await _settle();
    expect([for (final e in told) if (e.kind == PairingEventKind.keysRestored) e.pairingId], [first.aSide]);
    // The engine keeps the folded pairing until its last message is out; it is never listed.
    expect([for (final r in await fred.pairing.pairings()) if (r.contactId == 'marta') r.id], [first.aSide]);
    expect((await fred.pairing.pairingForContact('marta'))?.id, first.aSide);

    // It goes a collect later, with no event of the engine's: the lists are told to read again.
    told.clear();
    for (var i = 0; i < 3; i++) {
      await rob.pairing.collect(trigger: PairingCollectTrigger.pull);
      await fred.pairing.collect(trigger: PairingCollectTrigger.pull);
    }
    await _settle();
    expect(told.map((e) => e.kind), contains(PairingEventKind.contactUpdated));
    expect([for (final r in await fred.pairing.pairings()) r.id], [first.aSide]);
    expect(await rob.pairing.pairings(), hasLength(1));

    final asked = await fred.pairing.requestPayment(id: (await martas())!, amount: _epic);
    expect(asked.pairingId, first.aSide);
    await sub.cancel();
  }, skip: _lib == null ? 'needs WFE_LEPIC_MOCK_LIB (the mock build)' : false);
}
