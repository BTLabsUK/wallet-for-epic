// History on LEPIC (H-01): the archive and history file the old epic-wallet core wrote
// (test/history/fixtures/, made before that core was removed) open and show the same list, and
// the import rules hold.
//
//   tools/lepic.sh build linux
//   xvfb-run -a flutter test integration_test/history_test.dart -d linux
//
// Offline: the node is a closed port. The phrase is a public BIP-39 test vector; never fund
// it, never print a phrase or password.
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _unreachableNode = 'http://127.0.0.1:9';
const _password = 'history test password';

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
    await initLepic();
  });
  tearDownAll(() async {
    for (final d in _dirs) {
      if (d.existsSync()) await d.delete(recursive: true);
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
    // The fixtures are files of this checkout, which a device does not have.
  }, skip: !Platform.isLinux);

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

  testWidgets(
    'a new wallet in a deleted wallet directory starts with no history',
    (tester) async {
      final config = await _config();
      final first = await _lepic.create(
        config: config,
        mnemonic: _phrase,
        password: _password,
      );
      await first.saveContact(
        contact: const Contact(id: '', name: 'Bob', address: 'bob@relay'),
      );
      final live = await first.transactions(refresh: false);
      expect(live, isEmpty);
      await first.setTxNote(key: 's:gone', note: 'kept by the old wallet');
      first.dispose();
      // A damaged copy moved aside earlier holds notes too.
      final aside = File('${config.dataDir}/$metaFileName.corrupt-1')
        ..writeAsStringSync('{"notes":{"s:x":"old"}');

      await _lepic.deleteWallet(config: config);
      expect(File('${config.dataDir}/$metaFileName').existsSync(), isFalse);
      expect(aside.existsSync(), isFalse);

      final second = await _lepic.create(config: config, password: _password);
      addTearDown(second.dispose);
      expect(await second.contacts(), isEmpty);
      expect(await second.transactions(refresh: false), isEmpty);
    },
  );
}
