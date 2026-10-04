// History on LEPIC against the old core, in one process (H-01): files the old core wrote open
// on LEPIC and show the same list, files LEPIC writes open on the old core, and the import
// rules of simple_test.dart's history test hold on LEPIC.
//
//   tools/lepic.sh build linux
//   xvfb-run -a flutter test integration_test/history_test.dart -d linux
//
// Offline: the node is a closed port. The phrase is a public BIP-39 test vector; never fund
// it, never print a phrase or password. With
// --dart-define=WFE_HISTORY_FIXTURES=<absolute dir> it also writes the old core's files there,
// which is how test/history/fixtures/ was made.
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/rust/frb_generated.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _unreachableNode = 'http://127.0.0.1:9';
const _password = 'history test password';
const _fixturesOut = String.fromEnvironment('WFE_HISTORY_FIXTURES');

/// The committed files of the old core, relative to `app/`.
const _fixtureMeta = 'test/history/fixtures/old_core_meta.json';
const _fixtureFile = 'test/history/fixtures/old_core.wfeh';

final _phrase = '${List.filled(23, 'abandon').join(' ')} art';

final _dirs = <Directory>[];

Future<WalletConfig> _config() async {
  final base = await getTemporaryDirectory();
  final dir = await base.createTemp('wfe-history-');
  _dirs.add(dir);
  return mainnetPreset.config(dataDir: dir.path, nodeUrl: _unreachableNode);
}

const _old = RustWalletService();
final _lepic = LepicWalletService(secrets: MemorySecretStore());

/// What the history screen shows of a row, comparable across cores.
String _row(TxEntry t) => [
  t.key,
  t.id == null ? 'imported' : 'live',
  t.slateId,
  t.kind.name,
  t.status.name,
  t.source.name,
  t.createdAtUnix,
  t.timeUnix,
  t.confirmed,
  t.blockHeight,
  t.blockTimeUnix,
  t.amountCredited,
  t.amountDebited,
  t.fee,
  t.numInputs,
  t.numOutputs,
  t.kernelExcess,
  t.outputCommits.join('+'),
  t.counterparty,
  t.note,
  t.ttlCutoffHeight,
  t.statusDetail,
  t.cancelReason?.name,
].join('|');

Future<List<String>> _rows(WalletSession s) async => [
  for (final t in await s.transactions(refresh: false)) _row(t),
];

Record _rec(
  String kind,
  String status, {
  String? slate,
  String? kernel,
  List<String> commits = const [],
  int created = 1780000000,
  int credited = 0,
  int debited = 0,
  int? fee,
  int? height,
  String? counterparty,
  String? note,
  String? cancelReason,
}) => Record(
  slateId: slate,
  kernelExcess: kernel,
  kernelLookupMinHeight: kernel == null ? null : BigInt.from(2000000),
  kind: kind,
  status: status,
  confirmed: status == 'Confirmed',
  createdAtUnix: created,
  blockHeight: height == null ? null : BigInt.from(height),
  amountCredited: BigInt.from(credited),
  amountDebited: BigInt.from(debited),
  fee: fee == null ? null : BigInt.from(fee),
  numInputs: debited > 0 ? 1 : 0,
  numOutputs: 1,
  outputCommits: [...commits],
  counterparty: counterparty,
  note: note,
  ttlCutoffHeight: BigInt.from(2020160),
  cancelReason: cancelReason,
);

