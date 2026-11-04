// SPDX-License-Identifier: Apache-2.0
// Send from a payment link on the phone: a pasted link (any host) opens Send filled, with the
// trust line; a refused link fills nothing and says why; a request paid before asks first; the
// changed-wallet listing asks once more before it sends; a paid link is recorded and its payee
// can be saved as a contact. Real link texts from the directory vectors.
import 'package:epic_wallet/src/directory/directory.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:epic_wallet/src/scan/incoming_link.dart' show linkClockProvider;
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/link_send.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart' show FakeQrScanner, qrScannerProvider;
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/link_support.dart';
import 'support/send_pin.dart';

final _l = englishStrings;

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Mainnet extends WalletConfigNotifier {
  @override
  WalletConfig? build() => mainnetPreset.config(dataDir: '/fake/wallets/mainnet', nodeUrl: mainnetPreset.nodeUrl);
}

/// A wallet that paid the listing of [pinned] before (to another key than the vectors' card).
class _Session extends FakeWalletSession {
  _Session() : super(summary: _forty);

  LinkMemory? memory;

  /// What the app recorded; the real store's file I/O does not run under the test clock.
  final recorded = <Payreq>[];

  @override
  LinkMemory linkMemory() => memory ?? const LinkMemory();

  @override
  Future<void> recordLinkPayment(Payreq request, int paidAt, {String? txId}) async {
    recorded.add(request);
    recordedTxIds.add(txId);
  }

  /// The slate ids the app passed, in the order of [recorded].
  final recordedTxIds = <String?>[];
}

class _Refuses implements PaymentRefusals {
  _Refuses(this.address);

  final String address;

  @override
  bool refusesPayments({String? pairingId, String? address}) => address != null && epicboxKey(address) == epicboxKey(this.address);

  @override
  String? refusedName({String? pairingId, String? address}) => refusesPayments(pairingId: pairingId, address: address) ? 'BT Labs Bot' : null;
}

final _forty = WalletSummary(
  lastConfirmedHeight: BigInt.from(2499990),
  minimumConfirmations: BigInt.from(3),
  total: BigInt.from(4000000000),
  spendable: BigInt.from(4000000000),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: BigInt.zero,
  validatedWithNode: true,
);

