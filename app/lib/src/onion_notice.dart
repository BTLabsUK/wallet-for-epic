// SPDX-License-Identifier: Apache-2.0
/// The one notice about the Tor address (LEPIC ADR 0044): the onion got its own key, so this
/// update changed every wallet's Tor address and the old one stopped working. A wallet that
/// existed before the update sees the notice once, on the phone and on the desktop; a wallet
/// made or restored on this version never does. The decision is one marker per wallet in the
/// secret store: absent means the wallet is from before, 'seen' once shown or dismissed, or
/// set at creation. A build without Tor shows nothing.
library;

import 'secret_store_api.dart';
import 'tor_build.dart' as build;

/// The marker's value, once shown, dismissed, or written at creation.
const String onionNoticeSeen = 'seen';

/// The per-wallet marker key: [chain] is [Chain.name], [walletId] null for wallet 1 (the
/// phone's config and the desktop's registry both name it so).
String onionNoticeKey(String chain, String? walletId) => 'onion_notice.$chain.${walletId ?? 'legacy'}';

/// Whether the notice is due for this wallet: a build with Tor, and no marker yet. A store
/// that cannot be read answers no, so a notice never shows twice because of a bad read.
Future<bool> onionNoticeDue(SecretStore store, {required String chain, String? walletId, bool torBuilt = build.torBuilt}) async {
  if (!torBuilt) return false;
  try {
    return await store.read(onionNoticeKey(chain, walletId)) == null;
  } on Object {
    return false;
  }
}

/// Marks the notice as seen for this wallet: after it shows, and at creation or restore, so a
/// wallet made on this version never sees it.
Future<void> markOnionNoticeSeen(SecretStore store, {required String chain, String? walletId}) =>
    store.write(onionNoticeKey(chain, walletId), onionNoticeSeen);
