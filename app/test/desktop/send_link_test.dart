// SPDX-License-Identifier: Apache-2.0
// Send from a payment link on the desktop: a pasted link of any host fills To and Amount with
// the trust line under To; a refused link says why (under To when pasted, a dialog from a
// link); a request paid before asks; a listing that changed wallet asks once more before the
// review; a paid link is recorded and its payee can be saved. Real texts from the vectors.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/pairing_state.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/link_trust.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/directory/directory.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/scan/incoming_link.dart' show linkClockProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/link_support.dart';

final _l = englishStrings;

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  int sends = 0;

  @override
  Future<SendResult> send(SendRequest request) {
    sends++;
    return super.send(request);
  }

  // The vectors' listing address is an Epicbox address for the mock.
  @override
  bool isEpicboxAddress(String to) => to.contains('@') || super.isEpicboxAddress(to);
}

void main() {
  final vectors = LinkVectors();
  late _Wallet wallet;
  String? clip;

  setUp(() {
    wallet = _Wallet()..linkVerifier = VectorWalletService(vectors.listed).verifyListingSignature;
    clip = null;
  });

  Future<ProviderContainer> show(
    WidgetTester tester, {
    FakeMembership? membership,
    DateTime? now,
    String? link,
    Size size = const Size(1280, 1000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return clip == null ? null : {'text': clip};
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final container = ProviderContainer(
      overrides: [
        deskApiProvider.overrideWithValue(wallet),
        linkClockProvider.overrideWithValue(() => now ?? linkNow),
        directoryMembershipProvider.overrideWithValue(membership ?? FakeMembership()),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
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
    return container;
  }

  Finder field(String label) => find.descendant(of: find.widgetWithText(EField, label), matching: find.byType(EditableText));
  String text(WidgetTester tester, String label) => tester.widget<EditableText>(field(label)).controller.text;
  Finder trust() => find.byKey(deskLinkTrustKey);
  Finder inDialog(Finder f) => find.descendant(of: find.byType(Dialog), matching: f);

  Future<void> paste(WidgetTester tester, String code) async {
    clip = code;
    await tester.tap(find.byTooltip(_l.commonPaste));
    await tester.pumpAndSettle();
  }

  final address = vectors.request('req-basic').card.address;
  final listed = FakeMembership(labels: {vectorDkey: 'Epic Directory'});
  final changedPin = {
    pinKey(vectors.request('req-basic').card.dkey, vectors.request('req-basic').card.handle): const ListingPin(
      listingKey: '03aa8c2f48c588fa84ed97a219b9841579c04241c1cef99b69bb19bb5168011df6',
      firstPaid: 1790000000,
      lastPaid: 1790000000,
    ),
  };

  group('trust line', () {
    testWidgets('a directory in use', (tester) async {
      await show(tester, membership: listed);
      await paste(tester, vectors.https('req-basic'));
      expect(text(tester, 'To'), address);
      expect(find.text('@alice_test · listed by Epic Directory'), findsOneWidget);
      expect(find.descendant(of: trust(), matching: find.byType(Wrap)), findsOneWidget);
    });

    testWidgets('another directory: no name', (tester) async {
      await show(tester);
      await paste(tester, vectors.https('req-basic'));
      expect(find.text(_l.linkTrustOther), findsOneWidget);
      expect(find.textContaining('alice_test'), findsNothing);
    });

    testWidgets('a listing that changed wallet', (tester) async {
      wallet.linkMeta.directoryPins.addAll(changedPin);
      await show(tester, membership: listed);
      await paste(tester, vectors.https('req-basic'));
      expect(find.textContaining('This listing now points to a different wallet than when you paid on'), findsOneWidget);
    });
  });

  group('refusals fill nothing', () {
    final cases = <String, (String, String Function(LinkVectors), DateTime?)>{
      'not a payment link': (_l.linkNotALink, (x) => x.bad('req-bad-checksum'), null),
      'made for floonet': (_l.linkMadeForFloonet, (x) => x.scheme('req-floonet'), null),
      'changed after it was made': (_l.linkChanged, (x) => x.bad('req-tamper-amount'), null),
      'expired': ('This link expired on ', (x) => x.scheme('req-basic'), linkAfterExpiry),
      'made for someone else': (_l.linkForOther, (x) => x.scheme('req-for'), null),
    };
    for (final e in cases.entries) {
      testWidgets('pasted: ${e.key}, under To', (tester) async {
        final (message, link, now) = e.value;
        await show(tester, now: now, membership: FakeMembership(listingKeys: {vectorDkey: vectors.listingKeyText('03${'11' * 32}')}));
        await paste(tester, link(vectors));
        expect(find.textContaining(message), findsOneWidget);
        expect(trust(), findsNothing);
        expect(text(tester, _l.deskSendAmount), isEmpty);
      });
    }

    testWidgets('from a link: a dialog', (tester) async {
      await show(tester, link: vectors.scheme('req-floonet'));
      expect(inDialog(find.text(_l.linkMadeForFloonet)), findsOneWidget);
      expect(trust(), findsNothing);
    });
  });

  testWidgets('an opened link (OS, scan) fills Send', (tester) async {
    await show(tester, link: vectors.https('req-basic', host: 'anything.invalid'));
    expect(text(tester, 'To'), address);
    expect(trust(), findsOneWidget);
  });

  testWidgets('already paid: asks, Cancel leaves it, Pay again fills', (tester) async {
    await wallet.recordLinkPayment(vectors.request('req-basic'), 1799990000);
    await show(tester);
    await paste(tester, vectors.https('req-basic'));
    expect(inDialog(find.text(_l.linkPaidTitle)), findsOneWidget);
    await tester.tap(find.text(_l.commonCancel));
    await tester.pumpAndSettle();
    expect(trust(), findsNothing);
    await paste(tester, vectors.https('req-basic'));
    await tester.tap(find.byKey(const ValueKey('send-link-pay-again')));
    await tester.pumpAndSettle();
    expect(trust(), findsOneWidget);
  });

  testWidgets('the amount is the requested one; edited, it says so; any amount stays empty', (tester) async {
    await show(tester);
    await paste(tester, vectors.https('req-basic'));
    expect(text(tester, _l.deskSendAmount), '2.5');
    expect(find.text(_l.linkAmountEdited), findsNothing);
    await tester.enterText(field(_l.deskSendAmount), '1');
    await tester.pumpAndSettle();
    expect(find.text(_l.linkAmountEdited), findsOneWidget);
    await paste(tester, vectors.scheme('req-payee'));
    expect(text(tester, _l.deskSendAmount), isEmpty);
  });

  Future<void> review(WidgetTester tester) async {
    await tester.ensureVisible(find.text(_l.deskSendReview));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.deskSendReview));
    await tester.pumpAndSettle();
  }

  Future<void> sendWithPassword(WidgetTester tester, String label) async {
    await tester.enterText(find.descendant(of: find.widgetWithText(EField, _l.deskSendPassword), matching: find.byType(TextField)), 'secret-pass');
    await tester.pump();
    await tester.tap(find.widgetWithText(EButton, label));
    await tester.pumpAndSettle();
  }

  testWidgets('a paid link is recorded, and the payee can be saved as a contact', (tester) async {
    await show(tester, membership: listed);
    await paste(tester, vectors.https('req-basic'));
    await review(tester);
    expect(inDialog(trust()), findsNothing, reason: 'the trust line stays under To');
    await sendWithPassword(tester, 'Send 2.5 EPIC');
    expect(wallet.sends, 1);
    expect(wallet.linkPaid, hasLength(1));
    expect(find.byKey(const ValueKey('send-link-save-contact')), findsOneWidget);
  });

  testWidgets('a changed wallet asks once more before the review', (tester) async {
    wallet.linkMeta.directoryPins.addAll(changedPin);
    await show(tester);
    await paste(tester, vectors.https('req-basic'));
    await review(tester);
    expect(find.byKey(const ValueKey('send-link-changed')), findsOneWidget);
    expect(find.text(_l.deskSendReviewTitle), findsNothing);
    await tester.tap(find.text(_l.commonCancel));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskSendReviewTitle), findsNothing);
    await review(tester);
    await tester.tap(find.byKey(const ValueKey('send-link-changed-send')));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskSendReviewTitle), findsOneWidget);
    expect(wallet.sends, 0);
  });
}
