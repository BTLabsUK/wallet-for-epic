// Settings › Advanced › Experimental: Pairing and Invoices, off by default, and the rule
// between them; stored with the other Advanced features.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('both are off for a new wallet and for one saved before they existed', () {
    expect(AdvancedPrefs.none.pairingOn, isFalse);
    expect(AdvancedPrefs.none.invoicesOn, isFalse);
    final old = AdvancedPrefs.decode('outputs,technicalDetails|standard');
    expect(old.pairingOn, isFalse);
    expect(old.invoicesOn, isFalse);
    expect(AdvancedPrefs.fromJson({'features': ['logs'], 'networkMode': 'standard'}).pairingOn, isFalse);
  });

  test('Invoices on turns Pairing on; Pairing off turns Invoices off', () {
    final inv = AdvancedPrefs.none.withExperimental(AdvancedFeature.invoices, true);
    expect(inv.pairingOn, isTrue);
    expect(inv.invoicesOn, isTrue);
    final off = inv.withExperimental(AdvancedFeature.pairing, false);
    expect(off.pairingOn, isFalse);
    expect(off.invoicesOn, isFalse);
    final pairOnly = AdvancedPrefs.none.withExperimental(AdvancedFeature.pairing, true);
    expect(pairOnly.pairingOn, isTrue);
    expect(pairOnly.invoicesOn, isFalse);
    expect(inv.withExperimental(AdvancedFeature.invoices, false).pairingOn, isTrue);
  });

  test('they survive a save and Hide all, and are not counted with the others', () {
    final p = AdvancedPrefs.none
        .withFeature(AdvancedFeature.outputs, true)
        .withExperimental(AdvancedFeature.invoices, true);
    expect(AdvancedPrefs.decode(p.encode()), p);
    expect(AdvancedPrefs.fromJson(p.toJson()), p);
    expect(p.shownFeatures, {AdvancedFeature.outputs});
    final hidden = p.withoutShown();
    expect(hidden.shownFeatures, isEmpty);
    expect(hidden.invoicesOn, isTrue);
  });

  test('the gate follows the switches', () {
    addTearDown(() => NetGate.setExperimental(AdvancedPrefs.all));
    NetGate.setExperimental(AdvancedPrefs.none);
    expect(NetGate.pairing, isFalse);
    expect(NetGate.invoices, isFalse);
    NetGate.setExperimental(AdvancedPrefs.none.withExperimental(AdvancedFeature.pairing, true));
    expect(NetGate.pairing, isTrue);
    expect(NetGate.invoices, isFalse);
  });
}