/// An archive with one of each kind of row a history file carries.
Meta _seed() => Meta(
  contacts: [
    ContactRec(id: 'c1', name: 'Bob', address: 'bob@relay.example'),
    ContactRec(
      id: 'c2',
      name: 'Alice',
      address: 'alice@relay.example',
      note: 'shop',
    ),
  ],
  records: [
    _rec(
      'Sent',
      'Confirmed',
      slate: '0b0c3f1e-0000-4000-8000-000000000001',
      kernel: '08${'a' * 64}',
      debited: 300000000,
      credited: 99200000,
      fee: 800000,
      height: 2000100,
      counterparty: 'bob@relay.example',
      note: 'rent',
    ),
    _rec(
      'Received',
      'Confirmed',
      kernel: '09${'b' * 64}',
      commits: ['08${'c' * 64}'],
      credited: 500000000,
      height: 2000050,
      created: 1779990000,
    ),
    _rec(
      'Sent',
      'AwaitingConfirmation',
      slate: '0b0c3f1e-0000-4000-8000-000000000002',
      kernel: '08${'d' * 64}',
      debited: 100000000,
      credited: 0,
      fee: 700000,
      created: 1780000100,
    ),
    _rec(
      'SentCancelled',
      'Cancelled',
      slate: '0b0c3f1e-0000-4000-8000-000000000003',
      debited: 50000000,
      fee: 700000,
      created: 1780000200,
      cancelReason: 'late_answer',
      note: 'too late',
    ),
    _rec(
      'Received',
      'AwaitingRecipient',
      slate: '0b0c3f1e-0000-4000-8000-000000000004',
      credited: 10000000,
      created: 1780000300,
    ),
  ],
);

/// A LEPIC wallet on [_phrase], with [meta] as its archive before it opens.
Future<WalletSession> _lepicWallet({Meta? meta, String? metaText}) async {
  final config = await _config();
  if (meta != null || metaText != null) {
    File('${config.dataDir}/$metaFileName')
        .writeAsStringSync(metaText ?? encodeJson(meta!.toJson()));
  }
  return _lepic.create(config: config, mnemonic: _phrase, password: _password);
}

