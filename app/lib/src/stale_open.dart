// SPDX-License-Identifier: Apache-2.0
/// The notice on opening a wallet that was not opened for a while ("Last opened 9 days ago.
/// Checking paired contacts."). The record is the wallet's last activity
/// (`Meta.lastActivity`, read as the session opened it); the limit is `contacts.stale_after_days`
/// of `app-config.toml`. Phone and desktop show the text their own way.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'settings_file/host_settings.dart' show appConfig, hostSettingsLoaded;
import 'wallet_service.dart';

/// Whole days since [session]'s wallet was last active, when that is more than the limit; null
/// when there is no record, the clock is behind it, or it is recent enough.
int? staleOpenDays(WalletSession? session, DateTime now) {
  final last = session?.lastActivityAtOpen;
  if (last == null || !hostSettingsLoaded) return null;
  final ago = now.toUtc().difference(last);
  return ago > appConfig.contactsStaleAfter ? ago.inDays : null;
}

/// The session the notice was already decided for, so it shows once per open.
final staleOpenShownProvider = NotifierProvider<StaleOpenShown, WalletSession?>(StaleOpenShown.new);

class StaleOpenShown extends Notifier<WalletSession?> {
  @override
  WalletSession? build() => null;

  /// The days to say for the open wallet, once; null when the notice is not due or was handed out.
  int? take(DateTime now) {
    final session = ref.read(sessionProvider);
    if (session == null || identical(state, session)) return null;
    state = session;
    return staleOpenDays(session, now);
  }
}
