/// `wallet_backend.dart` on the phone and desktop: LEPIC in this process, the platform
/// keystore, and wallet directories under the app's support directory.
library;

import 'dart:io';

import 'data_folder_io.dart' show appDataDirectory;

import 'lepic_wallet_service.dart';
import 'secret_store.dart';
import 'vault.dart' show LegacyFiles, setAsideLegacyWalletFiles;
import 'wallet_service.dart';
import 'windows_dpapi.dart';
import 'windows_secret_store.dart';

/// Loads LEPIC's native library. Before any [createWalletService] call.
Future<void> initWalletBackend() => initLepic();

WalletService createWalletService(SecretStore secrets) =>
    LepicWalletService(
      secrets: secrets,
      oneWalletPerChain: true,
      contactsDir: () async => (await appDataDirectory()).path,
    );

/// The platform keystore; on Windows the crash-safe store over the plugin's file
/// (windows_secret_store.dart), one per process so its writes share one lock.
SecretStore createSecretStore() =>
    Platform.isWindows ? _windowsSecrets : const PlatformSecretStore();

final SecretStore _windowsSecrets = WindowsSecretStore(
  directory: () async => (await appDataDirectory()).path,
  cipher: const DpapiCipher(),
  files: const Win32StoreFiles(),
);

/// `<application support>/wallets/<chain>`. One wallet per chain.
Future<String> defaultWalletDir(Chain chain) async {
  final support = await appDataDirectory();
  final sep = Platform.pathSeparator;
  final dir = Directory('${support.path}${sep}wallets$sep${chain.name}');
  await dir.create(recursive: true);
  return dir.path;
}

/// What an older app left in a wallet directory, set aside at launch; its wallet stays.
const LegacyFiles legacyWalletFiles = setAsideLegacyWalletFiles;

/// The operating system and its version, for the log.
String get platformLabel =>
    '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

/// Android or iOS, the platforms with a camera scanner.
bool get hostIsPhone => Platform.isAndroid || Platform.isIOS;
