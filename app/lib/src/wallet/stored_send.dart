// SPDX-License-Identifier: Apache-2.0
/// What a failed send left in the wallet, one answer for the phone and the desktop (AU-10).
///
/// LEPIC stores an Epicbox, HTTP or Tor send and locks its coins before it delivers, so a
/// delivery that fails leaves the payment waiting (resend or cancel). Its error does not name
/// that payment, so the rows before the send and after the failure are compared here: take a
/// [SendBefore] right before the send, and [SendBefore.leftBehind] after it failed.
library;

import '../models.dart';
import '../wallet_service.dart' show WalletSession;

/// How a stored send's recipient is matched to the address it was sent to.
enum SentToMatch {
  /// The row's recipient is the address as given (Epicbox).
  exact,

  /// The row names no recipient, or one that contains the address's host (HTTP, Tor).
  host,
}

/// The wallet's rows (and, when asked, its spendable balance) right before a send.
class SendBefore {
  SendBefore._(this._session, this._keys, this._spendable);

  final WalletSession _session;
  final Set<String> _keys;
  final BigInt? _spendable;

  /// Reads the rows of [session] as they are now, without a refresh; with
  /// [minimumConfirmations] also its spendable balance, so [StoredSend.nothingStored] can tell.
  static Future<SendBefore> take(WalletSession session, {BigInt? minimumConfirmations}) async {
    final keys = {for (final t in await session.transactions(refresh: false)) t.key};
    final spendable = minimumConfirmations == null
        ? null
        : (await session.summary(refresh: false, minimumConfirmations: minimumConfirmations)).spendable;
    return SendBefore._(session, keys, spendable);
  }

  /// What the failed send of [amount] to [to] left behind. Rows that cannot be read again
  /// answer [StoredSend.unknown].
  Future<StoredSend> leftBehind({required String to, required BigInt amount, required SentToMatch match, BigInt? minimumConfirmations}) async {
    final List<TxEntry> after;
    try {
      after = await _session.transactions(refresh: false);
    } on WalletError {
      return StoredSend.unknown;
    }
    final fresh = [for (final t in after) if (!_keys.contains(t.key) && t.kind == TxKind.sent) t];
    final host = to.toLowerCase();
    final waiting = fresh
        .where(
          (t) =>
              t.status == TxStatus.awaitingRecipient &&
              t.id != null &&
              txAmount(t).amount == amount &&
              switch (match) {
                SentToMatch.exact => t.counterparty?.trim() == to,
                SentToMatch.host => t.counterparty == null || t.counterparty!.toLowerCase().contains(host),
              },
        )
        .toList()
      ..sort((a, b) => b.createdAtUnix.compareTo(a.createdAtUnix));
    var nothing = false;
    final before = _spendable;
    if (before != null && minimumConfirmations != null && waiting.isEmpty) {
      final spendable = (await _session.summary(refresh: false, minimumConfirmations: minimumConfirmations)).spendable;
      nothing = spendable == before && after.length == _keys.length && after.every((t) => _keys.contains(t.key));
    }
    return StoredSend._(payment: waiting.firstOrNull, stored: fresh.isNotEmpty, nothingStored: nothing);
  }
}

/// What a failed send left in the wallet ([SendBefore.leftBehind]).
class StoredSend {
  const StoredSend._({this.payment, required this.stored, required this.nothingStored});

  /// The rows could not be read again: the send may wait in the history.
  static const StoredSend unknown = StoredSend._(stored: true, nothingStored: false);

  /// The payment the core stored for this send, waiting for its recipient with its coins
  /// locked (the newest such row); null when none matches.
  final TxEntry? payment;

  /// A new sent row of any recipient or amount is in the history, or the rows could not be read
  /// again.
  final bool stored;

  /// Nothing changed: no new row, and the spendable balance as before. Only told when the
  /// balance was taken before ([SendBefore.take] with minimum confirmations).
  final bool nothingStored;
}
