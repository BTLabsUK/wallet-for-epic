// Settings › Transactions on the phone: the payment methods (Epicbox always on, Direct and File
// as switches), the method Send starts on (only among the methods offered), and, with Advanced
// › Send options, the send defaults that used to sit on Outputs. The Advanced page no longer
// holds a Direct switch; an old one is taken over.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/backup_screen.dart' show backedUpProvider;
import 'package:epic_wallet/src/ui/info_hint.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

class _Tor extends PhoneTor {
  @override
  PhoneTorState build() => const PhoneTorState(
    phase: PhoneTorPhase.off,
    onion: 'abcdefghijklmnopqrstuvwxyz234567abcdefghijklmnopqrstuvwx',
  );
}

class _OpenSession extends SessionNotifier {
  @override
  WalletSession? build() => FakeWalletSession();
}

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
        updatePlatformProvider.overrideWithValue(null),
        relayDirectoryProvider.overrideWithValue(_NoRelays()),
        sessionProvider.overrideWith(_OpenSession.new),
        phoneTorProvider.overrideWith(_Tor.new),
        backedUpProvider.overrideWith((ref) async => true),
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

PaymentPrefs _payments(ProviderContainer c) =>
    c.read(appSettingsProvider).value!.payments;

void main() {
  testWidgets('methods: Epicbox is always on, Direct and File are switches', (tester) async {
    await _pump(tester, _store());
    expect(find.text(_l.txMethodsHeader), findsOneWidget);
    // Epicbox: a row with "Always on" and no switch.
    expect(find.descendant(of: _row('tx-epicbox'), matching: find.text(_l.txAlwaysOn)), findsOneWidget);
    expect(_switchOf('tx-epicbox'), findsNothing);
    // Direct is off by default, File on.
    expect(tester.widget<Switch>(_switchOf('tx-direct')).value, isFalse);
    expect(tester.widget<Switch>(_switchOf('tx-file')).value, isTrue);
    expect(find.text(_l.txDirectLine), findsOneWidget);
    expect(find.text(_l.txFileLine), findsOneWidget);
  });

  testWidgets('each method has an info sheet in plain words', (tester) async {
    await _pump(tester, _store());
    for (final (title, text) in [
      (_l.methodEpicbox, _l.txEpicboxHint),
      (_l.methodDirect, _l.txDirectHint),
      (_l.methodFile, _l.txFileHint),
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
  });

  testWidgets('the switches save', (tester) async {
    final store = _store();
    final c = await _pump(tester, store);
    await tester.tap(_row('tx-direct'));
    await tester.pumpAndSettle();
    expect(_payments(c), const PaymentPrefs(direct: true));
    expect(store.values['app.payment_prefs'], 'direct,file|epicbox');
    await tester.tap(_row('tx-file'));
    await tester.pumpAndSettle();
    expect(_payments(c), const PaymentPrefs(direct: true, file: false));
    expect(tester.widget<Switch>(_switchOf('tx-file')).value, isFalse);
  });

  testWidgets('Send starts on: only the methods offered, and a saved choice', (tester) async {
    final c = await _pump(tester, _store());
    // Epicbox and File (the default set).
    expect(_row('tx-start-epicbox'), findsOneWidget);
    expect(_row('tx-start-file'), findsOneWidget);
    expect(_row('tx-start-direct'), findsNothing);
    await tester.tap(_row('tx-start-file'));
    await tester.pumpAndSettle();
    expect(_payments(c).defaultMethod, PayMethod.file);
    // Direct on adds its choice.
    await tester.tap(_row('tx-direct'));
    await tester.pumpAndSettle();
    expect(_row('tx-start-direct'), findsOneWidget);
    await tester.tap(_row('tx-start-direct'));
    await tester.pumpAndSettle();
    expect(_payments(c).defaultMethod, PayMethod.direct);
    expect(_payments(c).startMethod, PayMethod.direct);
    // Direct off again: the choice is no longer offered and Send starts on Epicbox.
    await tester.tap(_row('tx-direct'));
    await tester.pumpAndSettle();
    expect(_row('tx-start-direct'), findsNothing);
    expect(_payments(c).startMethod, PayMethod.epicbox);
  });

  testWidgets('with Epicbox alone there is nothing to choose', (tester) async {
    await _pump(tester, _store({'app.payment_prefs': '|epicbox'}));
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
    for (final key in ['tx-direct', 'tx-file', 'tx-split']) {
      await tester.tap(_row(key));
      await tester.pumpAndSettle();
      expect(_row(key), findsOneWidget, reason: key);
    }
  });

  testWidgets('every Advanced switch stays in place when toggled', (tester) async {
    await _pump(tester, _store(), section: SettingsSection.advanced);
    for (final f in AdvancedFeature.values) {
      final row = _row('adv-${f.name}');
      if (row.evaluate().isEmpty) continue;
      final before = tester.widget<Switch>(find.descendant(of: row, matching: find.byType(Switch))).value;
      await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      expect(row, findsOneWidget, reason: f.name);
      expect(tester.widget<Switch>(find.descendant(of: row, matching: find.byType(Switch))).value, !before, reason: f.name);
    }
  });

  testWidgets('Advanced no longer holds a Direct switch', (tester) async {
    await _pump(tester, _store(), section: SettingsSection.advanced);
    expect(find.byKey(const ValueKey('adv-sendOptions')), findsOneWidget);
    expect(find.byKey(const ValueKey('adv-directReceiving')), findsNothing);
    expect(find.text('Direct receiving'), findsNothing);
  });

  testWidgets('the old Direct receiving switch is taken over as Direct on', (tester) async {
    final store = _store({'app.advanced_prefs': 'directReceiving|standard'});
    final c = await _pump(tester, store);
    expect(_payments(c).direct, isTrue);
    expect(tester.widget<Switch>(_switchOf('tx-direct')).value, isTrue);
  });
}
