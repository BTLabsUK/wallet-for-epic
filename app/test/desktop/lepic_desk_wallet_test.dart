// LepicDeskWallet on FakeWalletService: the desktop UI's adapter over the wallet core. The
// passwords and phrases here are throwaway test values.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/desktop/app/screens.dart';
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/network.dart' show floonetPreset;
import 'package:epic_wallet/src/desktop/data/phrase_check.dart' show phraseFingerprint;
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/network.dart' show defaultEpicboxHost;
import 'package:epic_wallet/src/wallet_registry.dart' as reg;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'advanced_on.dart';

const _password = 'test-pass-1234';

/// Throws [core.WalletErrorKind.damagedDatabase] on the first open, as LEPIC does once it has
/// set a damaged database aside.
class _DamagedOnce extends core.FakeWalletService {
  _DamagedOnce() : super(password: _password);

  bool damaged = true;

  @override
  Future<core.WalletSession> open({required core.WalletConfig config, required String password}) async {
    if (damaged) {
      damaged = false;
      throw const core.WalletError(kind: core.WalletErrorKind.damagedDatabase, message: 'moved aside');
    }
    return super.open(config: config, password: password);
  }
}

/// Checks the password on [mnemonic], as LEPIC does.
class _StrictSession extends core.FakeWalletSession {
  @override
  Future<String> mnemonic({required String password}) async {
    if (password != _password) throw const core.WalletError(kind: core.WalletErrorKind.wrongPassword, message: 'wrong');
    return phrase;
  }
}

/// A session whose refresh waits at [gate] before its last step, and that fails any call once
/// disposed, as LEPIC's handle does after a lock.
class _HeldRefresh extends _StrictSession {
  Completer<void>? gate;
  bool disposed = false;

  @override
  Stream<core.RefreshProgress> refresh({required BigInt minimumConfirmations}) async* {
    await gate?.future;
    yield* super.refresh(minimumConfirmations: minimumConfirmations);
  }

