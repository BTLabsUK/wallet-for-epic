// SPDX-License-Identifier: Apache-2.0
/// The web demo's connection to its wallet server, as the UI shows it: a warning while the
/// socket is down, a success notice once it is back, and the unlock screen when the server
/// dropped the open wallet. Nothing here runs unless the wallet is a [RemoteWalletService].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'demo.dart';
import 'l10n.dart';
import 'providers.dart';
import 'remote/client.dart';
import 'ui/launch_screen.dart';
import 'ui/notices.dart';

/// The wallet service when it runs on a server, else null.
final remoteWalletProvider = Provider<RemoteWalletService?>((ref) {
  final service = ref.watch(walletServiceProvider);
  return service is RemoteWalletService ? service : null;
});

/// Every change of the server connection; nothing without [remoteWalletProvider].
final remoteConnectionProvider = StreamProvider<RemoteConnection>(
  (ref) =>
      ref.watch(remoteWalletProvider)?.connectionChanges ?? const Stream.empty(),
);

/// Sessions the server no longer holds.
final lostSessionProvider = StreamProvider<String>(
  (ref) =>
      ref.watch(remoteWalletProvider)?.lostSessions ?? const Stream.empty(),
);

/// The tag of the connection notices, so the success replaces the warning in place.
const String demoConnectionNoticeTag = 'demo-connection';

/// Shows the connection notices and sends the app to the unlock screen when the server
/// dropped the open wallet, as after auto-lock. Leaving a demo (ended, or none) closes the
/// socket instead of retrying. The app root calls it in demo mode, with its navigator.
void listenForDemoConnection(
  WidgetRef ref,
  GlobalKey<NavigatorState> navigator,
) {
  ref.listen(remoteConnectionProvider, (previous, next) {
    final context = navigator.currentContext;
    if (context == null) return;
    final notices = ref.read(noticeProvider.notifier);
    final l = context.l10n;
    switch (next.value) {
      case RemoteConnection.reconnecting:
        logWarn('demo', 'connection lost, reconnecting');
        notices.show(
          l.demoConnectionLost,
          level: NoticeLevel.warning,
          persistent: true,
          tag: demoConnectionNoticeTag,
        );
      case RemoteConnection.connected
          when previous?.value == RemoteConnection.reconnecting:
        logInfo('demo', 'connection back');
        notices.show(
          l.demoConnectionBack,
          level: NoticeLevel.success,
          tag: demoConnectionNoticeTag,
        );
      case RemoteConnection.idle || RemoteConnection.closed:
        notices.dismissTag(demoConnectionNoticeTag);
      case _:
        break;
    }
  });
  ref.listen(lostSessionProvider, (_, next) {
    final handle = next.value;
    final session = ref.read(sessionProvider);
    if (handle == null ||
        session is! RemoteWalletSession ||
        session.handle != handle) {
      return;
    }
    logInfo('session', 'the server dropped the open wallet, locking');
    ref.read(sessionProvider.notifier).lock();
    navigator.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
      (_) => false,
    );
  });
  ref.listen(demoStatusProvider, (_, next) {
    if (next.value case DemoNone() || DemoEnded()) {
      ref.read(remoteWalletProvider)?.disconnect();
    }
  });
}
