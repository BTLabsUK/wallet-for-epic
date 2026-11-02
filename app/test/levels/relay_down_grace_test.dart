// SPDX-License-Identifier: Apache-2.0
// Item 11: the Epicbox switch offer waits for the connection grace after start and resume,
// shows only while the shell is the screen on top, and is compact (a title, one line, Switch,
// and the close button for Not now).
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/connection_grace.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/levels/level_features.dart';
import 'package:epic_wallet/src/levels/level_providers.dart';
import 'package:epic_wallet/src/levels/relay_switch.dart';
import 'package:epic_wallet/src/levels/relay_switch_providers.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/network.dart' show EpicboxRelay;
import 'package:epic_wallet/src/ui/common.dart' show SlotScaffold;
import 'package:epic_wallet/src/ui/levels/relay_down.dart';
import 'package:epic_wallet/src/ui/notices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

const _to = 'epicbox.example.net';

class _Offer extends RelaySwitchNotifier {
  @override
  RelaySwitchOffer? build() => null;

  void show() => state = RelaySwitchOffer(
    from: EpicboxRelay(host: 'epicbox.example.org'),
    to: EpicboxRelay(host: _to),
    name: _to,
  );

  int waited = 0;

  @override
  void keepWaiting() {
    waited++;
    state = null;
  }
}

Future<ProviderContainer> _pump(WidgetTester tester, {required bool grace}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        relaySwitchProvider.overrideWith(_Offer.new),
        connectionGraceLengthProvider.overrideWithValue(grace ? const Duration(seconds: 20) : Duration.zero),
        levelFeaturesProvider.overrideWithValue(
          LevelFeatures.of(WalletLevel.justSendReceive, AdvancedPrefs.none, torBuilt: true),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SlotScaffold(
          appBar: AppBar(actions: const [RelayDownNotices()]),
          body: const SizedBox.expand(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(RelayDownNotices)));
}

Finder get _title => find.text(_l.lvShellRelayDownTitle);

void main() {
  testWidgets('no offer during the grace; it shows once the grace is over', (tester) async {
    final c = await _pump(tester, grace: true);
    (c.read(relaySwitchProvider.notifier) as _Offer).show();
    await tester.pumpAndSettle();
    expect(_title, findsNothing);
    expect(c.read(noticeProvider), isNull);
    expect(c.read(connectionGraceProvider), isTrue);
    c.read(connectionGraceProvider.notifier).end();
    await tester.pumpAndSettle();
    expect(_title, findsOneWidget);
  });

  testWidgets('compact: title, one line, Switch, no Not now; close waits', (tester) async {
    final c = await _pump(tester, grace: false);
    final offer = c.read(relaySwitchProvider.notifier) as _Offer;
    offer.show();
    await tester.pumpAndSettle();
    expect(_title, findsOneWidget);
    expect(find.text(_l.lvShellRelayDownShort(_to)), findsOneWidget);
    expect(find.widgetWithText(TextButton, _l.lvShellSwitch), findsOneWidget);
    expect(find.text(_l.pairNotNow), findsNothing);
    await tester.tap(find.byTooltip(_l.commonClose));
    await tester.pumpAndSettle();
    expect(offer.waited, 1);
  });

  testWidgets('not over another screen: a screen pushed over the shell takes it away', (tester) async {
    final c = await _pump(tester, grace: false);
    (c.read(relaySwitchProvider.notifier) as _Offer).show();
    await tester.pumpAndSettle();
    expect(c.read(noticeProvider)?.tag, relayOfferNoticeTag);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(MaterialPageRoute<void>(builder: (_) => const SlotScaffold(body: Text('details'))));
    await tester.pumpAndSettle();
    expect(find.text('details'), findsOneWidget);
    expect(c.read(noticeProvider), isNull);
    expect(_title, findsNothing);
    // Back on the shell: the offer, still standing, shows again.
    nav.pop();
    await tester.pumpAndSettle();
    expect(_title, findsOneWidget);
  });
}
