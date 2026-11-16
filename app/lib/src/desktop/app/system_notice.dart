// SPDX-License-Identifier: Apache-2.0
/// The operating system's own notification for an arriving payment, shown only while the wallet
/// window is not in front (minimised, behind another window, or hidden to the tray). The words
/// are the in-app notice's; a click on it brings the window back and opens the payment. Settings ›
/// Appearance › System notifications turns it off.
///
/// `flutter_local_notifications` carries it on Windows (toast), macOS (UserNotifications) and
/// Linux (org.freedesktop.Notifications over D-Bus). It sends nothing anywhere: every call stays
/// on this computer. macOS asks for permission when the first notification would show, not at
/// startup.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../log.dart';
import '../data/models.dart' show IncomingPayment;
import '../data/state.dart' show deskApiProvider;

/// What the shell asks of the system's notifications.
abstract class DeskSystemNotifier {
  const DeskSystemNotifier();

  /// Shows [title] over [body]; [payload] comes back through [onTap] when it is clicked.
  /// Returns whether it was shown (false: refused by the user, or no notification service).
  Future<bool> show({required String title, required String body, required String payload, required String openLabel});

  /// Called with a notification's payload when the user clicks it.
  set onTap(void Function(String? payload)? run);
}

/// Shows nothing: tests, the web build, a platform with no notifications.
class NoSystemNotifier extends DeskSystemNotifier {
  const NoSystemNotifier();

  @override
  Future<bool> show({required String title, required String body, required String payload, required String openLabel}) async => false;

  @override
  set onTap(void Function(String? payload)? run) {}
}

/// The notifier [DeskApp] uses; main_desktop.dart puts in the real one.
final deskSystemNotifierProvider = Provider<DeskSystemNotifier>((ref) => const NoSystemNotifier());

/// Payments the wallet has just accepted, as the wallet API reports them.
final deskIncomingProvider = StreamProvider<IncomingPayment>((ref) => ref.watch(deskApiProvider).incomingPayments());

/// Whether this platform has the real notifier.
bool get deskSystemNoticesSupported => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

/// The plugin-backed notifier; set up on the first notification.
class PluginSystemNotifier extends DeskSystemNotifier {
  PluginSystemNotifier();

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;
  int _next = 1;
  void Function(String? payload)? _tap;

  @override
  set onTap(void Function(String? payload)? run) => _tap = run;

  Future<bool> _init(String openLabel) async {
    try {
      final ok = await _plugin.initialize(
        settings: InitializationSettings(
          linux: LinuxInitializationSettings(defaultActionName: openLabel),
          // Permission is asked for at the first notification (below), not here.
          macOS: DarwinInitializationSettings(requestAlertPermission: false, requestSoundPermission: false, requestBadgePermission: false),
          windows: WindowsInitializationSettings(
            appName: 'BT Wallet', // l10n-ok: the app's product name
            appUserModelId: 'uk.btlabs.epiccash.desktop',
            guid: '6f3c2c52-1d0e-4a57-9f2b-7c1a5d8e4b90',
          ),
        ),
        onDidReceiveNotificationResponse: (r) => _tap?.call(r.payload),
      );
      if (Platform.isMacOS) {
        final mac = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
        return await mac?.requestPermissions(alert: true, sound: true) ?? false;
      }
      return ok ?? true;
    } on Object catch (e) {
      logWarn('notify', 'system notifications unavailable (${e.runtimeType})');
      return false;
    }
  }

  @override
  Future<bool> show({required String title, required String body, required String payload, required String openLabel}) async {
    final ready = await (_ready ??= _init(openLabel));
    if (!ready) return false;
    try {
      await _plugin.show(
        id: _next++,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          linux: LinuxNotificationDetails(),
          macOS: DarwinNotificationDetails(),
          windows: WindowsNotificationDetails(),
        ),
        payload: payload,
      );
      return true;
    } on Object catch (e) {
      logWarn('notify', 'system notification not shown (${e.runtimeType})');
      return false;
    }
  }
}
