// SPDX-License-Identifier: Apache-2.0
/// `wallet_backend.dart` in the browser: only the web preview (`--dart-define=WFE_WEB_FAKE=true`,
/// `tool/build_preview.sh`) runs there, on [previewWalletService], with nothing kept across a
/// reload and no network at all.
library;

import 'package:flutter_riverpod/misc.dart' show Override;

import 'secret_store_api.dart';
import 'vault.dart' show LegacyFiles;
import 'wallet_service.dart';
import 'web/preview.dart';

/// Nothing to load: the preview has no wallet core.
Future<void> initWalletBackend() async {}

/// The preview runs no tor: nothing to tell it.
void wantTorAtOpen(Future<bool> Function(WalletConfig config) wanted) {}

/// The preview's wallet. A browser build without `WFE_WEB_FAKE` has no wallet to run.
WalletService createWalletService(SecretStore secrets) {
  if (webFakeBackend) return previewWalletService();
  throw UnsupportedError('in a browser the app runs only as the preview (--dart-define=WFE_WEB_FAKE=true)');
}

/// Nothing is kept across a reload.
SecretStore createSecretStore() => MemorySecretStore();

/// The preview's overrides at start ([previewOverrides]).
List<Override> backendOverrides() => webFakeBackend ? previewOverrides() : const [];

/// The fake wallet ignores its directory; it only has to be stable per chain, because the
/// vault keys its entries by chain.
Future<String> defaultWalletDir(Chain chain) async =>
    chain == Chain.mainnet ? '/preview/wallet' : '/preview/dev/${chain.name}/wallet';

/// A browser has no wallet files from an older app.
Future<bool> _noLegacyFiles(String dataDir) async => false;

const LegacyFiles legacyWalletFiles = _noLegacyFiles;

/// For the log. The browser's own name stays out of it.
String get platformLabel => 'web';

/// The web build has no camera scanner.
bool get hostIsPhone => false;
