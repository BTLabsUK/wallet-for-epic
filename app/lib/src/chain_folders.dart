// SPDX-License-Identifier: Apache-2.0
/// Where each chain's data lives in the app's data folder. Mainnet, the only network a user
/// sees, has the plain paths with no chain in them. A hidden dev chain (floonet, usernet) keeps
/// all its data under `<app data>/dev/<chain>`, apart from mainnet's.
library;

import 'dart:io';

import 'models.dart' show Chain;

/// The folder [chain]'s data hangs from: [appData] itself on mainnet, else
/// `<appData>/dev/<chain>`.
String chainHome(String appData, Chain chain) {
  if (chain == Chain.mainnet) return appData;
  final sep = Platform.pathSeparator;
  return '${_trim(appData)}${sep}dev$sep${chain.name}';
}

/// The folder [folder] (a path in the app's data folder) stands for on [chain]: [folder] itself
/// on mainnet, else the same name under the dev chain's home, `<parent>/dev/<chain>/<name>`.
String chainFolder(String folder, Chain chain) {
  if (chain == Chain.mainnet) return folder;
  final trimmed = _trim(folder);
  final cut = trimmed.lastIndexOf(RegExp(r'[\\/]'));
  final parent = cut <= 0 ? trimmed.substring(0, cut + 1) : trimmed.substring(0, cut);
  final home = chainHome(parent, chain);
  return '$home${Platform.pathSeparator}${trimmed.substring(cut + 1)}';
}

String _trim(String path) {
  var p = path;
  while (p.length > 1 && (p.endsWith('/') || p.endsWith(r'\'))) {
    p = p.substring(0, p.length - 1);
  }
  return p;
}
