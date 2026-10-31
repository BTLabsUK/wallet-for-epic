// SPDX-License-Identifier: Apache-2.0
// Settings › Transactions on the phone: the payment methods, one switch each, grouped by
// family (Epicbox; Link › HTTP, Tor; Direct › QR Payment, File Transfer), the last one on
// staying on; the method Send starts on (only among the methods offered, Link once); and, with
// Advanced › Send options, the send defaults that used to sit on Outputs. The Advanced page no
// longer holds a Link switch; an old one is taken over.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network_gate.dart' show NetGate;
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/phone_http.dart' show lanAddressReaderProvider, trustedNetworksKey;
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/backup_screen.dart' show backedUpProvider;
import 'package:epic_wallet/src/ui/info_hint.dart';
import 'package:epic_wallet/src/ui/notices.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart' show appConfig;

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

/// Tor as [initial] says: by default off, with the onion read (the app has Tor).
class _Tor extends PhoneTor {
  _Tor([this.initial = _torOff]);

  final PhoneTorState initial;

  @override
  PhoneTorState build() => initial;
}

const _onion = 'abcdefghijklmnopqrstuvwxyz234567abcdefghijklmnopqrstuvwx';
const _torOff = PhoneTorState(phase: PhoneTorPhase.off, onion: _onion);
const _torOn = PhoneTorState(phase: PhoneTorPhase.ready, onion: _onion, receiving: true);
const _noTor = PhoneTorState(phase: PhoneTorPhase.unavailable);

class _OpenSession extends SessionNotifier {
  _OpenSession([this.transactions = const []]);

  final List<TxEntry> transactions;

  @override
  WalletSession? build() => FakeWalletSession(transactions: transactions);
}

/// A send over Epicbox still waiting for the recipient's reply.
final TxEntry _waitingEpicboxSend = fakeTx(
  id: 7,
  slateId: 'waiting-epicbox',
  kind: TxKind.sent,
  status: TxStatus.awaitingRecipient,
  transport: 'epicbox',
  amountDebited: BigInt.from(100000000),
  numInputs: 1,
  numOutputs: 0,
);

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

const _sendOptions = AdvancedPrefs(features: {AdvancedFeature.sendOptions});

/// Opens [section] over a hub that reads [store]; returns the container.
Future<ProviderContainer> _pump(
  WidgetTester tester,
  MemorySecretStore store, {
  SettingsSection section = SettingsSection.transactions,
  bool phone = false,
  List<TxEntry> transactions = const [],
  PhoneTorState tor = _torOff,
  String? lanAddress,
}) async {
  tester.view.physicalSize = const Size(1080, 4800);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(FakeWalletService()),
        secretStoreProvider.overrideWithValue(store),
        phonePaymentsProvider.overrideWithValue(phone),
        updatePlatformProvider.overrideWithValue(null),
        relayDirectoryProvider.overrideWithValue(_NoRelays()),
        sessionProvider.overrideWith(() => _OpenSession(transactions)),
        phoneTorProvider.overrideWith(() => _Tor(tor)),
        backedUpProvider.overrideWith((ref) async => true),
        if (lanAddress != null) lanAddressReaderProvider.overrideWithValue(() async => lanAddress),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final advanced =
              ref.watch(appSettingsProvider).value?.advanced ?? AdvancedPrefs.none;
          return MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) =>
                AdvancedOptions(prefs: advanced, child: child!),
            home: SettingsSectionScreen(section: section),

          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

MemorySecretStore _store([Map<String, String> values = const {}]) =>
    MemorySecretStore({'app.network': 'mainnet', ...values});

Finder _row(String key) => find.byKey(ValueKey(key));

Finder _switchOf(String key) =>
    find.descendant(of: _row(key), matching: find.byType(Switch));

/// The page's rows from the Payment methods header down, as keys: family heads and switches.
List<String> _methodRows(WidgetTester tester) => [
  for (final e in find.byWidgetPredicate((w) {
    final k = w.key;
    return k is ValueKey<String> &&
        (k.value.startsWith('tx-family-') ||
            const {'tx-epicbox', 'tx-http', 'tx-tor', 'tx-qr', 'tx-file'}.contains(k.value));
  }).evaluate())
    (e.widget.key! as ValueKey<String>).value,
];

