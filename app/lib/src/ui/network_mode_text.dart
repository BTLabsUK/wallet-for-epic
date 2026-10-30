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

/// The one line under a mode's radio row. [desktop]: the Normal line says "under Privacy".
/// [tor]: false in the build without Tor.
String networkModeLine(AppLocalizations l, NetworkMode m, {bool desktop = false, bool? tor}) {
  final withTor = tor ?? torBuilt;
  return switch (m) {
    NetworkMode.standard => !withTor ? l.advModeStandardLineNoTor : (desktop ? l.deskSetAdvModeStandardText : l.advModeStandardLine),
    NetworkMode.torOnly => l.advModeTorOnlyLine,
    NetworkMode.nodeOnly => l.advModeNodeOnlyLine,
    NetworkMode.killSwitch => l.advModeKillSwitchLine,
  };
}

/// The info text behind a mode's ⓘ.
String networkModeHint(AppLocalizations l, NetworkMode m, {bool desktop = false, bool? tor}) {
  final withTor = tor ?? torBuilt;
  return switch (m) {
    NetworkMode.standard => !withTor ? l.advModeStandardHintNoTor : (desktop ? l.deskSetAdvModeStandardHint : l.advModeStandardHint),
    NetworkMode.torOnly => l.advModeTorOnlyHint,
    NetworkMode.nodeOnly => withTor ? l.advModeNodeOnlyHint : l.advModeNodeOnlyHintNoTor,
    NetworkMode.killSwitch => l.advModeKillSwitchHint,
  };
}

/// The info text behind the Network header.
String networkHeaderHint(AppLocalizations l, {bool? tor}) => (tor ?? torBuilt) ? l.advNetworkHint : l.advNetworkHintNoTor;

/// The dim line under the picker for the chosen mode; null for Normal.
String? networkModeSwitchNote(AppLocalizations l, NetworkMode m) => switch (m) {
  NetworkMode.standard => null,
  NetworkMode.torOnly => l.advModeSwitchNoteTorOnly,
  NetworkMode.nodeOnly => l.advModeSwitchNoteNodeOnly,
  NetworkMode.killSwitch => l.advModeSwitchNoteKillSwitch,
};

/// The mode mark popover's line. [waitingForTor]: Tor only and Tor is not ready.
String networkModeMarkLine(AppLocalizations l, NetworkMode m, {bool waitingForTor = false}) => switch (m) {
  NetworkMode.standard => '',
  NetworkMode.torOnly => waitingForTor ? l.netMarkLineTorWaiting : l.netMarkLineTorOnly,
  NetworkMode.nodeOnly => l.netMarkLineNodeOnly,
  NetworkMode.killSwitch => l.netMarkLineKillSwitch,
};

/// "Off (Node only)": the state word of a service the mode turns off.
String statusOffByModeWord(AppLocalizations l, NetworkMode m) => l.statusOffByMode(networkModeName(l, m));

/// Whether a send waiting for its recipient is paused by switching to [target]: an Epicbox or
/// Link send waits on a listener that Node only and Kill switch stop.
bool switchPausesSends(NetworkMode target) => target == NetworkMode.nodeOnly || target == NetworkMode.killSwitch;
