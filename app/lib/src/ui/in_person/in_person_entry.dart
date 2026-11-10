// SPDX-License-Identifier: Apache-2.0
/// The phone's ways into epic1 in-person payments (spec D5, P3, P5, P6). Receive, Send and the
/// scanner call these; the screens behind them live in this folder.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../epic1.dart';
import '../../l10n.dart';
import '../../models.dart';
import '../../providers.dart';
import 'in_person_logic.dart';
import 'in_person_scan.dart';
import 'in_person_screens.dart';

/// Receive › "Request in person": amount and message, then the code and the check.
Future<void> openRequestInPerson(BuildContext context) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(builder: (_) => const InPersonFormScreen(stage: InPersonStage.request)),
);

/// Send › "Pay in person": amount, then the send code and the check.
Future<void> openPayInPerson(BuildContext context) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(builder: (_) => const InPersonFormScreen(stage: InPersonStage.send)),
);

/// Scanned, pasted or opened [text] that may be an in-person code or answer. Handles it and
/// returns true, or returns false when it is neither.
Future<bool> openInPersonText(BuildContext context, String text) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final wallet = container.read(epic1Provider);
  if (wallet == null) return false;
  switch (readInPersonText(wallet, text)) {
    case null:
      return false;
    case InPersonArmored(:final bytes):
      return _openAnswer(context, wallet, bytes);
    case InPersonBytes(:final bytes, :final fromQr):
      return _openCode(context, container, wallet, bytes, fromQr: fromQr);
    case InPersonPart(:final part):
      // More parts to come: the scanner goes on until it has them all.
      final got = await Navigator.of(context).push<InPersonScanned>(
        MaterialPageRoute<InPersonScanned>(builder: (_) => InPersonScanScreen(first: part)),
      );
      if (got == null || !context.mounted) return true;
      final bytes = got.bytes;
      if (bytes != null) await _openCode(context, container, wallet, bytes, fromQr: true);
      final other = got.text;
      if (other != null && context.mounted) await openInPersonText(context, other);
      return true;
  }
}

/// A code's [bytes]: its review, or why it cannot be used. A whole QR code that is no code
/// may be an answer.
Future<bool> _openCode(BuildContext context, ProviderContainer container, Epic1Wallet wallet, Uint8List bytes, {required bool fromQr}) async {
  try {
    final info = await wallet.inPersonRead(bytes, minimumConfirmations: container.read(countedConfirmationsProvider));
    if (!context.mounted) return true;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => InPersonReviewScreen(code: bytes, info: info)),
    );
    return true;
  } on WalletError catch (e) {
    if (!context.mounted) return true;
    if (e.kind == WalletErrorKind.codeExpired) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => InPersonEndScreen(title: context.l10n.deskIpScanTitle, headline: context.l10n.deskE1ErrCodeExpired),
        ),
      );
      return true;
    }
    if (fromQr) return _openAnswer(context, wallet, bytes);
    return false;
  }
}

/// An answer to a code this wallet showed, taken outside the code's screen: the check.
Future<bool> _openAnswer(BuildContext context, Epic1Wallet wallet, List<int> bytes) async {
  final InPersonTaken taken;
  try {
    taken = await wallet.inPersonTake(bytes);
  } on Object {
    return false;
  }
  if (!context.mounted) return true;
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => InPersonCodeScreen(watch: InPersonCodeWatch.answered(wallet: wallet, taken: taken)),
    ),
  );
  return true;
}
