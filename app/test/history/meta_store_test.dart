// The archive file: format, atomic writes, damaged and newer files. Ported from the tests in
// app/rust/src/core/meta.rs.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/app_log.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('wfe-meta-'));
  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  File metaFile() => File('${dir.path}/$metaFileName');

  List<String> corruptCopies() =>
      dir
          .listSync()
          .whereType<File>()
          .where(
            (f) => f.uri.pathSegments.last.startsWith('$metaFileName.corrupt-'),
          )
          .map((f) => f.readAsStringSync())
          .toList()
        ..sort();

  test('round trips and writes atomically', () async {
    final store = await MetaStore.open(dir.path);
    expect(store.snapshot.notes, isEmpty);
    expect(metaFile().existsSync(), isFalse, reason: 'nothing written yet');

    await store.update((m) {
      m.notes['s:abc'] = 'rent';
      m.contacts.add(ContactRec(id: '1', name: 'Bob', address: 'addr'));
      m.blockTimes['10'] = 1790000000;
    });
    expect(File('${dir.path}/wfe_meta.tmp').existsSync(), isFalse);

    final reopened = await MetaStore.open(dir.path);
    expect(reopened.snapshot.notes['s:abc'], 'rent');
    expect(
      encodeJson(reopened.snapshot.toJson()),
      encodeJson(store.snapshot.toJson()),
    );
    // Compact, in the field order serde writes.
    expect(
      metaFile().readAsStringSync(),
      '{"version":1,"notes":{"s:abc":"rent"},"contacts":[{"id":"1","name":"Bob",'
      '"address":"addr"}],"annotations":{},"records":[],'
      '"block_times":{"10":1790000000},"kernel_heights":{}}',
    );
  });

  test('a write never recreates a deleted wallet directory', () async {
    final walletDir = Directory('${dir.path}/wallet')..createSync();
    final store = await MetaStore.open(walletDir.path);
    walletDir.deleteSync(recursive: true);
    await expectLater(
      store.update((m) => m.notes['k'] = 'v'),
      throwsA(isA<WalletError>()),
    );
    expect(walletDir.existsSync(), isFalse);
  });

  test('a delete stops the late writes of a store still open', () async {
    final store = await MetaStore.open(dir.path);
    await store.update((m) => m.notes['k'] = 'v');
    expect(metaFile().existsSync(), isTrue);
    await MetaStore.deleteFiles(dir.path);
    expect(metaFile().existsSync(), isFalse);
    await expectLater(
      store.update((m) => m.notes['k'] = 'w'),
      throwsA(
        isA<WalletError>().having((e) => e.kind, 'kind', WalletErrorKind.io),
      ),
    );
    expect(metaFile().existsSync(), isFalse);
    // A wallet made again in the same directory writes as before.
    final next = await MetaStore.open(dir.path);
    await next.update((m) => m.notes['k'] = 'x');
    expect(metaFile().existsSync(), isTrue);
  });

  test('a delete removes the damaged copies and leaves other files', () async {
    metaFile().writeAsStringSync('{ not json');
    await MetaStore.open(dir.path);
    final store = await MetaStore.open(dir.path);
    await store.update((m) => m.notes['k'] = 'v');
    File('${dir.path}/wfe_meta.tmp').writeAsStringSync('half');
    final other = File('${dir.path}/keep.json')..writeAsStringSync('{}');
    expect(corruptCopies(), hasLength(1));
    await MetaStore.deleteFiles(dir.path);
    expect(corruptCopies(), isEmpty);
    expect(metaFile().existsSync(), isFalse);
    expect(File('${dir.path}/wfe_meta.tmp').existsSync(), isFalse);
    expect(other.existsSync(), isTrue);
    // A directory that is already gone is nothing to delete.
    await MetaStore.deleteFiles('${dir.path}/missing');
  });

  test('a failed update changes nothing', () async {
    final store = await MetaStore.open(dir.path);
    await expectLater(
      store.update((m) {
        m.notes['k'] = 'v';
        throw StateError('no');
      }),
      throwsStateError,
    );
    expect(store.snapshot.notes, isEmpty);
    expect(metaFile().existsSync(), isFalse);
    // The queue goes on after a failure.
    await store.update((m) => m.notes['k'] = 'v');
    expect(store.snapshot.notes['k'], 'v');
  });

  test('updates run one at a time, in order', () async {
    final store = await MetaStore.open(dir.path);
    await Future.wait([
      for (var i = 0; i < 20; i++) store.update((m) => m.notes['n$i'] = '$i'),
    ]);
    final reopened = await MetaStore.open(dir.path);
    expect(reopened.snapshot.notes, hasLength(20));
  });

  test('an unreadable file is moved aside, not lost', () async {
    metaFile().writeAsStringSync('{ not json');
    final store = await MetaStore.open(dir.path);
    expect(store.snapshot.notes, isEmpty);
    expect(corruptCopies(), ['{ not json']);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    // Valid JSON of the wrong shape is damaged too.
    metaFile().writeAsStringSync('{"notes":["a"]}');
    await MetaStore.open(dir.path);
    expect(corruptCopies(), [
      '{ not json',
      '{"notes":["a"]}',
    ], reason: 'the first damaged copy is kept');
  });

  test('a damaged file is logged without its contents', () async {
    const secret = 'rent to carol';
    final damaged = [
      '{"notes":{"s:1":"$secret"},x',
      '{"notes":{"s:1":"$secret"},"contacts":"$secret"}',
      '{"notes":{"s:1":"$secret"}',
    ];
    for (final text in damaged) {
      AppLog.use(MemoryLogSink());
      metaFile().writeAsStringSync(text);
      await MetaStore.open(dir.path);
      final log = await AppLog.sink.tail(1 << 16);
      expect(log, contains('$metaFileName is unreadable'), reason: text);
      expect(log, isNot(contains(secret)), reason: text);
    }
    // Bytes that are not UTF-8 are named by position only too.
    AppLog.use(MemoryLogSink());
    metaFile().writeAsBytesSync([...utf8.encode('{"notes":{"$secret'), 0xff]);
    await MetaStore.open(dir.path);
    expect(await AppLog.sink.tail(1 << 16), isNot(contains(secret)));
  });

  test('a newer file version is read but never rewritten', () async {
    const text = '{"version":99,"notes":{"a":"b"},"future_field":[1]}';
    metaFile().writeAsStringSync(text);
    final store = await MetaStore.open(dir.path);
    expect(store.snapshot.notes['a'], 'b', reason: 'still readable');
    await expectLater(
      store.update((m) => m.notes.clear()),
      throwsA(
        isA<WalletError>().having(
          (e) => e.message,
          'message',
          contains('newer version'),
        ),
      ),
    );
    expect(metaFile().readAsStringSync(), text);
  });

  test('older files without the newer fields still load', () async {
    metaFile().writeAsStringSync('{"notes":{"l:1":"x"}}');
    final store = await MetaStore.open(dir.path);
    expect(store.snapshot.notes['l:1'], 'x');
    expect(store.snapshot.version, metaVersion);
  });

  test('every field the old core writes survives a rewrite', () async {
    final text = jsonEncode({
      'version': 1,
      'notes': {'s:a': 'n'},
      'contacts': [
        {'id': 'c', 'name': 'N', 'address': 'x@y', 'note': 'z'},
      ],
      'annotations': {
        'slate': {
          'counterparty': 'x@y',
          'finalized': true,
          'kernel_excess': '08ab',
          'finalized_at_unix': 5,
          'finalized_height': 6,
          'post_error': 'e',
          'post_refused': true,
          'cancelled_by': 'user',
          'kernel_absent_at': 7,
        },
      },
      'records': [
        {
          'slate_id': 's',
          'kernel_excess': 'k',
          'kernel_lookup_min_height': 1,
          'kind': 'Sent',
          'status': 'Confirmed',
          'confirmed': true,
          'created_at_unix': 2,
          'block_height': 3,
          'block_time_unix': 4,
          'amount_credited': 5,
          'amount_debited': 6,
          'fee': 7,
          'num_inputs': 1,
          'num_outputs': 2,
          'output_commits': ['c1'],
          'counterparty': 'x@y',
          'note': 'n',
          'ttl_cutoff_height': 9,
          'messages': {
            'messages': [
              {'id': '0', 'public_key': 'pk'},
            ],
          },
          'payment_proof': {'sender_address': 'a'},
          'status_detail': 'd',
          'cancel_reason': 'user',
          'exported_at_unix': 10,
        },
      ],
      'block_times': {'2': 1, '10': 2},
      'kernel_heights': {'k': 3},
      'block_time_misses': {'5': 100},
      'cache_node': 'https://node',
    });
    metaFile().writeAsStringSync(text);
    final store = await MetaStore.open(dir.path);
    await store.update((m) => m.notes['s:b'] = 'second');
    final back = jsonDecode(metaFile().readAsStringSync()) as Map;
    final want = jsonDecode(text) as Map;
    (want['notes'] as Map)['s:b'] = 'second';
    expect(back, want);
  });

  test('u64 values above 2^63-1 are kept as digits', () {
    final big = BigInt.parse('18446744073709551615');
    final r = Record(kind: 'Sent', status: 'Confirmed', amountCredited: big);
    final text = encodeJson(r.toJson());
    expect(text, contains('"amount_credited":18446744073709551615'));
    // Dart reads it back as a rounded double: the largest u64, never an error.
    expect(Record.fromJson(jsonDecode(text)).amountCredited, big);
    expect(
      () => Record.fromJson({...r.toJson(), 'amount_debited': 1e20}),
      throwsA(isA<MetaFormatException>()),
    );
    expect(
      () => Record.fromJson({...r.toJson(), 'amount_debited': -1}),
      throwsA(isA<MetaFormatException>()),
    );
  });

  group('records', () {
    Record rec(String status, int exported) => Record(
      slateId: 's',
      kind: 'Sent',
      status: status,
      exportedAtUnix: exported,
    );

    test('a later import fills gaps and updates the status when newer', () {
      final stored = rec('AwaitingRecipient', 100);
      expect(stored.mergeFrom(stored.copy()), isFalse);

      final later = rec('Confirmed', 200)
        ..confirmed = true
        ..note = 'rent'
        ..fee = BigInt.from(7)
        ..blockHeight = BigInt.from(9)
        ..outputCommits = ['c'];
      expect(stored.mergeFrom(later), isTrue);
      expect(stored.status, 'Confirmed');
      expect(stored.confirmed, isTrue);
      expect(stored.note, 'rent');
      expect(stored.fee, BigInt.from(7));
      expect(stored.blockHeight, BigInt.from(9));
      expect(stored.outputCommits, ['c']);
      expect(stored.exportedAtUnix, 200);

      // A newer file's edited note replaces the stored one.
      expect(
        stored.mergeFrom(rec('Confirmed', 250)..note = 'rent, March'),
        isTrue,
      );
      expect(stored.note, 'rent, March');

      // An older file fills gaps but never changes the status or an existing note.
      final older = rec('AwaitingRecipient', 50)
        ..note = 'old note'
        ..counterparty = 'bob';
      expect(stored.mergeFrom(older), isTrue);
      expect(stored.status, 'Confirmed');
      expect(stored.note, 'rent, March');
      expect(stored.counterparty, 'bob');

      // A newer file that is still pending does not undo a settled status.
      final stale = rec('AwaitingConfirmation', 300)..note = 'rent, March';
      expect(stored.mergeFrom(stale), isFalse);
      expect(stored.status, 'Confirmed');
    });

    test('the same transaction by slate, kernel or created output', () {
      Record r({String? slate, String? kernel, List<String>? commits}) =>
          Record(
            slateId: slate,
            kernelExcess: kernel,
            outputCommits: commits,
            kind: 'Sent',
            status: 'Confirmed',
          );
      expect(r(slate: 'a').sameTx(r(slate: 'a')), isTrue);
      expect(r(kernel: 'k').sameTx(r(slate: 'a', kernel: 'k')), isTrue);
      expect(r(commits: ['x', 'y']).sameTx(r(commits: ['y'])), isTrue);
      expect(r(slate: 'a').sameTx(r(slate: 'b')), isFalse);
      expect(r().sameTx(r()), isFalse, reason: 'nothing to match by');
    });

    test('a record without its required fields is damaged', () {
      expect(
        () => Record.fromJson({'kind': 'Sent', 'status': 'Confirmed'}),
        throwsA(isA<MetaFormatException>()),
      );
    });
  });
}
