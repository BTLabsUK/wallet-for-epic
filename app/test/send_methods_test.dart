// SPDX-License-Identifier: Apache-2.0
// Send's four methods: a selector with Epicbox, HTTP, Tor and File, a strip with a
// picture and one plain line, the shape of the method's address under To. The method follows
// the address: a paste, a pick or a whole address of another kind moves it,
// typing never does half way, and nothing moves it back. HTTP sends straight to their wallet:
// delivered, it waits only for a block and cannot be cancelled; not reached, the amount is on
// hold with Try again and Cancel payment. Each review states its cancel rule. Receive shows
// the same strip per tab, and Tor's honest line.

import 'dart:async';

import 'package:epic_wallet/src/demo.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/settings.dart' show appSettingsProvider;
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/method_strip.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/settings_sections.dart' show SettingsSectionScreen;
import 'package:epic_wallet/src/contacts.dart' show contactsProvider;
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/ui/net_block.dart' show netBlockNoteKey, offlineNoPeersKey, offlineNodeNoteKey;
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/send_pin.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

/// A valid address for [FakeWalletService.validateEpicboxAddress].
final String _bob = '${'b' * 52}@box.epic.invalid';

const String _name = 'wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid';
const String _onion = '$_name.onion';

const String _https = 'https://wallet.example.com:3415';
const String _lan = 'http://10.0.1.24:3415';

const TorBundle _bundle = TorBundle(binary: '/data/app/lib/arm64/libtor.so');

WalletSummary _summary() => WalletSummary(
  lastConfirmedHeight: BigInt.from(2499990),
  minimumConfirmations: BigInt.from(3),
  total: _epic(40),
  spendable: _epic(40),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: BigInt.zero,
  validatedWithNode: true,
);

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
  _Mainnet([this.nodeUrl]);

  /// The node in use; null is the preset's public node.
  final String? nodeUrl;

  @override
  WalletConfig? build() => mainnetPreset.config(
    dataDir: '/fake/wallets/mainnet',
    nodeUrl: nodeUrl ?? mainnetPreset.nodeUrl,
  );
}

/// The fake, but a direct send their wallet answered is finalized and posted, as LEPIC's:
/// confirming, no longer waiting for the recipient.
class _DirectSession extends FakeWalletSession {
  _DirectSession() : super(summary: _summary());

  void _answered(int txId) {
    final i = transactionsValue.indexWhere((t) => t.id == txId);
    final tx = transactionsValue[i];
    transactionsValue[i] = fakeTx(
      id: tx.id,
      slateId: tx.slateId,
      kind: TxKind.sent,
      status: TxStatus.awaitingConfirmation,
      createdAtUnix: tx.createdAtUnix,
      amountDebited: tx.amountDebited,
      fee: tx.fee,
      counterparty: tx.counterparty,
    );
  }

  @override
  Future<HttpSent> sendHttp({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String url,
    required bool allowPlainHttp,
    String? message,
    SendOptions? options,
    String? proofAddress,
  }) async {
    final sent = await super.sendHttp(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      url: url,
      allowPlainHttp: allowPlainHttp,
      message: message,
      options: options,
    );
    _answered(sent.txId);
    return sent;
  }

  @override
  Future<HttpSent> resendHttp({
    required int txId,
    required String url,
    required bool allowPlainHttp,
  }) async {
    final sent = await super.resendHttp(
      txId: txId,
      url: url,
      allowPlainHttp: allowPlainHttp,
    );
    _answered(sent.txId);
    return sent;
  }
}

class _Harness {
  _Harness() {
    allowPinCheck(session);
  }

  final session = _DirectSession();
  final network = StreamController<bool>.broadcast();
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester, {
    Widget? body,
    double height = 2340,
    AdvancedPrefs advanced = AdvancedPrefs.none,
    PaymentPrefs payments = PaymentPrefs.defaults,
    String? node,
    int? peers,
  }) async {
    tester.view.physicalSize = Size(1080, height);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          relayProbeProvider.overrideWithValue(FakeRelayProbe()),
          walletServiceProvider.overrideWithValue(FakeWalletService()),
          secretStoreProvider.overrideWithValue(
            sendPinStore()
              ..values['app.payment_prefs'] = payments.encode()
              // Pairing (Experimental) on, for the sealed files.
              ..values['app.advanced_prefs'] = AdvancedPrefs.none.withExperimental(AdvancedFeature.pairing, true).encode(),
          ),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: true)),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          sessionProvider.overrideWith(() => _Open(session)),
          walletConfigProvider.overrideWith(() => _Mainnet(node)),
          offlineNodePeersProvider.overrideWith((ref) async => peers),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          demoModeProvider.overrideWithValue(false),
          torBundleFinderProvider.overrideWithValue(() async => _bundle),
          networkChangesProvider.overrideWithValue(network.stream),
          phoneTorTimingProvider.overrideWithValue(
            PhoneTorTiming(
              backoff: [Duration(hours: 1)],
              sendWait: Duration(hours: 1),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            // Spinners never settle; a still icon stands in for them.
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: AdvancedOptions(prefs: advanced, child: child!),
          ),
          home: SlotScaffold(
            appBar: AppBar(),
            body: body ?? SendView(onDone: () {}),
          ),
        ),
      ),
    );
    await _settle(tester);
    container = ProviderScope.containerOf(
      tester.element(find.byType(SlotScaffold).first),
    );
    // The Tor controller reads the bundle and the onion with real async.
    for (var i = 0; i < 50; i++) {
      final s = container.read(phoneTorProvider);
      if (s.onion != null || s.phase == PhoneTorPhase.unavailable) break;
      await _settle(tester);
    }
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await network.close();
    });
  }

  /// The Tor switch on, and tor connected with the onion published.
  Future<void> torOn(WidgetTester tester) async {
    await container.read(phoneTorProvider.notifier).setReceiving(true);
    await _settle(tester);
    await emit(tester, TorEventKind.ready);
    expect(container.read(phoneTorProvider).phase, PhoneTorPhase.ready);
  }

  /// Tor's next event, with what `torStatus` answers afterwards.
  Future<void> emit(
    WidgetTester tester,
    TorEventKind kind, {
    int? progress,
    TorFailure? failure,
  }) async {
    session.torStatusValue = switch (kind) {
      TorEventKind.starting => TorStatus(
        kind: TorStatusKind.starting,
        progress: progress,
      ),
      TorEventKind.bootstrapped => const TorStatus(
        kind: TorStatusKind.bootstrapped,
      ),
      TorEventKind.ready => TorStatus(
        kind: TorStatusKind.ready,
        onion: session.onion,
      ),
      _ => TorStatus.off,
    };
    session.torEvents.add(
      TorEvent(
        kind: kind,
        progress: progress,
        failure: failure,
        onion: kind == TorEventKind.ready ? session.onion : null,
      ),
    );
    await _settle(tester);
  }

  /// Through recipient and amount to the review.
  Future<void> toReview(WidgetTester tester, String address) async {
    await _enter(tester, 'To', address);
    await _tap(tester, _continue);
    await _enter(tester, 'Amount (EPIC)', '1');
    await _tap(tester, _continue);
    expect(find.text('Review'), findsOneWidget);
  }
}

