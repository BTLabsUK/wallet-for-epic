/// When the wallet tells the push service about this phone, and when it takes that back.
///
/// The user's one saved intent is "wanted" (`app.push`, the Settings switch). Notifications are
/// in effect while it is on and this wallet's Tor is off: a registration would show the phone's
/// address to the relay, so Tor on unregisters and forgets the device token first, and Tor off
/// registers again with a new token. `services/push/PROTOCOL.md` has the wire side; the
/// requests are `push_registration.dart`.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'demo.dart';
import 'phone_tor.dart';
import 'providers.dart';
import 'push.dart';
import 'push_registration.dart';
import 'settings.dart';
import 'tor_phone.dart';
import 'tor_routes.dart';
import 'wallet_service.dart';

/// What the user is told, in the app's words (`app.dart` shows it, where the language is known).
enum PushNote { on, off, available }

/// One thing to tell the user; every event is a new object, so the same note again shows again.
class PushNoteEvent {
  const PushNoteEvent(this.note);

  final PushNote note;
}

final pushNoteProvider = NotifierProvider<PushNoteNotifier, PushNoteEvent?>(
  PushNoteNotifier.new,
);

class PushNoteNotifier extends Notifier<PushNoteEvent?> {
  @override
  PushNoteEvent? build() => null;

  void say(PushNote note) => state = PushNoteEvent(note);
}

/// Saved once the reminder was shown, so it never comes again.
const String pushHintShownKey = 'app.push_hint_shown';

/// How long after the first unlock of a run the reminder waits.
const Duration pushHintDelay = Duration(seconds: 60);

/// The most the Tor switch waits for the unregister and the token deletion before tor starts.
const Duration pushTorOnCap = Duration(seconds: 5);

final pushControllerProvider = NotifierProvider<PushController, bool>(
  PushController.new,
);

/// The Tor switch's hooks for push (`main.dart` puts them in [torSwitchHooksProvider]).
final pushTorHooksProvider = Provider<TorSwitchHooks>((ref) {
  final push = ref.read(pushControllerProvider.notifier);
  return TorSwitchHooks(beforeOn: push.beforeTorOn, afterOff: push.afterTorOff);
});

/// State: whether the relay accepted this phone's registration in the open wallet's session.
/// Something always alive must watch it (`app.dart`), so it follows every unlock.
class PushController extends Notifier<bool> {
  Timer? _hint;
  bool _hintScheduled = false;

  /// The token the relay accepted in this session.
  String? _registered;

  /// Registrations one after the other, so a token change and an unlock never overlap.
  Future<void> _work = Future.value();

  late final PushRegistration _registration = PushRegistration(
    post: (url, body, timeout) => ref.read(pushPostProvider)(url, body, timeout),
    now: () => ref.read(clockProvider)(),
    clearnet: _torOffNow,
  );

  @override
  bool build() {
    ref.onDispose(() => _hint?.cancel());
    ref.listen(sessionProvider, (previous, session) {
      _registered = null;
      state = false;
      if (session == null) {
        _hint?.cancel();
        _hint = null;
      } else if (!identical(previous, session)) {
        unawaited(_unlocked(session));
      }
    });
    // Built after the wallet opened (by a hook, or a Settings tap): treat it as the unlock.
    final open = ref.read(sessionProvider);
    if (open != null) scheduleMicrotask(() => unawaited(_unlocked(open)));
    // A new token from Firebase: register it.
    ref.listen(pushProvider.select((s) => s.token), (_, token) {
      if (token != null) unawaited(_serial(() => _registerToken(token)));
    });
    return false;
  }

  /// This wallet's Tor is off right now, by the state the app routes by.
  bool _torOffNow() =>
      torWay(TorRoute.push, phoneTorState(ref.read(phoneTorProvider))) ==
      TorWay.clearnet;

