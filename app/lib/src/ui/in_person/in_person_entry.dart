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
import '../epic1/epic1_common.dart' show showEpic1ModeSheet;
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
      // A classic payment's animated code: the caller's classic-code route says so.
      if (got.classic) return false;
      final bytes = got.bytes;
      if (bytes != null) await _openWhole(context, container, wallet, bytes);
      final other = got.text;
      if (other != null && context.mounted) await openInPersonText(context, other);
      return true;
  }
}

/// A whole in-person code or answer another scanner read as an animated code (Home's scan
/// reads one as the payment QR it looks like): in epic1 mode its review, or an answer's
/// check; in classic mode the sheet that says to turn epic1 on (spec P3).
Future<void> openScannedInPerson(BuildContext context, Uint8List bytes) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final wallet = container.read(epic1Provider);
  if (wallet == null) return;
  if (container.read(paymentModeProvider) != PaymentMode.epic1) {
    await showEpic1ModeSheet(context, context.l10n.deskE1ModeEpic1Code);
    return;
  }
  await _openWhole(context, container, wallet, bytes);
}

/// A whole animated code, read by a scanner: its review or its answer's check, or a refusal
/// that says why. A code for another network says so; an altered one, or an answer for
/// another device, is no code this wallet can use.
Future<void> _openWhole(BuildContext context, ProviderContainer container, Epic1Wallet wallet, Uint8List bytes) async {
  WalletErrorKind? why;
  if (await _openCode(context, container, wallet, bytes, fromQr: true, refused: (kind) => why = kind)) return;
  if (!context.mounted) return;
  final l = context.l10n;
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => InPersonEndScreen(
        title: l.deskIpScanTitle,
        headline: why == WalletErrorKind.epic1WrongNetwork ? l.deskE1ErrCodeWrongNetwork : l.deskE1ErrNotInPerson,
      ),
    ),
  );
}

/// A code's [bytes]: its review, or why it cannot be used. A whole QR code that is no code
/// may be an answer. When it is neither, [refused] hears why the code was not read.
Future<bool> _openCode(
  BuildContext context,
  ProviderContainer container,
  Epic1Wallet wallet,
  Uint8List bytes, {
  required bool fromQr,
  void Function(WalletErrorKind kind)? refused,
}) async {
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
    refused?.call(e.kind);
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