Finder get _continue => find.widgetWithText(FilledButton, 'Continue');

/// The review's Method row reading [value].
Finder _reviewMethod(String value) =>
    find.descendant(of: find.byType(ListView).last, matching: find.text(value));

/// Frames and a slice of real time: the Tor controller's work completes on microtasks the
/// test clock does not flush.
String _toText(WidgetTester tester) =>
    tester.widget<TextField>(find.widgetWithText(TextField, 'To')).controller!.text;

Future<void> _settle(WidgetTester tester) async {
  for (var round = 0; round < 2; round++) {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
}

Future<void> _reach(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reach(tester, finder);
  await tester.tap(finder);
  await _settle(tester);
  if (find.widgetWithText(TextField, 'PIN').evaluate().isNotEmpty) {
    await answerPin(tester, settle: false);
    await _settle(tester);
  }
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await _reach(tester, field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 500));
  await _settle(tester);
}

/// The method the selector shows.
TransferMethod _method(WidgetTester tester) => tester
    .widget<SegmentedButton<TransferMethod>>(find.byKey(sendMethodsKey))
    .selected
    .single;

/// The segment named [label] in Send's selector.
Finder _segment(String label) =>
    find.descendant(of: find.byKey(sendMethodsKey), matching: find.text(label));

/// Types [text] into To one character at a time, as a keyboard does, and returns the method
/// after each character.
Future<List<TransferMethod>> _type(WidgetTester tester, String text) async {
  final field = find.widgetWithText(TextField, 'To');
  final seen = <TransferMethod>[];
  for (var i = 1; i <= text.length; i++) {
    await tester.enterText(field, text.substring(0, i));
    await tester.pump();
    seen.add(_method(tester));
  }
  return seen;
}

/// How many times the method changed along [seen], starting from [from].
int _switches(TransferMethod from, List<TransferMethod> seen) {
  var n = 0;
  var last = from;
  for (final m in seen) {
    if (m != last) n++;
    last = m;
  }
  return n;
}

void _clipboard(WidgetTester tester, String? Function() text) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async =>
        call.method == 'Clipboard.getData' ? {'text': text()} : null,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
}

/// Settings › Transactions › Link · HTTP and Link · Tor on, as the Link segment and tab need
/// them.
const _directOn = PaymentPrefs(linkHttp: true, linkTor: true);


/// Scrolls Send's list until [finder] is built and in sight: the balance header above the
/// page leaves the rows under the review past a short phone's first page, and the list is
/// lazy, so a row out of sight is not in the tree at all.
Future<void> _reveal(WidgetTester tester, Finder finder) => tester.scrollUntilVisible(
  finder,
  200,
  scrollable: find
      .descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable))
      .first,
);