  /// The saved Tor switch is on for this wallet: tor starts with it, and until the controller
  /// has read that, its state says off.
  Future<bool> _torSavedOn() async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return false;
    final saved = await ref
        .read(secretStoreProvider)
        .read(PhoneTor.receivingKey(config));
    if (saved != 'true') return false;
    return await ref.read(torBundleFinderProvider)() != null;
  }

  Future<bool> _clearnet() async => _torOffNow() && !await _torSavedOn();

  /// Pushes exist here: a phone build with Firebase configured, not the demo.
  Future<bool> _available() async {
    if (ref.read(demoModeProvider)) return false;
    return await ref.read(pushConfiguredProvider.future);
  }

  Future<bool> _wanted() async =>
      (await ref.read(appSettingsProvider.future)).pushNotifications;

  Future<void> _setWanted(bool on) =>
      ref.read(appSettingsProvider.notifier).setPushNotifications(on);

  Future<T> _serial<T>(Future<T> Function() task) {
    final run = _work.then((_) => task());
    _work = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  // Unlock.

  Future<void> _unlocked(WalletSession session) async {
    await _sync(session);
    if (!identical(ref.read(sessionProvider), session)) return;
    await _scheduleHint();
  }

  /// Starts Firebase and registers, when notifications are wanted and Tor is off. [fresh] asks
  /// for a new token (after Tor), [announce] says "Notifications on" once it is registered.
  Future<void> _sync(
    WalletSession session, {
    bool fresh = false,
    bool announce = false,
  }) async {
    if (!await _available() || !await _wanted() || !await _clearnet()) return;
    if (!identical(ref.read(sessionProvider), session)) return;
    final push = ref.read(pushProvider.notifier);
    if (!await push.start()) {
      // Denied in system settings, or Firebase failed: Settings says why.
      await _setWanted(false);
      return;
    }
    final token = fresh
        ? await push.freshToken()
        : ref.read(pushProvider).token;
    if (token == null) return;
    final outcome = await _serial(() => _registerToken(token, session: session));
    if (announce && outcome == PushOutcome.sent) {
      ref.read(pushNoteProvider.notifier).say(PushNote.on);
    }
  }

  /// Registers [token] unless the relay already has it in this session, or notifications are
  /// not in effect now.
  Future<PushOutcome> _registerToken(String token, {WalletSession? session}) async {
    final open = ref.read(sessionProvider);
    if (open == null || (session != null && !identical(open, session))) {
      return PushOutcome.skipped;
    }
    if (_registered == token) return PushOutcome.sent;
    if (!await _available() || !await _wanted() || !await _clearnet()) {
      return PushOutcome.skipped;
    }
    final outcome = await _registration.register(open, token);
    if (outcome == PushOutcome.sent && identical(ref.read(sessionProvider), open)) {
      _registered = token;
      state = true;
    }
    return outcome;
  }

  // The Settings switch.

  /// Turns notifications on: saved first, then permission and the registration. False when
  /// the system denied permission or Firebase failed (the switch goes back off), or Tor is on.
  Future<bool> turnOn() async {
    final session = ref.read(sessionProvider);
    if (session == null || !await _available() || !await _clearnet()) return false;
    await _setWanted(true);
    final push = ref.read(pushProvider.notifier);
    if (!await push.start()) {
      await _setWanted(false);
      return false;
    }
    final token = ref.read(pushProvider).token;
    if (token != null) await _serial(() => _registerToken(token, session: session));
    return true;
  }

  /// Turns notifications off for good: unregisters and drops the device token when Tor is
  /// off (with Tor on there is nothing registered and nothing is sent).
  Future<void> turnOff() async {
    final session = ref.read(sessionProvider);
    final token = ref.read(pushProvider).token;
    final torOff = await _clearnet();
    await _setWanted(false);
    _registered = null;
    state = false;
    ref.read(pushNoteProvider.notifier).say(PushNote.off);
    if (torOff) {
      if (session != null && token != null) {
        await _registration.unregister(session, token);
      }
      await ref.read(pushProvider.notifier).deleteToken();
    }
  }

  // The Tor switch.

  /// Before tor starts: unregister over the clearnet and drop the device token, within
  /// [pushTorOnCap] together; the token goes even when the unregister fails or is slow (the
  /// service expires the registration). Wanted stays: it is the memory of "was on".
  Future<void> beforeTorOn() async {
    if (!await _available() || !await _wanted()) return;
    final session = ref.read(sessionProvider);
    final token = ref.read(pushProvider).token;
    _registered = null;
    state = false;
    final unregister = () async {
      try {
        // A registration still going out finishes first, so it cannot land after this.
        await _work;
        if (session != null && token != null) {
          await _registration.unregister(session, token, timeout: pushTorOnCap);
        }
      } catch (_) {}
    }();
    final drop = ref.read(pushProvider.notifier).deleteToken();
    try {
      await Future.wait([unregister, drop]).timeout(pushTorOnCap);
    } on TimeoutException {
      logWarn('push', 'before Tor: gave up waiting');
    }
  }

  /// After tor stopped and the clearnet is back: a fresh token, registered, and "Notifications
  /// on", when they were wanted still.
  Future<void> afterTorOff() async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    await _sync(session, fresh: true, announce: true);
  }

  // The reminder.

  /// Once per install, about a minute into the first unlock of a run: tells that notifications
  /// exist, if they are off and Tor is not on.
  Future<void> _scheduleHint() async {
    if (_hintScheduled) return;
    if (!await _available() || await _wanted()) return;
    if (await ref.read(secretStoreProvider).read(pushHintShownKey) == 'true') {
      return;
    }
    if (ref.read(sessionProvider) == null) return;
    _hintScheduled = true;
    _hint = Timer(pushHintDelay, () => unawaited(_hintDue()));
  }

  Future<void> _hintDue() async {
    _hint = null;
    if (ref.read(sessionProvider) == null) return;
    if (!await _available() || await _wanted() || !await _clearnet()) return;
    final store = ref.read(secretStoreProvider);
    if (await store.read(pushHintShownKey) == 'true') return;
    await store.write(pushHintShownKey, 'true');
    ref.read(pushNoteProvider.notifier).say(PushNote.available);
  }
}
