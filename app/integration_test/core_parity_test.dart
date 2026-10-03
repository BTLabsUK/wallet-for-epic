// Runs the same calls on both cores, epic-wallet (`app/rust`) and LEPIC, in one process and
// expects the same outcome: a value, or the same WalletErrorKind. It is the check that LEPIC does
// what the app relies on from the old core. Calls LEPIC lacks are in lepic_mapping_test.dart.
//
//   tools/lepic.sh build linux
//   LEPIC_FFI_LIB="$(tools/lepic.sh lib)" flutter test integration_test/core_parity_test.dart -d linux
//
// Offline by default: the node is a closed port. With --dart-define=WFE_PARITY_ONLINE=true it
// also reads the tip and refreshes against node.btlabs.uk (mainnet, read-only).
//
// The phrases are public BIP-39 test vectors. Never fund them, never print a phrase or password.
import 'dart:io';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart' show minimumConfirmations;
import 'package:epic_wallet/src/rust/frb_generated.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _online = bool.fromEnvironment('WFE_PARITY_ONLINE');
const _unreachableNode = 'http://127.0.0.1:9';
const _onlineNode = 'https://node.btlabs.uk';
const _password = 'parity test password';

final _phrase24 = '${List.filled(23, 'abandon').join(' ')} art';
final _phrase12 = '${List.filled(11, 'abandon').join(' ')} about';

/// What a call produced, comparable across cores: its value or `error:<kind>`.
Future<Object?> _outcome(Future<Object?> Function() call) async {
  try {
    return await call();
  } on WalletError catch (e) {
    return 'error:${e.kind.name}';
  }
}

class _Core {
  _Core(this.name, this.service);

  final String name;
  final WalletService service;
  final List<Directory> _dirs = [];

  Future<WalletConfig> config(Chain chain, {String node = _unreachableNode}) async {
    final base = await getTemporaryDirectory();
    final dir = await base.createTemp('wfe-parity-$name-');
    _dirs.add(dir);
    final preset = chain == Chain.floonet ? floonetPreset : mainnetPreset;
    return preset.config(dataDir: dir.path, nodeUrl: node);
  }

  Future<void> cleanUp() async {
    for (final dir in _dirs) {
      if (dir.existsSync()) await dir.delete(recursive: true);
    }
  }
}

late final _Core _old;
late final _Core _new;

/// Runs [call] on both cores and returns the two outcomes, old first.
Future<(Object?, Object?)> _both(
  Future<Object?> Function(_Core core) call,
) async => (await _outcome(() => call(_old)), await _outcome(() => call(_new)));

void _same((Object?, Object?) outcomes, String what) => expect(
  outcomes.$2,
  outcomes.$1,
  reason: '$what: epic-wallet gave ${outcomes.$1}, LEPIC ${outcomes.$2}',
);

/// A difference the plan already tracks under [request]. It fails once the cores agree, so the
/// pin move that closes the gap turns it back into [_same].
void _gap((Object?, Object?) outcomes, String what, String request) {
  expect(
    outcomes.$2,
    isNot(outcomes.$1),
    reason: '$what now matches: $request is closed, use _same here',
  );
  debugPrint('known gap ($request) $what: epic-wallet ${outcomes.$1}, LEPIC ${outcomes.$2}');
}

