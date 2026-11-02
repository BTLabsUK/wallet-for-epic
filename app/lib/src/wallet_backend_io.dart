// SPDX-License-Identifier: Apache-2.0
/// `wallet_backend.dart` on the phone and desktop: LEPIC in this process, the platform
/// keystore, and wallet directories under the app's support directory.
library;

import 'dart:io';

import 'package:flutter_riverpod/misc.dart' show Override;

import 'data_folder_io.dart' show appDataDirectory;

import 'lepic_wallet_service.dart';
import 'secret_store.dart';
import 'vault.dart' show LegacyFiles, setAsideLegacyWalletFiles;
import 'wallet_registry.dart' show WalletRegistry;
import 'wallet_service.dart';
import 'windows_dpapi.dart';
import 'windows_secret_store.dart';

/// Nothing to change at start: only the web preview has overrides.
List<Override> backendOverrides() => const [];

/// Loads LEPIC's native library. Before any [createWalletService] call.
Future<void> initWalletBackend() => initLepic();

/// How the app tells whether a wallet opens with its Tor switch on, asked before each session
/// opens ([LepicWalletService.torWantedFor]): the session then waits for tor from its first
/// connection and never goes directly, also when no tor bundle is found.
void wantTorAtOpen(Future<bool> Function(WalletConfig config) wanted) => LepicWalletService.torWantedFor = wanted;

WalletService createWalletService(SecretStore secrets) =>
    LepicWalletService(
      secrets: secrets,
      oneWalletPerChain: true,
      contactsDir: () async => (await appDataDirectory()).path,
      // Android: the PIN key and failure count under a Keystore key (pin_wrap.dart). iOS has
      // no channel for it yet; desktop opens with a password, not a PIN.
      keyWrap: Platform.isAndroid ? const PlatformKeyWrap() : null,
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

/// `<application support>/wallets/<chain>` ([WalletRegistry.firstWalletDir]). One wallet per
/// chain.
Future<String> defaultWalletDir(Chain chain) async {
  final support = await appDataDirectory();
  final dir = Directory(WalletRegistry.firstWalletDir(support.path, chain));
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
