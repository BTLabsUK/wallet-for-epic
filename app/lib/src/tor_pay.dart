// SPDX-License-Identifier: Apache-2.0
/// Tor for payments (item 2, the owner 2026-11-01): the Link · Tor switch starts tor just for
/// sending and receiving at the Tor address, without the Tor switch of Network & privacy. The
/// node, Epicbox, Direct http(s) sends, prices and updates keep that setting. Tor only routes
/// everything anyway and changes nothing the user chose; Node only and Kill switch block it.
///
/// [torPayOf] is the state both apps show (the state line under Link · Tor, the title-bar Tor
/// icon); the adapters start and stop tor from the same switch.
library;

import 'advanced.dart' show NetworkMode;
import 'l10n.dart' show AppLocalizations;
import 'tor_routes.dart' show TorState;
import 'ui/network_mode_text.dart' show networkModeName;

/// What Tor for payments is doing.
enum TorPayKind {
  /// Link · Tor is off.
  off,

  /// Tor is connecting, or publishing the onion: sends to onions may already work.
  starting,

  /// The onion is published: payments arrive at the Tor address.
  ready,

  /// Node only or Kill switch: no tor starts for payments ([TorPay.mode] says which).
  blocked,

  /// Tor did not connect or the onion could not be published: Retry.
  failed,
}

/// Tor for payments now.
class TorPay {
  const TorPay(this.kind, {this.onion, this.mode = NetworkMode.standard, this.torAll = false, this.problem});

  static const TorPay off = TorPay(TorPayKind.off);

  final TorPayKind kind;

  /// The wallet's onion, `<56 characters>.onion`, once [kind] is ready; null before.
  final String? onion;

  /// The network mode; the reason when [kind] is blocked.
  final NetworkMode mode;

  /// The Tor switch (or Tor only) carries every connection as well: the caption says so.
  final bool torAll;

  /// Why it failed, in a few words, when known.
  final String? problem;

  @override
  bool operator ==(Object other) =>
      other is TorPay && other.kind == kind && other.onion == onion && other.mode == mode && other.torAll == torAll && other.problem == problem;

  @override
  int get hashCode => Object.hash(kind, onion, mode, torAll, problem);

  @override
  String toString() => 'TorPay(${kind.name}${onion == null ? '' : ', onion'}, ${mode.name}${torAll ? ', all' : ''})';
}

/// Tor for payments from its parts: [linkTor] (the Link · Tor switch), [built] (the build has
/// tor), the network [mode], [torSwitch] (Network & privacy's Tor switch on), [tor] (the
/// wallet's tor process, whoever started it), [published] (its onion is up) and [onion].
TorPay torPayOf({
  required bool linkTor,
  required bool built,
  required NetworkMode mode,
  required bool torSwitch,
  required TorState tor,
  required bool published,
  String? onion,
  String? problem,
}) {
  final torAll = torSwitch || mode == NetworkMode.torOnly;
  if (!linkTor || !built) return TorPay(TorPayKind.off, mode: mode, torAll: torAll);
  if (mode == NetworkMode.nodeOnly || mode == NetworkMode.killSwitch) {
    return TorPay(TorPayKind.blocked, mode: mode, torAll: torAll);
  }
  return switch (tor) {
    TorState.failed => TorPay(TorPayKind.failed, mode: mode, torAll: torAll, problem: problem),
    // Running for sends with the onion not published (its listener or keys failed): Retry.
    TorState.on when !published && problem != null => TorPay(TorPayKind.failed, mode: mode, torAll: torAll, problem: problem),
    TorState.on when published => TorPay(TorPayKind.ready, mode: mode, torAll: torAll, onion: onion),
    _ => TorPay(TorPayKind.starting, mode: mode, torAll: torAll),
  };
}

/// Whether the Link · Tor switch can be changed: not while the mode blocks it.
bool torPayCanSwitch(TorPay p) => p.kind != TorPayKind.blocked;

/// Whether Retry is offered.
bool torPayRetry(TorPay p) => p.kind == TorPayKind.failed;

/// The state line under Link · Tor: what it does now and, when blocked, why.
String torPayLine(AppLocalizations l, TorPay p) => switch (p.kind) {
  TorPayKind.off => l.deskTorPayOff,
  TorPayKind.starting => l.deskTorPayStarting,
  TorPayKind.ready => l.deskTorPayReady,
  TorPayKind.blocked => p.mode == NetworkMode.killSwitch
      ? l.deskTorPayBlockedKill(networkModeName(l, p.mode))
      : l.deskTorPayBlockedNodeOnly(networkModeName(l, p.mode)),
  TorPayKind.failed => p.problem == null || p.problem!.isEmpty ? l.deskTorPayFailed : l.deskTorPayFailedWhy(_noStop(p.problem!)),
};

/// The caption after the state: whether Tor also carries everything else (Network & privacy).
String torPayRestLine(AppLocalizations l, TorPay p) => p.torAll ? l.deskTorPayRestOn : l.deskTorPayRestOff;

String _noStop(String s) => s.endsWith('.') || s.endsWith('。') ? s.substring(0, s.length - 1) : s;
