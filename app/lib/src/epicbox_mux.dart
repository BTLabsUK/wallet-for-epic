// SPDX-License-Identifier: Apache-2.0
/// Push sessions to the Epicbox relays (mux/1) as the app uses them. LEPIC only offers the
/// abilities (`EpicboxPush`); the policy is here: which groups, when to start and stop, when
/// the contacts check may rest.
///
/// With `epicbox.mux` on and a relay that offers mux/1, the payments listener and the contacts
/// share one socket per relay and group, and the relay says when mail comes ([EpicboxMux.mail]).
/// A relay without mux/1 falls back by itself (the listener keeps its own socket, the contacts
/// keep sockets), its session says `notOffered`, and the contacts check runs as before. With
/// `epicbox.mux` off none of this is called.
///
/// Groups: with Tor on the listener is in group `pay` and the contacts in `contacts` (two
/// sockets per relay, so a relay cannot tell the payments address from the contacts by what
/// shares a connection); with Tor off both are in `main` (one socket).
library;

import 'dart:async';

import 'contact_check.dart';
import 'log.dart';
import 'network.dart';
import 'settings_file/host_settings.dart' show AppConfig;
import 'wallet_service.dart';

/// The groups of the payments listener and of the contacts collect.
class MuxGroups {
  const MuxGroups({required this.listener, required this.contacts});

  final String listener;
  final String contacts;
}

/// The app's settings for push sessions, from `[epicbox]` of `app-config.toml`.
class MuxPolicy {
  const MuxPolicy({required this.enabled, required this.waitingEveryS});

  factory MuxPolicy.of(AppConfig c) => MuxPolicy(enabled: c.epicboxMux, waitingEveryS: c.epicboxMuxWaitingCheckS);

  final bool enabled;

  /// How often a session asks the relay whether mail waits, in seconds.
  final int waitingEveryS;

  static const String payGroup = 'pay';
  static const String contactsGroup = 'contacts';
  static const String mainGroup = 'main';

  /// Tor on: two sockets per relay. Tor off: one.
  MuxGroups groupsFor({required bool overTor}) => overTor
      ? const MuxGroups(listener: payGroup, contacts: contactsGroup)
      : const MuxGroups(listener: mainGroup, contacts: mainGroup);
}

/// A relay as `domain:port`, the way a push session names it: a pairing's home relay is
/// `domain[:port]`, port 443 when left out.
String muxRelayKey(String relay) {
  final parsed = EpicboxRelay.parse(relay);
  return parsed == null ? relay.trim().toLowerCase() : '${parsed.host}:${parsed.port}';
}

/// Stands for the wallet's own relay in [muxRelaysOf]: a pairing whose home relay is not known
/// is read there. [EpicboxMux.liveFor] takes it as met by any attached session.
const String muxOwnRelay = '';

/// The relays the contacts check reads: those of the pairings that have not ended.
Set<String> muxRelaysOf(Iterable<PairingRecord> pairings) => {
  for (final r in pairings)
    if (r.state != PairingState.ended) r.homeRelay.trim().isEmpty ? muxOwnRelay : muxRelayKey(r.homeRelay),
};

/// One open wallet's push sessions: starts the listener and the contacts through them, watches
/// them, and says when the contacts check may rest ([liveFor]). Made by [EpicboxMux.of], null
/// when the setting is off or the session cannot.
class EpicboxMux {
  EpicboxMux._(this.session, this._push, this.policy, this.debounce);

  /// The mux of [session], or null when [policy] is off or the session has no push sessions.
  static EpicboxMux? of(
    WalletSession? session,
    MuxPolicy policy, {
    Duration debounce = const Duration(seconds: 1),
  }) {
    final push = session?.push;
    if (session == null || push == null || !policy.enabled) return null;
    return EpicboxMux._(session, push, policy, debounce);
  }

  final WalletSession session;
  final EpicboxPush _push;
  final MuxPolicy policy;

  /// Mail that comes in a burst gives one [mail] event this long after the last.
  final Duration debounce;

  StreamSubscription<PushEvent>? _watch;
  Timer? _debounce;
  final StreamController<void> _mail = StreamController<void>.broadcast();
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// The contacts' group while the contacts are started, else null.
  String? _contactsGroup;
  bool _closed = false;

  /// The relay pushed mail for the contacts collect: debounced, one event per burst.
  Stream<void> get mail => _mail.stream;

  /// A session changed state: [liveFor] may answer otherwise.
  Stream<void> get changes => _changes.stream;

  /// The contacts' group while [startContacts] holds, else null.
  String? get contactsGroup => _contactsGroup;

  /// The groups for the Tor setting now. A session that cannot say counts as Tor off.
  Future<MuxGroups> groups() async {
    var overTor = false;
    try {
      overTor = await session.epicboxOverTor();
    } on Object catch (error) {
      logWarn('mux', 'tor setting unread: ${error.runtimeType}');
    }
    return policy.groupsFor(overTor: overTor);
  }

