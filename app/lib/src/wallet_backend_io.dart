/// `wallet_backend.dart` on the phone and desktop: LEPIC in this process, the platform
/// keystore, and wallet directories under the app's support directory.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'lepic_wallet_service.dart';
import 'secret_store.dart';
import 'vault.dart' show LegacyFiles, deleteLegacyWalletFiles;
import 'wallet_service.dart';

/// Loads LEPIC's native library. Before any [createWalletService] call.
Future<void> initWalletBackend() => initLepic();

WalletService createWalletService(SecretStore secrets) =>
    LepicWalletService(secrets: secrets);

SecretStore createSecretStore() => const PlatformSecretStore();

/// `<application support>/wallets/<chain>`. One wallet per chain.
Future<String> defaultWalletDir(Chain chain) async {
  final support = await getApplicationSupportDirectory();
  final sep = Platform.pathSeparator;
  final dir = Directory('${support.path}${sep}wallets$sep${chain.name}');
  await dir.create(recursive: true);
  return dir.path;
}

/// What an older app left in a wallet directory, deleted at launch.
const LegacyFiles legacyWalletFiles = deleteLegacyWalletFiles;

/// The operating system and its version, for the log.
String get platformLabel =>
    '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

/// Android or iOS, the platforms with a camera scanner.
bool get hostIsPhone => Platform.isAndroid || Platform.isIOS;
