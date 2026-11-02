// SPDX-License-Identifier: Apache-2.0
/// The servers the mock wallet, the web preview and the screenshot fixtures show: read from the
/// settings in use, so no host name is written in their code. The lists are the shipped ones
/// ([shippedHostSettings]), so the mock's servers do not depend on what a user's file lists; the
/// nth entry of a list wraps round when the settings have fewer.
library;

import '../../settings_file/host_settings.dart';

/// The Epicbox server wallets name in their address.
String get mockBox => hostSettings.epicboxUse;

/// The [i]th Epicbox server of the list.
String mockBoxAt(int i) {
  final all = shippedHostSettings.epicboxServers;
  return all.isEmpty ? mockBox : all[i % all.length].host;
}

/// The [i]th node of the list (its API root, with scheme).
String mockNodeAt(int i) {
  final all = shippedHostSettings.nodeServers;
  return all.isEmpty ? hostSettings.nodeUse : all[i % all.length].url;
}

/// Who runs the [i]th node of the list.
String mockNodeOp(int i) {
  final all = shippedHostSettings.nodeServers;
  return all.isEmpty ? '' : all[i % all.length].operator ?? '';
}

/// Who runs the [i]th Epicbox server of the list.
String mockBoxOp(int i) {
  final all = shippedHostSettings.epicboxServers;
  return all.isEmpty ? '' : all[i % all.length].operator ?? '';
}

/// An operator icon's address on the status site.
String mockIconUrl(String hash, int px) =>
    '${hostSettings.statusIcons ?? ''}$hash-$px.png';

/// An onion address for [name] (56 letters and digits, padded with `a`), built at run time.
String mockOnion(String name) => '${name.padRight(56, 'a')}.${'onion'}';

/// A host of the status site's own (a page address), read from the settings.
String get mockStatusUrl => hostSettings.statusDirectory ?? '';

/// The onion the fake and mock wallets answer for their own address.
String get fakeWalletOnion =>
    mockOnion('wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid');
