// The app's count before the first balance equals LEPIC's default (6, LEPIC ADR 0027): a send
// made before the balance arrives spends what the balance will call spendable, unless the wallet
// stores another count, which the balance then reports.
import 'package:epic_wallet/src/providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the fallback count is LEPIC\'s default, 6', () {
    expect(defaultMinimumConfirmations, 6);
    expect(minimumConfirmations, BigInt.from(6));
  });
}
