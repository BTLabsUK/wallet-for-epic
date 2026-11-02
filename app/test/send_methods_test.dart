// SPDX-License-Identifier: Apache-2.0
// Send's methods: one To field picks the method from the address, and a method line under it
// names it (Epicbox, Link · HTTP, Link · HTTPS, Link · Tor). Pay in person and Pay with a file
// sit under an empty field, or beside a hold. HTTP sends straight to their wallet: delivered,
// it waits only for a block and cannot be cancelled; not reached, the amount is on hold with
// Try again and Cancel payment. Each review states its cancel rule. Receive shows the same
// strip per tab, and Tor's honest line.

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
import 'package:epic_wallet/src/ui/info_hint.dart';
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
const String _plainHttp = 'http://wallet.example.com:3415';

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

/// A button of the recipient step: Pay in person and Pay with a file.
Finder _way(String label) => find.widgetWithText(TextButton, label);

/// The method line's names on screen now.
List<String> _lines() => [
  for (final name in ['Epicbox', 'Link · HTTP', 'Link · HTTPS', 'Link · Tor'])
    if (find.text(name).evaluate().isNotEmpty) name,
];

/// Types [text] into To one character at a time, as a keyboard does, and returns the method
/// lines shown after each character.
Future<List<List<String>>> _type(WidgetTester tester, String text) async {
  final field = find.widgetWithText(TextField, 'To');
  final seen = <List<String>>[];
  for (var i = 1; i <= text.length; i++) {
    await tester.enterText(field, text.substring(0, i));
    await tester.pump();
    seen.add(_lines());
  }
  return seen;
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


void main() {
  group('the To field and its method line', () {
    testWidgets('an empty To has no selector: the field, and the direct ways under it', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      expect(find.byKey(sendMethodsKey), findsNothing);
      expect(find.widgetWithText(TextField, 'To'), findsOneWidget);
      expect(find.text('Address or contact'), findsOneWidget);
      expect(_way('Pay with a file'), findsOneWidget);
      expect(_lines(), isEmpty);
    });

    testWidgets('a Link address shows its method line, and the way under the field goes', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      await _enter(tester, 'To', _https);
      expect(_lines(), ['Link · HTTPS']);
      await _enter(tester, 'To', _lan);
      expect(_lines(), ['Link · HTTP']);
      await _enter(tester, 'To', _onion);
      expect(_lines(), ['Link · Tor']);
      await _enter(tester, 'To', _bob);
      expect(_lines(), isNot(contains('Link · Tor')));
      // The way under the field goes once there is an address.
      expect(_way('Pay with a file'), findsNothing);
    }, skip: !torBuilt);

    testWidgets('Link · Tor off: the note, and Turn on turns Link · Tor on', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _enter(tester, 'To', _onion);
      expect(_lines(), ['Link · Tor']);
      expect(find.text('Link · Tor is off in Settings › Transactions.'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Turn on Link · Tor'), findsOneWidget);
      await _tap(tester, find.byKey(sendTurnOnMethodKey));
      expect(h.container.read(appSettingsProvider).value!.payments.linkTor, isTrue);
      expect(find.byKey(sendTurnOnMethodKey), findsNothing);
      expect(find.text('Link · Tor is off in Settings › Transactions.'), findsNothing);
    }, skip: !torBuilt);

    testWidgets('a name finds the contact; the pick shows as a chip', (tester) async {
      final h = _Harness();
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Alice', address: _bob, note: null),
      );
      await h.pump(tester);
      await _enter(tester, 'To', 'ali');
      await _tap(tester, find.text('Alice'));
      expect(find.byKey(sendRecipientFieldKey), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNotNull);
    });
  });

  group('Settings › Transactions', () {
    testWidgets('File off: Pay with a file goes, the To field stays', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(linkHttp: true, linkTor: true, directFile: false));
      expect(_way('Pay with a file'), findsNothing);
      expect(find.widgetWithText(TextField, 'To'), findsOneWidget);
    });

    testWidgets('only Epicbox offered: the field and no direct way', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(directFile: false, directQr: false));
      expect(_way('Pay with a file'), findsNothing);
      expect(_way('Pay in person'), findsNothing);
      expect(find.widgetWithText(TextField, 'To'), findsOneWidget);
    });

    testWidgets('a pasted onion with Link · Tor off says so and waits', (tester) async {
      String? clip = _onion;
      _clipboard(tester, () => clip);
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(directFile: false));
      await _tap(tester, find.text('Paste'));
      expect(_lines(), ['Link · Tor']);
      // Never a silent refusal: the note names the method that is off.
      expect(find.text('Link · Tor is off in Settings › Transactions.'), findsOneWidget);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
    }, skip: !torBuilt);

    testWidgets('Link · HTTP on, Link · Tor off: an http address goes, an onion waits with its reason', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(linkHttp: true));
      await _enter(tester, 'To', _https);
      expect(_lines(), ['Link · HTTPS']);
      expect(find.byKey(netBlockNoteKey), findsNothing);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNotNull);
      await _enter(tester, 'To', _onion);
      expect(find.text('Link · Tor is off in Settings › Transactions.'), findsOneWidget);
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
      expect(_lines(), ['Link · Tor']);
      const line = 'Link · Tor is off in Settings › Transactions. Tor Tom has only a Link · Tor address.';
      expect(find.text(line), findsOneWidget);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
      // The line opens Settings › Transactions.
      await _tap(tester, find.text(line));
      expect(find.byType(SettingsSectionScreen), findsOneWidget);
      expect(h.session.torSends, isEmpty);
    }, skip: !torBuilt);

    testWidgets('an Epicbox address in To waits when Epicbox goes off', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(linkHttp: true));
      await _enter(tester, 'To', _bob);
      await tester.runAsync(() => h.container.read(appSettingsProvider.notifier).setPayments(const PaymentPrefs(epicbox: false, linkHttp: true)));
      await _settle(tester);
      // The address still goes over Epicbox, which is off: Continue waits, with the note.
      expect(_toText(tester), _bob);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
      expect(find.text('Epicbox is off in Settings › Transactions.'), findsOneWidget);
      expect(h.session.epicboxSends, isEmpty);
    });

    testWidgets('File as the default opens the file route', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(defaultMethod: MethodKind.directFile));
      expect(find.text(lookupAppLocalizations(const Locale('en')).sendMakeFile), findsOneWidget);
      expect(find.byKey(sendRecipientFieldKey), findsNothing);
    });
  });

  group('the method follows the address', () {
    testWidgets('typing es shows no method line', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final seen = await _type(tester, 'es');
      expect(seen, everyElement(isEmpty));
      expect(find.byKey(sendSwitchedTagKey), findsNothing);
    });

    testWidgets('a whole Epicbox address pasted over a Link one replaces it', (
      tester,
    ) async {
      String? clip = _https;
      _clipboard(tester, () => clip);
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      await _tap(tester, find.text('Paste'));
      expect(_lines(), ['Link · HTTPS']);
      await _tap(tester, find.byKey(sendRecipientClearKey));
      clip = _bob;
      await _tap(tester, find.text('Paste'));
      expect(_toText(tester), _bob);
      expect(_lines(), isNot(contains('Link · HTTPS')));
    });

    testWidgets(
      'a bare onion typed by hand gets its method line once, at the 56th character',
      (tester) async {
        final h = _Harness();
        await h.pump(tester);
        final seen = await _type(tester, _name);
        expect(seen.indexWhere((s) => s.isNotEmpty), _name.length - 1);
        expect(seen.last, ['Link · Tor']);
        // One more character breaks the onion: the line goes with it.
        final more = await _type(tester, '${_name}x');
        expect(more.last, isNot(contains('Link · Tor')));
      },
      skip: !torBuilt,
    );

    testWidgets('http://10.0.1.24 typed gets its line from http:// on', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      const url = 'http://10.0.1.24';
      final seen = await _type(tester, url);
      expect(seen[url.indexOf('//')], isEmpty, reason: 'http:/ is no scheme yet');
      expect(seen.sublist(url.indexOf('//') + 1), everyElement(['Link · HTTP']));
    });

    testWidgets('https:// typed names Link · HTTPS at once, with port 3415', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      final seen = await _type(tester, 'https://203.0');
      expect(seen['https://'.length - 1], ['Link · HTTPS']);
      expect(seen.last, ['Link · HTTPS']);
      expect(find.textContaining(':3415', findRichText: true), findsWidgets);
    });

    testWidgets('picks by method: a contact fills its address whose method is on (qa-next)', (tester) async {
      final h = _Harness();
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Two Way', tor: _onion, http: _https, note: null),
      );
      await h.pump(tester, payments: const PaymentPrefs(linkHttp: true));
      await _tap(tester, find.text('Contacts'));
      await _tap(tester, find.text('Two Way'));
      expect(_lines(), ['Link · HTTPS']);
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
      expect(find.text('Link · Tor is off in Settings › Transactions.'), findsOneWidget);
      expect(find.textContaining('has only'), findsNothing);
    }, skip: !torBuilt);

    testWidgets('picks by method: a code with an Epicbox and an onion address fills the one that is on (qa-next)', (tester) async {
      String? clip = 'epic:$_bob?method=direct&direct=http://$_onion';
      _clipboard(tester, () => clip);
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(linkHttp: true));
      await _tap(tester, find.text('Paste'));
      expect(_toText(tester), _bob);
      expect(_lines(), isNot(contains('Link · Tor')));
      expect(find.byKey(netBlockNoteKey), findsNothing);
    });

    testWidgets('picks by method: Epicbox off, the code\'s onion with Link · Tor on (qa-next)', (tester) async {
      String? clip = 'epic:$_bob?direct=http://$_onion';
      _clipboard(tester, () => clip);
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(epicbox: false, linkTor: true));
      await _tap(tester, find.text('Paste'));
      expect(_toText(tester), _onion);
      expect(_lines(), ['Link · Tor']);
    }, skip: !torBuilt);

    testWidgets('an onion contact picked shows the Link · Tor line', (tester) async {
      final h = _Harness();
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Tor Tom', address: _onion, note: null),
      );
      await h.pump(tester);
      await _tap(tester, find.text('Contacts'));
      await _tap(tester, find.text('Tor Tom'));
      expect(_lines(), ['Link · Tor']);
    });

    testWidgets(
      'Link · Tor off: a pasted onion says it is off; an http address needs no switch',
      (tester) async {
        String? clip = _onion;
        _clipboard(tester, () => clip);
        final h = _Harness();
        await h.pump(tester);
        await _tap(tester, find.text('Paste'));
        expect(_lines(), ['Link · Tor']);
        expect(find.text('Link · Tor is off in Settings › Transactions.'), findsOneWidget);
        expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
        // The phone sends to an http(s) address with no switch on.
        await _tap(tester, find.byKey(sendRecipientClearKey));
        clip = _https;
        await _tap(tester, find.text('Paste'));
        expect(_lines(), ['Link · HTTPS']);
        expect(find.byKey(netBlockNoteKey), findsNothing);
        expect(tester.widget<FilledButton>(_continue).onPressed, isNotNull);
        await tester.pump(const Duration(seconds: 2));
      }, skip: !torBuilt,
    );
  });

  group('HTTP send', () {
    testWidgets('delivered: the tracker waits for a block, with no Cancel', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      await h.toReview(tester, _https);
      expect(_reviewMethod('Link · HTTPS'), findsOneWidget);
      expect(
        find.text('Cannot be cancelled once their wallet accepts it.'),
        findsOneWidget,
      );
      await _tap(tester, find.text('Send 1.0\u00a0EPIC'));
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
      await _tap(tester, find.text('Send 1.0\u00a0EPIC'));
      expect(
        find.text(
          'Their wallet was not reached. The amount stays locked until you cancel '
          'it, or for up to 1 day.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(sendTryAgainKey), findsOneWidget);
      expect(find.byKey(sendCancelPaymentKey), findsOneWidget);
      expect(find.text('Send 1.0\u00a0EPIC'), findsNothing);

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
      await _tap(tester, find.text('Send 1.0\u00a0EPIC'));
      await _tap(tester, find.byKey(sendCancelPaymentKey));
      expect(h.session.cancelledTxIds, hasLength(1));
      expect(find.text('2 of 3'), findsOneWidget);
    });

    testWidgets('plain HTTP to another device sends without asking', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      await h.toReview(tester, _lan);
      await _tap(tester, find.text('Send 1.0\u00a0EPIC'));
      expect(find.text('Not encrypted. Send anyway?'), findsNothing);
      expect(h.session.httpSends.single.allowPlainHttp, isTrue);
    });
  });

  group('review', () {
    testWidgets('the method row and the cancel rule: Epicbox', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.toReview(tester, _bob);
      expect(find.text('Via'), findsOneWidget);
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
      'an onion with Tor off: Tor starts when you send; the review waits for it',
      (tester) async {
        final h = _Harness();
        await h.pump(tester, payments: _directOn);
        await _enter(tester, 'To', _onion);
        expect(_lines(), ['Link · Tor']);
        expect(find.text('Tor starts when you send.'), findsOneWidget);
        expect(find.byKey(sendTurnOnTorKey), findsNothing);
        expect(tester.widget<FilledButton>(_continue).onPressed, isNotNull);
        await _tap(tester, _continue);
        await _enter(tester, 'Amount (EPIC)', '1');
        await _tap(tester, _continue);
        expect(find.text('Review'), findsOneWidget);
        // Tor starts as the review opens; the send waits for it.
        expect(h.session.torStarts, hasLength(1));
        await h.emit(tester, TorEventKind.starting, progress: 60);
        await h.emit(tester, TorEventKind.ready);
        expect(find.text('Ready to send over Tor'), findsOneWidget);
        expect(h.session.torSends, isEmpty);
      }, skip: !torBuilt,
    );

    testWidgets('Tor not connected: Retry only, no Turn Tor off (D-05); nothing goes', (
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
      expect(find.byKey(sendTurnOffTorKey), findsNothing);
      expect(h.container.read(phoneTorProvider).receiving, isTrue);
    }, skip: !torBuilt);

    testWidgets('Tor on: https and onion lines say Over Tor', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      await h.torOn(tester);
      await _enter(tester, 'To', _https);
      expect(_lines(), ['Link · HTTPS']);
      expect(find.text('Over Tor'), findsOneWidget);
      await _enter(tester, 'To', _onion);
      // An onion needs no tag: Tor is its method.
      expect(_lines(), ['Link · Tor']);
      expect(find.byKey(sendTorNoticeKey), findsNothing);

      // The review says it too.
      await h.toReview(tester, _https);
      expect(_reviewMethod('Link · HTTPS\u00A0· Over Tor'), findsOneWidget);
    }, skip: !torBuilt);

    testWidgets('Tor on: plain http to an internet host is held, and says why', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: _directOn);
      await h.torOn(tester);
      await _enter(tester, 'To', _plainHttp);
      expect(find.text('Tor is on. Plain http:// cannot go over Tor.'), findsOneWidget);
      expect(find.byKey(sendTurnOffTorKey), findsOneWidget);
      // Its caption: the switch is for every connection (D-05).
      expect(find.byKey(sendTurnOffTorCaptionKey), findsOneWidget);
      // Continue waits: nothing leads on to a send through a Tor exit.
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
      await _enter(tester, 'To', _https);
      expect(find.byKey(sendTurnOffTorKey), findsNothing);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNotNull);
      await _enter(tester, 'To', _plainHttp);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
      // A device on the local network is not held: it does not go through a Tor exit.
      await _enter(tester, 'To', _lan);
      expect(find.byKey(sendTurnOffTorKey), findsNothing);
      expect(find.text('Your network'), findsOneWidget);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNotNull);
      await _enter(tester, 'To', _plainHttp);
      // Turn Tor off: Continue goes on to the consent for plain http.
      await _tap(tester, find.byKey(sendTurnOffTorKey));
      expect(find.byKey(sendTurnOffTorKey), findsNothing);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNotNull);
    }, skip: !torBuilt);

    testWidgets('Tor on: an Epicbox review says Over Tor', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.torOn(tester);
      await h.toReview(tester, _bob);
      expect(_reviewMethod('Epicbox\u00A0· Over Tor'), findsOneWidget);
    }, skip: !torBuilt);

    testWidgets('with Tor off there are no Tor tags', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _enter(tester, 'To', _https);
      expect(find.text('Over Tor'), findsNothing);
      await _enter(tester, 'To', _bob);
      expect(find.text('Over Tor'), findsNothing);
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

    testWidgets('Offline: Epicbox is held with the reason; File runs and says the node is used', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, advanced: offline);
      expect(find.widgetWithText(TextField, 'To'), findsOneWidget);
      await _enter(tester, 'To', _bob);
      expect(find.text('Node only is on. Only the node connects.'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Turn off Node only'), findsOneWidget);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
      await _tap(tester, _way('Pay with a file'));
      expect(find.widgetWithText(TextField, 'To'), findsNothing);
      await _enter(tester, 'Amount (EPIC)', '1');
      expect(tester.widget<FilledButton>(makeFile()).onPressed, isNotNull);
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
      // No Epicbox and no Link in Node only, a local address included.
      await _enter(tester, 'To', _lan);
      expect(find.text('Node only is on. Only the node connects.'), findsOneWidget);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
      await _tap(tester, _way('Pay with a file'));
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
      expect(find.text('Node only is on. Only the node connects.'), findsOneWidget);
      expect(find.byKey(sendTurnOnTorKey), findsNothing);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
    }, skip: !torBuilt);

    testWidgets('Offline with a public node: File runs with the node note; no peers line (that is the local node\'s)', (tester) async {
      final h = _Harness();
      await h.pump(tester, advanced: offline, peers: 0);
      await _tap(tester, _way('Pay with a file'));
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
      await _tap(tester, find.byKey(sendRecipientClearKey));
      await _tap(tester, _way('Pay with a file'));
      await _enter(tester, 'Amount (EPIC)', '1');
      expect(tester.widget<FilledButton>(makeFile()).onPressed, isNotNull);
      expect(find.text('Waiting for Tor.'), findsNothing);
    }, skip: !torBuilt);

    testWidgets('Epicbox off: Continue waits with the reason; a saved contact is named as Epicbox-only', (tester) async {
      final h = _Harness();
      // Epicbox off, no direct way: an Epicbox address says Epicbox is off.
      await h.pump(tester, payments: const PaymentPrefs(epicbox: false, directFile: false, directQr: false));
      expect(_way('Pay with a file'), findsNothing);
      await _enter(tester, 'To', _bob);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
      expect(find.text('Epicbox is off in Settings\u00a0›\u00a0Transactions.'), findsOneWidget);
      await h.session.saveContact(contact: Contact(id: '', name: 'Alice', address: _bob, note: null));
      h.container.invalidate(contactsProvider);
      await tester.pumpAndSettle();
      expect(find.text('Epicbox is off in Settings\u00a0›\u00a0Transactions. Alice has only an Epicbox address.'), findsOneWidget);
      expect(h.session.epicboxSends, isEmpty);
    });

    testWidgets('Epicbox off with QR off: Send opens on the file route', (tester) async {
      final h = _Harness();
      await h.pump(tester, payments: const PaymentPrefs(epicbox: false, directQr: false));
      expect(find.byKey(sendMethodsKey), findsNothing);
      expect(find.widgetWithText(TextField, 'To'), findsNothing);
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
      expect(find.text('Share the address to get paid.'), findsOneWidget);
      expect(_info('The Epicbox server holds a payment until this wallet opens.'), findsOneWidget);
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

      await _tap(tester, find.descendant(of: find.byKey(receiveTabsKey), matching: find.byTooltip('Link')));
      expect(find.text('Straight to this wallet.'), findsOneWidget);
      expect(_info('Works while the app is open.'), findsOneWidget);
      expect(find.text('Link · Tor needs Tor.'), findsOneWidget);
      expect(
        find.text('Meanwhile, share the Epicbox address.'),
        findsOneWidget,
      );
      expect(find.byKey(receiveTorAddressKey), findsNothing);
      await _tap(tester, find.byKey(receiveTurnOnTorKey));
      expect(h.container.read(phoneTorProvider).receiving, isTrue);
      expect(find.byKey(receiveTorAddressKey), findsOneWidget);
      expect(find.text('Tor\u00A0· Starting'), findsOneWidget);
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
        _info('Works with no connection between the wallets.'),
        findsOneWidget,
      );
    }, skip: !torBuilt);

    testWidgets('Epicbox with Tor on: the strip adds Over Tor', (tester) async {
      final h = _Harness();
      await h.pump(tester, body: const ReceiveView(), height: 3600);
      await h.torOn(tester);
      expect(_info('The Epicbox server holds a payment until this wallet opens. Over Tor.'), findsOneWidget);
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

    // Offline holds the Epicbox address and offers Pay with a file beside it, keeping the
    // address in To: the one way to a file for a named recipient.
    const offline = AdvancedPrefs(networkMode: NetworkMode.nodeOnly);

    Future<void> toFile(WidgetTester tester) async {
      await _enter(tester, 'To', _bob);
      await _tap(tester, _way('Pay with a file'));
      await _enter(tester, 'Amount (EPIC)', '1');
    }

    testWidgets('a file to a paired contact is sealed for it; Send as plain instead asks first', (tester) async {
      final h = _Harness();
      pairBob(h);
      await h.pump(tester, advanced: offline);
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
      await h.pump(tester, advanced: offline);
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
      await h.pump(tester, advanced: offline);
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
      await h.pump(tester, advanced: offline);
      await toFile(tester);
      expect(find.text(l.trustSealedFor('Bob')), findsNothing);
      await _tap(tester, makeFile());
      expect(find.text(l.sendFileShareHint, skipOffstage: false), findsOneWidget);
    });
  });
}

/// A method strip's ⓘ holding [text]: everything past the strip's one line is behind it.
Finder _info(String text) => find.byWidgetPredicate((w) => w is InfoHint && w.text == text);