  @override
  Future<List<core.TxEntry>> transactions({required bool refresh}) async {
    if (disposed) throw StateError('RustArc disposed');
    return super.transactions(refresh: refresh);
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

/// Holds every split at [gate] until it is completed: a payment under way.
class _SlowSplit extends _StrictSession {
  Completer<void>? gate;

  @override
  Future<core.SelfSentTx> splitOutputs({required int outputs, required BigInt minimumConfirmations}) async {
    await gate?.future;
    return super.splitOutputs(outputs: outputs, minimumConfirmations: minimumConfirmations);
  }
}

/// Opens like LEPIC, except: a config [refuse] picks fails, and [gate] holds every open.
class _Opens extends core.FakeWalletService {
  _Opens() : super(password: _password, session: _StrictSession());

  bool Function(core.WalletConfig config)? refuse;
  Completer<void>? gate;

  @override
  Future<core.WalletSession> open({required core.WalletConfig config, required String password}) async {
    await gate?.future;
    if (refuse?.call(config) ?? false) throw const core.WalletError(kind: core.WalletErrorKind.io, message: 'locked by another process');
    return super.open(config: config, password: password);
  }
}

/// Accepts a second phrase besides [phrase], as LEPIC accepts any valid one.
class _TwoPhrases extends core.FakeWalletService {
  _TwoPhrases({core.FakeWalletSession? session}) : super(password: _password, session: session ?? _StrictSession());

  static const other = 'legal winner thank year wave sausage worth useful legal winner thank yellow';

  int creates = 0;

  @override
  bool validateMnemonic({required String phrase}) => phrase == this.phrase || phrase == other;

  @override
  Future<core.WalletSession> create({required core.WalletConfig config, String? mnemonic, required String password}) {
    creates++;
    return super.create(config: config, mnemonic: mnemonic, password: password);
  }
}

/// Records every config [open] was given.
class _Recording extends _TwoPhrases {
  _Recording();

  final List<core.WalletConfig> opened = [];

  /// Thrown by [create] when set.
  core.WalletError? createError;

  @override
  Future<core.WalletSession> create({required core.WalletConfig config, String? mnemonic, required String password}) async {
    if (createError != null) throw createError!;
    return super.create(config: config, mnemonic: mnemonic, password: password);
  }

  @override
  Future<core.WalletSession> open({required core.WalletConfig config, required String password}) async {
    opened.add(config);
    return super.open(config: config, password: password);
  }
}

/// A session that notes where each scan was told to start.
class _Starts extends _StrictSession {
  final List<BigInt?> starts = [];

  @override
  Stream<core.ScanProgress> scan({BigInt? startHeight, bool deleteUnconfirmed = false}) {
    starts.add(startHeight);
    return super.scan(startHeight: startHeight, deleteUnconfirmed: deleteUnconfirmed);
  }
}

/// A session whose scan waits for [gate].
class _GatedScan extends _StrictSession {
  final Completer<void> gate = Completer<void>();

  @override
  Stream<core.ScanProgress> scan({BigInt? startHeight, bool deleteUnconfirmed = false}) async* {
    await gate.future;
    yield* super.scan(startHeight: startHeight, deleteUnconfirmed: deleteUnconfirmed);
  }
}

/// [deleteWallet] fails, as when the disk refuses.
class _DeleteFails extends _Recording {
  @override
  Future<void> deleteWallet({required core.WalletConfig config}) async =>
      throw const core.WalletError(kind: core.WalletErrorKind.io, message: 'disk refused');
}

void main() {
  late Directory files;
  late Directory support;
  late MemorySecretStore secrets;
  late core.FakeWalletService service;
  late LepicDeskWallet wallet;

  /// As `defaultWalletDir`: `<support>/wallets/<chain>`, made when asked for.
  Future<String> walletDir(core.Chain chain) async {
    final dir = Directory('${support.path}${Platform.pathSeparator}wallets${Platform.pathSeparator}${chain.name}');
    await dir.create(recursive: true);
    return dir.path;
  }

  LepicDeskWallet make(core.FakeWalletService s) => LepicDeskWallet(
    service: s,
    walletDir: walletDir,
    secrets: secrets,
    filesDir: () async => files,
    nodePoll: const Duration(hours: 1),
  );

  setUp(() async {
    files = await Directory.systemTemp.createTemp('desk-wallet-test-');
    support = await Directory.systemTemp.createTemp('desk-wallet-support-');
    secrets = MemorySecretStore();
    service = core.FakeWalletService(password: _password, session: _StrictSession());
    wallet = make(service);
  });

  tearDown(() async {
    await wallet.dispose();
    await files.delete(recursive: true);
    await support.delete(recursive: true);
  });

  Future<void> created() async {
    await wallet.createWallet(name: 'Main', password: _password);
    expect(await wallet.unlock(_password), isTrue);
    await wallet.sync();
  }

  group('create and restore', () {
    test('refuses a short password before touching the core', () async {
      await expectLater(wallet.createWallet(name: '', password: 'short'), throwsA(isA<DeskError>()));
      expect(service.createdConfig, isNull);
    });

    test('creates a mainnet wallet in its own folder and returns its phrase', () async {
      final phrase = await wallet.createWallet(name: 'Main', password: _password);
      expect(phrase, hasLength(24));
      expect(service.createdConfig!.dataDir, '${support.path}/wallets/mainnet');
      expect(service.createdConfig!.chain, core.Chain.mainnet);
      expect(service.createdMnemonic, isNull);
      expect(service.session.disposeCalls, 1, reason: 'the session closes until Unlock');
      final ws = await wallet.wallets();
      expect(ws.single.name, 'Main');
      expect(ws.single.network, 'mainnet');
    });

    test('Welcome chose Floonet: the wallet is a floonet one, with its node, and the next start stays there (LNX-6)', () async {
      await wallet.useNetwork('floonet');
      expect(wallet.network, 'floonet');
      await wallet.createWallet(name: 'Test', password: _password);
      expect(service.createdConfig!.chain, core.Chain.floonet);
      expect(service.createdConfig!.dataDir, '${support.path}/wallets/floonet');
      expect(service.createdConfig!.nodeUrl, floonetPreset.nodeUrl);
      final ws = await wallet.wallets();
      expect(ws.single.network, 'floonet');
      expect((await LepicDeskWallet.savedPreset(secrets)).chain, core.Chain.floonet);
      // Back on mainnet: its own (empty) list, not the floonet wallet.
      await wallet.useNetwork('mainnet');
      expect(await wallet.wallets(), isEmpty);
      await wallet.createWallet(name: 'Main', password: _password);
      expect(service.createdConfig!.chain, core.Chain.mainnet);
    });

    test('a restored wallet\'s pending setup says so, also to a new start (WIN-2)', () async {
      await wallet.createWallet(name: 'Main', password: _password);
      final id = (await wallet.wallets()).single.id;
      expect(await wallet.setupRestored(id), isFalse);
      await wallet.setSetupPending(id, true);
      await wallet.setSetupRestored(id);
      final again = make(service);
      addTearDown(again.dispose);
      expect(await again.setupPending(id), isTrue);
      expect(await again.setupRestored(id), isTrue);
    });

    test('no wallet yet: the wallet list is empty', () async {
      expect(await wallet.wallets(), isEmpty);
    });

    test('restore checks the phrase, then scans after unlock', () async {
      await expectLater(
        wallet.restoreWallet(name: '', password: _password, phrase: ['abandon', 'abandon']),
        throwsA(isA<DeskError>()),
      );
      await wallet.restoreWallet(name: 'Old', password: _password, phrase: service.phrase.toUpperCase().split(' '));
      expect(service.createdMnemonic, service.phrase);
      expect(service.session.scanCalls, 0);
      expect(await wallet.unlock(_password), isTrue);
      await wallet.sync();
      expect(service.session.scanCalls, 1);
      // The scan ran to its end: the next unlock only refreshes.
      await wallet.lock();
      await wallet.unlock(_password);
      await wallet.sync();
      expect(service.session.scanCalls, 1);
    });

    test('the phrase check asks the wallet core, lower-cased and trimmed', () {
      expect(wallet.checkPhrase(service.phrase.toUpperCase().split(' ')), isTrue);
      expect(wallet.checkPhrase(['abandon', 'h4rbor']), isFalse);
    });

    group('a phrase that is already here (O1)', () {
      late _TwoPhrases two;
      final words = core.FakeWalletService().phrase.split(' ');
      final fp = phraseFingerprint(words.join(' '));

      setUp(() async {
        await wallet.dispose();
        two = _TwoPhrases();
        wallet = make(two);
      });

      Future<List<reg.WalletEntry>> listed() async => (await wallet.registry()).list();

      test('create keeps the fingerprint in the list; restoring that phrase finds the wallet and makes nothing', () async {
        await wallet.createWallet(name: 'Main', password: _password);
        expect((await listed()).single.phraseFingerprint, fp);
        expect(two.creates, 1);
        final same = await wallet.walletWithPhrase([for (final w in words) ' ${w.toUpperCase()}']);
        expect(same?.name, 'Main');
        expect(same?.id, (await listed()).single.id);
        final error = await wallet.restoreWallet(password: _password, phrase: words).then<Object?>((_) => null, onError: (Object e) => e);
        expect(error, isA<DeskError>());
        expect((error as DeskError).sameWallet?.name, 'Main');
        expect(error.message, isNot(contains(fp)), reason: 'the fingerprint is never shown');
        expect(two.creates, 1, reason: 'nothing was made');
        expect(await listed(), hasLength(1));
        expect(await wallet.wallets(), hasLength(1));
      });

      test('restore keeps the fingerprint; the same phrase again is refused, a different one restores', () async {
        await wallet.restoreWallet(name: 'Old', password: _password, phrase: words);
        expect((await listed()).single.phraseFingerprint, fp);
        await expectLater(
          wallet.restoreWallet(password: _password, phrase: words),
          throwsA(isA<DeskError>().having((e) => e.sameWallet?.name, 'sameWallet', 'Old')),
        );
        expect(await wallet.walletWithPhrase(_TwoPhrases.other.split(' ')), isNull);
        await wallet.restoreWallet(name: 'Other', password: _password, phrase: _TwoPhrases.other.split(' '));
        expect(two.creates, 2);
        final all = await listed();
        expect(all.map((e) => e.label), ['Old', 'Other']);
        expect(all.map((e) => e.phraseFingerprint).toSet(), hasLength(2));
        expect(all.last.phraseFingerprint, phraseFingerprint(_TwoPhrases.other));
        expect((await wallet.wallets()).last.current, isTrue, reason: 'the new wallet is the selected one');
      });

      test('a phrase that is not valid is never looked up', () async {
        await wallet.createWallet(name: 'Main', password: _password);
        expect(await wallet.walletWithPhrase(['abandon', 'h4rbor']), isNull);
      });

      test('a wallet listed before fingerprints were kept is not matched: the known gap', () async {
        await wallet.createWallet(name: 'Main', password: _password);
        await wallet.dispose();
        // As the list of a build before this fix: the entry without the field.
        final file = File('${support.path}${Platform.pathSeparator}${reg.WalletRegistry.fileName}');
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        for (final w in (json['wallets'] as List).cast<Map<String, dynamic>>()) {
          expect(w.remove('phraseFingerprint'), fp);
        }
        await file.writeAsString(jsonEncode(json));
        wallet = make(two);
        expect((await listed()).single.phraseFingerprint, isNull);
        expect(await wallet.walletWithPhrase(words), isNull, reason: 'no fingerprint, no address helper in the core: not caught');
        await wallet.restoreWallet(name: 'Again', password: _password, phrase: words);
        expect(two.creates, 2, reason: 'the duplicate is made, as before the fix');
        expect((await listed()).last.phraseFingerprint, fp, reason: 'the restored copy carries one from now on');
      });
    });
  });

  group('unlock and lock', () {
    setUp(() => wallet.createWallet(name: 'Main', password: _password));

    test('a wrong password is refused, the right one opens', () async {
      expect(await wallet.unlock('not-the-password'), isFalse);
      expect(await wallet.unlock(_password), isTrue);
      expect(await wallet.epicboxAddress(), service.session.address);
    });

    test('lock closes the session and the listener', () async {
      await wallet.unlock(_password);
      await wallet.setListening(true);
      final before = service.session.disposeCalls;
      await wallet.lock();
      expect(service.session.disposeCalls, before + 1);
      expect(service.session.listenerStops, 1);
      await expectLater(wallet.balance(), throwsA(isA<DeskError>()));
    });

    test('a damaged database is rebuilt: opened again, then scanned', () async {
      final damaged = _DamagedOnce();
      final w = make(damaged);
      await w.createWallet(name: '', password: _password);
      expect(await w.unlock(_password), isTrue);
      expect((await w.status()).notice, 'Wallet database damaged, rebuilding');
      await w.sync();
      expect(damaged.session.scanCalls, 1);
      expect((await w.status()).notice, isNull);
      await w.dispose();
    });
  });

  group('the Epicbox server of an install that never saved one (D-13)', () {
    test('a wallet in the first folder keeps the server 0.1.0 used, and it is saved', () async {
      service.existingWallets.add(await walletDir(core.Chain.mainnet));
      expect((await wallet.status()).epicbox.domain, 'epicbox.stackwallet.com');
      expect(secrets.values['app.relay.mainnet'], 'epicbox.stackwallet.com');
    });

    test('a wallet in wallets.json keeps it too', () async {
      await wallet.createWallet(name: 'Main', password: _password);
      await wallet.createWallet(name: 'Second', password: _password);
      secrets.values.remove('app.relay.mainnet');
      service.existingWallets.remove(await walletDir(core.Chain.mainnet));
      final again = make(service);
      addTearDown(again.dispose);
      expect((await again.status()).epicbox.domain, 'epicbox.stackwallet.com');
    });

    test('a fresh install starts on the new default and keeps it once a wallet exists', () async {
      expect((await wallet.status()).epicbox.domain, 'epicbox.epiccash.com');
      await wallet.createWallet(name: 'Main', password: _password);
      final again = make(service);
      addTearDown(again.dispose);
      expect((await again.status()).epicbox.domain, 'epicbox.epiccash.com');
    });

    test('a saved server is left alone', () async {
      secrets.values['app.relay.mainnet'] = 'epicbox.epicnet.us';
      service.existingWallets.add(await walletDir(core.Chain.mainnet));
      expect((await wallet.status()).epicbox.domain, 'epicbox.epicnet.us');
    });
  });

  group('reading', () {
    setUp(created);

    test('Total is the core\'s: one 100 EPIC output sending 1 is 100, then 98.99, never 199', () async {
      const epic = 100000000;
      final s = service.session;
      core.WalletSummary summary({required int total, int spendable = 0, int confirming = 0, int finalizing = 0, int locked = 0}) => core.WalletSummary(
        lastConfirmedHeight: BigInt.from(2500000),
        minimumConfirmations: BigInt.from(3),
        total: BigInt.from(total),
        spendable: BigInt.from(spendable),
        awaitingConfirmation: BigInt.from(confirming),
        awaitingFinalization: BigInt.from(finalizing),
        immature: BigInt.zero,
        locked: BigInt.from(locked),
        validatedWithNode: true,
      );
      // As LEPIC reports a pending send: the input locked, the change awaiting finalization
      // (not in the total) until the refresh that finds it on chain marks the input spent.
      s.summaryValue = summary(total: 100 * epic, locked: 100 * epic, finalizing: 99 * epic - 800000);
      await wallet.syncNow();
      final pending = await wallet.balance();
      expect(pending.total, 100 * epic);
      expect(pending.total, lessThan(199 * epic));
      // Mined: the input spent, the change confirming.
      s.summaryValue = summary(total: 99 * epic - 800000, confirming: 99 * epic - 800000);
      await wallet.syncNow();
      expect((await wallet.balance()).total, 99 * epic - 800000);
      // The core's figure wins over the parts.
      s.summaryValue = summary(total: 7, spendable: 5);
      await wallet.syncNow();
      expect((await wallet.balance()).total, 7);
      expect(const Balance(spendable: 5, awaitingConfirmation: 1, locked: 2, awaitingFinalization: 9, immature: 3).total, 11);
    });

    test('balance and history map onto the UI types', () async {
      final s = service.session;
      s.summaryValue = core.WalletSummary(
        lastConfirmedHeight: BigInt.from(2500000),
        minimumConfirmations: BigInt.from(3),
        total: BigInt.from(700),
        spendable: BigInt.from(500),
        awaitingConfirmation: BigInt.from(100),
        awaitingFinalization: BigInt.from(40),
        immature: BigInt.from(60),
        locked: BigInt.from(40),
        validatedWithNode: true,
      );
      s.transactionsValue = [
        core.fakeTx(id: 1, slateId: 's1', kind: core.TxKind.received, status: core.TxStatus.confirmed, amountCredited: BigInt.from(300), blockHeight: BigInt.from(2400000), counterparty: 'esA@epicbox.epiccash.com', messages: const [core.SlateMessage(role: core.SlateRole.sender, text: 'hi')]),
        core.fakeTx(id: 2, slateId: 's2', kind: core.TxKind.sent, status: core.TxStatus.awaitingRecipient, amountDebited: BigInt.from(1000), amountCredited: BigInt.from(390), fee: BigInt.from(10)),
        core.fakeTx(id: 3, slateId: 's3', kind: core.TxKind.sent, status: core.TxStatus.awaitingConfirmation, amountDebited: BigInt.from(110), fee: BigInt.from(10), blockHeight: BigInt.from(2499998), counterparty: 'esB@epicbox.epiccash.com'),
        core.fakeTx(kind: core.TxKind.coinbase, source: core.TxSource.restored, status: core.TxStatus.cancelled),
      ];
      await wallet.sync();
      final b = await wallet.balance();
      expect((b.spendable, b.awaitingConfirmation, b.awaitingFinalization, b.immature, b.locked), (500, 100, 40, 60, 40));

      final txs = await wallet.transactions();
      expect(txs, hasLength(4));
      final r = txs[0];
      expect((r.id, r.direction, r.state, r.method, r.amount, r.fee, r.message), (1, TxDirection.received, TxState.confirmed, TxMethod.epicbox, 300, 0, 'hi'));
      expect(r.confirmations, 2500000 - 2400000 + 1);
      final waiting = txs[1];
      expect((waiting.direction, waiting.state, waiting.method, waiting.amount, waiting.fee), (TxDirection.sent, TxState.waitingRecipient, TxMethod.file, 600, 10));
      final confirming = txs[2];
      expect((confirming.state, confirming.confirmations, confirming.amount), (TxState.confirming, 3, 100));
      final restored = txs[3];
      expect((restored.coinbase, restored.foundByScan, restored.state), (true, true, TxState.cancelled));
      expect(restored.id, isNegative, reason: 'no local id: not cancellable');
    });

    test('labels and details: the adapter maps them and writes through the core', () async {
      final s = service.session;
      s.transactionsValue = [
        core.fakeTx(id: 1, slateId: 's1', kind: core.TxKind.received, status: core.TxStatus.confirmed, amountCredited: BigInt.from(300), blockHeight: BigInt.from(2400000)),
        core.fakeTx(key: 'c:aa', kind: core.TxKind.received, source: core.TxSource.restored, status: core.TxStatus.confirmed, amountCredited: BigInt.from(500), blockHeight: BigInt.from(2400001)),
      ];
      await wallet.sync();
      var txs = await wallet.transactions();
      expect((txs[0].key, txs[0].label), ('s:s1', null));
      expect(txs[0].manualFields, isEmpty);
      expect((txs[1].key, txs[1].restored), ('c:aa', true));
      expect(txs[1].transport, isNull);

      await wallet.setTxLabel('s:s1', '  Rent  ');
      expect(s.labels, {'s:s1': 'Rent'});
      await wallet.setTxDetails('c:aa', counterparty: 'esA@epicbox.epiccash.com', transport: 'file', note: 'Pool');
      txs = await wallet.transactions();
      expect(txs[0].label, 'Rent');
      expect(txs[0].manualFields, {ManualField.label});
      expect(txs[0].manualEditedAt, isNotNull);
      expect((txs[1].counterparty, txs[1].transport, txs[1].method, txs[1].note), ('esA@epicbox.epiccash.com', 'file', TxMethod.file, 'Pool'));
      expect(txs[1].manualFields, {ManualField.counterparty, ManualField.transport, ManualField.note});

      // Removing: a blank label, and every detail cleared.
      await wallet.setTxLabel('s:s1', null);
      expect(s.labels, isEmpty);
      // The core refuses details on a row a scan did not find.
      await expectLater(wallet.setTxDetails('s:s1', note: 'x'), throwsA(isA<DeskError>()));
    });

    test('a history import that differs from typed details writes nothing until it has the choices', () async {
      final s = service.session;
      s.importConflicts = [
        core.ImportConflict(key: 's:s1', field: core.ManualField.label, mine: 'Rent', theirs: 'Flat', timeUnix: 1790000000, amount: BigInt.from(-300)),
      ];
      final first = await wallet.importHistory(Uint8List.fromList(utf8.encode('WFEH')));
      expect(first.applied, isFalse);
      expect(first.conflicts.map((c) => c.id), ['s:s1|label']);
      expect(s.lastUseBackup, isNull);
    });

    test('status follows the node, the sync and the listener', () async {
      final st = await wallet.status();
      expect(st.node.url, 'https://node.btlabs.uk');
      expect(st.nodeHeight, 2500000);
      expect(st.nodeHealth, ServiceHealth.ok);
      // Made on a fresh install: the new default (D-13).
      expect(st.epicbox.domain, defaultEpicboxHost);
      expect(st.epicboxHealth, ServiceHealth.off);
      expect(st.syncProgress, isNull);
      expect(await wallet.outputs(), isEmpty);
    });

    test('the listener: on, connected, a payment, off', () async {
      final changes = <void>[];
      final sub = wallet.changes().listen(changes.add);
      await wallet.setListening(true);
      expect(service.session.listenerStarts, 1);
      expect((await wallet.status()).epicboxHealth, ServiceHealth.checking);
      service.session.listenerEvents.add(const core.ListenerEvent(kind: core.ListenerEventKind.connected, message: 'listening'));
      await pumpEventQueue();
      expect((await wallet.status()).epicboxHealth, ServiceHealth.ok);
      final before = service.session.transactionsCalls;
      service.session.listenerEvents.add(core.ListenerEvent(kind: core.ListenerEventKind.received, message: 'got it', amount: BigInt.one));
      await pumpEventQueue();
      expect(service.session.transactionsCalls, greaterThan(before));
      service.session.listenerEvents.add(const core.ListenerEvent(kind: core.ListenerEventKind.disconnected, message: 'dropped'));
      await pumpEventQueue();
      expect((await wallet.status()).epicboxHealth, ServiceHealth.down);
      await wallet.setListening(false);
      expect(service.session.listenerStops, 1);
      expect((await wallet.status()).epicboxHealth, ServiceHealth.off);
      expect(changes, isNotEmpty);
      await sub.cancel();
    });

    test('contacts round trip, favourites kept by the app', () async {
      await wallet.saveContact(Contact(id: '', name: 'Ann', address: 'esA@epicbox.epiccash.com', favourite: true));
      final cs = (await wallet.contacts()).where((c) => c.name != 'BT Labs');
      expect(cs.single.name, 'Ann');
      expect(cs.single.favourite, isTrue);
      await wallet.deleteContact(cs.single.id);
      expect((await wallet.contacts()).map((c) => c.name), ['BT Labs']);
    });

    test('Refresh asks the node now and says when it did not answer', () async {
      final s = service.session;
      final before = s.refreshCalls;
      s.summaryValue = core.WalletSummary(
        lastConfirmedHeight: BigInt.from(2500001),
        minimumConfirmations: BigInt.from(3),
        total: BigInt.from(900),
        spendable: BigInt.from(900),
        awaitingConfirmation: BigInt.zero,
        awaitingFinalization: BigInt.zero,
        immature: BigInt.zero,
        locked: BigInt.zero,
        validatedWithNode: true,
      );
      await wallet.syncNow();
      expect(s.refreshCalls, before + 1);
      expect((await wallet.balance()).spendable, 900);

      s.refreshError = const core.WalletError(kind: core.WalletErrorKind.nodeUnreachable, message: 'down');
      await expectLater(wallet.syncNow(), throwsA(isA<DeskError>()));
      expect((await wallet.status()).nodeHealth, ServiceHealth.down);

      s.refreshError = null;
      await wallet.syncNow();
      await wallet.lock();
      await expectLater(wallet.syncNow(), throwsA(isA<DeskError>()));
    });

    // Tor is real now (tor_direct_test.dart), and the password change (change_password_test.dart).
    test('hidden features throw instead of faking', () async {
      expect(() => wallet.exportProof(1), throwsUnsupportedError);
    });
  });

  group('sending and files', () {
    setUp(() async {
      await created();
      service.session.summaryValue = core.WalletSummary(
        lastConfirmedHeight: BigInt.from(2500000),
        minimumConfirmations: BigInt.from(3),
        total: BigInt.from(100000000),
        spendable: BigInt.from(100000000),
        awaitingConfirmation: BigInt.zero,
        awaitingFinalization: BigInt.zero,
        immature: BigInt.zero,
        locked: BigInt.zero,
        validatedWithNode: true,
      );
    });

    test('fee, max and an Epicbox send', () async {
      expect(await wallet.estimateFee(1000), service.session.fee.toInt());
      final max = await wallet.estimateMax();
      expect(max.amount + max.fee, 100000000);
      expect(max.locked, greaterThan(0));
      final to = '${'1' * 52}@epicbox.epiccash.com';
      expect(await wallet.send(const SendRequest(method: TxMethod.epicbox, amount: 1000, to: 'nope')), isA<SendFailed>());
      final r = await wallet.send(SendRequest(method: TxMethod.epicbox, amount: 1000, to: to, message: ' lunch '));
      expect(r, isA<SendDone>());
      expect(service.session.epicboxSends.single.to, to);
      expect(service.session.sentMessages.single, 'lunch');
    });

    test('a refused Epicbox send says the payment waits', () async {
      service.session.sendError = const core.WalletError(kind: core.WalletErrorKind.transportFailed, message: 'relay down');
      final r = await wallet.send(SendRequest(method: TxMethod.epicbox, amount: 1000, to: '${'1' * 52}@epicbox.epiccash.com'));
      expect((r as SendFailed).message, startsWith('Not delivered'));
      expect(r.inActivity, isTrue, reason: 'the payment exists: no second review');
    });

    test('send all sends the reviewed amount, not a new maximum', () async {
      final to = '${'1' * 52}@epicbox.epiccash.com';
      final r = await wallet.send(SendRequest(method: TxMethod.epicbox, amount: 1234, to: to, sendAll: true));
      expect(r, isA<SendDone>());
      expect(service.session.epicboxSends.single.amount, BigInt.from(1234));
    });

    test('a slate file that cannot be written fails clearly; the payment is in Activity', () async {
      final blocker = File('${files.path}${Platform.pathSeparator}not-a-folder')..writeAsStringSync('x');
      final w = LepicDeskWallet(
        service: service,
        walletDir: walletDir,
        secrets: secrets,
        filesDir: () async => Directory(blocker.path),
        nodePoll: const Duration(hours: 1),
      );
      addTearDown(w.dispose);
      expect(await w.unlock(_password), isTrue);
      final r = await w.send(const SendRequest(method: TxMethod.file, amount: 5000));
      expect(r, isA<SendFailed>().having((f) => f.inActivity, 'inActivity', isTrue).having((f) => f.message, 'message', contains('Activity')));
      expect(service.session.sentAmounts.single, BigInt.from(5000));
    });

    test('a response that cannot go beside the slate goes to the files folder', () async {
      final ro = await Directory('${files.path}${Platform.pathSeparator}ro').create();
      final incoming = File('${ro.path}${Platform.pathSeparator}in.tx')..writeAsStringSync('{"id":"in"}');
      await Process.run('chmod', ['555', ro.path]);
      addTearDown(() => Process.run('chmod', ['755', ro.path]));
      final r = await wallet.receiveFile(incoming.path);
      expect(r.response, '${files.path}${Platform.pathSeparator}slate-2.response');
      expect(File(r.response).readAsStringSync(), service.session.responseSlate.json);
      expect(File('${ro.path}${Platform.pathSeparator}slate-2.response').existsSync(), isFalse);
    }, skip: Platform.isWindows || Platform.environment['USER'] == 'root' ? 'needs POSIX permissions' : false);

    test('file send, receive and finalize go through files on disk', () async {
      final sent = await wallet.send(const SendRequest(method: TxMethod.file, amount: 5000));
      final ready = sent as SendFileReady;
      expect(ready.fileName, '${files.path}${Platform.pathSeparator}slate-1.tx');
      expect(File(ready.fileName).readAsStringSync(), service.session.sendSlate.json);

      final incoming = File('${files.path}${Platform.pathSeparator}in.tx')..writeAsStringSync('{"id":"in"}');
      expect((await wallet.receiveFile(incoming.path)).response, '${files.path}${Platform.pathSeparator}slate-2.response');
      expect(service.session.receivedSlates.single, '{"id":"in"}');
      expect(File('${files.path}${Platform.pathSeparator}slate-2.response').readAsStringSync(), service.session.responseSlate.json);

      final reply = File('${files.path}${Platform.pathSeparator}reply.tx.response')..writeAsStringSync(service.session.responseSlate.json);
      final tx = await wallet.finalizeFile(reply.path);
      expect(service.session.finalizedSlates.single, service.session.responseSlate.json);
      expect(tx.direction, TxDirection.sent);

      final junk = File('${files.path}${Platform.pathSeparator}junk.txt')..writeAsStringSync('hello');
      await expectLater(wallet.finalizeFile(junk.path), throwsA(isA<DeskError>().having((e) => e.message, 'message', 'Not a transaction file')));
      await expectLater(wallet.receiveFile('${files.path}/missing.tx'), throwsA(isA<DeskError>()));
    });

    test('receive reads any file name and never overwrites an earlier answer', () async {
      final sep = Platform.pathSeparator;
      const long = '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d';
      for (final name in ['$long.tx', '$long.tx.response', 'no-suffix', 'odd name (1).slate.json']) {
        final f = File('${files.path}$sep$name')..writeAsStringSync('{"id":"in"}');
        expect((await wallet.receiveFile(f.path)).response.contains('slate-2'), isTrue, reason: name);
      }
      expect(File('${files.path}${sep}slate-2.response').existsSync(), isTrue);
      expect(File('${files.path}${sep}slate-2-2.response').existsSync(), isTrue);
      expect(File('${files.path}${sep}slate-2-4.response').existsSync(), isTrue);
    });

    test('remove wallet checks the password, then deletes only its folder', () async {
      await expectLater(wallet.removeWallet('legacy-mainnet', WalletRemoval.delete, password: 'wrong-pass-123'), throwsA(isA<DeskError>()));
      expect(service.deletedWallets, isEmpty);
    });
  });

  test('remove wallet with the right password deletes its folder and data', () async {
    await created();
    await wallet.removeWallet('legacy-mainnet', WalletRemoval.delete, password: _password);
    expect(service.deletedWallets, ['${support.path}/wallets/mainnet']);
    expect(await wallet.wallets(), isEmpty);
    expect(await secrets.read(DeskStore.walletKey('mainnet')), isNull);
  });

  test('node and Epicbox choices are saved under the phone keys and reopen the wallet', () async {
    await created();
    await wallet.useNode('https://node.epicnet.us:3413');
    expect(await secrets.read('app.node.mainnet'), 'https://node.epicnet.us:3413');
    expect((await wallet.status()).node.url, 'https://node.epicnet.us:3413');
    await wallet.useEpicbox('epicbox.epicnet.us');
    expect(await secrets.read('app.relay.mainnet'), 'epicbox.epicnet.us');
    expect((await wallet.status()).epicbox.domain, 'epicbox.epicnet.us');
    final checked = await wallet.checkNode('https://node.btlabs.uk');
    expect((checked.health, checked.height, checked.version), (ServiceHealth.ok, 2500000, '3.6.0'));
    await wallet.addNode(const NodeServer(url: 'http://10.0.0.5:3413', label: 'Home', own: true));
    expect((await wallet.nodes()).where((n) => n.own).single.label, 'Home');
  });

  group('server changes reopen the wallet', () {
    late _Opens opens;
    late LepicDeskWallet w;
    const next = 'https://node.epicnet.us:3413';

    setUp(() async {
      opens = _Opens();
      w = make(opens);
      await w.createWallet(name: 'Main', password: _password);
      expect(await w.unlock(_password), isTrue);
    });

    tearDown(() => w.dispose());

    test('a node the wallet cannot open on is not saved; the old one is back', () async {
      opens.refuse = (c) => c.nodeUrl == next;
      await expectLater(w.useNode(next), throwsA(isA<DeskError>().having((e) => e.locked, 'locked', isFalse).having((e) => e.message, 'message', startsWith('Not changed'))));
      expect(await secrets.read('app.node.mainnet'), isNull);
      expect((await w.status()).node.url, isNot(next));
      expect(await w.epicboxAddress(), opens.session.address, reason: 'open on the old node');
    });

    test('when the old config fails too, the wallet locks and says so', () async {
      opens.refuse = (_) => true;
      await expectLater(w.useNode(next), throwsA(isA<DeskError>().having((e) => e.locked, 'locked', isTrue)));
      await expectLater(w.balance(), throwsA(isA<DeskError>()));
      expect(await secrets.read('app.node.mainnet'), isNull);
    });

    test('a lock during the reopen wins: the new session closes at once', () async {
      await w.setListening(true);
      opens.gate = Completer<void>();
      final change = w.useNode(next);
      await pumpEventQueue();
      await w.lock();
      final disposed = opens.session.disposeCalls;
      final starts = opens.session.listenerStarts;
      opens.gate!.complete();
      await change;
      expect(opens.session.disposeCalls, disposed + 1);
      expect(opens.session.listenerStarts, starts, reason: 'no listener on a locked wallet');
      await expectLater(w.balance(), throwsA(isA<DeskError>()));
    });
  });

  group('settings persistence', () {
    test('DeskSettings and SettingsPrefs survive a restart', () async {
      final store = DeskStore(secrets);
      await store.saveSettings(const DeskSettings(theme: ThemeChoice.light, scale: 125, hideAmounts: true, newLookSeen: true));
      final container = ProviderContainer(overrides: [deskStoreProvider.overrideWithValue(store)]);
      container.read(settingsPrefsProvider.notifier).set(const SettingsPrefs(epicboxOnStart: false, walletLabel: 'Savings', nodeLabels: {'http://a': 'A'}));
      await pumpEventQueue();
      container.dispose();
      expect(jsonDecode((await secrets.read(DeskStore.prefsKey))!), containsPair('walletLabel', 'Savings'));

      final boot = await DeskBoot.load(store);
      expect((boot.settings.theme, boot.settings.scale, boot.settings.hideAmounts, boot.settings.newLookSeen), (ThemeChoice.light, 125, true, true));
      final again = ProviderContainer(overrides: [deskStoreProvider.overrideWithValue(store), deskBootProvider.overrideWithValue(boot)]);
      addTearDown(again.dispose);
      final prefs = again.read(settingsPrefsProvider);
      expect((prefs.epicboxOnStart, prefs.walletLabel), (false, 'Savings'));
      expect(prefs.nodeLabels, {'http://a': 'A'});
      expect(again.read(deskProvider).settings.scale, 125);
    });

    test('a saved setting through the controller lands in the store', () async {
      final store = DeskStore(secrets);
      final container = ProviderContainer(overrides: [deskStoreProvider.overrideWithValue(store)]);
      addTearDown(container.dispose);
      await container.read(deskProvider.notifier).saveSettings(const DeskSettings(scale: 150));
      expect((await store.settings()).scale, 150);
    });

    test('damaged saved settings fall back to the defaults', () async {
      await secrets.write(DeskStore.settingsKey, 'not json');
      expect((await DeskStore(secrets).settings()).theme, ThemeChoice.dark);
    });

    test('saved values of the wrong type fall back one by one', () async {
      await secrets.write(DeskStore.settingsKey, jsonEncode({'theme': 'light', 'scale': '125', 'hideAmounts': 1, 'newLookSeen': 'yes', 'autoLockMinutes': '5'}));
      final s = await DeskStore(secrets).settings();
      const d = DeskSettings();
      expect((s.theme, s.scale, s.hideAmounts, s.newLookSeen, s.autoLockMinutes), (ThemeChoice.light, d.scale, d.hideAmounts, d.newLookSeen, d.autoLockMinutes));
      // Auto-lock: 15 minutes and on by default; 1 to 60; the pre-26.10.13 key is not read.
      expect((d.autoLockMinutes, d.autoLockOn), (15, true));
      expect(deskSettingsFromJson({'autoLockMinutes': 30}).autoLockMinutes, 15);
      expect(deskSettingsFromJson({'autoLock': 30}).autoLockMinutes, 30);
      expect(deskSettingsFromJson({'autoLock': 0}).autoLockMinutes, 1);
      expect(deskSettingsFromJson({'autoLock': 600}).autoLockMinutes, 60);
      expect(deskSettingsFromJson({'autoLockOn': false}).autoLockOn, isFalse);
      final back = deskSettingsFromJson(deskSettingsToJson(d.copyWith(autoLockMinutes: 1, autoLockOn: false)));
      expect((back.autoLockMinutes, back.autoLockOn), (1, false));
    });
  });

  // Every hidden feature stays hidden: no route, row, segment or menu item renders.
  group('several wallets', () {
    late _Recording rec;
    late LepicDeskWallet w;
    String first() => '${support.path}/wallets/mainnet';

    setUp(() async {
      rec = _Recording();
      w = make(rec);
    });

    tearDown(() => w.dispose());

    /// A wallet's lepic folder and an epic-wallet seed folder, as on a real disk.
    void fill(String dir) {
      File('$dir/lepic/wallet.db').createSync(recursive: true);
      File('$dir/wallet_data/wallet.seed').createSync(recursive: true);
    }

    test('the first wallet keeps the 0.1.0 folder, a null walletId and the old store key', () async {
      await w.createWallet(name: 'Main', password: _password);
      expect(rec.createdConfig!.dataDir, first());
      expect(rec.createdConfig!.walletId, isNull);
      expect(jsonDecode((await secrets.read('desk.wallet.mainnet'))!), containsPair('name', 'Main'));
      final ws = await w.wallets();
      expect((ws.single.id, ws.single.name, ws.single.folder, ws.single.current), ('legacy-mainnet', 'Main', first(), true));
      expect(File('${support.path}/wallets.json').readAsStringSync(), contains('"legacy-mainnet"'));
      expect(await w.unlock(_password), isTrue);
      expect(rec.opened.last.walletId, isNull);
      expect(rec.opened.last.dataDir, first());
    });

    test('a 0.1.0 wallet is listed as the first one, under its saved name', () async {
      rec.existingWallets.add(first());
      await secrets.write('desk.wallet.mainnet', jsonEncode({'name': 'Tester', 'created': 1700000000}));
      final before = await secrets.read('desk.wallet.mainnet');
      final ws = await w.wallets();
      expect((ws.single.id, ws.single.name, ws.single.folder), ('legacy-mainnet', 'Tester', first()));
      expect(await w.unlock(_password), isTrue);
      expect(rec.opened.single.dataDir, first());
      expect(rec.opened.single.walletId, isNull);
      expect(jsonDecode((await secrets.read('desk.wallet.mainnet'))!), containsPair('name', 'Tester'));
      expect(jsonDecode(before!)['created'], 1700000000);
    });

    test('a second wallet gets its own folder, walletId and store key, and is selected', () async {
      await w.createWallet(name: 'Main', password: _password);
      final firstMeta = await secrets.read('desk.wallet.mainnet');
      await w.createWallet(name: 'Savings', password: _password);
      final id = rec.createdConfig!.walletId!;
      expect(id, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(rec.createdConfig!.dataDir, '${support.path}/wallets/$id/mainnet');
      expect(jsonDecode((await secrets.read('desk.wallet.mainnet.$id'))!), containsPair('name', 'Savings'));
      expect(await secrets.read('desk.wallet.mainnet'), firstMeta, reason: 'the first wallet is not touched');
      final ws = await w.wallets();
      expect(ws.map((e) => e.name), ['Main', 'Savings']);
      expect(ws.where((e) => e.current).single.id, id);
    });

    test('a folder written into wallets.json by hand is never opened', () async {
      await w.createWallet(name: 'Main', password: _password);
      await w.createWallet(name: 'Savings', password: _password);
      final id = rec.createdConfig!.walletId!;
      final list = File('${support.path}/wallets.json');
      final elsewhere = '${support.path}/elsewhere/.epic/main';
      list.writeAsStringSync(list.readAsStringSync().replaceAll('${support.path}/wallets/$id/mainnet', elsewhere));
      final again = make(rec);
      addTearDown(again.dispose);
      await again.selectWallet(id);
      expect(await again.unlock(_password), isTrue);
      expect(rec.opened.last.dataDir, '${support.path}/wallets/$id/mainnet');
      expect(Directory(elsewhere).existsSync(), isFalse);
    });

    test('unlock opens the selected wallet and remembers it', () async {
      await w.createWallet(name: 'Main', password: _password);
      await w.createWallet(name: 'Savings', password: _password);
      final id = rec.createdConfig!.walletId!;
      await w.selectWallet('legacy-mainnet');
      expect(await w.unlock(_password), isTrue);
      expect((rec.opened.last.dataDir, rec.opened.last.walletId), (first(), null));
      expect((await w.account()).name, 'Main');
      await w.selectWallet(id);
      expect(await w.unlock(_password), isTrue);
      expect((rec.opened.last.dataDir, rec.opened.last.walletId), ('${support.path}/wallets/$id/mainnet', id));
      expect((await w.account()).id, id);
      expect((await w.wallets()).where((e) => e.current).single.id, id);
      await expectLater(w.selectWallet('nope'), throwsA(isA<DeskError>()));
      // Next start: the wallet opened last comes first.
      final again = make(rec);
      addTearDown(again.dispose);
      expect((await again.wallets()).where((e) => e.current).single.id, id);
    });

    test('rename changes the list and the wallet name, and refuses a bad label', () async {
      await w.createWallet(name: '', password: _password);
      await w.createWallet(name: '', password: _password);
      final id = rec.createdConfig!.walletId!;
      expect((await w.wallets()).map((e) => e.name), ['Wallet 1', 'Wallet 2']);
      await w.renameWallet(id, '  Savings ');
      expect((await w.wallets()).last.name, 'Savings');
      expect(jsonDecode((await secrets.read('desk.wallet.mainnet.$id'))!), containsPair('name', 'Savings'));
      await expectLater(w.renameWallet(id, ''), throwsA(isA<DeskError>()));
      await expectLater(w.renameWallet(id, 'x' * 33), throwsA(isA<DeskError>()));
    });

    test('wallets made without a name are Wallet 1, 2, 3, the next free number after a rename or removal', () async {
      await w.createWallet(password: _password);
      await w.createWallet(password: _password);
      await w.restoreWallet(password: _password, phrase: _TwoPhrases.other.split(' '));
      expect((await w.wallets()).map((e) => e.name), ['Wallet 1', 'Wallet 2', 'Wallet 3']);
      final second = (await w.wallets())[1].id;
      await w.renameWallet(second, 'Savings');
      await w.createWallet(password: _password);
      expect((await w.wallets()).map((e) => e.name), ['Wallet 1', 'Savings', 'Wallet 3', 'Wallet 2']);
      await w.removeWallet((await w.wallets())[2].id, WalletRemoval.list);
      await w.createWallet(password: _password);
      expect((await w.wallets()).map((e) => e.name), ['Wallet 1', 'Savings', 'Wallet 2', 'Wallet 3']);
    });

    test('a wallet added while another is open is the one Unlock offers and the one opened next start', () async {
      await w.createWallet(password: _password);
      await w.unlock(_password);
      await w.createWallet(password: _password);
      final added = rec.createdConfig!.walletId!;
      final fresh = make(rec);
      addTearDown(fresh.dispose);
      expect((await fresh.wallets()).where((e) => e.current).single.id, added, reason: 'the registry lastUsedId is the new wallet');
      await w.lock();
      final current = (await w.wallets()).where((e) => e.current).single;
      expect((current.id, current.name), (added, 'Wallet 2'));
      expect(await w.unlock(_password), isTrue);
      expect(rec.opened.last.walletId, added);
      final again = make(rec);
      addTearDown(again.dispose);
      expect((await again.wallets()).where((e) => e.current).single.id, added);
    });

    test('remove from list keeps every file; Add back returns it under its name', () async {
      await w.createWallet(name: 'Main', password: _password);
      await w.createWallet(name: 'Savings', password: _password);
      final id = rec.createdConfig!.walletId!;
      final dir = '${support.path}/wallets/$id/mainnet';
      fill(dir);
      await w.removeWallet(id, WalletRemoval.list);
      expect(rec.deletedWallets, isEmpty);
      expect(File('$dir/lepic/wallet.db').existsSync(), isTrue);
      expect(await secrets.read('desk.wallet.mainnet.$id'), isNotNull);
      expect((await w.wallets()).map((e) => e.id), ['legacy-mainnet']);
      final removed = await w.findRemoved();
      expect((removed.single.id, removed.single.name), (id, 'Savings'));
      await w.addBack(id);
      expect((await w.wallets()).map((e) => e.name), ['Main', 'Savings']);
    });

    test('the first wallet removed from the list stays off after a restart until added back', () async {
      await w.createWallet(name: 'Main', password: _password);
      await w.createWallet(name: 'Savings', password: _password);
      await w.removeWallet('legacy-mainnet', WalletRemoval.list);
      expect(rec.deletedWallets, isEmpty);
      final again = make(rec);
      addTearDown(again.dispose);
      expect((await again.wallets()).map((e) => e.name), ['Savings']);
      expect((await again.findRemoved()).single.id, 'legacy-mainnet');
      await again.addBack('legacy-mainnet');
      expect((await again.wallets()).map((e) => e.name), unorderedEquals(['Main', 'Savings']));
    });

    test('delete removes only that wallet\'s lepic folder, never wallet_data or the first wallet', () async {
      await w.createWallet(name: 'Main', password: _password);
      await w.createWallet(name: 'Savings', password: _password);
      final id = rec.createdConfig!.walletId!;
      final dir = '${support.path}/wallets/$id/mainnet';
      fill(first());
      fill(dir);
      final firstMeta = await secrets.read('desk.wallet.mainnet');
      await w.selectWallet(id);
      expect(await w.unlock(_password), isTrue);
      await w.removeWallet(id, WalletRemoval.delete, password: _password);
      expect(rec.deletedWallets, [dir]);
      expect(Directory('$dir/lepic').existsSync(), isFalse);
      expect(File('$dir/wallet_data/wallet.seed').existsSync(), isTrue);
      expect(File('${first()}/lepic/wallet.db').existsSync(), isTrue);
      expect(File('${first()}/wallet_data/wallet.seed').existsSync(), isTrue);
      expect(await secrets.read('desk.wallet.mainnet.$id'), isNull);
      expect(await secrets.read('desk.wallet.mainnet'), firstMeta);
      expect((await w.wallets()).map((e) => e.id), ['legacy-mainnet']);
    });

    test('removing the open wallet needs its password and locks it first', () async {
      await w.createWallet(name: 'Main', password: _password);
      await w.createWallet(name: 'Savings', password: _password);
      final id = rec.createdConfig!.walletId!;
      expect(await w.unlock(_password), isTrue);
      await expectLater(w.removeWallet(id, WalletRemoval.delete), throwsA(isA<DeskError>()));
      await expectLater(w.removeWallet(id, WalletRemoval.delete, password: 'wrong-pass-123'), throwsA(isA<DeskError>()));
      expect(rec.deletedWallets, isEmpty);
      expect(await w.epicboxAddress(), rec.session.address, reason: 'still open after a refused delete');
      await w.removeWallet(id, WalletRemoval.delete, password: _password);
      await expectLater(w.balance(), throwsA(isA<DeskError>()));
      expect(rec.deletedWallets, ['${support.path}/wallets/$id/mainnet']);
      expect((await w.wallets()).single.current, isTrue);
    });

    test('deleting the first wallet while it is open leaves the second one\'s keys and folder', () async {
      await w.createWallet(name: 'Main', password: _password);
      await w.createWallet(name: 'Savings', password: _password);
      final id = rec.createdConfig!.walletId!;
      final dir = '${support.path}/wallets/$id/mainnet';
      fill(first());
      fill(dir);
      await w.selectWallet('legacy-mainnet');
      expect(await w.unlock(_password), isTrue);
      await w.removeWallet('legacy-mainnet', WalletRemoval.delete, password: _password);
      expect(rec.deletedWallets, [first()]);
      expect(await secrets.read('desk.wallet.mainnet'), isNull);
      expect(await secrets.read('desk.wallet.mainnet.$id'), isNotNull);
      expect(File('$dir/lepic/wallet.db').existsSync(), isTrue);
      expect((await w.wallets()).map((e) => e.id), [id]);
    });

    test('a wallet that is not open cannot be deleted, but can be removed from the list', () async {
      await w.createWallet(name: 'Main', password: _password);
      await w.createWallet(name: 'Savings', password: _password);
      final id = rec.createdConfig!.walletId!;
      final dir = '${support.path}/wallets/$id/mainnet';
      fill(dir);
      expect(await w.unlock(_password), isTrue); // Savings is selected: it is the open one
      await expectLater(
        w.removeWallet('legacy-mainnet', WalletRemoval.delete, password: _password),
        throwsA(isA<DeskError>().having((e) => e.message, 'message', 'Open the wallet to delete it')),
      );
      await expectLater(w.removeWallet('legacy-mainnet', WalletRemoval.delete), throwsA(isA<DeskError>()));
      expect(rec.deletedWallets, isEmpty);
      expect((await w.wallets()).map((e) => e.id), ['legacy-mainnet', id]);
      await w.removeWallet('legacy-mainnet', WalletRemoval.list);
      expect((await w.wallets()).map((e) => e.id), [id]);
    });

    test('a failed delete of the open wallet still locks it', () async {
      final bad = _DeleteFails();
      final f = make(bad);
      addTearDown(f.dispose);
      await f.createWallet(name: 'Main', password: _password);
      await f.createWallet(name: 'Savings', password: _password);
      final id = bad.createdConfig!.walletId!;
      expect(await f.unlock(_password), isTrue);
      await expectLater(f.removeWallet(id, WalletRemoval.delete, password: _password), throwsA(isA<DeskError>()));
      await expectLater(f.balance(), throwsA(isA<DeskError>()), reason: 'locked, not open over a failed removal');
    });

    test('creating a wallet while another is open keeps the open one marked current', () async {
      await w.createWallet(name: 'Main', password: _password);
      expect(await w.unlock(_password), isTrue);
      await w.createWallet(name: 'Savings', password: _password);
      final ws = await w.wallets();
      expect(ws.map((e) => e.name), ['Main', 'Savings']);
      expect(ws.where((e) => e.current).single.id, 'legacy-mainnet');
      await w.restoreWallet(name: 'Third', password: _password, phrase: _TwoPhrases.other.split(' '));
      expect((await w.wallets()).where((e) => e.current).single.id, 'legacy-mainnet');
    });

    test('a node change with the second wallet open reopens that wallet, not the first', () async {
      await w.createWallet(name: 'Main', password: _password);
      await w.createWallet(name: 'Savings', password: _password);
      final id = rec.createdConfig!.walletId!;
      expect(await w.unlock(_password), isTrue);
      await w.useNode('https://node.epicnet.us:3413');
      expect((rec.opened.last.walletId, rec.opened.last.dataDir), (id, '${support.path}/wallets/$id/mainnet'));
      await w.useEpicbox('epicbox.epicnet.us');
      expect((rec.opened.last.walletId, rec.opened.last.dataDir), (id, '${support.path}/wallets/$id/mainnet'));
      expect((await w.account()).id, id);
    });

    test('favourites are kept per wallet', () async {
      await w.createWallet(name: 'Main', password: _password);
      await w.createWallet(name: 'Savings', password: _password);
      final id = rec.createdConfig!.walletId!;
      await w.selectWallet('legacy-mainnet');
      expect(await w.unlock(_password), isTrue);
      await w.saveContact(Contact(id: '', name: 'Ann', address: 'esA@epicbox.epiccash.com', favourite: true));
      Future<Contact> ann() async => (await w.contacts()).singleWhere((c) => c.name == 'Ann');
      expect((await ann()).favourite, isTrue);
      expect(await secrets.read('desk.favourites'), isNotNull);
      await w.selectWallet(id);
      expect(await w.unlock(_password), isTrue);
      expect((await w.contacts()).where((c) => c.name == 'Ann').single.favourite, isFalse, reason: 'wallet 2 has not marked it');
      expect(await secrets.read('desk.favourites.$id'), isNull);
      final firstFavourites = await secrets.read('desk.favourites');
      await w.saveContact(Contact(id: (await ann()).id, name: 'Ann', address: 'esA@epicbox.epiccash.com', favourite: true));
      expect(await secrets.read('desk.favourites.$id'), isNotNull);
      expect(await secrets.read('desk.favourites'), firstFavourites);
    });

    test('a restore from a block height scans from there once, and forgets it', () async {
      final session = _Starts();
      final gw = make(_TwoPhrases(session: session));
      addTearDown(gw.dispose);
      await gw.createWallet(name: 'Main', password: _password);
      await gw.restoreWallet(name: 'Old', password: _password, phrase: _TwoPhrases.other.split(' '), startHeight: BigInt.from(2800000));
      final id = (await gw.wallets()).last.id;
      expect(jsonDecode((await secrets.read('desk.wallet.mainnet.$id'))!), containsPair('scanFrom', 2800000));
      expect(await gw.unlock(_password), isTrue);
      await gw.sync();
      expect(session.starts, [BigInt.from(2800000)]);
      expect(jsonDecode((await secrets.read('desk.wallet.mainnet.$id'))!)['scanFrom'], isNull);
    });

    test('a restore without a start height scans the whole chain', () async {
      final session = _Starts();
      final gw = make(_TwoPhrases(session: session));
      addTearDown(gw.dispose);
      await gw.restoreWallet(name: 'Old', password: _password, phrase: _TwoPhrases.other.split(' '));
      expect(await gw.unlock(_password), isTrue);
      await gw.sync();
      expect(session.starts, [null]);
    });

    test('a scan that ends after a switch clears the flag of the wallet it ran for', () async {
      final session = _GatedScan();
      final gw = make(_TwoPhrases(session: session));
      addTearDown(gw.dispose);
      await gw.createWallet(name: 'Main', password: _password);
      await gw.restoreWallet(name: 'Savings', password: _password, phrase: _TwoPhrases.other.split(' '));
      final id = (await gw.wallets()).last.id;
      expect(jsonDecode((await secrets.read('desk.wallet.mainnet.$id'))!), containsPair('scanPending', true));
      expect(await gw.unlock(_password), isTrue); // Savings: the scan starts and waits
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await gw.lock();
      await gw.selectWallet('legacy-mainnet');
      expect(await gw.unlock(_password), isTrue);
      session.gate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(jsonDecode((await secrets.read('desk.wallet.mainnet.$id'))!), containsPair('scanPending', false));
      expect(jsonDecode((await secrets.read('desk.wallet.mainnet'))!).containsKey('scanPending'), isFalse);
    });

    group('a wallet list this version cannot write', () {
      File list() => File('${support.path}/wallets.json');

      test('a newer wallets.json still lists and opens the first wallet', () async {
        rec.existingWallets.add(first());
        await secrets.write('desk.wallet.mainnet', jsonEncode({'name': 'Tester'}));
        list().writeAsStringSync(jsonEncode({'version': 2, 'wallets': []}));
        final ws = await w.wallets();
        expect((ws.single.id, ws.single.name), ('legacy-mainnet', 'Tester'));
        expect(await w.unlock(_password), isTrue);
        await expectLater(
          w.renameWallet('legacy-mainnet', 'Other'),
          throwsA(isA<DeskError>().having((e) => e.message, 'message', 'Update the app to change the list')),
        );
      });

      test('a newer wallets.json does not bring back a first wallet removed from the list', () async {
        rec.existingWallets.add(first());
        await secrets.write('desk.wallet.mainnet', jsonEncode({'name': 'Tester', 'unlisted': true}));
        list().writeAsStringSync(jsonEncode({'version': 2, 'wallets': []}));
        expect(await w.wallets(), isEmpty);
      });

      test('an unreadable wallets.json lists the first wallet unless it was removed', () async {
        rec.existingWallets.add(first());
        await secrets.write('desk.wallet.mainnet', jsonEncode({'name': 'Tester'}));
        Directory(list().path).createSync(); // a folder where the file goes
        expect((await w.wallets()).single.id, 'legacy-mainnet');
        await secrets.write('desk.wallet.mainnet', jsonEncode({'name': 'Tester', 'unlisted': true}));
        expect(await w.wallets(), isEmpty);
      });

      test('a damaged wallets.json does not bring back a first wallet removed from the list', () async {
        rec.existingWallets.add(first());
        Directory('${first()}/lepic').createSync(recursive: true);
        await secrets.write('desk.wallet.mainnet', jsonEncode({'name': 'Tester', 'unlisted': true}));
        list().writeAsStringSync('not json');
        expect(await w.wallets(), isEmpty);
      });
    });

    test('a wallet that fails to be made leaves no half-made folder', () async {
      await w.createWallet(name: 'Main', password: _password);
      rec.createError = const core.WalletError(kind: core.WalletErrorKind.io, message: 'disk full');
      await expectLater(w.createWallet(name: 'Savings', password: _password), throwsA(isA<DeskError>()));
      expect(rec.deletedWallets.length, 1, reason: 'the new entry went through the registry delete path');
      expect(rec.deletedWallets.single, isNot(first()));
    });

    test('a wallet whose folder is gone is flagged', () async {
      await w.createWallet(name: 'Main', password: _password);
      await w.createWallet(name: 'Savings', password: _password);
      final id = rec.createdConfig!.walletId!;
      await Directory('${support.path}/wallets/$id').delete(recursive: true);
      final ws = await w.wallets();
      expect(ws.firstWhere((e) => e.id == id).missing, isTrue);
      expect(ws.firstWhere((e) => e.id == 'legacy-mainnet').missing, isFalse);
    });

    test('a wallet the core refuses to make leaves no entry', () async {
      await w.createWallet(name: 'Main', password: _password);
      rec.createError = const core.WalletError(kind: core.WalletErrorKind.io, message: 'disk full');
      await expectLater(w.createWallet(name: 'Savings', password: _password), throwsA(isA<DeskError>()));
      expect((await w.wallets()).map((e) => e.name), ['Main']);
      expect(Directory('${support.path}/wallets').listSync().map((e) => e.path.split('/').last), ['mainnet']);
    });
  });

  group('a lock during a sync (LNX-4)', () {
    test('the sync running when the wallet locks ends quietly, on nothing of the closed session', () async {
      final session = _HeldRefresh();
      service = core.FakeWalletService(password: _password, session: session);
      await wallet.dispose();
      wallet = make(service);
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await wallet.unlock(_password), isTrue);
      // The fake hands out one session object: Create's own use of it closed it.
      session.disposed = false;
      await wallet.sync();
      final reads = session.transactionsCalls;
      session.gate = Completer<void>();
      final running = wallet.sync();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await wallet.lock();
      expect(session.disposed, isTrue);
      session.gate!.complete();
      // No error out of the sync, and no call on the closed session.
      await expectLater(running, completes);
      expect(session.transactionsCalls, reads);
    });
  });

  group('payments under way', () {
    late _SlowSplit session;

    setUp(() async {
      session = _SlowSplit()..gate = Completer<void>();
      service = core.FakeWalletService(password: _password, session: session);
      await wallet.dispose();
      wallet = make(service);
      await created();
    });

    test('a lock waits for a split under way, and no payment starts while it waits', () async {
      final disposed = session.disposeCalls;
      final split = wallet.splitOutputs(2).then<Object?>((v) => v, onError: (Object e) => e);
      await Future<void>.delayed(Duration.zero);
      expect(wallet.busy, isTrue);
      var locked = false;
      final lock = wallet.lock().then((_) => locked = true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(locked, isFalse, reason: 'the split still runs');
      expect(session.disposeCalls, disposed);
      await expectLater(
        wallet.send(const SendRequest(method: TxMethod.file, amount: 100000000)),
        throwsA(isA<DeskError>().having((e) => e.locked, 'locked', isTrue)),
      );
      session.gate!.complete();
      await split;
      await lock;
      expect(locked, isTrue);
      expect(wallet.busy, isFalse);
      expect(session.disposeCalls, disposed + 1);
    });

    test('closing the app waits for a payment only up to closeWait', () async {
      final quick = LepicDeskWallet(
        service: service,
        walletDir: walletDir,
        secrets: secrets,
        filesDir: () async => files,
        nodePoll: const Duration(hours: 1),
        closeWait: const Duration(milliseconds: 50),
      );
      expect(await quick.unlock(_password), isTrue);
      final disposed = session.disposeCalls;
      unawaited(quick.splitOutputs(2).then<Object?>((v) => v, onError: (Object e) => e));
      await Future<void>.delayed(Duration.zero);
      expect(quick.busy, isTrue);
      await quick.dispose().timeout(const Duration(seconds: 5));
      expect(session.disposeCalls, disposed + 1, reason: 'locked though the split never finished');
      session.gate!.complete();
    });
  });

  group('hidden features', () {
    Future<void> pump(WidgetTester tester, DeskRoute route) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      // The Link parts are an Advanced switch; these tests look at what a build offers.
      await tester.runAsync(() => advancedOn(container));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: deskScreen(DeskLocation(route)))),
      ));
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    }

