// SPDX-License-Identifier: Apache-2.0
/// The one state language of both apps: every node, Epicbox, Tor, listener, server-row and
/// payment state the screens show is a [ShownState], which gives its one word, its mark (the
/// dot's shape) and its tone (the dot's and the word's colour role). The desktop's
/// `EStateDot` and the phone's `StateDot` draw a [StateMark] in their own tokens; nothing
/// picks a state colour or word on its own.
///
/// The marks, decided (status-icon-state-language):
/// - [StateMark.ok]: a solid green dot: working, connected, synced, reachable.
/// - [StateMark.busy]: a blue ring: in progress, checking, or not known yet.
/// - [StateMark.problem]: a filled dot with "!": not answering, failed, behind. Red for a
///   fault, amber for a degraded state that still works (behind, slow).
/// - [StateMark.off]: a slash: off by choice, calm, never an error.
///
/// Never the brand gold for a state, and never colour alone: the mark's shape and the word
/// say it too. "On" and "Off" are switch words; a connection is "Connected", a listener
/// "Receiving", a Tor address "Reachable".
library;

import 'l10n.dart' show AppLocalizations;
import 'relay_directory.dart' show NodeHealthState;
import 'tor_routes.dart' show TorState;

/// The shape of a state's dot.
enum StateMark { ok, busy, problem, off }

/// The colour role of a state, which each app maps to its tokens: ok green, info blue, warn
/// amber, risk red, faint grey. Never the accent.
enum StateTone {
  ok(StateMark.ok),
  info(StateMark.busy),
  warn(StateMark.problem),
  risk(StateMark.problem),
  faint(StateMark.off);

  const StateTone(this.mark);

  /// The dot's shape for this tone.
  final StateMark mark;
}

/// Every state a status line, a dot or a server row shows, each with one word everywhere.
enum ShownState {
  /// This wallet's connection works (Epicbox, Tor).
  connected(StateTone.ok),

  /// The node answers at the network's tip.
  synced(StateTone.ok),

  /// A server the status site lists as healthy.
  healthy(StateTone.ok),

  /// A Tor or Link address others can reach.
  reachable(StateTone.ok),

  /// A listener runs and takes payments (Link · HTTP); whether the internet reaches it is a
  /// separate check ([notReachable]).
  receiving(StateTone.ok),

  /// The node answers but is behind the network's tip.
  behind(StateTone.warn),

  /// It works, slowly.
  slow(StateTone.warn),

  /// Published but not reachable yet; sends work.
  notPublished(StateTone.warn),

  /// The node or the wallet catches up.
  syncing(StateTone.info),

  /// A connection is being made.
  connecting(StateTone.info),

  /// A service starts (the local node, the listener).
  starting(StateTone.info),

  /// Its state is being asked right now.
  checking(StateTone.info),

  /// Nothing is known of it yet (no check has answered, the status site has nothing).
  unchecked(StateTone.info),

  /// Epicbox waits for Tor to start.
  waitingTor(StateTone.info),

  /// The Tor address is being published.
  publishing(StateTone.info),

  /// A server or node that does not answer.
  notAnswering(StateTone.risk),

  /// This wallet's connection was lost.
  notConnected(StateTone.risk),

  /// The address is not reachable from the outside: nothing comes in that way.
  notReachable(StateTone.risk),

  /// A listener that should run does not.
  notReceiving(StateTone.risk),

  /// This network blocks it.
  blocked(StateTone.risk),

  /// It failed to start or stopped with an error.
  failed(StateTone.risk),

  /// It runs and makes no progress.
  stalled(StateTone.risk),

  /// Stopped (the local node, by the user).
  stopped(StateTone.faint),

  /// Turned off by its switch.
  off(StateTone.faint);

  const ShownState(this.tone);

  final StateTone tone;

  StateMark get mark => tone.mark;

  /// The state's one word, the same on both apps.
  String word(AppLocalizations l) => switch (this) {
    ShownState.connected => l.netStatusConnected,
    ShownState.synced => l.netStatusSynced,
    ShownState.healthy => l.serverHealthy,
    ShownState.reachable => l.netStatusReachable,
    ShownState.receiving => l.stateReceiving,
    ShownState.behind => l.deskNodeBehind,
    ShownState.slow => l.deskKitMethodSlow,
    ShownState.notPublished => l.deskKitMethodTorNotPublished,
    ShownState.syncing => l.netStatusSyncing,
    ShownState.connecting => l.netStatusConnecting,
    ShownState.starting => l.deskNodeStarting,
    ShownState.checking => l.deskNodeChecking,
    ShownState.unchecked => l.stateUnchecked,
    ShownState.waitingTor => l.deskKitMethodWaitingTor,
    ShownState.publishing => l.netStatusPublishing,
    ShownState.notAnswering => l.deskNodeNotAnswering,
    ShownState.notConnected => l.netStatusNotConnected,
    ShownState.notReachable => l.netStatusNotReachable,
    ShownState.notReceiving => l.deskKitMethodNotReceiving,
    ShownState.blocked => l.netStatusBlocked,
    ShownState.failed => l.deskNodeFailed,
    ShownState.stalled => l.deskNodeStalled,
    ShownState.stopped => l.deskNodeStopped,
    ShownState.off => l.netStatusOff,
  };
}

/// What a server's health from the status site shows: healthy, behind, not answering, or not
/// known yet (null or unknown: a blue ring, never a healthy dot). The server lists' corner dot
/// and the switch rows read this.
ShownState serverHealthState(NodeHealthState? h) => switch (h) {
  NodeHealthState.healthy => ShownState.healthy,
  NodeHealthState.degraded => ShownState.behind,
  NodeHealthState.down => ShownState.notAnswering,
  NodeHealthState.unknown || null => ShownState.unchecked,
};

/// Tor's connection in one word on both apps: Off (its switch), Starting, Connected, Not
/// connected. The rail, the status cards and Settings › Privacy read this, so one page never
/// says two things of Tor (D-04).
ShownState torShownState(TorState s) => switch (s) {
  TorState.off => ShownState.off,
  TorState.starting => ShownState.starting,
  TorState.on => ShownState.connected,
  TorState.failed => ShownState.notConnected,
};
