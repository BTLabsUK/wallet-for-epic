// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/method_strip.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

/// Starts with [session] already unlocked.
class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

/// The open wallet is on mainnet, as after the launch screen.
class _MainnetConfig extends WalletConfigNotifier {
  @override
  WalletConfig? build() => mainnetPreset.config(
    dataDir: '/fake/wallets/mainnet',
    nodeUrl: mainnetPreset.nodeUrl,
  );
}

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

/// Pumps [screen] on a phone-shaped view and returns the scope's container.
Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget screen,
  MemorySecretStore store,
) async {
  // Tall: the test font draws every glyph a full em wide.
  tester.view.physicalSize = const Size(1080, 3300);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final session = FakeWalletSession(
    summary: WalletSummary(
      lastConfirmedHeight: BigInt.from(2499990),
      minimumConfirmations: BigInt.from(3),
      total: BigInt.from(4000000000),
      spendable: BigInt.from(4000000000),
      awaitingConfirmation: BigInt.zero,
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: BigInt.zero,
      validatedWithNode: true,
    ),
  )..address = '${'a' * 52}@epicbox.epiccash.com';
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(FakeWalletService()),
        secretStoreProvider.overrideWithValue(store),
        slateFilesProvider.overrideWithValue(FakeSlateFiles()),
        sessionProvider.overrideWith(() => _OpenSession(session)),
        walletConfigProvider.overrideWith(_MainnetConfig.new),
        relayDirectoryProvider.overrideWithValue(_NoRelays()),
        relayProbeProvider.overrideWithValue(FakeRelayProbe()),
        priceSourceProvider.overrideWithValue(_NoPrice()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

/// Where the strip and everything under it sit.
List<Offset> _places(WidgetTester tester, List<Finder> below) => [
  tester.getTopLeft(find.byKey(methodStripKey)),
  tester.getSize(find.byKey(methodStripKey)).bottomRight(Offset.zero),
  for (final f in below) tester.getTopLeft(f),
];

bool _seen(WidgetTester tester) =>
    tester
        .widget<AnimatedOpacity>(
          find
              .ancestor(
                of: find.byKey(methodStripKey),
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        )
        .opacity ==
    1;

Future<void> _closeAndBringBack(
  WidgetTester tester,
  ProviderContainer container,
  MemorySecretStore store,
  String id,
  List<Finder> below,
) async {
  final semantics = tester.ensureSemantics();
  await tester.pump();
  expect(_seen(tester), isTrue);
  expect(find.semantics.byLabel(_l.tipHide), findsOneWidget);
  final before = _places(tester, below);

  // Through the screen reader: the X is its own node, and its tap closes only the guide.
  tester.semantics.tap(find.semantics.byLabel(_l.tipHide));
  await tester.pumpAndSettle();

  expect(_places(tester, below), before, reason: 'nothing moves');
  expect(_seen(tester), isFalse);
  expect(find.semantics.byLabel('Hide tip'), findsNothing);
  expect(container.read(appSettingsProvider).value!.hiddenTips, {id});
  expect(store.values[AppSettingsNotifier.tipsHiddenKey], contains(id));
  expect(container.read(tipsHiddenProvider), isTrue);

  await container.read(appSettingsProvider.notifier).showTipsAgain();
  await tester.pumpAndSettle();

  expect(_places(tester, below), before, reason: 'nothing moves back');
  expect(_seen(tester), isTrue);
  expect(store.values[AppSettingsNotifier.tipsHiddenKey], isNull);
  expect(container.read(tipsHiddenProvider), isFalse);
  semantics.dispose();
}

void main() {
  testWidgets('Send: the method guide closes with its X and nothing moves', (
    tester,
  ) async {
    final store = MemorySecretStore();
    final container = await _pump(
      tester,
      SlotScaffold(
        appBar: AppBar(),
        body: SendView(onDone: () {}),
      ),
      store,
    );
    // The way is named on the file route; the recipient field picks the method on the first step.
    await tester.tap(find.text(_l.sendPayByFile));
    await tester.pumpAndSettle();
    await _closeAndBringBack(tester, container, store, sendMethodTipId, [
      find.byKey(sendFileAmountFieldKey),
    ]);
  });

  testWidgets('Receive: the method guide closes with its X and nothing moves', (
    tester,
  ) async {
    final store = MemorySecretStore();
    final container = await _pump(
      tester,
      const SlotScaffold(body: ReceiveView()),
      store,
    );
    await _closeAndBringBack(tester, container, store, receiveMethodTipId, [
      find.text(_l.receiveHelpButton),
    ]);
  });

  testWidgets('a closed guide stays closed after a restart', (tester) async {
    final store = MemorySecretStore()
      ..values[AppSettingsNotifier.tipsHiddenKey] = '["$receiveMethodTipId"]';
    await _pump(tester, const SlotScaffold(body: ReceiveView()), store);
    expect(_seen(tester), isFalse);
    expect(
      find.byKey(tipHideKey(receiveMethodTipId)).hitTestable(),
      findsNothing,
    );
  });
}
