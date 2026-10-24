// Settings › Transactions' model: defaults, the stored forms, Send's first method, and the old
// Advanced "Direct receiving" switch taken over.
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults: Epicbox and File offered, Direct not, Send starts on Epicbox', () {
    const p = PaymentPrefs.defaults;
    expect([for (final m in PayMethod.values) p.offers(m)], [true, false, true]);
    expect(p.startMethod, PayMethod.epicbox);
  });

  test('a default method that is not offered starts Send on Epicbox', () {
    expect(const PaymentPrefs(defaultMethod: PayMethod.direct).startMethod, PayMethod.epicbox);
    expect(const PaymentPrefs(direct: true, defaultMethod: PayMethod.direct).startMethod, PayMethod.direct);
    expect(const PaymentPrefs(file: false, defaultMethod: PayMethod.file).startMethod, PayMethod.epicbox);
  });

  test('encode and decode, and the old Direct receiving switch', () {
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
