// A payment that came without an address (a QR code or file exchange): its details say who it
// was is not known, on the phone and the desktop, instead of leaving out the other side.
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart' show txNoAddressShown;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phone: a payment with no address, contact or pairing says so; the others do not', () {
    TxEntry tx({String? counterparty, TxKind kind = TxKind.received, String? transport, TxSource source = TxSource.wallet, TxOrigin origin = TxOrigin.thisWallet}) =>
        fakeTx(id: 1, kind: kind, status: TxStatus.confirmed, counterparty: counterparty, transport: transport, source: source, origin: origin);
    expect(txNoAddressShown(tx()), isTrue);
    expect(txNoAddressShown(tx(kind: TxKind.sent, transport: 'file')), isTrue);
    expect(txNoAddressShown(tx(counterparty: 'esAlice@epicbox.epiccash.com')), isFalse);
    expect(txNoAddressShown(tx(kind: TxKind.coinbase)), isFalse);
    expect(txNoAddressShown(tx(transport: 'self')), isFalse);
    expect(txNoAddressShown(tx(source: TxSource.restored)), isFalse);
    expect(txNoAddressShown(tx(origin: TxOrigin.otherWallet)), isFalse);
  });

  test('desktop: the same rule', () {
    Tx tx({String? counterparty, bool coinbase = false, bool toSelf = false, bool otherWallet = false}) => Tx(
      id: 1,
      slateId: '',
      direction: TxDirection.received,
      state: TxState.confirmed,
      method: TxMethod.file,
      amount: 100000000,
      fee: 0,
      created: DateTime(2026, 10, 28),
      counterparty: counterparty,
      coinbase: coinbase,
      toSelf: toSelf,
      otherWallet: otherWallet,
    );
    expect(noAddressShown(tx()), isTrue);
    expect(noAddressShown(tx(counterparty: 'esAlice@epicbox.epiccash.com')), isFalse);
    expect(noAddressShown(tx(coinbase: true)), isFalse);
    expect(noAddressShown(tx(toSelf: true)), isFalse);
    expect(noAddressShown(tx(otherWallet: true)), isFalse);
  });
}
