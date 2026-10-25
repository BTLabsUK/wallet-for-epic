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
import 'network_gate.dart';
import 'phone_tor.dart';
import 'providers.dart';
import 'push.dart';
import 'push_registration.dart';
import 'settings.dart';
import 'tor_phone.dart';
import 'tor_routes.dart';
import 'wallet_service.dart';

/// What the user is told, in the app's words (`app.dart` shows it, where the language is known).
enum PushNote { on, off, offEpicbox, available }

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

/// How long the Epicbox relay must stay put before push follows it: a run of quick switches
/// counts once, by the relay the wallet ends on.
const Duration pushRelaySettle = Duration(seconds: 2);

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

  /// Waits [pushRelaySettle] after the last relay switch before push follows it.
  Timer? _relaySettle;

  /// The token the relay accepted in this session.
  String? _registered;

  /// Registrations one after the other, so a token change and an unlock never overlap.
  Future<void> _work = Future.value();

  /// The switch's on and off, one after the other: an on tapped while the
  /// off still unregisters and deletes the token waits for it, and never registers that token.
  Future<void> _switching = Future.value();

  late final PushRegistration _registration = PushRegistration(
    post: (url, body, timeout) => ref.read(pushPostProvider)(url, body, timeout),
    now: () => ref.read(clockProvider)(),
    clearnet: _torOffNow,
  );

  @override
  bool build() {
    ref.onDispose(() {
      _hint?.cancel();
      _relaySettle?.cancel();
    });
    ref.listen(sessionProvider, (previous, session) {
      _registered = null;
      state = false;
      _relaySettle?.cancel();
      _relaySettle = null;
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
    // The relay switched live (Settings › Node and Epicbox): registered on the BT Labs relay,
    // unregistered when the wallet leaves it (pushes from there would announce slates this
    // listener no longer collects). The device token stays: only Tor and the switch delete it.
    // Quick switches count once: push follows the relay the wallet is on once it stays put.
    ref.listen(walletConfigProvider.select((c) => c?.epicboxDomain), (before, after) {
      final session = ref.read(sessionProvider);
      if (before == after || session == null) return;
      _relaySettle?.cancel();
      _relaySettle = Timer(pushRelaySettle, () {
        _relaySettle = null;
        if (identical(ref.read(sessionProvider), session)) {
          unawaited(_followRelay(session));
        }
      });
    });
    // Back to Standard from Tor only or Offline: registers again when notifications are on.
    ref.listen(networkModeProvider, (before, after) {
      final session = ref.read(sessionProvider);
      if (before == after || session == null || !pushAllowed(after)) return;
      unawaited(_sync(session, why: 'network mode'));
    });
    // Epicbox turned off (Settings › Transactions): notifications go off with it, and stay
    // off when it comes back (the switch is the user's), with one notice.
    ref.listen(appSettingsProvider.select((s) => s.value?.payments.epicbox), (before, after) {
      if (before != true || after != false) return;
      unawaited(_exclusive(() async {
        if (!(await ref.read(appSettingsProvider.future)).pushNotifications) return;
        await _turnOff(note: PushNote.offEpicbox);
      }));
    });
    // A new token from Firebase: register it.
    ref.listen(pushProvider.select((s) => s.token), (_, token) {
      if (token != null) unawaited(_serial(() => _registerToken(token)));
    });
    return false;
  }

  /// This wallet's Tor is off right now, by the state the app routes by.
  /// Tor only and Offline never register (network_gate.dart, [torWayIn]).
  bool _torOffNow() =>
      torWayIn(TorRoute.push, phoneTorState(ref.read(phoneTorProvider)), NetGate.mode) ==
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

  /// Notifications are on, and so is Epicbox (they ride on it: Settings › Transactions).
  Future<bool> _wanted() async {
    final s = await ref.read(appSettingsProvider.future);
    return s.pushNotifications && s.payments.epicbox;
  }

  Future<void> _setWanted(bool on) =>
      ref.read(appSettingsProvider.notifier).setPushNotifications(on);

  Future<T> _serial<T>(Future<T> Function() task) {
    final run = _work.then((_) => task());
    _work = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  Future<T> _exclusive<T>(Future<T> Function() task) {
    final run = _switching.then((_) => task());
    _switching = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  // The relay.

  /// The open wallet's Epicbox relay is the BT Labs one, the only one that pushes.
  bool _onPushRelay() =>
      ref.read(walletConfigProvider)?.epicboxDomain == PushRegistration.relayHost;

  /// Brings the registration in line with the relay the wallet is on now: registered on the
  /// BT Labs relay (when notifications are in effect), unregistered on any other.
  Future<void> _followRelay(WalletSession session) async {
    if (_onPushRelay()) return _sync(session, why: 'relay switched');
    await _serial(() async {
      // Back on the BT Labs relay by now: that move has its own turn.
      if (_onPushRelay()) return;
      final token = _registered;
      if (token == null) {
        logInfo('push', 'relay switched: nothing registered, nothing to take back');
        return;
      }
      _registered = null;
      state = false;
      if (!identical(ref.read(sessionProvider), session)) return;
      logInfo('push', 'relay switched off the push relay: unregistering');
      await _registration.unregister(session, token);
    });
  }

  // Unlock.

  Future<void> _unlocked(WalletSession session) async {
    await _sync(session, why: 'unlocked');
    if (!identical(ref.read(sessionProvider), session)) return;
    await _scheduleHint();
  }

  /// Starts Firebase and registers, when notifications are wanted and Tor is off. [fresh] asks
  /// for a new token (after Tor), [announce] says "Notifications on" once it is registered.
  /// [why], when given, is logged with the reason nothing was sent.
  Future<void> _sync(
    WalletSession session, {
    bool fresh = false,
    bool announce = false,
    String? why,
  }) async {
    void skipped(String reason) {
      if (why != null) logInfo('push', '$why: register skipped, $reason');
    }

    if (!await _available()) return skipped('not available in this build');
    if (!await _wanted()) return skipped('notifications are off');
    if (!await _clearnet()) return skipped('Tor is on');
    if (!identical(ref.read(sessionProvider), session)) return;
    final push = ref.read(pushProvider.notifier);
    if (!await push.start()) {
      // Denied in system settings, or Firebase failed: Settings says why.
      await _setWanted(false);
      return;
    }
    final token = fresh
        ? await push.freshToken()
        : ref.read(pushProvider).token ?? await push.freshToken();
    if (token == null) return skipped('no device token');
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
    // The wallet left the BT Labs relay while this waited its turn (the request checks the
    // address too).
    final relay = ref.read(walletConfigProvider)?.epicboxDomain;
    if (relay != null && relay != PushRegistration.relayHost) {
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
  Future<bool> turnOn() => _exclusive(_turnOn);

  Future<bool> _turnOn() async {
    final session = ref.read(sessionProvider);
    if (session == null || !await _available() || !await _clearnet()) return false;
    await _setWanted(true);
    final push = ref.read(pushProvider.notifier);
    if (!await push.start()) {
      await _setWanted(false);
      return false;
    }
    // Turned off before in this run: that deleted the token, so ask for a new one.
    final token = ref.read(pushProvider).token ?? await push.freshToken();
    if (token != null) await _serial(() => _registerToken(token, session: session));
    return true;
  }

  /// Turns notifications off for good: unregisters and drops the device token when Tor is
  /// off (with Tor on there is nothing registered and nothing is sent).
  Future<void> turnOff() => _exclusive(_turnOff);

  Future<void> _turnOff({PushNote note = PushNote.off}) async {
    final session = ref.read(sessionProvider);
    final token = ref.read(pushProvider).token;
    final torOff = await _clearnet();
    await _setWanted(false);
    _registered = null;
    state = false;
    ref.read(pushNoteProvider.notifier).say(note);
    if (torOff) {
      if (session != null && token != null) {
        await _registration.unregister(session, token);
      }
      await ref.read(pushProvider.notifier).deleteToken();
    }
  }

  // Delete.

  /// Before the wallet is deleted: takes this phone's registration back from the relay, so
  /// pushes for the deleted wallet's address stop. With the wallet open, an unregister it signs
  /// (within [pushTorOnCap]); either way the device token goes too, which ends a registration
  /// the relay still holds (Forgot PIN has no open wallet to sign with). The next wallet
  /// registers with a fresh token. The Settings switch stays as it is.
  Future<void> beforeDelete() async {
    if (!await _available()) return;
    final session = ref.read(sessionProvider);
    final token = _registered ?? ref.read(pushProvider).token;
    final wanted = await _wanted();
    _registered = null;
    state = false;
    try {
      await Future.wait([
        () async {
          // A registration still going out finishes first, so it cannot land after this.
          await _work;
          if (session != null && token != null) {
            logInfo('push', 'wallet deleted: unregistering');
            await _registration.unregister(session, token, timeout: pushTorOnCap);
          }
        }(),
        if (wanted || token != null)
          () async {
            final push = ref.read(pushProvider.notifier);
            // Not started in this run (Forgot PIN on a cold start): the token lives on in
            // Firebase all the same. Permission was given when notifications were turned on.
            if (wanted) await push.start();
            await push.deleteToken();
          }(),
      ]).timeout(pushTorOnCap);
    } catch (error) {
      logWarn('push', 'before delete: ${error.runtimeType}');
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
