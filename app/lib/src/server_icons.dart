// SPDX-License-Identifier: Apache-2.0
/// Operators' icons from status.btlabs.uk for the server tiles: fetched like the monitor's
/// list (over the onion while Tor is on, nothing while Settings turned the site off), held
/// in memory for the rest of the run once fetched. A missing or broken icon is null, and the
/// tile shows initials.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'net/http.dart';
import 'relay_directory.dart' show statusSite;

/// The most an icon may weigh: the monitor's 256 px PNGs are about 60 KB.
const int serverIconMaxBytes = 256 * 1024;

/// Fetches one icon's bytes, or null.
typedef ServerIconFetch = Future<Uint8List?> Function(Uri url);

/// How icons are fetched; tests and the tours override it with bundled bytes.
final serverIconFetchProvider = Provider<ServerIconFetch>((ref) => fetchServerIcon);

/// One icon by its URL (the URL names the content's hash, so it never changes). A fetched icon
/// stays for the run; a failed one is asked again the next time a list shows it.
final serverIconProvider = FutureProvider.autoDispose.family<Uint8List?, Uri>((ref, url) async {
  final bytes = await ref.watch(serverIconFetchProvider)(url);
  if (bytes != null) ref.keepAlive();
  return bytes;
});

const _png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

/// The PNG at [url], or null: the site off, no answer, not a 200, too large or not a PNG.
Future<Uint8List?> fetchServerIcon(Uri url) async {
  try {
    if (!await statusSite.allowed()) return null;
    final reply = await httpGetBytes(
      url,
      timeout: const Duration(seconds: 10),
      maxBytes: serverIconMaxBytes,
    );
    final b = reply.bytes;
    if (reply.status != 200 || b.length < _png.length) return null;
    for (var i = 0; i < _png.length; i++) {
      if (b[i] != _png[i]) return null;
    }
    return b;
  } on Object {
    return null;
  }
}
