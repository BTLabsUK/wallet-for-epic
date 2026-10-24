// Settings › Transactions' model: defaults, the stored forms, Send's first method, and the old
// Advanced "Link receiving" switch taken over.
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults: Epicbox and File offered, Link not, Send starts on Epicbox', () {
    const p = PaymentPrefs.defaults;
    expect([for (final m in PayMethod.values) p.offers(m)], [true, false, true, true]);
    expect(p.startMethod, PayMethod.epicbox);
  });

  test('a new phone: Epicbox and QR offered, File and Link not', () {
    const p = PaymentPrefs.phoneDefaults;
    expect([for (final m in PayMethod.values) p.offers(m)], [true, false, true, false]);
    expect(PaymentPrefs.decode(null, phone: true), p);
    expect(PaymentPrefs.decode(null, phone: true, legacyDirect: true).direct, isTrue);
    // A stored value wins over the platform's defaults.
    expect(PaymentPrefs.decode('file|epicbox', phone: true).file, isTrue);
  });

  test('QR reads as on in a value stored before it existed, and off once saved off', () {
    expect(PaymentPrefs.decode('direct,file|epicbox').qr, isTrue);
    const off = PaymentPrefs(qr: false);
    expect(PaymentPrefs.decode(off.encode()).qr, isFalse);
    expect(PaymentPrefs.fromJson({'direct': false, 'file': true}).qr, isTrue);
    expect(PaymentPrefs.fromJson(off.toJson()).qr, isFalse);
    expect(const PaymentPrefs(defaultMethod: PayMethod.qr, qr: false).startMethod, PayMethod.epicbox);
    expect(const PaymentPrefs(defaultMethod: PayMethod.qr).startMethod, PayMethod.qr);
  });

  test('a default method that is not offered starts Send on Epicbox', () {
    expect(const PaymentPrefs(defaultMethod: PayMethod.direct).startMethod, PayMethod.epicbox);
    expect(const PaymentPrefs(direct: true, defaultMethod: PayMethod.direct).startMethod, PayMethod.direct);
    expect(const PaymentPrefs(file: false, defaultMethod: PayMethod.file).startMethod, PayMethod.epicbox);
  });

  test('encode and decode, and the old Link receiving switch', () {
    const p = PaymentPrefs(direct: true, file: false, defaultMethod: PayMethod.direct);
    expect(PaymentPrefs.decode(p.encode()), p);
    expect(PaymentPrefs.decode(PaymentPrefs.defaults.encode()), PaymentPrefs.defaults);
    expect(PaymentPrefs.decode(null), PaymentPrefs.defaults);
    expect(PaymentPrefs.decode(null, legacyDirect: true).direct, isTrue);
    expect(PaymentPrefs.decode('direct|nonsense').defaultMethod, PayMethod.epicbox);
  });

  test('the desktop store keeps it and takes over the old switch', () {
    const p = PaymentPrefs(direct: true, defaultMethod: PayMethod.file);
    expect(deskSettingsFromJson(deskSettingsToJson(const DeskSettings(payments: p))).payments, p);
    expect(deskSettingsFromJson({}).payments, PaymentPrefs.defaults);
    expect(
      deskSettingsFromJson({
        'advanced': {'features': ['directReceiving', 'outputs'], 'networkMode': 'standard'},
      }).payments.direct,
      isTrue,
    );
  });
}
