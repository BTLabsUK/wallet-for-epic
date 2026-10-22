// The app's count before the first balance equals LEPIC's (BALANCE_MINIMUM_CONFIRMATIONS, 3 since
// f756e15, decision D1): a send made before the balance arrives spends what the balance will call
// spendable.
import 'package:epic_wallet/src/providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the fallback count is LEPIC\'s 3', () {
    expect(defaultMinimumConfirmations, 3);
    expect(minimumConfirmations, BigInt.from(3));
  });
}
