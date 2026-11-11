// SPDX-License-Identifier: Apache-2.0
/// Signed announcements from BT Labs (`announcements.json`, announcements spec §2 to §7): the
/// app-wide service that fetches, verifies, keeps and exposes the messages. UI-neutral: it
/// shows nothing itself; a screen reads [announcementsProvider] and calls [AnnouncementsNotifier.markSeen]
/// and [AnnouncementsNotifier.dismiss].
///
/// One plain GET of the feed (`[announcements] feed` of `app-config.toml`), through [httpGet]:
/// no User-Agent, no cookies, no conditional headers. First after `first_check_s`, then every
/// `check_every_h`, while the switch (Settings › Advanced, `online.announcements`) is on and the
/// app is in the foreground. Node only, Kill switch (and the web demo) fetch nothing. A file
/// that does not verify is dropped with one log line; the last accepted one stays.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show AppLifecycleListener, AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../advanced.dart' show NetworkMode;
import '../btlabs_keys.dart';
import '../btlabs_public.dart';
import '../log.dart';
import '../net/http.dart';
import '../network_gate.dart';
import '../providers.dart' show secretStoreProvider;
import '../secret_store_api.dart';
import '../settings_file/host_settings.dart' show HostSettings, hostSettings, hostSettingsLoaded;
import '../settings_file/settings_providers.dart' show hostSettingsProvider;

/// Where the phone keeps the last accepted file, the seen times and the dismissed ids.
const String announcementsPhoneKey = 'app.announcements';

/// Where the desktop keeps them (the desktop's saved state, `desk.*`).
const String announcementsDeskKey = 'desk.announcements';

/// Whether the app offers announcements at all: a feed in `app-config.toml` and not the web
/// demo. Without it Settings shows no switch.
bool announcementsOffered(HostSettings s) => !kIsWeb && s.announcementsFeedUrl != null;

/// What a fetch needs and the clock: when to ask and how long to wait.
typedef AnnouncementsSchedule = ({Duration first, Duration every, Duration timeout});

/// Fetches the feed file; null when it did not answer with one (offline, refused by the
/// network mode or Tor, over the size cap, timed out, not 200).
typedef AnnouncementsFetch = Future<String?> Function(Uri url, Duration timeout);

/// The default fetch: a plain [httpGet], capped at [btlabsMaxEnvelopeBytes], no extra headers.
Future<String?> fetchAnnouncements(Uri url, Duration timeout) async {
  try {
    final r = await httpGet(url, timeout: timeout, maxBytes: btlabsMaxEnvelopeBytes);
    return r.status == 200 ? r.body : null;
  } on Object {
    return null;
  }
}

/// The feed's URL; null = the feature is off with no switch. Tests replace it.
final announcementsFeedProvider = Provider<Uri?>((ref) {
  if (kIsWeb || !hostSettingsLoaded) return null;
  final url = ref.watch(hostSettingsProvider.select((s) => s.announcementsFeedUrl));
  return url == null ? null : Uri.parse(url);
});

/// The user's switch (`online.announcements`, on unless set off). Tests replace it.
final announcementsOnProvider = Provider<bool>((ref) {
  if (!hostSettingsLoaded) return false;
  return ref.watch(hostSettingsProvider.select((s) => s.announcementsEnabled));
});

/// First check, interval and timeout from `app-config.toml`. Tests replace it.
final announcementsScheduleProvider = Provider<AnnouncementsSchedule>((ref) {
  if (!hostSettingsLoaded) {
    return (first: const Duration(seconds: 45), every: const Duration(hours: 6), timeout: const Duration(seconds: 30));
  }
  final c = hostSettings.config;
  return (first: c.announcementsFirstCheck, every: c.announcementsEvery, timeout: c.announcementsTimeout);
});

/// The platform a message is for: `phone` (the default) or `desktop` (overridden in
/// `main_desktop.dart`).
final announcementsPlatformProvider = Provider<String>((ref) => 'phone');

/// The store key: the desktop's saved state or the phone's, by [announcementsPlatformProvider].
final announcementsStoreKeyProvider = Provider<String>(
  (ref) => ref.watch(announcementsPlatformProvider) == 'desktop' ? announcementsDeskKey : announcementsPhoneKey,
);

