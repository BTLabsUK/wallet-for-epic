// SPDX-License-Identifier: Apache-2.0
/// `slate_files.dart`'s file calls in the browser: a save is a download, and there is no share
/// sheet and no temporary copy. Picking a file needs nothing here: file_picker reads its bytes
/// on the web as everywhere else.
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

/// Saves [bytes] as a browser download called [name]. The browser decides where it goes and
/// does not say whether the visitor kept it, so this returns true. [dialogTitle] has no place
/// on the web.
Future<bool> saveBytesToDevice({
  required String name,
  required Uint8List bytes,
  required String dialogTitle,
}) async {
  downloadBytes(name: name, bytes: bytes);
  return true;
}

/// Never called: `canShareFiles` is false on the web.
Future<bool> shareBytes({
  required String name,
  required Uint8List bytes,
  String mimeType = 'application/octet-stream',
  String? text,
}) => throw UnsupportedError('no share sheet on the web');

/// Nothing to clear: the web writes no temporary copies.
Future<void> clearSharedFiles() async {}

/// How long the download's `blob:` URL lives. The browser reads it when the click starts the
/// download, so a few seconds is plenty; Firefox needs it alive past the click itself.
const Duration _blobLifetime = Duration(seconds: 30);

/// Starts a download of [bytes] as [name] through a `blob:` URL and a clicked `<a download>`.
/// `application/octet-stream` keeps the browser from opening a `.tx` file as text.
void downloadBytes({
  required String name,
  required Uint8List bytes,
  String mimeType = 'application/octet-stream',
}) {
  final blob = _Blob([bytes.toJS].toJS, _BlobOptions(type: mimeType));
  final url = _createObjectUrl(blob);
  final anchor = _document.createElement('a')
    ..href = url
    ..download = name
    ..rel = 'noopener';
  anchor.style.display = 'none';
  _document.body.append(anchor);
  anchor.click();
  anchor.remove();
  Timer(_blobLifetime, () => _revokeObjectUrl(url));
}

@JS('document')
external _Document get _document;

extension type _Document._(JSObject _) implements JSObject {
  external _Anchor createElement(String tag);
  external _Element get body;
}

extension type _Element._(JSObject _) implements JSObject {
  external void append(JSObject child);
  external void remove();
  external _Style get style;
}

extension type _Style._(JSObject _) implements JSObject {
  external set display(String value);
}

extension type _Anchor._(JSObject _) implements _Element {
  external set href(String value);
  external set download(String value);
  external set rel(String value);
  external void click();
}

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external _Blob(JSArray<JSAny> parts, _BlobOptions options);
}

extension type _BlobOptions._(JSObject _) implements JSObject {
  external factory _BlobOptions({String type});
}

@JS('URL.createObjectURL')
external String _createObjectUrl(_Blob blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(String url);
