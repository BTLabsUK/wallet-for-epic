@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/slate_files_web.dart';
import 'package:epic_wallet/src/web/splash_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('download', () {
    test('a save is a download of the bytes under the name', () async {
      final clicks = <({String download, String href})>[];
      final listener = ((_Event event) {
        final target = event.target;
        if (target.download.isEmpty) return;
        clicks.add((download: target.download, href: target.href));
        // Keep the test browser from writing a file.
        event.preventDefault();
      }).toJS;
      _document.addEventListener('click', listener, true.toJS);
      addTearDown(
        () => _document.removeEventListener('click', listener, true.toJS),
      );

      final json = '{"id":"slate-1","note":"é"}';
      final saved = await saveBytesToDevice(
        name: 'slate-1.tx',
        bytes: Uint8List.fromList(utf8.encode(json)),
        dialogTitle: 'Save',
      );

      expect(saved, isTrue);
      expect(clicks.single.download, 'slate-1.tx');
      expect(clicks.single.href, startsWith('blob:'));
      // The blob URL stays alive past the click, and holds the bytes.
      final reply = await httpGet(Uri.parse(clicks.single.href));
      expect(reply.body, json);
      // The anchor does not stay in the page.
      expect(_document.querySelectorAll('a[download]').length, 0);
    });

    test('clearSharedFiles has nothing to do and share is refused', () async {
      await clearSharedFiles();
      expect(
        () => shareBytes(name: 'x.tx', bytes: Uint8List(1)),
        throwsUnsupportedError,
      );
    });
  });

  group('splash', () {
    test('removeSplash takes the splash out of the page, once', () {
      final splash = _document.createElement('div')..id = splashElementId;
      _document.body.append(splash);
      expect(_document.getElementById(splashElementId), isNotNull);

      removeSplash();
      expect(_document.getElementById(splashElementId), isNull);
      // Already gone: no error.
      removeSplash();
    });
  });
}

@JS('document')
external _Document get _document;

extension type _Document._(JSObject _) implements JSObject {
  external _Element createElement(String tag);
  external _Element get body;
  external _Element? getElementById(String id);
  external _NodeList querySelectorAll(String selector);
  external void addEventListener(String type, JSFunction f, JSBoolean capture);
  external void removeEventListener(
    String type,
    JSFunction f,
    JSBoolean capture,
  );
}

extension type _NodeList._(JSObject _) implements JSObject {
  external int get length;
}

extension type _Element._(JSObject _) implements JSObject {
  external set id(String value);
  external void append(JSObject child);
  external String get download;
  external String get href;
}

extension type _Event._(JSObject _) implements JSObject {
  external _Element get target;
  external void preventDefault();
}
