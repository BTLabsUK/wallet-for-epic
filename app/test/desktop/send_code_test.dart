// SPDX-License-Identifier: Apache-2.0
// A pasted or linked `epic:` code on desktop Send:
// a payment request fills To, Amount and Message, the payee's words stay in a "not verified"
// block, and nothing is sent until the review and the password. Pasted codes Send cannot take
// stay in To with the reason under it; links get dialogs; plain text is typed text.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/pairing_state.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/finalize_screen.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/import_tx_screen.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_code.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// No saved contact has these.
const _e = 'esTk4wRm8Nq2Vx7Lc5Bh9Jd3Fg6Hs1Ka8Pz4Yu2Wn7Ec5Rt9Q@box.epic.invalid';
const _floonet = 'esFw9Rk2Lp4Nx8Vc3Bm7Hj5Gd1Sa6Qz2Wy4Ut8Re3Tn5Ym7K@box.epic.invalid';
// A mock contact.
const _anna = 'Anna Kowalska';
const _annaAddress = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@box.epic.invalid';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  int sends = 0;

  @override
  Future<SendResult> send(SendRequest request) {
    sends++;
    return super.send(request);
  }

  @override
  bool isEpicboxAddress(String to) => to.trim() != _floonet && super.isEpicboxAddress(to);

  @override
  bool epicboxAddressOtherChain(String to) => to.trim() == _floonet;
}

class _PastedWallet extends MockDeskWallet {
  _PastedWallet() : super(delay: Duration.zero);

  final texts = <String>[];
  bool notSlate = false;

  @override
  Future<ReceivedFile> receiveText(String text) {
    texts.add(text);
    if (notSlate) throw DeskError.l10n((l) => l.deskErrNotTxFile2, wrongType: true);
    return super.receiveText(text);
  }
}

