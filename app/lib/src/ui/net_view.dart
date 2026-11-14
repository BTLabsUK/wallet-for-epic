// SPDX-License-Identifier: Apache-2.0
/// What the connection mode makes of the status the wallet shows: the one place that turns
/// (connection mode, node and Epicbox state) into the Home pill's mode mark and health. A call
/// site does not decide this itself. The Tor badges come from the same mode through
/// `torWayIn` (`tor_routes.dart`); which services a mode turns off is `network_gate.dart`.
library;

import 'package:flutter/widgets.dart';

import '../advanced.dart';
import 'network_mode_text.dart' show networkModeGlyph;
import 'status.dart';

/// Where Home's connection pill stands. [paused]: the mode connects to nothing (Kill switch),
/// which is a choice, not a fault.
enum HomeConnection { ready, syncing, reconnecting, offline, paused }

/// The mark at the start of the pill: the glyph of the mode in force. Null in Normal, where the
/// pill shows no mode at all.
IconData? netModeMark(NetworkMode mode) => mode == NetworkMode.standard ? null : networkModeGlyph(mode);

/// The pill's health for [status] in [mode], counting only the services the mode uses.
///
/// Normal and Tor only use the node and Epicbox. Node only uses the node alone: Epicbox is off
/// there (the listener reads as connecting only because it is parked), so it never drives the
/// state. Kill switch connects to nothing and reads [HomeConnection.paused].
HomeConnection netHealth(NetworkMode mode, WalletStatus status) {
  if (mode == NetworkMode.killSwitch) return HomeConnection.paused;
  final node = status.node.state;
  final box = mode == NetworkMode.nodeOnly ? null : status.epicbox;
  final boxDown = box == EpicboxState.offline || box == EpicboxState.blocked;
  if (node == NodeState.offline && (boxDown || mode == NetworkMode.nodeOnly)) return HomeConnection.offline;
  if (node == NodeState.offline || node == NodeState.connecting || box == EpicboxState.connecting || boxDown) {
    return HomeConnection.reconnecting;
  }
  if (node == NodeState.syncing) return HomeConnection.syncing;
  return HomeConnection.ready;
}
