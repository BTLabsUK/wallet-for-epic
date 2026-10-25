// Live: pairing (RFC 0002) through the app's LEPIC adapter on the real library, with LEPIC's
// mock chain and mock relay: an invite answered and its words checked, in person by cards,
// a request to a verified contact paid and finalized, a sealed payment file there and back,
// and the pairings carried by the history backup to a restored install. Needs the Linux
// library:
//
//   WFE_DEMO_LEPIC_LIB=$PWD/third_party/lepic-flutter/native/x86_64-unknown-linux-gnu/liblepic_ffi.so \
//   flutter test test/lepic_pairing_live_test.dart
//
// Without it it is skipped.
import 'dart:io';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

final String? _lib = Platform.environment['WFE_DEMO_LEPIC_LIB'];

/// A built-in floonet relay, so pairing words are offered; the mock relay serves it.
const _relay = 'flooepicbox.btlabs.uk';
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
  late lepic.MockChain chain;
  late lepic.LepicRuntime runtime;
  final open = <LepicWalletSession>[];
  var made = 0;

  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
  });

  setUp(() {
    root = Directory.systemTemp.createTempSync('wfe-pairing-live-');
    chain = lepic.MockChain(height: BigInt.one);
    runtime = chain.runtimeWithRelay(
      logLevel: lepic.LogLevel.warn,
      relay: lepic.MockRelay(chain: lepic.Chain.floonet),
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
      config: lepic.WalletConfig(
        dataDir: (Directory('${root.path}/w$made')..createSync()).path,
        chain: lepic.Chain.floonet,
        nodeUrl: 'http://127.0.0.1:1',
        epicboxDomain: _relay,
        epicboxPort: 443,
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
    final invite = await a.pairing.makeInvite(name: 'Anna', expiry: const Duration(days: 1));
    expect(invite.state, PairingState.pendingInvite);
    expect(invite.inviteLink, startsWith('epiccash://pair/1/'));
    final preview = await b.pairing.openInvite(invite.inviteLink!);
    expect(preview.name, 'Anna');
    final answer = await b.pairing.acceptInvite(token: preview.token, name: 'Ben');
    expect(answer.state, PairingState.pendingReply);
    await a.pairing.collect(trigger: PairingCollectTrigger.open);
    await b.pairing.collect(trigger: PairingCollectTrigger.pull);
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
    // The mailbox is never an address to show (RFC C-21).
    expect(pairings.single.paymentsAddress, isNull);
    expect(pairings.single.seals, isTrue);
    await anna.pairing.removePairing(ids.aSide);
    expect(await anna.pairing.pairings(), isEmpty);
  }, skip: _lib == null ? 'needs WFE_DEMO_LEPIC_LIB' : false);

  test('two phones pair in person by their cards, with no relay', () async {
    final (anna, _) = await wallet();
    final (carl, _) = await wallet();
    final annaCard = await anna.pairing.showCard(name: 'Anna');
    final carlCard = await carl.pairing.showCard(name: 'Carl');
    final a = await anna.pairing.scanCard(cardId: annaCard.id, text: carlCard.link);
    final c = await carl.pairing.scanCard(cardId: carlCard.id, text: annaCard.link);
    expect(a.name, 'Carl');
    expect(c.name, 'Anna');
    expect([for (final w in a.sas) w.name], [for (final w in c.sas) w.name]);
  }, skip: _lib == null ? 'needs WFE_DEMO_LEPIC_LIB' : false);

  test('a request to a verified contact that allows it is paid and finalized', () async {
    final (anna, _) = await wallet(funded: 10);
    final (ben, _) = await wallet();
    final ids = await pair(ben, anna);
    await anna.pairing.setAllowInvoices(ids.bSide, true);

    final asked = await ben.pairing.requestPayment(id: ids.aSide, amount: BigInt.from(3) * _epic, message: 'order 42');
    expect(asked.pairingId, ids.aSide);
    expect(asked.payerAddress, isEmpty);

    expect((await anna.drainInvoices()).parked, 1);
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
    await ben.drainInvoices();
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
  }, skip: _lib == null ? 'needs WFE_DEMO_LEPIC_LIB' : false);

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
  }, skip: _lib == null ? 'needs WFE_DEMO_LEPIC_LIB' : false);

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
  }, skip: _lib == null ? 'needs WFE_DEMO_LEPIC_LIB' : false);
}
