// The build-time Tor switch (lib/src/tor_build.dart): what a stored Tor choice reads as, with
// Tor in (the default) and in the build without Tor. Run both ways:
//   flutter test test/tor_build_test.dart
//   flutter test --dart-define=WFE_TOR=false test/tor_build_test.dart
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/data/features.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the desktop flag and in-app updates follow the switch', () {
    expect(DeskFeatures.tor, torBuilt);
    expect(inAppUpdates, torBuilt);
  });

  test('Link · Tor stays on only with Tor in, however it was stored', () {
    expect(const PaymentPrefs(linkTor: true).linkTor, torBuilt);
    expect(const PaymentPrefs(linkTor: true).offers(MethodKind.linkTor), torBuilt);
    expect(PaymentPrefs.decode('v2,tor|linkTor').linkTor, torBuilt);
    expect(PaymentPrefs.fromJson({'linkHttp': false, 'linkTor': true}).linkTor, torBuilt);
    expect(const PaymentPrefs(linkTor: true).copyWith(linkHttp: true).linkTor, torBuilt);
    // Send's first method: a stored Link · Tor default falls back to a method that is on.
    final p = PaymentPrefs.decode('v2,tor|linkTor');
    expect(p.startMethod, torBuilt ? MethodKind.linkTor : MethodKind.epicbox);
  });

  test('Tor only reads as Standard without Tor', () {
    final mode = torBuilt ? NetworkMode.torOnly : NetworkMode.standard;
    expect(const AdvancedPrefs(networkMode: NetworkMode.torOnly).networkMode, mode);
    expect(AdvancedPrefs.none.withMode(NetworkMode.torOnly).networkMode, mode);
    expect(AdvancedPrefs.none.withMode(NetworkMode.torOnly).startsWithTor, torBuilt);
    expect(AdvancedPrefs.decode('outputs|torOnly').networkMode, mode);
    expect(AdvancedPrefs.fromJson({'networkMode': 'torOnly'}).networkMode, mode);
    expect(AdvancedPrefs.none.withMode(NetworkMode.offline).networkMode, NetworkMode.offline);
  });

  test('no tor is looked for without Tor', () async {
    if (torBuilt) return;
    expect(await findTorBundle(), isNull);
  });
}
