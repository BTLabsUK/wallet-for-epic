// SPDX-License-Identifier: Apache-2.0
/// Whether the block explorer has reached a block yet.
///
/// The explorer's indexer can lag the chain by days (2026-11-03: about 3,700 blocks), and its
/// page of a block it has not reached says the search term is wrong. When the explorer link is
/// copied the app asks the explorer's own record of that block once (`explorer.indexed` of
/// `app-config.toml`, through [httpGet], so Tor and the network mode apply), and says so when it
/// is not there yet. Nothing is asked before the press.
library;

import 'dart:convert';

import 'log.dart';
import 'net/http.dart';
import 'settings_file/host_settings.dart' show hostSettings;

/// What the explorer said about a block.
enum ExplorerHas { block, notYet, unknown }

/// The time the one request gets: enough for a Tor exit.
const Duration explorerCheckTimeout = Duration(seconds: 20);

/// Asks the explorer about the block at [height]. [ExplorerHas.unknown] when no record address
/// is configured, the request fails or the answer is not one of the explorer's.
Future<ExplorerHas> explorerHasBlock(int height, {Future<HttpReply> Function(Uri url)? get}) async {
  final address = hostSettings.explorerIndexed(height);
  if (address == null) return ExplorerHas.unknown;
  try {
    final url = Uri.parse(address);
    final reply = await (get ?? (u) => httpGet(u, headers: const {'accept': 'application/json'}, timeout: explorerCheckTimeout, maxBytes: 256 * 1024))(url);
    if (reply.status == 404) return ExplorerHas.notYet;
    if (!reply.ok) return ExplorerHas.unknown;
    // The Epic explorer answers HTTP 200 with its own status: 404 "No Data Found" for a block
    // it has not indexed.
    final body = jsonDecode(reply.body);
    return switch (body is Map ? body['status'] : null) {
      200 => ExplorerHas.block,
      404 => ExplorerHas.notYet,
      _ => ExplorerHas.unknown,
    };
  } on Object catch (e) {
    logInfo('explorer', 'block not checked: ${e.runtimeType}');
    return ExplorerHas.unknown;
  }
}
