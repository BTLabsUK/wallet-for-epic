// SPDX-License-Identifier: Apache-2.0
// The Unlock list's second line: wallets in the app's own folder say when they were
// opened (their path differs by an id only); others show their folder from `~`, the end kept.
import 'package:epic_wallet/l10n/app_localizations_en.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/unlock_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l = AppLocalizationsEn();
  final now = DateTime(2026, 10, 27, 12);

  WalletEntry entry(String folder, {DateTime? opened}) =>
      WalletEntry(id: 'x', name: 'W', folder: folder, network: 'mainnet', lastOpened: opened);

  test('the app\'s own wallets folder, Linux and Windows', () {
    expect(inWalletsFolder('/home/marv/.epic_cash_desktop/wallets/5a1d2e3f'), isTrue);
    expect(inWalletsFolder('/home/marv/.epic_cash_desktop/wallet'), isTrue);
    expect(inWalletsFolder('/home/marv/.epic_cash_desktop/dev/floonet/wallets/5a1d2e3f'), isTrue);
    expect(inWalletsFolder(r'C:\Users\Marv\.epic_cash_desktop\wallets\5a1d2e3f'), isTrue);
    expect(inWalletsFolder(r'C:\Users\Marv\.epic\main\wallet_data'), isFalse);
    expect(inWalletsFolder('/media/usb/epic/w9'), isFalse);
  });

  test('home becomes ~, other folders stay whole', () {
    expect(shortFolder('/home/marv/.epic/main/savings', home: '/home/marv'), '~/.epic/main/savings');
    expect(shortFolder('/home/marvin/x', home: '/home/marv'), '/home/marvin/x');
    expect(shortFolder('/media/usb/w9', home: '/home/marv'), '/media/usb/w9');
  });

  test('the second line: opened time in the own folder, the folder elsewhere or when never opened', () {
    final own = '/home/marv/.epic_cash_desktop/wallets/5a1d2e3f';
    expect(walletRowLine(l, entry(own, opened: now.subtract(const Duration(days: 3))), now: now), 'Opened 3 d ago');
    expect(walletRowLine(l, entry(own, opened: now.subtract(const Duration(minutes: 5))), now: now), 'Opened 5 min ago');
    expect(walletRowLine(l, entry(own), now: now, home: '/home/marv'), '~/.epic_cash_desktop/wallets/5a1d2e3f');
    expect(
      walletRowLine(l, entry('/home/marv/.epic/main/savings', opened: now), now: now, home: '/home/marv'),
      '~/.epic/main/savings',
    );
  });
}
