import 'package:epic_wallet/src/data_folder_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the Linux data folder is named by the app ID under the XDG data home', () {
    expect(linuxDataFolder({'HOME': '/home/a'}), '/home/a/.local/share/com.blacktyger.epicwallet');
    expect(linuxDataFolder({'HOME': '/home/a', 'XDG_DATA_HOME': '/data'}), '/data/com.blacktyger.epicwallet');
    expect(linuxDataFolder({'HOME': '/home/a', 'XDG_DATA_HOME': ''}), '/home/a/.local/share/com.blacktyger.epicwallet');
    expect(linuxDataFolder({}), isNull);
  });
}
