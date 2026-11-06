// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/desk_link_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late File appImage;
  late Map<String, String> env;
  File entry() => File('${dir.path}/data/applications/$linkEntryName');

  setUp(() {
    dir = Directory.systemTemp.createTempSync('links');
    appImage = File('${dir.path}/BT Wallet.AppImage')..writeAsStringSync('x');
    env = {'XDG_DATA_HOME': '${dir.path}/data', 'APPIMAGE': appImage.path};
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('an AppImage writes an entry for both schemes, hidden from the menus', () async {
    await registerAppImageLinks(environment: env);
    final text = entry().readAsStringSync();
    expect(text, contains('Exec="${appImage.resolveSymbolicLinksSync()}" %u\n'));
    expect(text, contains('MimeType=x-scheme-handler/epic;x-scheme-handler/epiccash;\n'));
    expect(text, contains('NoDisplay=true\n'));
  });

  test('the same entry is left alone, a moved AppImage writes it again', () async {
    await registerAppImageLinks(environment: env);
    final first = entry().lastModifiedSync();
    await registerAppImageLinks(environment: env);
    expect(entry().lastModifiedSync(), first);
    final moved = appImage.renameSync('${dir.path}/moved.AppImage');
    await registerAppImageLinks(environment: {...env, 'APPIMAGE': moved.path});
    expect(entry().readAsStringSync(), contains('moved.AppImage'));
  });

  test('nothing is written outside an AppImage, or for a path that is gone', () async {
    await registerAppImageLinks(environment: {'XDG_DATA_HOME': env['XDG_DATA_HOME']!});
    await registerAppImageLinks(environment: {...env, 'APPIMAGE': '${dir.path}/gone'});
    await registerAppImageLinks(environment: {...env, 'APPIMAGE': '${appImage.path}\nx'});
    expect(entry().existsSync(), isFalse);
  });

  test('a folder that cannot be written costs the links only', () async {
    final blocked = File('${dir.path}/blocked')..writeAsStringSync('x');
    await registerAppImageLinks(environment: {...env, 'XDG_DATA_HOME': blocked.path});
  });

  test('the Exec line quotes what a path can hold, and only then', () {
    expect(linkEntry('/home/a/bt-wallet_1.2.AppImage'), contains('Exec=/home/a/bt-wallet_1.2.AppImage %u\n'));
    expect(linkEntry(r'/a b/c"d$e\f%g'), contains(r'Exec="/a b/c\\"d\\$e\\\\f%%g" %u'));
  });

  test('the folder follows XDG, then HOME', () {
    expect(linkEntryFolder({'XDG_DATA_HOME': '/x', 'HOME': '/h'}), '/x/applications');
    expect(linkEntryFolder({'XDG_DATA_HOME': 'relative', 'HOME': '/h'}), '/h/.local/share/applications');
    expect(linkEntryFolder({}), isNull);
  });
}
