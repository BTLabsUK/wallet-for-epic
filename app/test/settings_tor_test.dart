// SPDX-License-Identifier: Apache-2.0
// Settings › Privacy & network: the one Tor switch, bound to the phone's Tor controller, with one line
// saying what it covers ("Not connected" and Retry when Tor failed); not under Advanced,
// and absent where the app has no Tor.

import 'dart:async';

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/info_hint.dart';
import 'package:epic_wallet/src/ui/network_mode_phone.dart' show networkModeRowKey;
import 'package:epic_wallet/src/ui/tor_ui.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const TorBundle _bundle = TorBundle(binary: '/data/app/lib/arm64/libtor.so');

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Harness {
  _Harness({this.bundle = _bundle, this.advanced = AdvancedPrefs.none});

  final TorBundle? bundle;

  /// What the Advanced page holds: the network mode locks the Tor switch.
  final AdvancedPrefs advanced;
  final session = FakeWalletSession();
  final store = MemorySecretStore();
  final network = StreamController<bool>.broadcast();
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester, {
    bool privacy = false,
    SettingsSection? section,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(FakeWalletService()),
          secretStoreProvider.overrideWithValue(store),
          sessionProvider.overrideWith(() => _OpenSession(session)),
          updatePlatformProvider.overrideWithValue(null),
          torBundleFinderProvider.overrideWithValue(() async => bundle),
          networkChangesProvider.overrideWithValue(network.stream),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              AdvancedOptions(prefs: advanced, child: child!),
          home: SettingsScreen(privacy: privacy, section: section),
        ),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    await tester.pumpAndSettle();
    // The controller reads the bundle and the onion on real async: wait for it.
    for (var i = 0; i < 50; i++) {
      final s = container.read(phoneTorProvider);
      if (s.onion != null || s.phase == PhoneTorPhase.unavailable) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
    }
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await network.close();
    });
  }

  /// Tor's next event, with what `torStatus` answers afterwards.
  Future<void> emit(
    WidgetTester tester,
    TorEventKind kind, {
    TorFailure? failure,
  }) async {
    session.torStatusValue = switch (kind) {
      TorEventKind.ready => TorStatus(
        kind: TorStatusKind.ready,
        onion: session.onion,
      ),
      _ => TorStatus.off,
    };
    session.torEvents.add(
      TorEvent(
        kind: kind,
        failure: failure,
        onion: kind == TorEventKind.ready ? session.onion : null,
      ),
    );
    await tester.pumpAndSettle();
  }
}