void main() {
  late _Wallet wallet;
  late ProviderContainer container;
  String? clip;

  setUp(() {
    wallet = _Wallet();
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
    clip = null;
  });
  tearDown(() => container.dispose());

  /// A build that does not pair: a pairing link says so (the pairing flow has its own tests).
  void noPairing() {
    container.dispose();
    container = ProviderContainer(overrides: [
      deskApiProvider.overrideWithValue(wallet),
      deskPairsProvider.overrideWithValue(false),
    ]);
  }

  Future<void> show(WidgetTester tester, {Size size = const Size(1280, 1000), String? link, PaymentPrefs? payments}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.getData':
          return clip == null ? null : {'text': clip};
        case 'Clipboard.setData':
          clip = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.runAsync(() async {
      final n = container.read(deskProvider.notifier);
      await n.refresh();
      if (payments != null) await n.saveSettings(container.read(deskProvider).settings.copyWith(payments: payments));
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: Scaffold(body: SendScreen(arg: SendArgs(epicboxHealth: ServiceHealth.ok, code: link))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(of: find.widgetWithText(EField, label), matching: find.byType(EditableText));
  String text(WidgetTester tester, String label) => tester.widget<EditableText>(field(label)).controller.text;
  Finder inDialog(Finder f) => find.descendant(of: find.byType(Dialog), matching: f);
  Finder banner() => find.byKey(const ValueKey('send-code-banner'));

  /// The Paste button next to To (To must be empty), with [code] on the clipboard.
  Future<void> paste(WidgetTester tester, String code) async {
    clip = code;
    await tester.tap(find.byTooltip('Paste'));
    await tester.pumpAndSettle();
  }

  Future<void> clearTo(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Clear recipient'));
    await tester.pumpAndSettle();
  }

  /// A selectable text (the review's address) whose whole text is [s].
  Finder selectable(String s) => find.byWidgetPredicate((w) => w is SelectableText && (w.data ?? w.textSpan?.toPlainText()) == s);

  Future<void> review(WidgetTester tester) async {
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Check and send'), findsOneWidget);
  }

  testWidgets('a pasted payment request fills the form, says it is one, and sends nothing until review and password', (tester) async {
    await show(tester);
    await paste(tester, 'epic:$_e?amount=1.5&message=Lunch%20with%20Anna');
    expect(text(tester, 'To'), _e);
    expect(text(tester, 'Amount'), '1.5');
    expect(text(tester, 'Message'), 'Lunch with Anna');
    expect(banner(), findsOneWidget);
    expect(find.text('Invoice'), findsOneWidget);
    expect(find.text('Check the amount, then continue.'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const ValueKey('send-code-note'))).data, 'Lunch with Anna');
    expect(find.text('Message from the recipient (not verified)'), findsOneWidget);
    expect(find.text('Requested by the code'), findsOneWidget);
    expect(find.text('From the code. They see it too.'), findsOneWidget);
    expect(wallet.sends, 0);

    // The fields stay editable; the marker says what the code asked for.
    await tester.enterText(field('Amount'), '2');
    await tester.pump();
    expect(find.text('The code asked for 1.5000 EPIC.'), findsOneWidget);
    await tester.enterText(field('Amount'), '1.5');
    await tester.pumpAndSettle();

    await review(tester);
    expect(wallet.sends, 0);
    expect(inDialog(find.byKey(const ValueKey('send-review-origin'))), findsOneWidget);
    expect(inDialog(find.text('Pasted')), findsOneWidget);
    expect(inDialog(find.byWidgetPredicate((w) => w is EAddress && w.address == _e)), findsOneWidget, reason: 'the whole address, not shortened');
    expect(inDialog(find.byKey(const ValueKey('send-code-claims'))), findsOneWidget);

    final send = find.widgetWithText(EButton, 'Send 1.5000 EPIC');
    expect(tester.widget<EButton>(send).onPressed, isNull, reason: 'the password comes first');
    await tester.enterText(find.descendant(of: find.widgetWithText(EField, 'Password'), matching: find.byType(TextField)), 'secret-pass');
    await tester.pump();
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(wallet.sends, 1);
  });

  testWidgets("a second code replaces the first: its untouched amount and note never ride along", (tester) async {
    await show(tester);
    await paste(tester, 'epic:$_e?amount=5&message=Table%204');
    expect(text(tester, 'Amount'), '5');
    expect(text(tester, 'Message'), 'Table 4');
    // Pasted over the first one, To still holding its address.
    await tester.enterText(field('To'), 'epic:$_annaAddress?label=Bob');
    await tester.pumpAndSettle();
    expect(text(tester, 'To'), _annaAddress);
    expect(text(tester, 'Amount'), isEmpty);
    expect(text(tester, 'Message'), isEmpty);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('a request pasted into To goes the same way; typing "epic:" stays text; × hides the banner only', (tester) async {
    await show(tester);
    await tester.enterText(field('To'), 'epic:$_e?amount=3&label=Bakery');
    await tester.pumpAndSettle();
    expect(text(tester, 'To'), _e);
    expect(text(tester, 'Amount'), '3');
    expect(tester.widget<Text>(find.byKey(const ValueKey('send-code-label'))).data, 'Bakery');
    await tester.tap(find.byKey(const ValueKey('send-code-dismiss')));
    await tester.pumpAndSettle();
    expect(find.text('Invoice'), findsNothing);
    expect(find.byKey(const ValueKey('send-code-label')), findsOneWidget);

    // A different address: the code goes, and the amount it put in with it.
    await clearTo(tester);
    expect(find.byKey(const ValueKey('send-code-claims')), findsNothing);
    expect(text(tester, 'Amount'), '');
    for (final t in ['e', 'ep', 'epi', 'epic', 'epic:']) {
      await tester.enterText(field('To'), t);
      await tester.pump();
    }
    expect(find.byType(Dialog), findsNothing);
    expect(text(tester, 'To'), 'epic:');
    expect(banner(), findsNothing);
  });

  testWidgets('plain text pasted or typed is no code: To takes it, no dialog', (tester) async {
    await show(tester);
    await paste(tester, 'hello there friend');
    expect(find.byType(Dialog), findsNothing);
    expect(text(tester, 'To'), 'hello there friend');
    await tester.enterText(field('To'), 'Anna');
    await tester.pump();
    expect(find.byType(Dialog), findsNothing);
    expect(text(tester, 'To'), 'Anna');
    // An epic: text that is no request: today's path too.
    await clearTo(tester);
    await paste(tester, 'epic:$_e?amount=1&amount=2');
    expect(find.byType(Dialog), findsNothing);
    expect(text(tester, 'To'), 'epic:$_e?amount=1&amount=2');
    expect(banner(), findsNothing);
  });

  testWidgets('a pasted recovery phrase never stays in To nor shows: To empties, the note says why', (tester) async {
    await show(tester);
    await paste(tester, 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art');
    expect(text(tester, 'To'), '');
    expect(find.text('That is a recovery phrase, so it was not pasted. Keep it private.'), findsOneWidget);
    expect(find.textContaining('abandon'), findsNothing);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets("a code's name equal to a contact's selects no contact; the contact's address shows the contact's name", (tester) async {
    await show(tester);
    await paste(tester, 'epic:$_e?label=Anna%20Kowalska');
    expect(find.byKey(const ValueKey('send-picked')), findsNothing, reason: 'a code never selects a contact');
    expect(tester.widget<Text>(find.byKey(const ValueKey('send-code-label'))).data, _anna);

    await clearTo(tester);
    await paste(tester, 'epic:$_annaAddress?label=Mallory');
    expect(find.descendant(of: find.byKey(const ValueKey('send-picked')), matching: find.text(_anna)), findsWidgets);
    expect(tester.widget<Text>(find.byKey(const ValueKey('send-code-label'))).data, 'Mallory', reason: 'shown because it differs');

    await clearTo(tester);
    await paste(tester, 'epic:$_annaAddress?label=anna%20kowalska%20&amount=1');
    expect(find.byKey(const ValueKey('send-picked')), findsOneWidget);
    expect(find.byKey(const ValueKey('send-code-label')), findsNothing, reason: 'the same name is not shown twice');
    await review(tester);
    expect(inDialog(find.text(_anna)), findsOneWidget);
    expect(inDialog(find.byKey(const ValueKey('send-code-label'))), findsNothing);
  });

  testWidgets('pasted, another network, a bad address, a QR Payment part or a pairing link stay in To with the reason', (tester) async {
    noPairing();
    await show(tester);
    final cases = {
      'epic:$_floonet?amount=1': 'This address is for a different Epic network. This wallet cannot pay it.',
      'epic:notanaddress?amount=1': 'The address in this code is not valid.',
      'ur:epic-slate/1-3/lpadaxcsencylobemohsgmoyadtaadehoeadaeaoaeamtdaebs': 'A QR Payment code. Scan it with Epic Cash Mobile.',
      'epiccash://pair/1/AbCdEfGh123': 'Pairing is not available in this version.',
      // LNX-2: a code refused as a whole says so at once.
      'epic:$_annaAddress?amount=1&amount=2': 'This is not an Epic address or payment code.',
      'epic:$_annaAddress?${List.generate(9, (i) => 'x$i=1').join('&')}': 'This is not an Epic address or payment code.',
    };
    for (final MapEntry(key: code, value: reason) in cases.entries) {
      await paste(tester, code);
      expect(find.text(reason), findsOneWidget, reason: code);
      expect(text(tester, 'To'), code);
      expect(text(tester, 'Amount'), '');
      expect(find.byType(Dialog), findsNothing);
      await clearTo(tester);
      expect(find.text(reason), findsNothing, reason: 'editing To clears it');
    }
    // Typing clears the reason too.
    await paste(tester, 'epic:notanaddress');
    await tester.enterText(field('To'), 'epic:notanaddres');
    await tester.pump();
    expect(find.text('The address in this code is not valid.'), findsNothing);
  });

  testWidgets('a transaction file opens a dialog with the way to Import transaction', (tester) async {
    await show(tester);
    await paste(tester, 'BEGINSLATEPACK. 4H1qx1wHe668tFW yC2gfL8PPd8kSgv. ENDSLATEPACK.');
    expect(inDialog(find.text('Transaction file')), findsOneWidget);
    expect(text(tester, 'To'), '');
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(container.read(deskNavProvider).route, DeskRoute.importTx);
    // LNX-3: the pasted text goes along, not only the screen.
    expect((container.read(deskNavProvider).arg as ImportArgs?)?.text, 'BEGINSLATEPACK. 4H1qx1wHe668tFW yC2gfL8PPd8kSgv. ENDSLATEPACK.');
  });

  testWidgets('an answer to one of this wallet\'s sends goes to Finalize, not to signing (LNX-14)', (tester) async {
    const answer = '{"ver":"4:3","id":"0436430c-2b02-624c-2032-570501212b00","sta":"S2"}';
    await show(tester);
    await paste(tester, answer);
    expect(inDialog(find.text('Transaction file')), findsOneWidget);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(container.read(deskNavProvider).route, DeskRoute.finalize);
    expect((container.read(deskNavProvider).arg as FinalizeArgs?)?.text, answer);
  });

  testWidgets('the finalize screen finalizes a pasted answer at once (LNX-14)', (tester) async {
    final api = MockDeskWallet(delay: Duration.zero);
    final c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)]);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: FinalizeScreen(arg: FinalizeArgs(text: '{"ver":"4:3","sta":"S2"}')))),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Payment posted'), findsWidgets);
  });

  testWidgets('the import screen signs pasted text at once, as a chosen file (LNX-3)', (tester) async {
    final api = _PastedWallet();
    final c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)]);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: ImportTxScreen(arg: ImportArgs(text: '{"ver":"4:3"}')))),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(api.texts, ['{"ver":"4:3"}']);
    expect(find.text('Response saved'), findsOneWidget);
  });

  testWidgets('pasted text that is no transaction says so about text, not a file (LNX-3)', (tester) async {
    final api = _PastedWallet()..notSlate = true;
    final c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)]);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: ImportTxScreen(arg: ImportArgs(text: 'BEGINSLATEPACK. x. ENDSLATEPACK.')))),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('The pasted text is not a transaction. Paste the whole text the sender gave, or choose their file.'), findsOneWidget);
    expect(find.textContaining('.slate'), findsNothing);
  });

  testWidgets('a link opens Send filled the same way, "From a link" on the review', (tester) async {
    await show(tester, link: 'EPICCASH:$_e?AMOUNT=0.5');
    expect(text(tester, 'To'), _e);
    expect(text(tester, 'Amount'), '0.5');
    expect(banner(), findsOneWidget);
    await review(tester);
    expect(inDialog(find.text('From a link')), findsOneWidget);
    expect(wallet.sends, 0);
  });

  testWidgets("a link's bare address fills To without a banner; the review says where it came from", (tester) async {
    await show(tester, link: _e);
    expect(text(tester, 'To'), _e);
    expect(banner(), findsNothing);
    await tester.enterText(field('Amount'), '1');
    await tester.pumpAndSettle();
    await review(tester);
    expect(inDialog(find.text('From a link')), findsOneWidget);
  });

  for (final (link, title) in [
    ('epic:$_floonet', 'Other network'),
    ('epic:notanaddress', 'Not an Epic code'),
    ('bitcoin:1abc?amount=1', 'Not an Epic code'),
    ('epiccash://pair/1/AbCdEfGh123', 'Pairing link'),
  ]) {
    testWidgets('a link "$link" opens "$title" with Copy', (tester) async {
      if (link.startsWith('epiccash://pair/')) noPairing();
      await show(tester, link: link);
      expect(inDialog(find.text(title)), findsOneWidget);
      expect(text(tester, 'To'), '');
      await tester.tap(inDialog(find.text('Copy')));
      await tester.pumpAndSettle();
      expect(clip, link == 'epic:$_floonet' ? _floonet : link, reason: 'the whole text, or the address');
      expect(find.text('Copied'), findsOneWidget);
      await tester.tap(inDialog(find.text('OK')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('a dropped amount: the address fills, the banner says why Amount is empty', (tester) async {
    await show(tester);
    await tester.enterText(field('Amount'), '7');
    await paste(tester, 'epic:$_e?amount=0');
    expect(text(tester, 'To'), _e);
    expect(text(tester, 'Amount'), '');
    expect(find.descendant(of: banner(), matching: find.text('The amount in this code is not valid and was ignored.')), findsOneWidget);
    expect(find.text('Check the amount, then continue.'), findsNothing);
  });

  testWidgets('a plain epic: address is an address: no banner, no block', (tester) async {
    await show(tester);
    await paste(tester, 'epic:$_e');
    expect(text(tester, 'To'), _e);
    expect(banner(), findsNothing);
    expect(find.byKey(const ValueKey('send-code-claims')), findsNothing);
  });

  testWidgets('a note over 256 bytes stays in the block in full; Message stays as it was', (tester) async {
    await show(tester);
    final note = 'ก' * 100; // 300 UTF-8 bytes
    await paste(tester, 'epic:$_e?amount=1&message=${Uri.encodeComponent(note)}');
    expect(text(tester, 'Message'), '');
    expect(tester.widget<Text>(find.byKey(const ValueKey('send-code-note'))).data, note);
  });

  // The longest a code may carry: a 255-character Direct URL, a 264-character note, a 64-character name.
  final direct = 'https://pay.example.com:3415/${'v' * (255 - 'https://pay.example.com:3415/'.length)}';
  final note = '${List.generate(263, (i) => 'abcdefghij '[i % 11]).join()}z';
  for (final size in const [Size(1280, 800), Size(2474, 1338)]) {
    testWidgets('a 255-character Direct URL and a 264-character note fit at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      expect(direct.length, 255);
      // A Direct URL goes by Link · HTTP, off by default since the methods split.
      await show(tester, size: size, payments: const PaymentPrefs(linkHttp: true));
      await paste(tester, 'epic:$direct?amount=1&label=${Uri.encodeComponent('L' * 64)}&message=${Uri.encodeComponent(note)}');
      expect(text(tester, 'To'), direct);
      expect(tester.widget<Text>(find.byKey(const ValueKey('send-code-note'))).data, note);
      expect(text(tester, 'Message'), '', reason: '264 bytes do not fit a slate');
      expect(tester.takeException(), isNull);

      await review(tester);
      expect(inDialog(selectable('pay.example.com:3415')), findsOneWidget);
      expect(inDialog(selectable(direct)), findsOneWidget);
      expect(inDialog(find.byKey(const ValueKey('send-code-note'))), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('the payee name hides only for the same name, trimmed, in any case', () {
    expect(EPayeeClaims.labelBeside('Anna', null), 'Anna');
    expect(EPayeeClaims.labelBeside(' anna ', 'Anna'), isNull);
    expect(EPayeeClaims.labelBeside('Anna K', 'Anna'), 'Anna K');
  });
}
