// The tour opens by itself once: across restarts of the real adapter (LepicDeskWallet over the
// fake core) on one secret store, through the calls the app makes on a start (settings load,
// remembered unlock, refresh, startLive) and with the tour opened and closed in between.
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/desktop/app/tour.dart';
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';

/// The mock with a change stream and a status call that can be held, as a status read waits
/// behind a settings write in the Windows store.
class _SlowStatus extends MockDeskWallet {
  _SlowStatus() : super(delay: Duration.zero);

  final changed = StreamController<void>.broadcast();
  var holding = false;

  /// The status reads waiting, in call order.
  final held = <Completer<void>>[];

  @override
  Stream<void> changes() => changed.stream;

  @override
  Future<ServiceStatus> status() async {
    if (holding) {
      final gate = Completer<void>();
      held.add(gate);
      await gate.future;
    }
    return super.status();
  }
}

void main() {
  late Directory support;
  late MemorySecretStore secrets;
  late core.FakeWalletService service;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('desk-tour-restart-');
    secrets = MemorySecretStore();
    service = core.FakeWalletService(password: _password);
  });

  tearDown(() => support.delete(recursive: true));

  LepicDeskWallet wallet(DeskBoot boot) => LepicDeskWallet(
    service: service,
    walletDir: (chain) async {
      final d = Directory('${support.path}/wallets/${chain.name}');
      await d.create(recursive: true);
      return d.path;
    },
    secrets: secrets,
    filesDir: () async => support,
    settings: boot.settings,
    nodePoll: const Duration(hours: 1),
    rememberDir: () async => Directory('${support.path}/remember'),
  );

  /// One app start as main_desktop does it, up to Overview with the wallet open.
  Future<(ProviderContainer, LepicDeskWallet)> start() async {
    final store = DeskStore(secrets);
    final boot = await DeskBoot.load(store);
    final w = wallet(boot);
    final c = ProviderContainer(
      overrides: [
        deskApiProvider.overrideWithValue(w),
        deskStoreProvider.overrideWithValue(store),
        deskBootProvider.overrideWithValue(boot),
      ],
      retry: (_, _) => null,
    );
    final desk = c.read(deskProvider.notifier);
    final load = desk.loadSettings();
    if ((await w.wallets()).isEmpty) {
      await w.createWallet(name: 'Main', password: _password);
      expect(await w.unlock(_password, remember: true), isTrue);
    } else {
      expect(await w.unlockRemembered(), isTrue);
    }
    await desk.refresh();
    await desk.startLive();
    await load;
    return (c, w);
  }

  Future<void> quit(ProviderContainer c, LepicDeskWallet w) async {
    await c.read(deskProvider.notifier).lock();
    c.read(deskTourProvider.notifier).close();
    c.dispose();
    await w.dispose();
  }

  test('opened and closed on the first start, it is seen on the next', () async {
    var (c, w) = await start();
    expect(c.read(deskTourProvider).seen, isFalse);
    c.read(deskTourProvider.notifier).open();
    await pumpEventQueue();
    c.read(deskTourProvider.notifier).close();
    await quit(c, w);

    (c, w) = await start();
    expect((await DeskStore(secrets).settings()).tourSeen, isTrue);
    expect(c.read(deskTourProvider).seen, isTrue);
    await quit(c, w);
  });

  test('a status read under way when the tour opens does not undo its seen flag', () async {
    final store = DeskStore(secrets);
    final api = _SlowStatus();
    final c = ProviderContainer(
      overrides: [
        deskApiProvider.overrideWithValue(api),
        deskStoreProvider.overrideWithValue(store),
        deskBootProvider.overrideWithValue(await DeskBoot.load(store)),
      ],
      retry: (_, _) => null,
    );
    addTearDown(c.dispose);
    final desk = c.read(deskProvider.notifier);
    await desk.refresh();
    await desk.startLive();

    // Sync progress: the lists reload quietly and the status read takes a while.
    api.holding = true;
    api.changed.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    // The status poll's read, then the quiet reload's.
    expect(api.held, hasLength(2));
    c.read(deskTourProvider.notifier).open();
    await pumpEventQueue();
    api.holding = false;
    // The reload's read answers first; the tour's save waits on its own.
    api.held[1].complete();
    await pumpEventQueue();
    expect(c.read(deskProvider).settings.tourSeen, isTrue);
    for (final g in api.held) {
      if (!g.isCompleted) g.complete();
    }
    await pumpEventQueue();

    // Any later settings change (Hide amounts) saves what the app holds.
    await desk.saveSettings(c.read(deskProvider).settings.copyWith(hideAmounts: true));
    expect((await store.settings()).tourSeen, isTrue);
    await desk.lock();
  });

  group('the seen flag', () {
    Future<ProviderContainer> app(DeskStore store) async {
      final c = ProviderContainer(
        overrides: [
          deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)),
          deskStoreProvider.overrideWithValue(store),
          deskBootProvider.overrideWithValue(await DeskBoot.load(store)),
        ],
        retry: (_, _) => null,
      );
      addTearDown(c.dispose);
      return c;
    }

    test('a stale copy of the settings never saves it back to unseen', () async {
      final store = DeskStore(secrets);
      await store.saveSettings(const DeskSettings(tourSeen: true));
      await store.saveSettings(const DeskSettings(hideAmounts: true));
      final saved = await store.settings();
      expect(saved.tourSeen, isTrue);
      expect(saved.hideAmounts, isTrue);
    });

    test('does not open by itself when the store says seen, whatever the app holds', () async {
      final store = DeskStore(secrets);
      final c = await app(store);
      expect(c.read(deskTourProvider.notifier).seen, isFalse);
      // Seen since the start (another save of the flag): the store is asked before opening.
      await store.saveTourSeen();
      expect(await c.read(deskTourProvider.notifier).openIfUnseen(), isFalse);
      expect(c.read(deskTourProvider).open, isFalse);
      expect(c.read(deskTourProvider).seen, isTrue);
    });

    test('opens by itself when unseen and saves the flag at once', () async {
      final store = DeskStore(secrets);
      final c = await app(store);
      expect(await c.read(deskTourProvider.notifier).openIfUnseen(), isTrue);
      await pumpEventQueue();
      expect((await store.settings()).tourSeen, isTrue);
      expect(c.read(deskProvider).settings.tourSeen, isTrue);
      expect(await c.read(deskTourProvider.notifier).openIfUnseen(), isFalse);
    });

    test('closing an open tour saves it as seen, also when the save at opening was lost', () async {
      final store = DeskStore(secrets);
      final c = await app(store);
      c.read(deskTourProvider.notifier).open();
      await pumpEventQueue();
      await secrets.delete(DeskStore.settingsKey);
      c.read(deskTourProvider.notifier).close();
      await pumpEventQueue();
      expect((await store.settings()).tourSeen, isTrue);
    });

    test('Show the tour opens it again in this run; the next start still does not open it', () async {
      final store = DeskStore(secrets);
      final c = await app(store);
      c.read(deskTourProvider.notifier).open();
      c.read(deskTourProvider.notifier).close();
      await pumpEventQueue();
      c.read(deskTourProvider.notifier)
        ..reset()
        ..open();
      expect(c.read(deskTourProvider).open, isTrue);
      await pumpEventQueue();
      final next = await app(store);
      expect(next.read(deskTourProvider).seen, isTrue);
      expect(await next.read(deskTourProvider.notifier).openIfUnseen(), isFalse);
    });
  });
}