void main() {
  final vectors = LinkVectors();
  late _Session session;

  Future<void> pump(
    WidgetTester tester, {
    FakeMembership? membership,
    DateTime? now,
    Size size = const Size(1080, 2340),
    PaymentRefusals? refusals,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    allowPinCheck(session);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          relayProbeProvider.overrideWithValue(FakeRelayProbe()),
          walletServiceProvider.overrideWithValue(VectorWalletService(vectors.listed)),
          secretStoreProvider.overrideWithValue(sendPinStore()),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: true)),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          sessionProvider.overrideWith(() => _Open(session)),
          walletConfigProvider.overrideWith(_Mainnet.new),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          linkClockProvider.overrideWithValue(() => now ?? linkNow),
          directoryMembershipProvider.overrideWithValue(membership ?? FakeMembership()),
          if (refusals != null) paymentRefusalsProvider.overrideWithValue(refusals),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: AdvancedOptions(prefs: AdvancedPrefs.none, child: child!),
          ),
          home: SlotScaffold(appBar: AppBar(), body: SendView(onDone: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The link text pasted with the Paste button.
  Future<void> paste(WidgetTester tester, String text) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return {'text': text};
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.tap(find.text(_l.commonPaste));
    await tester.pumpAndSettle();
  }

  setUp(() => session = _Session());

  final listed = FakeMembership(labels: {vectorDkey: 'Test Service'});

  Finder trust() => find.byKey(linkTrustLineKey);
  String trustText(WidgetTester tester) =>
      tester.widget<Text>(find.descendant(of: trust(), matching: find.byType(Text)).first).data!;
  Finder amountField() => find.widgetWithText(TextField, 'Amount (EPIC)');

  group('trust line', () {
    testWidgets('a directory in use: the name, its label and the code pictures', (tester) async {
      await pump(tester, membership: listed);
      await paste(tester, vectors.https('req-basic'));
      expect(trustText(tester), '@alice_test · via Test Service');
      expect(find.descendant(of: trust(), matching: find.byType(Wrap)), findsOneWidget);
    });

    testWidgets('any other directory: no name, no alarm', (tester) async {
      await pump(tester);
      await paste(tester, vectors.https('req-basic'));
      expect(trustText(tester), _l.linkTrustOther);
      expect(find.textContaining('alice_test'), findsNothing);
    });

    testWidgets('a listing that changed wallet: the warning', (tester) async {
      final request = vectors.request('req-basic');
      session.memory = LinkMemory(
        pins: {
          pinKey(request.card.dkey, request.card.handle): const ListingPin(
            listingKey: '03aa8c2f48c588fa84ed97a219b9841579c04241c1cef99b69bb19bb5168011df6',
            firstPaid: 1790000000,
            lastPaid: 1790000000,
          ),
        },
      );
      await pump(tester, membership: listed);
      await paste(tester, vectors.https('req-basic'));
      expect(trustText(tester), startsWith('This payee now gets paid to a different wallet than when you paid on'));
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
      testWidgets(e.key, (tester) async {
        final (message, text, now) = e.value;
        // The wallet's own listing key is another one than the request is made for.
        final membership = FakeMembership(listingKeys: {vectorDkey: vectors.listingKeyText('03${'11' * 32}')});
        await pump(tester, now: now, membership: membership);
        await paste(tester, text(vectors));
        expect(find.textContaining(message), findsOneWidget);
        expect(trust(), findsNothing);
      });
    }
  });

  testWidgets('a request made for this wallet opens', (tester) async {
    final membership = FakeMembership(listingKeys: {vectorDkey: vectors.listingKeyText('026b8c2f48c588fa84ed97a219b9841579c04241c1cef99b69bb19bb5168011df6')});
    await pump(tester, membership: membership);
    await paste(tester, vectors.scheme('req-for'));
    expect(trustText(tester), _l.linkTrustDirectory);
  });

  testWidgets('already paid: asks, Cancel leaves it empty', (tester) async {
    session.memory = LinkMemory(paidRequests: {toHex(vectors.request('req-basic').reqid): 1799990000});
    await pump(tester);
    await paste(tester, vectors.https('req-basic'));
    expect(find.text(_l.linkPaidTitle), findsOneWidget);
    expect(find.textContaining('You paid this request on'), findsOneWidget);
    await tester.tap(find.text(_l.commonCancel));
    await tester.pumpAndSettle();
    expect(trust(), findsNothing);
  });

  testWidgets('already paid: Pay again fills', (tester) async {
    session.memory = LinkMemory(paidRequests: {toHex(vectors.request('req-basic').reqid): 1799990000});
    await pump(tester);
    await paste(tester, vectors.https('req-basic'));
    await tester.tap(find.text(_l.linkPayAgain));
    await tester.pumpAndSettle();
    expect(trust(), findsOneWidget);
  });

  testWidgets('the amount is the requested one; edited, it says so', (tester) async {
    await pump(tester);
    await paste(tester, vectors.https('req-basic'));
    expect(amountField(), findsOneWidget);
    expect(tester.widget<TextField>(amountField()).controller!.text, startsWith('2.5'));
    expect(find.byKey(linkAmountNoteKey), findsNothing);
    await tester.enterText(amountField(), '1');
    await tester.pumpAndSettle();
    expect(find.text(_l.linkAmountEdited), findsOneWidget);
  });

  testWidgets('any amount: the amount stays empty for the payer', (tester) async {
    await pump(tester);
    await paste(tester, vectors.scheme('req-payee'));
    expect(tester.widget<TextField>(amountField()).controller!.text, isEmpty);
  });

  group('a contact that takes no payments', () {
    final address = 'es${'k' * 50}@epicbox.epiccash.com';

    testWidgets('an address pasted or typed stops at the field and Continue stays', (tester) async {
      await pump(tester, refusals: _Refuses(address));
      await paste(tester, address);
      expect(find.text(_l.contactNoPaymentsNamed('BT Labs Bot')), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, _l.commonContinue));
      await tester.pumpAndSettle();
      expect(find.text(_l.contactNoPaymentsNamed('BT Labs Bot')), findsOneWidget);
      expect(find.widgetWithText(FilledButton, _l.commonContinue), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'es${'m' * 50}@epicbox.epiccash.com');
      await tester.pumpAndSettle();
      expect(find.text(_l.contactNoPaymentsNamed('BT Labs Bot')), findsNothing);
      await tester.enterText(find.byType(TextField).first, address);
      await tester.tap(find.widgetWithText(FilledButton, _l.commonContinue));
      await tester.pumpAndSettle();
      expect(find.text(_l.contactNoPaymentsNamed('BT Labs Bot')), findsOneWidget);
    });
  });

  group('sending', () {
    Future<void> toReview(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, _l.commonContinue));
      await tester.pumpAndSettle();
    }

    testWidgets('a paid link is recorded, and the payee can be saved', (tester) async {
      await pump(tester, membership: listed);
      await paste(tester, vectors.https('req-basic'));
      await toReview(tester);
      await tester.tap(find.textContaining('Send 2.5'));
      await tester.pumpAndSettle();
      await answerPin(tester);
      expect(session.epicboxSends, hasLength(1));
      expect(session.recorded.map((r) => toHex(r.reqid)), [toHex(vectors.request('req-basic').reqid)]);
      expect(find.text(_l.sendSaveContact), findsOneWidget);
      expect(session.recordedTxIds.single, isNotNull, reason: 'the slate id of the payment, for the receipt line');
    });

    testWidgets('a changed wallet asks once more, and Cancel does not send', (tester) async {
      final request = vectors.request('req-basic');
      session.memory = LinkMemory(
        pins: {
          pinKey(request.card.dkey, request.card.handle): const ListingPin(
            listingKey: '03aa8c2f48c588fa84ed97a219b9841579c04241c1cef99b69bb19bb5168011df6',
            firstPaid: 1790000000,
            lastPaid: 1790000000,
          ),
        },
      );
      await pump(tester);
      await paste(tester, vectors.https('req-basic'));
      await toReview(tester);
      await tester.tap(find.textContaining('Send 2.5'));
      await tester.pumpAndSettle();
      expect(find.text(_l.linkChangedConfirmTitle), findsOneWidget);
      await tester.tap(find.text(_l.commonCancel));
      await tester.pumpAndSettle();
      expect(session.epicboxSends, isEmpty);
    });
  });
}
