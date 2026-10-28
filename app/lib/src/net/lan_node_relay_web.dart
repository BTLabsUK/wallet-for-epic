// SPDX-License-Identifier: Apache-2.0
/// `lan_node_relay.dart` on the web: the browser reaches no node on the local network.
library;

bool needsPlainHttpConsent(String url) => false;

Future<void> allowPlainHttpNode(String url) async {}
