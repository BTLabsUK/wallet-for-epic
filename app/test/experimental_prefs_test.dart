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

  test('Linked devices is always on: a stored off from an older build is ignored (item 10)', () {
    expect(AdvancedPrefs.none.linkedDevicesOn, isTrue);
    expect(AdvancedPrefs.none.any, isFalse);
    expect(AdvancedPrefs.decode('outputs|standard').linkedDevicesOn, isTrue);
    expect(AdvancedPrefs.decode('outputs|standard|noLinkedDevices').linkedDevicesOn, isTrue);
    expect(AdvancedPrefs.fromJson({'features': ['logs'], 'networkMode': 'standard', 'linkedDevices': false}).linkedDevicesOn, isTrue);
    final off = AdvancedPrefs.none.withExperimental(AdvancedFeature.linkedDevices, false);
    expect(off.linkedDevicesOn, isTrue);
    expect(off.has(AdvancedFeature.linkedDevices), isTrue);
    expect(off.any, isFalse);
    expect(off.encode(), isNot(contains('noLinkedDevices')));
    expect(AdvancedPrefs.fromJson(off.toJson()).linkedDevicesOn, isTrue);
    expect(AdvancedPrefs.decode(AdvancedPrefs.none.encode()), AdvancedPrefs.none);
    expect(retiredFeatures, contains(AdvancedFeature.linkedDevices));
    expect(AdvancedPrefs.none.withoutShown().linkedDevicesOn, isTrue);
    expect(AdvancedPrefs.none.pairingEngineOn, isTrue);
  });
}
