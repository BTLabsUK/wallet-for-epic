// SPDX-License-Identifier: Apache-2.0
// The phone in the build without Tor (lib/src/tor_build.dart): tor is unavailable at once and
// never started, a saved Tor switch reads as off, an onion cannot be paid, and no update is
// asked for. Run both ways; the variant's checks are skipped with Tor in:
//   flutter test test/phone_no_tor_test.dart
//   flutter test --dart-define=WFE_TOR=false test/phone_no_tor_test.dart
import 'package:epic_wallet/src/contacts.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/tor_routes.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _skip = torBuilt ? 'Tor is in this build' : null;

final _config = mainnetPreset.config(dataDir: '/fake/wallets/mainnet', nodeUrl: 'https://node');

class _Config extends WalletConfigNotifier {
  @override
  WalletConfig? build() => _config;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l = lookupAppLocalizations(const Locale('en'));

  test('an onion is never offered: no Turn on Tor', () {
    for (final state in TorState.values) {
      expect(torWay(TorRoute.onionDirect, state), TorWay.off);
    }
  }, skip: _skip);

  test('an onion recipient says this version cannot send to it', () {
    final session = FakeWalletSession();
    final service = FakeWalletService(session: session);
    expect(checkRecipient(l, service, session.onion), l.sendTorNotInVersion);
    expect(l.sendTorNotInVersion, 'This version cannot send to Tor addresses.');
  }, skip: _skip);

  test('tor is unavailable at once, never starts, and the switch stays off', () async {
    final store = MemorySecretStore();
    final session = FakeWalletSession();
    // A switch saved on by a build with Tor.
    await store.write(PhoneTor.receivingKey(_config), 'true');
    expect(await PhoneTor.savedOn(store), isFalse);
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        secretStoreProvider.overrideWithValue(store),
        walletConfigProvider.overrideWith(_Config.new),
        torBundleFinderProvider.overrideWithValue(
          () async => const TorBundle(binary: '/data/app/lib/arm64/libtor.so'),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(phoneTorProvider, (_, _) {}, fireImmediately: true);
    expect(container.read(phoneTorProvider).phase, PhoneTorPhase.unavailable);
    container.read(sessionProvider.notifier).unlocked(session);
    final state = container.read(phoneTorProvider);
    expect(state.phase, PhoneTorPhase.unavailable);
    expect(state.settled, isTrue);
    expect(state.receiving, isFalse);
    await container.read(phoneTorProvider.notifier).setReceiving(true);
    await expectLater(
      container.read(phoneTorProvider.notifier).ensureForSend(),
      throwsA(isA<WalletError>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(session.torStarts, isEmpty);
    expect(container.read(phoneTorProvider).phase, PhoneTorPhase.unavailable);
    expect(container.read(epicboxOverTorProvider), isFalse);
    expect(container.read(epicboxWaitingForTorProvider), isFalse);
  }, skip: _skip);

  test('no in-app update check', () async {
    final container = ProviderContainer(retry: (_, _) => null);
    addTearDown(container.dispose);
    final update = container.read(updateProvider.notifier);
    expect(update.supported, isFalse);
    await update.check();
    expect(container.read(updateProvider).phase, UpdatePhase.idle);
  }, skip: _skip);
}
