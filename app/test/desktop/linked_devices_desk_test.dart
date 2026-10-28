// Linked devices on the desktop (Settings › Linked devices, the link dialog, the other device's
// payments): the code, the four pictures on both sides and the link; a payment of the phone holds
// its coins here (Locked in the balance, held in the outputs, a row Sent from the phone, the Send
// message) until Release by hand; the switch in Settings › Advanced hides it all.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/devices_state.dart';
import 'package:epic_wallet/src/desktop/data/mock_devices.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/devices/link_flow.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_devices.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart' show statusOf;
import 'package:epic_wallet/src/devices/device_ending.dart';
import 'package:epic_wallet/src/devices/device_service.dart';
import 'package:epic_wallet/src/devices/device_store.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/models.dart' show CancelReason, Chain, DeviceEnding;
import 'package:epic_wallet/src/ui/pairing/pairing_parts.dart' show WordTiles;
import 'package:epic_wallet/src/providers.dart' show secretStoreProvider;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockDeskWallet wallet;
  late ProviderContainer container;

  setUp(() {
    wallet = MockDeskWallet(delay: Duration.zero);
    container = ProviderContainer(
      overrides: [
        deskApiProvider.overrideWithValue(wallet),
        deskNodeProvider.overrideWithValue(MockDeskNode()),
        deskStoreProvider.overrideWithValue(DeskStore(MemorySecretStore())),
        secretStoreProvider.overrideWithValue(MemorySecretStore()),
        deskDeviceClockProvider.overrideWithValue(() => wallet.pairing.clock()),
      ],
    );
  });

  Future<void> settle(WidgetTester tester, [int n = 6]) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    }
  }

  Future<DeviceService> show(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    final service = container.read(deskDeviceServiceProvider)!;
    await tester.runAsync(service.load);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
      ),
    );
    await settle(tester);
    return service;
  }

  Future<void> end(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
  }

  /// A phone linked to the computer's service, paying with the mock's coin 6 (7.5 EPIC).
  Future<MockPhone> linkedPhone(WidgetTester tester, DeviceService desk) => tester.runAsync(() async {
    final phone = await MockPhone.create(wallet);
    await phone.link(desk);
    return phone;
  }).then((p) => p!);

  testWidgets('the section lists this computer, says none linked, and offers Link a device', (tester) async {
    await show(tester, const DevicesSettingsBlock());
    expect(find.text('Linked devices'), findsOneWidget);
    expect(find.byKey(const ValueKey('dev-this')), findsOneWidget);
    expect(find.text('Desktop'), findsOneWidget);
    expect(find.text('No device linked yet.'), findsOneWidget);
    expect(find.text('No coins held.'), findsOneWidget);
    expect(tester.widget<EButton>(find.byKey(devicesLinkKey)).onPressed, isNotNull);
    await end(tester);
  });

  testWidgets('Link a device: the code, the pictures on both devices, then linked', (tester) async {
    final desk = await show(tester, const DevicesSettingsBlock());
    final phone = (await tester.runAsync(() => MockPhone.create(wallet)))!;

    await tester.tap(find.byKey(devicesLinkKey));
    await settle(tester);
    expect(desk.link?.phase, LinkPhase.waiting);
    expect(find.byKey(deskLinkCodeKey), findsOneWidget);
    expect(find.text('Waiting for the other device…'), findsOneWidget);

    await tester.runAsync(() => phone.scan(desk));
    await settle(tester);
    expect(desk.link?.phase, LinkPhase.checking);
    expect(find.byType(WordTiles), findsOneWidget);
    expect(find.byKey(deskLinkMatchKey), findsOneWidget);

    await tester.tap(find.byKey(deskLinkMatchKey));
    await settle(tester);
    expect(desk.link?.phase, LinkPhase.waitingOther);
    expect(desk.book.devices, isEmpty, reason: 'nothing is linked until both matched');

    await tester.runAsync(() async {
      await phone.service.answerCheck(true);
      await phone.rounds(desk);
    });
    await settle(tester);
    expect(desk.link?.phase, LinkPhase.done);
    expect(find.text('Linked'), findsOneWidget);
    await tester.tap(find.byKey(deskLinkDoneKey));
    await settle(tester);
    expect(find.text('Phone'), findsWidgets);
    expect(desk.book.devices.single.name, 'Phone');
    await end(tester);
  });

  // A tester, 2026-10-28: the computer showed the code, the phone listed it, the computer never
  // listed the phone. A reopen of the wallet (node failover, a node or server change) while
  // the link was under way made a new devices service: the dialog finished the link on the old
  // one, the list showed the new one, and the new one saved its empty book over the link.
  testWidgets('the wallet reopens in the middle of a link: the computer still lists the phone', (tester) async {
    final desk = await show(tester, const DevicesSettingsBlock());
    final phone = (await tester.runAsync(() => MockPhone.create(wallet)))!;
    await tester.tap(find.byKey(devicesLinkKey));
    await settle(tester);
    await tester.runAsync(() => phone.scan(desk));
    await settle(tester);
    await tester.tap(find.byKey(deskLinkMatchKey));
    await settle(tester);
    expect(desk.link?.phase, LinkPhase.waitingOther);

    // Another node: the wallet reopens on it, then the lists reload.
    await tester.runAsync(() => container.read(deskProvider.notifier).useNode('https://node.example'));
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await settle(tester);
    expect(container.read(deskProvider).session, greaterThan(0));
    final shown = container.read(deskDeviceServiceProvider)!;
    expect(shown, same(desk), reason: 'one service for the open wallet, through the reopen');

    await tester.runAsync(() async {
      await phone.service.answerCheck(true);
      await phone.rounds(shown);
    });
    await settle(tester);
    expect(shown.link?.phase, LinkPhase.done);
    await tester.tap(find.byKey(deskLinkDoneKey));
    await settle(tester);
    expect(shown.book.devices.single.name, 'Phone');
    expect(phone.service.book.devices.single.name, 'Desktop');
    expect(find.byKey(ValueKey('dev-${phone.service.book.deviceId}')), findsOneWidget);
    // The book is kept: the next start lists the phone too.
    final again = DeviceStore(container.read(secretStoreProvider), chain: Chain.mainnet, walletId: container.read(deskProvider).account!.id);
    final stored = (await tester.runAsync(() => again.load(defaultName: 'x')))!;
    expect(stored.devices.single.deviceId, phone.service.book.deviceId);
    await end(tester);
  });

  testWidgets('a pasted code from another computer answers the link', (tester) async {
    final desk = await show(tester, const DevicesSettingsBlock());
    final phone = (await tester.runAsync(() => MockPhone.create(wallet, name: 'Laptop')))!;
    await tester.runAsync(() => phone.service.startShowing(const ['epicbox.epiccash.com']));
    final code = phone.service.link!.code!;

    await tester.tap(find.byKey(devicesLinkKey));
    await settle(tester);
    await tester.tap(find.text('Paste code'));
    await settle(tester);
    await tester.enterText(find.byKey(deskLinkPasteFieldKey), code);
    await tester.tap(find.byKey(deskLinkGoKey));
    await settle(tester);
    await tester.runAsync(() => phone.rounds(desk));
    await settle(tester);
    expect(desk.link?.phase, LinkPhase.checking);
    await tester.tap(find.byKey(deskLinkNoMatchKey));
    await settle(tester);
    expect(desk.link?.phase, LinkPhase.failed);
    expect(find.text('The pictures differ, so the devices were not linked.'), findsOneWidget);
    expect(desk.book.devices, isEmpty);
    await end(tester);
  });

  testWidgets('a pasted code of another wallet is refused at once, before it is answered', (tester) async {
    final desk = await show(tester, const DevicesSettingsBlock());
    final phone = (await tester.runAsync(() => MockPhone.create(wallet, name: 'Laptop', walletKey: 'esAnotherWalletKey')))!;
    await tester.runAsync(() => phone.service.startShowing(const ['epicbox.epiccash.com']));
    final code = phone.service.link!.code!;

    await tester.tap(find.byKey(devicesLinkKey));
    await settle(tester);
    await tester.tap(find.text('Paste code'));
    await settle(tester);
    await tester.enterText(find.byKey(deskLinkPasteFieldKey), code);
    await tester.tap(find.byKey(deskLinkGoKey));
    await settle(tester);
    expect(desk.link?.phase, LinkPhase.failed);
    expect(desk.link?.failure, LinkFailure.otherWalletCode);
    expect(find.text('This code is from a different wallet.'), findsOneWidget);
    await tester.runAsync(() => phone.rounds(desk));
    expect(phone.service.link?.phase, LinkPhase.waiting);
    expect(desk.book.devices, isEmpty);
    await end(tester);
  });

  testWidgets('a text that is no device code is refused in the paste tab', (tester) async {
    await show(tester, const DevicesSettingsBlock());
    await tester.tap(find.byKey(devicesLinkKey));
    await settle(tester);
    await tester.tap(find.text('Paste code'));
    await settle(tester);
    await tester.enterText(find.byKey(deskLinkPasteFieldKey), 'epiccash://pair/abc');
    await tester.tap(find.byKey(deskLinkGoKey));
    await settle(tester);
    expect(find.text('This is not a device link code, or it is damaged.'), findsOneWidget);
    await end(tester);
  });

  testWidgets("the phone's payment holds its coin here until Release by hand", (tester) async {
    final desk = await show(tester, const DevicesSettingsBlock());
    final phone = await linkedPhone(tester, desk);
    final coin = mockCommitment(6);
    final before = (await tester.runAsync(wallet.balance))!;
    await tester.runAsync(() => phone.makePayment(desk, commitment: coin, message: 'Rent'));
    await settle(tester);

    final hold = desk.book.holds.single;
    expect(hold.state, HoldState.held);
    expect(hold.deviceName, 'Phone');

    // The balance moves the coin from spendable to locked; the outputs name the payment.
    final after = (await tester.runAsync(wallet.balance))!;
    final value = 750000000;
    expect(after.spendable, before.spendable - value);
    expect(after.locked, before.locked + value);
    expect(after.total, before.total);
    final held = (await tester.runAsync(wallet.outputs))!.singleWhere((o) => o.commitment == coin);
    expect(held.word, OutputWord.locked);
    expect(held.heldBy, 'Phone');

    // The history has the row, pending, from the phone.
    final rows = (await tester.runAsync(wallet.transactions))!.where((t) => t.deviceName != null).toList();
    expect(rows.single.deviceName, 'Phone');
    expect(rows.single.state, TxState.waitingRecipient);
    expect(rows.single.message, 'Rent');

    // Settings lists it, with Release; the confirm says it may still be finishing.
    expect(find.byKey(devicesHeldKey), findsOneWidget);
    expect(find.text("Held by Phone’s payment"), findsOneWidget);
    await tester.tap(find.text('Release'));
    await settle(tester);
    expect(find.text('Release these coins?'), findsOneWidget);
    expect(find.textContaining('may still be finishing this payment'), findsOneWidget);
    await tester.tap(find.byKey(devicesReleaseConfirmKey));
    await settle(tester);
    expect(desk.book.holds.single.state, HoldState.byHand);
    expect(find.text('No coins held.'), findsOneWidget);

    // Released here: the coin is spendable again, and the row reads that the phone may still send it.
    final freed = (await tester.runAsync(wallet.balance))!;
    expect(freed.spendable, before.spendable);
    final row = (await tester.runAsync(wallet.transactions))!.singleWhere((t) => t.deviceName != null);
    expect(row.deviceEnding, DeviceEnding.releasedHere);
    await end(tester);
  });

  testWidgets("the phone's payment ends there: the coin is free here and the row says how", (tester) async {
    final desk = await show(tester, const DevicesSettingsBlock());
    final phone = await linkedPhone(tester, desk);
    final coin = mockCommitment(6);
    final before = (await tester.runAsync(wallet.balance))!;
    await tester.runAsync(() => phone.makePayment(desk, commitment: coin));
    await tester.runAsync(() => phone.end(desk, commitment: coin, reason: CancelReason.failed));
    await settle(tester);
    expect(desk.book.holds.single.state, HoldState.released);
    final after = (await tester.runAsync(wallet.balance))!;
    expect(after.spendable, before.spendable);
    final row = (await tester.runAsync(wallet.transactions))!.singleWhere((t) => t.deviceName != null);
    expect(row.deviceEnding, DeviceEnding.failed);
    expect(row.deviceWhy, 'notDelivered');
    final l = englishStrings;
    expect(statusOf(l, row).$1, 'Failed on Phone');
    expect(deviceEndingLine(l, row.deviceEnding!, 'Phone', row.deviceWhy), contains('could not deliver'));
    await end(tester);
  });

  testWidgets('removing a device asks first and says it does not protect the money', (tester) async {
    final desk = await show(tester, const DevicesSettingsBlock());
    final phone = await linkedPhone(tester, desk);
    await settle(tester);
    expect(phone.service.book.devices, isNotEmpty);
    await tester.tap(find.byKey(ValueKey('dev-remove-${desk.book.devices.single.deviceId}')));
    await settle(tester);
    expect(find.text('Remove Phone?'), findsOneWidget);
    expect(find.textContaining('stops getting and sending notices'), findsOneWidget);
    await tester.tap(find.byKey(devicesRemoveConfirmKey));
    await settle(tester);
    expect(desk.book.devices, isEmpty);
    await end(tester);
  });

  testWidgets('Linked devices off: no service, no section', (tester) async {
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    final s = container.read(deskProvider).settings;
    await tester.runAsync(() => container.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: s.advanced.withFeature(AdvancedFeature.linkedDevices, false))));
    expect(container.read(deskLinkedDevicesOnProvider), isFalse);
    expect(container.read(deskDeviceServiceProvider), isNull);
    container.dispose();
  });
}