void main() {
  group('selector and strip', () {
    testWidgets('Link is listed from the start, its switches on or not', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      expect(_segment('Epicbox'), findsOneWidget);
      expect(_segment('Direct · File'), findsOneWidget);
      expect(_segment('Link'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      final on = _Harness();
      await on.pump(tester, payments: _directOn);
      expect(_segment('Link'), findsOneWidget);
      expect(find.byKey(sendTurnOnMethodKey), findsNothing);
    });

    testWidgets('Link picked with both switches off: the note, and Turn on turns Link · HTTP on', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, _segment('Link'));
      expect(_method(tester), TransferMethod.direct);
      expect(find.text('Link · HTTP is off in Settings › Transactions.'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Turn on Link · HTTP'), findsOneWidget);
      await _tap(tester, find.byKey(sendTurnOnMethodKey));
      expect(h.container.read(appSettingsProvider).value!.payments.linkHttp, isTrue);
      expect(h.container.read(appSettingsProvider).value!.payments.linkTor, isFalse);
      expect(find.byKey(sendTurnOnMethodKey), findsNothing);
      expect(find.text('Link · HTTP is off in Settings › Transactions.'), findsNothing);
      expect(_method(tester), TransferMethod.direct);
    });

    testWidgets('three segments, Epicbox first; each with its strip and shape', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      for (final label in ['Epicbox', 'Link', 'Direct · File']) {
        expect(_segment(label), findsOneWidget, reason: label);
      }
      // Tor is not a method: the one switch in Settings changes how they connect.
      expect(_segment('Tor'), findsNothing);
      expect(_segment('HTTP'), findsNothing);
      final xs = [
        for (final label in ['Epicbox', 'Link', 'Direct · File'])
          tester.getCenter(_segment(label)).dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()));
      expect(_method(tester), TransferMethod.epicbox);
      expect(
        tester.getSize(find.byKey(sendMethodsKey)).height,
        greaterThanOrEqualTo(44),
      );
      expect(find.text('The recipient can be offline.'), findsOneWidget);
      expect(
        find.text(
          'The Epicbox server holds the payment until they open their wallet.',
        ),
        findsOneWidget,
      );
      expect(find.text('esXXXX…XXXX@box.epic.invalid'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'To'), findsOneWidget);
      expect(find.text('Address or contact'), findsOneWidget);

      await _tap(tester, _segment('Link'));
      expect(_method(tester), TransferMethod.direct);
      expect(find.text('Straight to their wallet.'), findsOneWidget);
      expect(
        find.text('Their wallet must be open. An onion address goes over Tor.'),
        findsOneWidget,
      );
      expect(find.text('http://host:3415 or xxxx….onion'), findsOneWidget);

      await _tap(tester, _segment('Direct · File'));
      expect(find.text('No connection needed.'), findsOneWidget);
      expect(
        find.text(
          'Hand the file over, get their response file back, then finalize it here.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'To'), findsNothing);
      await _reveal(tester, find.text('Can be cancelled until the response file is finalized.'));
      expect(
        find.text('Can be cancelled until the response file is finalized.'),
        findsOneWidget,
      );

      // Back to an address method: the form again.
      await _tap(tester, _segment('Epicbox'));
      expect(find.widgetWithText(TextField, 'To'), findsOneWidget);
    }, skip: !torBuilt);

    testWidgets('the ? beside the shape opens help on the address kinds', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.byTooltip('Address kinds'));
      expect(find.byType(HelpTopicScreen), findsOneWidget);
      expect(find.text('What an address looks like'), findsOneWidget);
    });

    testWidgets('a pasted name finds the contact', (tester) async {
      final h = _Harness();
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Alice', address: _bob, note: null),
      );
      await h.pump(tester);
      await _enter(tester, 'To', 'ali');
      await _tap(tester, find.text('Alice'));
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'To'))
            .controller!
            .text,
        _bob,
      );
    });
  });

  group('Settings › Transactions', () {
    testWidgets('File off: the File segment goes, Epicbox and Link stay', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(linkHttp: true, linkTor: true, directFile: false));
      expect(_segment('Epicbox'), findsOneWidget);
      expect(_segment('Link'), findsOneWidget);
      expect(_segment('Direct · File'), findsNothing);
    });

    testWidgets('only Epicbox offered: Epicbox and Link, nothing else', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(directFile: false, directQr: false));
      expect(_segment('Epicbox'), findsOneWidget);
      expect(_segment('Link'), findsOneWidget);
      expect(_segment('Direct · File'), findsNothing);
      expect(find.widgetWithText(TextField, 'To'), findsOneWidget);
    });

    testWidgets('a pasted onion keeps Link for that send with Link off', (tester) async {
      String? clip = _onion;
      _clipboard(tester, () => clip);
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(directFile: false));
      await _tap(tester, find.text('Paste'));
      expect(_segment('Link'), findsOneWidget);
      expect(_method(tester), TransferMethod.direct);
      // Never a silent refusal: the note names the method that is off.
      expect(find.text('Link · Tor is off in Settings › Transactions.'), findsOneWidget);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
    }, skip: !torBuilt);

    testWidgets('Link · HTTP on, Link · Tor off: an http address goes, an onion waits with its reason', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(linkHttp: true));
      expect(_segment('Link'), findsOneWidget);
      await _enter(tester, 'To', _https);
      expect(_method(tester), TransferMethod.direct);
      expect(find.byKey(netBlockNoteKey), findsNothing);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNotNull);
      await _enter(tester, 'To', _onion);
      expect(find.text('Link · Tor is off in Settings › Transactions.'), findsOneWidget);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
    }, skip: !torBuilt);

    testWidgets('a saved contact with only an address whose method is off is named, with the way to Settings', (tester) async {
      final h = _Harness();
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Tor Tom', address: _onion, note: null),
      );
      await h.pump(tester, payments: const PaymentPrefs(linkHttp: true));
      await _tap(tester, find.text('Contacts'));
      await _tap(tester, find.text('Tor Tom'));
      expect(_method(tester), TransferMethod.direct);
      const line = 'Link · Tor is off in Settings › Transactions. Tor Tom has only a Link · Tor address.';
      expect(find.text(line), findsOneWidget);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
      // The line opens Settings › Transactions.
      await _tap(tester, find.text(line));
      expect(find.byType(SettingsSectionScreen), findsOneWidget);
      expect(h.session.torSends, isEmpty);
    }, skip: !torBuilt);

    testWidgets('Send opens on the default method', (tester) async {
      final h = _Harness();
      await h.pump(
        tester,
        payments: const PaymentPrefs(linkHttp: true, linkTor: true, defaultMethod: MethodKind.linkHttp),
      );
      expect(_method(tester), TransferMethod.direct);
      expect(find.text('Link address'), findsNothing);
    });

    testWidgets('a method switched off while Send is open: the idle form moves to the start method', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(linkHttp: true));
      expect(_method(tester), TransferMethod.epicbox);
      await tester.runAsync(() => h.container.read(appSettingsProvider.notifier).setPayments(const PaymentPrefs(epicbox: false, linkHttp: true)));
      await _settle(tester);
      expect(_method(tester), TransferMethod.direct);
      expect(_segment('Epicbox'), findsNothing);
      expect(find.text('Epicbox is off in Settings › Transactions.'), findsNothing);
    });

    testWidgets('an Epicbox address in To keeps Epicbox when it goes off, with the note', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(linkHttp: true));
      await _enter(tester, 'To', _bob);
      await tester.runAsync(() => h.container.read(appSettingsProvider.notifier).setPayments(const PaymentPrefs(epicbox: false, linkHttp: true)));
      await _settle(tester);
      expect(_method(tester), TransferMethod.epicbox);
      expect(_toText(tester), _bob);
      expect(find.text('Epicbox is off in Settings › Transactions.'), findsOneWidget);
    });

    testWidgets('a default that is not offered falls back to Epicbox', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(defaultMethod: MethodKind.linkHttp));
      expect(_method(tester), TransferMethod.epicbox);
    });

    testWidgets('File as the default opens the file route', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(defaultMethod: MethodKind.directFile));
      expect(find.text(lookupAppLocalizations(const Locale('en')).sendMakeFile), findsOneWidget);
      expect(find.byKey(sendRecipientFieldKey), findsNothing);
    });
  });

  group('the method follows the address', () {
    testWidgets('typing es stays on Epicbox', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final seen = await _type(tester, 'es');
      expect(seen, everyElement(TransferMethod.epicbox));
      expect(find.byKey(sendSwitchedTagKey), findsNothing);
    });

    testWidgets(
      'a whole Epicbox address pasted under Link moves it to Epicbox',
      (tester) async {
        String? clip;
        _clipboard(tester, () => clip);
        final semantics = tester.ensureSemantics();
        final h = _Harness();
        await h.pump(tester, payments: _directOn);
        await _tap(tester, _segment('Link'));
        expect(_method(tester), TransferMethod.direct);
        clip = _bob;
        await _tap(tester, find.text('Paste'));
        expect(_method(tester), TransferMethod.epicbox);
        // The field keeps the text, and the tag says why.
        expect(
          tester
              .widget<TextField>(find.widgetWithText(TextField, 'To'))
              .controller!
              .text,
          _bob,
        );
        expect(find.text('Via Epicbox'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Epicbox address. Method set to Epicbox.'),
          findsOneWidget,
        );
        semantics.dispose();
      },
    );

    testWidgets(
      'a bare onion typed by hand moves it to Link once, at the 56th character',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final h = _Harness();
        await h.pump(tester);
        final seen = await _type(tester, _name);
        expect(_switches(TransferMethod.epicbox, seen), 1);
        expect(seen.indexOf(TransferMethod.direct), _name.length - 1);
        expect(
          find.descendant(
            of: find.byKey(sendSwitchedTagKey),
            matching: find.text('Link address'),
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Link address. Method set to Link.'),
          findsOneWidget,
        );
        semantics.dispose();
        // The tag fades after 3 s, then leaves the label (android-08: no empty notch); the
        // method stays.
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester
              .widget<AnimatedOpacity>(find.byKey(sendSwitchedTagKey))
              .opacity,
          0,
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byKey(sendSwitchedTagKey), findsNothing);
        final label = find.descendant(of: find.widgetWithText(TextField, 'To'), matching: find.text('To'));
        expect(find.ancestor(of: label, matching: find.byType(Row)).evaluate(), isNotEmpty);
        expect(tester.getSize(find.ancestor(of: label, matching: find.byType(Row)).first).width,
            moreOrLessEquals(tester.getSize(label).width, epsilon: 1));
        // Never back: one more character breaks the onion, Link stays.
        final more = await _type(tester, '${_name}x');
        expect(more.last, TransferMethod.direct);
      },
    );

    testWidgets('http://10.0.1.24 typed moves it to Link once the host is '
        'whole', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      const url = 'http://10.0.1.24';
      final seen = await _type(tester, url);
      expect(_switches(TransferMethod.epicbox, seen), 1);
      expect(seen.last, TransferMethod.direct);
      // Not while the host is half typed.
      expect(
        seen[url.indexOf('192.168.') + '192.168.'.length - 1],
        TransferMethod.epicbox,
      );
      expect(find.text('Link address'), findsOneWidget);
    });

    testWidgets('picks by method: a contact fills its address whose method is on (qa-next)', (tester) async {
      final h = _Harness();
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Two Way', tor: _onion, http: _https, note: null),
      );
      await h.pump(tester, payments: const PaymentPrefs(linkHttp: true));
      await _tap(tester, find.text('Contacts'));
      await _tap(tester, find.text('Two Way'));
      expect(_toText(tester), _https);
      expect(find.byKey(netBlockNoteKey), findsNothing);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNotNull);
    });

    testWidgets('a pasted onion of a contact with another address stays, without "only" (qa-next)', (tester) async {
      String? clip = _onion;
      _clipboard(tester, () => clip);
      final h = _Harness();
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Two Way', tor: _onion, http: _https, note: null),
      );
      await h.pump(tester, payments: const PaymentPrefs(linkHttp: true));
      await _tap(tester, find.text('Paste'));
      // Never swapped: what was pasted stays, and the note names the method that is off.
      expect(_toText(tester), _onion);
      expect(find.text('Link · Tor is off in Settings › Transactions.'), findsOneWidget);
      expect(find.textContaining('has only'), findsNothing);
    }, skip: !torBuilt);

    testWidgets('picks by method: a code with an Epicbox and an onion address fills the one that is on (qa-next)', (tester) async {
      String? clip = 'epic:$_bob?method=direct&direct=http://$_onion';
      _clipboard(tester, () => clip);
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(linkHttp: true));
      await _tap(tester, find.text('Paste'));
      expect(_toText(tester), _bob);
      expect(_method(tester), TransferMethod.epicbox);
      expect(find.byKey(netBlockNoteKey), findsNothing);
    });

    testWidgets('picks by method: Epicbox off, the code\'s onion with Link · Tor on (qa-next)', (tester) async {
      String? clip = 'epic:$_bob?direct=http://$_onion';
      _clipboard(tester, () => clip);
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(epicbox: false, linkTor: true));
      await _tap(tester, find.text('Paste'));
      expect(_toText(tester), _onion);
      expect(_method(tester), TransferMethod.direct);
    }, skip: !torBuilt);

    testWidgets('an onion contact picked moves it to Link', (tester) async {
      final h = _Harness();
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Tor Tom', address: _onion, note: null),
      );
      await h.pump(tester);
      await _tap(tester, find.text('Contacts'));
      await _tap(tester, find.text('Tor Tom'));
      expect(_method(tester), TransferMethod.direct);
      expect(find.text('Link address'), findsOneWidget);
    });

    testWidgets(
      'Link off: a pasted onion or http address moves to Link, which says it is off',
      (tester) async {
        String? clip;
        _clipboard(tester, () => clip);
        for (final address in [_onion, _https]) {
          // A fresh tree for each, so the screen's state starts over.
          await tester.pumpWidget(const SizedBox());
          final h = _Harness();
          await h.pump(tester);
          // Link is off, and listed all the same.
          expect(_segment('Link'), findsOneWidget);
          clip = address;
          await _tap(tester, find.text('Paste'));
          // The method follows the address and Link shows for this send.
          expect(_segment('Link'), findsOneWidget, reason: address);
          expect(_method(tester), TransferMethod.direct, reason: address);
          expect(find.text('Link address'), findsOneWidget);
          // Not the address's fault: no shape sentence; the note names the method that is
          // off, and Continue waits until it is on.
          expect(
            find.text(
              'A Link address starts with http:// or https://, or ends in .onion.',
            ),
            findsNothing,
          );
          expect(
            find.text(
              '${address == _onion ? 'Link · Tor' : 'Link · HTTP'} is off in Settings › Transactions.',
            ),
            findsOneWidget,
            reason: address,
          );
          expect(tester.widget<FilledButton>(_continue).onPressed, isNull, reason: address);
        }
      }, skip: !torBuilt,
    );

    testWidgets('choosing a method by hand never clears the field', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      await _enter(tester, 'To', _bob);
      await _tap(tester, _segment('Link'));
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'To'))
            .controller!
            .text,
        _bob,
      );
      await _tap(tester, _continue);
      expect(
        find.text(
          'A Link address starts with http:// or https://, or ends in .onion.',
        ),
        findsOneWidget,
      );
    }, skip: !torBuilt);
  });

  group('HTTP send', () {
    testWidgets('delivered: the tracker waits for a block, with no Cancel', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      await h.toReview(tester, _https);
      expect(_reviewMethod('Link · HTTP'), findsOneWidget);
      expect(
        find.text('Cannot be cancelled once their wallet accepts it.'),
        findsOneWidget,
      );
      await _tap(tester, find.text('Send 1.00000000 EPIC'));
      expect(h.session.httpSends, hasLength(1));
      expect(h.session.httpSends.single.url, _https);
      expect(h.session.httpSends.single.allowPlainHttp, isFalse);
      expect(h.session.epicboxSends, isEmpty);
      expect(find.text('Delivered · Waiting for a block'), findsOneWidget);
      expect(find.textContaining('Cancel'), findsNothing);
    });

    testWidgets('not reached: on hold, Try again delivers it again', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      await h.toReview(tester, _https);
      h.session.sendError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'their wallet did not answer',
      );
      await _tap(tester, find.text('Send 1.00000000 EPIC'));
      expect(
        find.text(
          'Their wallet was not reached. The amount stays locked until you cancel '
          'it, or for up to 1 day.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(sendTryAgainKey), findsOneWidget);
      expect(find.byKey(sendCancelPaymentKey), findsOneWidget);
      expect(find.text('Send 1.00000000 EPIC'), findsNothing);

      h.session.sendError = null;
      await _tap(tester, find.byKey(sendTryAgainKey));
      expect(h.session.httpSends, hasLength(2));
      expect(h.session.httpSends.last.txId, isNotNull);
      expect(find.text('Delivered · Waiting for a block'), findsOneWidget);
    });

    testWidgets('not reached: Cancel payment frees it, back to the amount', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      await h.toReview(tester, _https);
      h.session.sendError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'their wallet did not answer',
      );
      await _tap(tester, find.text('Send 1.00000000 EPIC'));
      await _tap(tester, find.byKey(sendCancelPaymentKey));
      expect(h.session.cancelledTxIds, hasLength(1));
      expect(find.text('2 of 3'), findsOneWidget);
    });

    testWidgets('plain HTTP to another device asks first', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      await h.toReview(tester, _lan);
      await _tap(tester, find.text('Send 1.00000000 EPIC'));
      expect(find.text('Not encrypted. Send anyway?'), findsOneWidget);
      await _tap(tester, find.text('Cancel'));
      expect(h.session.httpSends, isEmpty);
      expect(find.text('Review'), findsOneWidget);

      await _tap(tester, find.text('Send 1.00000000 EPIC'));
      await _tap(tester, find.text('Send anyway'));
      expect(h.session.httpSends.single.allowPlainHttp, isTrue);
    });
  });

  group('review', () {
    testWidgets('the method row and the cancel rule: Epicbox', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.toReview(tester, _bob);
      expect(find.text('Method'), findsOneWidget);
      expect(_reviewMethod('Epicbox'), findsOneWidget);
      expect(
        find.text('Can be cancelled while it waits for the recipient.'),
        findsOneWidget,
      );
    });

    testWidgets('the method row and the cancel rule: Link to an onion', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      await h.torOn(tester);
      await h.toReview(tester, _onion);
      expect(_reviewMethod('Link · Tor'), findsOneWidget);
      expect(
        find.text('Cannot be cancelled once their wallet accepts it.'),
        findsOneWidget,
      );
    }, skip: !torBuilt);
  });

  group('the Tor switch', () {
    testWidgets(
      'an onion with Tor off: Needs Tor; Turn on Tor keeps the form',
      (tester) async {
        final h = _Harness();
        await h.pump(tester, payments: _directOn);
        await _enter(tester, 'To', _onion);
        expect(_method(tester), TransferMethod.direct);
        expect(find.byKey(sendTorNoticeKey), findsOneWidget);
        expect(find.text('Link · Tor needs Tor.'), findsOneWidget);
        // Continue goes on to the amount, where Review waits for Tor.
        await _tap(tester, _continue);
        await _enter(tester, 'Amount (EPIC)', '1');
        expect(find.text('Link · Tor needs Tor.'), findsOneWidget);
        expect(
          tester.widget<FilledButton>(_continue).onPressed,
          isNull,
          reason: 'no review while the onion cannot be reached',
        );
        await _tap(tester, find.byKey(sendTurnOnTorKey));
        final tor = h.container.read(phoneTorProvider);
        expect(tor.receiving, isTrue);
        expect(tor.phase, PhoneTorPhase.starting);
        // Starting: the button waits, and the amount is still there.
        expect(
          find.widgetWithText(FilledButton, 'Waiting for Tor'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Waiting for Tor'),
              )
              .onPressed,
          isNull,
        );
        expect(find.text('Link · Tor needs Tor.'), findsNothing);
        await h.emit(tester, TorEventKind.ready);
        expect(tester.widget<FilledButton>(_continue).onPressed, isNotNull);
        await _tap(tester, _continue);
        expect(find.text('Review'), findsOneWidget);
        expect(h.session.torSends, isEmpty);
      }, skip: !torBuilt,
    );

    testWidgets('Tor not connected: Retry and Turn Tor off; nothing goes', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.container.read(phoneTorProvider.notifier).setReceiving(true);
      await _settle(tester);
      await h.emit(tester, TorEventKind.failed, failure: TorFailure.network);
      await h.emit(tester, TorEventKind.stopped);
      expect(h.container.read(phoneTorProvider).phase, PhoneTorPhase.failed);
      await _enter(tester, 'To', _bob);
      // Epicbox goes over Tor, which is down: it waits for Retry or Tor off.
      expect(find.text('Tor is not connected.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await _tap(tester, find.byKey(sendTurnOffTorKey));
      expect(h.container.read(phoneTorProvider).receiving, isFalse);
      expect(find.text('Tor is not connected.'), findsNothing);
    }, skip: !torBuilt);

    testWidgets('Tor on: Epicbox Over Tor, http Not over Tor, onion Over Tor', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      await h.torOn(tester);
      Finder tag(String text) => find.descendant(
        of: find.byKey(sendTorTagKey),
        matching: find.text(text),
      );
      expect(tag('Over Tor'), findsOneWidget);
      await _enter(tester, 'To', _https);
      expect(_method(tester), TransferMethod.direct);
      expect(tag('Not over Tor'), findsOneWidget);
      await _enter(tester, 'To', _onion);
      expect(tag('Over Tor'), findsOneWidget);
      expect(find.byKey(sendTorNoticeKey), findsNothing);

      // The review says it too.
      await _enter(tester, 'To', _https);
      await h.toReview(tester, _https);
      expect(_reviewMethod('Link · HTTP · Not over Tor'), findsOneWidget);
    }, skip: !torBuilt);

    testWidgets('Tor on: an Epicbox review says Over Tor', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.torOn(tester);
      await h.toReview(tester, _bob);
      expect(_reviewMethod('Epicbox · Over Tor'), findsOneWidget);
    }, skip: !torBuilt);

    testWidgets('with Tor off there are no Tor tags', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _enter(tester, 'To', _https);
      expect(find.byKey(sendTorTagKey), findsNothing);
      await _enter(tester, 'To', _bob);
      expect(find.byKey(sendTorTagKey), findsNothing);
    });
  });

  group('network modes', () {
    const offline = AdvancedPrefs(networkMode: NetworkMode.nodeOnly);
    const torOnly = AdvancedPrefs(networkMode: NetworkMode.torOnly);
    Finder makeFile() => find.widgetWithText(FilledButton, 'Make transaction file');

    testWidgets('Standard: Continue works and no reason shows', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _enter(tester, 'To', _bob);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNotNull);
      expect(find.byKey(netBlockNoteKey), findsNothing);
    });

    testWidgets('Offline: Epicbox is disabled with the reason; File runs and says the node is used', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, advanced: offline);
      await _enter(tester, 'To', _bob);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
      expect(find.text('Node only is on: Epicbox is off. QR Payment and File Transfer work.'), findsOneWidget);
      // File asks the node in use, a public one too: it runs, with the note (a warning).
      await _tap(tester, _segment('Direct · File'));
      await _enter(tester, 'Amount (EPIC)', '1');
      expect(tester.widget<FilledButton>(makeFile()).onPressed, isNotNull);
      expect(find.text('Node only is on: Epicbox is off. QR Payment and File Transfer work.'), findsNothing);
      expect(find.byKey(offlineNodeNoteKey), findsOneWidget);
      expect(find.text('Uses the node'), findsOneWidget);
      await _tap(tester, find.byKey(offlineNodeNoteKey));
      expect(find.text('Uses the node to read the chain and post. For the most privacy, use a local node.'), findsOneWidget);
      expect(h.session.epicboxSends, isEmpty);
    });

    testWidgets('Node only with a LAN node: File runs, Link does not; no peers says the payment waits', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, advanced: offline, node: 'http://10.100.10.20:3413', peers: 0);
      // Epicbox still waits.
      await _enter(tester, 'To', _bob);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
      // No Link in Node only, a local address included.
      await _enter(tester, 'To', 'http://10.0.1.30:3415');
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
      await _tap(tester, _segment('Direct · File'));
      await _enter(tester, 'Amount (EPIC)', '1');
      expect(tester.widget<FilledButton>(makeFile()).onPressed, isNotNull);
      await _tap(tester, makeFile());
      expect(find.text('Open response file'), findsOneWidget);
      expect(find.byKey(offlineNoPeersKey), findsOneWidget);
      expect(find.text('Your node has no peers: the payment waits in its pool until it reconnects.'), findsOneWidget);
    });

    testWidgets('Offline: an onion in To gives the Offline reason, never Turn on Tor (LNX-12)', (tester) async {
      final h = _Harness();
      await h.pump(tester, advanced: offline, payments: _directOn);
      await _enter(tester, 'To', _onion);
      expect(find.byKey(sendTurnOnTorKey), findsNothing);
      expect(find.text('Node only is on: Link is off. QR Payment and File Transfer work.'), findsOneWidget);
    });

    testWidgets('Offline with a public node: File runs with the node note; no peers line (that is the local node\'s)', (tester) async {
      final h = _Harness();
      await h.pump(tester, advanced: offline, peers: 0);
      await _tap(tester, _segment('Direct · File'));
      await _enter(tester, 'Amount (EPIC)', '1');
      expect(tester.widget<FilledButton>(makeFile()).onPressed, isNotNull);
      expect(find.byKey(offlineNodeNoteKey), findsOneWidget);
      expect(find.byKey(offlineNoPeersKey), findsNothing);
    });

    testWidgets('Tor only without Tor: Waiting for Tor, File still works', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, advanced: torOnly);
      await _enter(tester, 'To', _bob);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
      expect(find.text('Waiting for Tor. Nothing connects until it is ready.'), findsOneWidget);
      await _tap(tester, _segment('Direct · File'));
      await _enter(tester, 'Amount (EPIC)', '1');
      expect(tester.widget<FilledButton>(makeFile()).onPressed, isNotNull);
      expect(find.text('Waiting for Tor.'), findsNothing);
    }, skip: !torBuilt);

    testWidgets('Epicbox off: Continue waits with the reason; a saved contact is named as Epicbox-only', (tester) async {
      final h = _Harness();
      // Every method off: Send opens on Epicbox and says it is off.
      await h.pump(tester, payments: const PaymentPrefs(epicbox: false, directFile: false, directQr: false));
      expect(_segment('Direct · File'), findsNothing);
      await _enter(tester, 'To', _bob);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
      expect(find.text('Epicbox is off in Settings › Transactions.'), findsOneWidget);
      await h.session.saveContact(contact: Contact(id: '', name: 'Alice', address: _bob, note: null));
      h.container.invalidate(contactsProvider);
      await tester.pumpAndSettle();
      expect(find.text('Epicbox is off in Settings › Transactions. Alice has only an Epicbox address.'), findsOneWidget);
      expect(h.session.epicboxSends, isEmpty);
    });

    testWidgets('Epicbox off with File on: Send opens on File, without the Epicbox segment', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(epicbox: false));
      // QR and File remain: a selector without Epicbox, on the file amount step.
      expect(find.descendant(of: find.byKey(sendMethodsKey), matching: find.text('Epicbox')), findsNothing);
      expect(find.descendant(of: find.byKey(sendMethodsKey), matching: find.text('Direct · File')), findsOneWidget);
      // QR comes first in the order, so Send opened on it: over to File.
      await _tap(tester, _segment('Direct · File'));
      await _enter(tester, 'Amount (EPIC)', '1');
      expect(tester.widget<FilledButton>(makeFile()).onPressed, isNotNull);
      expect(find.byKey(netBlockNoteKey), findsNothing);
    });

    testWidgets('Tor only with Tor connected: nothing waits', (tester) async {
      final h = _Harness();
      await h.pump(tester, advanced: torOnly);
      await h.torOn(tester);
      await _enter(tester, 'To', _bob);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNotNull);
      expect(find.byKey(netBlockNoteKey), findsNothing);
    }, skip: !torBuilt);
  });

  group('details', () {
    test('an HTTP or Tor send their wallet accepted waits for a block', () {
      final l = englishStrings;
      for (final to in [_https, 'http://$_onion']) {
        final tx = fakeTx(
          id: 3,
          kind: TxKind.sent,
          status: TxStatus.awaitingConfirmation,
          amountDebited: _epic(1),
          counterparty: to,
        );
        expect(
          txExplanation(l, tx, BigInt.from(2500000)),
          'Delivered · Waiting for a block',
        );
      }
      // An epicbox send says it was published, as before.
      final epicbox = fakeTx(
        id: 4,
        kind: TxKind.sent,
        status: TxStatus.awaitingConfirmation,
        amountDebited: _epic(1),
        counterparty: _bob,
      );
      expect(
        txExplanation(l, epicbox, BigInt.from(2500000)),
        isNot('Delivered · Waiting for a block'),
      );
    });
  });

  group('receive', () {
    testWidgets('a strip per tab; Link needs Tor, then the onion', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(
        tester,
        body: const ReceiveView(),
        height: 3600,
        payments: _directOn,
      );
      expect(find.text('Share it to get paid.'), findsOneWidget);
      expect(find.text('Senders can pay while this wallet is closed.'), findsOneWidget);
      // The caption under the address went for room.
      expect(
        find.text(
          'When reading it out, check the first six and last six characters.',
        ),
        findsNothing,
      );
      for (final label in ['Epicbox', 'Link', 'Direct · File']) {
        expect(
          find.descendant(
            of: find.byKey(receiveTabsKey),
            // A long label wraps in two lines; the tooltip holds it whole.
            matching: find.byTooltip(label),
          ),
          findsOneWidget,
          reason: label,
        );
      }
      expect(find.text('HTTP'), findsNothing);
      expect(find.text('Tor'), findsNothing);

      await _tap(tester, find.text('Link'));
      expect(find.text('Straight to this wallet.'), findsOneWidget);
      expect(find.text('Works while the app is open.'), findsOneWidget);
      expect(find.text('Link · Tor needs Tor.'), findsOneWidget);
      expect(
        find.text('Meanwhile, share the Epicbox address.'),
        findsOneWidget,
      );
      expect(find.byKey(receiveTorAddressKey), findsNothing);
      await _tap(tester, find.byKey(receiveTurnOnTorKey));
      expect(h.container.read(phoneTorProvider).receiving, isTrue);
      expect(find.byKey(receiveTorAddressKey), findsOneWidget);
      expect(find.text('Tor · Starting…'), findsOneWidget);
      expect(
        find.text(
          'Some wallets show the address without .onion; both are the same '
          'address.',
        ),
        findsOneWidget,
      );
      // No switch on Receive: the link goes to Settings.
      expect(find.byType(Switch), findsNothing);
      expect(find.text('Tor settings'), findsOneWidget);

      await _tap(tester, find.descendant(of: find.byKey(receiveTabsKey), matching: find.byTooltip('Direct · File')));
      expect(find.text('Hand a file back and forth.'), findsOneWidget);
      expect(
        find.text('Works with no connection between the wallets.'),
        findsOneWidget,
      );
    }, skip: !torBuilt);

    testWidgets('Epicbox with Tor on: the strip adds Over Tor', (tester) async {
      final h = _Harness();
      await h.pump(tester, body: const ReceiveView(), height: 3600);
      await h.torOn(tester);
      expect(find.text('Senders can pay while this wallet is closed. Over Tor.'), findsOneWidget);
    }, skip: !torBuilt);

    testWidgets('receiving help opens the Receive topic', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, body: const HelpScreen(topic: HelpId.receive));
      expect(
        find.text('Receive your first EPIC'),
        findsOneWidget,
      );
    });
  });

  group('sealed files', () {
    final l = lookupAppLocalizations(const Locale('en'));
    Finder makeFile() => find.widgetWithText(FilledButton, 'Make transaction file');

    /// Bob as a paired, verified contact whose wallet opens sealed files.
    PairingRecord pairBob(_Harness h, {SealMode seal = SealMode.on, Duration quiet = const Duration(days: 1)}) {
      h.session.contactsValue.add(Contact(id: 'c-bob', name: 'Bob', address: _bob));
      return h.session.pairing.seedPaired(
        id: 'p-bob',
        name: 'Bob',
        contactId: 'c-bob',
        paymentsAddress: _bob,
        seal: seal,
        lastSealedIn: DateTime.now().subtract(quiet),
      );
    }

    Future<void> toFile(WidgetTester tester) async {
      await _enter(tester, 'To', _bob);
      await _tap(tester, _segment('Direct · File'));
      await _enter(tester, 'Amount (EPIC)', '1');
    }

    testWidgets('a file to a paired contact is sealed for it; Send as plain instead asks first', (tester) async {
      final h = _Harness();
      pairBob(h);
      await h.pump(tester);
      await toFile(tester);
      expect(find.text(l.trustSealedFor('Bob')), findsOneWidget);
      await _tap(tester, makeFile());
      expect(find.text(l.sendSealedTitle('Bob'), skipOffstage: false), findsOneWidget);
      expect(find.text(l.sendSealedBody('Bob')), findsOneWidget);
      expect(find.text(sealedFileName(h.session.sendSlate.slateId)), findsOneWidget);
      expect(h.session.pairing.calls, contains('seal'));

      await _tap(tester, find.byKey(sendAsPlainKey));
      expect(find.text(l.sendAsPlainTitle), findsOneWidget);
      expect(find.text(l.sendAsPlainBody), findsOneWidget);
      await _tap(tester, find.text(l.sendKeepSealed));
      expect(find.text(l.sendSealedTitle('Bob'), skipOffstage: false), findsOneWidget, reason: 'kept sealed');

      await _tap(tester, find.byKey(sendAsPlainKey));
      await _tap(tester, find.byKey(sendAsPlainConfirmKey));
      expect(find.text(l.sendSealedTitle('Bob'), skipOffstage: false), findsNothing);
      expect(find.text(l.sendFileShareHint, skipOffstage: false), findsOneWidget);
      expect((await h.session.pairing.pairing('p-bob'))!.seal, SealMode.degraded);
    });

    testWidgets('after a plain file: Seal this file? with Sealed preselected; Plain makes it plain', (tester) async {
      final h = _Harness();
      pairBob(h, seal: SealMode.degraded);
      await h.pump(tester);
      await toFile(tester);
      expect(find.text(l.sendSealOrPlainTitle), findsOneWidget);
      expect(tester.widget<RadioGroup<bool>>(find.byType(RadioGroup<bool>)).groupValue, isFalse);
      await _tap(tester, find.byKey(sendPlainOptionKey));
      await _tap(tester, makeFile());
      expect(h.session.pairing.calls, isNot(contains('seal')));
      expect(find.text(l.sendSealedTitle('Bob'), skipOffstage: false), findsNothing);
    });

    testWidgets('90 days without a sealed message: the hint offers Send plain', (tester) async {
      final h = _Harness();
      pairBob(h, quiet: const Duration(days: 120));
      await h.pump(tester);
      await toFile(tester);
      expect(find.text(l.sendNotHeardTitle('Bob')), findsOneWidget);
      await _tap(tester, find.byKey(sendPlainShortKey));
      expect(find.text(l.sendNotHeardTitle('Bob')), findsNothing);
      expect(find.text(l.trustSealedFor('Bob')), findsNothing);
      await _tap(tester, makeFile());
      expect(h.session.pairing.calls, isNot(contains('seal')));
    });

    testWidgets('a recipient not paired gets a plain file', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await toFile(tester);
      expect(find.text(l.trustSealedFor('Bob')), findsNothing);
      await _tap(tester, makeFile());
      expect(find.text(l.sendFileShareHint, skipOffstage: false), findsOneWidget);
    });
  });
}
