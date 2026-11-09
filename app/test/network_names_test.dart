// SPDX-License-Identifier: Apache-2.0
// Network names on screen: the development builds name a network in plain words, and no
// screen, file name or translation says mainnet, floonet or usernet.
import 'package:epic_wallet/src/desktop/screens/onboarding/onboarding_parts.dart' show networkName;
import 'package:epic_wallet/src/desktop/screens/settings/backup.dart' show deskHistoryFileName, deskPaymentsFileName;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/ui/settings_history.dart' show historyFileName, paymentsFileName;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _protocol = RegExp('mainnet|floo|usernet', caseSensitive: false);

void main() {
  final day = DateTime(2026, 11, 9);

  test('every chain has a plain name, on phone and desktop alike', () {
    final l = lookupAppLocalizations(const Locale('en'));
    for (final chain in Chain.values) {
      final shown = [chainName(l, chain), networkSuffix(l, chain), networkName(chain.name)];
      for (final s in shown) {
        expect(s, isNot(contains(_protocol)), reason: '$chain: $s');
      }
    }
    expect(chainName(l, Chain.floonet), 'Test network');
    expect(networkSuffix(l, Chain.floonet), ' (Test network)');
    expect(networkSuffix(l, Chain.mainnet), isEmpty);
    expect(networkName('floonet'), chainName(l, Chain.floonet));
  });

  test('offered file names say test, not the protocol name', () {
    for (final chain in Chain.values) {
      final names = [
        historyFileName(chain, day, 'wfeh'),
        paymentsFileName(chain, day),
        deskHistoryFileName(chain.name, day, 'wfeh'),
        deskPaymentsFileName(chain.name, day),
      ];
      for (final n in names) {
        expect(n, isNot(contains(_protocol)), reason: n);
      }
    }
    expect(historyFileName(Chain.floonet, day, 'wfeh'), 'epic-wallet-data-test-20261109.wfeh');
    expect(deskPaymentsFileName('mainnet', day), 'epic-payments-20261109.csv');
  });

  test('the link refusal names the network in plain words, in every language', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = lookupAppLocalizations(locale);
      for (final s in [l.linkMadeForMainnet, l.linkMadeForFloonet]) {
        expect(s, isNot(contains(_protocol)), reason: '$locale: $s');
      }
    }
  });
}
