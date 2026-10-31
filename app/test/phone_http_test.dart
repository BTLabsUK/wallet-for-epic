// SPDX-License-Identifier: Apache-2.0
// Link · HTTP receiving on the phone: the listener runs while a wallet is open and its switch
// is on, on every interface at port 3415, and never while Tor is on; it stops when the switch
// goes off and on lock. The card on Receive › Link shows the LAN address with Copy and a QR
// code hidden until asked for, or the listener's state with Retry where Retry helps.

import 'dart:async';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/phone_http.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/receive_http_card.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/test_settings.dart' show useNetworkModeFile;

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

/// The wallet's Tor, settled: [receiving] is the one Tor switch.
class _Tor extends PhoneTor {
  _Tor(this.initial);

  final PhoneTorState initial;

  @override
  PhoneTorState build() => initial;

  void set(PhoneTorState s) => state = s;
}

const _torOff = PhoneTorState(phase: PhoneTorPhase.off);
const _torOn = PhoneTorState(phase: PhoneTorPhase.ready, receiving: true);

class _Harness {
  _Harness({this.payments = const PaymentPrefs(linkHttp: true), this.tor = _torOff, this.advanced, this.trustedNetworks = '192.168.1'});

  /// What the store holds under [trustedNetworksKey]: the test network is trusted by default.
  final String? trustedNetworks;

  final AdvancedPrefs? advanced;

  final PaymentPrefs payments;
  final PhoneTorState tor;
  final session = FakeWalletSession();
  final service = FakeWalletService();
  final store = MemorySecretStore();
  final network = StreamController<bool>.broadcast();
  String? ip = '10.100.10.20';
  final copied = <String>[];
  late ProviderContainer container;

  PhoneHttpState get http => container.read(phoneHttpProvider);

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    if (trustedNetworks != null) store.values[trustedNetworksKey] = trustedNetworks!;
    if (advanced != null) {
      store.values['app.advanced_prefs'] = advanced!.encode();
      useNetworkModeFile(advanced!.networkMode);
    }
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store..values['app.payment_prefs'] = payments.encode()),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          sessionProvider.overrideWith(() => _OpenSession(session)),
          phoneTorProvider.overrideWith(() => _Tor(tor)),
          networkChangesProvider.overrideWithValue(network.stream),
          lanAddressReaderProvider.overrideWithValue(() async => ip),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SizedBox(width: 360, child: SingleChildScrollView(child: ReceiveHttpCard())),
          ),
        ),
      ),
    );
    container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await settle(tester);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await network.close();
      NetGate.setPayments(PaymentPrefs.defaults);
    });
  }

  /// Lets the settings load and the listener's work on real async finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      // Not pumpAndSettle: Starting… spins until the listener answers.
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> emit(WidgetTester tester, HttpListenerEventKind kind, {int? port}) async {
    session.httpListenerEvents.add(HttpListenerEvent(kind: kind, port: port));
    await settle(tester);
  }

  Future<void> setPayments(WidgetTester tester, PaymentPrefs prefs) async {
    await tester.runAsync(() => container.read(appSettingsProvider.notifier).setPayments(prefs));
    await settle(tester);
  }

  Future<void> setTor(WidgetTester tester, PhoneTorState s) async {
    (container.read(phoneTorProvider.notifier) as _Tor).set(s);
    await settle(tester);
  }
}

