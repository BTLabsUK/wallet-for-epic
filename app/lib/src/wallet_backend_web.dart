/// `wallet_backend.dart` in the browser. The wallet runs on the demo server; this side keeps
/// only the PIN-sealed text, in `localStorage`. A `WFE_WEB_FAKE=true` build runs on
/// [previewWalletService] instead, with nothing kept across a reload.
library;

import 'secret_store.dart' show MemorySecretStore, SecretStore;
import 'secret_store_web.dart';
import 'vault.dart' show LegacyFiles;
import 'wallet_service.dart';
import 'web/preview.dart';

/// Nothing to load: LEPIC runs on the server.
Future<void> initWalletBackend() async {}

WalletService createWalletService(SecretStore secrets) {
  if (webFakeBackend) return previewWalletService();
  // W-03 step 2: RemoteWalletService over <origin>/api/ws, once W-01 is on main.
  throw UnsupportedError('the web app needs the wallet server');
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
