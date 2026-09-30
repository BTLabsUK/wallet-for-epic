/// Firebase Cloud Messaging on Android: permission, the device token, and what arrives.
///
/// A push only says "a transaction is waiting on the relay". It carries no amount or sender and
/// nothing is signed from it: opening the app and unlocking lets the epicbox listener collect the
/// slate as usual. Registering the token with a relay webhook comes with the relay change.
library;

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';

/// What the app knows about pushes on this device.
class PushState {
  const PushState({
    this.token,
    this.permitted = false,
    this.blocked = false,
    this.unavailable = false,
    this.last,
  });

  /// The FCM registration token, once Firebase has one.
  final String? token;

  /// The user allowed notifications.
  final bool permitted;

  /// The last start found notification permission denied in system settings.
  final bool blocked;

  /// The last start failed for another reason, such as a build without Firebase configuration.
  final bool unavailable;

  /// The latest push received while the app was in the foreground.
  final RemoteMessage? last;
}

abstract interface class PushPlatform {
  /// Whether this build carries a Firebase configuration, found without starting Firebase.
  Future<bool> configured();

  /// Initialises Firebase and asks for notification permission. Returns whether it was granted.
  Future<bool> start();

  Future<String?> token();

  Stream<String> get tokenRefresh;

  /// Pushes that arrive while the app is in the foreground.
  Stream<RemoteMessage> get foreground;
}

class FirebasePushPlatform implements PushPlatform {
  const FirebasePushPlatform();

  static const MethodChannel _channel = MethodChannel('epic_wallet/push');

  @override
  Future<bool> configured() async {
    try {
      return await _channel.invokeMethod<bool>('configured') ?? true;
    } on MissingPluginException {
      // An older native side cannot say; let a start attempt decide.
      return true;
    }
  }

  @override
  Future<bool> start() async {
    await Firebase.initializeApp();
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> token() => FirebaseMessaging.instance.getToken();

  @override
  Stream<String> get tokenRefresh => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<RemoteMessage> get foreground => FirebaseMessaging.onMessage;
}

/// Null where FCM is not available: desktop, web, tests.
final pushPlatformProvider = Provider<PushPlatform?>((ref) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  return const FirebasePushPlatform();
});

/// Whether to offer the notifications switch at all: false where FCM is missing, or where the
/// build has no Firebase configuration (`google-services.json` absent at build time).
final pushConfiguredProvider = FutureProvider<bool>((ref) async {
  final platform = ref.watch(pushPlatformProvider);
  return platform != null && await platform.configured();
});

final pushProvider = NotifierProvider<PushNotifier, PushState>(
  PushNotifier.new,
);

class PushNotifier extends Notifier<PushState> {
  final List<StreamSubscription<Object>> _subscriptions = [];
  bool _started = false;

  @override
  PushState build() {
    ref.onDispose(() {
      for (final s in _subscriptions) {
        s.cancel();
      }
    });
    return const PushState();
  }

  /// Starts once per process. Returns false when pushes stay off: the system denied notification
  /// permission ([PushState.blocked]) or Firebase failed to start ([PushState.unavailable]). A
  /// start that returned false does not count, so turning notifications on again tries again.
  Future<bool> start() async {
    final platform = ref.read(pushPlatformProvider);
    if (platform == null || _started) return true;
    _started = true;
    try {
      final permitted = await platform.start();
      if (!permitted) {
        logInfo('push', 'notification permission denied');
        _started = false;
        state = PushState(token: state.token, blocked: true, last: state.last);
        return false;
      }
      final token = await platform.token();
      // Never the token itself: it addresses pushes to this device.
      logInfo(
        'push',
        'started, ${token == null ? 'no token yet' : 'token received'}',
      );
      state = PushState(token: token, permitted: permitted);
      _subscriptions
        ..add(
          platform.tokenRefresh.listen((t) {
            state = PushState(
              token: t,
              permitted: state.permitted,
              last: state.last,
            );
          }),
        )
        ..add(
          platform.foreground.listen((m) {
            state = PushState(
              token: state.token,
              permitted: state.permitted,
              last: m,
            );
          }),
        );
    } catch (error, stack) {
      logError('push', 'setup failed: $error', stack);
      _started = false;
      state = PushState(unavailable: true, last: state.last);
      return false;
    }
    return true;
  }
}
