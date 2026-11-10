// SPDX-License-Identifier: Apache-2.0
// Pay with a file on the desktop for a paired contact (RFC 9.2): sealed as the phone seals it,
// "Sealed for Anna" with Send as plain instead; opened by a wallet paired with the sender,
// the file names its contact. A plain file stays Unknown sender, whatever address it claims.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/import_tx_screen.dart' show ImportArgs;
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart' show SendArgs;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/slate_files.dart' show isSealedText;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'review_password.dart';

final _l = englishStrings;

late ProviderContainer _container;

Future<MockDeskWallet> _open(WidgetTester tester, DeskRoute route, {Object? arg}) async {
  tester.view.physicalSize = const Size(1280, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final wallet = MockDeskWallet(delay: Duration.zero);
  _container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)], retry: (_, _) => null);
  addTearDown(_container.dispose);
  await tester.runAsync(() async {
    final n = _container.read(deskProvider.notifier);
    await n.refresh();
    await n.saveSettings(_container.read(deskProvider).settings.copyWith(tourSeen: true));
  });
  _container.read(deskNavProvider.notifier).reset(route, arg);
  await tester.pumpWidget(UncontrolledProviderScope(container: _container, child: const DeskApp()));
  await _settle(tester);
  return wallet;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await _settle(tester);
}

/// A sealed file from Anna's wallet to this one (the mock's pairing with Anna, as both sides
/// know it).
Future<String> _sealedFromAnna(WidgetTester tester) async {
  final anna = MockDeskWallet(delay: Duration.zero);
  final sent = await tester.runAsync(() => anna.send(const SendRequest(method: TxMethod.file, amount: 100000000, sealFor: mockAnnaPairing)));
  return anna.fileTexts[(sent! as SendFileReady).fileName]!;
}

void main() {
  testWidgets('Pay with a file for a paired contact: sealed for them, then Send as plain instead', (tester) async {
    final anna = (await tester.runAsync(MockDeskWallet(delay: Duration.zero).contacts))!.firstWhere((c) => c.id == 'c1');
    final wallet = await _open(tester, DeskRoute.send, arg: SendArgs(method: TxMethod.file, contact: anna, amount: '1'));
    expect(find.byKey(const ValueKey('send-file-for-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('send-file-sealed-badge')), findsOneWidget);

    await _tap(tester, find.widgetWithText(EButton, _l.deskSendReview));
    await enterReviewPassword(tester, 'right password');
    await _tap(tester, find.text('Send 1.0 EPIC'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _settle(tester);

    expect(find.byKey(const ValueKey('send-file-sealed')), findsOneWidget);
    expect(find.text(_l.sendSealedTitle('Anna Kowalska')), findsOneWidget);
    final name = wallet.fileTexts.keys.single;
    final text = wallet.fileTexts[name]!;
    expect(isSealedText(text), isTrue);
    expect(text.startsWith('BEGINEPICSEALED') || text.startsWith('BEGINEPICTX.'), isTrue);
    expect(find.text(name), findsWidgets);

    await _tap(tester, find.byKey(const ValueKey('send-file-as-plain')));
    expect(find.text(_l.sendAsPlainTitle), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('send-file-plain-confirm')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _settle(tester);
    expect(find.byKey(const ValueKey('send-file-ready')), findsOneWidget);
    final plain = wallet.fileTexts.entries.firstWhere((e) => e.key != name);
    expect(isSealedText(plain.value), isFalse);
    expect(find.text(plain.key), findsWidgets);
  });

  testWidgets('Pay with a file without a contact: no seal, the file is plain', (tester) async {
    final wallet = await _open(tester, DeskRoute.send, arg: const SendArgs(method: TxMethod.file, amount: '1'));
    expect(find.byKey(const ValueKey('send-file-for')), findsOneWidget);
    expect(find.byKey(const ValueKey('send-file-sealed-badge')), findsNothing);
    final sent = await tester.runAsync(() => wallet.send(const SendRequest(method: TxMethod.file, amount: 100000000)));
    expect((sent! as SendFileReady).sealedFor, isNull);
    expect(wallet.fileTexts, isEmpty);
  });

  testWidgets('a sealed file opened by a wallet paired with the sender names the contact', (tester) async {
    final text = await _sealedFromAnna(tester);
    await _open(tester, DeskRoute.importTx, arg: ImportArgs(text: text));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _settle(tester);
    final sender = tester.widget<Text>(find.byKey(const ValueKey('imp-sender')));
    expect(sender.data, 'Anna Kowalska');
    expect(find.text(_l.deskTxUnknownSender), findsNothing);
  });

  testWidgets('a plain file stays Unknown sender, whatever address it claims', (tester) async {
    const plain = '{"id":"9a8b7c6d-5e4f-4321-8765-0fedcba98765","sta":"S1","sender":"esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@relay.example.invalid"}';
    await _open(tester, DeskRoute.importTx, arg: const ImportArgs(text: plain));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _settle(tester);
    final sender = tester.widget<Text>(find.byKey(const ValueKey('imp-sender')));
    expect(sender.data, _l.deskTxUnknownSender);
  });
}