/// Scrolls Settings until [finder] is built and in view.
Future<void> _reach(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  // Tor's own behaviour: nothing of it is in the build without Tor.
  if (!torBuilt) {
    test('Tor', () {}, skip: 'no Tor in this build');
    return;
  }
  group('network modes', () {
    Switch torSwitch(WidgetTester tester) => tester.widget<Switch>(
      find.descendant(
        of: find.byKey(torReceivingSwitchKey),
        matching: find.byType(Switch),
      ),
    );

    testWidgets('Standard: the switch is the user\'s, with no mode line', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, privacy: true);
      await _reach(tester, find.byKey(torReceivingSwitchKey));
      expect(torSwitch(tester).onChanged, isNotNull);
      expect(torSwitch(tester).value, isFalse);
      expect(find.byKey(torLockedLineKey), findsNothing);
    });

    testWidgets('Tor only: the switch shows on, disabled and faded, its line names the mode on the same page', (
      tester,
    ) async {
      final h = _Harness(
        advanced: const AdvancedPrefs(networkMode: NetworkMode.torOnly),
      );
      await h.pump(tester, privacy: true);
      await _reach(tester, find.byKey(torReceivingSwitchKey));
      expect(torSwitch(tester).value, isTrue, reason: 'shown on although Tor is off');
      expect(torSwitch(tester).onChanged, isNull, reason: 'locked');
      // The bug: the theme painted a disabled switch as a live one. Disabled now fades.
      for (final tokens in [protocolDark, protocolLight]) {
        final theme = buildWalletTheme(tokens, tokens == protocolDark ? Brightness.dark : Brightness.light).switchTheme;
        const live = {WidgetState.selected};
        const off = {WidgetState.selected, WidgetState.disabled};
        expect(theme.trackColor!.resolve(off), theme.trackColor!.resolve(live)!.withValues(alpha: 0.4));
        expect(theme.thumbColor!.resolve(off), theme.thumbColor!.resolve(live)!.withValues(alpha: 0.4));
      }
      expect(find.byKey(torLockedLineKey), findsOneWidget);
      expect(find.text('On in Tor only.'), findsOneWidget);
      // The mode is right above (B-03): no link to another page.
      expect(find.byKey(torUndercoverChangeKey), findsNothing);
      expect(find.byKey(networkModeRowKey(NetworkMode.torOnly)), findsOneWidget);
      await tester.tap(find.byKey(torReceivingSwitchKey));
      await tester.pumpAndSettle();
      expect(h.container.read(phoneTorProvider).receiving, isFalse);
      expect(h.session.torStarts, isEmpty);
    });

    testWidgets('Kill switch: the switch is off and disabled, with its line', (
      tester,
    ) async {
      final h = _Harness(
        advanced: const AdvancedPrefs(networkMode: NetworkMode.killSwitch),
      );
      await h.pump(tester, privacy: true);
      await _reach(tester, find.byKey(torReceivingSwitchKey));
      expect(torSwitch(tester).value, isFalse);
      expect(torSwitch(tester).onChanged, isNull);
      expect(find.text('Off in Kill switch: nothing connects.'), findsOneWidget);
      await tester.tap(find.byKey(torReceivingSwitchKey));
      await tester.pumpAndSettle();
      expect(h.session.torStarts, isEmpty);
    });
  });

  testWidgets('Privacy: one Tor switch, what it covers, no Advanced needed', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester, privacy: true);
    final privacy = find.byKey(settingsPrivacyKey);
    expect(privacy, findsOneWidget);
    // Network & privacy: the switch sits under its own Tor header.
    expect(find.descendant(of: privacy, matching: find.text('Tor')), findsOneWidget);
    expect(find.text('Receiving'), findsNothing);
    expect(find.text('Tor receiving'), findsNothing);
    // The switch is the first row under Tor.
    await _reach(tester, privacy);
    expect(
      tester.getTopLeft(find.byKey(torReceivingSwitchKey)).dy,
      greaterThan(tester.getTopLeft(privacy).dy),
    );
    await tester.ensureVisible(find.byKey(torReceivingSwitchKey));
    await tester.pumpAndSettle();
    // The label only; the explanation is the info icon's tooltip, and no line in the row
    // says what goes over Tor or what does not.
    expect(
      find.descendant(
        of: find.byKey(torReceivingSwitchKey),
        matching: find.text('Tor network'),
      ),
      findsOneWidget,
    );
    // The info icon opens the Tor Network sheet: the icon, the title, the explanation.
    final hint = find.descendant(
      of: find.byKey(torReceivingSwitchKey),
      matching: find.byType(InfoHint),
    );
    expect(hint, findsOneWidget);
    expect(find.textContaining('go through Tor'), findsNothing);
    expect(find.textContaining('Not over Tor'), findsNothing);
    expect(find.byKey(torStatusKey), findsNothing, reason: 'off: no state line');
    await tester.tap(hint);
    await tester.pumpAndSettle();
    expect(find.byType(InfoSheet), findsOneWidget);
    expect(
      find.descendant(of: find.byType(InfoSheet), matching: find.text('Tor network')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Network activity goes through the Tor network.'),
      findsOneWidget,
    );
    expect(find.textContaining('Notifications'), findsNothing);
    expect(find.textContaining('Not over Tor'), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(InfoSheet), findsNothing);

    for (final word in ['Listener', 'listener', 'Advanced Tor']) {
      expect(find.textContaining(word), findsNothing);
    }

    await tester.tap(find.byKey(torReceivingSwitchKey));
    await tester.pumpAndSettle();
    // No confirmation: it just turns on.
    expect(find.byType(AlertDialog), findsNothing);
    expect(h.session.torStarts, hasLength(1));
    expect(h.container.read(phoneTorProvider).receiving, isTrue);
    // Starting: the state word alone, under the label.
    expect(
      find.descendant(
        of: find.byKey(torStatusKey),
        matching: find.text('Starting'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('go through Tor'), findsNothing);
    expect(
      tester
          .widget<Switch>(
            find.descendant(
              of: find.byKey(torReceivingSwitchKey),
              matching: find.byType(Switch),
            ),
          )
          .value,
      isTrue,
    );
    // The choice is saved for this wallet.
    final config = h.container.read(walletConfigProvider);
    if (config != null) {
      expect(h.store.values[PhoneTor.receivingKey(config)], 'true');
    }
  });

  testWidgets('Tor not connected: the line says so, with Retry', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester, privacy: true);
    await h.container.read(phoneTorProvider.notifier).setReceiving(true);
    await tester.pumpAndSettle();
    await h.emit(tester, TorEventKind.failed, failure: TorFailure.network);
    await h.emit(tester, TorEventKind.stopped);
    await tester.ensureVisible(find.byKey(torReceivingSwitchKey));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(torStatusKey),
        matching: find.text('Not connected'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(torRetryKey), findsOneWidget);
    await tester.tap(find.byKey(torRetryKey));
    await tester.pumpAndSettle();
    expect(h.session.torStarts, hasLength(2));
  });

  testWidgets('opened for privacy, the Tor switch is in view', (tester) async {
    final h = _Harness();
    await h.pump(tester, privacy: true);
    final view = tester.getRect(find.byType(ListView));
    final row = tester.getRect(find.byKey(torReceivingSwitchKey));
    expect(row.top, greaterThanOrEqualTo(view.top));
    expect(row.bottom, lessThanOrEqualTo(view.bottom));
    expect(h.container.read(phoneTorProvider).receiving, isFalse);
  });

  testWidgets('no Tor switch where the app has no Tor', (tester) async {
    final h = _Harness(bundle: null);
    await h.pump(tester, privacy: true);
    expect(find.byKey(torReceivingSwitchKey), findsNothing);
  });

  testWidgets('the switch left on without a tor bundle stays in view and can go off', (tester) async {
    final h = _Harness(bundle: null);
    await h.pump(tester, privacy: true);
    // Saved on before the bundle went missing: the wallet waits for tor, blocked.
    await h.container.read(phoneTorProvider.notifier).setReceiving(true);
    await tester.pumpAndSettle();
    await _reach(tester, find.byKey(torReceivingSwitchKey));
    final tile = tester.widget<Switch>(
      find.descendant(of: find.byKey(torReceivingSwitchKey), matching: find.byType(Switch)),
    );
    expect(tile.value, isTrue);
    expect(tile.onChanged, isNotNull, reason: 'off ends the blocked wait');
    await tester.tap(find.byKey(torReceivingSwitchKey));
    await tester.pumpAndSettle();
    expect(h.container.read(phoneTorProvider).receiving, isFalse);
    expect(find.byKey(torReceivingSwitchKey), findsNothing);
  });
}
