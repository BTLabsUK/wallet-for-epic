// SPDX-License-Identifier: Apache-2.0
/// The first-start step on the desktop (`first_start.dart` has the model): the desktop's markers
/// of an earlier install, the launch hold, the first-run tour's settling and Welcome's answer.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../advanced.dart';
import '../../first_run_tour.dart';
import '../../first_start.dart';
import '../../log.dart';
import '../../secret_store_api.dart';
import 'desk_first_run_servers.dart';
import 'desk_store.dart';
import 'state.dart';

/// The keys only a desktop install from before the first-start step holds (`desk_store.dart`):
/// any one present settles the step as answered, never asked.
const List<String> deskExistingInstallMarkers = [
  'desk.settings',
  'desk.prefs',
  'desk.nodes',
  'desk.window',
  'desk.tor_switch',
  'desk.autostart',
  'desk.wallet.mainnet',
  'desk.wallet.floonet',
  'desk.wallet.usernet',
];

/// At launch, before the settings open and before any request ([holdUntilFirstStart] with the
/// desktop's markers). [walletsOnDisk]: whether the data folder already holds a wallet. Such an
/// install is past Welcome, the only screen that answers the step, so it is never held, also
/// when the keychain lost its keys or holds a pending step (a new code signature, a wiped
/// keychain): held, it would reach no node, Epicbox server or site and never be asked.
Future<bool> deskHoldUntilFirstStart(SecretStore store, {Future<bool> Function()? walletsOnDisk}) async {
  try {
    if (walletsOnDisk != null && !firstStartAnswered(await store.read(firstStartKey)) && await walletsOnDisk()) {
      await store.write(firstStartKey, firstStartDone);
      logInfo('first-start', 'a wallet on disk: existing install');
    }
  } on Object catch (e) {
    logWarn('first-start', 'wallets on disk not checked: ${e.runtimeType}');
  }
  return holdUntilFirstStart(store, markers: deskExistingInstallMarkers);
}

/// At launch, first, before this run writes a key ([settleFirstRunTour]): an install that ran
/// before (any of [deskExistingInstallMarkers], the first-start answer, or a wallet on disk) gets
/// [DeskSettings.tourSeen] saved and never the first-run tour by itself. Settings that are not
/// readable JSON are left as they are.
Future<bool> deskSettleFirstRunTour(DeskStore store, {Future<bool> Function()? walletsOnDisk}) => settleFirstRunTour(
  read: store.readText,
  seen: () async => (await store.settings()).tourSeen,
  markSeen: () async {
    if (await store.readText(DeskStore.settingsKey) != null && await store.readJson(DeskStore.settingsKey) is! Map) return;
    await store.saveTourSeen();
  },
  markers: const [...deskExistingInstallMarkers, firstStartKey],
  hasData: walletsOnDisk,
);

/// Welcome's answer ([DeskFirstStart.complete]).
final deskFirstStartProvider = Provider<DeskFirstStart>(DeskFirstStart.new);

class DeskFirstStart {
  DeskFirstStart(this._ref);

  final Ref _ref;

  /// Welcome answered (Create, Import or Restore pressed): Tor only when [undercover] (Tor
  /// builds), and only then the gate opens.
  Future<void> complete({bool undercover = false}) => _ref.read(firstStartProvider.notifier).completeWith(
    undercover: undercover,
    torOnly: () async {
      final s = _ref.read(deskProvider).settings;
      await _ref.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: s.advanced.withMode(NetworkMode.torOnly)));
    },
    pickServers: () => deskFirstRunServers(_ref),
  );
}
