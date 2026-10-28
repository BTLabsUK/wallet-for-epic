// SPDX-License-Identifier: Apache-2.0
/// `splash.dart` in the browser, with `dart:js_interop` only.
library;

import 'dart:js_interop';

/// The id of the splash element in `web/index.html`.
const String splashElementId = 'splash';

/// Removes the page's splash. Safe to call when it is already gone.
void removeSplash() => _document.getElementById(splashElementId)?.remove();

@JS('document')
external _Document get _document;

extension type _Document._(JSObject _) implements JSObject {
  external _Element? getElementById(String id);
}

extension type _Element._(JSObject _) implements JSObject {
  external void remove();
}
