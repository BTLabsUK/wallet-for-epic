// SPDX-License-Identifier: Apache-2.0
/// Where a restore or a recheck starts scanning, picked as a month (the owner, 2026-11-01): the
/// year and the month the wallet was made, no day. The scan starts from the first of that
/// month, less the margin [mainnetHeightForDate] keeps. The phone's picker (`ui/month_picker.dart`)
/// and the desktop's (`desktop/widgets/start_date.dart`) share this file: the months offered,
/// the month a picker opens on, the warning rule and the height a month maps to.
library;

import 'dart:math' show max;

import 'package:flutter/foundation.dart' show immutable;

/// Mainnet block 1 was mined at 2019-09-03T02:10:08Z (`get_header` at height 1 on
/// the built-in node, checked 2026-09-30). The genesis block is dated 2019-08-09T17:04:38Z, 24 days
/// earlier; counting from genesis at 60 s per block overshoots real heights by up to 20,000
/// blocks, which would skip outputs, so the estimate counts from block 1.
const int mainnetBlockOneUnix = 1567476608;

/// Target block time. Real blocks averaged 58.6 to 59.8 s from block 1, so the estimate runs
/// behind the chain, which is the safe side: the scan starts early rather than late.
const int blockSeconds = 60;

/// Two days of blocks subtracted on top, for clock skew and the day boundary.
const int restoreMarginBlocks = 2 * 24 * 3600 ~/ blockSeconds;

/// A mainnet height at or before the first block mined on [date]. Checked against real headers
/// from height 100,000 to 3,700,000: the estimate was 13,600 to 65,100 blocks early.
BigInt mainnetHeightForDate(DateTime date) {
  final seconds = date.toUtc().millisecondsSinceEpoch ~/ 1000 - mainnetBlockOneUnix;
  final estimate = 1 + seconds ~/ blockSeconds - restoreMarginBlocks;
  return BigInt.from(max(1, estimate));
}

/// The first day a mainnet wallet can hold funds.
final DateTime mainnetFirstDay = DateTime(2019, 9, 3);

/// A calendar month: what the start pickers offer and return.
@immutable
class StartMonth implements Comparable<StartMonth> {
  const StartMonth(this.year, this.month) : assert(month >= 1 && month <= 12);

  /// The month [date] falls in.
  StartMonth.of(DateTime date) : this(date.year, date.month);

  final int year;

  /// 1 for January to 12 for December.
  final int month;

  /// The first of the month, local midnight: what the scan starts from.
  DateTime get firstDay => DateTime(year, month);

  /// The height a scan from this month starts at.
  BigInt get height => mainnetHeightForDate(firstDay);

  StartMonth get previous => month == 1 ? StartMonth(year - 1, 12) : StartMonth(year, month - 1);

  @override
  int compareTo(StartMonth other) => year != other.year ? year - other.year : month - other.month;

  bool operator <(StartMonth other) => compareTo(other) < 0;
  bool operator >(StartMonth other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) => other is StartMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}

/// The first month a wallet can have been made in: September 2019, block 1's.
final StartMonth firstStartMonth = StartMonth.of(mainnetFirstDay);

/// Where a restore, and a Recheck balance with a start, scan from on mainnet unless the user
/// chooses (the owner, 2026-11-03): January 2025. "Scan from the start" is block 0.
const StartMonth defaultStartMonth = StartMonth(2025, 1);

/// The years a picker offers, oldest first: 2019 to [now]'s.
List<int> startYears(DateTime now) => [for (var y = firstStartMonth.year; y <= now.year; y++) y];

/// Whether [m] can be picked: from [firstStartMonth] to [now]'s month, never a later one.
bool startMonthOffered(StartMonth m, DateTime now) => !(m < firstStartMonth) && !(m > StartMonth.of(now));

/// The year a picker opens on: the chosen month's, else the wallet era's first (never today,
/// which would invite a start that misses coins).
int startPickerYear(StartMonth? chosen) => chosen?.year ?? firstStartMonth.year;

/// The picked month says older coins may be missed: it is [now]'s month or the one before.
bool startMonthRecent(StartMonth m, DateTime now) => !(m < StartMonth.of(now).previous);
