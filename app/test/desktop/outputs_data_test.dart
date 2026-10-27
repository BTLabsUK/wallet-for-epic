// F11–F13 data on the desktop, no screens: LepicDeskWallet over FakeWalletSession maps outputs,
// passes send options, returns the whole estimate, runs splits and consolidates, and reads
// the per-wallet Outputs choices. The password is a throwaway test value.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/smart_outputs.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const int _epic = 100000000;

core.WalletOutput _out(
  String c,
  int value, {
  core.WalletOutputStatus status = core.WalletOutputStatus.unspent,
  core.OutputCategory? category = core.OutputCategory.spendable,
  bool coinbase = false,
  int confirmations = 20,
  int? txId = 4,
}) => core.WalletOutput(
  commitment: c,
  value: BigInt.from(value),
  status: status,
  category: category,
  isCoinbase: coinbase,
  height: BigInt.from(2499990),
  lockHeight: BigInt.from(coinbase ? 2501430 : 0),
  mmrIndex: status == core.WalletOutputStatus.unconfirmed ? null : BigInt.from(77),
  confirmations: BigInt.from(confirmations),
  txId: txId,
);

void main() {
  group('deskOutput', () {
    test('status from LEPIC status and category', () {
      OutputStatus st(core.WalletOutputStatus s, core.OutputCategory? c) => deskOutput(_out('c', 1, status: s, category: c), minConf: 3).status;
      expect(st(core.WalletOutputStatus.unspent, core.OutputCategory.spendable), OutputStatus.unspent);
      expect(st(core.WalletOutputStatus.unspent, core.OutputCategory.awaitingConfirmation), OutputStatus.confirming);
      expect(st(core.WalletOutputStatus.unspent, core.OutputCategory.immature), OutputStatus.immature);
      expect(st(core.WalletOutputStatus.unspent, core.OutputCategory.locked), OutputStatus.locked);
      expect(st(core.WalletOutputStatus.locked, core.OutputCategory.locked), OutputStatus.locked);
      expect(st(core.WalletOutputStatus.unconfirmed, core.OutputCategory.awaitingConfirmation), OutputStatus.unconfirmed);
      expect(st(core.WalletOutputStatus.unconfirmed, null), OutputStatus.unconfirmed);
      expect(st(core.WalletOutputStatus.spent, null), OutputStatus.spent);
    });

    test('fields: height only on chain, lock height only for rewards', () {
      final o = deskOutput(_out('08ab', 5 * _epic, coinbase: true, category: core.OutputCategory.immature), minConf: 3);
      expect(o.commitment, '08ab');
      expect(o.value, 5 * _epic);
      expect(o.height, 2499990);
      expect(o.lockHeight, 2501430);
      expect(o.isCoinbase, true);
      expect(o.mmrIndex, 77);
      expect(o.confirmations, 20);
      expect(o.confirmationsNeeded, 3);
      expect(o.txId, 4);
      expect(o.spendable, false);
      final pending = deskOutput(_out('09', 1, status: core.WalletOutputStatus.unconfirmed, confirmations: 0), minConf: 3);
      expect(pending.height, isNull);
      expect(pending.lockHeight, isNull);
      expect(pending.mmrIndex, isNull);
    });

    test('the word each output shows', () {
      OutputWord w(core.WalletOutputStatus s, core.OutputCategory? c, {bool coinbase = false}) =>
          deskOutput(_out('c', 1, status: s, category: c, coinbase: coinbase), minConf: 3).word;
      expect(w(core.WalletOutputStatus.unspent, core.OutputCategory.spendable), OutputWord.spendable);
      expect(w(core.WalletOutputStatus.unspent, core.OutputCategory.awaitingConfirmation), OutputWord.confirming);
      expect(w(core.WalletOutputStatus.unconfirmed, core.OutputCategory.awaitingFinalization), OutputWord.finalizing);
      expect(w(core.WalletOutputStatus.unconfirmed, null, coinbase: true), OutputWord.mining);
      // Unconfirmed in any other category, a reward included, is confirming (spec §2.2).
      expect(w(core.WalletOutputStatus.unconfirmed, core.OutputCategory.awaitingConfirmation), OutputWord.confirming);
      expect(w(core.WalletOutputStatus.unconfirmed, null), OutputWord.confirming);
      expect(w(core.WalletOutputStatus.unconfirmed, core.OutputCategory.awaitingConfirmation, coinbase: true), OutputWord.confirming);
      expect(w(core.WalletOutputStatus.unspent, core.OutputCategory.immature, coinbase: true), OutputWord.immature);
      expect(w(core.WalletOutputStatus.locked, core.OutputCategory.locked), OutputWord.locked);
      expect(w(core.WalletOutputStatus.spent, null), OutputWord.spent);
    });
  });

  group('LepicDeskWallet', () {
    late Directory support;
    late core.FakeWalletService service;
    late MemorySecretStore secrets;
    late LepicDeskWallet wallet;
    core.FakeWalletSession session() => service.session;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('desk-outputs-test-');
      service = core.FakeWalletService(password: _password);
      secrets = MemorySecretStore();
      wallet = LepicDeskWallet(
        service: service,
        walletDir: (chain) async {
          final dir = Directory('${support.path}/wallets/${chain.name}');
          await dir.create(recursive: true);
          return dir.path;
        },
        secrets: secrets,
        filesDir: () async => support,
        nodePoll: const Duration(hours: 1),
      );
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await wallet.unlock(_password), isTrue);
      session()
        ..summaryValue = core.WalletSummary(
          lastConfirmedHeight: BigInt.from(2500000),
          minimumConfirmations: BigInt.from(3),
          total: BigInt.from(100 * _epic),
          spendable: BigInt.from(100 * _epic),
          awaitingConfirmation: BigInt.zero,
          awaitingFinalization: BigInt.zero,
          immature: BigInt.zero,
          locked: BigInt.zero,
          validatedWithNode: true,
        )
        ..outputsValue = [_out('c1', 100 * _epic)];
    });

    tearDown(() async {
      await wallet.dispose();
      await support.delete(recursive: true);
    });

    test('outputs come from the wallet', () async {
      session().outputsValue = [_out('c1', 100 * _epic), _out('c2', _epic, status: core.WalletOutputStatus.spent, category: null)];
      final list = await wallet.outputs();
      expect([for (final o in list) (o.commitment, o.status)], [('c1', OutputStatus.unspent), ('c2', OutputStatus.spent)]);
    });

    test('the whole estimate, with the options given', () async {
      const options = SendOptions(changeOutputs: 4);
      final e = await wallet.estimateSend(_epic, options: options);
      expect(session().estimateOptions.last, options);
      expect(e.inputCount, 1);
      expect(e.locked, 100 * _epic);
      expect(e.changeOutputs, 4);
      expect(e.change, 100 * _epic - _epic - e.fee);
      // Without options: the wallet's default.
      await wallet.estimateSend(_epic);
      expect(session().estimateOptions.last, isNull);
    });

    test('SmartOutputs plans the split through the adapter', () async {
      final plan = await planSend(
        estimate: (o) => wallet.estimateSend(_epic, options: o),
        strategy: SelectionStrategy.smallest,
        smartOutputsOn: true,
        spendableOutputs: (await wallet.outputs()).where((o) => o.spendable).length,
        splitRefused: deskSplitRefused,
      );
      expect(plan.options.changeOutputs, 4);
      expect(plan.extraFee, 3 * session().changeOutputFee.toInt());
    });

    test('a split the coins cannot build is marked, and the plan falls back', () async {
      // Change of 3 base units after the split's fee: too small for 4 outputs.
      session().outputsValue = [_out('c1', _epic + session().fee.toInt() + 3 * session().changeOutputFee.toInt() + 3)];
      await expectLater(
        wallet.estimateSend(_epic, options: const SendOptions(changeOutputs: 4)),
        throwsA(isA<DeskError>().having((e) => e.unbuildable, 'unbuildable', isTrue)),
      );
      final plan = await planSend(
        estimate: (o) => wallet.estimateSend(_epic, options: o),
        strategy: SelectionStrategy.smallest,
        smartOutputsOn: true,
        spendableOutputs: 1,
        splitRefused: deskSplitRefused,
      );
      expect(plan.splits, isFalse);
      expect(plan.estimate.changeOutputs, 1);
    });

    test('the send carries its options', () async {
      const options = SendOptions(strategy: SelectionStrategy.all, changeOutputs: 3);
      final r = await wallet.send(SendRequest(method: TxMethod.epicbox, amount: 1000, to: '${'1' * 52}@epicbox.epiccash.com', options: options));
      expect(r, isA<SendDone>());
      await wallet.send(const SendRequest(method: TxMethod.file, amount: 1000));
      expect(session().sentOptions, [options, null]);
    });

    test('split and consolidate: estimate, run, and the balance reloads', () async {
      final e = await wallet.estimateSplit(4);
      expect(e.inputCount, 1);
      expect(e.changeOutputs, 3);
      var changed = 0;
      final sub = wallet.changes().listen((_) => changed++);
      final s = await wallet.splitOutputs(4);
      await Future<void>.delayed(Duration.zero);
      expect(s.outputCount, 4);
      expect(session().splits, [4]);
      expect(changed, greaterThan(0));
      final locked = await wallet.outputs();
      expect(locked.where((o) => o.status == OutputStatus.locked).length, 1);
      expect(locked.where((o) => o.status == OutputStatus.confirming || o.status == OutputStatus.unconfirmed).length, 4);
      await sub.cancel();

      session().outputsValue = [_out('a', _epic), _out('b', 2 * _epic)];
      final c = await wallet.estimateConsolidate();
      expect(c.inputCount, 2);
      final done = await wallet.consolidateOutputs();
      expect(done.outputCount, 1);
      expect(session().consolidations, 1);
      await expectLater(wallet.estimateSplit(11), throwsA(isA<DeskError>()));
    });

    test('Outputs choices: Smallest and SmartOutputs on unless saved', () async {
      expect(await wallet.outputPrefs(), const OutputPrefs());
      expect(const OutputPrefs().strategy, SelectionStrategy.smallest);
      expect(const OutputPrefs().smartOutputs, isTrue);
      final store = DeskStore(secrets);
      const all = OutputPrefs(strategy: SelectionStrategy.all, smartOutputs: false);
      // The first wallet keeps its choices under the plain key.
      await store.saveOutputPrefs(null, all);
      expect(await wallet.outputPrefs(), all);
    });
  });

  group('DeskStore Outputs choices', () {
    test('per wallet, defaults on missing or damaged values', () async {
      final secrets = MemorySecretStore();
      final store = DeskStore(secrets);
      expect(await store.outputPrefs(null), const OutputPrefs());
      await store.saveOutputPrefs('w2', const OutputPrefs(strategy: SelectionStrategy.all));
      expect(await store.outputPrefs('w2'), const OutputPrefs(strategy: SelectionStrategy.all));
      expect(await store.outputPrefs(null), const OutputPrefs());
      await secrets.write(DeskStore.outputsKeyOf(null), '{"strategy":"biggest","smartOutputs":"yes"}');
      expect(await store.outputPrefs(null), const OutputPrefs());
      await secrets.write(DeskStore.outputsKeyOf(null), 'not json');
      expect(await store.outputPrefs(null), const OutputPrefs());
    });
  });

  group('mock', () {
    test('estimates, plans and splits like the wallet', () async {
      final m = MockDeskWallet(delay: Duration.zero);
      final e = await m.estimateSend(_epic);
      expect(e.inputCount, greaterThan(0));
      expect(e.locked, e.amount + e.fee + e.change);
      final all = await m.estimateSend(_epic, options: const SendOptions(strategy: SelectionStrategy.all));
      expect(all.inputCount, (await m.outputs()).where((o) => o.spendable).length);
      final split = await m.estimateSplit(4);
      expect(split.changeOutputs, 3);
      final spendable = (await m.outputs()).where((o) => o.spendable).length;
      expect((await m.splitOutputs(4)).outputCount, 4);
      final after = await m.outputs();
      expect(after.where((o) => o.spendable), isEmpty);
      expect(after.where((o) => o.status == OutputStatus.locked).length, spendable + 1);
      expect(after.where((o) => o.word == OutputWord.finalizing).length, 4 + (await MockDeskWallet(delay: Duration.zero).outputs()).where((o) => o.word == OutputWord.finalizing).length);
      // Nothing spendable until the split confirms.
      await expectLater(m.consolidateOutputs(), throwsA(isA<DeskError>()));
      expect(await m.outputPrefs(), const OutputPrefs());
    });
  });
}
