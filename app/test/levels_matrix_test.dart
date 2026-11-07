import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/levels/level_features.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/payment_method.dart';
import 'package:epic_wallet/src/tor_build.dart';

LevelFeatures f(WalletLevel l, [AdvancedPrefs p = AdvancedPrefs.none]) => LevelFeatures.of(l, p, torBuilt: true);

void main() {
  test('level 1 is the quiet shell', () {
    final x = f(WalletLevel.justSendReceive);
    expect(x.wording, LevelWording.plain);
    expect(x.sendMethods, {MethodKind.epicbox, MethodKind.directQr});
    expect(x.statusIcons, {StatusIcon.network, StatusIcon.epicbox});
    expect(x.advancedPage, AdvancedPageKind.changeLevelOnly);
    expect(x.invoices, InvoicePresence.quiet);
    expect(x.pairingListener, isTrue);
    expect(x.pairingSetupScreens, isFalse);
    expect(x.nodeAutomatic, isTrue);
    expect(x.txActions, TxActionSet.cancelOnly);
    expect(x.undercoverOffered, isTrue);
    expect(LevelFeatures.of(WalletLevel.justSendReceive, AdvancedPrefs.none, torBuilt: false).undercoverOffered, isFalse);
  });

  test('levels 2 and 3 follow the stored prefs', () {
    final c = f(WalletLevel.casual);
    expect(c.wording, LevelWording.casual);
    expect(c.timeline, TimelineStyle.casualSteps);
    expect(c.invoices, InvoicePresence.shown);
    expect(c.pairingListener, isTrue);
    expect(c.outputs, isFalse);
    final e = f(WalletLevel.everything, AdvancedPrefs.all);
    expect(e.wording, LevelWording.technical);
    expect(e.invoices, InvoicePresence.shown);
    expect(e.outputs, isTrue);
    expect(e.technicalDetails, isTrue);
    expect(e.sendMethods, MethodKind.values.toSet());
    expect(e.nodeAutomatic, isFalse);
  });

  test('effectiveAdvanced', () {
    const stored = AdvancedPrefs(
      features: {AdvancedFeature.outputs, AdvancedFeature.logs, AdvancedFeature.linkedDevices},
      networkMode: NetworkMode.torOnly,
      nodeFailover: false,
    );
    final one = effectiveAdvanced(WalletLevel.justSendReceive, stored);
    expect(one.shownFeatures, isEmpty);
    expect(one.pairingOn, isTrue);
    // A build without Tor reads a stored Tor only as Standard.
    expect(one.networkMode, torBuilt ? NetworkMode.torOnly : NetworkMode.standard);
    expect(one.nodeFailover, isTrue);
    expect(effectiveAdvanced(WalletLevel.everything, stored), stored);
    expect(effectiveAdvanced(WalletLevel.casual, stored), stored);
  });

  test('levelPreset', () {
    const stored = AdvancedPrefs(networkMode: NetworkMode.nodeOnly, nodeFailover: false);
    final three = levelPreset(WalletLevel.everything, stored);
    for (final x in AdvancedFeature.values.where((x) => !retiredFeatures.contains(x))) {
      expect(three.has(x), isTrue, reason: x.name);
    }
    expect(three.has(AdvancedFeature.invoices), isFalse);
    expect(three.networkMode, NetworkMode.nodeOnly);
    expect(three.nodeFailover, isFalse);
    expect(levelPreset(WalletLevel.casual, stored), stored);
    expect(levelPreset(WalletLevel.justSendReceive, three), three);
  });

  group('settleLevelChoice', () {
    Future<(LevelChoice, Map<String, String>)> run(Map<String, String> init) async {
      final m = {...init};
      final c = await settleLevelChoice(read: (k) async => m[k], write: (k, v) async => m[k] = v);
      return (c, m);
    }

    test('fresh store asks', () async {
      final (c, m) = await run({});
      expect(c, const LevelPending());
      expect(m[levelKey], 'ask');
    });
    test('existing install gets the existing-install level', () async {
      final (c, m) = await run({'app.qr_method_seen': 'true'});
      expect(c, const LevelChosen(existingInstallLevel));
      expect(m[levelKey], '${existingInstallLevel.number}');
    });
    test('stored 2 is kept', () async {
      final (c, _) = await run({levelKey: '2', 'app.qr_method_seen': 'true'});
      expect(c, const LevelChosen(WalletLevel.casual));
    });
  });
}
