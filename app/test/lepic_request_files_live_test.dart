// Live: payment requests by file (DESIGN §3) through the app's LEPIC adapter on the real
// library, with LEPIC's mock chain: a request saved as a file, read as a request, paid by
// another wallet for its signed amount only, and its answer finished and posted by the issuer;
// a second payment and a stray answer are refused. Needs LEPIC's mock build of the Linux
// library, as test/lepic_pairing_live_test.dart says:
//
//   WFE_LEPIC_MOCK_LIB="$OUT/x86_64-unknown-linux-gnu/liblepic_ffi.so" \
//     flutter test test/lepic_request_files_live_test.dart
//
// Without it it is skipped.
import 'dart:io';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

final String? _lib = Platform.environment['WFE_LEPIC_MOCK_LIB'];

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
    root = Directory.systemTemp.createTempSync('wfe-request-files-live-');
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
  Future<LepicWalletSession> wallet({int funded = 0}) async {
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

  Future<SlateInfo> inspect(String json) async =>
      lepicSlateInfo(await lepic.inspectSlate(json: json, chain: lepic.Chain.floonet));

  test('a request file is issued, paid for its amount only, and its answer finished by the issuer', () async {
    final ben = await wallet();
    final anna = await wallet(funded: 10);
    expect(ben.supportsRequestFiles, isTrue);

    final slate = await ben.pairing.requestFile(amount: BigInt.from(3) * _epic, message: 'beans \u202E 42');
    final issued = (await ben.issuedInvoices()).singleWhere((i) => i.slateId == slate.slateId);
    expect(issued.state, IssuedInvoiceState.waiting);
    expect(issued.byFile, isTrue, reason: 'no payer, no pairing: Requests sent reads By file');

    final request = await inspect(slate.json);
    expect(request.stage, SlateStage.request);
    expect(request.slateId, slate.slateId);
    expect(request.amount, BigInt.from(3) * _epic);
    // The issuer's message is the receiver's; the screens clean it before they show it.
    expect(messageBy(request.messages, SlateRole.receiver), contains('beans'));

    await expectLater(
      anna.payRequestFile(slateJson: slate.json, amount: BigInt.from(2) * _epic),
      throwsA(isA<WalletError>().having((e) => e.kind, 'kind', WalletErrorKind.amountMismatch)),
    );
    final paid = await anna.payRequestFile(slateJson: slate.json, amount: BigInt.from(3) * _epic);
    expect(paid.slateId, slate.slateId);
    expect(paid.amount, BigInt.from(3) * _epic);
    expect(paid.fee, greaterThan(BigInt.zero));
    final sent = (await anna.transactions(refresh: false)).singleWhere((t) => t.slateId == slate.slateId);
    expect(sent.kind, TxKind.sent);

    await expectLater(
      anna.payRequestFile(slateJson: slate.json, amount: BigInt.from(3) * _epic),
      throwsA(isA<WalletError>().having((e) => e.kind, 'kind', WalletErrorKind.invoiceAlreadyPaid)),
    );

    final answer = await inspect(paid.json);
    expect(answer.stage, SlateStage.requestAnswer);
    expect(answer.slateId, slate.slateId);

    // A wallet that did not issue it cannot finish it.
    final other = await wallet();
    await expectLater(other.finalizeAndPost(slateJson: paid.json), throwsA(isA<WalletError>()));

    final posted = await ben.finalizeAndPost(slateJson: paid.json);
    expect(posted.slateId, slate.slateId);
    final after = (await ben.issuedInvoices()).singleWhere((i) => i.slateId == slate.slateId);
    expect(after.state, IssuedInvoiceState.paid);
    // The same answer again pays nothing twice: LEPIC answers with the same transaction (the
    // screens say "already paid" before they get here).
    final again = await ben.finalizeAndPost(slateJson: paid.json);
    expect(again.slateId, slate.slateId);
    expect((await ben.issuedInvoices()).where((i) => i.slateId == slate.slateId).single.state, IssuedInvoiceState.paid);
  }, skip: _lib == null ? 'needs WFE_LEPIC_MOCK_LIB (the mock build)' : false);
}