    testWidgets('welcome offers the import, no folder or network choice', (tester) async {
      await pump(tester, DeskRoute.welcome);
      expect(find.text('Import wallets'), findsOneWidget);
      expect(find.text('Advanced'), findsNothing);
      await done(tester);
    });

    testWidgets('settings list All wallets; node has no built-in node', (tester) async {
      await pump(tester, DeskRoute.settingsNode);
      expect(find.text('All wallets'), findsOneWidget);
      expect(find.text('Sync in background'), findsNothing);
      // "last block" is no longer hidden: the node card (W6 §17) prints it only from a real
      // answer (the status directory's tip age, or a node's header time).
      await done(tester);
    });

    testWidgets('receiving has HTTP receiving; the Tor switch is in Privacy as DeskFeatures.tor says', (tester) async {
      await pump(tester, DeskRoute.settingsReceiving);
      expect(find.text('Link · HTTP receiving'), findsOneWidget);
      expect(find.text('Tor receiving'), findsNothing);
      await done(tester);
      await pump(tester, DeskRoute.settingsPrivacy);
      expect(find.byKey(const ValueKey('privacy-tor-switch')), DeskFeatures.tor ? findsOneWidget : findsNothing);
      await done(tester);
    });

    testWidgets('send has Epicbox, Link and File (an onion is a Link send), no Dandelion++', (tester) async {
      await pump(tester, DeskRoute.send);
      expect(find.text('Link'), findsOneWidget);
      expect(find.text('Tor'), findsNothing, reason: 'no Tor method of its own');
      expect(find.textContaining('Dandelion'), findsNothing);
      await done(tester);
    });

    testWidgets('receive has the HTTP address with Tor off (Link over Tor shows only with it on)', (tester) async {
      await pump(tester, DeskRoute.receive);
      expect(find.text('Link · HTTP address'), findsOneWidget);
      expect(find.text('Link · Tor address'), findsNothing);
      await done(tester);
    });

    testWidgets('activity has one tab (Outputs is a page); account changes the password as DeskFeatures says', (tester) async {
      await pump(tester, DeskRoute.activity);
      expect(find.text('Transactions'), findsNothing);
      await done(tester);
      await pump(tester, DeskRoute.settingsAccount);
      expect(find.text('Change password…'), DeskFeatures.changePassword ? findsOneWidget : findsNothing);
      expect(find.text('Delete…'), findsOneWidget);
      await done(tester);
    });

    testWidgets('rescan has no repair option or Stop', (tester) async {
      await pump(tester, DeskRoute.settingsRescan);
      expect(find.text('Delete unconfirmed transactions'), findsNothing);
      await done(tester);
    });
  });
}