/// The title a method's switch shows.
String? _titleOf(WidgetTester tester, String key) => tester
    .widget<TitleWithHint>(find.descendant(of: _row(key), matching: find.byType(TitleWithHint)))
    .title;

PaymentPrefs _payments(ProviderContainer c) =>
    c.read(appSettingsProvider).value!.payments;

void main() {
  testWidgets('methods: one switch each, grouped by family; Epicbox on by default', (tester) async {
    await _pump(tester, _store());
    expect(find.text(_l.txMethodsHeader), findsOneWidget);
    // Epicbox alone, then Link › HTTP, Tor, then Direct › File Transfer (QR is the phone's).
    expect(_methodRows(tester), [
      'tx-epicbox',
      'tx-family-link',
      'tx-http',
      'tx-tor',
      'tx-family-direct',
      'tx-file',
    ]);
    // A family head: its name only.
    expect(find.descendant(of: _row('tx-family-link'), matching: find.text(_l.methodDirect)), findsOneWidget);
    expect(find.descendant(of: _row('tx-family-direct'), matching: find.text(_l.methodDirectFamily)), findsOneWidget);
    // Under its family a method goes by its own name: Epicbox, HTTP, Tor, File Transfer.
    expect(_titleOf(tester, 'tx-epicbox'), 'Epicbox');
    expect(_titleOf(tester, 'tx-http'), 'HTTP');
    expect(_titleOf(tester, 'tx-tor'), 'Tor');
    expect(_titleOf(tester, 'tx-file'), 'File Transfer');
    // Epicbox: a switch, on; the row is the label only, the explanation behind its info icon.
    expect(find.descendant(of: _row('tx-epicbox'), matching: find.text(_l.txEpicboxHint)), findsNothing);
    expect(tester.widget<Switch>(_switchOf('tx-epicbox')).value, isTrue);
    // Link is off by default, File Transfer on.
    expect(tester.widget<Switch>(_switchOf('tx-http')).value, isFalse);
    expect(tester.widget<Switch>(_switchOf('tx-tor')).value, isFalse);
    expect(tester.widget<Switch>(_switchOf('tx-file')).value, isTrue);
    // Off, Link · Tor says nothing about Tor.
    expect(find.byKey(txTorNeededKey), findsNothing);
  }, skip: !torBuilt);

  testWidgets('where the app has no Tor, HTTP stays and Tor goes', (tester) async {
    await _pump(tester, _store(), tor: _noTor);
    expect(_row('tx-http'), findsOneWidget);
    expect(_row('tx-tor'), findsNothing);
  });

  testWidgets('a phone has no Tor: Link · Tor on keeps its row, so it can be turned off', (tester) async {
    final c = await _pump(tester, _store({'app.payment_prefs': 'v2,tor,file|epicbox'}), tor: _noTor);
    expect(tester.widget<Switch>(_switchOf('tx-tor')).value, isTrue);
    await tester.tap(_switchOf('tx-tor'));
    await tester.pumpAndSettle();
    expect(_payments(c).linkTor, isFalse);
    expect(_row('tx-tor'), findsOneWidget, reason: 'a row shown stays while the page is open');
  }, skip: !torBuilt);

  testWidgets('Link · HTTP on: the Trusted networks row lists the trusted networks, Forget drops one', (tester) async {
    final store = _store({
      'app.payment_prefs': const PaymentPrefs(linkHttp: true).encode(),
      trustedNetworksKey: '10.0.0,192.168.1',
    });
    await _pump(tester, store, phone: true, lanAddress: '10.100.10.20');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.text('Trusted networks · 2 trusted'), findsOneWidget);
    await tester.tap(_row('tx-trusted-networks'));
    await tester.pumpAndSettle();
    // Newest first, the one in use tagged.
    expect(find.text('192.168.1.x'), findsOneWidget);
    expect(find.text('10.0.0.x'), findsOneWidget);
    expect(find.text('This network'), findsOneWidget);

    await tester.tap(_row('tx-forget-network-10.0.0'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.text('10.0.0.x'), findsNothing);
    expect(store.values[trustedNetworksKey], '192.168.1');
    expect(find.text('Trusted networks · 1 trusted'), findsOneWidget);

    // The last one: the sheet says none is trusted.
    await tester.tap(_row('tx-forget-network-192.168.1'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.textContaining('No trusted network yet'), findsOneWidget);
    expect(find.text('Trusted networks · None yet'), findsOneWidget);
  });

  testWidgets('Link · HTTP off: no Trusted networks row', (tester) async {
    await _pump(tester, _store({trustedNetworksKey: '192.168.1'}), phone: true);
    expect(_row('tx-trusted-networks'), findsNothing);
  });

  testWidgets('Link · Tor on with Tor off: the line under it opens Privacy & network', (tester) async {
    final c = await _pump(tester, _store());
    await tester.tap(_switchOf('tx-tor'));
    await tester.pumpAndSettle();
    expect(_payments(c).linkTor, isTrue);
    expect(find.byKey(txTorNeededKey), findsOneWidget);
    expect(find.text(_l.txLinkTorNeedsTor), findsOneWidget);
    await tester.tap(find.byKey(txTorNeededKey));
    await tester.pumpAndSettle();
    // Settings opens over the page, at Privacy & network (the hub stays under it).
    expect(find.byType(SettingsScreen, skipOffstage: false), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is SettingsSectionScreen && w.section == SettingsSection.privacyNetwork), findsOneWidget);
  }, skip: !torBuilt);

  testWidgets('Link · Tor on with Tor on: no line', (tester) async {
    await _pump(tester, _store({'app.payment_prefs': 'v2,tor,file|epicbox'}), tor: _torOn);
    expect(tester.widget<Switch>(_switchOf('tx-tor')).value, isTrue);
    expect(find.byKey(txTorNeededKey), findsNothing);
  }, skip: !torBuilt);

  testWidgets('the last method on stays on: the switch holds and a notice says why', (tester) async {
    addTearDown(() => NetGate.setEpicbox(true));
    // Epicbox alone (File Transfer and QR Payment off).
    final store = _store({'app.payment_prefs': 'v2,noqr|epicbox'});
    final c = await _pump(tester, store);
    await tester.tap(_switchOf('tx-epicbox'));
    await tester.pumpAndSettle();
    expect(_payments(c).epicbox, isTrue);
    expect(tester.widget<Switch>(_switchOf('tx-epicbox')).value, isTrue);
    expect(c.read(noticeProvider)?.text, _l.txLastMethodNotice);
    expect(c.read(noticeProvider)?.level, NoticeLevel.warning);
    expect(store.values['app.payment_prefs'], 'v2,noqr|epicbox');
    c.read(noticeProvider.notifier).clear();
    // Another one on: now Epicbox can go, and that one is the last.
    await tester.tap(_switchOf('tx-http'));
    await tester.pumpAndSettle();
    await tester.tap(_switchOf('tx-epicbox'));
    await tester.pumpAndSettle();
    expect(_payments(c).epicbox, isFalse);
    expect(c.read(noticeProvider), isNull);
    await tester.tap(_switchOf('tx-http'));
    await tester.pumpAndSettle();
    expect(_payments(c).linkHttp, isTrue);
    expect(c.read(noticeProvider)?.text, _l.txLastMethodNotice);
    c.read(noticeProvider.notifier).clear();
    await tester.pumpAndSettle();
  });

  testWidgets('each method has an info sheet in plain words', (tester) async {
    await _pump(tester, _store());
    // The sheet carries the full name (no family header around it).
    for (final (title, text) in [
      (_l.methodEpicbox, _l.txEpicboxHint),
      (_l.methodDirectHttp, _l.txLinkHttpHint('${appConfig.httpListenPort}')),
      (_l.methodDirectTor, _l.txLinkTorHint),
      (_l.methodDirectFile, _l.txFileHint),
    ]) {
      await tester.tap(
        find.byWidgetPredicate((w) => w is InfoHint && w.title == title),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(InfoSheet), matching: find.text(text)),
        findsOneWidget,
        reason: title,
      );
      await tester.tap(find.widgetWithText(TextButton, _l.commonClose));
      await tester.pumpAndSettle();
    }
  }, skip: !torBuilt);

  testWidgets('the Epicbox switch saves, reaches the gate, and comes back on', (tester) async {
    addTearDown(() => NetGate.setEpicbox(true));
    final store = _store();
    final c = await _pump(tester, store);
    await tester.tap(_switchOf('tx-epicbox'));
    await tester.pumpAndSettle();
    expect(_payments(c).epicbox, isFalse);
    expect(store.values['app.payment_prefs'], 'v2,file,noqr,noepicbox|epicbox');
    expect(NetGate.epicbox, isFalse);
    // Nothing waited for a reply: no confirm.
    expect(find.text(_l.txEpicboxOffTitle), findsNothing);
    // Send starts on: Epicbox is not offered while it is off.
    expect(find.byKey(const ValueKey('tx-start-epicbox')), findsNothing);
    await tester.tap(_switchOf('tx-epicbox'));
    await tester.pumpAndSettle();
    expect(_payments(c).epicbox, isTrue);
    expect(NetGate.epicbox, isTrue);
  });

  testWidgets('Epicbox off while a send waits for its reply over Epicbox asks first', (tester) async {
    addTearDown(() => NetGate.setEpicbox(true));
    final store = _store();
    final c = await _pump(tester, store, transactions: [_waitingEpicboxSend]);
    await tester.tap(_switchOf('tx-epicbox'));
    await tester.pumpAndSettle();
    expect(find.text(_l.txEpicboxOffTitle), findsOneWidget);
    expect(find.text(_l.txEpicboxOffPending(1)), findsOneWidget);
    await tester.tap(find.text(_l.commonCancel));
    await tester.pumpAndSettle();
    expect(_payments(c).epicbox, isTrue, reason: 'Cancel keeps it on');
    await tester.tap(_switchOf('tx-epicbox'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.txEpicboxOffAction));
    await tester.pumpAndSettle();
    expect(_payments(c).epicbox, isFalse);
  });

  testWidgets('the switches save', (tester) async {
    final store = _store();
    final c = await _pump(tester, store);
    await tester.tap(_switchOf('tx-http'));
    await tester.pumpAndSettle();
    expect(_payments(c), const PaymentPrefs(linkHttp: true, directQr: false));
    expect(store.values['app.payment_prefs'], 'v2,http,file,noqr|epicbox');
    await tester.tap(_switchOf('tx-tor'));
    await tester.pumpAndSettle();
    expect(_payments(c), const PaymentPrefs(linkHttp: true, linkTor: true, directQr: false));
    expect(store.values['app.payment_prefs'], 'v2,http,tor,file,noqr|epicbox');
    await tester.tap(_switchOf('tx-file'));
    await tester.pumpAndSettle();
    expect(_payments(c), const PaymentPrefs(linkHttp: true, linkTor: true, directFile: false, directQr: false));
    expect(tester.widget<Switch>(_switchOf('tx-file')).value, isFalse);
  }, skip: !torBuilt);

  testWidgets('Send starts on: only the methods offered, and a saved choice', (tester) async {
    final c = await _pump(tester, _store());
    // Epicbox and File Transfer (the default set), by their full names.
    expect(_row('tx-start-epicbox'), findsOneWidget);
    expect(_row('tx-start-file'), findsOneWidget);
    expect(_row('tx-start-link'), findsNothing);
    expect(find.descendant(of: _row('tx-start-file'), matching: find.text(_l.methodDirectFile)), findsOneWidget);
    await tester.tap(_row('tx-start-file'));
    await tester.pumpAndSettle();
    expect(_payments(c).defaultMethod, MethodKind.directFile);
    // Link · HTTP on adds Link, once, named for the family.
    await tester.tap(_switchOf('tx-http'));
    await tester.pumpAndSettle();
    expect(_row('tx-start-link'), findsOneWidget);
    expect(find.descendant(of: _row('tx-start-link'), matching: find.text(_l.methodDirect)), findsOneWidget);
    await tester.tap(_row('tx-start-link'));
    await tester.pumpAndSettle();
    expect(_payments(c).defaultMethod, MethodKind.linkHttp);
    expect(_payments(c).startMethod, MethodKind.linkHttp);
    // Link · Tor on too: still one Link choice, still chosen.
    await tester.tap(_switchOf('tx-tor'));
    await tester.pumpAndSettle();
    expect(_row('tx-start-link'), findsOneWidget);
    expect(tester.widget<RadioGroup<MethodKind>>(find.byType(RadioGroup<MethodKind>)).groupValue, MethodKind.linkHttp);
    // HTTP off: Link stays chosen through Tor.
    await tester.tap(_switchOf('tx-http'));
    await tester.pumpAndSettle();
    expect(_payments(c).startMethod, MethodKind.linkTor);
    expect(tester.widget<RadioGroup<MethodKind>>(find.byType(RadioGroup<MethodKind>)).groupValue, MethodKind.linkTor);
    // Both off: the choice is no longer offered and Send starts on Epicbox.
    await tester.tap(_switchOf('tx-tor'));
    await tester.pumpAndSettle();
    expect(_row('tx-start-link'), findsNothing);
    expect(_payments(c).startMethod, MethodKind.epicbox);
  }, skip: !torBuilt);

  testWidgets('with Epicbox alone there is nothing to choose', (tester) async {
    await _pump(tester, _store({'app.payment_prefs': 'v2,noqr|epicbox'}));
    expect(find.text(_l.txStartHeader), findsNothing);
    expect(_row('tx-start-epicbox'), findsNothing);
  });

  testWidgets('Send defaults: nothing about them without Send options', (tester) async {
    await _pump(tester, _store());
    expect(find.text(_l.txDefaultsHeader), findsNothing);
    expect(find.text(_l.outputsStrategy), findsNothing);
    expect(find.text(_l.outputsSplitChange), findsNothing);
  });

  testWidgets('Send defaults: with Send options, Strategy and Split change save', (tester) async {
    final store = _store({'app.advanced_prefs': _sendOptions.encode()});
    final c = await _pump(tester, store);
    expect(find.text(_l.txDefaultsHeader), findsOneWidget);
    expect(find.descendant(of: _row('tx-strategy'), matching: find.text(_l.outputsSmallest)), findsOneWidget);
    await tester.tap(_row('tx-strategy'));
    await tester.pumpAndSettle();
    await tester.tap(_row('tx-strategy-all'));
    await tester.pumpAndSettle();
    expect(c.read(appSettingsProvider).value?.sendStrategy, SelectionStrategy.all);
    expect(store.values['app.send_strategy'], 'all');
    expect(tester.widget<Switch>(_switchOf('tx-split')).value, isTrue);
    await tester.tap(_row('tx-split'));
    await tester.pumpAndSettle();
    expect(c.read(appSettingsProvider).value?.splitChange, isFalse);
  });

  testWidgets('Send defaults stay while one is not at its default (never hide a choice in use)', (
    tester,
  ) async {
    await _pump(tester, _store({'app.send_strategy': 'all'}));
    expect(find.text(_l.txDefaultsHeader), findsOneWidget);
  });

  testWidgets('a setting never disappears because it was changed: back at the defaults, both rows stay', (
    tester,
  ) async {
    // Send options off: the defaults show only because they are changed.
    final store = _store({'app.send_strategy': 'all', 'app.split_change': 'false'});
    final c = await _pump(tester, store);
    expect(tester.widget<Switch>(_switchOf('tx-split')).value, isFalse);
    await tester.tap(_row('tx-split'));
    await tester.pumpAndSettle();
    expect(c.read(appSettingsProvider).value?.splitChange, isTrue);
    expect(_row('tx-split'), findsOneWidget, reason: 'the row stays, with its new value');
    expect(tester.widget<Switch>(_switchOf('tx-split')).value, isTrue);
    await tester.tap(_row('tx-strategy'));
    await tester.pumpAndSettle();
    await tester.tap(_row('tx-strategy-smallest'));
    await tester.pumpAndSettle();
    expect(c.read(appSettingsProvider).value?.sendStrategy, SelectionStrategy.smallest);
    expect(find.descendant(of: _row('tx-strategy'), matching: find.text(_l.outputsSmallest)), findsOneWidget);
    expect(_row('tx-split'), findsOneWidget);
    // Every switch on the page toggles in place.
    for (final key in ['tx-http', 'tx-tor', 'tx-file', 'tx-split']) {
      await tester.tap(_row(key));
      await tester.pumpAndSettle();
      expect(_row(key), findsOneWidget, reason: key);
    }
  }, skip: !torBuilt);

  testWidgets('every Advanced switch stays in place when toggled', (tester) async {
    await _pump(tester, _store(), section: SettingsSection.advanced);
    for (final f in AdvancedFeature.values) {
      final row = _row('adv-${f.name}');
      if (row.evaluate().isEmpty) continue;
      final before = tester.widget<Switch>(find.descendant(of: row, matching: find.byType(Switch))).value;
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      expect(row, findsOneWidget, reason: f.name);
      expect(tester.widget<Switch>(find.descendant(of: row, matching: find.byType(Switch))).value, !before, reason: f.name);
    }
  });

  testWidgets('Advanced no longer holds a Link switch', (tester) async {
    await _pump(tester, _store(), section: SettingsSection.advanced);
    expect(find.byKey(const ValueKey('adv-sendOptions')), findsOneWidget);
    expect(find.byKey(const ValueKey('adv-directReceiving')), findsNothing);
    expect(find.text('Link receiving'), findsNothing);
  });

  testWidgets('the old Link receiving switch is taken over as Link · Tor on', (tester) async {
    final store = _store({'app.advanced_prefs': 'directReceiving|standard'});
    final c = await _pump(tester, store, phone: true);
    expect(_payments(c).linkTor, isTrue);
    expect(tester.widget<Switch>(_switchOf('tx-tor')).value, isTrue);
  }, skip: !torBuilt);

  group('on a phone: QR for everyone, File behind Advanced', () {
    const files = AdvancedPrefs(features: {AdvancedFeature.transactionFiles});

    testWidgets('a new phone: QR is on, there is no File row', (tester) async {
      await _pump(tester, _store(), phone: true);
      expect(_methodRows(tester), [
        'tx-epicbox',
        'tx-family-link',
        'tx-http',
        'tx-tor',
        'tx-family-direct',
        'tx-qr',
      ]);
      expect(_titleOf(tester, 'tx-qr'), 'QR Payment');
      expect(tester.widget<Switch>(_switchOf('tx-qr')).value, isTrue);
      expect(_row('tx-file'), findsNothing);
      expect(_row('tx-start-qr'), findsOneWidget);
      expect(_row('tx-start-file'), findsNothing);
    }, skip: !torBuilt);

    testWidgets('Advanced › Transaction files brings the File switch, off', (tester) async {
      final store = _store({'app.advanced_prefs': files.encode()});
      final c = await _pump(tester, store, phone: true);
      expect(tester.widget<Switch>(_switchOf('tx-file')).value, isFalse);
      await tester.tap(_switchOf('tx-file'));
      await tester.pumpAndSettle();
      expect(_payments(c).directFile, isTrue);
      expect(_row('tx-start-file'), findsOneWidget);
    });

    testWidgets('a phone that has File on keeps the row, so it can switch it off', (
      tester,
    ) async {
      final c = await _pump(
        tester,
        _store({'app.payment_prefs': 'v2,file|epicbox'}),
        phone: true,
      );
      expect(tester.widget<Switch>(_switchOf('tx-file')).value, isTrue);
      await tester.tap(_switchOf('tx-file'));
      await tester.pumpAndSettle();
      expect(_payments(c).directFile, isFalse);
      // It stays on the page, so a changed setting does not vanish under the finger.
      expect(_row('tx-file'), findsOneWidget);
    });

    testWidgets('the QR switch saves, and Send starts on QR when chosen', (tester) async {
      final store = _store();
      final c = await _pump(tester, store, phone: true);
      await tester.tap(_row('tx-start-qr'));
      await tester.pumpAndSettle();
      expect(_payments(c).startMethod, MethodKind.directQr);
      await tester.tap(_switchOf('tx-qr'));
      await tester.pumpAndSettle();
      expect(_payments(c).directQr, isFalse);
      expect(store.values['app.payment_prefs'], contains('noqr'));
      // Off: it is no longer a choice and Send starts on Epicbox.
      expect(_row('tx-start-qr'), findsNothing);
      expect(_payments(c).startMethod, MethodKind.epicbox);
    });

    testWidgets('the QR switch has an info sheet', (tester) async {
      await _pump(tester, _store(), phone: true);
      await tester.tap(
        find.byWidgetPredicate((w) => w is InfoHint && w.title == _l.methodDirectQr),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(InfoSheet), matching: find.text(_l.txQrHint)),
        findsOneWidget,
      );
    });

    testWidgets('the Advanced page has the Transaction files switch', (tester) async {
      final c = await _pump(
        tester,
        _store(),
        section: SettingsSection.advanced,
        phone: true,
      );
      expect(_row('adv-transactionFiles'), findsOneWidget);
      await tester.tap(_row('adv-transactionFiles'));
      await tester.pumpAndSettle();
      expect(
        c.read(appSettingsProvider).value!.advanced.has(AdvancedFeature.transactionFiles),
        isTrue,
      );
    });
  });
}
