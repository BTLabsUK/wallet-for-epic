// SPDX-License-Identifier: Apache-2.0
// Settings › Transactions' model: one switch per method, defaults, the stored forms (today's
// and the ones before the split), Send's first method, at least one on, and the old Advanced
// "Link receiving" switch taken over.
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/tor_routes.dart' show TorState;
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

List<bool> _on(PaymentPrefs p) => [for (final m in MethodKind.values) p.offers(m)];

void main() {
  test('defaults: Epicbox and File Transfer on, Link off, QR off (the phone\'s method), Send starts on Epicbox', () {
    const p = PaymentPrefs.defaults;
    expect(_on(p), [true, false, false, false, true]);
    expect(p.startMethod, MethodKind.epicbox);
    expect(p.offersFamily(MethodFamily.link), isFalse);
    expect(p.offersFamily(MethodFamily.direct), isTrue);
  });

  test('a new phone: Epicbox and QR Payment on, File Transfer and Link off', () {
    const p = PaymentPrefs.phoneDefaults;
    expect(_on(p), [true, false, false, true, false]);
    expect(PaymentPrefs.decode(null, phone: true), p);
    // The Advanced "Direct receiving" switch before 26.10.13 sent to web and onion addresses.
    final legacy = PaymentPrefs.decode(null, phone: true, legacyDirect: true);
    expect((legacy.linkTor, legacy.linkHttp), (true, true));
    // A stored value wins over the platform's defaults.
    expect(PaymentPrefs.decode('v2,file|epicbox', phone: true).directFile, isTrue);
  });

  test('the one Link switch before the split turns both Link methods on (HTTP sending stays)', () {
    final phone = PaymentPrefs.decode('direct,file|direct', phone: true);
    expect((phone.linkHttp, phone.linkTor, phone.directFile, phone.directQr), (true, true, true, true));
    expect(phone.startMethod, MethodKind.linkHttp, reason: 'Link stays the start method');
    final desk = PaymentPrefs.decode('direct,file|direct');
    expect((desk.linkHttp, desk.linkTor), (true, true));
    expect(desk.startMethod, MethodKind.linkHttp);
    expect(PaymentPrefs.decode('file|epicbox').offersFamily(MethodFamily.link), isFalse);
    // The old names of the Direct methods as the default.
    expect(PaymentPrefs.decode('file|qr').defaultMethod, MethodKind.directQr);
    expect(PaymentPrefs.decode('file|file').defaultMethod, MethodKind.directFile);
  });

  test('QR reads as on in a value stored before it existed, and off once saved off', () {
    expect(PaymentPrefs.decode('direct,file|epicbox').directQr, isTrue);
    const off = PaymentPrefs(directQr: false);
    expect(PaymentPrefs.decode(off.encode()).directQr, isFalse);
    expect(PaymentPrefs.fromJson({'direct': false, 'file': true}).directQr, isFalse, reason: 'the desktop never offers QR');
    expect(PaymentPrefs.fromJson({'directQr': true}).directQr, isTrue);
    expect(PaymentPrefs.fromJson(off.toJson()).directQr, isFalse);
    expect(const PaymentPrefs(defaultMethod: MethodKind.directQr, directQr: false).startMethod, MethodKind.epicbox);
    expect(const PaymentPrefs(defaultMethod: MethodKind.directQr).startMethod, MethodKind.directQr);
  });

  test('a default method that is off starts Send on the first method on; Link counts as a family', () {
    expect(const PaymentPrefs(defaultMethod: MethodKind.linkHttp).startMethod, MethodKind.epicbox);
    expect(const PaymentPrefs(linkHttp: true, defaultMethod: MethodKind.linkHttp).startMethod, MethodKind.linkHttp);
    expect(const PaymentPrefs(linkTor: true, defaultMethod: MethodKind.linkHttp).startMethod, MethodKind.linkTor);
    expect(const PaymentPrefs(linkHttp: true, defaultMethod: MethodKind.linkTor).startMethod, MethodKind.linkHttp);
    expect(const PaymentPrefs(directFile: false, defaultMethod: MethodKind.directFile).startMethod, MethodKind.epicbox);
    expect(const PaymentPrefs(epicbox: false, defaultMethod: MethodKind.epicbox).startMethod, MethodKind.directQr);
  });

  test('encode and decode round-trip in the per-method form', () {
    const p = PaymentPrefs(linkHttp: true, directFile: false, defaultMethod: MethodKind.linkHttp);
    expect(p.encode(), 'v2,http|linkHttp');
    expect(PaymentPrefs.decode(p.encode()), p);
    const q = PaymentPrefs(linkTor: true, directQr: false, epicbox: false, defaultMethod: MethodKind.linkTor);
    expect(q.encode(), 'v2,tor,file,noqr,noepicbox|linkTor');
    expect(PaymentPrefs.decode(q.encode()), q);
    expect(PaymentPrefs.decode(PaymentPrefs.defaults.encode()), PaymentPrefs.defaults);
    expect(PaymentPrefs.decode(null), PaymentPrefs.defaults);
    expect(PaymentPrefs.decode('v2,http|nonsense').defaultMethod, MethodKind.epicbox);
    for (final m in MethodKind.values) {
      expect(PaymentPrefs.decode(PaymentPrefs.defaults.withMethod(m, false).encode()).offers(m), isFalse);
      expect(PaymentPrefs.decode(PaymentPrefs.defaults.withMethod(m, true).encode()).offers(m), isTrue);
    }
  });

  test('the Epicbox switch: on by default, read as on from older values, off once saved off', () {
    expect(PaymentPrefs.defaults.epicbox, isTrue);
    expect(PaymentPrefs.decode('direct,file|epicbox').epicbox, isTrue);
    expect(PaymentPrefs.fromJson({'direct': false, 'file': true}).epicbox, isTrue);
    const off = PaymentPrefs(epicbox: false);
    expect(off.offers(MethodKind.epicbox), isFalse);
    expect(PaymentPrefs.decode(off.encode()), off);
    expect(PaymentPrefs.fromJson(off.toJson()).epicbox, isFalse);
    expect(off.startMethod, MethodKind.directQr, reason: 'the phone\'s order');
    expect(const PaymentPrefs(epicbox: false, directQr: false).startMethod, MethodKind.directFile);
    expect(const PaymentPrefs(epicbox: false, linkHttp: true).startMethod, MethodKind.linkHttp);
    expect(const PaymentPrefs(epicbox: false, directFile: false, directQr: false).startMethod, MethodKind.epicbox);
    expect(deskSettingsFromJson(deskSettingsToJson(const DeskSettings(payments: off))).payments, off);
  });

  test('at least one method stays on', () {
    const one = PaymentPrefs(directQr: false, directFile: false);
    expect(one.on, [MethodKind.epicbox]);
    expect(one.canTurnOff(MethodKind.epicbox), isFalse);
    expect(one.canTurnOff(MethodKind.linkHttp), isTrue, reason: 'off already: nothing changes');
    expect(PaymentPrefs.defaults.canTurnOff(MethodKind.epicbox), isTrue);
    expect(const PaymentPrefs(epicbox: false, directQr: false, directFile: false, linkTor: true).canTurnOff(MethodKind.linkTor), isFalse);
  });

  test('the desktop store keeps it, and takes over the old switch and the old keys', () {
    const p = PaymentPrefs(linkHttp: true, linkTor: true, defaultMethod: MethodKind.directFile);
    expect(deskSettingsFromJson(deskSettingsToJson(const DeskSettings(payments: p))).payments, p);
    expect(deskSettingsFromJson({}).payments, PaymentPrefs.defaults);
    final legacy = deskSettingsFromJson({
      'advanced': {'features': ['directReceiving', 'outputs'], 'networkMode': 'standard'},
    }).payments;
    expect((legacy.linkHttp, legacy.linkTor), (true, true));
    final old = PaymentPrefs.fromJson({'epicbox': true, 'direct': true, 'file': false, 'qr': true, 'default': 'direct'});
    expect((old.linkHttp, old.linkTor, old.directFile, old.defaultMethod), (true, true, false, MethodKind.linkHttp));
    // A saved per-method value wins over the old switch.
    expect(PaymentPrefs.fromJson({'linkHttp': false, 'linkTor': false, 'direct': true}, legacyDirect: true).offersFamily(MethodFamily.link), isFalse);
  });

  test('the gate reads the whole model', () {
    addTearDown(() => NetGate.setPayments(PaymentPrefs.defaults));
    NetGate.setPayments(const PaymentPrefs(linkTor: true, directFile: false));
    expect(NetGate.offers(MethodKind.linkTor), isTrue);
    expect(NetGate.offers(MethodKind.directFile), isFalse);
    expect(NetGate.epicbox, isTrue);
    expect(() => NetGate.checkMethod(MethodKind.linkHttp, 'send'), throwsA(isA<NetBlocked>().having((e) => e.methodOff, 'methodOff', MethodKind.linkHttp)));
    NetGate.checkMethod(MethodKind.linkTor, 'send');
    NetGate.setEpicbox(false);
    expect(NetGate.offers(MethodKind.linkTor), isTrue, reason: 'the shim keeps the other switches');
    expect(() => NetGate.checkEpicbox('listen'), throwsA(isA<NetBlocked>().having((e) => e.epicboxOff, 'epicboxOff', isTrue)));
    expect(netBlockFor(NetworkMode.standard, TorState.off, offered: false), NetBlock.methodOff);
    expect(netBlockFor(NetworkMode.standard, TorState.off, epicbox: false, offered: false), NetBlock.epicboxOff, reason: 'Epicbox first');
    expect(netBlockFor(NetworkMode.nodeOnly, TorState.off, offered: false), NetBlock.nodeOnly, reason: 'the mode first');
  });
}
