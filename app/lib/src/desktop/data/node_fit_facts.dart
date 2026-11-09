// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'desk_store.dart';

/// What the local node's fit check (`screens/settings/node_fit_check.dart`) reads from this
/// computer besides the node facts: how long the wallet was open lately, whether the
/// connection is metered, and whether the person asked not to see the check again.
///
/// The hours stay on this computer, in the [DeskStore] under [openHoursKey]: seconds per local
/// day, the last [openHoursDays] days. Nothing here is sent anywhere.
class NodeFitFacts {
  const NodeFitFacts(this._store);

  final DeskStore? _store;

  static const openHoursKey = 'desk.open_hours';
  static const skipKey = 'desk.node_fit';
  static const openHoursDays = 7;

  /// How often the shell adds the time the wallet was open.
  static const tick = Duration(minutes: 5);

  static String _day(DateTime t) => '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  Future<Map<String, int>> _days() async {
    final j = await _store?.readJson(openHoursKey);
    if (j is! Map<String, dynamic>) return {};
    return {for (final e in j.entries) if (e.value is int) e.key: e.value as int};
  }

  /// Adds [open] to today's count and drops the days older than [openHoursDays].
  Future<void> addOpen(Duration open, {DateTime? now}) async {
    final store = _store;
    if (store == null) return;
    final t = now ?? DateTime.now();
    final days = await _days();
    final today = _day(t);
    days[today] = (days[today] ?? 0) + open.inSeconds;
    final keep = {for (var i = 0; i <= openHoursDays; i++) _day(DateTime(t.year, t.month, t.day - i))};
    days.removeWhere((k, _) => !keep.contains(k));
    await store.writeJson(openHoursKey, days);
  }

  /// Hours a day the wallet was open, over the whole days since counting began (at most
  /// [openHoursDays], today left out). Null before one whole day is counted.
  Future<double?> hoursPerDay({DateTime? now}) async => openHoursPerDay(await _days(), now ?? DateTime.now());

  /// Whether the connection is metered, as Windows reports it; null elsewhere or when it
  /// cannot be told.
  Future<bool?> metered() async => !kIsWeb && Platform.isWindows ? windowsMetered() : null;

  Future<bool> skip() async {
    final j = await _store?.readJson(skipKey);
    return j is Map<String, dynamic> && j['skip'] == true;
  }

  Future<void> setSkip(bool skip) async => _store?.writeJson(skipKey, {'skip': skip});
}

/// [NodeFitFacts.hoursPerDay] over [days] (seconds per `yyyy-mm-dd`).
double? openHoursPerDay(Map<String, int> days, DateTime now) {
  if (days.isEmpty) return null;
  final first = days.keys.reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
  var seconds = 0;
  var counted = 0;
  for (var i = 1; i <= NodeFitFacts.openHoursDays; i++) {
    final day = NodeFitFacts._day(DateTime(now.year, now.month, now.day - i));
    if (day.compareTo(first) < 0) break;
    seconds += days[day] ?? 0;
    counted++;
  }
  return counted == 0 ? null : seconds / counted / 3600;
}

/// The connection's cost type from Windows (WinRT NetworkInformation, through PowerShell, the
/// way `builtin_node.dart` asks about processes): metered when the plan is fixed or variable,
/// not metered when unrestricted, null when there is no answer.
Future<bool?> windowsMetered() async {
  try {
    final r = await Process.run('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-WindowStyle',
      'Hidden',
      '-Command',
      '[void][Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]; '
          '\$p = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile(); '
          'if (\$p) { \$p.GetConnectionCost().NetworkCostType }',
    ]).timeout(const Duration(seconds: 8));
    return switch ((r.stdout as String).trim()) {
      'Unrestricted' => false,
      'Fixed' || 'Variable' => true,
      _ => null,
    };
  } on Object {
    return null;
  }
}

final nodeFitFactsProvider = Provider<NodeFitFacts>((ref) => NodeFitFacts(ref.watch(deskStoreProvider)));