/// Whether the schedule and edge timers run. Off under `flutter test`, as the other app-wide
/// timers (a widget test ends with none pending); the service tests drive `checkNow`.
final announcementsTimersProvider = Provider<bool>((ref) => kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST'));

/// The fetch. Tests replace it with a fake.
final announcementsFetchProvider = Provider<AnnouncementsFetch>((ref) => fetchAnnouncements);

/// The clock. Tests replace it.
final announcementsClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The keys that may sign the feed. Tests replace it.
final announcementsKeyringProvider = Provider<Keyring>((ref) => announcementsKeyring);

/// What the screens read: the messages to show now and which of them were seen.
class AnnouncementsState {
  /// Creates a state.
  const AnnouncementsState({this.live = const [], this.seen = const {}});

  /// Live messages: the feed accepted and unexpired, `starts_at` ≤ now < `ends_at`, this
  /// platform, not dismissed. At most 4, in the feed's order. Empty while the switch is off.
  final List<Announcement> live;

  /// Id → when the message was first on screen (UTC), for the ids of the accepted feed.
  final Map<String, DateTime> seen;

  /// Whether [id] has been on screen once.
  bool isSeen(String id) => seen.containsKey(id);

  /// Live messages not yet seen, in order.
  List<Announcement> get unseen => [
    for (final m in live)
      if (!seen.containsKey(m.id)) m,
  ];
}

/// The app-wide announcements service. Read it once at the app's start so it runs.
final announcementsProvider = NotifierProvider<AnnouncementsNotifier, AnnouncementsState>(
  AnnouncementsNotifier.new,
);

/// Loads the kept file, fetches on schedule, keeps `seen` and `dismissed`.
class AnnouncementsNotifier extends Notifier<AnnouncementsState> {
  Timer? _fetchTimer;
  Timer? _edgeTimer;
  AppLifecycleListener? _life;
  StreamSubscription<NetworkMode>? _gate;

  String? _envelope;
  ManifestState? _manifest;
  AnnouncementsFeed? _feed;
  final Map<String, DateTime> _seen = {};
  final Set<String> _dismissed = {};

  bool _foreground = true;
  bool _loaded = false;
  bool _loading = false;
  bool _fetching = false;
  DateTime? _lastCheck;
  Future<void> _writes = Future.value();

  SecretStore get _store => ref.read(secretStoreProvider);
  DateTime _now() => ref.read(announcementsClockProvider)().toUtc();
  bool get _on => ref.read(announcementsOnProvider) && ref.read(announcementsFeedProvider) != null && !kIsWeb;

  @override
  AnnouncementsState build() {
    ref.onDispose(() {
      _fetchTimer?.cancel();
      _edgeTimer?.cancel();
      _life?.dispose();
      _gate?.cancel();
    });
    try {
      _life = AppLifecycleListener(onStateChange: _lifecycle);
    } on Object {
      // No widgets binding (a plain unit test): always in the foreground.
    }
    // The switch: off cancels the timers and shows nothing; on fetches once now.
    ref.listen<bool>(announcementsOnProvider, (_, on) => on ? _switchedOn() : _switchedOff());
    // The network mode opening again (first-start answer, leaving Node only): arm the check.
    _gate = NetGate.changes.listen((_) {
      if (!NetGate.restricted && _loaded && _fetchTimer == null) _arm();
    });
    // The kept file is read once the switch is on; with it off nothing is read.
    if (_on) unawaited(_load());
    return const AnnouncementsState();
  }

  // ------------------------------------------------------------------ public

  /// The message has been on screen once: remembered (first time only).
  Future<void> markSeen(String id) async {
    if (_seen.containsKey(id) || !state.live.any((m) => m.id == id)) return;
    _seen[id] = _now();
    _publish();
    await _persist();
  }

  /// The user closed the message: it never shows again (while its id is in the feed).
  Future<void> dismiss(String id) async {
    if (_dismissed.contains(id) || !(_feed?.messages.any((m) => m.id == id) ?? false)) return;
    _dismissed.add(id);
    _publish();
    await _persist();
  }

  /// Fetches now, when allowed (switch on, feed set, network mode open). For the switch and tests.
  Future<void> checkNow() => _fetch();

  /// The app came to the front (true) or went to the background (false). The lifecycle
  /// listener calls it; tests call it too.
  void setForeground(bool foreground) {
    if (_foreground == foreground) return;
    _foreground = foreground;
    if (foreground) {
      _arm();
    } else {
      _fetchTimer?.cancel();
      _fetchTimer = null;
    }
  }

  // ------------------------------------------------------------------ inside

  void _lifecycle(AppLifecycleState s) => setForeground(switch (s) {
    AppLifecycleState.resumed || AppLifecycleState.inactive => true,
    AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached => false,
  });

  void _switchedOn() {
    if (!_loaded) {
      unawaited(_load(fetchNow: true));
      return;
    }
    _publish();
    unawaited(_fetch().whenComplete(_arm));
  }

  void _switchedOff() {
    _fetchTimer?.cancel();
    _fetchTimer = null;
    _edgeTimer?.cancel();
    _edgeTimer = null;
    state = const AnnouncementsState();
  }

  Future<void> _load({bool fetchNow = false}) async {
    if (_loading) return;
    _loading = true;
    try {
      final text = await _store.read(ref.read(announcementsStoreKeyProvider));
      if (!ref.mounted) return;
      if (text != null) await _restore(text);
    } on Object catch (e) {
      logInfo('announce', 'kept announcements not read: ${e.runtimeType}');
    }
    _loading = false;
    if (!ref.mounted) return;
    _loaded = true;
    _publish();
    if (fetchNow && _on) {
      unawaited(_fetch().whenComplete(_arm));
    } else {
      _arm();
    }
  }

  Future<void> _restore(String text) async {
    final j = jsonDecode(text);
    if (j is! Map) return;
    final seen = j['seen'];
    if (seen is Map) {
      for (final e in seen.entries) {
        final t = e.value is String ? DateTime.tryParse(e.value as String) : null;
        if (e.key is String && t != null) _seen[e.key as String] = t.toUtc();
      }
    }
    final dismissed = j['dismissed'];
    if (dismissed is List) _dismissed.addAll(dismissed.whereType<String>());
    final envelope = j['envelope'];
    final manifest = ManifestState.fromJson(j['state']);
    if (envelope is! String || manifest == null) return;
    // Re-checked on load: trusted signer, valid signature, the payload the state names.
    final feed = await loadCachedAnnouncements(envelope, keyring: ref.read(announcementsKeyringProvider), state: manifest);
    if (!ref.mounted) return;
    if (feed == null) {
      logInfo('announce', 'kept announcements.json not used: failed the check');
      return;
    }
    _envelope = envelope;
    _manifest = manifest;
    _feed = feed;
  }

  /// Arms the next fetch: after `first_check_s` when none ran yet, else `check_every_h` after the
  /// last. Nothing while the switch is off, the feed unset or the app in the background.
  void _arm() {
    _fetchTimer?.cancel();
    _fetchTimer = null;
    if (!ref.mounted || !_loaded || !_on || !_foreground || !ref.read(announcementsTimersProvider)) return;
    final schedule = ref.read(announcementsScheduleProvider);
    final last = _lastCheck;
    final Duration wait;
    if (last == null) {
      wait = schedule.first;
    } else {
      final due = schedule.every - _now().difference(last);
      wait = due.isNegative ? Duration.zero : due;
    }
    _fetchTimer = Timer(wait, () {
      _fetchTimer = null;
      unawaited(_fetch().whenComplete(_arm));
    });
  }

  Future<void> _fetch() async {
    final url = ref.read(announcementsFeedProvider);
    if (url == null || !_on || kIsWeb || NetGate.restricted || _fetching) return;
    _fetching = true;
    try {
      final keyring = ref.read(announcementsKeyringProvider);
      final body = await ref.read(announcementsFetchProvider)(url, ref.read(announcementsScheduleProvider).timeout);
      if (!ref.mounted || !_on) return; // switched off while it ran: nothing is used.
      _lastCheck = _now();
      if (body == null) return;
      final r = await verifyAnnouncements(body, keyring: keyring, state: _manifest, now: _now());
      if (!ref.mounted || !_on) return;
      switch (r) {
        case Rejected(:final reason):
          logInfo('announce', 'announcements.json not used: ${reason.code}');
        case Accepted(:final manifest, :final state):
          _envelope = body;
          _manifest = state;
          _feed = manifest;
          final ids = {for (final m in manifest.messages) m.id};
          _seen.removeWhere((id, _) => !ids.contains(id));
          _dismissed.removeWhere((id) => !ids.contains(id));
          _publish();
          await _persist();
      }
    } on Object catch (e) {
      logInfo('announce', 'announcements.json not read: ${e.runtimeType}');
    } finally {
      _fetching = false;
    }
  }

  /// Recomputes [state] from the kept feed and the clock, and arms the timer for the next
  /// moment a message starts, ends or the feed expires.
  void _publish() {
    if (!ref.mounted) return;
    _edgeTimer?.cancel();
    _edgeTimer = null;
    final feed = _feed;
    if (!_on || feed == null) {
      state = const AnnouncementsState();
      return;
    }
    final now = _now();
    final platform = ref.read(announcementsPlatformProvider);
    final live = <Announcement>[];
    DateTime? next;
    void edge(DateTime? t) {
      if (t != null && t.isAfter(now) && (next == null || t.isBefore(next!))) next = t;
    }

    if (feed.expiresAt.isAfter(now)) {
      edge(feed.expiresAt);
      for (final m in feed.messages) {
        edge(m.startsAt);
        edge(m.endsAt);
        final started = m.startsAt == null || !m.startsAt!.isAfter(now);
        final notEnded = m.endsAt == null || m.endsAt!.isAfter(now);
        final here = m.platforms == null || m.platforms!.contains(platform);
        if (started && notEnded && here && !_dismissed.contains(m.id)) live.add(m);
      }
    }
    state = AnnouncementsState(live: List.unmodifiable(live), seen: Map.unmodifiable(_seen));
    final at = next;
    if (at != null && ref.read(announcementsTimersProvider)) {
      _edgeTimer = Timer(at.difference(now), _publish);
    }
  }

  Future<void> _persist() {
    final text = jsonEncode({
      if (_envelope != null) 'envelope': _envelope,
      if (_manifest != null) 'state': _manifest!.toJson(),
      'seen': {for (final e in _seen.entries) e.key: e.value.toUtc().toIso8601String()},
      'dismissed': _dismissed.toList()..sort(),
    });
    final key = ref.read(announcementsStoreKeyProvider);
    final store = _store;
    // One write at a time, in order.
    return _writes = _writes.then((_) => store.write(key, text)).catchError((Object e) {
      logInfo('announce', 'announcements not kept: ${e.runtimeType}');
    });
  }
}