void main() {
  group('pickLanIpv4', () {
    test('Wi-Fi first, never loopback, mobile data or a VPN', () {
      expect(
        pickLanIpv4([
          (name: 'lo', address: '127.0.0.1'),
          (name: 'rmnet_data0', address: '100.63.3.9'),
          (name: 'tun0', address: '10.8.0.2'),
          (name: 'eth0', address: '10.0.0.5'),
          (name: 'wlan0', address: '10.100.10.20'),
        ]),
        '10.100.10.20',
      );
      expect(pickLanIpv4([(name: 'eth0', address: '10.0.0.5')]), '10.0.0.5');
      expect(pickLanIpv4([(name: 'wlan0', address: '169.254.1.1')]), isNull);
      expect(pickLanIpv4([(name: 'rmnet_data0', address: '100.63.3.9')]), isNull);
      expect(pickLanIpv4(const []), isNull);
    });
  });

  test('lanNetworkKey: the /24 of an IPv4 LAN address, nothing else', () {
    expect(lanNetworkKey('http://10.100.10.20:3415'), '192.168.1');
    expect(lanNetworkKey('10.0.0.5'), '10.0.0');
    expect(lanNetworkKey('192.168.1'), isNull);
    expect(lanNetworkKey('http://[fe80::1]:3415'), isNull);
    expect(lanNetworkKey('junk'), isNull);
    expect(lanNetworkKey(null), isNull);
  });

  testWidgets('a network not trusted: nothing listens, the card says why; trusting it starts it and is kept', (tester) async {
    final h = _Harness(trustedNetworks: null);
    await h.pump(tester);
    expect(h.session.httpListenerStarts, isEmpty);
    expect(h.http.phase, PhoneHttpPhase.notTrusted);
    expect(find.text('Off on this network'), findsOneWidget);
    // The reason sits behind the info icon, not on the card.
    expect(find.textContaining('networks you trust'), findsNothing);
    await tester.tap(find.byKey(receiveHttpNotTrustedInfoKey));
    await h.settle(tester);
    expect(find.textContaining('networks you trust'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await h.settle(tester);
    await tester.tap(find.byKey(receiveHttpTrustKey));
    await h.settle(tester);
    expect(h.session.httpListenerStarts, hasLength(1));
    expect(h.store.values[trustedNetworksKey], '192.168.1');

    // Another network: it stops until that one is trusted too.
    await h.emit(tester, HttpListenerEventKind.started, port: 3415);
    h.ip = '10.20.30.40';
    h.network.add(true);
    await h.settle(tester);
    expect(h.http.phase, PhoneHttpPhase.notTrusted);
    expect(h.session.httpListenerStops, greaterThanOrEqualTo(1));
  });

  testWidgets('the trusted networks are in the state; forgetting the one in use stops the listener and the store follows', (tester) async {
    final h = _Harness(trustedNetworks: '10.0.0,192.168.1');
    await h.pump(tester);
    expect(h.http.trustedNetworks, ['10.0.0', '192.168.1']);
    expect(h.session.httpListenerStarts, hasLength(1));
    await h.emit(tester, HttpListenerEventKind.started, port: 3415);

    // A network not trusted: nothing changes.
    await h.container.read(phoneHttpProvider.notifier).forgetTrusted('172.16.0');
    await h.settle(tester);
    expect(h.http.trustedNetworks, ['10.0.0', '192.168.1']);
    expect(h.session.httpListenerStops, 0);

    await h.container.read(phoneHttpProvider.notifier).forgetTrusted('192.168.1');
    await h.settle(tester);
    expect(h.http.trustedNetworks, ['10.0.0']);
    expect(h.store.values[trustedNetworksKey], '10.0.0');
    expect(h.http.phase, PhoneHttpPhase.notTrusted);
    expect(h.session.httpListenerStops, 1);

    // The last one: an empty store entry, no network trusted.
    await h.container.read(phoneHttpProvider.notifier).forgetTrusted('10.0.0');
    await h.settle(tester);
    expect(h.http.trustedNetworks, isEmpty);
    expect(h.store.values[trustedNetworksKey], '');
  });

  testWidgets('starts on every interface at 3415 with the wallet open and the switch on; the card shows the address', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    expect(h.session.httpListenerStarts, [(exposure: HttpExposure.internet, port: phoneHttpPort)]);
    expect(h.http.phase, PhoneHttpPhase.starting);
    expect(find.text('Starting…'), findsOneWidget);

    await h.emit(tester, HttpListenerEventKind.started, port: 3415);
    expect(h.http.phase, PhoneHttpPhase.listening);
    expect(h.http.address, 'http://10.100.10.20:3415');
    expect(find.text('Link · HTTP address'), findsOneWidget);
    expect(find.text('http://10.100.10.20:3415'), findsOneWidget);
    expect(find.text('For wallets on this Wi-Fi network, while this wallet is open.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Copy'));
    await h.settle(tester);
    expect(h.copied, ['http://10.100.10.20:3415']);
  });

  testWidgets('the QR code is hidden until Show QR, and Hide QR hides it again', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await h.emit(tester, HttpListenerEventKind.started, port: 3415);
    expect(find.byKey(receiveHttpQrKey), findsNothing);
    await tester.tap(find.byKey(receiveHttpQrButtonKey));
    await tester.pumpAndSettle();
    expect(find.byKey(receiveHttpQrKey), findsOneWidget);
    expect(find.bySemanticsLabel('QR code of the Link · HTTP address'), findsOneWidget);
    expect(tester.getSize(find.byKey(receiveHttpCardKey)).width, lessThanOrEqualTo(360));
    await tester.tap(find.text('Hide QR'));
    await tester.pumpAndSettle();
    expect(find.byKey(receiveHttpQrKey), findsNothing);
  });

  testWidgets('nothing starts with the switch off; it stops when the switch goes off', (tester) async {
    final h = _Harness(payments: const PaymentPrefs());
    await h.pump(tester);
    expect(h.session.httpListenerStarts, isEmpty);
    expect(h.http.phase, PhoneHttpPhase.off);
    expect(find.byKey(receiveHttpCardKey), findsNothing);

    await h.setPayments(tester, const PaymentPrefs(linkHttp: true));
    expect(h.session.httpListenerStarts, hasLength(1));
    await h.emit(tester, HttpListenerEventKind.started, port: 3415);

    await h.setPayments(tester, const PaymentPrefs());
    expect(h.session.httpListenerStops, 1);
    expect(h.http.phase, PhoneHttpPhase.off);
    expect(find.byKey(receiveHttpCardKey), findsNothing);
  });

  testWidgets('lock stops it: our side lets go, LEPIC stops it with the session', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await h.emit(tester, HttpListenerEventKind.started, port: 3415);
    expect(h.session.httpListenerEvents.hasListener, isTrue);
    h.container.read(sessionProvider.notifier).lock();
    await h.settle(tester);
    expect(h.http.phase, PhoneHttpPhase.off);
    expect(h.session.httpListenerEvents.hasListener, isFalse);
    expect(find.byKey(receiveHttpCardKey), findsNothing);
  });

  testWidgets('Tor on: off while Tor is on and no start; Tor off starts it; Tor on again stops it', (tester) async {
    final h = _Harness(tor: _torOn);
    await h.pump(tester);
    expect(h.session.httpListenerStarts, isEmpty);
    expect(h.http.phase, PhoneHttpPhase.offWhileTor);
    expect(find.text('Off while Tor is on.'), findsOneWidget);

    await h.setTor(tester, _torOff);
    expect(h.session.httpListenerStarts, hasLength(1));
    await h.emit(tester, HttpListenerEventKind.started, port: 3415);
    expect(h.http.phase, PhoneHttpPhase.listening);

    await h.setTor(tester, const PhoneTorState(phase: PhoneTorPhase.starting, receiving: true));
    expect(h.session.httpListenerStops, 1);
    expect(h.http.phase, PhoneHttpPhase.offWhileTor);
  });

  testWidgets('never before the Tor switch is read', (tester) async {
    final h = _Harness(tor: PhoneTorState.unread);
    await h.pump(tester);
    expect(h.session.httpListenerStarts, isEmpty);
    await h.setTor(tester, _torOff);
    expect(h.session.httpListenerStarts, hasLength(1));
  });

  testWidgets('port in use: the card says so with Retry, which starts it again', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await h.emit(tester, HttpListenerEventKind.portInUse, port: 3415);
    expect(h.http.phase, PhoneHttpPhase.portInUse);
    expect(find.text('Port 3415 is in use by another program.'), findsOneWidget);
    expect(h.session.httpListenerStarts, hasLength(1));

    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    await h.settle(tester);
    expect(h.session.httpListenerStarts, hasLength(2));
    expect(h.http.phase, PhoneHttpPhase.starting);
    await h.emit(tester, HttpListenerEventKind.started, port: 3415);
    expect(h.http.phase, PhoneHttpPhase.listening);
  });

  testWidgets('bind failed: Could not start, with Retry', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await h.emit(tester, HttpListenerEventKind.bindFailed, port: 3415);
    expect(h.http.phase, PhoneHttpPhase.failed);
    expect(find.text('Could not start.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
  });

  testWidgets('no Wi-Fi address: nothing listens (QA-1, mobile data alone); a network change starts it', (tester) async {
    final h = _Harness()..ip = null;
    await h.pump(tester);
    expect(h.session.httpListenerStarts, isEmpty);
    expect(h.http.phase, PhoneHttpPhase.noNetwork);
    expect(find.text('Not on a Wi-Fi network. No address to hand out.'), findsOneWidget);

    h.ip = '10.0.1.33';
    h.network.add(true);
    await h.settle(tester);
    expect(h.session.httpListenerStarts, hasLength(1));
    await h.emit(tester, HttpListenerEventKind.started, port: 3415);
    expect(h.http.phase, PhoneHttpPhase.listening);
    expect(find.text('http://10.0.1.33:3415'), findsOneWidget);
    // The settle timer's second read.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('the Wi-Fi address gone: it stops, the no-network line shows; back: it starts again (QA-1)', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await h.emit(tester, HttpListenerEventKind.started, port: 3415);
    expect(h.http.phase, PhoneHttpPhase.listening);

    h.ip = null;
    h.network.add(true);
    await h.settle(tester);
    expect(h.session.httpListenerStops, 1);
    expect(h.http.phase, PhoneHttpPhase.noNetwork);
    expect(find.text('Not on a Wi-Fi network. No address to hand out.'), findsOneWidget);

    h.ip = '10.0.1.40';
    h.network.add(true);
    await h.settle(tester);
    expect(h.session.httpListenerStarts, hasLength(2));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Node only: nothing listens, the Node only line', (tester) async {
    final h = _Harness(advanced: const AdvancedPrefs(networkMode: NetworkMode.nodeOnly));
    await h.pump(tester);
    expect(h.session.httpListenerStarts, isEmpty);
    expect(h.http.phase, PhoneHttpPhase.offline);
    expect(find.text('Link receiving is off in Node only.'), findsOneWidget);
    NetGate.set(NetworkMode.standard);
  });
}
