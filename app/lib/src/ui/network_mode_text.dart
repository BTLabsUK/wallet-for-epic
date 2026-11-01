// SPDX-License-Identifier: Apache-2.0
/// The network modes in words and glyphs, one place for the phone and the desktop: a mode's name,
/// its one-line description, its info text, the note under the picker, the mode mark's glyph and
/// the Off (mode) word of a service the mode turns off. The rule that decides what a mode
/// blocks is `network_gate.dart`; nothing here decides anything.
library;

import 'package:flutter/widgets.dart';

import '../advanced.dart';
import '../l10n.dart';
import '../network_gate.dart';
import '../text_join.dart' show metaLine;
import '../tor_build.dart';
import 'status_icons.dart';

/// The modes the picker offers: Tor only is left out of the build without Tor.
List<NetworkMode> offeredNetworkModes({bool? tor}) => [
  for (final m in NetworkMode.values)
    if (m != NetworkMode.torOnly || (tor ?? torBuilt)) m,
];

/// A network mode's name.
String networkModeName(AppLocalizations l, NetworkMode m) => switch (m) {
  NetworkMode.standard => l.advModeStandard,
  NetworkMode.torOnly => l.advModeTorOnly,
  NetworkMode.nodeOnly => l.advModeNodeOnly,
  NetworkMode.killSwitch => l.advModeKillSwitch,
};

/// The mode a [NetBlock] by the mode names; null for the other blocks.
NetworkMode? blockMode(NetBlock b) => switch (b) {
  NetBlock.nodeOnly => NetworkMode.nodeOnly,
  NetBlock.killSwitch => NetworkMode.killSwitch,
  _ => null,
};

/// The glyph of a mode's mark. Normal has none (the mark is not shown there).
IconData networkModeGlyph(NetworkMode m) => switch (m) {
  NetworkMode.standard => EpicGlyphs.http,
  NetworkMode.torOnly => EpicGlyphs.tor,
  NetworkMode.nodeOnly => EpicGlyphs.nodeOnly,
  NetworkMode.killSwitch => EpicGlyphs.unplugged,
};

/// The info text behind a mode's ⓘ. Normal names the Tor switch (right below the modes on
/// Network & privacy, on both apps), so the build without Tor gets its own line. [desktop] is
/// kept for callers; both apps read the same words.
String networkModeHint(AppLocalizations l, NetworkMode m, {bool desktop = false, bool? tor}) {
  final withTor = tor ?? torBuilt;
  return switch (m) {
    NetworkMode.standard => withTor ? l.advModeStandardHintHere : l.advModeStandardHintNoTor,
    NetworkMode.torOnly => l.advModeTorOnlyHint,
    NetworkMode.nodeOnly => l.advModeNodeOnlyHint,
    NetworkMode.killSwitch => l.advModeKillSwitchHint,
  };
}

/// Network & privacy in one line, under its entry in Settings (the phone's hub row, the
/// desktop's section list): the mode, then the Tor switch where the mode leaves it to the user
/// ("Normal · Tor off"). Tor only and Kill switch decide Tor themselves, and a build without
/// Tor ([tor] false) has no switch: the mode alone.
String networkSummary(AppLocalizations l, NetworkMode mode, {required bool torOn, bool? tor}) {
  final name = networkModeName(l, mode);
  if (!(tor ?? torBuilt) || mode == NetworkMode.torOnly || mode == NetworkMode.killSwitch) return name;
  return metaLine([name, torOn ? l.netSummaryTorOn : l.netSummaryTorOff]);
}

/// The mode mark popover's line. [waitingForTor]: Tor only and Tor is not ready.
String networkModeMarkLine(AppLocalizations l, NetworkMode m, {bool waitingForTor = false}) => switch (m) {
  NetworkMode.standard => '',
  NetworkMode.torOnly => waitingForTor ? l.netMarkLineTorWaiting : l.netMarkLineTorOnly,
  NetworkMode.nodeOnly => l.netMarkLineNodeOnly,
  NetworkMode.killSwitch => l.netMarkLineKillSwitch,
};

/// "Off (Node only)": the state word of a service the mode turns off.
String statusOffByModeWord(AppLocalizations l, NetworkMode m) => l.statusOffByMode(networkModeName(l, m));

/// Why a link does not open the system browser now (the mode refuses it: Tor only can't carry
/// the browser, Node only and Kill switch connect to nothing else); the screen shows the
/// address to copy beside it.
String browserOffNote(AppLocalizations l) =>
    NetGate.torOnly ? l.browserOffTorOnly : l.browserOffMode(networkModeName(l, NetGate.mode));

/// Whether a send waiting for its recipient is paused by switching to [target]: an Epicbox or
/// Link send waits on a listener that Node only and Kill switch stop.
bool switchPausesSends(NetworkMode target) => target == NetworkMode.nodeOnly || target == NetworkMode.killSwitch;