  /// The payments listener through the push session of its group; the stream of
  /// [WalletSession.startListener] when a relay does not offer mux/1 (LEPIC falls back itself).
  Stream<ListenerEvent> startListener() async* {
    final g = await groups();
    logInfo('mux', 'listener via ${g.listener}');
    yield* _push.startListenerVia(group: g.listener, waitingEveryS: policy.waitingEveryS);
  }

  /// Starts the contacts collect on the push sessions of its group and watches the sessions.
  /// Called after an unlock or open, after a resume, and again after lock then unlock (a lock
  /// forgets it). Failing to start leaves the contacts on sockets.
  Future<void> startContacts() async {
    if (_closed) return;
    final g = await groups();
    if (_closed) return;
    try {
      _watchSessions();
      await _push.contactsPushStart(group: g.contacts, waitingEveryS: policy.waitingEveryS);
      _contactsGroup = g.contacts;
      logInfo('mux', 'contacts via ${g.contacts}');
    } on Object catch (error) {
      _contactsGroup = null;
      logWarn('mux', 'contacts push not started: ${error.runtimeType}');
    }
    if (!_changes.isClosed) _changes.add(null);
  }

  /// The contacts collect uses sockets again, and the sessions are no longer watched. For a
  /// lock; the listener's own stop ends its session.
  Future<void> stopContacts() async {
    _contactsGroup = null;
    _debounce?.cancel();
    _debounce = null;
    try {
      await _push.contactsPushStop();
    } on Object catch (error) {
      logWarn('mux', 'contacts push not stopped: ${error.runtimeType}');
    }
    if (!_changes.isClosed) _changes.add(null);
  }

  void _watchSessions() {
    if (_watch != null) return;
    _watch = _push.watchPushSessions().listen(
      (e) {
        if (e.kind == PushEventKind.mailQueued) {
          // The listener's group is read by the listener; only the contacts' mail asks a collect.
          if (e.group != _contactsGroup) return;
          _debounce?.cancel();
          _debounce = Timer(debounce, () {
            _debounce = null;
            if (!_closed && !_mail.isClosed) _mail.add(null);
          });
        } else if (!_changes.isClosed) {
          _changes.add(null);
        }
      },
      onError: (Object error) => logWarn('mux', 'session watch failed: ${error.runtimeType}'),
    );
  }

  /// The sessions in use now.
  List<PushSession> sessions() {
    try {
      return _push.pushSessions();
    } on Object {
      return const [];
    }
  }

  /// True while the contacts are started and every relay in [relays] (`domain:port`, see
  /// [muxRelayKey]) has an attached session of the contacts' group. No relay in use is not live:
  /// there is nothing to wait for.
  bool liveFor(Set<String> relays) {
    final group = _contactsGroup;
    if (group == null || relays.isEmpty) return false;
    final attached = {
      for (final s in sessions())
        if (s.group == group && s.state == PushState.attached) muxRelayKey(s.relay),
    };
    return relays.every((r) => r == muxOwnRelay ? attached.isNotEmpty : attached.contains(r));
  }

  /// Ends the watch. After this nothing is called on the session.
  void close() {
    _closed = true;
    _debounce?.cancel();
    _debounce = null;
    unawaited(_watch?.cancel());
    _watch = null;
    _contactsGroup = null;
    unawaited(_mail.close());
    unawaited(_changes.close());
  }
}

/// Joins an [EpicboxMux] to a shell's [ContactCheck]: the check rests while the sessions are
/// live ([live]), and reads once when the relay says mail was queued. The shell calls [bind] with
/// the mux it has now (null when none), [relaysChanged] when the pairings change, and [dispose].
class MuxLive {
  MuxLive({required this.relays});

  /// The relays the contacts check reads now ([muxRelaysOf]).
  final Set<String> Function() relays;

  /// The check this feeds; set once it is made.
  ContactCheck? check;

  EpicboxMux? _mux;
  StreamSubscription<void>? _mail;
  StreamSubscription<void>? _changes;

  EpicboxMux? get mux => _mux;

  /// True while every relay in use has an attached session of the contacts' group.
  bool get live => _mux?.liveFor(relays()) ?? false;

  void bind(EpicboxMux? mux) {
    if (identical(mux, _mux)) return;
    unawaited(_mail?.cancel());
    unawaited(_changes?.cancel());
    _mail = _changes = null;
    _mux = mux;
    if (mux != null) {
      _mail = mux.mail.listen((_) => unawaited(check?.pushCollect()));
      _changes = mux.changes.listen((_) => check?.liveChanged());
    }
    check?.liveChanged();
  }

  void relaysChanged() => check?.liveChanged();

  void dispose() {
    unawaited(_mail?.cancel());
    unawaited(_changes?.cancel());
    _mail = _changes = null;
    _mux = null;
  }
}
