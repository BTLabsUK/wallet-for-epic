// SPDX-License-Identifier: Apache-2.0
// Settings › Advanced › Experimental: Invoices, off by default; Pairing is on for everyone and
// its old stored switch value is ignored; stored with the other Advanced features.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Invoices is off for a new wallet and for one saved before it existed; Pairing is always on', () {
    expect(AdvancedPrefs.none.invoicesOn, isFalse);
    expect(AdvancedPrefs.none.pairingOn, isTrue);
    final old = AdvancedPrefs.decode('outputs,technicalDetails|standard');
    expect(old.invoicesOn, isFalse);
    expect(old.pairingOn, isTrue);
    expect(AdvancedPrefs.fromJson({'features': ['logs'], 'networkMode': 'standard'}).pairingOn, isTrue);
  });

  test('an install that stored the old pairing switch off still pairs', () {
    final stored = AdvancedPrefs.decode('outputs|standard');
    expect(stored.pairingOn, isTrue);
    final withOld = AdvancedPrefs.fromJson({'features': ['invoices'], 'networkMode': 'standard'});
    expect(withOld.invoicesOn, isTrue);
    expect(withOld.pairingOn, isTrue);
    expect(retiredFeatures, contains(AdvancedFeature.pairing));
  });

  test('Invoices survives a save and Hide all, and is not counted with the others', () {
    final p = AdvancedPrefs.none.withFeature(AdvancedFeature.outputs, true).withExperimental(AdvancedFeature.invoices, true);
    expect(AdvancedPrefs.decode(p.encode()), p);
    expect(AdvancedPrefs.fromJson(p.toJson()), p);
    expect(p.shownFeatures, {AdvancedFeature.outputs});
    final hidden = p.withoutShown();
    expect(hidden.shownFeatures, isEmpty);
    expect(hidden.invoicesOn, isTrue);
  });

  test('the gate follows Invoices; pairing is never gated', () {
    addTearDown(() => NetGate.setExperimental(AdvancedPrefs.all));
    NetGate.setExperimental(AdvancedPrefs.none);
    expect(NetGate.pairing, isTrue);
    expect(NetGate.invoices, isFalse);
    NetGate.setExperimental(AdvancedPrefs.none.withExperimental(AdvancedFeature.invoices, true));
    expect(NetGate.invoices, isTrue);
  });

  test('Linked devices is on by default, and a user who turned it off stays off', () {
    expect(AdvancedPrefs.none.linkedDevicesOn, isTrue);
    expect(AdvancedPrefs.none.any, isFalse);
    expect(AdvancedPrefs.decode('outputs|standard').linkedDevicesOn, isTrue);
    expect(AdvancedPrefs.fromJson({'features': ['logs'], 'networkMode': 'standard'}).linkedDevicesOn, isTrue);
    final off = AdvancedPrefs.none.withExperimental(AdvancedFeature.linkedDevices, false);
    expect(off.linkedDevicesOn, isFalse);
    expect(off.any, isTrue);
    expect(AdvancedPrefs.decode(off.encode()).linkedDevicesOn, isFalse);
    expect(AdvancedPrefs.fromJson(off.toJson()).linkedDevicesOn, isFalse);
    expect(AdvancedPrefs.decode(AdvancedPrefs.none.encode()), AdvancedPrefs.none);
    // Hide all keeps it; it runs the engine without Invoices.
    expect(off.withoutShown().linkedDevicesOn, isFalse);
    expect(AdvancedPrefs.none.withoutShown().linkedDevicesOn, isTrue);
    expect(AdvancedPrefs.none.pairingEngineOn, isTrue);
  });
}
