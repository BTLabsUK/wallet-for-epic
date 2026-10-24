// The HTTP listener's failure is kept structured and worded at display time, so the sidebar and
// the status card read right in every language, not only in English.
import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:epic_wallet/src/desktop/app/rail.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

ServiceStatus _down(HttpProblem p) => ServiceStatus(
  node: const NodeServer(url: 'https://node.btlabs.uk', label: 'BT Labs'),
  nodeHealth: ServiceHealth.ok,
  nodeHeight: 2914414,
  epicbox: const EpicboxServer(domain: 'epicbox.stackwallet.com'),
  epicboxHealth: ServiceHealth.ok,
  httpListener: ServiceHealth.down,
  httpProblem: p,
  httpProblemPort: 3420,
  tor: ServiceHealth.off,
);

void main() {
  const settings = DeskSettings(directHttp: true, httpPort: 3420);
  for (final lang in ['de', 'pl', 'ru', 'zh', 'th', 'en']) {
    final l = lookupAppLocalizations(Locale(lang));
    test('$lang: a port in use reads whole in the sidebar and the status card', () {
      final row = receivingRailItems(l, _down(HttpProblem.portInUse), settings).singleWhere((i) => i.name == 'HTTP');
      expect(row.second, l.deskRailPortInUse);
      expect(row.lines, contains(l.deskErrPortInUse(3420)));
      expect(row.state, EState.risk);
      final line = methodStateLine(l, TxMethod.http, _down(HttpProblem.portInUse), settings);
      expect(line.detail, l.deskKitMethodPortInUse('3420'));
    });

    test('$lang: a listener that stopped with an error says so, not "port in use"', () {
      final row = receivingRailItems(l, _down(HttpProblem.stopped), settings).singleWhere((i) => i.name == 'HTTP');
      expect(row.second, l.deskRailStopped);
      expect(row.lines, contains(l.deskErrStoppedWithError));
      final line = methodStateLine(l, TxMethod.http, _down(HttpProblem.portUnavailable), settings);
      expect(line.detail, '${l.deskErrPortUnavailable(3420)}.');
    });
  }
}
