import 'package:epic_wallet/src/data_folder_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the Linux and macOS data folder is ~/.epic_cash_desktop, whatever XDG or the app ID say', () {
    expect(desktopDataFolder({'HOME': '/home/a'}, windows: false), '/home/a/.epic_cash_desktop');
    expect(desktopDataFolder({'HOME': '/home/a/'}, windows: false), '/home/a/.epic_cash_desktop');
    expect(desktopDataFolder({'HOME': '/home/a', 'XDG_DATA_HOME': '/data'}, windows: false), '/home/a/.epic_cash_desktop');
    expect(desktopDataFolder({'HOME': '/Users/a', 'USERPROFILE': r'C:\x'}, windows: false), '/Users/a/.epic_cash_desktop');
    expect(desktopDataFolder({'HOME': ''}, windows: false), isNull);
    expect(desktopDataFolder({}, windows: false), isNull);
  });

  test('the Windows data folder is %USERPROFILE%\\.epic_cash_desktop, never under AppData', () {
    expect(desktopDataFolder({'USERPROFILE': r'C:\Users\a', 'APPDATA': r'C:\Users\a\AppData\Roaming'}, windows: true),
        r'C:\Users\a\.epic_cash_desktop');
    expect(desktopDataFolder({'USERPROFILE': r'C:\Users\a\'}, windows: true), r'C:\Users\a\.epic_cash_desktop');
    // HOME (Git Bash, MSYS) is not the profile folder.
    expect(desktopDataFolder({'HOME': '/c/Users/a'}, windows: true), isNull);
    expect(desktopDataFolder({'USERPROFILE': ''}, windows: true), isNull);
  });

  test('no vendor or app ID in the folder names', () {
    for (final windows in [false, true]) {
      final dir = desktopDataFolder({'HOME': '/home/a', 'USERPROFILE': r'C:\Users\a'}, windows: windows)!;
      expect(dir.toLowerCase(), isNot(contains('blacktyger')));
      expect(dir, endsWith(desktopDataFolderName));
    }
  });
}