Matcher _historyError(String text) => throwsA(
  isA<WalletError>()
      .having((e) => e.kind, 'kind', WalletErrorKind.invalidArgument)
      .having((e) => e.message, 'message', contains(text)),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
    await initLepic();
  });
  tearDownAll(() async {
    for (final d in _dirs) {
      if (d.existsSync()) await d.delete(recursive: true);
    }
  });

  testWidgets('files of each core open on the other and show the same list', (
    tester,
  ) async {
    // LEPIC writes a file from a seeded archive; the old core imports it.
    final seeded = await _lepicWallet(meta: _seed());
    final fromLepic = await seeded.exportHistory();
    expect(String.fromCharCodes(fromLepic.take(4)), 'WFEH');
    seeded.dispose();

    final oldConfig = await _config();
    final old = await _old.create(
      config: oldConfig,
      mnemonic: _phrase,
      password: _password,
    );
    final List<String> oldRows;
    final String oldCsv;
    final Uint8List fromOld;
    try {
      final report = await old.importHistory(data: fromLepic);
      expect(
        (report.added, report.merged, report.skipped, report.contactsAdded),
        (5, 0, 0, 2),
      );
      final rows = await old.transactions(refresh: false);
      expect(rows, hasLength(5));
      // Edits on the old core: a note on an imported row, a contact.
      final received = rows.firstWhere((t) => t.kind == TxKind.received);
      await old.setTxNote(key: received.key, note: 'salary');
      await old.saveContact(
        contact: const Contact(id: '', name: 'Carol', address: 'carol@relay'),
      );
      oldRows = await _rows(old);
      oldCsv = await old.exportHistoryCsv();
      fromOld = await old.exportHistory();
    } finally {
      old.dispose();
    }
    final oldMeta = File('${oldConfig.dataDir}/$metaFileName')
        .readAsStringSync();
    if (_fixturesOut.isNotEmpty) {
      File('$_fixturesOut/old_core_meta.json').writeAsStringSync(oldMeta);
      File('$_fixturesOut/old_core.wfeh').writeAsBytesSync(fromOld);
    }

    // The old core's archive, under a LEPIC wallet.
    final withMeta = await _lepicWallet(metaText: oldMeta);
    try {
      expect(await _rows(withMeta), oldRows);
      expect(await withMeta.exportHistoryCsv(), oldCsv);
      expect((await withMeta.contacts()).map((c) => c.name), [
        'Alice',
        'Bob',
        'Carol',
      ]);
    } finally {
      withMeta.dispose();
    }

    // The old core's file, imported on LEPIC, twice.
    final imported = await _lepicWallet();
    try {
      final first = await imported.importHistory(data: fromOld);
      expect(
        (first.added, first.merged, first.skipped, first.contactsAdded),
        (5, 0, 0, 3),
      );
      expect(await _rows(imported), oldRows);
      final again = await imported.importHistory(data: fromOld);
      expect(
        (again.added, again.merged, again.skipped, again.contactsAdded),
        (0, 0, 5, 0),
      );
      expect(await _rows(imported), oldRows);
    } finally {
      imported.dispose();
    }
  });

  testWidgets('the committed files of the old core open on LEPIC', (
    tester,
  ) async {
    final meta = File(_fixtureMeta).readAsStringSync();
    final file = File(_fixtureFile).readAsBytesSync();
    final withMeta = await _lepicWallet(metaText: meta);
    final List<String> rows;
    try {
      rows = await _rows(withMeta);
      expect(rows, hasLength(5));
      final shown = await withMeta.transactions(refresh: false);
      expect(shown.map((t) => t.note).whereType<String>().toSet(), {
        'rent',
        'salary',
        'too late',
      });
    } finally {
      withMeta.dispose();
    }
    final imported = await _lepicWallet();
    try {
      final report = await imported.importHistory(data: file);
      expect((report.added, report.contactsAdded), (5, 3));
      expect(await _rows(imported), rows);
    } finally {
      imported.dispose();
    }
  });

  // simple_test.dart's history test, on LEPIC.
  testWidgets('history: contacts and an export that only the same seed opens', (
    tester,
  ) async {
    final a = await _lepicWallet();
    final saved = await a.saveContact(
      contact: const Contact(id: '', name: 'Bob', address: 'bob@relay.example'),
    );
    expect(saved.id, isNotEmpty);
    final file = await a.exportHistory();
    expect(String.fromCharCodes(file.take(4)), 'WFEH');
    a.dispose();

    final b = await _lepicWallet();
    addTearDown(b.dispose);
    final report = await b.importHistory(data: file);
    expect(report.contactsAdded, 1);
    expect((await b.importHistory(data: file)).contactsAdded, 0);
    expect((await b.contacts()).single.name, 'Bob');

    final c = await _lepic.create(config: await _config(), password: _password);
    addTearDown(c.dispose);
    await expectLater(
      c.importHistory(data: file),
      _historyError('different wallet'),
    );

    final damaged = Uint8List.fromList(file)..[file.length - 1] ^= 1;
    await expectLater(
      b.importHistory(data: damaged),
      _historyError('This history file is damaged'),
    );
    await expectLater(
      b.importHistory(data: Uint8List.fromList('not a file'.codeUnits)),
      _historyError('This is not a history file'),
    );
  });

  testWidgets('a deleted wallet takes its archive with it', (tester) async {
    final config = await _config();
    final w = await _lepic.create(
      config: config,
      mnemonic: _phrase,
      password: _password,
    );
    await w.saveContact(
      contact: const Contact(id: '', name: 'Bob', address: 'bob@relay'),
    );
    final meta = File('${config.dataDir}/$metaFileName');
    expect(meta.existsSync(), isTrue);
    w.dispose();
    await _lepic.deleteWallet(config: config);
    expect(meta.existsSync(), isFalse);
    // A late call on the closed session never brings it back.
    await expectLater(
      w.saveContact(
        contact: const Contact(id: '', name: 'Late', address: 'late@relay'),
      ),
      throwsA(isA<WalletError>()),
    );
    expect(meta.existsSync(), isFalse);
  });
}
