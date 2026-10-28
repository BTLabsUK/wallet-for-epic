/// `wallet_backend.dart` in the browser. The wallet runs on the demo server, reached over one
/// WebSocket to `<origin>/api/ws` (the demo server's protocol); this side keeps only the PIN-sealed text,
/// in `localStorage`. A `WFE_WEB_FAKE=true` build runs on [previewWalletService] instead, with
/// nothing kept across a reload and no network at all.
library;

import 'package:flutter/widgets.dart' show WidgetsBinding;

import 'remote/client.dart';
import 'remote/web_channel.dart';
import 'secret_store_api.dart';
import 'secret_store_web.dart';
import 'vault.dart' show LegacyFiles;
import 'wallet_service.dart';
import 'web/preview.dart';

/// Nothing to load: LEPIC runs on the server.
Future<void> initWalletBackend() async {}

/// The server's wallet service. The socket opens at the end of the frame being drawn, the
/// first one when the launch screen asks for the vault, so nothing touches the network before
/// the first screen shows. [secrets] stays in the browser; the server keeps its own.
WalletService createWalletService(SecretStore secrets) {
  if (webFakeBackend) return previewWalletService();
  return RemoteWalletService(
    WebSocketChannel(
      demoSocketUrl(Uri.base),
      openAfter: WidgetsBinding.instance.endOfFrame,
    ),
  );
}

SecretStore createSecretStore() =>
    webFakeBackend ? MemorySecretStore() : const BrowserSecretStore();

/// The server owns the wallet's directory and ignores this one; it only has to be stable per
/// chain, because the vault keys its entries by chain.
Future<String> defaultWalletDir(Chain chain) async => '/demo/${chain.name}';

/// A browser has no wallet files from an older app.
Future<bool> _noLegacyFiles(String dataDir) async => false;

const LegacyFiles legacyWalletFiles = _noLegacyFiles;

/// For the log. The browser's own name stays out of it.
String get platformLabel => 'web';

/// The web build has no camera scanner.
bool get hostIsPhone => false;
