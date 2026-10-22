/// The public-node fallback while the local node syncs (decision D-7): the wallet may use one
/// public node until the local node is synced, only after the user said yes once, and the state
/// says so. Never an automatic rotation between public nodes (D4): the one node is the one the
/// user agreed to.
///
/// Pure: the switch itself is the wallet's (it calls [decideFallback] on every local node state
/// and moves its node setting when the answer changes).
library;

import 'local_node_state.dart';

/// The public node the fallback offers.
const String defaultFallbackNodeUrl = 'https://node.btlabs.uk';

enum FallbackConsent {
  /// Not asked yet: the first time the local node syncs, the user is asked.
  unasked,
  accepted,

  /// The wallet waits for the local node; it is not asked again.
  declined,
}

/// The user's answer, with the node it was about. Stored by [NodeSettings].
class FallbackChoice {
  const FallbackChoice(this.consent, {this.nodeUrl = defaultFallbackNodeUrl, this.at});

  const FallbackChoice.unasked() : this(FallbackConsent.unasked);

  final FallbackConsent consent;

  /// The public node the answer was about. A yes is for this node only.
  final String nodeUrl;
  final DateTime? at;

  Map<String, Object?> toJson() => {
    'consent': consent.name,
    'nodeUrl': nodeUrl,
    if (at != null) 'at': at!.toUtc().toIso8601String(),
  };

  /// Garbage gives [FallbackChoice.unasked]; an https URL is required.
  static FallbackChoice fromJson(Object? json) {
    if (json is! Map) return const FallbackChoice.unasked();
    final consent = FallbackConsent.values.where((c) => c.name == json['consent']).firstOrNull;
    final url = json['nodeUrl'];
    final uri = url is String ? Uri.tryParse(url) : null;
    if (consent == null || uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return const FallbackChoice.unasked();
    }
    final at = json['at'];
    return FallbackChoice(consent, nodeUrl: url as String, at: at is String ? DateTime.tryParse(at) : null);
  }

  @override
  bool operator ==(Object other) =>
      other is FallbackChoice && other.consent == consent && other.nodeUrl == nodeUrl && other.at == at;

  @override
  int get hashCode => Object.hash(consent, nodeUrl, at);
}

enum FallbackAction {
  /// The wallet uses the local node.
  useLocal,

  /// The wallet uses [FallbackDecision.nodeUrl] until the local node is synced.
  usePublic,

  /// Ask the user once ("Use node.btlabs.uk until the local node is synced?"); meanwhile the
  /// wallet stays where it is.
  ask,
}

/// What the wallet should do now, and what the status row says.
class FallbackDecision {
  const FallbackDecision(this.action, {this.nodeUrl, required this.localPhase});

  final FallbackAction action;

  /// For [FallbackAction.usePublic] (and [FallbackAction.ask]: the node to ask about).
  final String? nodeUrl;
  final LocalNodePhase localPhase;

  /// The fallback is in use: the status row shows `Local node syncing · using <host>`.
  bool get active => action == FallbackAction.usePublic;

  @override
  bool operator ==(Object other) =>
      other is FallbackDecision && other.action == action && other.nodeUrl == nodeUrl && other.localPhase == localPhase;

  @override
  int get hashCode => Object.hash(action, nodeUrl, localPhase);

  @override
  String toString() => 'FallbackDecision(${action.name}, $nodeUrl, ${localPhase.name})';
}

/// The rule: a synced local node is always used. Otherwise, once the user said yes, the agreed
/// public node is used until then (also while the local node is stopped or failing: the yes was
/// "until it is synced"); after a no the wallet waits on the local node; unasked, the user is
/// asked as soon as the local node is starting or syncing (not while it is stopped: nothing to
/// wait for).
FallbackDecision decideFallback(LocalNodeState local, FallbackChoice choice) {
  final phase = local.phase;
  if (local.online) return FallbackDecision(FallbackAction.useLocal, localPhase: phase);
  return switch (choice.consent) {
    FallbackConsent.accepted => FallbackDecision(FallbackAction.usePublic, nodeUrl: choice.nodeUrl, localPhase: phase),
    FallbackConsent.declined => FallbackDecision(FallbackAction.useLocal, localPhase: phase),
    FallbackConsent.unasked =>
      phase == LocalNodePhase.starting || phase == LocalNodePhase.syncing
          ? FallbackDecision(FallbackAction.ask, nodeUrl: choice.nodeUrl, localPhase: phase)
          : FallbackDecision(FallbackAction.useLocal, localPhase: phase),
  };
}
