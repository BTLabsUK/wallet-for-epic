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
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the app knows about pushes on this device.
class PushState {
  const PushState({this.token, this.permitted = false, this.last});

  /// The FCM registration token, once Firebase has one.
  final String? token;

  /// The user allowed notifications.
  final bool permitted;

  /// The latest push received while the app was in the foreground.
  final RemoteMessage? last;
}

abstract interface class PushPlatform {
  /// Initialises Firebase and asks for notification permission. Returns whether it was granted.
  Future<bool> start();

  Future<String?> token();

  Stream<String> get tokenRefresh;

  /// Pushes that arrive while the app is in the foreground.
  Stream<RemoteMessage> get foreground;
}

class FirebasePushPlatform implements PushPlatform {
  const FirebasePushPlatform();

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

  /// Starts once per process. Failures leave pushes off; the wallet works without them.
  Future<void> start() async {
    final platform = ref.read(pushPlatformProvider);
    if (platform == null || _started) return;
    _started = true;
    try {
      final permitted = await platform.start();
      final token = await platform.token();
      if (kDebugMode) debugPrint('FCM token: $token');
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
    } catch (error) {
      debugPrint('push setup failed: $error');
    }
  }
}