/// Restores [phrase] on [chain] in a fresh directory and returns the open session.
Future<WalletSession> _restore(
  _Core core,
  Chain chain,
  String phrase, {
  String node = _unreachableNode,
}) async => core.service.create(
  config: await core.config(chain, node: node),
  mnemonic: phrase,
  password: _password,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
    await initLepic();
    _old = _Core('epicwallet', const RustWalletService());
    _new = _Core('lepic', LepicWalletService(secrets: MemorySecretStore()));
  });
  tearDownAll(() async {
    await _old.cleanUp();
    await _new.cleanUp();
  });

  testWidgets('both cores agree on which phrases are valid', (tester) async {
    final cases = {
      '24 words': _phrase24,
      '12 words': _phrase12,
      'bad checksum': List.filled(24, 'abandon').join(' '),
      'unknown word': '${List.filled(23, 'abandon').join(' ')} zzzz',
      '23 words': List.filled(23, 'abandon').join(' '),
      'empty': '',
    };
    for (final MapEntry(key: what, value: phrase) in cases.entries) {
      _same(
        await _both((c) async => c.service.validateMnemonic(phrase: phrase)),
        what,
      );
    }
  });

  // epic-wallet holds one chain per process, so every mainnet session closes before floonet.
  for (final chain in [Chain.mainnet, Chain.floonet]) {
    testWidgets('${chain.name}: a restored phrase gives the same wallet', (
      tester,
    ) async {
      final old = await _restore(_old, chain, _phrase24);
      final neu = await _restore(_new, chain, _phrase24);
      try {
        final address = await old.epicboxAddress();
        expect(await neu.epicboxAddress(), address, reason: 'epicbox address');

        expect(
          await old.mnemonic(password: _password) == _phrase24 &&
              await neu.mnemonic(password: _password) == _phrase24,
          isTrue,
          reason: 'both cores return the restored phrase',
        );
        _same(
          await _both(
            (c) => (c == _old ? old : neu).mnemonic(password: 'wrong'),
          ),
          'phrase with a wrong password',
        );

        Future<Map<String, Object>> balances(WalletSession s) async {
          final b = await s.summary(
            refresh: false,
            minimumConfirmations: minimumConfirmations,
          );
          return {
            'total': b.total,
            'spendable': b.spendable,
            'awaitingConfirmation': b.awaitingConfirmation,
            'awaitingFinalization': b.awaitingFinalization,
            'immature': b.immature,
            'locked': b.locked,
            'minimumConfirmations': b.minimumConfirmations,
          };
        }

        // LEPIC asks the node even without a refresh; the app shows local balances offline.
        _gap(
          await _both((c) => balances(c == _old ? old : neu)),
          'balances without a refresh',
          'UP-1',
        );

        final validity = {
          'own address': address,
          'garbage': 'not-an-address',
          'no relay': address.split('@').first,
        };
        for (final MapEntry(key: what, value: candidate) in validity.entries) {
          _same(
            await _both(
              (c) async => c.service.validateEpicboxAddress(address: candidate),
            ),
            'validate $what',
          );
        }

        _same(
          await _both((c) => (c == _old ? old : neu).receiveSlate(slateJson: '{}')),
          'receive an empty slate',
        );
        _same(
          await _both(
            (c) => (c == _old ? old : neu).finalizeAndPost(slateJson: 'nope'),
          ),
          'finalize text that is no slate',
        );
        _same(
          await _both(
            (c) => (c == _old ? old : neu).createSendSlate(
              amount: BigInt.from(100000000),
              minimumConfirmations: minimumConfirmations,
            ),
          ),
          'send from an empty wallet',
        );

        // The app shows Home after this: epic-wallet ends with local balances, marked as not
        // checked with the node.
        final watch = Stopwatch()..start();
        final refreshed = await _both((c) async {
          watch.reset();
          final last = await (c == _old ? old : neu)
              .refresh(minimumConfirmations: minimumConfirmations)
              .last
              .timeout(const Duration(seconds: 90));
          return 'percent ${last.percent}, '
              'checked ${last.summary?.validatedWithNode}, '
              'total ${last.summary?.total}';
        });
        debugPrint('refresh, closed port: LEPIC took ${watch.elapsed}');
        _gap(refreshed, 'refresh with the node unreachable', 'UP-1');
      } finally {
        old.dispose();
        neu.dispose();
      }
    });
  }

  testWidgets('wallet lifecycle: exists, wrong password, delete', (
    tester,
  ) async {
    for (final core in [_old, _new]) {
      final config = await core.config(Chain.mainnet);
      final steps = <String, Object?>{
        'exists before': await core.service.walletExists(config: config),
      };
      (await core.service.create(
        config: config,
        mnemonic: _phrase12,
        password: _password,
      )).dispose();
      steps['exists after'] = await core.service.walletExists(config: config);
      steps['create again'] = await _outcome(
        () async => (await core.service.create(
          config: config,
          password: _password,
        )).dispose(),
      );
      steps['wrong password'] = await _outcome(
        () => core.service.open(config: config, password: 'wrong'),
      );
      final opened = await core.service.open(
        config: config,
        password: _password,
      );
      opened.dispose();
      await core.service.deleteWallet(config: config);
      steps['exists after delete'] = await core.service.walletExists(
        config: config,
      );
      steps['open after delete'] = await _outcome(
        () => core.service.open(config: config, password: _password),
      );
      expect(steps, {
        'exists before': false,
        'exists after': true,
        'create again': 'error:walletAlreadyExists',
        'wrong password': 'error:wrongPassword',
        'exists after delete': false,
        'open after delete': 'error:walletNotFound',
      }, reason: core.name);
    }
  });

  testWidgets('an unreachable node fails the same way', (tester) async {
    _same(
      await _both(
        (c) async => c.service.nodeTip(config: await c.config(Chain.mainnet)),
      ),
      'tip of a closed port',
    );
  });

  testWidgets('online: same tip and refresh against node.btlabs.uk', (
    tester,
  ) async {
    final oldTip = await _old.service.nodeTip(
      config: await _old.config(Chain.mainnet, node: _onlineNode),
    );
    final newTip = await _new.service.nodeTip(
      config: await _new.config(Chain.mainnet, node: _onlineNode),
    );
    expect(
      (newTip.height - oldTip.height).abs() <= BigInt.two,
      isTrue,
      reason: 'tips ${oldTip.height} and ${newTip.height}',
    );

    final old = await _restore(_old, Chain.mainnet, _phrase12, node: _onlineNode);
    final neu = await _restore(_new, Chain.mainnet, _phrase12, node: _onlineNode);
    try {
      final oldLast = (await old
              .refresh(minimumConfirmations: minimumConfirmations)
              .toList())
          .last;
      final newLast = (await neu
              .refresh(minimumConfirmations: minimumConfirmations)
              .toList())
          .last;
      expect(newLast.percent, oldLast.percent);
      expect(newLast.summary?.total, oldLast.summary?.total);
      expect(
        newLast.summary?.validatedWithNode,
        oldLast.summary?.validatedWithNode,
      );
    } finally {
      old.dispose();
      neu.dispose();
    }
  }, skip: !_online);
}
