import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a keychain macOS refused reads as what to do, not Something went wrong', () {
    for (final code in ['-25293', '-25308', '-128', '-34018']) {
      final error = PlatformException(code: code, message: 'The user name or passphrase you entered is not correct.');
      expect(isMacKeychainRefusal(error), isTrue, reason: code);
      expect(deskErrorText(error), englishStrings.deskErrMacKeychain);
    }
    expect(deskErrorText(Exception('other')), englishStrings.deskErrSomethingWrong);
    expect(deskErrorText(PlatformException(code: '-25300')), englishStrings.deskErrSomethingWrong);
  });
}
