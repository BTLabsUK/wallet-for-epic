// SPDX-License-Identifier: Apache-2.0
// The build without Tor (`--dart-define=WFE_TOR=false`) on the desktop: no Tor only mode, no Tor
// chip, an onion in To says this version cannot send there, updates from update.json's notor
// section. Skipped in the default build.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/desk_update.dart';
import 'package:epic_wallet/src/desktop/data/http_address.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/dist_build.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/updater.dart' show updateManifestSources;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _onion = 'pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd.onion';
const _noTor = 'This version cannot send to Tor addresses.';

late ProviderContainer _container;

Future<void> _open(WidgetTester tester, DeskRoute route, {Object? arg}) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final wallet = MockDeskWallet(delay: Duration.zero);
  _container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)], retry: (_, _) => null);
  addTearDown(_container.dispose);
  await tester.runAsync(() async {
    final n = _container.read(deskProvider.notifier);
    await n.refresh();
    await n.saveSettings(_container.read(deskProvider).settings.copyWith(tourSeen: true));
  });
  _container.read(deskNavProvider.notifier).reset(route, arg);
  await tester.pumpWidget(UncontrolledProviderScope(container: _container, child: const DeskApp()));
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  final skip = torBuilt ? 'the build with Tor' : null;

  test('the flags', () {
    expect(DeskFeatures.tor, isFalse);
    expect(inAppUpdates, distUpdates);
  }, skip: skip);

  test('an onion as a Link address: this version cannot send there', () {
    expect(httpAddressProblem('http://$_onion', englishStrings), _noTor);
  }, skip: skip);

  testWidgets('Network & privacy lists Standard and Offline, no Tor only', (tester) async {
    await _open(tester, DeskRoute.settingsPrivacy);
    expect(find.byKey(const ValueKey('adv-mode-standard')), findsOneWidget);
    expect(find.byKey(const ValueKey('adv-mode-offline')), findsOneWidget);
    expect(find.byKey(const ValueKey('adv-mode-torOnly')), findsNothing);
    expect(find.text('Tor only'), findsNothing);
  }, skip: skip != null);

  testWidgets('Send: an onion in To says so, with no Tor chip and no Turn on Tor', (tester) async {
    await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: _onion, amount: '1'));
    expect(find.byKey(const ValueKey('tor-chip')), findsNothing);
    // Said at once, under To and under Review send; no method-off notice to turn something on.
    expect(find.text(_noTor), findsNWidgets(2));
    expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
    expect(find.byKey(const ValueKey('send-needs-tor')), findsNothing);
    expect(find.text('Turn on Tor'), findsNothing);
  }, skip: skip != null);

  test('the updater reads update.json like the build with Tor', () async {
    final asked = <Uri>[];
    final c = ProviderContainer(overrides: [
      deskManifestFetchProvider.overrideWithValue((url) async {
        asked.add(url);
        return (404, '');
      }),
    ]);
    addTearDown(c.dispose);
    await c.read(deskUpdateProvider.notifier).check();
    expect(asked.map((u) => '$u'), unorderedEquals(updateManifestSources));
    expect(c.read(deskUpdateProvider).offered, isFalse);
  }, skip: skip ?? (inAppUpdates ? null : 'no in-app updates in this build'));
}
