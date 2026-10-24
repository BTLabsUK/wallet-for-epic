import 'package:epic_wallet/src/data_folder_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the Linux data folder is ~/.epic_cash_desktop, whatever XDG or the app ID say', () {
    expect(linuxDataFolder({'HOME': '/home/a'}), '/home/a/.epic_cash_desktop');
    expect(linuxDataFolder({'HOME': '/home/a', 'XDG_DATA_HOME': '/data'}), '/home/a/.epic_cash_desktop');
    expect(linuxDataFolder({'HOME': ''}), isNull);
    expect(linuxDataFolder({}), isNull);
  });
}
